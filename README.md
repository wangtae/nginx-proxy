# 🔧 Nginx Proxy Manager 설정 가이드

## 📋 개요

로컬 개발 환경에서 여러 프로젝트를 도메인으로 구분하여 접속할 수 있도록 Nginx Proxy Manager를 설정합니다.

## 🚀 실행 방법

### 자동 설치 및 실행 (Makefile 사용) - 권장

```bash
# 프로젝트 클론 및 빠른 시작
git clone https://github.com/wangtae/nginx-proxy.git
cd nginx-proxy
make quick-start

# 또는 이미 클론한 경우
make start
```

### Makefile 주요 명령어

```bash
make help          # 도움말 표시
make quick-start   # 빠른 시작 (클론 + 설치 + 시작)
make install       # 프로젝트 설치
make start         # 컨테이너 시작
make stop          # 컨테이너 중지
make restart       # 컨테이너 재시작
make status        # 컨테이너 상태 확인
make logs          # 실시간 로그 보기
make backup        # 데이터 백업
make restore BACKUP_FILE=backups/xxx.tar.gz  # 데이터 복원
make update        # 최신 버전으로 업데이트
```

### 수동 실행 방법

1. **NPM 시작**
```bash
cd nginx-proxy
docker compose up -d
```

2. **관리 UI 접속**
```
http://localhost:81
```

3. **초기 로그인**
- **Email**: admin@example.com
- **Password**: changeme

⚠️ 첫 로그인 후 반드시 비밀번호를 변경하세요!

## 🌐 프록시 호스트 설정

### Domaeka 프로젝트 설정

1. **Proxy Hosts** 메뉴 → **Add Proxy Host** 클릭

2. **Details 탭**
   - Domain Names: `domaeka.local`
   - Scheme: `http`
   - Forward Hostname / IP: `domaeka-web`
   - Forward Port: `80`
   - Cache Assets: ✓ (선택사항)
   - Block Common Exploits: ✓ (권장)
   - Websockets Support: ✓ (필요시)

3. **저장** 클릭

### 추가 프로젝트 설정 (예: kkobot)

동일한 방식으로 설정:
- Domain Names: `kkobot.local`
- Forward Hostname / IP: `kkobot-web`
- Forward Port: `80`

## 🔍 확인 방법

### 1. hosts 파일 확인
```bash
# Linux/Mac
cat /etc/hosts | grep local

# Windows (관리자 권한 필요)
# C:\Windows\System32\drivers\etc\hosts
```

다음과 같이 설정되어 있어야 함:
```
127.0.0.1    domaeka.local
127.0.0.1    kkobot.local
```

### 2. 접속 테스트
```bash
# NPM을 통한 접속 (포트 번호 불필요)
curl http://domaeka.local

# 브라우저에서 접속
http://domaeka.local
```

## ⚠️ 주의사항

1. **Docker 네트워크**: 모든 컨테이너가 같은 `docker-network`에 있어야 함
2. **포트 충돌**: 로컬에 이미 80번 포트를 사용하는 서비스가 없어야 함
3. **컨테이너 이름**: NPM에서는 컨테이너 이름으로 연결하므로 정확히 입력

## 🔧 문제 해결

### 80번 포트 사용 중
```bash
# 사용 중인 프로세스 확인
sudo lsof -i :80

# Apache/Nginx 중지
sudo systemctl stop apache2
sudo systemctl stop nginx
```

### 도메인 연결 안됨
1. hosts 파일 확인
2. NPM 프록시 설정 확인
3. 대상 컨테이너 실행 상태 확인

### NPM 로그 확인
```bash
docker-compose logs -f npm
```

## 📊 설정 후 구조

```
[브라우저]
    ↓
[domaeka.local] → [NPM (80번)] → [domaeka-web 컨테이너]
[kkobot.local]  → [NPM (80번)] → [kkobot-web 컨테이너]
    ↓
[관리 UI: localhost:81]
```

## 🎯 장점

1. **포트 번호 불필요** - 도메인만으로 접속
2. **중앙 집중 관리** - 모든 프록시 설정을 한 곳에서
3. **SSL 인증서** - Let's Encrypt 자동 발급 가능 (필요시)
4. **접근 제어** - IP 제한, 인증 등 추가 가능