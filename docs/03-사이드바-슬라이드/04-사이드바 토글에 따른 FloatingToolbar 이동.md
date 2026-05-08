# 단계 4: 사이드바 토글에 따른 FloatingToolbar 이동

## 학습 목표
- FloatingToolbar 가 ZStack 안에 살아 있을 때, 부모 ZStack 의 frame 변화가 어떻게 자식 위치를 자동으로 옮기는지 이해한다.
- 컨텍스트에 따라 달라지는 layout 값 (이번엔 leading padding) 을 SwiftUI 답게 분기하는 법.
- **animatable value** 의 본질 — `CGFloat` 같은 layout 인자는 `withAnimation` 컨텍스트 안에서 바뀌면 SwiftUI 가 자동 보간한다는 점.
- 결과적으로 사이드바 슬라이드 + 메인 영역 push + FloatingToolbar leading padding 변화가 **하나의 곡선 안에서** 함께 움직이는 macOS 표준 UX 를 만든다.

## 사전 지식
- 단계 3 완료. `withAnimation(.smooth) { isSidebarVisible.toggle() }` + Sidebar 의 `.transition(.move(edge: .leading))` 가 살아 있고, 사이드바가 부드럽게 슬라이드 인/아웃 됨.
- `ContentView.swift` 의 현재 구조:
  ```swift
  HStack(spacing: 0) {
      if isSidebarVisible { Sidebar().transition(.move(edge: .leading)) }
      ZStack(alignment: .topLeading) {
          Color.clear
          FloatingToolbar(isSidebarVisible: $isSidebarVisible)
      }
  }
  ```
  → FloatingToolbar 가 **HStack 의 우측 ZStack 안에** 들어가 있다는 것이 본 단계의 출발점. (단계 3 까지는 ContentView 의 overlay 였음.)

## Swift / SwiftUI 개념

### 1) ZStack alignment 와 부모 frame 변화의 협동

ZStack 의 `alignment:` 인자는 **그 ZStack 내부의 모든 자식이 어떻게 정렬되는지** 의 기본값이다. 자식의 frame 이 ZStack 의 frame 보다 작을 때 적용된다. `.topLeading` 이면 자식이 ZStack 의 top-leading 코너에 붙는다.

여기서 핵심은 **ZStack 의 frame 자체가 부모 (HStack) 안에서 움직인다** 는 점이다.

- 사이드바 닫힘: HStack 의 자식은 ZStack 하나뿐 → ZStack 이 윈도우 전체 폭. ZStack 의 top-leading = 윈도우 (0, 0).
- 사이드바 열림: HStack 의 자식이 Sidebar(240pt) + ZStack 두 개 → ZStack 이 우측 (windowWidth-240) 으로 줄어듦. ZStack 의 top-leading = (240, 0).

→ 사이드바가 열리면 ZStack 의 top-leading 좌표가 0 에서 240 으로 이동 → ZStack 의 자식인 FloatingToolbar 도 **자동으로 240 우측으로 따라간다.** 본인이 뭘 안 해도 부모 frame 이 알아서 옮겨준다.

이게 단계 2 의 push 레이아웃이 본격적으로 빛나는 지점이다.

> Vue 비유로 치면: 부모 컨테이너의 `flex` 변화로 자식이 자동으로 재배치되는 것과 같음. 자식이 부모 좌표계에 묶여 있다는 발상.

### 2) 그런데 leading padding 80 이 어색해진다

`FloatingToolbar.swift` 에는 `.padding(.leading, 80)` 이 있다. 이건 단계 2 시점에 **FloatingToolbar 가 윈도우 top-leading 에 박혀 있을 때 트래픽라이트와 겹치지 않게 하려고** 넣은 값이다.

하지만 지금:

| 상태 | FloatingToolbar 위치 | 트래픽라이트 | leading padding 80 의 의미 |
|---|---|---|---|
| 사이드바 닫힘 | 윈도우 (0,0) 기준 | 좌상단 윈도우 | **여전히 필요** — 80px 띄워야 안 겹침 |
| 사이드바 열림 | (240, 0) 기준 | 사이드바 위에 있음 | **불필요** — 어차피 사이드바와 멀리 떨어짐 |

그래서 사이드바가 열리면 FloatingToolbar 가 메인 영역 (사이드바 우측) 의 코너에서 80 + 240 = 320pt 안쪽에 뚝 떨어져 있게 된다. "메인 영역 좌상단 구석" 이라는 의도와 맞지 않는다.

→ **leading padding 은 `isSidebarVisible` 에 따라 달라져야 한다.**

### 3) Padding 도 animatable 이다

핵심 통찰: `.padding(.leading, value)` 의 `value` 는 `CGFloat` — **animatable**.

SwiftUI 에서 animatable 이라는 건, 그 값이 변할 때 두 상태 사이를 보간할 수 있다는 뜻이다. `withAnimation { isSidebarVisible.toggle() }` 안에서 toggle 이 일어나면, 그 토글의 결과로 변하는 모든 animatable 값들이 **같은 곡선** 으로 보간된다.

```swift
.padding(.leading, isSidebarVisible ? 10 : 80)
```

이 한 줄이면 — 단계 3 의 `withAnimation` 컨텍스트 안에서 토글되는 순간:

1. 사이드바 view 가 추가/제거됨 → `.transition(.move(edge: .leading))` 으로 보간 (단계 3 에서 함)
2. HStack 의 layout 이 재계산됨 → ZStack frame 이 width/x 보간 (자동)
3. FloatingToolbar 의 leading padding 이 80 → 10 보간 (← 이번 단계가 추가)

→ 모두 **같은 spring 곡선** 위에서 한 번에 흐른다. 별도의 추가 애니메이션 코드 없이.

> 별도의 `.animation(.smooth, value: isSidebarVisible)` 같은 걸 padding 한 줄을 위해 또 붙일 필요가 없다 — 이미 호출 측 (`withAnimation`) 이 컨텍스트를 만들었으므로.

### 4) 표현 — ternary vs computed property

(a) Ternary (이번 단계 권장)

```swift
.padding(.leading, isSidebarVisible ? 10 : 80)
```

한 줄에 의도가 끝. padding 값이 `isSidebarVisible` 에 묶여 있다는 사실이 호출 위치에서 바로 보임.

(b) Computed property

```swift
private var leadingInset: CGFloat {
    isSidebarVisible ? 10 : 80
}
// ...
.padding(.leading, leadingInset)
```

이름으로 의미를 한 번 더 드러냄. 분기 로직이 길어지면 (b) 가 깔끔. 지금은 한 줄이니 (a).

> Java 비유: 매번 ternary 보다 final 변수로 한 번 잡아두는 게 가독성 있는 것과 같음. SwiftUI computed property 는 view 가 다시 그려질 때마다 다시 호출되므로 같은 효과.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다.

### `FloatingToolbar.swift`

지금 이 부분만 손대면 된다:

```swift
.padding(.top, 10)
.padding(.leading, /* isSidebarVisible 에 따라 분기 */)
```

- 닫힘 값: 80 (현재 값 유지)
- 열림 값: 본인이 시각적으로 결정. 10~16 사이를 시도해보기 — 캡슐 좌측 모서리와 사이드바 우측 가장자리 사이의 여백 느낌으로.
- `isSidebarVisible` 은 이미 `@Binding` 으로 들어와 있으니 즉시 사용 가능.

### `ContentView.swift`

손댈 필요 없음. 단계 3 의 `withAnimation(.smooth) { ... }` 가 이미 컨텍스트를 만들고 있고, ZStack alignment 가 자식 위치를 옮긴다.

### 시각 검증

- 닫힘: 트래픽라이트 우측 80px (이전과 동일).
- 열림: 사이드바 우측 가장자리 + 본인이 정한 padding pt 위치. 메인 영역의 top-leading 코너 느낌이어야 함.
- 토글 시 사이드바 슬라이드 + 메인 영역 push + FloatingToolbar leading padding 변화 — 셋이 같은 곡선 위에서 한 번에 움직여야 함.

### 힌트

- 만약 FloatingToolbar 의 padding 만 점프 (jump) 하고 다른 건 부드럽게 움직인다면: `withAnimation` 컨텍스트 밖에서 `isSidebarVisible` 이 바뀐 게 있는지 확인. 단계 3 의 토글이 정확히 `withAnimation { ... }` 안에 있어야 한다.
- 반대로 padding 변화가 시각적으로 안 느껴진다면 (사이드바만 슬라이드되고 FloatingToolbar 는 그냥 ZStack 따라 옮겨가는 것 같음): 분기 값을 더 크게 벌려보기 — 80 ↔ 10 정도로 차이를 두면 보임. 80 ↔ 70 같은 미세 차이는 눈에 안 띈다.
- 닫힘 → 열림 보간이 어색하면 단계 3 의 spring preset 을 `.snappy` 로 바꿔도 OK. preset 변경은 두 곳 다 영향 (이미 같은 컨텍스트라).

### 더 갈 수 있는 지점 (선택)

- Computed property 형태로 리팩터.
- 사이드바 폭 (240) 을 `Sidebar.swift` 에서 노출해 ContentView/FloatingToolbar 가 공유하는 상수로 빼기.
- `.offset(x: ...)` 로 같은 시각 효과를 흉내내보고 padding 분기와 비교 — offset 은 layout 시스템 밖이라 다른 자식의 reflow 를 trigger 안 함, padding 은 layout 시스템 안. 의미가 다르다는 걸 손으로 확인.

## 직접 구현하기
- [ ] `FloatingToolbar.swift` 의 `.padding(.leading, 80)` 을 `isSidebarVisible` 에 따라 분기
- [ ] 열림 padding 값 결정 (시도 → 시각 확인 → 본인 취향)
- [ ] ⌘B 빌드 통과 / ⌘R 실행
- [ ] 사이드바 닫힘: 트래픽라이트 우측 80pt 위치 유지
- [ ] 사이드바 열림: 메인 영역 좌상단 코너 느낌
- [ ] 토글 시 사이드바 + 메인 push + 플로팅 툴바 padding 변화가 **같은 곡선** 으로 동시 보간
- [ ] 빠른 연속 토글 시 jitter 없음
- [ ] 라이트/다크 모드 양쪽 시각 확인

> 다 끝나면 "다 했어" 라고 알려줘.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: padding 변화가 왜 자동으로 보간되었는가? (정답: padding 의 인자 `CGFloat` 가 animatable 이고, toggle 이 단계 3 에서 만든 `withAnimation` 컨텍스트 안에서 발생하므로 SwiftUI 가 두 상태 사이를 자동으로 spring 곡선으로 보간. 별도 애니메이션 modifier 불필요.)
- 자문자답: 만약 FloatingToolbar 를 ContentView 의 overlay 로 다시 빼면 어떻게 동작하나? (정답: overlay 는 부모 HStack 의 top-leading → 윈도우 top-leading 고정. 사이드바가 열려도 ZStack frame 변화의 영향을 안 받아 메인 영역 코너로 이동 안 함. 그래서 ZStack 안으로 옮긴 것이 본 단계의 전제.)
- 자문자답: ZStack alignment 를 `.center` 로 바꾸면 어떻게 되나? (정답: FloatingToolbar 가 ZStack 의 정중앙에 정렬됨. top-leading 의도를 잃음 — alignment 인자가 자식 정렬의 기준임을 다시 확인.)
- 자문자답: padding 분기 없이 그대로 두면 어떤 시각적 결과? (정답: 사이드바 열림 시 FloatingToolbar 가 240+80=320pt 위치 — 메인 영역 안쪽에 깊숙이 떨어져 있음. "코너" 느낌이 안 남.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `FloatingToolbar.swift` 의 leading padding 이 `isSidebarVisible` 에 따라 분기
- [ ] 분기 값이 합리적인 범위 (열림: 10~16 / 닫힘: 80)
- [ ] 분기 표현이 ternary 또는 computed property — 어느 쪽이든 의도가 명확
- [ ] 단계 3 의 `withAnimation` 컨텍스트와 짝지어 padding 도 같은 곡선으로 보간됨 (별도 애니메이션 추가 없이)
- [ ] FloatingToolbar 가 사이드바 두 상태에서 적절한 위치
- [ ] 트래픽라이트가 두 상태 모두에서 시각적으로 어색하지 않음

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **사이드바 폭 상수화**: `Sidebar.swift` 의 240 을 `static let width: CGFloat = 240` 로 노출. ContentView/FloatingToolbar 가 동일 상수를 참조해 매직 넘버 줄이기.
- **Computed property 리팩터**: ternary 가 두 군데 이상으로 늘어나면 `private var leadingInset: CGFloat { ... }` 로 묶기.
- **닫힘 padding 도 동적으로**: 트래픽라이트 hover 영역 폭 (`TrafficLightHoverArea` 가 80 인지) 을 상수로 뽑아 padding 닫힘 값과 동기화 — 트래픽라이트 영역이 바뀌면 자동 추적.
- **`.offset(x:)` 로 흉내내기**: padding 대신 `.offset(x: isSidebarVisible ? -70 : 0)` 같은 식으로 같은 시각 효과를 시도. layout 시스템 밖이라 다른 자식과의 reflow 가 일어나지 않음 — 결과는 비슷하지만 의미가 다름. padding 이 본 케이스에 더 맞는 이유를 손으로 체감.
- **Reduced Motion 대응**: `@Environment(\.accessibilityReduceMotion)` 으로 감지해 spring 대신 즉시 toggle. 후속 기능에서 정리해도 OK.
