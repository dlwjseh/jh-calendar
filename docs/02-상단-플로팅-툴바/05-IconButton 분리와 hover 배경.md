# 단계 5: IconButton 뷰로 분리 + hover 배경

## 학습 목표
- 반복되는 Button 패턴을 작은 **재사용 뷰** (`IconButton`) 로 뽑아낸다.
- `@State` 로 뷰 인스턴스의 UI 상태(hover 여부) 를 관리한다.
- default 파라미터 + `Color.primary.opacity(...)` 조합으로, **호출 측은 짧고 / 다양한 케이스(어두워지기·밝아지기) 는 자동 대응** 되는 구조를 만든다.
- 그 안에 단계 4 의 `pointerCursor()` 를 끼워, 손모양 커서 + hover 배경이 한 컴포넌트에서 같이 따라오게 한다.

## 사전 지식
- 단계 4 완료: `pointerCursor()` modifier 가 동작하고, 두 Button 위에서 손모양 커서가 뜬다.
- 단계 3 까지의 floating 카드(Material 배경 + Capsule + 그림자) 가 그대로 있다.
- AppKit 호출은 단계 4 의 `pointerCursor()` 안에 캡슐화돼 있어, 이 단계에서는 SwiftUI 만 쓰면 된다.

## Swift / SwiftUI 개념

### 1) 작은 View 로 분리 = SwiftUI 의 컴포넌트화

지금 `FloatingToolbar.swift` 의 두 Button 은 **시그니처가 사실상 똑같다** — 아이콘 이름과 클릭 액션만 다르고 나머지(`font`, `frame`, `.buttonStyle(.plain)`, `.pointerCursor()`) 는 전부 동일. 여기에 hover 배경까지 더하면 더 길어진다.

Vue 비유:

```vue
<!-- Vue -->
<IconButton icon="plus" @click="addEvent" />
<IconButton icon="rectangle.leadinghalf.inset.filled" @click="toggleSidebar" />
```

SwiftUI 도 똑같이 가능. 차이는:
- Vue 의 컴포넌트는 `.vue` 파일 / object 인 반면, SwiftUI 의 컴포넌트는 그냥 `View` 프로토콜을 따르는 **`struct`**.
- props 같은 게 별도 선언이 아니라 **struct 의 멤버 변수**. 컴파일러가 멤버를 모아 `init` 을 자동 생성해줌 (memberwise initializer).

```swift
struct IconButton: View {
    let systemName: String
    let action: () -> Void
    // 컴파일러가 자동 생성: init(systemName: String, action: @escaping () -> Void)

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
        }
    }
}
```

호출 측:

```swift
IconButton(systemName: "plus") {
    print("plus 클릭")
}
```

### 2) `@State` — 뷰가 자체적으로 갖는 UI 상태

hover 중인지 아닌지는 "지금 이 한 버튼" 의 상태다. 부모(FloatingToolbar) 가 알 필요도 없고, 두 IconButton 인스턴스가 **각자 따로** 가져야 한다 (하나만 어두워져야지 둘 다 같이 어두워지면 안 됨).

```swift
struct IconButton: View {
    @State private var isHovered = false
    // ...
}
```

비유:
- Vue 의 `ref(false)` 또는 `data() { return { isHovered: false } }` 와 같은 발상.
- `@State` 가 붙은 변수는 값이 바뀌면 SwiftUI 가 **자동으로 body 를 다시 호출** 해 화면을 갱신한다.

자연스럽게 떠오르는 의문:

> View 는 `struct` (값 타입) 인데, 어떻게 자기 멤버를 mutating 할 수 있지? Java 의 immutable 객체가 자기 필드 값을 바꾸는 셈 아닌가?

→ 실제로 `@State` 는 변수 값을 struct 안에 저장하지 않는다. `@State` 는 **property wrapper** 라는 Swift 기능으로, 외부 저장소(SwiftUI 가 관리하는 별도 메모리)를 가리키는 얇은 wrapper 일 뿐. 그래서 struct 가 매번 새로 만들어져도 상태는 유지된다. 지금은 "그렇게 동작한다" 정도만 알아도 충분.

### 3) default 파라미터 — Java 오버로딩의 한 줄짜리 대체

Java 에선 인자 일부에 기본값을 주려면 메서드 오버로딩으로 흉내내야 했다. Swift 는 한 줄.

```swift
struct IconButton: View {
    let systemName: String
    var hoverFill: Color = .primary.opacity(0.08)   // ← default
    let action: () -> Void
}
```

이렇게 하면:
- 99% 의 호출은 그냥 `IconButton(systemName: "plus") { ... }` — hover 색은 자동.
- 특별한 케이스만 명시: `IconButton(systemName: "trash", hoverFill: .red.opacity(0.15)) { ... }`.

> 주의: stored property 에 default 를 주면 컴파일러가 만들어주는 자동 init 은 해당 인자를 default 가 있는 인자로 인식한다. 단, 인자 순서상 default 인자가 non-default 인자 사이에 끼면 호출 측이 헷갈리므로, 일반적으로 **(필수 인자들) → (default 인자들) → (트레일링 클로저용 마지막 인자)** 순서로 둔다.

### 4) `Color.primary.opacity(...)` — "어두워지기 / 밝아지기" 를 자동으로

처음에 사용자가 짚은 핵심 케이스:

> 버튼이 투명일 땐 어두워져야 하고, 어두운 색이면 밝아져야 한다.

`Color.primary` 는 **시스템의 "전경" 색** 이다. 라이트 모드에선 검정, 다크 모드에선 흰색. 거기에 `.opacity(0.08)` 같은 약한 투명도를 곱해 배경에 깔면:
- 라이트 모드: 거의 투명한 검정 → 살짝 **어두워** 보임
- 다크 모드: 거의 투명한 흰색 → 살짝 **밝아** 보임

즉 "버튼이 위에 올라간 배경" 의 명도와 자동으로 반대 방향으로 움직인다 — 한 줄로 두 케이스 모두 해결.

> Material 배경(단계 3 에서 깐 `.regularMaterial`) 위에 `Color.primary.opacity(0.08)` 을 깔면, vibrancy 가 살짝 더 진해진 느낌으로 깔끔하게 떨어진다. 만약 명시적으로 다른 톤이 필요해진다면 그때 시스템 색(`Color(.controlAccentColor)` 등)이나 직접 색을 지정.

### 5) 조건부 modifier 값

modifier 자체를 조건부로 끼우는 게 아니라 (그건 더 어려운 패턴), **modifier 의 인자만 조건부로** 결정한다.

```swift
.background(isHovered ? hoverFill : Color.clear)
```

triple-equal 같은 거 없고 그냥 Java 의 삼항 연산자와 똑같다. SwiftUI 는 `isHovered` 가 바뀌면 body 를 다시 호출하니, background 색이 자연스럽게 갱신된다.

배경을 깔 위치는 **Image 의 `.frame(width:height:)` 직후** — 고정된 hit area 안에 색이 깔려야 둥근 사각형이 일정하게 보임. `.background(...)` + `.clipShape(.rect(cornerRadius: ...))` (또는 `RoundedRectangle`) 로 모서리를 살짝 둥글게.

### 6) 클로저 파라미터와 `@escaping` (살짝만)

`action: () -> Void` 는 함수 타입의 멤버다. Button 이 **나중에** (탭됐을 때) 호출하므로 init 에서 받아서 저장 → init 함수 밖으로 escape. 멤버 변수로 받을 때는 컴파일러가 알아서 escaping 으로 인식하니 **명시 안 해도 된다**. 단, 별도의 `init(...)` 을 직접 쓰면 `@escaping` 을 명시해야 함. 지금은 자동 init 만 쓰니 신경 안 써도 OK.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다. 사용자가 직접 작성.

### 새 파일

`JHCalendar/Features/FloatingToolbar/IconButton.swift`

골격:

```swift
import SwiftUI

struct IconButton: View {
    let systemName: String
    var hoverFill: Color = .primary.opacity(0.08)
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 25, height: 25)
                // TODO: 여기 뒤에 background + clipShape
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            // TODO: isHovered 갱신
        }
        .pointerCursor()
    }
}
```

채워야 할 곳:
- `.frame(width: 25, height: 25)` 다음에 `.background(...)` 와 `.clipShape(...)` — hover 일 때만 색이 깔리도록.
  - `clipShape` 는 `.rect(cornerRadius: 6)` 정도. 캡슐 카드 안의 작은 둥근 사각형 느낌.
- `.onHover { hovering in ... }` 안에서 `isHovered` 를 갱신.

### 수정할 파일

`JHCalendar/Features/FloatingToolbar/FloatingToolbar.swift`
- 두 `Button { ... } label: { ... } .buttonStyle(.plain) .pointerCursor()` 블록을 각각 `IconButton(systemName: "...") { ... }` 한 줄로 대체.
- `IconButton` 안에서 이미 `pointerCursor()` 와 hover 배경을 다 처리하므로, FloatingToolbar 의 HStack 자체는 훨씬 짧아진다.

### project.pbxproj 등록

새 파일이라 4군데 등록 필요 (PBXFileReference + PBXBuildFile + `FloatingToolbar` 그룹 children + PBXSourcesBuildPhase). 단계 4 의 `PointerCursor.swift` 등록할 때와 똑같은 패턴이라 그때 패치 diff 를 참고하면 빠르다.

### 힌트

- hover 색이 너무 진하면 답답하다. `0.08` ~ `0.12` 정도가 시스템 톤과 잘 맞는다. `0.05` 부터 시작해 조금씩 올려보면서 감을 익히면 좋다.
- `clipShape` 의 `cornerRadius` 와 카드 전체의 캡슐 모양이 충돌하지 않는지 확인 — 버튼 hit area 28×28 안에서만 둥근 사각형이 나오면 OK.
- `Color.clear` 대신 `nil` 을 쓰는 패턴(`.background(isHovered ? hoverFill : nil)`) 도 있지만, 타입 추론이 까다로워질 수 있으니 처음엔 `Color.clear` 가 안전.
- 두 IconButton 인스턴스는 각자 `@State` 를 갖는다 — 별도 코드 없이도 독립적으로 hover 가 동작하는지 꼭 확인 (이게 단계의 핵심 학습 체험 중 하나).

## 직접 구현하기
- [ ] `Features/FloatingToolbar/IconButton.swift` 생성
- [ ] 멤버 변수 정의 (`systemName`, `hoverFill` (default), `action`) + `@State private var isHovered`
- [ ] body 에 Button + Image label + frame + 조건부 background + clipShape
- [ ] `.onHover` 에서 `isHovered` 갱신
- [ ] `.buttonStyle(.plain)` + `.pointerCursor()` 적용
- [ ] `project.pbxproj` 4군데 등록
- [ ] `FloatingToolbar.swift` 의 두 Button 블록을 `IconButton(...) { ... }` 로 교체
- [ ] ⌘B 빌드 통과 / ⌘R 실행
- [ ] hover 시 배경이 살짝 어두워지고, 빠지면 원상복귀
- [ ] 두 버튼이 **각자** hover 동작 (한쪽만 어두워짐)
- [ ] 다크 모드로 바꿔도 자연스러운지 (System Settings → Appearance)
- [ ] 손모양 커서도 그대로 작동하는지 (단계 4 회귀 없는지)

> 다 끝나면 "다 했어" 라고 알려줘. 리뷰할게.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 호버 톤(0.08 부근) 이 너무 강하지도 약하지도 않은가? 다른 값 (0.05 / 0.15) 도 잠깐 시도해 비교해본 적 있는가?
- 자문자답: 왜 `@State` 를 IconButton **안** 에 두지, FloatingToolbar 에 두 개를 두지 않는가? (정답: 상태가 그 뷰 본인에게만 의미가 있고, 인스턴스마다 독립적이어야 하기 때문. 부모로 끌어올릴 이유가 없음 — 부모가 hover 여부를 알 필요가 없음. 일반 원칙: state 는 그것을 쓰는 가장 가까운 뷰에 둔다.)
- 자문자답: 만약 hover 시 글씨색까지 바꾸고 싶으면 어디를 어떻게 늘릴 것인가? (정답: `hoverForeground: Color = .primary` 같은 default 파라미터를 추가하고, `Image` 에 `.foregroundStyle(isHovered ? hoverForeground : .primary)` 를 적용. 호출 측은 default 라 영향 없음.)
- 자문자답: `Color.primary.opacity(0.08)` 이 라이트/다크 두 모드 모두에서 자연스러운 이유? (정답: `Color.primary` 가 시스템 전경 색이라 모드에 따라 검정/흰색으로 자동 전환되고, 같은 opacity 로 살짝 깔리니 어두워지기/밝아지기 둘 다 한 줄로 처리됨)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `IconButton` 이 단일 책임만 갖는다 (아이콘 표시 + hover 인터랙션 묶음)
- [ ] `@State isHovered` 가 IconButton **내부**에 있고 부모로 새지 않는다
- [ ] `hoverFill` 에 default 값이 있어 호출 측이 한 줄에 머문다
- [ ] hover 색은 시스템 적응형 (`Color.primary.opacity(...)` 또는 그에 준하는 적응형 색) — 하드코딩된 `.gray` 등이 아님
- [ ] cursor 처리는 단계 4 의 `pointerCursor()` 재사용 — IconButton 안에서 다시 `.onHover` + `NSCursor` 를 박지 않음
- [ ] `FloatingToolbar.swift` 가 짧아졌고, 거기서 직접 hover 상태를 갖지 않음
- [ ] 새 파일이 `project.pbxproj` 4군데에 등록되어 빌드 통과

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **ButtonStyle 도전**: `IconButton` 대신 `PlainHoverButtonStyle: ButtonStyle` 을 만들어 `.buttonStyle(...)` 한 줄로 적용. 단, `ButtonStyle.makeBody(configuration:)` 에서 받는 `Configuration` 은 `isPressed` 만 알려주고 hover 는 모른다 — 그래서 `configuration.label` 을 다시 wrapping 하는 작은 helper view 가 필요해진다. 어떤 방식이 더 깔끔한지 비교해보면 좋다.
- **hoverForeground 추가**: 글씨색까지 변하는 케이스를 default 파라미터로 추가. 자가 점검의 자문자답을 직접 코드로 옮겨보기.
- **press 피드백**: hover 보다 더 진한 톤(예: opacity 0.16) 을 누르는 동안 깔리도록. `Button` 에 `ButtonStyle` 없이 만들면 pressed 감지가 어려우니, 이때 ButtonStyle 도입 동기가 생긴다.
- **`.help("새 일정 추가")`**: 한 줄로 시스템 tooltip 추가. 손모양 커서 + 배경 변화 + tooltip 의 3 콤보가 macOS 표준 UX 에 가장 가까움.
- **접근성**: `.accessibilityLabel("새 일정 추가")` 로 VoiceOver 사용자에게 의미 전달. 아이콘 버튼은 라벨이 없으므로 명시적으로 알려주는 것이 좋음.
