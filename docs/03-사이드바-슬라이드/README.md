# 사이드바 슬라이드

## 목표
플로팅 툴바의 사이드바 버튼을 누르면 화면 왼쪽에서 사이드바가 슬라이드되며 펼쳐지고, 다시 누르면 접힌다. 메인 콘텐츠와 플로팅 툴바는 사이드바 폭만큼 자연스럽게 우측으로 밀려난다 (push 방식). 트래픽라이트는 윈도우 좌상단에 고정.

## 의존 관계
- 사전 필요: 기능 02 (상단 플로팅 툴바) — 토글 버튼이 이미 자리잡혀 있고 print 만 찍는 상태
- 이후 영향: 사이드바 안에 들어갈 콘텐츠 (캘린더 목록, 미니 캘린더 등) 가 후속 기능에서 채워짐

## 단계 체크리스트
- [ ] 01 - 상태 끌어올리기 + `@Binding`
- [ ] 02 - Sidebar 뷰 + 조건부 레이아웃 (push)
- [ ] 03 - slide-in/out 애니메이션 + transition

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **State lifting** — 여러 뷰가 공유하는 상태는 가장 가까운 공통 부모에 둔다는 원칙
- **`@Binding`** — `@State` 의 양방향 참조를 자식에게 넘기는 도구 (Vue `v-model` 과 같은 발상)
- **`$` prefix (projected value)** — `@State` 변수에서 `Binding` 을 추출하는 문법
- **`@Binding` 의 init 규칙** — default 값 못 줌, 호출 측이 항상 명시 전달, `.constant(_:)` 로 preview 우회
- 작은 새 뷰 분리 (`Sidebar.swift`) + `Features/Sidebar/` 폴더 신설
- **HStack 기반 push 레이아웃** — 조건부 자식이 들어왔다 빠질 때 옆 콘텐츠가 자연스럽게 밀리는 발상
- **`if` 문을 SwiftUI body 안에서 사용** — 실제로는 `_ConditionalContent` 로 변환됨, 평범한 Swift if 가 아님
- **`.overlay(alignment:)` vs `ZStack`** — 같은 레이어링이지만 의미가 다름 (overlay 는 부모 size 에 종속, ZStack 은 자식들끼리)
- **`withAnimation { ... }` (명시) vs `.animation(_:value:)` (암시)** — 둘 다 있는 이유
- **`.transition(...)`** — 뷰가 추가/제거될 때의 등장/퇴장 효과 (`.move(edge: .leading)`)
- **Spring animation** (`.spring`, `.smooth`, `.snappy`, `.bouncy`) — Apple 이 macOS 14+ 에서 정리한 시맨틱 spring presets
- 매끄러운 사이드바 toggle 의 macOS 표준 UX

## 결과물 (이 기능 완료 후)
- 플로팅 툴바의 사이드바 아이콘 클릭 시 좌측에서 사이드바가 부드럽게 슬라이드되며 펼쳐진다.
- 한 번 더 클릭하면 부드럽게 접힌다.
- 메인 콘텐츠 영역과 플로팅 툴바가 사이드바 폭만큼 우측으로 밀려나며, 같은 spring 곡선으로 함께 움직인다.
- 트래픽라이트 영역은 항상 윈도우 좌상단 고정 (사이드바와 무관).
- 사이드바는 placeholder (단색/Material 배경 + 고정 폭) — 안의 콘텐츠는 후속 기능에서.
