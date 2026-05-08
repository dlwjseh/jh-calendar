# 단계 3: slide-in/out 애니메이션 + transition

## 학습 목표
- SwiftUI 의 두 가지 애니메이션 진입점을 구분한다: **명시적** `withAnimation { ... }` 와 **암시적** `.animation(_:value:)`.
- **`.transition(...)`** 이 무엇이고 `withAnimation` 과 어떻게 함께 동작하는지 이해한다 — 애니메이션 = "값이 변할 때" / transition = "뷰가 추가/제거될 때".
- macOS 14+ 의 정리된 spring presets (`.spring`, `.smooth`, `.snappy`, `.bouncy`) 의 의미를 익히고, 이 사이드바 케이스에 맞는 곡선을 고른다.
- 사이드바가 좌측에서 슬라이드되어 들어왔다 빠지고, 메인 영역이 같은 곡선으로 함께 밀리도록 만든다.

## 사전 지식
- 단계 2 완료: HStack 기반 push 레이아웃 + 조건부 `if` + Sidebar.swift 가 살아 있고, 사이드바가 즉시 뚝뚝 토글된다.
- `if` 안의 자식이 SwiftUI 에서 **추가/제거** 로 식별된다는 사실 (단계 2 의 `_ConditionalContent` 설명).

## Swift / SwiftUI 개념

### 1) 선언형 애니메이션 — "어떻게" 가 아니라 "언제 / 어떤 곡선"

UIKit / AppKit 에서 애니메이션은 보통 절차적이다 — `UIView.animate(withDuration: ...)` 안에서 frame 을 바꾸고, 프레임워크가 보간. SwiftUI 는 다른 발상이다:

> **"이 상태가 바뀔 때 (value), 이 곡선으로 (animation), 자동으로 보간하라."**

상태 (`@State`/`@Binding`) 가 바뀌면 SwiftUI 가 view-tree 의 **이전 모습 ↔ 새 모습** 을 자동으로 비교 (diff) 하고, 너가 지정한 곡선으로 사이를 채워준다. 우리는 "어떻게 움직일지" 를 일일이 안 짠다 — 그냥 두 상태를 선언하고 곡선만 알려준다.

Vue 비유: `<Transition>` 컴포넌트 + CSS transition 의 발상과 같음. CSS 클래스 (`v-enter-from`, `v-enter-to`) 대신 SwiftUI 는 view 두 상태를 자동 비교.

### 2) 두 가지 진입점 — `withAnimation { }` vs `.animation(_:value:)`

**(a) 명시적 — `withAnimation`**

```swift
withAnimation(.spring(duration: 0.3)) {
    isSidebarVisible.toggle()
}
```

- "이 **상태 변경** 을 spring 곡선으로 처리해 줘."
- 그 변경에 의해 영향받는 모든 뷰의 변화가 같은 곡선을 탄다.
- 호출 코드 (= 액션 클로저) 안에서 명시적으로 감싼다.

**(b) 암시적 — `.animation(_:value:)`**

```swift
HStack(spacing: 0) {
    if isSidebarVisible { Sidebar() }
    MainArea()
}
.animation(.smooth, value: isSidebarVisible)
```

- "이 view 와 그 자식들의 변화를 추적하다가, `isSidebarVisible` 이 바뀌면 자동으로 smooth 곡선 적용."
- 액션 코드를 안 건드리고 view 쪽에 한 줄로 끝.
- 동일 view 의 다른 변화도 같이 묶이지 않게 `value:` 인자로 **trigger 를 명시**.

> 옛날엔 `.animation(_:)` 만 있었는데 (모든 변화를 묶어버려 위험), 지금은 `value:` 가 있는 형태가 표준. 옛 형태는 deprecated.

**언제 어느 걸 쓰나?**

- 토글이 사용자 액션 한 곳에서만 일어나고 그 결과가 view-tree 곳곳에 퍼진다 → **`withAnimation` 이 깔끔**. "이 액션은 이런 곡선으로" 가 의도가 분명.
- view 한 덩어리가 특정 값에 반응해 늘 같은 곡선으로 움직이길 원한다 → **`.animation(_:value:)` 가 깔끔**.
- 둘 다 OK. 본 단계에선 `withAnimation` 으로 시작 — 토글 동작이 한 액션이라 의도 표현이 더 직설적.

### 3) `.transition(...)` — 뷰가 *생기거나 사라질 때* 의 등장/퇴장 효과

여기가 처음 헷갈리는 지점. 정리:

- **animation**: "이 뷰가 *계속 존재하면서 속성이 바뀔 때*" 의 곡선 — 위치/크기/색 등의 보간.
- **transition**: "이 뷰가 *생기거나 사라질 때*" 의 등장/퇴장 효과.

`if isSidebarVisible { Sidebar() }` 의 Sidebar 는 false 일 때 view-tree 에서 **사라진다** (그냥 작아지는 게 아니라 자식이 빠짐). 이 "사라짐 / 다시 생김" 의 모양을 정하는 게 transition.

**그냥 transition 만 붙이면 동작하나?**

```swift
if isSidebarVisible {
    Sidebar()
        .transition(.move(edge: .leading))
}
```

이것만으로는 안 움직인다. transition 은 "어떤 모양으로 등장/퇴장 하는지" 의 **카탈로그** 일 뿐, 실제 보간을 trigger 하려면 그 변화가 애니메이션 컨텍스트 안에서 일어나야 한다 → `withAnimation { isSidebarVisible.toggle() }` 또는 `.animation(_:value:)`.

> 즉 둘은 항상 짝이다: **transition 은 "어떻게 나타나고 사라지는지" + animation 은 "이 변화에 시간을 입혀라"**.

### 4) `.move(edge: .leading)` — 좌측에서 슬라이드되는 transition

```swift
.transition(.move(edge: .leading))
```

- 등장 시: 자기 폭만큼 왼쪽 바깥에서 슬라이드 → 제자리.
- 퇴장 시: 제자리 → 왼쪽 바깥으로 슬라이드.

다른 옵션:
- `.opacity` — 페이드 인/아웃 (사이드바엔 어울리지 않음).
- `.scale` — 확대/축소.
- `.slide` — `.move(edge: .leading)` 와 비슷하지만 약간 다름.
- `.asymmetric(insertion:removal:)` — 등장/퇴장에 다른 transition.
- `.combined(with:)` — 여러 transition 합치기 (move + opacity 같이).

이 단계에선 `.move(edge: .leading)` 으로 충분. 한 줄에 의도가 명확.

### 5) macOS 14+ 의 spring 시맨틱 presets

옛 SwiftUI 에선 `.easeInOut(duration: 0.3)` / `.spring(response: ..., dampingFraction: ...)` 등 매직 넘버 튜닝이 많았다. macOS 14 / iOS 17 부터 Apple 이 정리해 시맨틱 이름을 줬다:

- `.smooth` — 살짝 느릿하고 부드러운 spring. 일반 UI 변화에 무난.
- `.snappy` — 빠르고 단단함. 토글/탭 직후 즉답 느낌.
- `.bouncy` — 살짝 통통 튀는 spring. 장난스러운 톤.
- `.spring(duration:bounce:)` — 위 셋의 일반화. duration 은 0.3~0.5 정도, bounce 는 0.0 (단단) ~ 0.5 (튐).

사이드바엔 `.smooth` 또는 `.snappy` 가 자연스럽다. `.bouncy` 는 캘린더 톤에 안 어울림. duration 은 0.3 전후가 macOS 표준.

> presets 를 외우려 하기보단, 두세 개를 직접 시도해보고 "이 화면엔 이게 어울린다" 를 손으로 익히는 게 빠르다.

### 6) push 레이아웃 + transition 의 협동

이게 단계 2 의 `_ConditionalContent` 설명이 결정적으로 의미를 갖는 지점이다.

`if isSidebarVisible { Sidebar() }` 는 컴파일 타임에 `_ConditionalContent` 로 변환됨 → SwiftUI 는 false ↔ true 사이를 **"Sidebar 가 추가됨 / 제거됨"** 으로 인식 → transition + animation 이 결합되어 자연스러운 슬라이드 + 메인 영역 push 가 발생.

만약 `Sidebar().opacity(isSidebarVisible ? 1 : 0).frame(width: isSidebarVisible ? 240 : 0)` 같이 **계속 존재하면서 속성만 바꿨다면** transition 은 안 쓰고 animation 만 적용됐을 것 — 다른 코드 모양, 같은 시각 결과. 표현 방식 선택의 문제.

본 가이드는 **존재 / 부재 (if)** 패턴을 권장 — 코드가 의도를 더 잘 드러내고, 안 보일 땐 view-tree 에서 진짜로 빠져 measurement/redraw 비용이 없다.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다.

### `FloatingToolbar.swift` — 토글 액션을 애니메이션 컨텍스트로 감싸기

```swift
HoverButton {
    withAnimation(/* spring preset */) {
        isSidebarVisible.toggle()
    }
} label: { /* sidebar icon */ }
```

- spring preset 은 `.smooth` / `.snappy` / `.spring(duration: 0.3, bounce: 0.1)` 중에서 시도.
- 이 한 줄로 "이 상태 변경에 시간을 입혀라" 를 선언.

### `ContentView.swift` — Sidebar 에 transition 부여

```swift
if isSidebarVisible {
    Sidebar()
        .transition(.move(edge: .leading))
}
```

- transition 은 변하는 *그* 뷰에 직접 붙인다 (Sidebar 자체).
- HStack 이나 부모에 붙이지 않음 — 부모는 늘 존재하고, 사라지는 건 사이드바.

### 시각 검증

- 사이드바 버튼 클릭 → 사이드바가 좌측 바깥에서 슬라이드되며 들어오고, 동시에 메인 영역 + 플로팅 툴바가 같은 곡선으로 우측으로 밀림.
- 한 번 더 클릭 → 사이드바가 좌측으로 슬라이드되어 사라지고, 메인 영역이 같은 곡선으로 다시 좌측 끝으로.
- 한 번 더 빠르게 두 번 클릭해도 도중 상태에서 자연스럽게 반전 — spring 의 미덕.
- 트래픽라이트는 애니메이션과 무관하게 좌상단 고정.

### 힌트

- 처음 시도가 "사이드바가 슬라이드는 되는데 메인 영역은 텔레포트하듯 점프" 한다면: transition 은 사이드바에만 적용됐는데 부모 HStack 의 layout 변화가 animation 컨텍스트 안에 안 잡혔을 가능성. `withAnimation { ... }` 로 toggle 을 감쌌는지 다시 확인. (`.animation(_:value:)` 를 HStack 에 붙이는 형태로도 해결 가능.)
- 반대로 메인 영역은 부드럽게 미는데 사이드바는 fade 처럼 보인다면: `.transition(.move(edge: .leading))` 이 적용 안 됐을 가능성. transition 자리/철자 확인.
- spring preset 이 어색하면 듀레이션 한 단계만 바꿔보기 — `.spring(duration: 0.25, bounce: 0)` 같은 느낌. 0.5 이상은 사이드바 토글엔 너무 늘어진다.
- 두 번 빠르게 클릭하면 도중에 멈췄다가 반대로 부드럽게 가는지 확인 — 안 그러면 잠깐 jitter 가 보일 수 있다. spring 은 보통 잘 처리해 줌.

### 더 갈 수 있는 지점 (선택)

- `withAnimation` 대신 `.animation(.smooth, value: isSidebarVisible)` 을 HStack 에 붙이는 버전도 만들어 비교 — 동작은 동일, 코드 위치 차이.
- `.transition(.move(edge: .leading).combined(with: .opacity))` — 슬라이드 + 페이드 동시. 살짝 더 부드럽지만 취향.
- `.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading))` — 의도를 명시적으로 적되 동작은 같음. 등장/퇴장이 달라질 때 진가.

## 직접 구현하기
- [x] FloatingToolbar 의 사이드바 버튼 액션을 `withAnimation(...) { isSidebarVisible.toggle() }` 로 감싸기
- [x] ContentView 의 `if isSidebarVisible { Sidebar() }` 안의 Sidebar 에 `.transition(.move(edge: .leading))` 부여
- [x] spring preset 을 `.smooth` / `.snappy` / `.spring(duration: 0.3, bounce: 0.1)` 중 하나로 선택
- [x] ⌘B 빌드 통과 / ⌘R 실행
- [x] 사이드바 슬라이드 인/아웃이 부드럽게 동작
- [x] 메인 영역 + 플로팅 툴바가 같은 곡선으로 함께 밀림
- [x] 빠른 연속 클릭 시 도중 반전이 자연스러움
- [x] 라이트/다크 모드 양쪽 시각 확인
- [x] 트래픽라이트는 애니메이션과 무관하게 고정
- [ ] (선택) `.animation(_:value:)` 버전도 만들어 비교 후 본인 취향으로 합치기

> 다 끝나면 "다 했어" 라고 알려줘.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: `transition` 과 `animation` 의 차이? (정답: animation 은 "값/속성이 바뀔 때" 의 곡선이고, transition 은 "뷰가 추가/제거될 때" 의 등장/퇴장 효과. 둘은 짝이며 — transition 은 어떤 모양인지만 정하고, 실제 시간 보간은 animation 컨텍스트가 필요.)
- 자문자답: `withAnimation` 과 `.animation(_:value:)` 중 어느 걸 골랐고 왜? (정답 다양: withAnimation 은 액션 의도가 분명한 한 곳에 묶기 좋고, animation modifier 는 view 일관성을 view 쪽에 두기 좋음.)
- 자문자답: 만약 `.transition` 만 붙이고 `withAnimation` 을 안 감쌌다면 어떻게 동작하는가? (정답: 시간 보간 없이 즉시 toggle. transition 은 등장/퇴장의 모양 카탈로그일 뿐, 보간을 트리거하려면 애니메이션 컨텍스트가 필요.)
- 자문자답: spring preset 중 사이드바엔 왜 `.bouncy` 가 안 어울리는가? (정답: `.bouncy` 는 통통 튀는 곡선이라 캘린더 같은 도구 앱 톤과 안 맞음. 시맨틱 이름이 의도를 직접 표현하므로 이름만 보고도 어색함을 짐작할 수 있음.)
- 자문자답: 사이드바를 if 가 아니라 `frame(width: isVisible ? 240 : 0)` 로 만들었으면 어떻게 됐을까? (정답: transition 없이도 동작은 가능했지만 빈 폭 0 의 사이드바가 view-tree 에 늘 존재. measurement 비용도 있고, 의도가 코드에 덜 드러남. if 패턴이 SwiftUI 답고 깔끔.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] 사이드바 toggle 이 `withAnimation` 또는 `.animation(_:value:)` 컨텍스트 안에서 일어남
- [x] Sidebar 에 `.transition(.move(edge: .leading))` (또는 동등한 transition) 이 직접 부여됨
- [x] spring preset 이 macOS 14+ 시맨틱 이름 사용 (`.smooth` / `.snappy` / `.spring(duration:bounce:)`) — 매직 넘버 (`response:dampingFraction:`) 는 가급적 피함
- [x] Sidebar 가 슬라이드인/아웃 되며 메인 영역도 같은 곡선으로 push
- [x] 빠른 연속 토글 시 jitter 없이 자연스러운 반전
- [x] 트래픽라이트가 애니메이션 영향 안 받음
- [x] FloatingToolbar 의 leading padding 이 사이드바 push 와 시각적으로 부조리하지 않음 (단계 2 메모 후속)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **Animation curve 를 직접 만들기**: `.spring(duration: 0.3, bounce: 0.15)` 의 두 인자만 만져도 의외로 톤이 크게 바뀐다. duration 0.25/0.3/0.4, bounce 0/0.1/0.2 의 매트릭스로 시도해 본인 취향 찾기. macOS 표준은 0.3 전후 / bounce 0~0.15.
- **Transition 합치기**: `.move(edge: .leading).combined(with: .opacity)` 또는 `.asymmetric(...)` 으로 등장/퇴장에 다른 모양. 사용자가 사이드바를 닫을 때만 살짝 페이드를 더하는 식의 미세 조정 가능.
- **`AnyTransition` 확장**: 자주 쓰는 transition 조합을 `extension AnyTransition { static var sidebarSlide: AnyTransition { ... } }` 로 묶어 재사용. 호출 측이 `.transition(.sidebarSlide)` 한 줄로 짧아짐.
- **Reduced Motion 대응**: 시스템 설정에서 "동작 줄이기" 가 켜져 있으면 transition 을 fade 로 대체하는 게 매너. `@Environment(\.accessibilityReduceMotion)` 으로 감지해 transition 분기. 학습 부담 있으니 후속 단계에서.
- **Keyboard shortcut**: 사이드바 토글에 ⌘0 또는 ⌘⌥S 같은 단축키 부여 — `.keyboardShortcut("0", modifiers: .command)` modifier. macOS 표준 UX.
- **`.transaction { }`**: 더 세밀한 제어 — 이 변경만 다른 곡선/속도, 또는 애니메이션 자체를 끄는 등. 지금은 안 써도 됨.
