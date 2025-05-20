#!/usr/bin/env bash

# ------------------------------------------------------------
# 파일 라이브러리
# ------------------------------------------------------------

# 파일/디렉토리 백업
# 사용법: file_backup <파일 경로1> <파일 경로2> <파일 경로3> ...
file_backup() {
    local source_dirs=("$@")

    if [ ${#source_dirs[@]} -eq 0 ]; then
        echo "❌ 에러: 백업할 파일/디렉토리 경로를 지정해주세요"
        return 1
    fi

    local failed_count=0
    local timestamp=$(date +%Y%m%d.%H%M%S)

    for source_dir in "${source_dirs[@]}"; do
        if [ ! -e "$source_dir" ]; then
            continue
        fi

        local backup_file="${source_dir}.backup.${timestamp}"

        # 백업 실행 (권한, 소유자/그룹, 타임스탬프 등 모든 속성 보존)
        if sudo cp -a "$source_dir" "$backup_file"; then
            :
        else
            ((failed_count++))
        fi
    done

    return $failed_count
}

# 파일/디렉토리 삭제 함수
# 사용법: file_remove <파일 경로1> <파일 경로2> <파일 경로3> ...
file_remove() {
    local target_dirs=("$@")

    if [ ${#target_dirs[@]} -eq 0 ]; then
        echo "❌ 에러: 삭제할 파일/디렉토리 경로를 지정해주세요"
        return 1
    fi

    local failed_count=0

    for target_dir in "${target_dirs[@]}"; do
        if [ ! -e "$target_dir" ]; then
            continue
        fi

        # 파일 삭제 실행
        if sudo rm -rf "$target_dir"; then
            :
        else
            ((failed_count++))
        fi
    done

    return $failed_count
}
