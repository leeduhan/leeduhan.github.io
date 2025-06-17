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
EMOJI_QUICK="⚡"

# 스크립트 정보
SCRIPT_VERSION="3.3.0"
SCRIPT_NAME="AI Commit Manager"

# Claude Code 디렉토리 경로 (Markdown 기반)
GLOBAL_DIR="$HOME/.claude/commands"
PROJECT_DIR=".claude/commands"
BACKUP_DIR="$HOME/.claude/backups"
COMMAND_FILE="ai-commit.md"
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
        echo "🔧 첫 실행: 기본 설정을 생성합니다..."
        
        # 설정 파일의 디렉토리 생성
        local config_dir=$(dirname "$CONFIG_FILE")
        mkdir -p "$config_dir"
        
        # 설정 파일 생성
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
        
        if [ -f "$CONFIG_FILE" ]; then
            print_success "설정 파일이 생성되었습니다: $CONFIG_FILE"
        else
            print_error "설정 파일 생성에 실패했습니다."
            print_info "기본값으로 진행합니다."
            # 기본값 설정
            DEFAULT_LANG="kr"
            DEFAULT_EMOJI="false"
            DEFAULT_SPLIT="true"
            DEFAULT_DETAIL="false"
            DEFAULT_AUTO="false"
            AUTO_UPDATE_CHECK="true"
            LAST_UPDATE_CHECK="$(get_timestamp)"
            return
        fi
    fi
    
    # 설정 파일 로드
    if [ -f "$CONFIG_FILE" ]; then
        source "$CONFIG_FILE"
    fi
}

# 배너 출력
print_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << 'EOF'
    ╔══════════════════════════════════════════════╗
    ║                                              ║
    ║      🤖 Claude Code AI Commit Manager 🤖     ║
    ║               Version 3.3.0                  ║
    ║         Auto-Split Commit System! ⚡        ║
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

# AI Commit (Quick Commit) Markdown 내용 생성
create_ai_commit_content() {
    local is_global=$1
    local lang=${2:-$DEFAULT_LANG}
    local emoji=${3:-$DEFAULT_EMOJI}
    local split=${4:-$DEFAULT_SPLIT}
    local detail=${5:-$DEFAULT_DETAIL}
    local auto=${6:-$DEFAULT_AUTO}
    
    cat << 'EOF'
# AI Commit

변경사항을 작업 내역별로 자동 분리하여 개별 커밋 메시지를 생성하고 순차적으로 커밋합니다.

## 사용법
```
/user:ai-commit                # 기본 사용 (자동 분리 커밋)
/user:ai-commit --push         # 커밋 후 자동 push
/user:ai-commit --dry-run      # 메시지만 생성 (커밋 안함)
/user:ai-commit --lang en      # 영문 메시지
/user:ai-commit --emoji        # 이모지 포함
/user:ai-commit --single       # 모든 변경사항을 하나의 커밋으로 통합
```

## 별칭
- `/user:aic` - 짧은 버전

## 빠른 사용
- `/user:aic` - 작업 내역별 자동 분리 커밋
- `/user:aic --push` - 분리 커밋 후 자동 push

## 명령어 실행 내용

Git 저장소의 변경사항을 작업 내역별로 자동 분석하여 개별 커밋을 순차적으로 수행하세요.

### 1. Git 저장소 확인
```bash
git rev-parse --is-inside-work-tree 2>/dev/null
```
Git 저장소가 아니면 에러 메시지를 출력하고 종료하세요.

### 2. 변경사항 분석 및 그룹화
`git status --porcelain`과 `git diff`를 사용하여 변경사항을 분석하고 다음 기준으로 그룹화:

**그룹화 기준:**
1. **파일 경로별 그룹화**
   - 같은 디렉토리나 모듈의 파일들
   - components/, pages/, utils/, api/ 등

2. **변경 타입별 그룹화**
   - 새 파일 추가 (untracked)
   - 기존 파일 수정 (modified)
   - 파일 삭제 (deleted)
   - 파일 이름 변경 (renamed)

3. **기능별 그룹화**
   - 관련된 기능의 파일들 함께 그룹화
   - import/export 관계가 있는 파일들
   - 테스트 파일과 구현 파일

### 3. 각 그룹별 작업 내역 요약
각 그룹에 대해 다음을 생성:

**요약 형식:**
```
📁 그룹명: [파일 경로들]
📝 작업 내역:
- 주요 변경사항 1
- 주요 변경사항 2
- 주요 변경사항 3

📋 상세 변경 내용:
파일명1:
  + 추가된 기능
  ~ 수정된 기능
  - 삭제된 기능

파일명2:
  + 새로운 컴포넌트 생성
  ~ props 인터페이스 수정
```

### 4. 커밋 메시지 생성 규칙
각 그룹별로 Conventional Commits 형식의 메시지 생성:

**타입 결정:**
- feat: 새 기능, 새 컴포넌트, 새 API
- fix: 버그 수정, 에러 처리
- refactor: 코드 구조 개선, 리팩토링
- style: CSS, 스타일링 변경
- test: 테스트 코드 추가/수정
- docs: 문서, 주석 추가/수정
- chore: 설정, 빌드, 패키지 관리

**스코프 결정:**
- 파일 경로 기반: components, pages, api, utils
- 기능 기반: auth, payment, dashboard, profile

**메시지 형식:**
```
타입(스코프): 요약 (50자 이내)

- 상세 변경사항 1
- 상세 변경사항 2
- 상세 변경사항 3
```

### 5. 자동 스테이징 및 커밋 프로세스
1. **변경사항 미리보기**
   - 발견된 모든 그룹과 커밋 메시지 표시
   - 사용자에게 진행 여부 확인

2. **순차적 커밋 실행**
   - 그룹별로 파일 스테이징: `git add [파일들]`
   - 커밋 메시지로 커밋: `git commit -m "메시지"`
   - 다음 그룹으로 진행

3. **진행상황 표시**
   - 현재 커밋 중인 그룹 표시
   - 전체 진행률 표시
   - 완료된 커밋 정보 표시

### 6. 실행 예시

**기본 사용:**
```
⚡ AI Commit - 작업 내역 분석 중...

📊 발견된 변경사항 그룹:

1️⃣ 그룹 1: 사용자 인증 기능
📁 파일: src/components/Login.tsx, src/hooks/useAuth.ts
📝 커밋 메시지: feat(auth): 사용자 로그인 및 인증 훅 구현

- JWT 토큰 기반 로그인 구현
- 사용자 상태 관리 훅 추가
- 로그인 폼 컴포넌트 개발

2️⃣ 그룹 2: API 연동
📁 파일: src/api/auth.ts, src/types/user.ts
📝 커밋 메시지: feat(api): 인증 API 엔드포인트 및 타입 정의

- 로그인/로그아웃 API 함수 구현
- 사용자 타입 인터페이스 정의
- 에러 처리 로직 추가

3️⃣ 그룹 3: 스타일링
📁 파일: src/styles/login.css
📝 커밋 메시지: style(auth): 로그인 페이지 스타일링

- 반응형 로그인 폼 디자인
- 버튼 및 입력 필드 스타일
- 에러 메시지 표시 스타일

총 3개 그룹, 6개 파일이 개별 커밋됩니다.
진행하시겠습니까? (Y/n): 

✅ 그룹 1 커밋 완료: feat(auth): 사용자 로그인 및 인증 훅 구현
✅ 그룹 2 커밋 완료: feat(api): 인증 API 엔드포인트 및 타입 정의  
✅ 그룹 3 커밋 완료: style(auth): 로그인 페이지 스타일링

🎉 총 3개의 커밋이 성공적으로 완료되었습니다!
```

**Dry-run 모드:**
```
⚡ AI Commit (Dry-run) - 커밋 시뮬레이션

📋 생성될 커밋 미리보기:

Commit 1: feat(dashboard): 대시보드 차트 컴포넌트 추가
Files: src/components/Chart.tsx, src/hooks/useChartData.ts

Commit 2: test(dashboard): 차트 컴포넌트 단위 테스트
Files: src/components/__tests__/Chart.test.tsx

Commit 3: docs: 차트 컴포넌트 사용 가이드 추가
Files: docs/components/chart.md

💡 실제 커밋을 하려면 --dry-run 옵션을 제거하고 다시 실행하세요.
```

**단일 커밋 모드 (--single):**
```
📦 모든 변경사항을 하나의 커밋으로 통합합니다...

✨ 생성된 커밋 메시지:
feat(auth): 사용자 인증 시스템 구현

- 로그인/로그아웃 기능 추가
- JWT 토큰 기반 인증 구현  
- 사용자 상태 관리 훅 개발
- API 엔드포인트 및 타입 정의
- 로그인 페이지 UI/UX 구현

이 메시지로 커밋하시겠습니까? (Y/n/e[dit]):
```

### 7. 커밋 후 처리
- 각 커밋의 해시와 메시지 표시
- push 옵션 사용시 모든 커밋 완료 후 자동 push
- 다음 단계 제안 (PR 생성 등)

### 8. 그룹화 알고리즘

**스마트 그룹화:**
1. 파일 의존성 분석 (import/export)
2. 디렉토리 구조 기반 그룹화
3. 파일명 패턴 매칭
4. 변경 내용 유사성 분석

**예시 그룹화:**
- `UserProfile.tsx` + `UserProfile.test.tsx` → 같은 그룹
- `api/users.ts` + `types/user.ts` → API 관련 그룹
- `components/` 내 여러 파일 → UI 컴포넌트 그룹

### 9. 에러 처리
- 커밋 중 오류 발생시 롤백 옵션 제공
- pre-commit hook 실패시 그룹 건너뛰기
- 병합 충돌 상태에서는 실행 중단

## 옵션 설명

### 기본 옵션
- `--push`: 모든 커밋 완료 후 자동으로 원격 저장소에 push
- `--dry-run`: 실제 커밋하지 않고 미리보기만 표시
- `--lang en`: 영문 커밋 메시지 생성
- `--emoji`: 커밋 타입별 이모지 추가
- `--single`: 모든 변경사항을 하나의 커밋으로 통합

### 조합 예시
- `/user:aic`: 기본 자동 분리 커밋
- `/user:aic --push`: 분리 커밋 후 push (가장 일반적)
- `/user:ai-commit --single --emoji --push`: 단일 커밋 + 이모지 + push
- `/user:ai-commit --lang en --dry-run`: 영문 미리보기

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

# Quick Commit Markdown 내용 생성 (제거됨 - AI Commit에 통합)

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
        
        # 파일명에서 타입 결정
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
            create_ai_commit_content "true" > "$GLOBAL_DIR/$COMMAND_FILE"
            print_success "글로벌 AI Commit 명령어가 업데이트되었습니다."
        fi
        if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
            create_ai_commit_content "false" > "$PROJECT_DIR/$COMMAND_FILE"
            print_success "프로젝트 AI Commit 명령어가 업데이트되었습니다."
        fi
    fi
}

# 글로벌 설치
install_global() {
    print_info "글로벌 AI Commit 설치를 시작합니다..."
    
    # 기존 파일 백업
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        create_backup "global"
    fi
    
    # 디렉토리 생성
    mkdir -p "$GLOBAL_DIR"
    
    # Markdown 파일 생성
    create_ai_commit_content "true" > "$GLOBAL_DIR/$COMMAND_FILE"
    
    print_success "글로벌 AI Commit 설치가 완료되었습니다!"
    print_info "설치 위치: $GLOBAL_DIR/$COMMAND_FILE"
    echo ""
    echo -e "${CYAN}사용 방법:${NC}"
    echo -e "  ${BOLD}/user:ai-commit${NC} - 자동 분리 커밋"
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
    
    print_info "프로젝트 AI Commit 설치를 시작합니다..."
    
    # 기존 파일 백업
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        create_backup "project"
    fi
    
    # 디렉토리 생성
    mkdir -p "$PROJECT_DIR"
    
    # Markdown 파일 생성
    create_ai_commit_content "false" > "$PROJECT_DIR/$COMMAND_FILE"
    
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
    
    print_success "프로젝트 AI Commit 설치가 완료되었습니다!"
    print_info "설치 위치: $PROJECT_DIR/$COMMAND_FILE"
    echo ""
    echo -e "${CYAN}사용 방법:${NC}"
    echo -e "  ${BOLD}/project:ai-commit${NC} - 프로젝트 명령어"
    echo -e "  ${BOLD}/project:aic${NC} - 짧은 별칭"
}

# 글로벌 삭제
uninstall_global() {
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        print_warning "글로벌 AI Commit을 삭제합니다..."
        rm -f "$GLOBAL_DIR/$COMMAND_FILE"
        print_success "글로벌 AI Commit이 삭제되었습니다."
    else
        print_info "글로벌에 설치된 AI Commit이 없습니다."
    fi
}

# 프로젝트 삭제
uninstall_project() {
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        print_warning "프로젝트 AI Commit을 삭제합니다..."
        rm -f "$PROJECT_DIR/$COMMAND_FILE"
        print_success "프로젝트 AI Commit이 삭제되었습니다."
    else
        print_info "프로젝트에 설치된 AI Commit이 없습니다."
    fi
}

# 설정 파일 정리
cleanup_config() {
    # 글로벌과 프로젝트가 모두 삭제된 경우에만 설정 파일 삭제
    if [ ! -f "$GLOBAL_DIR/$COMMAND_FILE" ] && [ ! -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        if [ -f "$CONFIG_FILE" ]; then
            rm -f "$CONFIG_FILE"
            print_info "설정 파일도 삭제되었습니다."
        fi
    fi
}

# 설치 상태 표시
show_status() {
    local global_installed=$1
    local project_installed=$2
    local global_version=$3
    local project_version=$4
    
    echo ""
    echo -e "${BOLD}📊 설치 상태:${NC}"
    echo ""
    
    # AI Commit 상태
    echo -e "${BOLD}🤖 AI Commit (자동 분리 커밋):${NC}"
    if [ "$global_installed" = "true" ]; then
        echo -e "${GREEN}  ${EMOJI_GLOBAL} 글로벌: 설치됨 (v$global_version)${NC}"
        echo -e "${DIM}     사용: /user:ai-commit 또는 /user:aic${NC}"
    else
        echo -e "${YELLOW}  ${EMOJI_GLOBAL} 글로벌: 미설치${NC}"
    fi
    
    if [ "$project_installed" = "true" ]; then
        echo -e "${GREEN}  ${EMOJI_LOCAL} 프로젝트: 설치됨 (v$project_version)${NC}"
        echo -e "${DIM}     사용: /project:ai-commit 또는 /project:aic${NC}"
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            local repo_name=$(basename "$(git rev-parse --show-toplevel)")
            echo -e "${DIM}     저장소: $repo_name${NC}"
        fi
    else
        echo -e "${YELLOW}  ${EMOJI_LOCAL} 프로젝트: 미설치${NC}"
    fi
    
    echo ""
}

# 사용법 표시
show_usage() {
    echo -e "${BOLD}Claude Code 슬래시 명령어 사용법:${NC}"
    echo ""
    
    echo -e "${BOLD}🤖 AI Commit (자동 분리 커밋):${NC}"
    echo -e "${CYAN}/user:ai-commit${NC}               # 기본 사용 (작업별 자동 분리)"
    echo -e "${CYAN}/user:ai-commit --push${NC}        # 분리 커밋 후 자동 push"
    echo -e "${CYAN}/user:ai-commit --dry-run${NC}     # 미리보기만 (커밋 안함)"
    echo -e "${CYAN}/user:ai-commit --lang en${NC}     # 영문 메시지"
    echo -e "${CYAN}/user:ai-commit --emoji${NC}       # 이모지 포함"
    echo -e "${CYAN}/user:ai-commit --single${NC}      # 모든 변경사항을 하나로 통합"
    echo ""
    
    echo -e "${BOLD}프로젝트 명령어 (현재 프로젝트):${NC}"
    echo -e "${CYAN}/project:ai-commit${NC}            # 프로젝트별 AI Commit"
    echo ""
    
    echo -e "${BOLD}별칭:${NC}"
    echo -e "${CYAN}/user:aic${NC}                     # /user:ai-commit의 짧은 버전"
    echo ""
    
    echo -e "${BOLD}추천 사용법:${NC}"
    echo -e "${GREEN}/user:aic${NC}                      # 기본 자동 분리 커밋"
    echo -e "${GREEN}/user:aic --push${NC}               # 분리 커밋 후 push"
    echo -e "${GREEN}/user:aic --single --push${NC}      # 단일 커밋 후 push"
    echo ""
    
    echo -e "${BOLD}특징:${NC}"
    echo -e "${DIM}• 작업 내역별로 자동 그룹화하여 개별 커밋 생성${NC}"
    echo -e "${DIM}• 파일 경로, 기능, 변경 타입에 따른 스마트 분리${NC}"
    echo -e "${DIM}• Conventional Commits 형식의 멀티라인 메시지${NC}"
    echo -e "${DIM}• Claude Code 생성 메시지 없는 깔끔한 커밋${NC}"
    echo ""
}

# 명령어 테스트
test_commands() {
    echo -e "${BOLD}${EMOJI_INFO} 설치된 명령어 테스트${NC}"
    echo ""
    
    local found_any=false
    
    # 글로벌 AI Commit 확인
    if [ -f "$GLOBAL_DIR/$COMMAND_FILE" ]; then
        echo -e "${GREEN}✓ 글로벌 AI Commit 발견:${NC}"
        echo -e "  ${CYAN}$GLOBAL_DIR/$COMMAND_FILE${NC}"
        echo -e "  크기: $(ls -lh "$GLOBAL_DIR/$COMMAND_FILE" | awk '{print $5}')"
        echo -e "  수정일: $(ls -lh "$GLOBAL_DIR/$COMMAND_FILE" | awk '{print $6, $7, $8}')"
        found_any=true
        echo ""
    fi
    
    # 프로젝트 AI Commit 확인
    if [ -f "$PROJECT_DIR/$COMMAND_FILE" ]; then
        echo -e "${GREEN}✓ 프로젝트 AI Commit 발견:${NC}"
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
    local global_installed=$1
    local project_installed=$2
    
    echo -e "${BOLD}원하는 작업을 선택하세요:${NC}"
    echo ""
    
    # AI Commit 옵션
    if [ "$global_installed" = "true" ]; then
        echo -e "${RED}1) ${EMOJI_TRASH} 글로벌 AI Commit 삭제${NC}"
    else
        echo -e "${GREEN}1) ${EMOJI_GLOBAL} 글로벌 AI Commit 설치${NC}"
    fi
    
    if [ "$project_installed" = "true" ]; then
        echo -e "${RED}2) ${EMOJI_TRASH} 프로젝트 AI Commit 삭제${NC}"
    else
        echo -e "${BLUE}2) ${EMOJI_LOCAL} 프로젝트 AI Commit 설치${NC}"
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
                echo "1) 글로벌 AI Commit"
                echo "2) 프로젝트 AI Commit"
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
    
    # 설정 파일 정보 표시
    echo -e "${DIM}설정 파일: $CONFIG_FILE${NC}"
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${DIM}설정 상태: ✅ 로드됨${NC}"
    else
        echo -e "${DIM}설정 상태: ⚠️ 기본값 사용${NC}"
    fi
    echo ""
    
    while true; do
        # 상태를 한 번만 체크하고 모든 곳에서 동일하게 사용
        local status=$(check_installation)
        IFS='|' read -r global_installed project_installed global_version project_version <<< "$status"
        
        show_status "$global_installed" "$project_installed" "$global_version" "$project_version"
        show_menu "$global_installed" "$project_installed"
        
        read -p "선택 (1-8): " choice
        echo ""
        
        case $choice in
            1)
                # 메뉴 표시와 동일한 상태 확인 사용
                if [ "$global_installed" = "true" ]; then
                    read -p "${EMOJI_WARNING} 정말로 글로벌 AI Commit을 삭제하시겠습니까? (y/N): " confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        uninstall_global
                        cleanup_config
                    else
                        print_info "삭제가 취소되었습니다."
                    fi
                else
                    install_global
                fi
                ;;
            2)
                # 메뉴 표시와 동일한 상태 확인 사용
                if [ "$project_installed" = "true" ]; then
                    read -p "${EMOJI_WARNING} 정말로 프로젝트 AI Commit을 삭제하시겠습니까? (y/N): " confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        uninstall_project
                        cleanup_config
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