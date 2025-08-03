# Nginx Proxy Manager Makefile
# 다른 서버에서 자동으로 설치 및 실행할 수 있는 Makefile

SHELL := /bin/bash
PROJECT_NAME := nginx-proxy
DOCKER_COMPOSE := docker compose
DATA_DIR := ./data

# 색상 정의
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help
help: ## 도움말 표시
	@echo -e "$(GREEN)Nginx Proxy Manager 설치 및 관리$(NC)"
	@echo ""
	@echo "사용법:"
	@echo "  make [타겟]"
	@echo ""
	@echo "타겟:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

.PHONY: check-requirements
check-requirements: ## 필수 요구사항 확인
	@echo -e "$(YELLOW)필수 요구사항 확인 중...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo -e "$(RED)Docker가 설치되어 있지 않습니다. https://docs.docker.com/get-docker/ 를 참고하여 설치해주세요.$(NC)" >&2; exit 1; }
	@command -v docker compose >/dev/null 2>&1 || command -v docker-compose >/dev/null 2>&1 || { echo -e "$(RED)Docker Compose가 설치되어 있지 않습니다.$(NC)" >&2; exit 1; }
	@docker info >/dev/null 2>&1 || { echo -e "$(RED)Docker 데몬이 실행 중이 아닙니다. Docker를 시작해주세요.$(NC)" >&2; exit 1; }
	@echo -e "$(GREEN)모든 요구사항이 충족되었습니다.$(NC)"

.PHONY: init
init: check-requirements ## 초기 설정 (데이터 디렉토리 생성)
	@echo -e "$(YELLOW)데이터 디렉토리 구조 생성 중...$(NC)"
	@mkdir -p $(DATA_DIR)/nginx/{proxy_host,redirection_host,stream,dead_host,temp,default_host,default_www}
	@mkdir -p $(DATA_DIR)/logs
	@mkdir -p $(DATA_DIR)/access
	@mkdir -p $(DATA_DIR)/custom_ssl
	@mkdir -p $(DATA_DIR)/letsencrypt-acme-challenge
	@mkdir -p letsencrypt
	@touch $(DATA_DIR)/access/default.log
	@echo -e "$(GREEN)데이터 디렉토리 구조가 생성되었습니다.$(NC)"

.PHONY: install
install: init ## 프로젝트 클론 및 설치
	@if [ ! -f docker-compose.yml ]; then \
		echo -e "$(YELLOW)GitHub에서 프로젝트 클론 중...$(NC)"; \
		git clone https://github.com/wangtae/nginx-proxy.git . || { echo -e "$(RED)프로젝트 클론 실패$(NC)"; exit 1; }; \
	fi
	@echo -e "$(GREEN)설치가 완료되었습니다.$(NC)"

.PHONY: start
start: check-requirements ## Docker 컨테이너 시작
	@echo -e "$(YELLOW)Nginx Proxy Manager 시작 중...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@echo -e "$(GREEN)Nginx Proxy Manager가 시작되었습니다.$(NC)"
	@echo -e "$(GREEN)웹 인터페이스: http://localhost:81$(NC)"
	@echo -e "$(GREEN)기본 로그인 정보:$(NC)"
	@echo -e "  이메일: admin@example.com"
	@echo -e "  비밀번호: changeme"

.PHONY: stop
stop: ## Docker 컨테이너 중지
	@echo -e "$(YELLOW)Nginx Proxy Manager 중지 중...$(NC)"
	@$(DOCKER_COMPOSE) down
	@echo -e "$(GREEN)Nginx Proxy Manager가 중지되었습니다.$(NC)"

.PHONY: restart
restart: stop start ## Docker 컨테이너 재시작

.PHONY: status
status: ## 컨테이너 상태 확인
	@$(DOCKER_COMPOSE) ps

.PHONY: logs
logs: ## 컨테이너 로그 보기
	@$(DOCKER_COMPOSE) logs -f

.PHONY: logs-tail
logs-tail: ## 최근 100줄 로그 보기
	@$(DOCKER_COMPOSE) logs --tail=100

.PHONY: backup
backup: ## 데이터 백업
	@echo -e "$(YELLOW)데이터 백업 중...$(NC)"
	@mkdir -p backups
	@tar -czf backups/nginx-proxy-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz data/
	@echo -e "$(GREEN)백업이 완료되었습니다: backups/nginx-proxy-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz$(NC)"

.PHONY: restore
restore: ## 데이터 복원 (BACKUP_FILE 변수 필요)
	@if [ -z "$(BACKUP_FILE)" ]; then \
		echo -e "$(RED)BACKUP_FILE 변수를 지정해주세요. 예: make restore BACKUP_FILE=backups/nginx-proxy-backup-20240101-120000.tar.gz$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f "$(BACKUP_FILE)" ]; then \
		echo -e "$(RED)백업 파일을 찾을 수 없습니다: $(BACKUP_FILE)$(NC)"; \
		exit 1; \
	fi
	@echo -e "$(YELLOW)데이터 복원 중...$(NC)"
	@$(DOCKER_COMPOSE) down
	@rm -rf data/
	@tar -xzf $(BACKUP_FILE)
	@echo -e "$(GREEN)데이터가 복원되었습니다.$(NC)"
	@echo -e "$(YELLOW)'make start'로 서비스를 시작하세요.$(NC)"

.PHONY: update
update: ## 최신 버전으로 업데이트
	@echo -e "$(YELLOW)최신 버전으로 업데이트 중...$(NC)"
	@$(DOCKER_COMPOSE) pull
	@$(DOCKER_COMPOSE) up -d
	@echo -e "$(GREEN)업데이트가 완료되었습니다.$(NC)"

.PHONY: clean
clean: ## 모든 컨테이너와 볼륨 제거 (주의: 데이터 손실)
	@echo -e "$(RED)경고: 이 작업은 모든 데이터를 삭제합니다!$(NC)"
	@read -p "정말로 계속하시겠습니까? (y/N) " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		$(DOCKER_COMPOSE) down -v; \
		rm -rf data/ letsencrypt/; \
		echo -e "$(GREEN)정리가 완료되었습니다.$(NC)"; \
	else \
		echo -e "$(YELLOW)작업이 취소되었습니다.$(NC)"; \
	fi

.PHONY: shell
shell: ## 컨테이너 쉘 접속
	@$(DOCKER_COMPOSE) exec nginx-proxy /bin/bash

.PHONY: quick-start
quick-start: install start ## 빠른 시작 (클론 + 설치 + 시작)
	@echo -e "$(GREEN)Nginx Proxy Manager가 성공적으로 설치되고 시작되었습니다!$(NC)"
	@echo -e "$(GREEN)웹 인터페이스: http://localhost:81$(NC)"

# 기본 타겟
.DEFAULT_GOAL := help