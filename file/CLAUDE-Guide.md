# CLAUDE.md - AI 개발 컨텍스트 및 가이드라인

> 이 문서는 Claude가 본 프로젝트를 이해하고 효과적으로 협업하기 위한 종합적인 가이드입니다.

## 프로젝트 개요

**프로젝트명**: [프로젝트명]  
**설명**: [프로젝트 간단 설명]  
**아키텍처**: [아키텍처 설명 - 예: Serverless AI Workflows / Microservices / Monolith]

### 핵심 목표
- [목표 1]
- [목표 2]
- [목표 3]

---

## 도메인 용어 사전

### AI 에이전트 관련 용어 (Julep 기반)
- **Agent**: 메모리, 도구, 행동이 정의된 지속적 AI 엔티티 (Celery task가 아님)
- **Task**: 단계로 구성된 워크플로우 정의. 복잡한 다단계 프로세스 처리
- **Session**: 사용자와 에이전트 간의 상호작용 기간. 대화 컨텍스트 유지
- **Execution**: 실행 중인 Task 인스턴스. 상태 추적 및 진행 상황 모니터링
- **Tool**: 에이전트가 호출할 수 있는 함수 (브라우저, API, 데이터베이스 등)
- **Document Store**: RAG를 위한 문서 저장소. 검색 증강 생성 지원

### 프로젝트별 용어
- **[용어1]**: [정의]
- **[용어2]**: [정의]
- **[용어3]**: [정의]

---

## 기술 스택 및 아키텍처

### 백엔드 아키텍처
```
[서비스명1]: [역할 설명]
[서비스명2]: [역할 설명]
[서비스명3]: [역할 설명]
```

### 핵심 기술
- **언어**: [Python/TypeScript/JavaScript 등]
- **프레임워크**: [FastAPI/Express/Next.js 등]
- **데이터베이스**: [PostgreSQL/MongoDB/Redis 등]
- **AI/ML**: [OpenAI/Anthropic/Local Models 등]
- **인프라**: [Docker/Kubernetes/Serverless 등]

### 서비스 간 통신
- [서비스 간 통신 방식 설명]
- [API 계약 및 인터페이스]
- [이벤트 기반 아키텍처 여부]

---

## 코딩 스타일 및 컨벤션

### 언어별 스타일
**Python**:
- PEP 8 준수
- Type hints 필수 사용
- 함수/클래스 docstring 작성 (Google 스타일)
- `import` 순서: 표준 라이브러리 → 서드파티 → 로컬

**TypeScript/JavaScript**:
- ES 모듈 (import/export) 구문 사용, CommonJS (require) 사용 금지
- 가능한 경우 구조 분해 할당으로 import
- `async/await` 사용, Promise chaining 지양
- 명시적 타입 정의 (TypeScript)

### 네이밍 컨벤션
- **파일명**: kebab-case (user-service.py)
- **클래스명**: PascalCase (UserService)
- **함수/변수명**: snake_case (Python) / camelCase (JS/TS)
- **상수명**: UPPER_SNAKE_CASE
- **환경변수**: UPPER_SNAKE_CASE

### API 설계 원칙
- RESTful 설계 원칙 준수
- 명사 중심의 엔드포인트 네이밍
- HTTP 상태 코드 정확한 사용
- API 버전 관리 (v1, v2 등)

---

## 프로젝트 구조

```
project-root/
├── src/                    # 소스 코드
│   ├── agents/            # AI 에이전트 정의
│   ├── tasks/             # 워크플로우 태스크
│   ├── tools/             # 에이전트 도구
│   ├── services/          # 비즈니스 로직
│   ├── models/            # 데이터 모델
│   ├── api/               # API 엔드포인트
│   └── utils/             # 유틸리티 함수
├── tests/                 # 테스트 코드
│   ├── unit/              # 단위 테스트
│   ├── integration/       # 통합 테스트
│   └── e2e/               # E2E 테스트
├── docs/                  # 문서
├── config/                # 설정 파일
├── migrations/            # 데이터베이스 마이그레이션
└── scripts/               # 스크립트
```

---

## 빌드 및 실행 명령어

### 개발 환경
```bash
# 의존성 설치
npm install  # 또는 pip install -r requirements.txt

# 개발 서버 실행
npm run dev  # 또는 python -m uvicorn main:app --reload

# 테스트 실행
npm test     # 또는 pytest

# 타입 검사
npm run typecheck  # 또는 mypy .

# 린팅
npm run lint       # 또는 flake8 .

# 코드 포맷팅
npm run format     # 또는 black .
```

### 프로덕션 환경
```bash
# 빌드
npm run build

# 프로덕션 실행
npm start

# 도커 빌드
docker build -t [image-name] .

# 도커 실행
docker run -p 8000:8000 [image-name]
```

---

## AI 개발 가드레일 (CRITICAL)

### 🚫 절대 금지 사항
1. **테스트 파일 수정 금지** - 테스트는 인간의 의도를 인코딩함
2. **API 계약 변경 금지** - 실제 애플리케이션을 중단시킬 수 있음
3. **AIDEV-* 앵커 주석 제거 금지** - 미래 AI 상호작용을 위한 컨텍스트
4. **프로덕션 설정 수정 금지** - 환경 변수, 데이터베이스 연결 등
5. **보안 관련 코드 무단 수정 금지** - 인증, 권한, 암호화 로직

### ⚠️ 주의 필요 작업
- 데이터베이스 스키마 변경
- 외부 API 통합 수정
- 결제 처리 로직
- 사용자 데이터 처리
- 중요 비즈니스 로직

### ✅ 안전한 작업
- 코드 리팩토링 (동작 변경 없이)
- 성능 최적화
- 새로운 기능 추가 (기존 기능 영향 없음)
- 문서 업데이트
- 유틸리티 함수 추가

---

## 앵커 주석 시스템

### 사용법
코드베이스 전체에 AI가 읽을 수 있는 컨텍스트를 삽입하는 체계적 접근법:

```python
# AIDEV-NOTE: perf-critical; 이 함수는 초당 10K+ 요청 처리
async def process_high_volume_request():
    pass

# AIDEV-TODO: caching-layer; Redis 캐시 추가 필요 (예상 성능 향상: 60%)
def expensive_calculation():
    pass

# AIDEV-QUESTION: scalability; 동시 사용자 10K+ 지원 방안 검토 필요
class WebSocketManager:
    pass

# AIDEV-RISK: security; 사용자 입력 검증 강화 필요
def process_user_input(data):
    pass

# AIDEV-CONTEXT: legacy-integration; 기존 시스템과 호환성 유지 필요
def legacy_api_wrapper():
    pass
```

### 앵커 규칙
- 120자 이내로 간결하게 작성
- 기존 `AIDEV-*` 앵커 수정 시 반드시 확인 후 업데이트
- 복잡하거나 중요하거나 혼란스러운 코드에 추가
- 측정 가능한 정보 포함 (성능 지표, 타임라인 등)

---

## 개발 워크플로우

### 계획 우선 접근법
1. **문제 이해**: 요구사항과 현재 코드베이스 분석
2. **계획 수립**: 상세한 구현 계획 작성 (코드 작성 전)
3. **검토**: 계획의 타당성과 위험성 검토
4. **구현**: 승인된 계획에 따른 단계별 구현
5. **테스트**: 구현 결과 검증

### TDD 워크플로우
```bash
# 1. 테스트 작성
claude "새로운 기능의 테스트를 먼저 작성해줘"

# 2. 실패 확인
npm test  # 테스트가 실패하는 것을 확인

# 3. 구현
claude "테스트를 통과하도록 최소한의 코드를 구현해줘"

# 4. 리팩토링
claude "테스트를 유지하면서 코드를 개선해줘"
```

### AI 협업 모드
1. **페어 프로그래머**: 인간과 AI가 함께 설계하고 구현
2. **검증자**: 인간이 작성한 코드를 AI가 검토
3. **코드 생성기**: 반복적인 코드를 AI가 생성

---

## 에이전트 설계 패턴 (Julep 기반)

### 8-Factor Agent 방법론
1. **Prompts as Code**: 프롬프트를 별도 버전 관리
2. **Clear Tool Interfaces**: 명시적 도구 인터페이스 정의
3. **Model Independence**: 모델 제공업체 독립성 유지
4. **Context Management**: 명시적 상태 관리
5. **Ground Truth Examples**: 검증을 위한 명확한 예시
6. **Structured Reasoning**: 계획적/즉흥적 추론 분리
7. **Error Handling**: 강력한 오류 처리 및 복구
8. **Monitoring & Observability**: 포괄적 모니터링

### 에이전트 정의 패턴
```python
# 에이전트 생성 예시
agent = julep.agents.create(
    name="customer_support_agent",
    model="gpt-4-turbo",
    about="고객 지원을 위한 AI 에이전트",
    instructions=[
        "항상 정중하고 도움이 되는 응답을 제공하세요",
        "복잡한 문제는 인간 상담원에게 에스컬레이션하세요",
        "고객 데이터를 안전하게 처리하세요"
    ],
    tools=[
        "search_knowledge_base",
        "create_ticket",
        "send_email"
    ]
)
```

### 태스크 워크플로우 패턴
```yaml
# 복잡한 워크플로우 예시
workflow:
  - step: analyze_request
    type: llm_call
    prompt: "사용자 요청을 분석하고 카테고리를 분류하세요"
    
  - step: route_request
    type: conditional
    if: category == "technical"
    then: technical_support_flow
    else: general_support_flow
    
  - step: parallel_processing
    type: parallel
    tasks:
      - search_knowledge_base
      - check_user_history
      - validate_permissions
      
  - step: generate_response
    type: llm_call
    context: "이전 단계들의 결과"
    
  - step: quality_check
    type: validation
    criteria: "응답 품질 기준"
```

---

## 보안 고려사항

### 데이터 보호
- **PII 필드**: `email`, `phone`, `ssn`, `credit_card`, `address`
- **민감한 테이블**: `users`, `payments`, `personal_info`, `audit_logs`
- **암호화**: 저장 시 및 전송 시 암호화 필수

### 접근 제어
```python
# 환경별 AI 권한
DEVELOPMENT: ["read", "write", "delete", "deploy"]
STAGING: ["read", "write", "deploy"]  # 민감 데이터 제외
PRODUCTION: ["read"]  # 읽기 전용
```

### API 보안
- JWT 토큰 기반 인증
- Rate limiting 적용
- CORS 정책 설정
- 입력 검증 및 sanitization

---

## 모니터링 및 로깅

### 로그 레벨
- **DEBUG**: 상세한 디버깅 정보
- **INFO**: 일반적인 시스템 동작
- **WARNING**: 주의가 필요한 상황
- **ERROR**: 오류 발생
- **CRITICAL**: 시스템 중단 위험

### 메트릭
- 응답 시간
- 처리량 (RPS)
- 오류율
- 시스템 리소스 사용량
- AI 모델 호출 횟수 및 비용

### 알림
- 높은 오류율 (> 5%)
- 응답 시간 초과 (> 5초)
- 시스템 리소스 고갈 (CPU > 80%, Memory > 90%)
- AI 모델 API 한도 초과

---

## 테스트 전략

### 테스트 유형
```python
# 단위 테스트
def test_user_creation():
    user = create_user("test@example.com")
    assert user.email == "test@example.com"

# 통합 테스트
def test_agent_workflow():
    result = agent.execute_task("customer_inquiry", data)
    assert result.status == "completed"

# E2E 테스트
def test_full_customer_journey():
    # 사용자 등록부터 문제 해결까지 전체 플로우
    pass
```

### 테스트 커버리지
- 최소 85% 코드 커버리지 유지
- 중요 비즈니스 로직 100% 커버리지
- AI 에이전트 워크플로우 테스트 필수

---

## 환경 설정

### 필수 환경 변수
```bash
# 데이터베이스
DATABASE_URL=postgresql://...
REDIS_URL=redis://...

# AI 서비스
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-...

# 애플리케이션 설정
SECRET_KEY=your-secret-key
ENVIRONMENT=development|staging|production
DEBUG=true|false

# 외부 서비스
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
```

### 환경별 설정
- **Development**: 디버그 모드, 상세 로깅
- **Staging**: 프로덕션과 유사하지만 테스트 데이터
- **Production**: 최적화된 설정, 최소 로깅

---

## 문제 해결 가이드

### 일반적인 문제
1. **의존성 설치 오류**: 패키지 버전 충돌 확인
2. **데이터베이스 연결 실패**: 환경 변수 및 네트워크 확인
3. **AI 모델 API 오류**: API 키 및 요청 한도 확인
4. **성능 저하**: 쿼리 최적화 및 캐싱 검토

### 디버깅 팁
- 로그 레벨을 DEBUG로 설정
- 단위 테스트부터 차근차근 확인
- 네트워크 요청 모니터링
- 메모리 및 CPU 사용량 확인

---

## 기여 가이드라인

### Pull Request 프로세스
1. 이슈 생성 및 할당
2. 브랜치 생성 (`feature/`, `bugfix/`, `hotfix/`)
3. 코드 작성 및 테스트
4. 문서 업데이트
5. PR 생성 및 리뷰 요청
6. 리뷰 반영 및 머지

### 코드 리뷰 체크리스트
- [ ] 테스트 커버리지 충족
- [ ] 문서 업데이트 완료
- [ ] 보안 검토 완료
- [ ] 성능 영향 검토
- [ ] 앵커 주석 적절히 추가/수정

---

## 참고 자료

### 내부 문서
- [API 문서](./docs/api.md)
- [아키텍처 설계서](./docs/architecture.md)
- [배포 가이드](./docs/deployment.md)

### 외부 자료
- [Julep 공식 문서](https://docs.julep.ai/)
- [Claude 개발 모범 사례](https://www.anthropic.com/engineering/claude-code-best-practices)
- [AI 에이전트 패턴](https://github.com/julep-ai/awesome-ai-agents)

---

## 업데이트 이력

| 날짜 | 버전 | 변경 사항 | 작성자 |
|------|------|-----------|--------|
| 2025-06-09 | 1.0.0 | 초기 문서 작성 | [작성자명] |

---

**중요**: 이 문서는 Claude와의 효과적인 협업을 위한 핵심 자료입니다. 프로젝트 변경 시 반드시 업데이트하고, 모든 팀원이 숙지해야 합니다.