#!/bin/bash

# 문자열 처리 모듈


# 파일 내용이 존재한다면 수정, 없다면 추가
# example: string_replace_or_append <파일> <찾을 패턴> <대체 텍스트>
string_replace_or_append() {
  local file="$1"        # 대상 파일
  local pattern="$2"     # 찾을 패턴
  local replacement="$3" # 대체 텍스트

  if grep -q "$pattern" "$file"; then
    sed -i "s|$pattern.*|$replacement|" "$file"
  else
    echo "$replacement" >> "$file"
  fi
}
