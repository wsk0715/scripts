#!/usr/bin/env bash

# ------------------------------------------------------------
# 문자열 처리 모듈
# ------------------------------------------------------------

# sed 패턴 이스케이프 (basic regex)
_escape_sed() {
  echo "$1" | sed 's:[][\/.^$*]:\\&:g'
}

# 파일 내용이 존재한다면 수정, 없다면 추가
# 사용법: string_replace_or_append <파일> <찾을 패턴> <대체 텍스트>
# pattern은 고정 문자열(fixed string)로 검색하며, 일치하는 라인 전체를 replacement로 교체
string_replace_or_append() {
  local file="$1"
  local pattern="$2"
  local replacement="$3"

  if [ ! -f "$file" ]; then
    echo "❌ 파일이 존재하지 않습니다: $file"
    return 1
  fi

  # 백업
  local backup="${file}.bak.$(date +%s)"
  sudo cp "$file" "$backup" 2>/dev/null || true

  # 고정 문자열(fixed) 매칭
  if sudo grep -qF "$pattern" "$file" 2>/dev/null; then
    local escaped
    escaped=$(_escape_sed "$pattern")
    sudo sed -i "s/^${escaped}.*/$replacement/" "$file"
  else
    echo "$replacement" | sudo tee -a "$file" > /dev/null
  fi
}
