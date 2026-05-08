# 단계 5: HoverButton 뷰로 분리 + hover 배경 (범용 label)

## 학습 목표
- 반복되는 Button 패턴을 작은 **재사용 뷰** (`HoverButton`) 로 뽑아낸다.
- 진짜 재사용 가치가 있는 건 "아이콘" 이 아니라 **hover 배경 + 손모양 커서 + plain style 인터랙션 묶음** 임을 코드로 표현한다 — 그래서 label 은 아이콘이든 텍스트든 임의 View 를 받도록 일반화.
- **제네릭** + **`@ViewBuilder`** 로 자식 View 타입을 자유롭게 받는 패턴을 익힌다.
- `@State` 로 뷰 인스턴스의 UI 상태(hover 여부) 를 관리한다.
- default 파라미터 + `Color.primary.opacity(...)` 조합으로, **호출 측은 짧고 / 다양한 케이스(어두워지기·밝아지기) 는 자동 대응** 되는 구조를 만든다.
- 그 안에 단계 4 의 `.pointerStyle(.link)` 를 끼워, 손모양 커서 + hover 배경이 한 컴포넌트에서 같이 따라오게 한다.

## 사전 지식
- 단계 4 완료: 두 Button 에 `.pointerStyle(.link)` 가 붙어 손모양 커서가 뜬다.
- 단계 3 까지의 floating 카드(Material 배경 + Capsule + 그림자) 가 그대로 있다.
- 이 단계도 SwiftUI 만으로 가능 — AppKit 호출 없음.

## Swift / SwiftUI 개념

### 1) 작은 View 로 분리 = SwiftUI 의 컴포넌트화

지금 `FloatingToolbar.swift` 의 두 Button 은 **시그니처가 사실상 똑같다** — 아이콘 이름과 클릭 액션만 다르고 나머지(`font`, `frame`, `.buttonStyle(.plain)`, `.pointerStyle(.link)`) 는 전부 동일. 여기에 hover 배경까지 더하면 더 길어진다.

Vue 비유:

```vue
<!-- Vue -->
<HoverButton @click="addEvent">
  <Icon name="plus" />
</HoverButton>

<HoverButton @click="save">저장</HoverButton>
```

SwiftUI 도 똑같이 가능. 차이는:
- Vue 의 컴포넌트는 `.vue` 파일 / object 인 반면, SwiftUI 의 컴포넌트는 그냥 `View` 프로토콜을 따르는 **`struct`**.
- props 같은 게 별도 선언이 아니라 **struct 의 멤버 변수**. 컴파일러가 멤버를 모아 `init` 을 자동 생성해줌 (memberwise initializer).

### 2) 왜 "범용 label" 인가 — 추상화의 경계 정하기

처음 본능적으로 떠오르는 이름은 `IconButton` 이지만, 이 컴포넌트가 진짜 책임지는 건 **인터랙션 묶음** (`buttonStyle(.plain) + pointerStyle(.link) + hover 배경`) 이고, **콘텐츠가 무엇인가** 는 호출 측의 관심사다.

- 아이콘으로 박아두면: 글씨 버튼이 필요해질 때 또 비슷한 뷰를 만든다 → 인터랙션 묶음이 두 곳에 중복.
- label 을 임의 View 로 열어두면: 아이콘이든 글씨든 `Image + Text` 조합이든 다 한 컴포넌트가 떠받침.

이게 **"컴포넌트의 책임은 가능한 좁게, 그러나 콘텐츠는 가능한 넓게"** 라는 일반적 디자인 원칙의 SwiftUI 버전.

### 3) 제네릭 — Java generics 와 같은 발상

`HoverButton` 안에 들어갈 label 의 타입을 미리 못 박을 수 없다 (호출자마다 `Image`, `Text`, `HStack<...>` 등 제각각). Java 의 `class Box<T> { T value; }` 와 똑같이, Swift 도 타입 파라미터를 받는다:

```swift
struct HoverButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label
    // ...
}
```

- `<Label: View>` — "`View` 프로토콜을 따르는 어떤 타입이든 OK" (Java 의 `<T extends View>` 와 같은 발상).
- 호출 측이 어떤 View 를 넣느냐에 따라 컴파일러가 `Label` 자리에 들어갈 구체 타입을 추론.
- 런타임 비용 없음 — Swift 제네릭은 컴파일 타임에 specialize.

### 4) `@ViewBuilder` — Vue `<slot>` 에 대응되는 메커니즘

label 자리를 그냥 `let label: () -> Label` 로 두면 호출 측은 단일 표현식만 넣을 수 있다:

```swift
HoverButton(action: ...) { Image(systemName: "plus") }   // OK
HoverButton(action: ...) {                                // ❌ 컴파일 에러
    Image(systemName: "plus")
    Text("추가")
}
```

SwiftUI 가 `HStack { ... }` / `VStack { ... }` 안에 여러 자식을 그냥 나열할 수 있게 해주는 마법이 바로 `@ViewBuilder` 라는 어노테이션. label 클로저 앞에 `@ViewBuilder` 를 붙이면 같은 마법이 우리 컴포넌트에도 적용된다.

```swift
@ViewBuilder let label: () -> Label
```

비유:
- Vue 의 `<slot>` 또는 React 의 `children`. 부모 컴포넌트가 자식 콘텐츠 모양을 모르고 그냥 위치만 비워둔다.
- 차이: SwiftUI 는 result builder (DSL) 로 컴파일타임에 자식들을 묶어 단일 View 트리로 합친다.

### 5) `Button(action:label:)` 과 같은 시그니처 = trailing closure 두 개

Apple 의 Button 자체가 이미 같은 패턴을 쓴다:

```swift
Button(action: { ... }) {
    Image(systemName: "plus")
}
```

또는 두 trailing closure 문법 (Swift 5.3+):

```swift
Button {
    print("탭")
} label: {
    Image(systemName: "plus")
}
```

`HoverButton` 도 똑같은 시그니처로 만들면 호출 측에서 직관이 일관된다 — Button 쓰던 사람이 그대로 쓸 수 있음.

```swift
HoverButton {
    print("탭")
} label: {
    Image(systemName: "plus")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)
}
```

> 두 trailing closure 문법은 첫 번째 것만 인자 라벨이 생략되고, 두 번째부터는 라벨이 필요. 그래서 `action:` 은 생략, `label:` 은 명시.

### 6) `@State` — 뷰가 자체적으로 갖는 UI 상태

hover 중인지 아닌지는 "지금 이 한 버튼" 의 상태다. 부모(FloatingToolbar) 가 알 필요도 없고, 두 HoverButton 인스턴스가 **각자 따로** 가져야 한다 (하나만 어두워져야지 둘 다 같이 어두워지면 안 됨).

```swift
struct HoverButton<Label: View>: View {
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

### 7) default 파라미터 — Java 오버로딩의 한 줄짜리 대체

Java 에선 인자 일부에 기본값을 주려면 메서드 오버로딩으로 흉내내야 했다. Swift 는 한 줄.

```swift
struct HoverButton<Label: View>: View {
    var hoverFill: Color = .primary.opacity(0.08)   // ← default
    var cornerRadius: CGFloat = 6                    // ← default
    let action: () -> Void
    @ViewBuilder let label: () -> Label
}
```

이렇게 하면:
- 99% 의 호출은 그냥 `HoverButton { ... } label: { ... }` — hover 색/모서리 자동.
- 특별한 케이스만 명시: `HoverButton(hoverFill: .red.opacity(0.15)) { ... } label: { ... }`.

> 주의: stored property 에 default 를 주면 컴파일러가 만들어주는 자동 init 은 해당 인자를 default 가 있는 인자로 인식한다. 호출 측이 헷갈리지 않게 **(필수 인자들) → (default 인자들) → (트레일링 클로저용 마지막 인자)** 순서로 둔다. 위 예시에선 `action`, `label` 이 트레일링 클로저로 빠지므로 `hoverFill`/`cornerRadius` 는 그 앞에.

### 8) `Color.primary.opacity(...)` — "어두워지기 / 밝아지기" 를 자동으로

처음에 사용자가 짚은 핵심 케이스:

> 버튼이 투명일 땐 어두워져야 하고, 어두운 색이면 밝아져야 한다.

`Color.primary` 는 **시스템의 "전경" 색** 이다. 라이트 모드에선 검정, 다크 모드에선 흰색. 거기에 `.opacity(0.08)` 같은 약한 투명도를 곱해 배경에 깔면:
- 라이트 모드: 거의 투명한 검정 → 살짝 **어두워** 보임
- 다크 모드: 거의 투명한 흰색 → 살짝 **밝아** 보임

즉 "버튼이 위에 올라간 배경" 의 명도와 자동으로 반대 방향으로 움직인다 — 한 줄로 두 케이스 모두 해결.

> Material 배경(단계 3 에서 깐 `.regularMaterial`) 위에 `Color.primary.opacity(0.08)` 을 깔면, vibrancy 가 살짝 더 진해진 느낌으로 깔끔하게 떨어진다.

### 9) 조건부 modifier 값

modifier 자체를 조건부로 끼우는 게 아니라 (그건 더 어려운 패턴), **modifier 의 인자만 조건부로** 결정한다.

```swift
.background(isHovered ? hoverFill : Color.clear)
```

triple-equal 같은 거 없고 그냥 Java 의 삼항 연산자와 똑같다. SwiftUI 는 `isHovered` 가 바뀌면 body 를 다시 호출하니, background 색이 자연스럽게 갱신된다.

### 10) 어디에 padding / hit area 를 주나 — label 책임 vs 컴포넌트 책임

이전 IconButton 안 에서는 `frame(width:25, height:25)` 가 박혀 있었다. 하지만 label 을 범용화한 지금은:

- **label 의 크기/폰트는 호출 측 책임** (텍스트 길이가 달라질 수 있고, 아이콘마다 무게가 다름).
- **HoverButton 은 label 둘레에 일정한 padding 만 주고**, 그 padding 영역까지가 hover hit area 가 된다.

```swift
Button(action: action) {
    label()
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovered ? hoverFill : Color.clear)
        .clipShape(.rect(cornerRadius: cornerRadius))
}
```

이러면 아이콘 버튼이든 텍스트 버튼이든 **hover 영역이 콘텐츠 둘레에 일정하게** 따라온다.

### 11) 클로저 파라미터와 `@escaping` (살짝만)

`action: () -> Void` 는 함수 타입의 멤버다. Button 이 **나중에** (탭됐을 때) 호출하므로 init 에서 받아서 저장 → init 함수 밖으로 escape. 멤버 변수로 받을 때는 컴파일러가 알아서 escaping 으로 인식하니 **명시 안 해도 된다**. 단, 별도의 `init(...)` 을 직접 쓰면 `@escaping` 을 명시해야 함. 지금은 자동 init 만 쓰니 신경 안 써도 OK.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다. 사용자가 직접 작성.

### 새 파일

`JHCalendar/Features/FloatingToolbar/HoverButton.swift`

골격:

```swift
import SwiftUI

struct HoverButton<Label: View>: View {
    var hoverFill: Color = .primary.opacity(0.08)
    var cornerRadius: CGFloat = 6
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            label()
                // TODO: padding + background + clipShape
        }
        .buttonStyle(.plain)
        .pointerStyle(.link)
        .onHover { hovering in
            // TODO: isHovered 갱신
        }
    }
}
```

채워야 할 곳:
- label 호출 뒤에 `.padding(.horizontal, 8)` + `.padding(.vertical, 4)` 정도 — 콘텐츠 둘레에 hit area 형성.
- 그 다음 `.background(...)` 와 `.clipShape(...)` — hover 일 때만 색이 깔리도록.
  - `clipShape` 는 `.rect(cornerRadius: cornerRadius)`. 캡슐 카드 안의 작은 둥근 사각형 느낌.
- `.onHover { hovering in ... }` 안에서 `isHovered` 를 갱신.

> **제네릭 init 주의**: 제네릭 타입 파라미터(`Label`) 가 있어도 컴파일러가 자동 init 을 만들어준다. 단, `@ViewBuilder` 어노테이션은 자동 init 에도 그대로 전파되므로 호출 측 trailing closure 가 여러 줄이어도 OK.

### 수정할 파일

`JHCalendar/Features/FloatingToolbar/FloatingToolbar.swift`
- 두 `Button { ... } label: { ... } .buttonStyle(.plain) .pointerStyle(.link)` 블록을 각각 다음 형태로 대체:

```swift
HoverButton {
    print("Sidebar 버튼 클릭")
} label: {
    Image(systemName: "rectangle.leadinghalf.inset.filled")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(.primary)
        .frame(width: 25, height: 25)   // 아이콘이 작은 경우 hit area 키우는 용도, 필요시
}
```

- `frame(width:25, height:25)` 은 **호출 측 책임** 으로 옮긴 것. 아이콘 버튼이라 일정한 크기를 원하면 여기서. 텍스트 버튼은 frame 없이 패딩만으로 자연스러운 크기.
- `HoverButton` 안에서 이미 cursor 와 hover 배경을 다 처리하므로, FloatingToolbar 의 HStack 자체는 짧아진다.

### project.pbxproj 등록

새 파일이라 4군데 등록 필요 (PBXFileReference + PBXBuildFile + `FloatingToolbar` 그룹 children + PBXSourcesBuildPhase). `CLAUDE.md` 의 "새 기능을 추가할 때" 항목 참조.

### 힌트

- hover 색이 너무 진하면 답답하다. `0.08` ~ `0.12` 정도가 시스템 톤과 잘 맞는다. `0.05` 부터 시작해 조금씩 올려보면서 감을 익히면 좋다.
- `cornerRadius` 와 카드 전체의 캡슐 모양이 충돌하지 않는지 확인 — 콘텐츠 둘레의 padding 영역 안에서만 둥근 사각형이 나오면 OK.
- `Color.clear` 대신 `nil` 을 쓰는 패턴(`.background(isHovered ? hoverFill : nil)`) 도 있지만, 타입 추론이 까다로워질 수 있으니 처음엔 `Color.clear` 가 안전.
- 두 HoverButton 인스턴스는 각자 `@State` 를 갖는다 — 별도 코드 없이도 독립적으로 hover 가 동작하는지 꼭 확인 (이게 단계의 핵심 학습 체험 중 하나).
- 텍스트 버튼이 잘 받아지는지 mental check: `HoverButton { print("hi") } label: { Text("저장") }` 도 자연스럽게 컴파일 통과해야 한다 (지금 화면엔 안 넣지만, 머릿속으로 시그니처 확인).

## 직접 구현하기
- [x] `Features/FloatingToolbar/HoverButton.swift` 생성
- [x] 타입 파라미터 `<Label: View>` 선언
- [x] 멤버 변수 정의: `hoverFill` (default), `cornerRadius` (default), `action`, `@ViewBuilder label`
- [x] `@State private var isHovered`
- [x] body 에 Button + label() + padding + 조건부 background + clipShape
- [x] `.onHover` 에서 `isHovered` 갱신
- [x] `.buttonStyle(.plain)` + `.pointerStyle(.link)` 적용
- [x] `project.pbxproj` 4군데 등록
- [x] `FloatingToolbar.swift` 의 두 Button 블록을 `HoverButton { ... } label: { ... }` 로 교체
- [x] ⌘B 빌드 통과 / ⌘R 실행
- [x] hover 시 배경이 살짝 어두워지고, 빠지면 원상복귀
- [x] 두 버튼이 **각자** hover 동작 (한쪽만 어두워짐)
- [x] 다크 모드로 바꿔도 자연스러운지 (System Settings → Appearance)
- [x] 손모양 커서도 그대로 작동하는지 (단계 4 회귀 없는지)

> 다 끝나면 "다 했어" 라고 알려줘. 리뷰할게.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 호버 톤(0.08 부근) 이 너무 강하지도 약하지도 않은가? 다른 값 (0.05 / 0.15) 도 잠깐 시도해 비교해본 적 있는가?
- 자문자답: 왜 `IconButton` 이 아니라 `HoverButton<Label>` 인가? (정답: 진짜 재사용 가치가 있는 책임은 "인터랙션 묶음" 이고, 콘텐츠 모양은 호출 측 관심사. label 을 generic + @ViewBuilder 로 열어두면 텍스트 버튼·아이콘+텍스트 조합 등이 한 컴포넌트로 모두 커버됨.)
- 자문자답: 왜 `@State` 를 HoverButton **안** 에 두지, FloatingToolbar 에 두 개를 두지 않는가? (정답: 상태가 그 뷰 본인에게만 의미가 있고, 인스턴스마다 독립적이어야 하기 때문. 부모로 끌어올릴 이유가 없음 — 부모가 hover 여부를 알 필요가 없음. 일반 원칙: state 는 그것을 쓰는 가장 가까운 뷰에 둔다.)
- 자문자답: `@ViewBuilder` 가 없으면 어떤 호출이 깨지는가? (정답: label 클로저 안에 단일 표현식만 가능해져, `Image + Text` 같은 다중 자식 나열이 컴파일 에러. SwiftUI 의 `HStack { Image; Text }` 가 되는 마법이 곧 `@ViewBuilder`.)
- 자문자답: 만약 hover 시 글씨색까지 바꾸고 싶으면 어디를 어떻게 늘릴 것인가? (정답: 이건 label 안의 modifier 라 호출 측에서 처리해도 되고, 정말 자주 쓰는 패턴이면 `hoverForeground: Color?` default 파라미터를 추가하고 `.foregroundStyle(...)` 을 label 호출 후에 적용. 단, label 안 modifier 가 우선될 수 있어 적용 순서 주의.)
- 자문자답: `Color.primary.opacity(0.08)` 이 라이트/다크 두 모드 모두에서 자연스러운 이유? (정답: `Color.primary` 가 시스템 전경 색이라 모드에 따라 검정/흰색으로 자동 전환되고, 같은 opacity 로 살짝 깔리니 어두워지기/밝아지기 둘 다 한 줄로 처리됨.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `HoverButton` 이 단일 책임만 갖는다 (인터랙션 묶음: hover 배경 + 손모양 커서 + plain style)
- [x] 제네릭 타입 파라미터 `<Label: View>` 와 `@ViewBuilder label` 로 임의 콘텐츠 받음
- [x] `Button(action:label:)` 과 같은 trailing closure 두 개 시그니처 (호출 측 일관성)
- [x] `@State isHovered` 가 HoverButton **내부**에 있고 부모로 새지 않는다
- [x] `hoverFill`, `cornerRadius` 에 default 값이 있어 호출 측이 한 줄에 머문다 *(현재 구현은 `hoverfill` — Swift 관용 camelCase 로 정정 권장)*
- [x] hover 색은 시스템 적응형 (`Color.primary.opacity(...)` 또는 그에 준하는 적응형 색) — 하드코딩된 `.gray` 등이 아님
- [x] cursor 처리는 `.pointerStyle(.link)` 한 줄 — `.onHover` + AppKit 우회를 새로 만들지 않음
- [x] padding 은 컴포넌트 책임, label 의 폰트/크기는 호출 측 책임으로 분리됨
- [x] `FloatingToolbar.swift` 가 짧아졌고, 거기서 직접 hover 상태를 갖지 않음
- [x] 새 파일이 `project.pbxproj` 4군데에 등록되어 빌드 통과
- [x] mental check: 텍스트 label (`HoverButton { ... } label: { Text("...") }`) 도 컴파일·실행에 무리 없는 형태

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **ButtonStyle 도전**: `HoverButton` 대신 `PlainHoverButtonStyle: ButtonStyle` 을 만들어 `.buttonStyle(...)` 한 줄로 적용. 단, `ButtonStyle.makeBody(configuration:)` 에서 받는 `Configuration` 은 `isPressed` 만 알려주고 hover 는 모른다 — 그래서 `configuration.label` 을 다시 wrapping 하는 작은 helper view 가 필요해진다. 어떤 방식이 더 깔끔한지 비교해보면 좋다.
- **press 피드백**: hover 보다 더 진한 톤(예: opacity 0.16) 을 누르는 동안 깔리도록. `Button` 에 `ButtonStyle` 없이 만들면 pressed 감지가 어려우니, 이때 ButtonStyle 도입 동기가 생긴다.
- **`.help("새 일정 추가")`**: 한 줄로 시스템 tooltip 추가. 손모양 커서 + 배경 변화 + tooltip 의 3 콤보가 macOS 표준 UX 에 가장 가까움.
- **접근성**: `.accessibilityLabel("새 일정 추가")` 로 VoiceOver 사용자에게 의미 전달. 아이콘 버튼은 라벨이 없으므로 명시적으로 알려주는 것이 좋음.
- **편의 init 추가 (선택)**: 자주 쓰는 SF Symbol 케이스만 짧게 부를 수 있도록 extension 으로 편의 이니셜라이저 하나 더. 호출 측이 `HoverButton(systemName: "plus") { print(...) }` 같이 쓸 수 있게. 다만 두 가지 호출 패턴이 공존하면 일관성이 흐려질 수도 있어 진짜 자주 쓰일 때만.
  ```swift
  extension HoverButton where Label == Image {
      init(systemName: String, action: @escaping () -> Void) {
          self.init(action: action) {
              Image(systemName: systemName)
                  .font(.system(size: 14, weight: .medium))
                  .foregroundStyle(.primary)
                  .frame(width: 25, height: 25)
          }
      }
  }
  ```
  `where Label == Image` 가 핵심 — "label 자리가 정확히 `Image` 일 때만 이 init 이 존재" 라는 제약. Java 의 generic bound 와 비슷하지만, **타입 동등성** 까지 표현 가능한 부분이 더 강력함.
