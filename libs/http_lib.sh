#!/bin/bash

# ------------------------------------------------------------
# HTTP 유틸리티 모듈
# ------------------------------------------------------------

# URL에서 GET 요청
# example: http_curl_get <URL>
http_curl_get() {
  local url="$1"

  if [ -z "$url" ]; then
    echo "❌ URL을 입력해주세요"
    return 1
  fi

  echo "🌐 GET 요청 중: $url"
  curl -fsSL "$url"
  echo "✅ GET 요청 완료"
}
