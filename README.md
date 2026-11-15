# scripts

노드와 개인 호스트의 초기 설정 스크립트 모음이다.

## runner-setup.sh

GitHub Actions 러너를 전용 계정(`ci`)과 그 계정의 rootless docker로 옮기기 위한 설정 스크립트다. 실제 설정은 대상 호스트에서 직접 실행한다.

사용 순서:

1. `./runner-setup.sh --check`로 cgroup v2, rootless docker 도구, 관련 패키지, `ci` 계정과 그룹, subuid/subgid, linger를 읽기 전용으로 점검한다. `missing`이 하나라도 있으면 종료 코드 3이다.
2. `sudo ./runner-setup.sh --apply`로 빠진 패키지(`uidmap`, `slirp4netns`, `fuse-overlayfs`)를 설치하고, `ci` 계정과 subuid/subgid, linger, rootless docker를 설정한다. 모든 단계는 다시 실행해도 결과가 같다.
3. `./runner-setup.sh --verify`로 `ci`가 sudo·docker 그룹에서 빠졌는지, linger, rootless docker 유닛, 러너 서비스가 active인지 확인한다.
4. 러너 등록은 스크립트가 하지 않는다. `--apply` 마지막에 출력되는 `config.sh` 명령을 `ci` 사용자로 실행하고 토큰은 직접 넣는다.

`--check`와 `--verify`는 아무것도 바꾸지 않는다. `--apply`는 root 권한이 필요하다. 스크립트는 기존 러너, `ubuntu` 계정, sudoers, `/etc/rancher/k3s/`, iptables를 건드리지 않는다.
