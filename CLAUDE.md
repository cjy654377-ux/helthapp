# HealthApp - Flutter Health & Fitness Application

## Project Overview
- **Product**: Health & fitness mobile app (운동 가이드, 기록, 커뮤니티, 식단, 캘린더)
- **Platform**: iOS + Android (Flutter)
- **Org**: com.rhythmicaleskimo
- **Goal**: Fast completion -> Global deployment -> Revenue generation
- **User**: Non-developer, communicate in clear Korean

## Agent Structure & Delegation Rules

### Opus (Main - This Agent)
**Heavy decisions only. Never do repetitive work directly.**
- Architecture design & tech stack decisions
- Feature priority decisions
- Distribute tasks to sub-agents
- Final code quality review
- Deployment strategy & monetization decisions
- Complex bug root cause analysis

### Sonnet (sonnet-implementer)
**All substantive code implementation. Delegate proactively.**
- Workout tracking & logging features
- Exercise guide & AI coaching integration
- Community/team features
- Diet/nutrition tracking
- Calendar & workout planning
- State management (Riverpod)
- API integration (monetization, analytics, backend)
- Complex UI components
- Performance optimization
- Test code (unit, widget, integration)
- App store build configuration

### Haiku (haiku-worker)
**All repetitive/simple tasks. Use aggressively to save tokens.**
- File creation, copy, move, delete
- Localization ARB file generation (17 languages)
- Boilerplate code generation
- Config file templates
- Comments and documentation
- JSON/CSV format conversion
- App store description drafts (per language)
- Icon/image file organization
- Exercise database seed data generation

## Decision Flow
1. Can Haiku do it? -> Delegate to Haiku
2. Is it code implementation? -> Delegate to Sonnet
3. Is it architecture/strategy? -> Handle directly

## Parallel Execution Rules
- **독립적인 서브에이전트 작업은 반드시 병렬 호출할 것**
- 예: ARB 파일 수정(Haiku) + 코드 구현(Sonnet) -> 동시 실행
- 예: 여러 독립 파일 생성 -> 병렬 Task 호출
- **단, 의존 관계가 있는 작업은 순차 실행** (예: Provider 생성 후 -> Screen에서 import)

## Conflict Prevention
- **같은 파일을 여러 에이전트가 동시에 수정하지 말 것**
- 에이전트 위임 시 수정 대상 파일을 명확히 분리할 것
- 한 에이전트가 작업 중인 파일에 다른 에이전트가 접근하면 중첩 오류 발생
- 병렬 작업 분배 시 파일 소유권을 명시: "Sonnet -> workout_screen.dart, Haiku -> ARB 파일들"
- 동일 파일에 대한 작업이 필요하면 순차 처리로 전환

## Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (flutter_riverpod)
- **Navigation**: go_router
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Monetization**: RevenueCat (purchases_flutter) + AdMob (google_mobile_ads)
- **Localization**: flutter_localizations + intl
- **Analytics**: Firebase Analytics + Crashlytics
- **Deployment**: Fastlane
- **Charts**: fl_chart
- **Calendar**: table_calendar
- **Image Picker**: image_picker
- **Health Data**: health (Apple Health / Google Fit)

## Core Features
1. **운동 가이드**: 부위별/기구별 운동 방법 (비디오/애니메이션)
2. **운동 기록**: 세트/반복/무게 기록, 휴식 타이머, PR 추적
3. **팀 커뮤니티**: 팀 생성, 운동 기록/사진 공유, 팀 방명록
4. **식단 관리**: 오늘의 식단, 칼로리/매크로 추적, 바코드 스캔
5. **수분 보충**: 물 섭취 추적, 알림, 홈화면 위젯
6. **캘린더**: 운동 스케줄링, 스플릿 계획, 알림
7. **AI 코칭**: 개인화 운동 추천, 폼 가이드
8. **진행 추적**: 체중/체성분 변화, Before/After 사진, 차트

## Coding Standards
- `flutter analyze` before any commit
- `dart format .` for formatting
- `flutter test` must pass
- Null safety: strict, no `dynamic`
- File naming: snake_case, Class naming: PascalCase
- Feature-first directory structure under lib/features/
- All strings via i18n keys (no hardcoded strings)
- Error handling always included
- Korean comments allowed for readability

## Supported Languages (17)
ko, en, ja, zh-CN, zh-TW, es, fr, de, pt, it, ru, ar (RTL), hi, id, th, vi, tr

## Decision Logging (MANDATORY)
- **모든 중요한 결정은 반드시 `decisions.md`에 기록할 것**
- 기술 스택 선택, 아키텍처 변경, 수익화 전략 등
- 형식: `D-XXX: 결정명` + 결정 내용 + 대안 + 이유
- 새 세션/컨텍스트 시작 시 반드시 `decisions.md`부터 읽을 것
- 컨텍스트 정리(/compact) 전에 미기록 결정이 있으면 먼저 기록

## Context Management
- Split work into independent small units
- Save results to files at each stage completion
- Warn when too many large files in one context

### Token Limit Protocol (토큰 한계 도달 시)
**토큰/컨텍스트 한계 임박 감지 시 반드시 다음 순서 실행:**
1. 현재 작업 상태를 `decisions.md`에 기록 (진행 중인 작업, 완료된 작업, 다음 작업)
2. 미기록 결정사항이 있으면 `decisions.md`에 추가
3. 변경된 파일 `git add` + `git commit` (메시지: "checkpoint: [작업 요약]")
4. `git push` (원격 설정 시)
5. 사용자에게 컨텍스트 클리어 안내

```
Token Limit Warning:
Status: [현재 상태 요약]
Saved to: decisions.md
Committed: [커밋 해시]
Action: /compact 또는 새 세션 시작 권장
Resume: decisions.md 읽고 [다음 작업] 부터 재개
```

### Self-Review Cycle (자가 리뷰 루프)
각 작업 단위 완료 후:
1. `flutter analyze` 실행 → 경고/에러 0 목표
2. `flutter test` 실행 → 테스트 통과 확인
3. 추가/개선 가능한 항목 조사
4. 다음 작업 결정 후 반복
5. 매 사이클마다 토큰/컨텍스트 여유 확인

### Compact Trigger
When detected:
- 3+ large files in same context
- 5+ repeated error debugging cycles
- Excessive code accumulation
- Token usage approaching limit

Output:
```
Warning: Compact recommended
Reason: [one line]
Method: Enter /compact in Claude Code
Next: [what to continue after]
```

### Checkpoint Format
```
Checkpoint: [stage name] complete
Saved files: [list]
Next stage: [task name]
New context recommended: [yes/no]
```

## Output Principles
- Concise and clear - no unnecessary explanation
- No emotional expressions - skip praise, empathy, greetings
- Conclusion first - result before reason
- No repetition - don't re-state what's been said
- Tech terms: one-line explanation only
- Errors: cause + solution only
- Options: option + one-line pros/cons only
