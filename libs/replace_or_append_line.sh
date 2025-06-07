#!/bin/bash

# 파일 내용 수정 or 추가 함수

replace_or_append_line() {
  local file="$1"        # 대상 파일
  local pattern="$2"     # 찾을 패턴
  local replacement="$3" # 대체 텍스트

  if grep -q "$pattern" "$file"; then
    sed -i "s|$pattern.*|$replacement|" "$file"
  else
    echo "$replacement" >> "$file"
  fi
}
