#!/bin/bash
# Claude Code AI Commit Slash Command 관리 스크립트 (Markdown 기반)
# 대화형 메뉴 방식으로 설치, 삭제, 업데이트 관리

set -e

# macOS 호환성 체크
IS_MACOS=false
if [[ "$OSTYPE" == "darwin"* ]]; then
    IS_MACOS=true
fi

# 색상 정의 (macOS Terminal 호환)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# 이모지
EMOJI_SUCCESS="✅"
EMOJI_ERROR="❌"
EMOJI_WARNING="⚠️"
EMOJI_INFO="ℹ️"
EMOJI_ROCKET="🚀"
EMOJI_TRASH="🗑️"
EMOJI_PACKAGE="📦"
EMOJI_GLOBAL="🌍"
EMOJI_LOCAL="📁"
EMOJI_UPDATE="🔄"
EMOJI_BACKUP="💾"
EMOJI_RESTORE="♻️"
EMOJI_CONFIG="⚙️"

# 스크립트 정보
SCRIPT_VERSION="3.2.0"
SCRIPT_NAME="AI Commit Manager"

# Claude Code 디렉토리 경로 (Markdown 기반)
GLOBAL_DIR="$HOME/.claude/commands"
PROJECT_DIR=".claude/commands"
BACKUP_DIR="$HOME/.claude/backups"
COMMAND_FILE="ai-commit.md"  # .yaml에서 .md로 변경
CONFIG_FILE="$HOME/.claude/ai-commit.conf"

# date 명령어 호환성 함수
get_timestamp() {
    date +%s
}

get_iso_date() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

get_backup_timestamp() {
    date +%Y%m%d-%H%M%S
}

# 설정 초기화
init_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat > "$CONFIG_FILE" << EOF
# AI Commit 기본 설정
DEFAULT_LANG="kr"
DEFAULT_EMOJI="false"
DEFAULT_SPLIT="true"
DEFAULT_DETAIL="false"
DEFAULT_AUTO="false"
AUTO_UPDATE_CHECK="true"
LAST_UPDATE_CHECK="$(get_timestamp)"
EOF
    fi
    source "$CONFIG_FILE"
}

# 배너 출력
print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════╗
    ║                                              ║
    ║      🤖 Claude Code AI Commit Manager 🤖     ║
    ║               Version 3.2.0                  ║
    ║         Now with Help Option (-h)!           ║
    ║                                              ║
    ╚══════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # macOS 정보 표시
    if [ "$IS_MACOS" = true ]; then
        echo -e "${DIM}Running on macOS $(sw_vers -productVersion 2>/dev/null || echo "")${NC}"
        echo ""
    fi
}

# 메시지 출력 함수
print_success() { echo -e "${GREEN}${EMOJI_SUCCESS} $1${NC}"; }
print_error() { echo -e "${RED}${EMOJI_ERROR} $1${NC}"; }
print_warning() { echo -e "${YELLOW}${EMOJI_WARNING} $1${NC}"; }
print_info() { echo -e "${BLUE}${EMOJI_INFO} $1${NC}"; }
print_dim() { echo -e "${DIM}$1${NC}"; }

# AI Commit Markdown 내용 생성
create_markdown_content() {
    local is_global=$1
    local lang=${2:-$DEFAULT_LANG}
    local emoji=${3:-$DEFAULT_EMOJI}
    local split=${4:-$DEFAULT_SPLIT}
    local detail=${5:-$DEFAULT_DETAIL}
    local auto=${6:-$DEFAULT_AUTO}
    
    cat << 'EOF'
# AI Commit

AI가 코드 변경사항을 분석하여 Conventional Commits 형식의 한글 커밋 메시지를 생성하고 커밋합니다.

## 사용법
```
/user:ai-commit -h             # 도움말 표시
/user:ai-commit --help         # 도움말 표시
/user:ai-commit
/user:ai-commit --auto         # 모든 변경사항 자동 스테이징
/user:ai-commit --quick        # 자동 스테이징 + 확인 없이 커밋
/user:ai-commit --lang en      # 영문 메시지
/user:ai-commit --emoji        # 이모지 포함
/user:ai-commit --detail       # 상세 분석
/user:ai-commit --split        # 변경사항 분리
/user:ai-commit --push         # 커밋 후 자동 push
/user:ai-commit --dry-run      # 메시지만 생성 (커밋 안함)
```

## 별칭
- `/user:aic` - 짧은 버전
- `/user:aic -h` - 도움말 표시

## 빠른 사용
- `/user:aic --quick` - 모든 변경사항을 자동으로 스테이징하고 확인 없이 커밋
- `/user:aic --quick --push` - 빠른 커밋 후 자동 push

## 명령어 실행 내용

Git 저장소의 변경사항을 분석하여 적절한 커밋 메시지를 생성하고 커밋을 수행하세요.

### 0. 도움말 확인 (-h 또는 --help 옵션)
옵션에 `-h` 또는 `--help`가 포함되어 있으면:
```
🤖 AI Commit 사용법

기본 사용:
  /user:ai-commit              # 기본 커밋 (한글 메시지)
  /user:aic                    # 짧은 별칭

스테이징 옵션:
  --auto                       # 모든 변경사항 자동 스테이징
  --quick                      # 자동 스테이징 + 확인 없이 즉시 커밋

메시지 옵션:
  --lang en                    # 영문 메시지 생성
  --emoji                      # 커밋 타입별 이모지 추가
  --detail                     # 상세 코드 분석

워크플로우 옵션:
  --split                      # 변경사항을 논리적 단위로 분리
  --push                       # 커밋 후 자동 push
  --dry-run                    # 메시지만 생성 (실제 커밋 안함)

도움말:
  -h, --help                   # 이 도움말 표시

예시:
  /user:aic --quick --push     # 빠른 커밋 후 push
  /user:ai-commit --lang en --emoji  # 영문 + 이모지
  /user:ai-commit --auto --split     # 자동 스테이징 + 분리 커밋

자세한 정보: https://github.com/your-repo/ai-commit
```
도움말을 표시한 후 종료하세요.

### 1. Git 저장소 확인
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```
Git 저장소가 아니면 에러 메시지를 출력하고 종료하세요.

### 2. 변경사항 확인 및 스테이징
- `git status --porcelain`으로 변경사항 확인
- --quick 옵션 사용시:
  * 자동으로 `git add .` 실행
  * 사용자 확인 없이 즉시 커밋 진행
- --auto 옵션 사용시:
  * 자동으로 `git add .` 실행
  * 커밋 전 사용자 확인은 받음
- 옵션 미사용시:
  * staged 파일이 없으면:
    - unstaged/untracked 파일 목록 표시
    - 사용자에게 스테이징 옵션 제공
    - 모두 추가 (git add .) 또는 대화형 선택 (git add -i)

### 3. 코드 분석
`git diff --cached`로 실제 변경 내용을 분석하여:

**커밋 타입 결정 (우선순위순)**
1. **fix**: 버그 수정
   - 에러 처리 추가/수정
   - 조건문 버그 수정
   - null/undefined 체크
   - try-catch 추가

2. **feat**: 새 기능
   - 새 컴포넌트/함수/클래스
   - 새 API 엔드포인트
   - 새 페이지/라우트

3. **perf**: 성능 개선
   - 메모이제이션 (useMemo, useCallback)
   - 지연 로딩
   - 캐싱 로직

4. **refactor**: 리팩토링
   - 코드 구조 개선
   - 중복 제거

5. **test**: 테스트
   - 테스트 파일 추가/수정

6. **docs**: 문서
   - README, 주석 변경

7. **style**: 스타일
   - 포맷팅, 공백

8. **chore**: 기타
   - package.json, 설정

**스코프 결정**
- components/* → 컴포넌트명 또는 'ui'
- pages/* → 페이지명
- api/*, services/* → 'api'
- auth/*, *login* → 'auth'
- utils/* → 'utils'
- hooks/* → 'hooks'
- store/* → 'store'
- styles/* → 'style'
- db/* → 'db'

### 4. 메시지 생성
- 형식: `타입(스코프): 설명`
- 한글 50자 이내 (기본)
- 영문은 imperative mood
- emoji 옵션 사용시 타입별 이모지 추가

### 5. 변경사항 분리 (split 옵션)
서로 다른 목적의 변경사항 발견시:
- 논리적 그룹으로 분류
- 각 그룹 설명과 함께 표시
- 개별 커밋 vs 통합 선택

### 7. 실행 예시

**도움말 표시 (-h):**
```
$ /user:ai-commit -h

🤖 AI Commit 사용법

기본 사용:
  /user:ai-commit              # 기본 커밋 (한글 메시지)
  /user:aic                    # 짧은 별칭

스테이징 옵션:
  --auto                       # 모든 변경사항 자동 스테이징
  --quick                      # 자동 스테이징 + 확인 없이 즉시 커밋

메시지 옵션:
  --lang en                    # 영문 메시지 생성
  --emoji                      # 커밋 타입별 이모지 추가
  --detail                     # 상세 코드 분석

워크플로우 옵션:
  --split                      # 변경사항을 논리적 단위로 분리
  --push                       # 커밋 후 자동 push
  --dry-run                    # 메시지만 생성 (실제 커밋 안함)

예시:
  /user:aic --quick --push     # 빠른 커밋 후 push
  /user:ai-commit --lang en --emoji  # 영문 + 이모지
```

**기본 사용:**
```
🔍 코드 변경사항을 분석했습니다:

📝 주요 변경내용:
- UserProfile 컴포넌트에 편집 모드 추가
- 프로필 이미지 업로드 기능 구현
- 입력값 검증 로직 강화

✨ 생성된 커밋 메시지:
feat(profile): 사용자 프로필 편집 기능 추가

이 메시지로 커밋하시겠습니까? (Y/n/e[dit])
```

**빠른 커밋 (--quick):**
```
🚀 빠른 커밋 모드
📦 모든 변경사항을 자동 스테이징합니다...
✅ 5개 파일이 스테이징되었습니다.
🤖 코드를 분석하는 중...
✨ 커밋 메시지: feat(auth): 소셜 로그인 기능 추가
✅ 커밋이 완료되었습니다!
```

### 8. 커밋 후 처리
- 커밋 해시와 메시지 표시
- push 옵션 사용시 자동 push
- 다음 단계 제안 (PR 생성 등)

## 이모지 매핑 (emoji 옵션)
- ✨ feat
- 🐛 fix
- 📚 docs
- 💎 style
- ♻️ refactor
- ⚡️ perf
- ✅ test
- 🔧 chore

## 에러 처리
각 에러에 대해 명확한 해결 방법 제시:
- Git 저장소가 아닌 경우
- 변경사항이 없는 경우
- 병합 충돌 상태
- pre-commit hook 실패

## 옵션 설명

### 도움말
- `-h`, `--help`: 사용법과 모든 옵션 설명 표시

### 스테이징 옵션
- `--auto`: 모든 변경사항을 자동으로 스테이징 (`git add .`)하지만 커밋 전 확인
- `--quick`: 자동 스테이징 + 확인 없이 즉시 커밋 (가장 빠른 방법)

### 메시지 옵션
- `--lang en`: 영문 커밋 메시지 생성
- `--emoji`: 커밋 타입에 맞는 이모지 추가
- `--detail`: 상세한 코드 분석 및 설명

### 워크플로우 옵션
- `--split`: 여러 목적의 변경사항을 개별 커밋으로 분리
- `--push`: 커밋 후 자동으로 원격 저장소에 push
- `--dry-run`: 실제 커밋하지 않고 메시지만 생성 (테스트용)

### 조합 예시
- `/user:aic -h`: 도움말 보기
- `/user:aic --quick --push`: 즉시 커밋하고 push (가장 빠른 워크플로우)
- `/user:ai-commit --auto --emoji --push`: 자동 스테이징, 이모지 포함, push
- `/user:ai-commit --lang en --detail --dry-run`: 영문 상세 분석 미리보기

## 예시 커밋 메시지
- feat(auth): 카카오 로그인 기능 추가
- fix(payment): 결제 금액 계산 오류 수정
- perf(dashboard): 차트 렌더링 최적화
- refactor(utils): 날짜 처리 함수 통합
- test: 사용자 서비스 단위 테스트 추가
- docs: API 사용 가이드 업데이트
- style: 코드 포맷팅 및 import 정렬
- chore: 의존성 패키지 업데이트
EOF
    
    # 설정 정보 추가
    echo ""
    echo "## 현재 기본 설정"
    echo "- 언어: $lang"
    echo "- 이모지: $emoji"
    echo "- 분리 커밋: $split"
    echo "- 상세 모드: $detail"
    echo "- 자동 스테이징: $auto"
    echo ""
    echo "---"
    echo "Created: $(get_iso_date)"
    echo "Version: $SCRIPT_VERSION"
}

# 설치 상태 확인
check_installation() {
    local global_installed=false
    local project_installed=false
    local global_version=""
    local project_version=""
    
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        global_installed=true
        global_version=$(grep "Version:" "$GLOBAL_DIR/$COMMAND_FILE" 2>/dev/null | tail -1 | cut -d' ' -f2 || echo "1.0.0")
    fi
    
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        project_installed=true
        project_version=$(grep "Version:" "$PROJECT_DIR/$COMMAND_FILE" 2>/dev/null | tail -1 | cut -d' ' -f2 || echo "1.0.0")
    fi
    
    echo "$global_installed|$project_installed|$global_version|$project_version"
}

# 백업 생성
create_backup() {
    local type=$1 # global 또는 project
    local source_file=""
    local backup_name=""
    
    if [ "$type" = "global" ]; then
        source_file="$GLOBAL_DIR/$COMMAND_FILE"
        backup_name="ai-commit-global-$(get_backup_timestamp).md"
    else
        source_file="$PROJECT_DIR/$COMMAND_FILE"
        backup_name="ai-commit-project-$(get_backup_timestamp).md"
    fi
    
    if [ -f "$source_file" ]; then
        mkdir -p "$BACKUP_DIR"
        cp "$source_file" "$BACKUP_DIR/$backup_name"
        print_success "백업이 생성되었습니다: $backup_name"
    else
        print_error "백업할 파일이 없습니다."
    fi
}

# 백업 복원
restore_backup() {
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
        print_warning "백업 파일이 없습니다."
        return
    fi
    
    echo -e "${BOLD}사용 가능한 백업:${NC}"
    echo ""
    
    local i=1
    local backups=()
    
    # macOS 호환 방식으로 파일 목록 읽기
    while IFS= read -r backup; do
        if [ -f "$backup" ]; then
            backups+=("$backup")
            echo "$i) $(basename "$backup")"
            i=$((i + 1))
        fi
    done < <(find "$BACKUP_DIR" -name "*.md" -type f 2>/dev/null | sort -r)
    
    echo ""
    read -p "복원할 백업 번호를 선택하세요 (취소: 0): " choice
    
    if [ "$choice" -eq 0 ] 2>/dev/null; then
        return
    fi
    
    if [ "$choice" -gt 0 ] && [ "$choice" -le "${#backups[@]}" ] 2>/dev/null; then
        local selected_backup="${backups[$((choice-1))]}"
        local backup_name=$(basename "$selected_backup")
        
        echo ""
        echo "복원 대상: $backup_name"
        
        if [[ "$backup_name" == *"global"* ]]; then
            read -p "글로벌로 복원하시겠습니까? (Y/n): " confirm
            if [ "$confirm" != "n" ] && [ "$confirm" != "N" ]; then
                mkdir -p "$GLOBAL_DIR"
                cp "$selected_backup" "$GLOBAL_DIR/$COMMAND_FILE"
                print_success "글로벌로 복원되었습니다."
            fi
        else
            read -p "프로젝트로 복원하시겠습니까? (Y/n): " confirm
            if [ "$confirm" != "n" ] && [ "$confirm" != "N" ]; then
                mkdir -p "$PROJECT_DIR"
                cp "$selected_backup" "$PROJECT_DIR/$COMMAND_FILE"
                print_success "프로젝트로 복원되었습니다."
            fi
        fi
    else
        print_error "잘못된 선택입니다."
    fi
}

# 설정 편집
edit_config() {
    echo -e "${BOLD}${EMOJI_CONFIG} AI Commit 기본 설정${NC}"
    echo ""
    echo "1) 기본 언어: $DEFAULT_LANG"
    echo "2) 기본 이모지 사용: $DEFAULT_EMOJI"
    echo "3) 기본 분리 커밋: $DEFAULT_SPLIT"
    echo "4) 기본 상세 모드: $DEFAULT_DETAIL"
    echo "5) 기본 자동 스테이징: $DEFAULT_AUTO"
    echo "6) 돌아가기"
    echo ""
    
    read -p "변경할 항목 (1-6): " choice
    
    case $choice in
        1)
            echo ""
            echo "언어 선택: 1) kr (한글)  2) en (영문)"
            read -p "선택: " lang_choice
            case $lang_choice in
                1) DEFAULT_LANG="kr" ;;
                2) DEFAULT_LANG="en" ;;
                *) print_error "잘못된 선택입니다." ;;
            esac
            ;;
        2)
            DEFAULT_EMOJI=$([ "$DEFAULT_EMOJI" = "true" ] && echo "false" || echo "true")
            ;;
        3)
            DEFAULT_SPLIT=$([ "$DEFAULT_SPLIT" = "true" ] && echo "false" || echo "true")
            ;;
        4)
            DEFAULT_DETAIL=$([ "$DEFAULT_DETAIL" = "true" ] && echo "false" || echo "true")
            ;;
        5)
            DEFAULT_AUTO=$([ "$DEFAULT_AUTO" = "true" ] && echo "false" || echo "true")
            ;;
        6)
            return
            ;;
    esac
    
    # 설정 저장
    cat > "$CONFIG_FILE" << EOF
# AI Commit 기본 설정
DEFAULT_LANG="$DEFAULT_LANG"
DEFAULT_EMOJI="$DEFAULT_EMOJI"
DEFAULT_SPLIT="$DEFAULT_SPLIT"
DEFAULT_DETAIL="$DEFAULT_DETAIL"
DEFAULT_AUTO="$DEFAULT_AUTO"
AUTO_UPDATE_CHECK="$AUTO_UPDATE_CHECK"
LAST_UPDATE_CHECK="$LAST_UPDATE_CHECK"
EOF
    
    print_success "설정이 저장되었습니다."
    
    # 기존 설치 파일 업데이트 제안
    echo ""
    read -p "기존 설치된 명령어도 새 설정으로 업데이트하시겠습니까? (Y/n): " update_existing
    if [ "$update_existing" != "n" ] && [ "$update_existing" != "N" ]; then
        if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
            create_markdown_content "true" > "$GLOBAL_DIR/$COMMAND_FILE"
            print_success "글로벌 명령어가 업데이트되었습니다."
        fi
        if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
            create_markdown_content "false" > "$PROJECT_DIR/$COMMAND_FILE"
            print_success "프로젝트 명령어가 업데이트되었습니다."
        fi
    fi
}

# 글로벌 설치
install_global() {
    print_info "글로벌 설치를 시작합니다..."
    
    # 기존 파일 백업
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        create_backup "global"
    fi
    
    # 디렉토리 생성
    mkdir -p "$GLOBAL_DIR"
    
    # Markdown 파일 생성
    create_markdown_content "true" > "$GLOBAL_DIR/$COMMAND_FILE"
    
    print_success "글로벌 설치가 완료되었습니다!"
    print_info "설치 위치: $GLOBAL_DIR/$COMMAND_FILE"
    echo ""
    echo -e "${CYAN}사용 방법:${NC}"
    echo -e "  ${BOLD}/user:ai-commit${NC} - 기본 사용"
    echo -e "  ${BOLD}/user:aic${NC} - 짧은 별칭"
    echo ""
    print_warning "Claude Code를 재시작해야 명령어를 사용할 수 있습니다."
    
    # macOS에서 Claude Code 재시작 안내
    if [ "$IS_MACOS" = true ]; then
        echo ""
        print_info "macOS에서 Claude Code 재시작:"
        print_dim "  1) Cmd+Q로 Claude Code 완전 종료"
        print_dim "  2) Spotlight(Cmd+Space)에서 Claude Code 재실행"
    fi
}

# 프로젝트 설치
install_project() {
    # Git 저장소 확인
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_error "현재 디렉토리는 Git 저장소가 아닙니다!"
        print_info "Git 저장소에서 실행해주세요."
        return
    fi
    
    print_info "프로젝트 설치를 시작합니다..."
    
    # 기존 파일 백업
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        create_backup "project"
    fi
    
    # 디렉토리 생성
    mkdir -p "$PROJECT_DIR"
    
    # Markdown 파일 생성
    create_markdown_content "false" > "$PROJECT_DIR/$COMMAND_FILE"
    
    # .gitignore에 추가 제안
    if [ -f ".gitignore" ]; then
        if ! grep -q "^.claude/" .gitignore; then
            echo ""
            read -p "${EMOJI_INFO} .gitignore에 .claude/ 디렉토리를 추가하시겠습니까? (Y/n): " ADD_GITIGNORE
            if [ "$ADD_GITIGNORE" != "n" ] && [ "$ADD_GITIGNORE" != "N" ]; then
                echo ".claude/" >> .gitignore
                print_success ".gitignore에 추가되었습니다."
            fi
        fi
    fi
    
    print_success "프로젝트 설치가 완료되었습니다!"
    print_info "설치 위치: $PROJECT_DIR/$COMMAND_FILE"
    echo ""
    echo -e "${CYAN}사용 방법:${NC}"
    echo -e "  ${BOLD}/project:ai-commit${NC} - 프로젝트 명령어"
    echo -e "  ${BOLD}/project:aic${NC} - 짧은 별칭"
}

# 글로벌 삭제
uninstall_global() {
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        # 백업 생성
        create_backup "global"
        
        print_warning "글로벌 AI Commit을 삭제합니다..."
        rm -f "$GLOBAL_DIR/$COMMAND_FILE"
        
        # 디렉토리가 비어있으면 삭제
        if [ -d "$GLOBAL_DIR" ] && [ -z "$(ls -A "$GLOBAL_DIR" 2>/dev/null)" ]; then
            rmdir "$GLOBAL_DIR" 2>/dev/null || true
        fi
        
        print_success "글로벌 AI Commit이 삭제되었습니다."
        print_dim "백업은 $BACKUP_DIR에 저장되었습니다."
    else
        print_info "글로벌에 설치된 AI Commit이 없습니다."
    fi
}

# 프로젝트 삭제
uninstall_project() {
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        # 백업 생성
        create_backup "project"
        
        print_warning "프로젝트 AI Commit을 삭제합니다..."
        rm -f "$PROJECT_DIR/$COMMAND_FILE"
        
        # 디렉토리가 비어있으면 삭제
        if [ -d "$PROJECT_DIR" ] && [ -z "$(ls -A "$PROJECT_DIR" 2>/dev/null)" ]; then
            rmdir "$PROJECT_DIR" 2>/dev/null || true
            # 상위 .claude 디렉토리도 비어있으면 삭제
            if [ -d ".claude" ] && [ -z "$(ls -A ".claude" 2>/dev/null)" ]; then
                rmdir ".claude" 2>/dev/null || true
            fi
        fi
        
        print_success "프로젝트 AI Commit이 삭제되었습니다."
        print_dim "백업은 $BACKUP_DIR에 저장되었습니다."
    else
        print_info "프로젝트에 설치된 AI Commit이 없습니다."
    fi
}

# 설치 상태 표시
show_status() {
    local status=$(check_installation)
    IFS='|' read -r global_installed project_installed global_version project_version <<< "$status"
    
    echo ""
    echo -e "${BOLD}📊 설치 상태:${NC}"
    echo ""
    
    if [ "$global_installed" = "true" ]; then
        echo -e "${GREEN}${EMOJI_GLOBAL} 글로벌: 설치됨 (v$global_version)${NC}"
        echo -e "${DIM}   위치: $GLOBAL_DIR/$COMMAND_FILE${NC}"
        echo -e "${DIM}   사용: /user:ai-commit 또는 /user:aic${NC}"
    else
        echo -e "${YELLOW}${EMOJI_GLOBAL} 글로벌: 미설치${NC}"
    fi
    
    echo ""
    
    if [ "$project_installed" = "true" ]; then
        echo -e "${GREEN}${EMOJI_LOCAL} 프로젝트: 설치됨 (v$project_version)${NC}"
        echo -e "${DIM}   위치: $PROJECT_DIR/$COMMAND_FILE${NC}"
        echo -e "${DIM}   사용: /project:ai-commit 또는 /project:aic${NC}"
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local repo_name=$(basename "$(git rev-parse --show-toplevel)")
            echo -e "${DIM}   저장소: $repo_name${NC}"
        fi
    else
        echo -e "${YELLOW}${EMOJI_LOCAL} 프로젝트: 미설치${NC}"
    fi
    
    echo ""
}

# 사용법 표시
show_usage() {
    echo -e "${BOLD}Claude Code 슬래시 명령어 사용법:${NC}"
    echo ""
    echo -e "${BOLD}글로벌 명령어 (모든 프로젝트):${NC}"
    echo -e "${CYAN}/user:ai-commit -h${NC}            # 도움말 표시"
    echo -e "${CYAN}/user:ai-commit${NC}               # 기본 사용 (한글)"
    echo -e "${CYAN}/user:ai-commit --auto${NC}        # 모든 변경사항 자동 스테이징"
    echo -e "${CYAN}/user:ai-commit --quick${NC}       # 자동 스테이징 + 확인 없이 커밋"
    echo -e "${CYAN}/user:ai-commit --lang en${NC}     # 영문 메시지"
    echo -e "${CYAN}/user:ai-commit --emoji${NC}       # 이모지 포함"
    echo -e "${CYAN}/user:ai-commit --detail${NC}      # 상세 분석"
    echo -e "${CYAN}/user:ai-commit --split${NC}       # 변경사항 분리"
    echo -e "${CYAN}/user:ai-commit --push${NC}        # 커밋 후 자동 push"
    echo -e "${CYAN}/user:ai-commit --dry-run${NC}     # 메시지만 생성 (커밋 안함)"
    echo ""
    echo -e "${BOLD}프로젝트 명령어 (현재 프로젝트):${NC}"
    echo -e "${CYAN}/project:ai-commit${NC}            # 프로젝트별 설정 사용"
    echo -e "${CYAN}/project:aic${NC}                  # 짧은 별칭"
    echo ""
    echo -e "${BOLD}별칭:${NC}"
    echo -e "${CYAN}/user:aic${NC}                     # /user:ai-commit의 짧은 버전"
    echo -e "${CYAN}/user:aic -h${NC}                  # 도움말 표시"
    echo ""
    echo -e "${BOLD}빠른 커밋 예시:${NC}"
    echo -e "${GREEN}/user:aic --quick${NC}             # 즉시 커밋 (확인 없음)"
    echo -e "${GREEN}/user:aic --quick --push${NC}      # 즉시 커밋 후 push"
    echo ""
    echo -e "${BOLD}기타 예시:${NC}"
    echo -e "${DIM}/user:ai-commit --auto --push     # 자동 스테이징 후 push${NC}"
    echo -e "${DIM}/user:ai-commit --lang en --emoji # 영문 + 이모지${NC}"
    echo -e "${DIM}/user:aic --dry-run              # 미리보기만${NC}"
    echo -e "${DIM}/project:aic --push              # 프로젝트 설정으로 커밋 후 push${NC}"
    echo ""
}

# 명령어 테스트
test_commands() {
    echo -e "${BOLD}${EMOJI_INFO} 설치된 명령어 테스트${NC}"
    echo ""
    
    local found_any=false
    
    # 글로벌 명령어 확인
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        echo -e "${GREEN}✓ 글로벌 명령어 발견:${NC}"
        echo -e "  ${CYAN}$GLOBAL_DIR/$COMMAND_FILE${NC}"
        echo -e "  크기: $(ls -lh "$GLOBAL_DIR/$COMMAND_FILE" | awk '{print $5}')"
        echo -e "  수정일: $(ls -lh "$GLOBAL_DIR/$COMMAND_FILE" | awk '{print $6, $7, $8}')"
        found_any=true
        echo ""
    fi
    
    # 프로젝트 명령어 확인
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        echo -e "${GREEN}✓ 프로젝트 명령어 발견:${NC}"
        echo -e "  ${CYAN}$PROJECT_DIR/$COMMAND_FILE${NC}"
        echo -e "  크기: $(ls -lh "$PROJECT_DIR/$COMMAND_FILE" | awk '{print $5}')"
        echo -e "  수정일: $(ls -lh "$PROJECT_DIR/$COMMAND_FILE" | awk '{print $6, $7, $8}')"
        found_any=true
        echo ""
    fi
    
    if [ "$found_any" = false ]; then
        echo -e "${YELLOW}설치된 명령어가 없습니다.${NC}"
    else
        echo -e "${BOLD}Claude Code에서 테스트:${NC}"
        echo "1. Claude Code 재시작 (Cmd+Q → 재실행)"
        echo "2. 터미널에서 '/' 입력"
        echo "3. 명령어 목록에서 'user:ai-commit' 확인"
        echo "4. 없으면 Claude Code 새로고침 (Cmd+R)"
    fi
    echo ""
}

# 메인 메뉴
show_menu() {
    local status=$(check_installation)
    IFS='|' read -r global_installed project_installed global_version project_version <<< "$status"
    
    echo -e "${BOLD}원하는 작업을 선택하세요:${NC}"
    echo ""
    
    # 설치/삭제 옵션
    if [ "$global_installed" = "true" ]; then
        echo -e "${RED}1) ${EMOJI_TRASH} 글로벌 AI Commit 삭제${NC}"
    else
        echo -e "${GREEN}1) ${EMOJI_GLOBAL} 글로벌 설치 (모든 프로젝트에서 사용)${NC}"
    fi
    
    if [ "$project_installed" = "true" ]; then
        echo -e "${RED}2) ${EMOJI_TRASH} 프로젝트 AI Commit 삭제${NC}"
    else
        echo -e "${BLUE}2) ${EMOJI_LOCAL} 프로젝트 설치 (현재 프로젝트만)${NC}"
    fi
    
    echo ""
    echo "3) ${EMOJI_INFO} 사용법 보기"
    echo "4) ${EMOJI_CONFIG} 기본 설정 변경"
    echo "5) ${EMOJI_BACKUP} 백업 관리"
    echo "6) 🧪 명령어 테스트"
    echo "7) 🔄 새로고침"
    echo "8) ❌ 종료"
    echo ""
}

# 백업 관리 메뉴
backup_menu() {
    while true; do
        echo ""
        echo -e "${BOLD}${EMOJI_BACKUP} 백업 관리${NC}"
        echo ""
        echo "1) 현재 설정 백업"
        echo "2) 백업 복원"
        echo "3) 백업 목록 보기"
        echo "4) 백업 삭제"
        echo "5) 돌아가기"
        echo ""
        
        read -p "선택 (1-5): " choice
        
        case $choice in
            1)
                echo ""
                echo "백업할 대상:"
                echo "1) 글로벌 설정"
                echo "2) 프로젝트 설정"
                echo "3) 취소"
                read -p "선택: " backup_choice
                case $backup_choice in
                    1) create_backup "global" ;;
                    2) create_backup "project" ;;
                esac
                ;;
            2)
                restore_backup
                ;;
            3)
                if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
                    echo ""
                    echo -e "${BOLD}백업 목록:${NC}"
                    ls -lt "$BACKUP_DIR"/*.md 2>/dev/null | awk '{print $9}' | xargs -n1 basename
                else
                    print_warning "백업이 없습니다."
                fi
                ;;
            4)
                if [ -d "$BACKUP_DIR" ] && [ -n "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
                    read -p "${EMOJI_WARNING} 모든 백업을 삭제하시겠습니까? (y/N): " confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        rm -rf "$BACKUP_DIR"
                        print_success "모든 백업이 삭제되었습니다."
                    fi
                else
                    print_info "삭제할 백업이 없습니다."
                fi
                ;;
            5)
                return
                ;;
        esac
        
        if [ "$choice" != "5" ]; then
            echo ""
            read -p "계속하려면 Enter를 누르세요..."
        fi
    done
}

# 메인 실행
main() {
    # 설정 초기화
    init_config
    
    print_banner
    
    while true; do
        show_status
        show_menu
        
        read -p "선택 (1-8): " choice
        echo ""
        
        case $choice in
            1)
                local status=$(check_installation)
                IFS='|' read -r global_installed project_installed <<< "$status"
                
                if [ "$global_installed" = "true" ]; then
                    read -p "${EMOJI_WARNING} 정말로 글로벌 AI Commit을 삭제하시겠습니까? (y/N): " confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        uninstall_global
                    else
                        print_info "삭제가 취소되었습니다."
                    fi
                else
                    install_global
                fi
                ;;
            2)
                local status=$(check_installation)
                IFS='|' read -r global_installed project_installed <<< "$status"
                
                if [ "$project_installed" = "true" ]; then
                    read -p "${EMOJI_WARNING} 정말로 프로젝트 AI Commit을 삭제하시겠습니까? (y/N): " confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        uninstall_project
                    else
                        print_info "삭제가 취소되었습니다."
                    fi
                else
                    install_project
                fi
                ;;
            3)
                show_usage
                ;;
            4)
                edit_config
                ;;
            5)
                backup_menu
                ;;
            6)
                test_commands
                ;;
            7)
                print_banner
                print_info "새로고침 중..."
                sleep 0.5
                print_banner
                ;;
            8)
                print_info "AI Commit Manager를 종료합니다."
                echo -e "${CYAN}${EMOJI_ROCKET} Happy Coding!${NC}"
                exit 0
                ;;
            *)
                print_error "잘못된 선택입니다. 다시 선택해주세요."
                ;;
        esac
        
        echo ""
        read -p "계속하려면 Enter를 누르세요..."
        print_banner
    done
}

# 스크립트 실행
main