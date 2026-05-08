# 단계 2: Sidebar 뷰 + 조건부 레이아웃 (push)

## 학습 목표
- 사이드바 자체를 작은 새 View (`Sidebar`) 로 분리한다 — 새 Feature 폴더 신설 패턴 반복.
- `ContentView` 의 ZStack-only 구조를 **HStack 기반 push 레이아웃 + overlay** 로 재구성한다.
- SwiftUI body 안의 `if` 가 평범한 Swift if 가 아니라 **`_ConditionalContent` 로 변환되는 view-tree DSL** 임을 이해한다.
- `.overlay(alignment:)` 와 `ZStack` 의 의미 차이를 분리해 사용한다.

## 사전 지식
- 단계 1 완료: `ContentView` 가 `@State var isSidebarVisible` 를 들고, `FloatingToolbar` 가 `@Binding` 으로 받아 toggle 한다. 콘솔로 동작 확인됨.
- 임시 print/Text 디버그 코드는 제거됨.
- `Features/<Name>/` 폴더 신설 + `project.pbxproj` 4군데 등록 패턴 (CLAUDE.md "새 기능을 추가할 때" 항목).
- `HStack`, `ZStack`, `.frame`, `.background`, `.overlay` 의 기본 사용법.

## Swift / SwiftUI 개념

### 1) Sidebar 도 작은 View — 책임 분리

`ContentView` 안에 `Color.gray.opacity(0.1).frame(width: 240)` 을 직접 박아도 동작은 한다. 하지만:
- 사이드바가 단순한 색 배경을 넘어서 **목록·헤더·아이콘** 등을 갖게 되면 ContentView body 가 곧 거대해진다.
- ContentView 의 책임은 **레이아웃 조립** — Sidebar/Toolbar/Calendar 의 위치 관계를 정하는 일. 사이드바 안의 콘텐츠는 Sidebar 의 책임.

이미 `FloatingToolbar`, `TrafficLightHoverArea` 처럼 분리해온 흐름을 그대로 이어가는 것.

> **이 단계에선 Sidebar 를 placeholder 로만 만든다** — 단색/Material 배경 + 고정 폭. 안의 콘텐츠는 후속 기능에서.

### 2) Push 레이아웃의 발상 — HStack + 조건부 자식

push 방식은 의외로 단순하다. **HStack 안에 사이드바를 조건부로 넣는다.** 들어오면 옆 콘텐츠가 자연스럽게 밀리고, 빠지면 다시 좁혀진다.

```swift
HStack(spacing: 0) {
    if isSidebarVisible {
        Sidebar()
    }
    MainContent()   // ← 사이드바 폭만큼 자동으로 밀림
}
```

이게 SwiftUI 가 **선언형 레이아웃** 이라 가능한 일. AppKit/UIKit 이라면 frame 좌표 + 애니메이션을 직접 손봐야 했을 것. SwiftUI 는 "사이드바가 있는지 없는지" 만 선언하고, 실제 위치/폭 변화는 프레임워크가 계산.

Vue 비유: `v-if` 로 컴포넌트가 들어왔다 나갔다 하면 형제들의 위치가 자동으로 조정되는 거랑 같은 발상.

### 3) SwiftUI body 안의 `if` 는 평범한 if 가 아니다

```swift
HStack {
    if isSidebarVisible {
        Sidebar()
    }
    MainContent()
}
```

이 코드는 **컴파일 단계에서** 다음과 비슷한 형태로 변환된다:

```swift
HStack {
    _ConditionalContent<Sidebar, EmptyView>(...)   // 둘 중 하나
    MainContent()
}
```

즉 if 가 진짜 분기 실행이 아니라 **두 갈래 view-tree 중 하나를 선택하는 DSL** 로 컴파일된다. 결과적으로:

- HStack 의 자식 개수는 컴파일 타임에 결정됨 (가변 자식 갯수가 아님).
- `if` ~ `else` 양쪽이 모두 View 를 반환해야 한다.
- `if` 만 쓰면 false 일 때 `EmptyView()` 가 들어가는 셈.
- `for` 루프 같은 일반 제어문은 body 에서 못 쓴다 (대신 `ForEach` 사용).

이건 단계 02-5 의 `@ViewBuilder` 와 같은 메커니즘 — **result builder DSL**. SwiftUI 의 `if`/`switch` 도 ViewBuilder 가 처리해주는 특별 문법.

> 처음엔 "어차피 같은 if 인데 뭐가 다르지?" 싶지만, 이게 SwiftUI 의 view diffing / 애니메이션 / transition 의 기반이다. 다음 단계 (애니메이션) 에서 이 사실이 결정적으로 쓰인다.

### 4) `.overlay(alignment:)` vs `ZStack` — 같은 듯 다른 용도

지금 `ContentView` 의 ZStack 은 두 종류의 자식이 섞여 있다:
- **메인 레이아웃** : `Color.clear + FloatingToolbar`.
- **윈도우 고정 오버레이** : `TrafficLightHoverArea` (사이드바와 무관하게 항상 좌상단).

push 로 바꾸면 메인 레이아웃이 HStack 으로 바뀌니, **트래픽라이트는 그 위에 따로 떠 있어야 한다.** 두 옵션:

```swift
// (A) ZStack 으로 바깥 한 겹 더 감싸기
ZStack(alignment: .topLeading) {
    HStack(spacing: 0) { ... }
    TrafficLightHoverArea()
}

// (B) overlay modifier 로 첨부
HStack(spacing: 0) { ... }
    .overlay(alignment: .topLeading) {
        TrafficLightHoverArea()
    }
```

둘 다 시각적으로 비슷한 결과지만 의미가 살짝 다르다:
- **ZStack**: "이 자식들끼리 서로 align." 자식들이 동등한 멤버.
- **overlay**: "어떤 뷰의 **부모 size 안에** 다른 뷰를 첨부." 본체와 첨부물의 비대칭 관계 — 첨부물은 본체의 frame 을 따라간다.

트래픽라이트는 "메인 영역 위에 얹힌 고정 액세서리" 이므로 **overlay 가 의도를 더 잘 표현**. 추천은 (B).

> 단, overlay 는 본체의 frame 안쪽에 그려진다. 본체가 minWidth/minHeight 으로 윈도우 전체를 덮어야 트래픽라이트가 윈도우 좌상단에 정확히 떨어진다. 지금 코드의 `.frame(minWidth: 900, minHeight: 600)` + `.ignoresSafeArea()` 흐름이 그 역할.

### 5) Sidebar 의 폭 — fixed vs flexible

이번 단계엔 단순히 `.frame(width: 240)` 으로 고정. 240 은 macOS 표준 사이드바와 비슷한 톤.

향후 옵션 (지금은 안 함):
- 사용자가 드래그로 폭 조정 → `NavigationSplitView` 나 직접 drag gesture.
- 가변 폭 (`.frame(maxWidth: 320, idealWidth: 240, minWidth: 200)`) 로 윈도우 크기에 따라 적응.

현재는 placeholder 라 고정이 가장 깔끔.

### 6) Sidebar 배경 — Color vs Material

두 가지 자연스러운 선택:
- `Color.gray.opacity(0.08)` — 가볍고 단순.
- `Rectangle().fill(.regularMaterial)` — 단계 02-3 의 vibrancy 와 톤이 맞아 floating toolbar 와 어울린다.

학습 부담을 줄이려면 첫 번째로 시작하고, 보기 마음에 안 들면 두 번째로 바꾸기. 둘 다 다크/라이트 자동 대응.

> macOS 표준 사이드바는 `Material.bar` 또는 `Material.sidebar` 같은 더 시맨틱한 변종을 쓰지만, SwiftUI 에서 이름이 약간씩 다르다. `.regularMaterial` 이면 충분.

## 구현 가이드

### 새 파일

`JHCalendar/Features/Sidebar/Sidebar.swift`

골격:

```swift
import SwiftUI

struct Sidebar: View {
    var body: some View {
        // TODO: placeholder 배경 (Color 또는 Material) + .frame(width: 240)
        // 처음엔 Color.gray.opacity(0.08) + frame 만으로 충분
    }
}
```

`project.pbxproj` 4군데 등록 (PBXFileReference, PBXBuildFile, `Features` 그룹의 children — 새 폴더라 PBXGroup `Sidebar` 도 신설, PBXSourcesBuildPhase). CLAUDE.md "새 기능을 추가할 때" 참조.

### 수정할 파일

**`JHCalendar/ContentView.swift`** — 핵심 재구성

지금 형태:
```swift
ZStack(alignment: .topLeading) {
    Color.clear.frame(minWidth: 900, minHeight: 600)
    TrafficLightHoverArea()
    FloatingToolbar(isSidebarVisible: $isSidebarVisible)
}
.ignoresSafeArea()
```

목표 형태 (의사 코드):
```swift
HStack(spacing: 0) {
    if isSidebarVisible {
        Sidebar()
    }
    ZStack(alignment: .topLeading) {
        Color.clear   // 메인 캘린더 영역 (placeholder)
        FloatingToolbar(isSidebarVisible: $isSidebarVisible)
    }
}
.frame(minWidth: 900, minHeight: 600)
.overlay(alignment: .topLeading) {
    TrafficLightHoverArea()
}
.ignoresSafeArea()
```

핵심 포인트:
- 바깥은 `HStack(spacing: 0)` — 사이드바와 메인 영역이 가로로 나란히.
- 사이드바는 `if` 로 조건부.
- 메인 영역은 `ZStack(alignment: .topLeading) { Color.clear + FloatingToolbar }` — FloatingToolbar 가 메인 영역의 좌상단에 자리잡도록.
- `Color.clear` 는 메인 영역이 사이드바 외 남은 공간을 모두 차지하도록 늘어나는 역할 (HStack 안에서 가변 폭).
- minWidth/minHeight 은 **HStack 전체** 에 줘서 윈도우 최소 크기 보장.
- `TrafficLightHoverArea` 는 `.overlay(alignment: .topLeading)` 으로 — 사이드바와 무관하게 항상 윈도우 좌상단.

### 힌트

- `Color.clear` 가 HStack 안에서 자기 폭이 0 이 되어버리면 메인 영역이 안 보일 수 있다. 이때 `.frame(maxWidth: .infinity, maxHeight: .infinity)` 를 명시하거나, `Color.clear` 자리를 차지하도록 다른 placeholder (예: `Rectangle().fill(.clear)`) 를 쓰는 등의 방법. 보통은 HStack 의 분배 룰에 맡겨도 잘 된다.
- 만약 메인 영역이 사이드바 펼치자마자 좁아지면서 `FloatingToolbar` 의 leading padding (단계 02-1 의 `.padding(.leading, 80)`) 때문에 우측으로 너무 멀어진다면, 그 padding 의 의미를 다시 생각해볼 시점 — 트래픽라이트 자리를 비우려는 padding 인데, 사이드바가 펼쳐지면 트래픽라이트는 사이드바와 별개니 padding 이 더 이상 필요 없을 수 있다. 본 단계에서 결정해도 좋고 (지금 leading padding 을 줄이거나 제거), 단계 3 끝나고 시각적으로 보고 결정해도 좋다.
- 사이드바 배경을 Material 로 갈 거면, `.frame(width: 240)` 만으로는 안 되고 `.frame(width: 240, maxHeight: .infinity)` 처럼 세로로 꽉 차게 명시하는 게 안전.
- 토글 동작이 즉시 (애니메이션 없이) 뚝뚝 끊겨야 정상 — 단계 3 에서 부드럽게 만들 것.

### 시각 검증

- 사이드바 버튼 클릭 → 좌측에 회색/Material 영역이 즉시 나타나고 메인 영역 + 플로팅 툴바가 우측으로 밀린다.
- 한 번 더 클릭 → 즉시 사라지고 메인 영역이 다시 좌측 끝으로.
- 트래픽라이트는 항상 좌상단 고정 — 사이드바가 펼쳐져도 위치 안 바뀜 (사이드바 위에 살짝 가려지는 게 정상).
- 라이트/다크 모드 양쪽에서 자연스러운지.

## 직접 구현하기
- [x] `Features/Sidebar/Sidebar.swift` 생성 (placeholder 배경 + 폭)
- [x] `project.pbxproj` 등록 — Xcode 16+ 의 `PBXFileSystemSynchronizedRootGroup` 방식으로 `Sidebar` 폴더 그룹 신설 (FloatingToolbar 와 동일 패턴)
- [x] `ContentView` 를 HStack-기반 + overlay 구조로 재구성
- [x] HStack 안에 `if isSidebarVisible { Sidebar() }` 조건부 자식
- [x] 메인 영역은 `Color.clear` 만 (FloatingToolbar 는 별도 overlay 로 분리 — 회고 참조)
- [x] `.frame(minWidth: 900, minHeight: 600)` 을 HStack 에 적용
- [x] `.overlay(alignment: .topLeading) { TrafficLightHoverArea() }` + `.overlay(alignment: .topLeading) { FloatingToolbar(...) }` chain
- [x] `.ignoresSafeArea()` 유지
- [x] ⌘B 빌드 통과 / ⌘R 실행
- [x] 사이드바 버튼 클릭 시 즉시 push 토글 동작
- [x] 트래픽라이트 위치가 사이드바와 무관하게 좌상단 고정
- [x] 라이트/다크 모드 시각 확인

> 다 끝나면 "다 했어" 라고 알려줘.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: HStack 안의 `if` 가 일반 if 와 다른 점? (정답: ViewBuilder 가 컴파일 타임에 `_ConditionalContent` 로 변환. 자식 개수가 가변이 아니라 양 갈래 중 하나가 선택되는 형태. 그래서 SwiftUI 가 "들어왔다/빠졌다" 를 추적해 transition 을 적용할 수 있게 됨.)
- 자문자답: `ZStack` 으로 트래픽라이트를 처리해도 동작은 같은데, `.overlay(alignment:)` 로 한 이유? (정답: 트래픽라이트는 본체와 동등한 멤버라기보다 본체 위에 첨부된 액세서리. overlay 가 의도를 더 잘 표현하고, frame 도 본체에 자동 종속.)
- 자문자답: 메인 영역에 `Color.clear` 를 쓴 이유? (정답: 보이지 않으면서 가용 공간을 차지해 ZStack 의 alignment 를 위한 ground 역할. 차후 진짜 캘린더 뷰가 들어오면 그게 자연스럽게 대체.)
- 자문자답: Sidebar 의 frame 을 `.frame(width: 240)` 으로만 줬는데 세로 높이는 어떻게? (정답: HStack 안에서 자식의 height 는 형제 중 가장 큰 것에 맞춰 늘어나거나, 부모의 가용 height 를 따른다. 메인 영역의 Color.clear 가 maxHeight 으로 늘어나면 사이드바도 같은 높이로 늘어남. 명시하고 싶으면 `.frame(maxHeight: .infinity)` 도 함께.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `Features/Sidebar/Sidebar.swift` 가 별도 파일로 분리됨
- [x] `project.pbxproj` 등록 — Xcode 16+ `PBXFileSystemSynchronizedRootGroup` 방식 (빌드 통과)
- [x] ContentView 가 HStack-기반 push 레이아웃으로 재구성됨
- [x] 사이드바가 `if isSidebarVisible { Sidebar() }` 로 조건부 표시됨
- [x] **사용자 디자인 결정**: FloatingToolbar 는 사이드바와 함께 밀리지 않고 윈도우 고정 (overlay 로 분리). 트래픽라이트와 동일 카테고리.
- [x] TrafficLightHoverArea 가 `.overlay(alignment: .topLeading)` 으로 분리되어 사이드바와 무관하게 고정
- [x] minWidth/minHeight 이 적절한 위치 (HStack) 에 옮겨짐
- [x] 토글이 즉시 (애니메이션 없이) 동작 — 다음 단계 여백을 둠
- [x] overlay 두 개 chain 으로 z-order 명시 (트래픽라이트 → FloatingToolbar 순)

## 회고
- **디자인 결정**: 가이드 의사 코드는 FloatingToolbar 를 메인 영역 안에 두어 사이드바와 함께 밀리는 형태였지만, 직접 써보니 툴바가 항상 같은 자리에 있는 편이 더 자연스러워서 트래픽라이트와 같은 overlay 액세서리 카테고리로 분리.
  - 결과 구조:
    ```swift
    HStack(spacing: 0) {
        if isSidebarVisible { Sidebar() }
        Color.clear
    }
    .frame(minWidth: 900, minHeight: 600)
    .overlay(alignment: .topLeading) { TrafficLightHoverArea() }
    .overlay(alignment: .topLeading) { FloatingToolbar(isSidebarVisible: $isSidebarVisible) }
    .ignoresSafeArea()
    ```
  - overlay 를 두 번 chain 한 이유: 두 액세서리가 서로 다른 책임이라는 점 + 그리는 순서(z-order) 가 chain 순으로 명시됨 — 뒤에 chain 한 게 위로 올라옴.
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(사용자가 추가로 채우는 영역)*

## 조금 더 (선택)
- **NavigationSplitView**: macOS 의 표준 사이드바 패턴은 사실 `NavigationSplitView` 다 (Apple 캘린더/메일이 쓰는 그것). toolbar 는 SwiftUI 의 표준 toolbar API 와 맞물려 동작. 다만 우리 앱은 floating 한 커스텀 툴바를 이미 만들어서, NavigationSplitView 를 같이 쓰면 두 toolbar 영역이 충돌한다. 학습 트레이드오프: NavigationSplitView 는 macOS 관용에 정확히 맞지만 black-box 가 많고, 커스텀 HStack 은 SwiftUI 의 일반 개념(state/binding/animation/transition) 학습이 더 잘 된다. 우리는 후자 선택.
- **`.frame(maxWidth:)` 과 layout priority**: HStack 안에서 누가 늘어나고 누가 고정되는지의 분배 룰. 사이드바 폭 고정 (`.frame(width: 240)`) + 메인 영역은 `.frame(maxWidth: .infinity)` 같은 식으로 명시할 수도 있다. SwiftUI 는 보통 똑똑하게 처리하지만 어색해 보이면 명시.
- **`.background(.regularMaterial)` 의 시맨틱 변종들**: `.bar`, `.thick`, `.thin`, `.ultraThin` — 각각 vibrancy 강도가 다르다. 사이드바가 floating toolbar 와 같은 톤이길 원하면 `.regularMaterial` 또는 `.thinMaterial` 이 좋고, 더 묵직한 칸막이 느낌이 좋으면 `.thickMaterial`.
- **사이드바 안의 `Divider()` / `VStack`**: 폴더 헤더 / 항목 목록 등 콘텐츠가 들어올 자리. 본 기능에서는 placeholder 라 비워두고, 다음 기능에서 채울 때 자연스러운 진입점.
