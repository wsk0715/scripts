# Commands
alias grep='grep --color=auto'
alias cl='clear'
alias h='history'
alias hg='history | grep -i'
alias md='mkdir'

# alias ls='ls --color=auto'
# alias la='ls -A'
# alias ll='ls -alF'
# alias lg='ls -alF | grep -i'
# alias l='ls -CF'

# exa & eza
alias ls='eza --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'

alias l='eza -lbh --icons --group-directories-first --git --color-scale --time-style=iso'
alias lt='l --tree --level=2'
alias lg='l --color=always | grep -i'

alias ll='eza -albh --icons --group-directories-first --git --color-scale --time-style=iso'
alias llt='ll --tree --level=2'
alias llg='ll --color=always | grep -i' 

alias lx='eza -albhg --modified --accessed --icons --group-directories-first --git --color-scale --time-style=long-iso'
alias lxt='lx --tree --level=2'

alias lxx='eza -albhgHUSmi --created --modified --accessed --icons --group-directories-first --git --color-scale --time-style=long-iso'
alias lxxt='lxx --tree --level=2'

# Docker & Kubernetes
alias d='docker'
alias dc='docker compose'
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" | cut -c 1-$COLUMNS'
alias k='kubectl'
alias ku='kustomize'

# Terraform
alias 'tf'='terraform'
alias '_tf'='terraform plan && terraform apply'
alias '_tfy'='terraform plan && terraform apply -auto-approve'

# Functions
cmod() {
  # 첫 번째 인자가 있으면 그 타겟을 사용하고, 없으면 현재 폴더(.)를 사용
  local target=${1:-.}

  # 해당 경로에 .sh 파일이 있는지 먼저 확인 (불필요한 에러 방지)
  if ls "$target"/*.sh >/dev/null 2>&1; then
    echo "🔐 Adding execution permission to file(s): $target"
    sudo chmod +x "$target"/*.sh
  else
    echo "❓ No .sh files found in: $target"
  fi
}

# etc.
alias lq="logcli query '{pod=~\"springboot.*\"}' --limit=100 | grep -i"
