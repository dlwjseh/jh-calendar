# 상단 플로팅 툴바

## 목표
윈도우 좌상단에 **캡슐(pill) 모양 + 그림자** 가 있는 floating 영역을 띄우고, 그 안에 사이드바 토글 버튼과 '+' 버튼을 가로로 둔다. 실제 기능 동작은 추후 단계에서.

## 의존 관계
- 사전 필요: 기능 01 (타이틀바 호버 표시) — 콘텐츠가 타이틀바 영역까지 확장된 상태가 출발점
- 이후 영향: 사이드바 토글 / 새 일정 추가 같은 후속 기능들이 이 영역의 버튼에 연결될 자리

## 단계 체크리스트
- [x] 01 - 플로팅 컨테이너 만들기 (HStack + 배경 + 모서리 + 그림자)
- [x] 02 - 버튼과 SF Symbols
- [x] 03 - Material 배경으로 vibrancy 적용
- [ ] 04 - 버튼 호버 시 손모양 커서
- [ ] 05 - IconButton 뷰로 분리 + hover 배경

## 이 기능에서 학습할 Swift / SwiftUI 개념
- `HStack` 으로 가로 layout 구성
- `.padding`, `.background`, `.clipShape(Capsule())`, `.shadow` 의 modifier 체이닝과 **순서**
- `Capsule` shape — `RoundedRectangle` 의 특수형 (양 끝이 반원)
- `Button { action } label: { ... }` 패턴과 trailing closure 두 개
- SF Symbols (`Image(systemName:)`) — Apple 이 제공하는 시스템 아이콘 라이브러리
- `.buttonStyle(.plain)` — macOS 기본 button chrome 벗기기
- `Material` (`.regularMaterial` 등) — vibrancy/blur 효과와 다크/라이트 자동 대응
- 기존 `ZStack(alignment: .topLeading)` 위에 floating 레이어 한 층 더 얹기
- `.pointerStyle(.link)` — macOS 15+ 의 SwiftUI 표준 cursor modifier 와 `PointerStyle` enum
- 작은 View 로 분리 + 멤버 변수로 파라미터 받기 (memberwise initializer)
- `@State` 로 뷰 인스턴스의 UI 상태 (hover 여부) 관리
- default 파라미터 값으로 호출 측 짧게 유지 (Java 오버로딩 흉내 → Swift 한 줄)
- `Color.primary.opacity(...)` 로 다크/라이트 자동 대응되는 hover 톤
- 조건부 modifier 값 (state 에 따라 `.background` 색 바꾸기)

## 결과물 (이 기능 완료 후)
- 윈도우 좌상단에 **캡슐(pill) 모양 + 가벼운 그림자** 가 있는 floating 영역이 떠 있다.
- 그 안에 사이드바 모양 아이콘 1개 + '+' 아이콘 1개가 가로로 배치된다.
- 클릭은 가능하지만 아직 실제 동작은 없다 (액션은 빈 클로저 / print 정도).
- 버튼 위에 마우스를 올리면 커서가 손모양(pointing hand)으로 바뀌고, 빠지면 다시 화살표로 돌아온다.
- 버튼 위에 마우스를 올리면 **버튼 배경이 살짝 어두워져** hover 가 시각적으로 표시되고, 빠지면 원상복귀한다. 다크/라이트 모드 모두 자연스럽게 보인다.
- 두 버튼은 각자 독립적인 hover 상태를 가진다 (한쪽만 어두워짐).
- 트래픽라이트가 호버로 나타날 때, floating 영역과 시각적으로 겹치지 않는다.
- 시스템 외관(다크/라이트)을 바꿔도 카드 톤이 자연스럽게 적응한다.
