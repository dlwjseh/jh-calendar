# 타이틀바 호버 표시

## 목표
macOS 의 기본 타이틀바("JHCalendar" 글자가 박힌 회색 줄) 를 숨기고, 트래픽라이트 버튼(빨/노/초)도 평소엔 보이지 않다가 좌상단에 마우스를 올리면 부드럽게 페이드 인 되도록 만든다.

## 의존 관계
- 사전 필요: 없음 (첫 기능)
- 이후 영향: 윈도우 chrome 이 사라진 상태가 기본이 되므로, 이후 사이드바/툴바 디자인의 출발점이 된다.

## 단계 체크리스트
- [x] 01 - 기본 타이틀바 숨기기
- [x] 02 - 트래픽라이트 버튼 직접 제어
- [x] 03 - 호버 영역과 상태 관리
- [x] 03-A - content view 를 타이틀바 영역까지 확장 *(03 진행 중 발견 — 단계 1 보강)*
- [ ] 04 - 페이드 인/아웃 애니메이션

## 이 기능에서 학습할 Swift / SwiftUI 개념
- `Scene` / `WindowGroup` 와 `.windowStyle` modifier
- SwiftUI 와 AppKit (NSWindow, NSButton) 의 관계 — SwiftUI 는 AppKit 위의 추상화
- `NSApplication.shared.windows`, `NSWindow.standardWindowButton(_:)`
- `@State` 와 `.onHover { }` modifier
- `ZStack` 과 `alignment` 로 레이어/배치
- `OptionSet` 과 `NSWindow.styleMask` (`.fullSizeContentView`)
- SwiftUI 의 safe area 와 `.ignoresSafeArea()` — AppKit/SwiftUI 두 레이어의 inset 정렬
- `withAnimation { }` 과 `Animation.easeInOut`
- AppKit 뷰의 애니메이션 (`.animator()`, `NSAnimationContext`)

## 결과물 (이 기능 완료 후)
- 앱 윈도우에 타이틀바 줄/제목이 없다.
- 평소엔 트래픽라이트 버튼이 보이지 않는다.
- 좌상단 약 100×40 영역에 마우스를 올리면 버튼이 0.2초쯤 걸쳐 부드럽게 나타난다.
- 마우스가 벗어나면 다시 부드럽게 사라진다.
