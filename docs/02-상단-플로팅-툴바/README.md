# 상단 플로팅 툴바

## 목표
윈도우 좌상단에 **캡슐(pill) 모양 + 그림자** 가 있는 floating 영역을 띄우고, 그 안에 사이드바 토글 버튼과 '+' 버튼을 가로로 둔다. 실제 기능 동작은 추후 단계에서.

## 의존 관계
- 사전 필요: 기능 01 (타이틀바 호버 표시) — 콘텐츠가 타이틀바 영역까지 확장된 상태가 출발점
- 이후 영향: 사이드바 토글 / 새 일정 추가 같은 후속 기능들이 이 영역의 버튼에 연결될 자리

## 단계 체크리스트
- [x] 01 - 플로팅 컨테이너 만들기 (HStack + 배경 + 모서리 + 그림자)
- [ ] 02 - 버튼과 SF Symbols
- [ ] 03 - Material 배경으로 vibrancy 적용

## 이 기능에서 학습할 Swift / SwiftUI 개념
- `HStack` 으로 가로 layout 구성
- `.padding`, `.background`, `.clipShape(Capsule())`, `.shadow` 의 modifier 체이닝과 **순서**
- `Capsule` shape — `RoundedRectangle` 의 특수형 (양 끝이 반원)
- `Button { action } label: { ... }` 패턴과 trailing closure 두 개
- SF Symbols (`Image(systemName:)`) — Apple 이 제공하는 시스템 아이콘 라이브러리
- `.buttonStyle(.plain)` — macOS 기본 button chrome 벗기기
- `Material` (`.regularMaterial` 등) — vibrancy/blur 효과와 다크/라이트 자동 대응
- 기존 `ZStack(alignment: .topLeading)` 위에 floating 레이어 한 층 더 얹기

## 결과물 (이 기능 완료 후)
- 윈도우 좌상단에 **캡슐(pill) 모양 + 가벼운 그림자** 가 있는 floating 영역이 떠 있다.
- 그 안에 사이드바 모양 아이콘 1개 + '+' 아이콘 1개가 가로로 배치된다.
- 클릭은 가능하지만 아직 실제 동작은 없다 (액션은 빈 클로저 / print 정도).
- 트래픽라이트가 호버로 나타날 때, floating 영역과 시각적으로 겹치지 않는다.
- 시스템 외관(다크/라이트)을 바꿔도 카드 톤이 자연스럽게 적응한다.
