# 07 — 사이드바 토글 다듬기

## 목표
사이드바 토글의 시각/구조 품질을 끌어올린다. 보이는 애니메이션만 고치는 게 아니라, 그 과정에서 드러난 두 가지 SwiftUI 핵심 — **View identity** 와 **View 와 데이터의 분리** — 까지 같이 짚는다.

## 의존 관계
- 사전 필요: 기능 03 (사이드바 슬라이드), 기능 05 (월간 달력 UI)
- 이후 영향: 이후 모든 View 에서 Store 패턴 재사용. 캘린더의 prev/next 월 이동, 이벤트 fetch 등은 모두 이 단계의 Store 위에서 자란다.

## 출발점의 문제

기능 03 에서 만든 토글 (`if isSidebarVisible { Sidebar() }` + `.transition(.move(edge: .leading))`) 에는 두 가지 거슬리는 점이 있었다:

1. **일 그리드 영역이 토글 때마다 페이드 아웃/인** — 사이드바와 무관한 영역이 흐려졌다 돌아옴.
2. **사이드바 자체의 등장이 캘린더와 별개로 "끼어드는" 느낌** — 자연스럽게 캘린더가 좁아지면서 사이드바가 펼쳐지는 게 아니라, 슬라이드 + 페이드가 섞임.

분석 결과:
- 2번은 transition 방식 자체의 한계 — `if` 로 자식이 추가/제거되면 형제 view 의 layout 변화에 default transition 이 묻어 들어옴.
- 1번 원인은 기능 05 의 **`DayCell.id = UUID()`** — body 재평가마다 모든 셀의 id 가 새로 발급돼서 SwiftUI 가 "이전 셀들 사라짐 / 새 셀들 등장" 으로 보고 `withAnimation` 컨텍스트의 기본 `.opacity` transition 을 발동.
- 더 깊이는 **`makeDayCells` 가 매번 호출되는 구조** — View struct 의 init 에 무거운 일이 쌓이면 앞으로 이벤트/공휴일 fetch 가 추가될 때 부하가 누적.

## 단계 체크리스트
- [x] 01 - 펼침 애니메이션: frame 너비 + .clipped()
- [x] 02 - DayCell id 안정화: 자연키 패턴
- [ ] 03 - CalendarStore 도입: ObservableObject + @StateObject

## 이 기능에서 학습할 Swift / SwiftUI 개념
- `.clipped()` 와 frame 두 겹 트릭 (외부 frame 으로 reported width, 내부 frame 으로 layout 고정)
- View identity — `id` 가 안정적이어야 하는 이유, UUID 가 문제인 시점, 자연키 (natural key) 패턴
- 기본 transition 의 함정 — `withAnimation` 안에서 identity 가 깨지면 자동 fade
- `ObservableObject` / `@Published` / `@StateObject` — 데이터 lifecycle 을 View 밖으로
- `@MainActor` — UI 와 닿는 비동기 코드의 thread 보장
- "View struct = 가벼운 템플릿, Store class = 상태 보유자" 의 분리
