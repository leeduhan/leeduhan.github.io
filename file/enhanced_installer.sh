#!/bin/bash
# Git Subcommands 전역 설치 스크립트 (macOS 최적화)
#
# 사용법:
# 
# 방법 1: 직접 실행 (권장)
#   curl -fsSL [스크립트-URL] | bash
#   wget -qO- [스크립트-URL] | bash
#
# 방법 2: 파일 다운로드 후 실행
#   curl -fsSL [스크립트-URL] -o install.sh
#   chmod +x install.sh
#   ./install.sh
#
# 방법 3: git clone 후 실행 (개발자용)
#   git clone [repository-URL]
#   cd [repository-name]
#   chmod +x install.sh
#   ./install.sh
#
# 방법 4: 통합 관리
#   curl -fsSL [스크립트-URL] -o install.sh
#   chmod +x install.sh
#   ./install.sh
#   # 실행 시 기존 설치 감지하여 업데이트/제거 옵션 제공

# 방법 5: 제거 스크립트 직접 실행
#   /usr/local/bin/git-tools-uninstall (또는 ~/.local/bin/git-tools-uninstall)

# macOS 호환성을 위한 설정
set -e
export LC_ALL=C

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 로그 함수들
header() { echo -e "\n${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${PURPLE}${BOLD}  $1${NC}"; echo -e "${PURPLE}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
log() { echo -e "${BLUE}🚀 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}ℹ️ $1${NC}"; }

# 전역 변수
TOOLS_VERSION="1.0.0"
TOOLS=("wt-jira" "wt-clean" "wt-list")

# macOS에 최적화된 검색 경로들
SEARCH_PATHS=(
    "/usr/local/bin"
    "/opt/homebrew/bin"
    "/usr/bin"
    "/bin"
    "$HOME/.local/bin"
    "/opt/bin"
)

# 명령줄 인수 처리 (호환성 유지)
case "$1" in
    --uninstall|-u)
        MODE="uninstall"
        ;;
    --search|-s)
        MODE="search"
        ;;
    --help|-h)
        echo "사용법: $0 [옵션]"
        echo ""
        echo "옵션:"
        echo "  (없음)          통합 관리 메뉴 (검색/설치/업데이트/제거)"
        echo "  --uninstall, -u 직접 제거 실행 (호환성)"
        echo "  --search, -s    직접 검색 실행 (호환성)"
        echo "  --help, -h      이 도움말 표시"
        echo ""
        echo "권장 사용법:"
        echo "  ./install.sh    # 통합 관리 메뉴"
        echo ""
        echo "설치 예시:"
        echo "  curl -fsSL [URL] | bash"
        echo "  ./install.sh"
        exit 0
        ;;
    *)
        MODE="install"
        ;;
esac

# ==========================================
# 설치된 환경 검색 함수
# ==========================================
search_installed_tools() {
    local search_mode="$1"  # "display" 또는 "collect"
    local found_tools=()
    local found_uninstall_scripts=()
    
    if [[ "$search_mode" == "display" ]]; then
        header "설치된 Git Subcommands 검색"
        log "시스템 전체에서 설치된 도구를 검색 중..."
        echo ""
    fi
    
    # 각 경로에서 도구 검색
    for search_path in "${SEARCH_PATHS[@]}"; do
        if [[ -d "$search_path" ]]; then
            local found_in_path=()
            
            # Git subcommand 검색
            for tool in "${TOOLS[@]}"; do
                local tool_path="$search_path/git-$tool"
                if [[ -f "$tool_path" ]] && [[ -x "$tool_path" ]]; then
                    found_in_path+=("$tool_path")
                    found_tools+=("$tool_path")
                fi
            done
            
            # 제거 스크립트 검색
            local uninstall_script="$search_path/git-tools-uninstall"
            if [[ -f "$uninstall_script" ]] && [[ -x "$uninstall_script" ]]; then
                found_uninstall_scripts+=("$uninstall_script")
            fi
            
            # 결과 출력 (display 모드일 때만)
            if [[ "$search_mode" == "display" ]] && [[ ${#found_in_path[@]} -gt 0 ]]; then
                echo -e "${CYAN}📁 $search_path${NC}"
                for tool_path in "${found_in_path[@]}"; do
                    local tool_name=$(basename "$tool_path")
                    local tool_version=$("$tool_path" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
                    echo -e "  ✅ $tool_name (버전: $tool_version)"
                done
                if [[ -f "$uninstall_script" ]]; then
                    echo -e "  🗑️ git-tools-uninstall (제거 스크립트)"
                fi
                echo ""
            fi
        fi
    done
    
    if [[ "$search_mode" == "display" ]]; then
        if [[ ${#found_tools[@]} -eq 0 ]]; then
            info "설치된 Git Subcommands를 찾을 수 없습니다."
            echo ""
            echo -e "${CYAN}💡 설치하려면:${NC}"
            echo "  curl -fsSL [스크립트-URL] | bash"
        else
            success "총 ${#found_tools[@]}개의 도구가 설치되어 있습니다."
            if [[ ${#found_uninstall_scripts[@]} -gt 0 ]]; then
                success "총 ${#found_uninstall_scripts[@]}개의 제거 스크립트가 있습니다."
            fi
            
            echo ""
            echo -e "${CYAN}🔧 관리 명령어:${NC}"
            echo "  $0               # 통합 관리 메뉴"
            echo "  git wt-jira --help        # 도구 사용법"
        fi
    fi
    
    # collect 모드일 때는 배열을 환경변수로 설정
    if [[ "$search_mode" == "collect" ]]; then
        FOUND_TOOLS=("${found_tools[@]}")
        FOUND_UNINSTALL_SCRIPTS=("${found_uninstall_scripts[@]}")
    fi
}

# ==========================================
# 제거 함수
# ==========================================
uninstall_all_tools() {
    header "모든 Git Subcommands 제거"
    
    # 설치된 도구 검색
    search_installed_tools "collect"
    
    if [[ ${#FOUND_TOOLS[@]} -eq 0 ]] && [[ ${#FOUND_UNINSTALL_SCRIPTS[@]} -eq 0 ]]; then
        info "제거할 Git Subcommands가 없습니다."
        echo ""
        echo -e "${CYAN}💡 설치하려면:${NC}"
        echo "  curl -fsSL [스크립트-URL] | bash"
        return 0
    fi
    
    log "제거 대상 확인 중..."
    echo ""
    
    # 발견된 도구들 표시
    if [[ ${#FOUND_TOOLS[@]} -gt 0 ]]; then
        echo -e "${CYAN}🔧 제거할 도구들:${NC}"
        for tool_path in "${FOUND_TOOLS[@]}"; do
            local tool_name=$(basename "$tool_path")
            local tool_dir=$(dirname "$tool_path")
            local tool_version=$("$tool_path" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
            echo -e "  📍 $tool_dir/$tool_name (버전: $tool_version)"
        done
        echo ""
    fi
    
    if [[ ${#FOUND_UNINSTALL_SCRIPTS[@]} -gt 0 ]]; then
        echo -e "${CYAN}🗑️ 제거할 제거 스크립트들:${NC}"
        for script_path in "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
            local script_dir=$(dirname "$script_path")
            echo -e "  📍 $script_dir/git-tools-uninstall"
        done
        echo ""
    fi
    
    # 권한 확인 및 경고
    local system_files=()
    local user_files=()
    
    for tool_path in "${FOUND_TOOLS[@]}" "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
        if [[ "$tool_path" == /usr/* ]] || [[ "$tool_path" == /bin/* ]] || [[ "$tool_path" == /opt/* ]]; then
            system_files+=("$tool_path")
        else
            user_files+=("$tool_path")
        fi
    done
    
    if [[ ${#system_files[@]} -gt 0 ]]; then
        warn "시스템 디렉토리의 파일 제거는 sudo 권한이 필요합니다:"
        for file in "${system_files[@]}"; do
            echo "  📍 $file"
        done
        echo ""
    fi
    
    if [[ ${#user_files[@]} -gt 0 ]]; then
        info "사용자 디렉토리의 파일들:"
        for file in "${user_files[@]}"; do
            echo "  📍 $file"
        done
        echo ""
    fi
    
    # 최종 확인
    echo -e "${YELLOW}⚠️ 정말로 모든 Git Subcommands를 제거하시겠습니까?${NC}"
    echo "이 작업은 되돌릴 수 없습니다."
    echo ""
    read -p "제거를 진행하시겠습니까? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "제거를 취소했습니다."
        return 0
    fi
    
    # 제거 실행
    log "제거 작업 시작..."
    echo ""
    
    local removed_count=0
    local failed_count=0
    
    # 도구들 제거
    for tool_path in "${FOUND_TOOLS[@]}"; do
        local tool_name=$(basename "$tool_path")
        local requires_sudo=false
        
        if [[ "$tool_path" == /usr/* ]] || [[ "$tool_path" == /bin/* ]] || [[ "$tool_path" == /opt/* ]]; then
            requires_sudo=true
        fi
        
        echo -n "  제거 중: $tool_name ... "
        
        if [[ "$requires_sudo" == "true" ]]; then
            if sudo rm -f "$tool_path" 2>/dev/null; then
                echo -e "${GREEN}✅ 완료${NC}"
                ((removed_count++))
            else
                echo -e "${RED}❌ 실패${NC}"
                ((failed_count++))
            fi
        else
            if rm -f "$tool_path" 2>/dev/null; then
                echo -e "${GREEN}✅ 완료${NC}"
                ((removed_count++))
            else
                echo -e "${RED}❌ 실패${NC}"
                ((failed_count++))
            fi
        fi
    done
    
    # 제거 스크립트들 제거
    for script_path in "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
        local requires_sudo=false
        
        if [[ "$script_path" == /usr/* ]] || [[ "$script_path" == /bin/* ]] || [[ "$script_path" == /opt/* ]]; then
            requires_sudo=true
        fi
        
        echo -n "  제거 중: git-tools-uninstall ... "
        
        if [[ "$requires_sudo" == "true" ]]; then
            if sudo rm -f "$script_path" 2>/dev/null; then
                echo -e "${GREEN}✅ 완료${NC}"
                ((removed_count++))
            else
                echo -e "${RED}❌ 실패${NC}"
                ((failed_count++))
            fi
        else
            if rm -f "$script_path" 2>/dev/null; then
                echo -e "${GREEN}✅ 완료${NC}"
                ((removed_count++))
            else
                echo -e "${RED}❌ 실패${NC}"
                ((failed_count++))
            fi
        fi
    done
    
    echo ""
    
    # 결과 요약
    if [[ $removed_count -gt 0 ]]; then
        success "$removed_count개 파일이 성공적으로 제거되었습니다."
    fi
    
    if [[ $failed_count -gt 0 ]]; then
        error "$failed_count개 파일 제거에 실패했습니다."
        echo ""
        echo -e "${CYAN}💡 실패 원인:${NC}"
        echo "  • 권한 부족 (sudo 권한 필요)"
        echo "  • 파일이 사용 중"
        echo "  • 파일 시스템 오류"
    fi
    
    if [[ $removed_count -gt 0 ]]; then
        echo ""
        echo -e "${CYAN}🎉 제거가 완료되었습니다!${NC}"
        echo ""
        echo -e "${CYAN}💡 다시 설치하려면:${NC}"
        echo "  curl -fsSL [스크립트-URL] | bash"
        echo "  또는"
        echo "  ./install.sh"
    fi
}

# ==========================================
# 메인 모드 분기
# ==========================================
case "$MODE" in
    search)
        search_installed_tools "display"
        exit 0
        ;;
    uninstall)
        uninstall_all_tools
        exit 0
        ;;
    install)
        # 기존 설치 로직 계속 진행
        ;;
esac

# 스크립트 시작
clear
header "Git Subcommands 전역 설치"

# 실행 방법 감지
SCRIPT_NAME="${BASH_SOURCE[0]}"
if [[ "$SCRIPT_NAME" == "/dev/fd/"* ]] || [[ "$SCRIPT_NAME" == "/proc/self/fd/"* ]]; then
    EXECUTION_METHOD="직접 실행 (curl/wget | bash)"
elif [[ "$SCRIPT_NAME" == *"install"* ]]; then
    EXECUTION_METHOD="파일 다운로드 후 실행"
else
    EXECUTION_METHOD="스크립트 파일 실행"
fi

info "실행 방법: $EXECUTION_METHOD"

echo -e "${CYAN}🎯 이 스크립트는 다음 Git subcommand를 전역으로 설치합니다:${NC}"
echo "  • git wt-jira <issue-key>     - Jira 워크트리 생성"
echo "  • git wt-clean                - 워크트리 선택 삭제"
echo "  • git wt-list                 - 워크트리 목록 보기"
echo ""
echo -e "${CYAN}✨ 설치 후 모든 Git 프로젝트에서 사용 가능합니다!${NC}"
echo ""

# 플랫폼 감지 (macOS 최적화)
PLATFORM=""
case "$(uname -s)" in
    Darwin*) 
        PLATFORM="macos" 
        # macOS 버전 확인
        MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || echo "unknown")
        ;;
    Linux*)  PLATFORM="linux" ;;
    CYGWIN*|MINGW*|MSYS*) PLATFORM="windows" ;;
    *) PLATFORM="unknown" ;;
esac

if [[ "$PLATFORM" == "macos" ]]; then
    info "플랫폼: macOS $MACOS_VERSION"
else
    info "플랫폼 감지: $PLATFORM"
fi

# ==========================================
# Phase 0: 기존 설치 자동 감지 및 관리
# ==========================================
header "Phase 0: 기존 설치 확인"

log "시스템에서 기존 Git Subcommands 설치를 확인 중..."

search_installed_tools "collect"

if [[ ${#FOUND_TOOLS[@]} -gt 0 ]]; then
    echo ""
    warn "⚠️ 기존 설치가 감지되었습니다!"
    echo ""
    echo -e "${CYAN}📋 발견된 설치:${NC}"
    
    # 설치 위치별로 표시 (macOS bash 3.x 호환)
    processed_locations=""
    
    for tool_path in "${FOUND_TOOLS[@]}"; do
        tool_name=$(basename "$tool_path")
        tool_dir=$(dirname "$tool_path")
        tool_version=$("$tool_path" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        
        # 이미 처리된 위치인지 확인 (문자열 매칭)
        if [[ "$processed_locations" != *"$tool_dir"* ]]; then
            processed_locations="$processed_locations|$tool_dir"
            
            location_type=""
            case "$tool_dir" in
                "/usr/local/bin")
                    location_type="시스템 전역 (Intel Mac)"
                    ;;
                "/opt/homebrew/bin")
                    location_type="Homebrew (Apple Silicon)"
                    ;;
                "/usr/bin")
                    location_type="시스템 기본"
                    ;;
                *".local/bin")
                    location_type="사용자 개인"
                    ;;
                *)
                    location_type="기타"
                    ;;
            esac
            
            echo "  📍 $tool_dir (${location_type})"
            
            # 해당 위치의 모든 도구 나열
            tools_list=""
            for other_tool_path in "${FOUND_TOOLS[@]}"; do
                if [[ "$(dirname "$other_tool_path")" == "$tool_dir" ]]; then
                    other_tool_name=$(basename "$other_tool_path")
                    other_tool_version=$("$other_tool_path" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
                    if [[ -z "$tools_list" ]]; then
                        tools_list="$other_tool_name (v$other_tool_version)"
                    else
                        tools_list="$tools_list, $other_tool_name (v$other_tool_version)"
                    fi
                fi
            done
            
            echo "     도구: $tools_list"
        fi
    done
    
    if [[ ${#FOUND_UNINSTALL_SCRIPTS[@]} -gt 0 ]]; then
        echo "  🗑️ 제거 스크립트: ${#FOUND_UNINSTALL_SCRIPTS[@]}개 발견"
    fi
    
    echo ""
    echo -e "${YELLOW}🤔 어떻게 처리하겠습니까?${NC}"
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}1. 🔄 업데이트${NC} - 기존 설치를 최신 버전으로 업데이트"
    echo -e "   • 기존 설치 위치 그대로 유지"
    echo -e "   • 설정과 환경 보존"
    echo -e "   • 빠르고 안전한 업그레이드"
    echo ""
    echo -e "${CYAN}${BOLD}2. 🗑️ 완전 제거${NC} - 모든 기존 설치를 깨끗하게 제거"
    echo -e "   • 시스템 전체에서 모든 Git Subcommands 제거"
    echo -e "   • 제거 스크립트까지 모두 정리"
    echo -e "   • 완전 초기화 후 새로 시작"
    echo ""
    echo -e "${CYAN}${BOLD}3. ➕ 추가 설치${NC} - 기존 설치는 그대로 두고 새 위치에 설치"
    echo -e "   • 기존 설치와 병존"
    echo -e "   • 다른 위치에 중복 설치"
    echo -e "   • 테스트나 백업 목적"
    echo ""
    echo -e "${CYAN}${BOLD}4. ❌ 취소${NC} - 아무것도 하지 않고 종료"
    echo -e "   • 현재 상태 그대로 유지"
    echo -e "   • 설치 프로세스 중단"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}💡 권장사항:${NC}"
    echo -e "   • ${BOLD}일반적인 경우${NC}: ${GREEN}1번 (업데이트)${NC} - 기존 설치를 최신 버전으로"
    echo -e "   • ${BOLD}문제가 있는 경우${NC}: ${RED}2번 (완전 제거)${NC} - 깨끗하게 다시 시작"
    echo -e "   • ${BOLD}테스트 목적${NC}: ${BLUE}3번 (추가 설치)${NC} - 기존과 별도로 설치"
    echo ""
    
    while true; do
        read -p "선택하세요 (1=업데이트, 2=완전제거, 3=추가설치, 4=취소): " -n 1 -r
        echo ""
        echo ""
        case $REPLY in
            1)
                success "🔄 업데이트 모드 선택"
                info "기존 설치를 최신 버전으로 업데이트합니다."
                INSTALL_MODE="update"
                break
                ;;
            2)
                warn "🗑️ 완전 제거 모드 선택"
                echo ""
                echo -e "${YELLOW}⚠️ 모든 Git Subcommands가 제거됩니다!${NC}"
                echo "제거할 항목들:"
                for tool_path in "${FOUND_TOOLS[@]}"; do
                    echo "  📍 $tool_path"
                done
                for script_path in "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
                    echo "  📍 $script_path"
                done
                echo ""
                read -p "정말로 모든 설치를 제거하시겠습니까? (y/N): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    echo ""
                    log "완전 제거를 실행합니다..."
                    uninstall_all_tools
                    echo ""
                    success "제거가 완료되었습니다."
                    echo ""
                    read -p "새로 설치하시겠습니까? (Y/n): " -n 1 -r
                    echo ""
                    if [[ $REPLY =~ ^[Nn]$ ]]; then
                        info "설치를 취소했습니다."
                        exit 0
                    else
                        success "새로운 설치를 시작합니다."
                        INSTALL_MODE="new"
                        break
                    fi
                else
                    info "제거를 취소했습니다. 다시 선택해주세요."
                    echo ""
                    continue
                fi
                ;;
            3)
                info "➕ 추가 설치 모드 선택"
                warn "기존 설치와 별도로 새로운 위치에 설치합니다."
                INSTALL_MODE="new"
                break
                ;;
            4)
                info "❌ 설치를 취소했습니다."
                exit 0
                ;;
            *)
                error "잘못된 선택입니다. 1, 2, 3, 4 중 하나를 입력해주세요."
                echo ""
                ;;
        esac
    done
else
    success "✨ 기존 설치가 없습니다."
    info "새로운 설치를 진행합니다."
    INSTALL_MODE="new"
fi

echo ""

# ==========================================
# Phase 1: 설치 목적 및 위치 선택
# ==========================================
header "Phase 1: 설치 목적 및 위치 선택"

# 설치 위치 결정
INSTALL_DIR=""
SUDO_CMD=""
INSTALL_TYPE=""
INSTALL_PURPOSE=""

if [[ $EUID -eq 0 ]]; then
    # 이미 root인 경우
    INSTALL_DIR="/usr/local/bin"
    SUDO_CMD=""
    INSTALL_TYPE="system"
    INSTALL_PURPOSE="system"
    success "Root 권한으로 실행 중 - 시스템 전역 설치"
else
    # 일반 사용자인 경우 - 목적별 옵션 제공
    echo -e "${CYAN}🎯 설치 목적에 따라 적절한 위치를 선택해주세요:${NC}"
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}${BOLD}1. 개발/테스트 환경${NC} ${CYAN}(개인 사용자)${NC}"
    echo -e "${GREEN}────────────────────────────────────────────────────────────────────${NC}"
    echo -e "   📍 설치 위치: ${BOLD}~/.local/bin/${NC}"
    echo -e "   🎯 용도: 개인 개발, 테스트, 실험"
    echo -e "   ✅ 장점:"
    echo -e "      • sudo 권한 불필요 (macOS 권한 문제 회피)"
    echo -e "      • 빠른 설치/제거"
    echo -e "      • 개인 환경에만 영향"
    echo -e "      • Homebrew와 충돌 없음"
    echo -e "   ⚠️ 단점:"
    echo -e "      • PATH 설정이 필요할 수 있음"
    echo -e "      • 현재 사용자만 사용 가능"
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}${BOLD}2. 운영/공유 환경${NC} ${CYAN}(팀/조직 전체)${NC}"
    echo -e "${GREEN}────────────────────────────────────────────────────────────────────${NC}"
    echo -e "   📍 설치 위치: ${BOLD}/usr/local/bin/${NC}"
    echo -e "   🎯 용도: 팀 공유, 운영 서버, CI/CD"
    echo -e "   ✅ 장점:"
    echo -e "      • 모든 사용자가 사용 가능"
    echo -e "      • 표준 macOS 위치"
    echo -e "      • PATH 설정 불필요"
    echo -e "      • 팀 표준화 도구로 활용"
    echo -e "   ⚠️ 단점:"
    echo -e "      • sudo 권한 필요"
    echo -e "      • macOS 권한 설정 주의 필요"
    echo ""
    echo -e "${GREEN}────────────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${CYAN}💡 권장사항:${NC}"
    echo -e "   • ${YELLOW}처음 사용${NC}하거나 ${YELLOW}개인 테스트${NC}인 경우 → ${BOLD}1번 (개발/테스트)${NC}"
    echo -e "   • ${YELLOW}팀에서 공유${NC}하거나 ${YELLOW}CI/CD${NC}에서 사용 → ${BOLD}2번 (운영/공유)${NC}"
    echo ""
    
    while true; do
        read -p "선택하세요 (1=개발/테스트, 2=운영/공유): " -n 1 -r
        echo ""
        case $REPLY in
            1)
                INSTALL_DIR="$HOME/.local/bin"
                SUDO_CMD=""
                INSTALL_TYPE="user"
                INSTALL_PURPOSE="development"
                echo ""
                success "📍 개발/테스트 환경 선택됨"
                info "설치 위치: $INSTALL_DIR"
                echo -e "${CYAN}✨ 개인 개발 환경에 최적화된 설치가 진행됩니다.${NC}"
                break
                ;;
            2)
                INSTALL_DIR="/usr/local/bin"
                SUDO_CMD="sudo"
                INSTALL_TYPE="system"
                INSTALL_PURPOSE="production"
                echo ""
                success "📍 운영/공유 환경 선택됨"
                info "설치 위치: $INSTALL_DIR"
                echo -e "${CYAN}🏢 팀 공유 환경에 최적화된 설치가 진행됩니다.${NC}"
                break
                ;;
            *)
                echo -e "${RED}잘못된 선택입니다. 1 또는 2를 선택해주세요.${NC}"
                ;;
        esac
    done
fi

echo ""

# 설치 디렉토리 생성
if [[ ! -d "$INSTALL_DIR" ]]; then
    log "설치 디렉토리 생성: $INSTALL_DIR"
    $SUDO_CMD mkdir -p "$INSTALL_DIR"
fi

# 목적별 추가 안내
if [[ "$INSTALL_PURPOSE" == "development" ]]; then
    echo -e "${CYAN}👨‍💻 개발/테스트 환경 설정:${NC}"
    echo -e "   • 개인 사용자 전용 설치"
    echo -e "   • 빠른 업데이트/제거 가능"
    echo -e "   • 실험적 기능 테스트에 적합"
elif [[ "$INSTALL_PURPOSE" == "production" ]]; then
    echo -e "${CYAN}🏢 운영/공유 환경 설정:${NC}"
    echo -e "   • 시스템 전역 설치"
    echo -e "   • 모든 사용자가 동일한 도구 사용"
    echo -e "   • 팀 표준화에 적합"
fi

# PATH 확인 (사용자 설치인 경우)
if [[ "$INSTALL_TYPE" == "user" ]]; then
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        warn "~/.local/bin이 PATH에 없습니다."
        echo ""
        echo -e "${YELLOW}🔧 PATH 설정이 필요합니다:${NC}"
        echo "다음 중 하나를 선택하세요:"
        echo ""
        echo "A. 자동 설정 (권장):"
        echo "   설치 완료 후 자동으로 PATH를 설정합니다"
        echo ""
        echo "B. 수동 설정:"
        echo "   설치 후 수동으로 다음 명령어를 실행하거나"
        echo "   ~/.bashrc (또는 ~/.zshrc)에 추가하세요:"
        echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
        
        read -p "자동 PATH 설정을 원하시나요? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            AUTO_PATH_SETUP=false
            info "수동 PATH 설정 선택됨"
        else
            AUTO_PATH_SETUP=true
            success "자동 PATH 설정 선택됨"
        fi
        echo ""
        
        read -p "계속하시겠습니까? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "설치를 취소했습니다."
            exit 0
        fi
    else
        AUTO_PATH_SETUP=false
        success "PATH에 ~/.local/bin이 이미 포함되어 있습니다"
    fi
fi

# 권한 테스트 (macOS 최적화)
log "설치 권한 테스트 중..."
TEST_FILE="$INSTALL_DIR/.git-tools-test"
if $SUDO_CMD touch "$TEST_FILE" 2>/dev/null; then
    $SUDO_CMD rm -f "$TEST_FILE"
    success "설치 권한 확인됨"
else
    error "설치 디렉토리에 쓰기 권한이 없습니다: $INSTALL_DIR"
    if [[ "$INSTALL_TYPE" == "system" ]]; then
        error "sudo 권한이 필요합니다."
        echo ""
        echo -e "${CYAN}💡 macOS 권한 해결 방법:${NC}"
        echo "1. sudo 비밀번호 입력: sudo ./install.sh"
        echo "2. 또는 개인 설치로 변경: ~/.local/bin 사용"
        echo "3. Homebrew 사용자: /opt/homebrew/bin 권한 확인"
    fi
    exit 1
fi

# 기존 설치 확인 (업데이트 모드가 아닌 경우)
if [[ "$INSTALL_MODE" != "update" ]]; then
    EXISTING_TOOLS=()
    for tool in "${TOOLS[@]}"; do
        if [[ -f "$INSTALL_DIR/git-$tool" ]]; then
            EXISTING_TOOLS+=("$tool")
        fi
    done

    if [[ ${#EXISTING_TOOLS[@]} -gt 0 ]]; then
        warn "설치 위치에 기존 설치가 발견되었습니다:"
        for tool in "${EXISTING_TOOLS[@]}"; do
            EXISTING_VERSION=$($INSTALL_DIR/git-$tool --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
            echo "  - git-$tool (버전: $EXISTING_VERSION)"
        done
        echo ""
        echo -e "${YELLOW}🔄 업데이트 모드로 진행됩니다.${NC}"
        read -p "기존 설치를 업데이트하시겠습니까? (Y/n): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            echo "설치를 취소했습니다."
            exit 0
        fi
        log "기존 설치를 업데이트합니다..."
    fi
fi

# 최종 확인
echo ""
echo -e "${CYAN}🎯 설치 요약:${NC}"
echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
echo -e "  📍 설치 위치: ${BOLD}$INSTALL_DIR${NC}"
echo -e "  🎯 설치 목적: ${BOLD}$([ "$INSTALL_PURPOSE" == "development" ] && echo "개발/테스트" || echo "운영/공유")${NC}"
echo -e "  🔧 설치 타입: ${BOLD}$INSTALL_TYPE${NC}"
echo -e "  📦 도구 개수: ${BOLD}${#TOOLS[@]}개${NC}"
echo -e "  🔑 권한 요구: ${BOLD}${SUDO_CMD:-"불필요"}${NC}"
echo -e "  🎲 설치 모드: ${BOLD}$([ "$INSTALL_MODE" == "update" ] && echo "업데이트" || echo "새로설치")${NC}"
if [[ "$INSTALL_TYPE" == "user" ]] && [[ "$AUTO_PATH_SETUP" == "true" ]]; then
echo -e "  🛣️ PATH 설정: ${BOLD}자동${NC}"
fi
echo -e "${GREEN}────────────────────────────────────────────────────────────────${NC}"
echo ""

if [[ "$INSTALL_PURPOSE" == "development" ]]; then
    echo -e "${CYAN}💡 개발/테스트 환경 특징:${NC}"
    echo -e "   • 빠른 실험과 테스트에 최적화"
    echo -e "   • 언제든 쉽게 제거/업데이트 가능"
    echo -e "   • 시스템에 최소한의 영향"
elif [[ "$INSTALL_PURPOSE" == "production" ]]; then
    echo -e "${CYAN}💡 운영/공유 환경 특징:${NC}"
    echo -e "   • 팀 전체가 동일한 도구 사용"
    echo -e "   • 안정적이고 일관된 개발 환경"
    echo -e "   • CI/CD 파이프라인에서 활용 가능"
fi

echo ""
read -p "설치를 시작하시겠습니까? (Y/n): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "설치를 취소했습니다."
    exit 0
fi

# ==========================================
# Phase 2: Git Subcommand 스크립트 생성 및 설치
# ==========================================
header "Phase 2: Git Subcommand 스크립트 생성 및 설치"

# git-wt-jira 스크립트 생성
log "git-wt-jira 생성 중..."
cat > /tmp/git-wt-jira << 'JIRA_SCRIPT'
#!/bin/bash
# Git Subcommand: git wt-jira
# Jira 워크트리 생성 도구

set -e

VERSION="1.0.0"

# 버전 정보
if [[ "$1" == "--version" ]]; then
    echo "git-wt-jira version $VERSION"
    exit 0
fi

# 도움말
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]] || [[ $# -eq 0 ]]; then
    cat << 'HELP_EOF'
Usage: git wt-jira <issue-key> [base-branch]

Create a git worktree from Jira issue with automatic dependency installation.

Examples:
  git wt-jira QAT-3349                    # Create fix/QAT-3349 from current branch
  git wt-jira PROJ-123                    # Create feature/PROJ-123 from current branch
  git wt-jira QAT-3349 develop           # Create fix/QAT-3349 from develop branch
  git wt-jira https://company.atlassian.net/browse/QAT-3349

Branch Naming Rules:
  • QAT-* issues  → fix/QAT-XXXX (bug fixes)
  • Other issues  → feature/ISSUE-KEY (new features)

Options:
  -h, --help     Show this help message
  --version      Show version information

Features:
  ✅ Automatic dependency installation (pnpm/npm/yarn)
  ✅ VSCode integration
  ✅ Smart branch naming conventions
  ✅ Comprehensive error checking
  ✅ Works in any Git repository

Global Installation:
  This tool is globally installed and available in all Git repositories.
HELP_EOF
    exit 0
fi

JIRA_INPUT="$1"
BASE_BRANCH="${2:-$(git branch --show-current 2>/dev/null)}"

# Jira 이슈 키 추출
ISSUE_KEY=$(echo "$JIRA_INPUT" | grep -o '[A-Z]\+-[0-9]\+')
if [[ -z "$ISSUE_KEY" ]]; then
    echo "❌ Error: No issue key found in: $JIRA_INPUT"
    echo "💡 Cause: URL doesn't contain valid Jira issue pattern (ABC-123)"
    echo "🔧 Solution: Use format like QAT-3349 or full Jira URL"
    exit 1
fi

echo "🚀 Jira Worktree Setup: $ISSUE_KEY"

# Git 저장소 확인
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$GIT_ROOT" ]]; then
    echo "❌ Error: Not in a git repository"
    echo "💡 Cause: Current directory is not part of a git repository"
    echo "🔧 Solution: Navigate to your project root or run 'git init'"
    exit 1
fi

CURRENT_DIR=$(pwd)
echo "📍 Current location: $CURRENT_DIR"
echo "📁 Git root: $GIT_ROOT"

# Git root로 이동
if [[ "$CURRENT_DIR" != "$GIT_ROOT" ]]; then
    echo "📁 Navigating to git root: $GIT_ROOT"
    cd "$GIT_ROOT"
fi

# 워크트리 설정 - QAT는 fix/, 나머지는 feature/
if [[ "$ISSUE_KEY" == QAT-* ]]; then
    BRANCH_PREFIX="fix"
    echo "🐛 QAT 이슈 감지 - 버그 수정 브랜치로 생성됩니다"
else
    BRANCH_PREFIX="feature"
fi

TARGET_WORKTREE_NAME="$BRANCH_PREFIX-$ISSUE_KEY"
WORKTREE_PATH=".worktrees/$BRANCH_PREFIX-$ISSUE_KEY"
BRANCH_NAME="$BRANCH_PREFIX/$ISSUE_KEY"

echo "🌿 Target: $BRANCH_NAME (from $BASE_BRANCH)"

# 이미 해당 워크트리에 있는지 확인
if [[ "$CURRENT_DIR" == *"/$TARGET_WORKTREE_NAME" ]]; then
    echo "✅ Already in target worktree: $TARGET_WORKTREE_NAME"
    echo "🌿 Current branch: $(git branch --show-current)"
    echo "💻 Opening VSCode..."
    command -v code >/dev/null 2>&1 && code .
    echo "🎉 Ready for development!"
    exit 0
fi

# 기존 워크트리 확인
if [[ -d "$WORKTREE_PATH" ]]; then
    echo "✅ Worktree already exists: $WORKTREE_PATH"
    cd "$WORKTREE_PATH"
    echo "📍 Switched to: $(pwd)"
    echo "🌿 Branch: $(git branch --show-current)"
    echo "💻 Opening VSCode..."
    command -v code >/dev/null 2>&1 && code .
    echo "🎉 Ready for development!"
    exit 0
fi

# 새 워크트리 생성을 위한 검증
echo "🔍 Checking prerequisites..."

# Base 브랜치 존재 확인
if ! git show-ref --verify --quiet "refs/heads/$BASE_BRANCH"; then
    echo "❌ Error: Base branch '$BASE_BRANCH' not found"
    echo "💡 Cause: Branch doesn't exist in local repository"
    echo "🔧 Solution: Use 'git branch -a' to see available branches or fetch from origin"
    exit 1
fi

# 변경사항 확인
if ! git diff --quiet; then
    echo "❌ Error: Uncommitted changes detected in working directory"
    echo "💡 Cause: You have modified files that aren't committed"
    echo "🔧 Solution: Commit your changes with 'git commit -am \"message\"' or stash with 'git stash'"
    exit 1
fi

if ! git diff --cached --quiet; then
    echo "❌ Error: Staged changes detected"
    echo "💡 Cause: You have staged files waiting to be committed"
    echo "🔧 Solution: Commit staged changes with 'git commit -m \"message\"' or unstage with 'git reset'"
    exit 1
fi

# 브랜치 중복 확인
if git show-ref --verify --quiet "refs/heads/$BRANCH_NAME"; then
    echo "❌ Error: Branch already exists: $BRANCH_NAME"
    echo "💡 Cause: This feature branch was already created"
    echo "🔧 Solution: Use different issue key or delete existing branch with 'git branch -d $BRANCH_NAME'"
    exit 1
fi

echo "✅ All prerequisites met"

# 워크트리 디렉토리 생성
mkdir -p .worktrees

# 워크트리 생성
echo "🌿 Creating worktree..."
if ! git worktree add "$WORKTREE_PATH" -b "$BRANCH_NAME" "$BASE_BRANCH"; then
    echo "❌ Error: Failed to create worktree"
    echo "💡 Cause: Git worktree command failed"
    echo "🔧 Solution: Check git version (requires 2.5+) and repository state"
    exit 1
fi

# 워크트리로 이동
cd "$WORKTREE_PATH"
echo "✅ Worktree created: $(pwd)"

# 의존성 설치
echo "📦 Installing dependencies..."

if [[ -f "pnpm-lock.yaml" ]]; then
    echo "📦 Installing with pnpm..."
    if command -v pnpm >/dev/null 2>&1; then
        if pnpm install; then
            echo "✅ Dependencies installed with pnpm"
        else
            echo "❌ Error: pnpm install failed"
            echo "💡 Cause: Dependency installation error"
            echo "🔧 Solution: Check network connection and run 'pnpm install --verbose' for details"
            exit 1
        fi
    else
        echo "❌ Error: pnpm not found but pnpm-lock.yaml exists"
        echo "💡 Cause: Project uses pnpm but it's not installed"
        echo "🔧 Solution: Install pnpm with: npm install -g pnpm"
        exit 1
    fi
elif [[ -f "package-lock.json" ]]; then
    echo "📦 Installing with npm..."
    if command -v npm >/dev/null 2>&1; then
        if npm install; then
            echo "✅ Dependencies installed with npm"
        else
            echo "❌ Error: npm install failed"
            exit 1
        fi
    else
        echo "❌ Error: npm not found"
        exit 1
    fi
elif [[ -f "yarn.lock" ]]; then
    echo "📦 Installing with yarn..."
    if command -v yarn >/dev/null 2>&1; then
        if yarn install; then
            echo "✅ Dependencies installed with yarn"
        else
            echo "❌ Error: yarn install failed"
            exit 1
        fi
    else
        echo "❌ Error: yarn not found but yarn.lock exists"
        exit 1
    fi
else
    echo "⚠️ No lockfile found, skipping dependency installation"
    echo "💡 Available package files:"
    ls -la package* 2>/dev/null || echo "No package files found"
fi

# VSCode 실행
echo "💻 Opening VSCode..."
if command -v code >/dev/null 2>&1; then
    code .
    echo "✅ VSCode opened successfully"
else
    echo "⚠️ VSCode 'code' command not found"
    echo "💡 Open the project manually: code $(pwd)"
fi

# 성공 요약
echo ""
echo "🎉 Setup complete!"
echo "📍 Location: $(pwd)"
echo "🌿 Branch: $(git branch --show-current)"
if [[ "$ISSUE_KEY" == QAT-* ]]; then
    echo "🔗 Jira: https://company.atlassian.net/browse/$ISSUE_KEY"
    echo "🐛 Bug fix branch created: $BRANCH_NAME"
else
    echo "🔗 Jira: https://company.atlassian.net/browse/$ISSUE_KEY"
    echo "✨ Feature branch created: $BRANCH_NAME"
fi
echo ""
echo "🚀 Ready for development on $ISSUE_KEY!"
JIRA_SCRIPT

$SUDO_CMD mv /tmp/git-wt-jira "$INSTALL_DIR/git-wt-jira"
$SUDO_CMD chmod +x "$INSTALL_DIR/git-wt-jira"
success "git-wt-jira 설치 완료"

# git-wt-clean 스크립트 생성
log "git-wt-clean 생성 중..."
cat > /tmp/git-wt-clean << 'CLEAN_SCRIPT'
#!/bin/bash
# Git Subcommand: git wt-clean
# 워크트리 선택 삭제 도구

set -e

VERSION="1.0.0"

# 버전 정보
if [[ "$1" == "--version" ]]; then
    echo "git-wt-clean version $VERSION"
    exit 0
fi

# 도움말
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << 'HELP_EOF'
Usage: git wt-clean

워크트리를 선택하여 안전하게 삭제합니다.

Features:
  ✅ 커밋되지 않은 변경사항 감지 및 안내
  ✅ 개별 워크트리 선택 삭제
  ✅ 전체 워크트리 일괄 삭제
  ✅ Git 참조 자동 정리
  ✅ 포괄적인 에러 처리

Options:
  -h, --help     Show this help message
  --version      Show version information

Safety:
  커밋되지 않은 변경사항이 있으면 실행을 중단하고 안내합니다.
  사용자가 직접 커밋하거나 스태시한 후 다시 실행해야 합니다.
HELP_EOF
    exit 0
fi

echo "🧹 Git 워크트리 선택 삭제"

# Git 저장소 확인
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$GIT_ROOT" ]]; then
    echo "❌ Error: Not in a git repository"
    echo "💡 Cause: Current directory is not part of a git repository"
    echo "🔧 Solution: Navigate to your project root or run 'git init'"
    exit 1
fi

CURRENT_DIR=$(pwd)
echo "📍 현재 위치: $CURRENT_DIR"
echo "📁 Git 저장소: $GIT_ROOT"

# 변경사항 확인 (커밋되지 않은 파일이 있으면 중단)
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo ""
    echo "❌ Error: 커밋되지 않은 변경사항이 감지되었습니다"
    echo ""
    echo "📋 변경된 파일들:"
    git status --short
    echo ""
    echo "💡 다음 중 하나를 선택하여 변경사항을 처리하세요:"
    echo "   🔹 커밋: git add . && git commit -m \"작업 내용\""
    echo "   🔹 스태시: git stash push -m \"임시 저장\""
    echo "   🔹 취소: git checkout -- . (주의: 변경사항 손실)"
    echo ""
    echo "🔧 변경사항을 처리한 후 다시 실행해주세요."
    exit 1
fi

echo "✅ 변경사항 확인 완료 (깨끗한 상태)"

# 현재 브랜치 정보
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
echo "🌿 현재 브랜치: $CURRENT_BRANCH"

# 워크트리 목록 가져오기
echo ""
echo "📋 워크트리 목록 조회 중..."
WORKTREE_LIST=$(git worktree list 2>/dev/null || echo "")

if [[ -z "$WORKTREE_LIST" ]]; then
    echo "❌ 워크트리 정보를 가져올 수 없습니다."
    exit 1
fi

# 워크트리 파싱 (메인 저장소 제외)
WORKTREE_PATHS=()
WORKTREE_BRANCHES=()
WORKTREE_DISPLAY=()

while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        WORKTREE_PATH=$(echo "$line" | awk '{print $1}')
        WORKTREE_BRANCH=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//' | tr -d '[]')
        
        # 메인 저장소가 아닌 경우만 추가
        if [[ "$WORKTREE_PATH" != "$GIT_ROOT" ]]; then
            WORKTREE_PATHS+=("$WORKTREE_PATH")
            WORKTREE_BRANCHES+=("$WORKTREE_BRANCH")
            WORKTREE_DISPLAY+=("$WORKTREE_PATH ($WORKTREE_BRANCH)")
        fi
    fi
done <<< "$WORKTREE_LIST"

# 삭제 가능한 워크트리가 없는 경우
if [[ ${#WORKTREE_PATHS[@]} -eq 0 ]]; then
    echo "ℹ️ 삭제할 수 있는 추가 워크트리가 없습니다."
    echo "✅ 메인 저장소만 존재합니다."
    echo ""
    echo "💡 새 워크트리를 만들려면:"
    echo "   git wt-jira QAT-3349"
    exit 0
fi

echo "✅ ${#WORKTREE_PATHS[@]}개의 삭제 가능한 워크트리를 발견했습니다."
echo ""

# 워크트리 선택 메뉴
echo "🎯 삭제할 워크트리를 선택하세요:"
echo ""

# 개별 워크트리 목록 표시
for i in "${!WORKTREE_DISPLAY[@]}"; do
    echo "  $((i + 1)). 📁 ${WORKTREE_DISPLAY[i]}"
done

echo ""
echo "  $((${#WORKTREE_PATHS[@]} + 1)). 🗑️ 모든 워크트리 삭제"
echo "  $((${#WORKTREE_PATHS[@]} + 2)). 🔧 Git 참조만 정리 (prune)"
echo "  $((${#WORKTREE_PATHS[@]} + 3)). ❌ 취소"
echo ""

# 사용자 선택 받기
while true; do
    MAX_OPTION=$((${#WORKTREE_PATHS[@]} + 3))
    read -p "선택하세요 (1-$MAX_OPTION): " -r CHOICE
    echo ""
    
    if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [[ "$CHOICE" -ge 1 ]] && [[ "$CHOICE" -le "$MAX_OPTION" ]]; then
        break
    else
        echo "❌ 잘못된 선택입니다. 1-$MAX_OPTION 사이의 숫자를 입력해주세요."
        echo ""
    fi
done

# 선택에 따른 처리
if [[ "$CHOICE" -le "${#WORKTREE_PATHS[@]}" ]]; then
    # 개별 워크트리 삭제
    SELECTED_INDEX=$((CHOICE - 1))
    SELECTED_PATH="${WORKTREE_PATHS[SELECTED_INDEX]}"
    SELECTED_BRANCH="${WORKTREE_BRANCHES[SELECTED_INDEX]}"
    
    echo "🗑️ 선택된 워크트리 삭제: $SELECTED_PATH ($SELECTED_BRANCH)"
    echo ""
    
    read -p "정말로 삭제하시겠습니까? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🗑️ 워크트리 삭제 중..."
        
        if git worktree remove "$SELECTED_PATH" --force 2>/dev/null; then
            echo "✅ Git 워크트리 제거 성공: $SELECTED_PATH"
        else
            echo "⚠️ Git 워크트리 제거 실패. 수동 정리를 시도합니다..."
            if rm -rf "$SELECTED_PATH" 2>/dev/null; then
                echo "✅ 디렉토리 수동 삭제 성공"
            else
                echo "❌ 디렉토리 삭제 실패: $SELECTED_PATH"
            fi
        fi
        
        # Git 참조 정리
        echo "🧹 Git 참조 정리 중..."
        git worktree prune
        echo "✅ 참조 정리 완료"
        
        echo ""
        echo "🎉 워크트리 삭제 완료!"
    else
        echo "❌ 삭제를 취소했습니다."
        exit 0
    fi
    
elif [[ "$CHOICE" -eq $((${#WORKTREE_PATHS[@]} + 1)) ]]; then
    # 모든 워크트리 삭제
    echo "🗑️ 모든 워크트리를 삭제합니다..."
    echo ""
    echo "삭제될 워크트리:"
    for i in "${!WORKTREE_DISPLAY[@]}"; do
        echo "  📁 ${WORKTREE_DISPLAY[i]}"
    done
    echo ""
    
    read -p "정말로 모든 워크트리를 삭제하시겠습니까? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🗑️ 모든 워크트리 삭제 중..."
        
        DELETED_COUNT=0
        FAILED_COUNT=0
        
        for i in "${!WORKTREE_PATHS[@]}"; do
            WORKTREE_PATH="${WORKTREE_PATHS[i]}"
            WORKTREE_BRANCH="${WORKTREE_BRANCHES[i]}"
            
            echo "  🗑️ 삭제 중: $WORKTREE_PATH ($WORKTREE_BRANCH)"
            
            if git worktree remove "$WORKTREE_PATH" --force 2>/dev/null; then
                echo "     ✅ 성공"
                ((DELETED_COUNT++))
            else
                echo "     ⚠️ Git 제거 실패, 수동 삭제 시도..."
                if rm -rf "$WORKTREE_PATH" 2>/dev/null; then
                    echo "     ✅ 수동 삭제 성공"
                    ((DELETED_COUNT++))
                else
                    echo "     ❌ 삭제 실패"
                    ((FAILED_COUNT++))
                fi
            fi
        done
        
        # Git 참조 정리
        echo "  🧹 Git 참조 정리 중..."
        git worktree prune
        echo "     ✅ 참조 정리 완료"
        
        echo ""
        echo "🎉 전체 삭제 완료!"
        echo "  ✅ 성공: $DELETED_COUNT개"
        [[ $FAILED_COUNT -gt 0 ]] && echo "  ❌ 실패: $FAILED_COUNT개"
    else
        echo "❌ 삭제를 취소했습니다."
        exit 0
    fi
    
elif [[ "$CHOICE" -eq $((${#WORKTREE_PATHS[@]} + 2)) ]]; then
    # Git 참조만 정리
    echo "🔧 Git 참조 정리만 실행합니다..."
    git worktree prune
    echo "✅ 참조 정리 완료"
    
elif [[ "$CHOICE" -eq $((${#WORKTREE_PATHS[@]} + 3)) ]]; then
    # 취소
    echo "❌ 작업을 취소했습니다."
    exit 0
fi

echo ""
echo "📋 현재 상태:"
echo "📍 위치: $(pwd)"
echo "🌿 브랜치: $(git branch --show-current 2>/dev/null || echo 'detached')"
echo ""
echo "📋 남은 워크트리:"
git worktree list 2>/dev/null || echo "워크트리 없음"
echo ""
echo "💡 새 워크트리를 만들려면: git wt-jira <ISSUE-KEY>"
CLEAN_SCRIPT

$SUDO_CMD mv /tmp/git-wt-clean "$INSTALL_DIR/git-wt-clean"
$SUDO_CMD chmod +x "$INSTALL_DIR/git-wt-clean"
success "git-wt-clean 설치 완료"

# git-wt-list 스크립트 생성
log "git-wt-list 생성 중..."
cat > /tmp/git-wt-list << 'LIST_SCRIPT'
#!/bin/bash
# Git Subcommand: git wt-list
# 워크트리 목록 표시 도구

set -e

VERSION="1.0.0"

# 버전 정보
if [[ "$1" == "--version" ]]; then
    echo "git-wt-list version $VERSION"
    exit 0
fi

# 도움말
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    cat << 'HELP_EOF'
Usage: git wt-list [options]

Git 워크트리 목록을 보기 좋게 표시합니다.

Options:
  -v, --verbose  상세 정보 표시
  -h, --help     Show this help message
  --version      Show version information

Features:
  ✅ 현재 워크트리 하이라이트
  ✅ 브랜치 정보 표시
  ✅ .worktrees 디렉토리 구조 표시
  ✅ 워크트리별 상태 정보

Examples:
  git wt-list          # 기본 목록
  git wt-list -v       # 상세 정보 포함
HELP_EOF
    exit 0
fi

# Verbose 모드
VERBOSE=false
[[ "$1" == "-v" ]] || [[ "$1" == "--verbose" ]] && VERBOSE=true

echo "📋 Git 워크트리 목록"

# Git 저장소 확인
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -z "$GIT_ROOT" ]]; then
    echo "❌ Error: Not in a git repository"
    echo "💡 Cause: Current directory is not part of a git repository"
    echo "🔧 Solution: Navigate to your project root or run 'git init'"
    exit 1
fi

CURRENT_DIR=$(pwd)
echo "📁 Git 저장소: $GIT_ROOT"
echo "📍 현재 위치: $CURRENT_DIR"
echo ""

# 현재 브랜치 정보
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
echo "🌿 현재 브랜치: $CURRENT_BRANCH"

# Git 워크트리 목록
echo ""
echo "🏠 Git 워크트리 목록:"
WORKTREE_LIST=$(git worktree list 2>/dev/null || echo "")

if [[ -z "$WORKTREE_LIST" ]]; then
    echo "❌ 워크트리 정보를 가져올 수 없습니다."
    exit 1
fi

# 워크트리 목록 파싱 및 표시
WORKTREE_COUNT=0
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        ((WORKTREE_COUNT++))
        
        WORKTREE_PATH=$(echo "$line" | awk '{print $1}')
        WORKTREE_HASH=$(echo "$line" | awk '{print $2}' | tr -d '[]')
        WORKTREE_BRANCH=$(echo "$line" | awk '{$1=$2=""; print $0}' | sed 's/^ *//' | tr -d '[]')
        
        # 현재 워크트리인지 확인
        IS_CURRENT=""
        if [[ "$CURRENT_DIR" == "$WORKTREE_PATH"* ]]; then
            IS_CURRENT=" 👈 현재 위치"
        fi
        
        # 메인 저장소인지 확인
        if [[ "$WORKTREE_PATH" == "$GIT_ROOT" ]]; then
            echo "  🏠 $WORKTREE_PATH (메인 저장소)$IS_CURRENT"
        else
            echo "  📁 $WORKTREE_PATH$IS_CURRENT"
        fi
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo "     🏷️ 브랜치: $WORKTREE_BRANCH"
            echo "     🔗 커밋: $WORKTREE_HASH"
            
            # 워크트리 상태 확인
            if [[ -d "$WORKTREE_PATH" ]]; then
                cd "$WORKTREE_PATH"
                STATUS_OUTPUT=$(git status --porcelain 2>/dev/null || echo "")
                if [[ -z "$STATUS_OUTPUT" ]]; then
                    echo "     ✅ 상태: 깨끗함"
                else
                    MODIFIED_COUNT=$(echo "$STATUS_OUTPUT" | wc -l | tr -d ' ')
                    echo "     📝 상태: $MODIFIED_COUNT개 파일 변경됨"
                fi
                cd "$CURRENT_DIR"
            else
                echo "     ❌ 상태: 디렉토리 없음"
            fi
            echo ""
        fi
    fi
done <<< "$WORKTREE_LIST"

echo ""
echo "📊 요약:"
echo "  • 총 워크트리 개수: $WORKTREE_COUNT개"
echo "  • 메인 저장소: 1개"
echo "  • 추가 워크트리: $((WORKTREE_COUNT - 1))개"

# .worktrees 디렉토리 확인
echo ""
echo "📂 .worktrees 디렉토리:"
cd "$GIT_ROOT"

if [[ -d ".worktrees" ]]; then
    WORKTREE_DIRS=$(ls -la .worktrees/ 2>/dev/null | tail -n +4 | wc -l | tr -d ' ')
    echo "  📍 위치: $GIT_ROOT/.worktrees"
    echo "  📁 디렉토리 개수: $WORKTREE_DIRS개"
    
    if [[ "$VERBOSE" == "true" ]]; then
        echo ""
        echo "  📋 디렉토리 목록:"
        ls -la .worktrees/ 2>/dev/null | tail -n +4 | while read -r line; do
            DIR_NAME=$(echo "$line" | awk '{print $NF}')
            echo "    📁 $DIR_NAME"
        done
    fi
else
    echo "  ℹ️ .worktrees 디렉토리가 없습니다."
    echo "  💡 워크트리를 만들면 자동으로 생성됩니다: git wt-jira <ISSUE-KEY>"
fi

cd "$CURRENT_DIR"

echo ""
echo "💡 사용 가능한 명령어:"
echo "  • 새 워크트리: git wt-jira <ISSUE-KEY>"
echo "  • 워크트리 정리: git wt-clean"
echo "  • 상세 목록: git wt-list -v"
LIST_SCRIPT

$SUDO_CMD mv /tmp/git-wt-list "$INSTALL_DIR/git-wt-list"
$SUDO_CMD chmod +x "$INSTALL_DIR/git-wt-list"
success "git-wt-list 설치 완료"

# ==========================================
# Phase 3: PATH 설정 (사용자 설치 시)
# ==========================================
if [[ "$INSTALL_TYPE" == "user" ]] && [[ "$AUTO_PATH_SETUP" == "true" ]]; then
    header "Phase 3: PATH 자동 설정"
    
    log "PATH 설정 중..."
    
    # macOS에서 사용 중인 셸 감지
    SHELL_NAME=$(basename "$SHELL")
    SHELL_RC=""
    
    case "$SHELL_NAME" in
        zsh)
            # macOS Catalina+ 기본 셸
            SHELL_RC="$HOME/.zshrc"
            ;;
        bash)
            # macOS에서 bash 사용 시
            if [[ -f "$HOME/.bash_profile" ]]; then
                SHELL_RC="$HOME/.bash_profile"  # macOS bash 기본
            elif [[ -f "$HOME/.bashrc" ]]; then
                SHELL_RC="$HOME/.bashrc"
            else
                SHELL_RC="$HOME/.bash_profile"  # 새로 생성
            fi
            ;;
        fish)
            if [[ ! -d "$HOME/.config/fish" ]]; then
                mkdir -p "$HOME/.config/fish"
            fi
            SHELL_RC="$HOME/.config/fish/config.fish"
            ;;
        *)
            SHELL_RC="$HOME/.profile"
            ;;
    esac
    
    info "감지된 셸: $SHELL_NAME"
    info "설정 파일: $SHELL_RC"
    
    # PATH 추가
    PATH_EXPORT="export PATH=\"\$HOME/.local/bin:\$PATH\""
    
    if [[ ! -f "$SHELL_RC" ]]; then
        log "셸 설정 파일 생성: $SHELL_RC"
        echo "# Git Subcommands PATH" >> "$SHELL_RC"
        echo "$PATH_EXPORT" >> "$SHELL_RC"
        success "PATH 설정 추가됨"
    elif grep -q "HOME/.local/bin" "$SHELL_RC"; then
        success "PATH 설정이 이미 존재함"
    else
        log "셸 설정 파일에 PATH 추가"
        echo "" >> "$SHELL_RC"
        echo "# Git Subcommands PATH" >> "$SHELL_RC"
        echo "$PATH_EXPORT" >> "$SHELL_RC"
        success "PATH 설정 추가됨"
    fi
    
    # 현재 세션에도 적용
    export PATH="$HOME/.local/bin:$PATH"
    success "현재 세션에 PATH 적용됨"
    
    echo ""
    warn "새 터미널을 열거나 다음 명령어를 실행해주세요:"
    echo "  source $SHELL_RC"
fi

# ==========================================
# Phase 4: 설치 확인 및 테스트
# ==========================================
header "Phase 4: 설치 확인 및 테스트"

log "설치된 도구 확인 중..."
echo "📁 설치 위치: $INSTALL_DIR"
echo "📋 설치된 도구들:"

INSTALLED_TOOLS=()
FAILED_TOOLS=()

for tool in "${TOOLS[@]}"; do
    if [[ -f "$INSTALL_DIR/git-$tool" ]] && [[ -x "$INSTALL_DIR/git-$tool" ]]; then
        echo "  ✅ git-$tool"
        INSTALLED_TOOLS+=("$tool")
    else
        echo "  ❌ git-$tool"
        FAILED_TOOLS+=("$tool")
    fi
done

if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    error "일부 도구 설치 실패: ${FAILED_TOOLS[*]}"
    exit 1
fi

success "모든 도구 설치 완료 (${#INSTALLED_TOOLS[@]}개)"

# 기본 기능 테스트
log "기본 기능 테스트 중..."

for tool in "${INSTALLED_TOOLS[@]}"; do
    echo -n "  $tool 버전 확인: "
    if "$INSTALL_DIR/git-$tool" --version >/dev/null 2>&1; then
        success "정상"
    else
        warn "버전 정보 없음"
    fi
    
    echo -n "  $tool 도움말: "
    if "$INSTALL_DIR/git-$tool" --help >/dev/null 2>&1; then
        success "정상"
    else
        error "실패"
    fi
done

# Git 통합 테스트
log "Git 통합 테스트 중..."

# 임시 Git 저장소에서 테스트
TEMP_TEST_DIR=$(mktemp -d)
cd "$TEMP_TEST_DIR"

git init --quiet
git config user.name "Test User"
git config user.email "test@example.com"

echo "# Test Repository" > README.md
git add README.md
git commit -m "Initial commit" --quiet

echo -n "  git wt-jira 도움말: "
if git wt-jira --help >/dev/null 2>&1; then
    success "정상"
else
    error "실패"
fi

echo -n "  git wt-clean 도움말: "
if git wt-clean --help >/dev/null 2>&1; then
    success "정상"
else
    error "실패"
fi

echo -n "  git wt-list 도움말: "
if git wt-list --help >/dev/null 2>&1; then
    success "정상"
else
    error "실패"
fi

# 정리
cd - >/dev/null
rm -rf "$TEMP_TEST_DIR"

# ==========================================
# Phase 5: 향상된 제거 스크립트 생성
# ==========================================
header "Phase 5: 향상된 제거 스크립트 생성"

log "향상된 제거 스크립트 생성 중..."

# 제거 스크립트 생성
UNINSTALL_SCRIPT="$INSTALL_DIR/git-tools-uninstall"

cat > /tmp/git-tools-uninstall << 'UNINSTALL_SCRIPT'
#!/bin/bash
# Git Subcommands 제거 스크립트 (향상된 환경 검색 기능)

set -e

# 색상 출력
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 로그 함수들
header() { echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${CYAN}${BOLD}  $1${NC}"; echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"; }
log() { echo -e "${BLUE}🚀 $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }
info() { echo -e "${CYAN}ℹ️ $1${NC}"; }

# 설치된 도구들
TOOLS=("wt-jira" "wt-clean" "wt-list")

# 검색할 일반적인 설치 위치들
SEARCH_PATHS=(
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "$HOME/.local/bin"
    "/opt/bin"
)

header "Git Subcommands 전체 제거"

echo "🔍 시스템 전체에서 설치된 Git Subcommands를 검색합니다..."
echo ""

# 설치된 도구 검색
FOUND_TOOLS=()
FOUND_UNINSTALL_SCRIPTS=()

for search_path in "${SEARCH_PATHS[@]}"; do
    if [[ -d "$search_path" ]]; then
        local found_in_path=()
        
        # Git subcommand 검색
        for tool in "${TOOLS[@]}"; do
            local tool_path="$search_path/git-$tool"
            if [[ -f "$tool_path" ]] && [[ -x "$tool_path" ]]; then
                found_in_path+=("$tool_path")
                FOUND_TOOLS+=("$tool_path")
            fi
        done
        
        # 제거 스크립트 검색
        local uninstall_script="$search_path/git-tools-uninstall"
        if [[ -f "$uninstall_script" ]] && [[ -x "$uninstall_script" ]]; then
            FOUND_UNINSTALL_SCRIPTS+=("$uninstall_script")
        fi
        
        # 결과 출력
        if [[ ${#found_in_path[@]} -gt 0 ]]; then
            echo -e "${CYAN}📁 $search_path${NC}"
            for tool_path in "${found_in_path[@]}"; do
                tool_name=$(basename "$tool_path")
                tool_version=$("$tool_path" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
                echo -e "  ✅ $tool_name (버전: $tool_version)"
            done
            if [[ -f "$uninstall_script" ]]; then
                echo -e "  🗑️ git-tools-uninstall (제거 스크립트)"
            fi
            echo ""
        fi
    fi
done

if [[ ${#FOUND_TOOLS[@]} -eq 0 ]] && [[ ${#FOUND_UNINSTALL_SCRIPTS[@]} -eq 0 ]]; then
    info "제거할 Git Subcommands가 없습니다."
    echo ""
    echo -e "${CYAN}💡 설치하려면:${NC}"
    echo "  curl -fsSL [install-script-url] | bash"
    exit 0
fi

success "총 ${#FOUND_TOOLS[@]}개의 도구가 발견되었습니다."
if [[ ${#FOUND_UNINSTALL_SCRIPTS[@]} -gt 0 ]]; then
    success "총 ${#FOUND_UNINSTALL_SCRIPTS[@]}개의 제거 스크립트가 발견되었습니다."
fi

echo ""
echo "제거할 파일들:"
for tool_path in "${FOUND_TOOLS[@]}"; do
    echo "  📍 $tool_path"
done
for script_path in "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
    echo "  📍 $script_path"
done

# 권한 확인
echo ""
system_files=()
user_files=()

for file_path in "${FOUND_TOOLS[@]}" "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
    if [[ "$file_path" == /usr/* ]] || [[ "$file_path" == /bin/* ]] || [[ "$file_path" == /opt/* ]]; then
        system_files+=("$file_path")
    else
        user_files+=("$file_path")
    fi
done

if [[ ${#system_files[@]} -gt 0 ]]; then
    warn "시스템 디렉토리의 파일들은 sudo 권한이 필요합니다:"
    for file in "${system_files[@]}"; do
        echo "  📍 $file"
    done
    echo ""
fi

echo ""
echo -e "${YELLOW}⚠️ 정말로 모든 Git Subcommands를 제거하시겠습니까?${NC}"
echo "이 작업은 되돌릴 수 없습니다."
echo ""
read -p "제거를 진행하시겠습니까? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "제거를 취소했습니다."
    exit 0
fi

# 제거 실행
log "제거 작업 시작..."
echo ""

removed_count=0
failed_count=0

# 도구들 제거
for tool_path in "${FOUND_TOOLS[@]}"; do
    local tool_name=$(basename "$tool_path")
    local requires_sudo=false
    
    if [[ "$tool_path" == /usr/* ]] || [[ "$tool_path" == /bin/* ]] || [[ "$tool_path" == /opt/* ]]; then
        requires_sudo=true
    fi
    
    echo -n "  제거 중: $tool_name ... "
    
    if [[ "$requires_sudo" == "true" ]]; then
        if sudo rm -f "$tool_path" 2>/dev/null; then
            echo -e "${GREEN}✅ 완료${NC}"
            ((removed_count++))
        else
            echo -e "${RED}❌ 실패${NC}"
            ((failed_count++))
        fi
    else
        if rm -f "$tool_path" 2>/dev/null; then
            echo -e "${GREEN}✅ 완료${NC}"
            ((removed_count++))
        else
            echo -e "${RED}❌ 실패${NC}"
            ((failed_count++))
        fi
    fi
done

# 제거 스크립트들 제거 (자기 자신 제외)
CURRENT_SCRIPT="$(realpath "$0" 2>/dev/null || echo "$0")"

for script_path in "${FOUND_UNINSTALL_SCRIPTS[@]}"; do
    SCRIPT_REALPATH="$(realpath "$script_path" 2>/dev/null || echo "$script_path")"
    
    # 현재 실행 중인 스크립트는 나중에 제거
    if [[ "$SCRIPT_REALPATH" == "$CURRENT_SCRIPT" ]]; then
        continue
    fi
    
    local requires_sudo=false
    
    if [[ "$script_path" == /usr/* ]] || [[ "$script_path" == /bin/* ]] || [[ "$script_path" == /opt/* ]]; then
        requires_sudo=true
    fi
    
    echo -n "  제거 중: $(basename "$script_path") ... "
    
    if [[ "$requires_sudo" == "true" ]]; then
        if sudo rm -f "$script_path" 2>/dev/null; then
            echo -e "${GREEN}✅ 완료${NC}"
            ((removed_count++))
        else
            echo -e "${RED}❌ 실패${NC}"
            ((failed_count++))
        fi
    else
        if rm -f "$script_path" 2>/dev/null; then
            echo -e "${GREEN}✅ 완료${NC}"
            ((removed_count++))
        else
            echo -e "${RED}❌ 실패${NC}"
            ((failed_count++))
        fi
    fi
done

echo ""

# 결과 요약
if [[ $removed_count -gt 0 ]]; then
    success "$removed_count개 파일이 성공적으로 제거되었습니다."
fi

if [[ $failed_count -gt 0 ]]; then
    error "$failed_count개 파일 제거에 실패했습니다."
fi

echo ""
echo -e "${CYAN}🎉 제거가 완료되었습니다!${NC}"
echo "제거될 워크트리:"
for i in "${!WORKTREE_DISPLAY[@]}"; do
    echo "  📁 ${WORKTREE_DISPLAY[i]}"
done

# 텍스트 변경 - --search, --uninstall 제거
echo ""
echo -e "${CYAN}💡 다시 설치하려면:${NC}"
echo "  # 직접 실행"
echo "  curl -fsSL [install-script-url] | bash"
echo ""
echo "  # 파일 다운로드 후 실행"  
echo "  curl -fsSL [install-script-url] -o install.sh"
echo "  chmod +x install.sh"
echo "  ./install.sh"

# 자기 자신 제거 (마지막에)
CURRENT_REQUIRES_SUDO=false
if [[ "$CURRENT_SCRIPT" == /usr/* ]] || [[ "$CURRENT_SCRIPT" == /bin/* ]] || [[ "$CURRENT_SCRIPT" == /opt/* ]]; then
    CURRENT_REQUIRES_SUDO=true
fi

echo ""
echo -n "자기 자신 제거 중: $(basename "$0") ... "

if [[ "$CURRENT_REQUIRES_SUDO" == "true" ]]; then
    if sudo rm -f "$0" 2>/dev/null; then
        echo -e "${GREEN}✅ 완료${NC}"
    else
        echo -e "${RED}❌ 실패 (수동 제거 필요)${NC}"
    fi
else
    if rm -f "$0" 2>/dev/null; then
        echo -e "${GREEN}✅ 완료${NC}"
    else
        echo -e "${RED}❌ 실패 (수동 제거 필요)${NC}"
    fi
fi
UNINSTALL_SCRIPT

$SUDO_CMD mv /tmp/git-tools-uninstall "$UNINSTALL_SCRIPT"
$SUDO_CMD chmod +x "$UNINSTALL_SCRIPT"
success "향상된 제거 스크립트 생성: $UNINSTALL_SCRIPT"

# ==========================================
# Phase 6: 목적별 맞춤 가이드 생성
# ==========================================
header "Phase 6: 사용 가이드 생성"

log "목적별 맞춤 가이드 생성 중..."

# 목적별 맞춤 가이드 파일명
if [[ "$INSTALL_PURPOSE" == "development" ]]; then
    GUIDE_FILE="$HOME/GIT_TOOLS_DEV_GUIDE.md"
    GUIDE_TITLE="Git Subcommands 개발/테스트 가이드"
else
    GUIDE_FILE="$HOME/GIT_TOOLS_PROD_GUIDE.md"
    GUIDE_TITLE="Git Subcommands 운영/공유 가이드"
fi

cat > "$GUIDE_FILE" << EOF
# $GUIDE_TITLE

## 🎉 설치 완료!

Git Subcommands가 **$([ "$INSTALL_PURPOSE" == "development" ] && echo "개발/테스트" || echo "운영/공유")** 환경에 설치되었습니다.

### 📍 설치 정보
- **설치 위치**: $INSTALL_DIR
- **설치 목적**: $([ "$INSTALL_PURPOSE" == "development" ] && echo "개발/테스트 (개인 사용)" || echo "운영/공유 (팀 전체)")
- **설치 타입**: $INSTALL_TYPE
- **설치 일시**: $(date)
- **버전**: $TOOLS_VERSION

## 📖 기본 사용법

### 핵심 명령어
\`\`\`bash
# Jira 워크트리 생성
git wt-jira QAT-3349                # → fix/QAT-3349 브랜치 생성
git wt-jira PROJ-123                # → feature/PROJ-123 브랜치 생성  
git wt-jira QAT-3349 develop       # develop 브랜치에서 fix/QAT-3349 생성
git wt-jira https://company.atlassian.net/browse/QAT-3349

# 워크트리 관리
git wt-list                         # 워크트리 목록 보기
git wt-list -v                      # 상세 정보 포함
git wt-clean                        # 워크트리 선택 삭제
\`\`\`

### 브랜치 명명 규칙
- **QAT-*** 이슈: \`fix/QAT-XXXX\` (버그 수정용)
- **기타** 이슈: \`feature/ISSUE-KEY\` (기능 개발용)

### 도움말
\`\`\`bash
# 상세 도움말
git wt-jira --help
git wt-list --help
git wt-clean --help
\`\`\`

## 🛠️ 고급 관리 기능

### 설치된 도구 관리
\`\`\`bash
# 통합 관리 (검색/업데이트/제거)
./install.sh

# 또는 제거 스크립트 직접 실행
$UNINSTALL_SCRIPT
\`\`\`

EOF

if [[ "$INSTALL_PURPOSE" == "development" ]]; then
cat >> "$GUIDE_FILE" << 'EOF'
## 🧪 개발/테스트 환경 특화 기능

### 빠른 실험
```bash
# 새로운 기능을 빠르게 테스트
git wt-jira EXPERIMENT-001            # → feature/EXPERIMENT-001
# 버그 수정 테스트
git wt-jira QAT-999                   # → fix/QAT-999
# 워크트리 상태 확인
git wt-list -v                        # 상세 정보 포함
# 개발...
git wt-clean                          # 선택 삭제
```

### 개인 워크플로우 최적화
```bash
# 개인 브랜치 패턴 테스트
git wt-jira PERSONAL-FEATURE          # → feature/PERSONAL-FEATURE
git wt-jira QAT-123                   # → fix/QAT-123
# 워크트리 목록 확인
git wt-list
# 개발 완료 후
git push origin feature/PERSONAL-FEATURE
git push origin fix/QAT-123
# 정리
git wt-clean
```

### 도구 업데이트/제거
```bash
# 방법 1: 직접 업데이트 (권장)
curl -fsSL [install-script-url] | bash

# 방법 2: 파일 다운로드 후 업데이트
curl -fsSL [install-script-url] -o update.sh
chmod +x update.sh
./update.sh

# 완전 제거 (통합 관리)
./install.sh                          # → "완전 제거" 선택

# 빠른 제거 (현재 위치만)
rm ~/.local/bin/git-wt-* ~/.local/bin/git-tools-uninstall
```

### 환경 격리
- 다른 사용자에게 영향 없음
- 시스템 수준 변경 없음
- 자유로운 실험 가능

EOF
else
cat >> "$GUIDE_FILE" << 'EOF'
## 🏢 운영/공유 환경 특화 기능

### 팀 표준화
```bash
# 모든 팀원이 동일한 명령어 사용
git wt-jira TEAM-3349                 # → feature/TEAM-3349
git wt-jira QAT-456                   # → fix/QAT-456
# 표준화된 브랜치명: feature/TEAM-3349 또는 fix/QAT-456
# 표준화된 워크트리 경로: .worktrees/feature-TEAM-3349 또는 .worktrees/fix-QAT-456

# 팀 워크트리 상태 확인
git wt-list -v                        # 모든 워크트리 상세 정보

# 표준화된 정리 프로세스
git wt-clean                          # 선택 삭제
```

### CI/CD 통합
```yaml
# GitHub Actions 예시
steps:
  - name: Checkout
    uses: actions/checkout@v3
  
  - name: Create Worktree for Feature  
    run: |
      if [[ "${{ github.event.issue.key }}" == QAT-* ]]; then
        git wt-jira ${{ github.event.issue.key }}  # → fix/QAT-XXX
      else
        git wt-jira ${{ github.event.issue.key }}  # → feature/ISSUE-KEY
      fi
  
  - name: Run Tests in Worktree
    run: |
      BRANCH_PREFIX="feature"
      if [[ "${{ github.event.issue.key }}" == QAT-* ]]; then
        BRANCH_PREFIX="fix"
      fi
      cd .worktrees/$BRANCH_PREFIX-${{ github.event.issue.key }}
      npm test
```

### 팀 워크플로우
1. **표준 브랜치 생성**: 
   - 기능 개발: `git wt-jira PROJECT-123 develop` → `feature/PROJECT-123`
   - 버그 수정: `git wt-jira QAT-456 develop` → `fix/QAT-456`
2. **개발 진행**: 워크트리에서 작업
3. **상태 확인**: `git wt-list -v` → 팀 전체 워크트리 현황 파악
4. **완료 후 정리**: `git wt-clean` → 선택 삭제

### 관리 및 유지보수
```bash
# 시스템 전체 관리
./install.sh                          # 통합 관리 메뉴

# 방법 1: 직접 업데이트 (관리자만)
sudo curl -fsSL [install-script-url] | bash

# 방법 2: 파일 다운로드 후 업데이트
curl -fsSL [install-script-url] -o update.sh
chmod +x update.sh
sudo ./update.sh

# 시스템 전체 워크트리 확인 (fix/, feature/ 구분)
find /home -name ".worktrees" -type d 2>/dev/null | while read dir; do
  echo "📁 $dir:"
  ls -la "$dir" | grep -E "(fix-|feature-)" || echo "  No worktrees found"
done

# 팀 워크트리 현황 파악
git wt-list -v                        # 각 프로젝트에서 실행
```

### 보안 및 권한
- 시스템 수준 설치로 안정성 확보
- 모든 사용자가 동일한 버전 사용
- 중앙 집중식 관리 가능

EOF
fi

# 공통 사용법 추가
cat >> "$GUIDE_FILE" << 'EOF'
## 🔄 일반적인 워크플로우

1. **새 작업 시작**
   ```bash
   git wt-jira QAT-3349 develop      # 버그 수정: fix/QAT-3349
   git wt-jira PROJ-123 develop      # 기능 개발: feature/PROJ-123
   ```

2. **개발 진행**
   - 자동으로 워크트리로 이동됨
   - VSCode 자동 실행 (설치된 경우)
   - 의존성 자동 설치 (Node.js 프로젝트)

3. **작업 완료**
   ```bash
   git add .
   git commit -m "fix: resolve QAT-3349 issue"      # QAT 이슈
   git commit -m "feat: implement PROJ-123"        # 기타 이슈
   git push origin fix/QAT-3349                    # 또는 feature/PROJ-123
   ```

4. **정리**
   ```bash
   # 워크트리 정리 (권장)
   git wt-clean                             # 선택 삭제
   
   # 또는 수동 정리
   cd ..  # 메인 저장소로 이동
   git worktree remove .worktrees/fix-QAT-3349     # 또는 .worktrees/feature-PROJ-123
   ```

## 💡 팁과 모범 사례

- 워크트리는 `.worktrees/` 디렉토리에 생성됩니다
- 브랜치명은 자동으로 생성됩니다:
  - **QAT-*** 이슈 → `fix/QAT-XXXX` (버그 수정)
  - **기타** 이슈 → `feature/ISSUE-KEY` (기능 개발)
- VSCode가 설치되어 있으면 자동으로 열립니다
- Node.js 프로젝트는 의존성이 자동으로 설치됩니다
- `git wt-list -v`로 모든 워크트리 상태를 한눈에 확인
- `git wt-clean`으로 선택 삭제 (변경사항 보호)

## 🆘 문제 해결

문제가 발생하면:

1. 도움말 확인: `git wt-jira --help`
2. Git 저장소 확인: `git status`
3. 워크트리 목록: `git wt-list -v`
4. 워크트리 정리: `git wt-clean`
5. 통합 관리: `./install.sh`
6. 완전 제거 후 재설치: `./install.sh` → 완전 제거 선택
EOF

if [[ "$INSTALL_PURPOSE" == "development" ]]; then
cat >> "$GUIDE_FILE" << 'EOF'
6. 개인 환경 초기화: `rm ~/.local/bin/git-*`
EOF
else
cat >> "$GUIDE_FILE" << 'EOF'
6. 관리자에게 문의 또는 시스템 재설치
EOF
fi

success "맞춤 가이드 생성 완료: $GUIDE_FILE"

# ==========================================
# 최종 요약 (목적별 맞춤)
# ==========================================
header "🎉 설치 완료!"

if [[ "$INSTALL_PURPOSE" == "development" ]]; then
    echo -e "${GREEN}✅ 개발/테스트 환경 설치가 성공적으로 완료되었습니다!${NC}"
    echo ""
    echo -e "${CYAN}🧪 개발자 개인 환경 특징:${NC}"
    echo -e "  • 빠른 실험과 테스트에 최적화"
    echo -e "  • sudo 권한 불필요"
    echo -e "  • 언제든 쉽게 업데이트/제거 가능"
    echo -e "  • 다른 사용자에게 영향 없음"
else
    echo -e "${GREEN}✅ 운영/공유 환경 설치가 성공적으로 완료되었습니다!${NC}"
    echo ""
    echo -e "${CYAN}🏢 팀 공유 환경 특징:${NC}"
    echo -e "  • 모든 팀원이 동일한 도구 사용"
    echo -e "  • 표준화된 개발 워크플로우"
    echo -e "  • CI/CD 파이프라인 통합 가능"
    echo -e "  • 중앙 집중식 관리"
fi

echo ""
echo -e "${CYAN}📍 설치 정보:${NC}"
echo -e "  • 설치 위치: ${BOLD}$INSTALL_DIR${NC}"
echo -e "  • 설치 목적: ${BOLD}$([ "$INSTALL_PURPOSE" == "development" ] && echo "개발/테스트" || echo "운영/공유")${NC}"
echo -e "  • 도구 개수: ${BOLD}${#TOOLS[@]}개${NC}"
echo -e "  • 설치 모드: ${BOLD}$([ "$INSTALL_MODE" == "update" ] && echo "업데이트" || echo "새로설치")${NC}"

if [[ "$INSTALL_TYPE" == "user" ]] && [[ "$AUTO_PATH_SETUP" == "true" ]]; then
echo -e "  • PATH 설정: ${BOLD}자동 완료${NC}"
fi

echo ""
echo -e "${CYAN}🚀 즉시 사용해보세요:${NC}"
echo "  git wt-jira QAT-3349            # 버그 수정: fix/QAT-3349"
echo "  git wt-jira PROJ-123            # 기능 개발: feature/PROJ-123"
echo "  git wt-jira QAT-3349 develop    # develop 브랜치에서 생성"
echo "  git wt-list                     # 워크트리 목록 보기"
echo "  git wt-clean                    # 워크트리 선택 삭제"
echo "  git wt-jira --help              # 상세 도움말"

echo ""
echo -e "${CYAN}📖 맞춤 가이드:${NC}"
echo "  cat $GUIDE_FILE"

echo ""
echo -e "${CYAN}🛠️ 고급 관리:${NC}"
echo "  $0                      # 통합 관리 (검색/업데이트/제거)"
echo "  $UNINSTALL_SCRIPT           # 제거 스크립트 직접 실행"
echo "  curl -fsSL [URL] | bash              # 업데이트 (직접 실행)"

echo ""
if [[ "$INSTALL_PURPOSE" == "development" ]]; then
    echo -e "${CYAN}🧪 개발자를 위한 추천 첫 단계:${NC}"
    echo "1. Git 프로젝트로 이동: cd /path/to/your/git-project"
    echo "2. 첫 워크트리 생성: git wt-jira TEST-001 (→ feature/TEST-001)"
    echo "3. QAT 이슈 테스트: git wt-jira QAT-999 (→ fix/QAT-999)"
    echo "4. 워크트리 목록 확인: git wt-list -v"
    echo "5. 선택 삭제: git wt-clean"
    echo "6. 원하는 대로 커스터마이징하여 사용"
    echo ""
    echo -e "${YELLOW}💡 언제든 './install.sh'로 통합 관리 가능합니다!${NC}"
else
    echo -e "${CYAN}🏢 팀을 위한 추천 첫 단계:${NC}"
    echo "1. 팀원들에게 설치 방법 공유:"
    echo "   • 직접 실행: curl -fsSL [URL] | bash"
    echo "   • 파일 다운로드: curl -fsSL [URL] -o install.sh && chmod +x install.sh && ./install.sh"
    echo "2. 표준 워크플로우 정의 및 문서화"
    echo "3. 팀원 교육: git wt-list, git wt-clean 사용법"
    echo "4. CI/CD 파이프라인에 통합 검토"
    echo ""
    echo -e "${YELLOW}💡 './install.sh'로 시스템 전체 관리 현황을 확인할 수 있습니다!${NC}"
fi

if [[ "$INSTALL_TYPE" == "user" ]] && [[ "$AUTO_PATH_SETUP" == "true" ]]; then
    echo ""
    warn "새 터미널을 열거나 다음 명령어를 실행해주세요:"
    if [[ "$SHELL_NAME" == "zsh" ]]; then
        echo "  source ~/.zshrc"
    elif [[ "$SHELL_NAME" == "bash" ]]; then
        echo "  source ~/.bash_profile"
    else
        echo "  source $SHELL_RC"
    fi
fi

echo ""
success "🎊 $([ "$INSTALL_PURPOSE" == "development" ] && echo "개발/테스트" || echo "운영/공유") 환경 설치가 완전히 완료되었습니다!"
echo ""
echo -e "${PURPLE}🍎 macOS에서 $([ "$INSTALL_PURPOSE" == "development" ] && echo "개인 개발 환경에서" || echo "팀 전체가") Git 워크트리 도구를 사용할 수 있습니다!${NC}"
echo ""
echo -e "${CYAN}📋 다른 macOS 시스템에 설치하려면:${NC}"
echo -e "  ${YELLOW}방법 1${NC}: curl -fsSL [스크립트-URL] | bash"
echo -e "  ${YELLOW}방법 2${NC}: wget -qO- [스크립트-URL] | bash"  
echo -e "  ${YELLOW}방법 3${NC}: wget [스크립트-URL] -O install.sh && chmod +x install.sh && ./install.sh"
echo ""
echo -e "${CYAN}🔧 고급 관리:${NC}"
echo -e "  ${YELLOW}통합 관리${NC}: ./install.sh"
echo -e "  ${YELLOW}직접 제거${NC}: $UNINSTALL_SCRIPT"
echo ""
echo -e "${CYAN}🍎 macOS 특별 안내:${NC}"
echo -e "  • zsh 사용자: ~/.zshrc에 PATH가 자동 추가됨"
echo -e "  • Homebrew와 충돌 없음"
echo -e "  • VSCode와 완벽 연동"