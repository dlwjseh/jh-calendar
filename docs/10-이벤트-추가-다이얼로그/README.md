# 이벤트 추가 다이얼로그

## 목표
`FloatingToolbar` 의 `+` 버튼을 누르면 이벤트 추가 다이얼로그가 떠서, **카테고리(필수) · 이벤트명 · 종일 여부** 세 가지를 입력해 저장한다. 09 의 폴더/카테고리와 동일한 mode enum 패턴으로 만들어, 추후 편집 진입까지 자연스럽게 이어진다.

## 의존 관계
- 사전 필요: `02` (FloatingToolbar), `09` (SwiftData 영속화 + Dialog 패턴)
- 이후 영향: 시작/종료 시각·반복·알람 같은 일정 부가 속성이 모두 이 모델 위에 얹힘. 월간 뷰에서 카테고리 색으로 이벤트 점·바를 그리는 후속 기능의 기반.

## 핵심 변경 요약
- `Event` `@Model` 신설 — `name: String`, `isAllDay: Bool`, `category: Category?`
- `Category` 에 역방향 `events: [Event]` (`@Relationship(deleteRule: .nullify)`) 추가
- `AddEventDialog` 신설 — 09 의 `AddCategoryDialog` 와 같은 폼/Backdrop 패턴, **`Toggle`** 로 종일 여부 표현
- `EventDialogMode` enum — `.add` / `.edit(Event)`
- `ContentView` 에 `eventDialog` state + `FloatingToolbar` 로 `@Binding` 전달
- `FloatingToolbar` 의 `+` 버튼 → `eventDialog = .add`

## 단계 체크리스트
- [x] 01 - Event @Model + Category 관계
- [x] 02 - AddEventDialog UI (Toggle · Mode enum)
- [x] 03 - FloatingToolbar `+` 연결 + 저장
- [x] 04 - 시간입력 오전/오후 토글 (focusable · onMoveCommand) — 커스텀 시간 입력기 1조각

> 후속(별도 단계 예정): 시·분 입력 + `Event` 에 시각 필드 추가 + `BorderlessTimePicker` 데이터 바인딩. 현재 타임피커는 UI만(오전/오후), 아직 `Event` 에 저장 안 됨.

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **`Toggle`** — Bool 상태를 스위치/체크박스 UI 로 표현. macOS 기본 스타일과 `.switch` / `.checkbox` 스타일 차이.
- **관계 deleteRule 의 선택 — `.nullify`** — 09 의 `.cascade` 와 대비. 카테고리를 지워도 이벤트 자체는 살려두는 정책.
- **`.focusable()` + `.onMoveCommand`** (04) — 입력 컨트롤이 아닌 일반 뷰를 키보드 포커스 가능하게 만들고, 방향키를 가로채 상태 토글. 기본 `DatePicker` 대신 커스텀 시간 입력기를 직접 만드는 기반.
- (응용) SwiftData 양방향 관계 · `modelContext` 자동 dirty tracking · mode enum 다이얼로그 — 09 패턴을 새 모델에 그대로 재적용.

## 자바/스프링 비유 한 줄 매핑
| Spring (JPA) | 이 단계에 대응 |
|---|---|
| `@OneToMany(cascade = {}, orphanRemoval = false)` | `@Relationship(deleteRule: .nullify, inverse: \Event.category)` |
| `event.setCategory(null)` 후 flush | `category` 가 nil 인 `Event` — 가능 (Optional) |
| `JCheckBox` (Swing) | SwiftUI `Toggle` |
