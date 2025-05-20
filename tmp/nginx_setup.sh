#!/bin/bash

set -e

# 1. 사용자 입력 받기
read -p "(1/3) 앱 이름을 입력하세요 (기본값: default-app): " APP_NAME
read -p "(2/3) 리버스 프록시 대상 포트를 입력하세요 (기본값: 3000): " APP_PORT
read -p "(3/3) SSL 인증서를 발급받으시겠습니까? (Y/n): " ENABLE_SSL

APP_NAME=${APP_NAME:-default-app}
APP_PORT=${APP_PORT:-3000}
ENABLE_SSL=${ENABLE_SSL:-Y}

# SSL 인증서 선택 시
if [[ "$ENABLE_SSL" == "Y" || "$ENABLE_SSL" == "y" ]]; then
  # 도메인 입력 (빈 값 허용 안 함)
  while true; do
    read -p "(1/2) 사용할 도메인명을 입력하세요 (예시: example.com): " DOMAIN
    if [ -n "$DOMAIN" ]; then
      break
    fi
    echo "❌ 도메인명을 반드시 입력해야 합니다."
  done

  # 이메일 입력 (빈 값 허용 안 함)
  while true; do
    read -p "(2/2) SSL 인증서 발급용 이메일을 입력하세요: " EMAIL
    if [ -n "$EMAIL" ]; then
      break
    fi
    echo "❌ 이메일을 반드시 입력해야 합니다."
  done
fi

# 입력 요약
echo "▶ 앱 이름: $APP_NAME"
echo "▶ 포트: $APP_PORT"
echo "▶ SSL 적용 여부: $ENABLE_SSL"
if [[ "$ENABLE_SSL" == "Y" || "$ENABLE_SSL" == "y" ]]; then
  echo "▶ 도메인: $DOMAIN"
  echo "▶ 이메일: $EMAIL"
fi

read -p "계속 진행하시겠습니까? (Y/n): " CONFIRM
CONFIRM=${CONFIRM:-Y}

if [[ "$CONFIRM" != "Y" && "$CONFIRM" != "y" ]]; then
  exec "$0"
fi

# 2. 패키지 설치
echo "📦 Nginx 및 Certbot 설치 중..."
sudo apt update
sudo apt install -y \
  nginx \
  certbot \
  python3-certbot-nginx

# 3. Nginx 설정 생성
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
echo "📝 Nginx 설정 파일 생성: $NGINX_CONF"

cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name ${DOMAIN:-127.0.0.1};

    location / {
        proxy_pass http://localhost:$APP_PORT;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# 4. 심볼릭 링크 적용
echo "🔗 심볼릭 링크 연결..."
ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 5. Nginx 테스트 및 재시작
echo "🚦 Nginx 설정 테스트 및 재시작..."
nginx -t
systemctl reload nginx

# 6. SSL 인증서 발급
if [[ "$ENABLE_SSL" == "Y" || "$ENABLE_SSL" == "y" ]]; then
  echo "🔐 Certbot으로 SSL 인증서 발급..."
  certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "$EMAIL" --redirect

  echo "🔐 SSL 인증서 발급 완료: https://$DOMAIN"
fi

echo "✅ Nginx 웹 서버 설치 완료"
