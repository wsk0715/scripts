" --- 외관 및 인터페이스 ---
"set title               " 터미널 상단에 파일명 표시
set number              " 왼쪽 줄 번호 표시
"set relativenumber      " 현재 줄 기준 상대 번호 (멀리 이동할 때 유용)
"set cursorline          " 현재 커서가 있는 줄 강조
set showmatch           " 괄호 닫을 때 대응하는 앞 괄호 표시

" --- 편집 및 들여쓰기 ---
set autoindent          " 자동 들여쓰기
set smartindent         " 코딩 시 스마트한 들여쓰기
set tabstop=4           " Tab을 4칸으로 표시
set shiftwidth=4        " >>나 << 사용 시 4칸 이동
set expandtab           " Tab을 공백(Space)으로 변환 (협업 시 권장)

" --- 검색 관련 ---
set hlsearch            " 검색 결과 하이라이트
set ignorecase          " 검색 시 대소문자 무시
set smartcase           " 대문자를 포함해 검색하면 대소문자 구분
set incsearch           " 검색어 입력하는 동안 실시간 이동

" --- 기타 ---
set clipboard=unnamedplus " 시스템 클립보드와 연동 (복붙 편리)
set mouse=a             " 마우스 사용 가능
syntax on               " 구문 강조(하이라이트) 켜기

filetype plugin indent on
augroup filetype_settings
    autocmd!
    " YAML: 2 spaces
    autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
    " Python: 4 spaces
    autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab
augroup END
