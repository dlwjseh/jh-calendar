# 단계 1: 상태 끌어올리기 + `@Binding`

## 학습 목표
- 사이드바 펼침 여부 (`isSidebarVisible`) 의 **소유자** 가 어디여야 하는지 결정한다.
- `@State` 가 한 뷰의 **자기 상태** 였다면, `@Binding` 은 **다른 뷰의 상태에 대한 양방향 참조** 임을 이해한다.
- `$state` 문법으로 `@State` 변수에서 binding 을 추출하는 패턴을 익힌다.

## 사전 지식
- 기능 02 까지 완료. `FloatingToolbar` 안의 사이드바 버튼은 현재 `print(...)` 만 찍는다.
- `@State` 가 무엇인지 (단계 02-5 에서 다룸) — 뷰가 자체적으로 갖는 UI 상태.
- `ContentView.swift` 가 `ZStack(alignment: .topLeading)` 안에 `Color.clear / TrafficLightHoverArea / FloatingToolbar` 를 쌓고 있다.

## Swift / SwiftUI 개념

### 1) state 의 소유권 — 누가 들고 있어야 할까

지금 상황을 정리하면:
- 토글을 **유발** 하는 건 `FloatingToolbar` 안의 사이드바 버튼.
- 토글에 **반응** 해야 하는 건 사이드바 뷰 (= FloatingToolbar 의 형제 / 곧 만들 것) 와 메인 콘텐츠 영역 둘.

`@State var isSidebarVisible` 을 어디에 둘까?

- (A) `FloatingToolbar` 안에 둔다 → 사이드바 뷰가 그 값을 어떻게 알지? 부모/형제 관계라 자연스러운 통로가 없다.
- (B) **공통 부모** (= `ContentView`) 에 둔다 → FloatingToolbar 와 Sidebar 모두 같은 부모를 통해 그 상태를 공유한다.

이게 SwiftUI / React / Vue 가 모두 공유하는 **"state lifting (lift state up)"** 원칙:

> **여러 뷰가 공유해야 하는 상태는, 그것을 공유하는 가장 가까운 공통 부모에 둔다.**

Vue 비유:
- 부모 컴포넌트에 `ref(false)` 를 두고
- 자식에게 `props` 로 내려보낸 뒤
- 자식이 `emit('update:isVisible', ...)` 로 다시 알려 부모가 갱신
- → 그 두 방향(내려가는 prop + 올라가는 emit) 을 한 줄로 묶은 게 Vue 의 `v-model`.

SwiftUI 의 `@Binding` 은 이 `v-model` 과 거의 정확히 대응되는 메커니즘이다.

### 2) `@State` 와 `@Binding` 의 관계

```swift
// ContentView (소유자)
@State private var isSidebarVisible = false

// FloatingToolbar (사용자, 부모의 상태를 양방향으로 빌려옴)
@Binding var isSidebarVisible: Bool
```

- `@State`: "내가 이 값의 **단독 소유자** 다. 값이 바뀌면 내 body 가 다시 호출된다."
- `@Binding`: "이 값은 **다른 누군가의 @State** 다. 나는 그걸 읽고 쓸 수 있는 양방향 통로만 가진다."

자식이 `isSidebarVisible.toggle()` 하면 → 실제 저장소(부모의 @State) 가 갱신 → 부모와 부모 아래의 다른 자식들이 모두 다시 그려진다.

백엔드 비유: 같은 DB 레코드를 가리키는 두 서비스 — 한쪽이 update 하면 다른 쪽도 같은 값을 본다. `@Binding` 은 그 "레코드 포인터" 인 셈. 다만 read/write 모두 type-safe.

### 3) `$` prefix — projected value 문법

`@State` 가 붙은 변수는 사실 두 가지 얼굴을 가진다:

- `isSidebarVisible` — 평범한 `Bool` 값.
- `$isSidebarVisible` — 같은 값에 대한 **`Binding<Bool>`** (양방향 참조).

`$` 가 그 두 번째 얼굴을 꺼내는 문법:

```swift
struct ContentView: View {
    @State private var isSidebarVisible = false

    var body: some View {
        FloatingToolbar(isSidebarVisible: $isSidebarVisible)   // ← $ 로 binding 전달
    }
}
```

Java 관점에서 처음엔 어색한데, `$x` 는 "x 의 양방향 참조를 꺼내는 연산자" 라고 받아들이면 된다. C 의 `&x` 와 비슷한 발상이지만, type-safe 하고 컴파일러가 wrapper 를 통해 정합성을 보장.

이 `$` 는 더 일반적으론 **property wrapper 의 projected value** 를 꺼내는 문법으로, `@State` 외에 `@Binding`, `@FocusState`, `@Environment` 등 여러 wrapper 가 자기 나름의 projected value 를 제공한다. 지금은 "@State 의 projected value 가 곧 Binding" 이라고만 알아두면 충분.

### 4) Binding 을 받은 자식은 그 값을 어떻게 쓰나

Binding 을 받은 자식 안에서는 **그냥 평범한 변수처럼** 읽고 쓸 수 있다:

```swift
struct FloatingToolbar: View {
    @Binding var isSidebarVisible: Bool

    var body: some View {
        HoverButton {
            isSidebarVisible.toggle()   // ← 부모의 @State 가 갱신됨
        } label: { ... }
    }
}
```

`.toggle()` 만 호출하면 SwiftUI 가 알아서:
1. 부모의 실제 저장소 갱신
2. 부모와 부모의 자식들이 다시 그려지도록 트리거

### 5) `@Binding` 의 init 규칙

`@Binding` 은 stored property 가 아니라 wrapper. **자기 자신은 값을 저장하지 않고**, 외부 저장소(부모의 @State) 를 가리킨다. 따라서:

- **default 값을 줄 수 없다.** `@Binding var x: Bool = false` ❌
- **호출 측이 반드시 명시적으로 binding 을 넘겨야 한다.** `FloatingToolbar(isSidebarVisible: $...)`
- 컴파일러가 만들어주는 자동 init 의 인자에 binding 이 들어간다.

### 6) `.constant(_:)` — 자식 단독 preview 를 위한 정적 binding

만약 `FloatingToolbar` 만 단독 preview 하고 싶다면:

```swift
#Preview {
    FloatingToolbar(isSidebarVisible: .constant(false))
}
```

`.constant(_:)` 는 "값이 절대 안 바뀌는 read-only binding" — preview 처럼 상호작용을 안 봐도 되는 곳에 편하다. 진짜 토글 동작을 보려면 wrapping view 를 만들어야 하지만, 그건 나중 일.

> 본 단계에선 `#Preview { ContentView() }` 가 그대로 OK. ContentView 가 owner 라 binding 까지 알아서 흘러간다.

## 구현 가이드

### 수정할 파일

**`JHCalendar/ContentView.swift`**
- `@State private var isSidebarVisible = false` 추가.
- `FloatingToolbar()` 호출에 binding 전달: `FloatingToolbar(isSidebarVisible: $isSidebarVisible)`.

**`JHCalendar/Features/FloatingToolbar/FloatingToolbar.swift`**
- 멤버 변수 `@Binding var isSidebarVisible: Bool` 추가.
- 사이드바 버튼의 액션 클로저에서 `isSidebarVisible.toggle()` 로 변경 (기존 print 는 제거하거나 디버깅용으로 잠깐 유지).

> 사이드바 뷰는 **이 단계에서 만들지 않는다.** 다음 단계의 주제.

### 동작 확인 방법

지금 단계는 화면에 변화가 없으니 **확인 수단** 이 필요. 두 옵션:
- (a) `print("isSidebarVisible: \(isSidebarVisible)")` 를 toggle 직후에. Xcode 콘솔에서 값이 true ↔ false 로 바뀌는지 확인.
- (b) 임시로 ContentView 안에 `Text("\(isSidebarVisible.description)")` 한 줄 — 시각적으로 토글 확인 후 제거.

### 힌트

- Xcode 가 `@Binding var isSidebarVisible: Bool` 까지 입력하면 자동 init 에 그 인자가 추가된다 → ContentView 호출 사이트가 "Missing argument" 컴파일 에러 → 자연스럽게 `$isSidebarVisible:` 를 채우게 됨. 컴파일러가 학습 가이드.
- `@Binding` 변수는 default 값이 없다. 컴파일러가 친절히 알려주니 한 번 일부러 `= false` 도 적어보고 메시지 읽어볼 가치.
- `@State` 옆 `private` 는 SwiftUI 관용 — 외부 노출이 의미 없음. 자식은 `@State` 를 직접 못 읽고 `@Binding` 으로만 받는다.

## 직접 구현하기
- [x] `ContentView` 에 `@State private var isSidebarVisible = false` 추가
- [x] `FloatingToolbar(isSidebarVisible: $isSidebarVisible)` 로 호출 갱신
- [x] `FloatingToolbar` 에 `@Binding var isSidebarVisible: Bool` 멤버 추가
- [x] 사이드바 버튼 액션을 `isSidebarVisible.toggle()` 로 변경
- [x] print 또는 임시 Text 로 toggle 동작 확인
- [x] ⌘B 빌드 통과 / ⌘R 실행
- [x] 사이드바 버튼 누를 때마다 값이 true ↔ false 로 바뀌는지 확인
- [x] (확인 끝나면) print / 임시 Text 제거 — 다음 단계는 진짜 사이드바 뷰

> 다 끝나면 "다 했어" / "이렇게 했어" 라고 알리면 Claude 가 리뷰.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: 왜 `isSidebarVisible` 을 `FloatingToolbar` 가 아니라 `ContentView` 에 두었는가? (정답: 사이드바 뷰가 FloatingToolbar 의 자식이 아니라 형제이므로, 둘이 공유하는 가장 가까운 공통 부모인 ContentView 에 두는 게 자연스럽다 — state lifting 원칙.)
- 자문자답: `$isSidebarVisible` 의 `$` 는 무엇인가? (정답: `@State` property wrapper 가 제공하는 projected value, 즉 `Binding<Bool>`. C 의 `&x` 와 비슷한 발상이지만 type-safe.)
- 자문자답: `@Binding var x: Bool = false` 같이 default 를 줄 수 있나? (정답: 없다. Binding 은 외부 저장소에 대한 참조이므로 자체 초기값이 무의미.)
- 자문자답: ContentView 가 `@Binding` 이 아니라 `@State` 인 이유? (정답: ContentView 가 그 값의 **소유자** 이기 때문. Binding 은 다른 누군가의 state 를 빌려오는 통로.)
- 자문자답: 자식 안에서 `isSidebarVisible.toggle()` 만 호출했는데 부모와 다른 자식까지 다시 그려지는 이유? (정답: Binding 은 외부 저장소에 대한 참조라 toggle 이 실제 @State 를 갱신함 → @State 의존성을 가진 부모가 invalidate → 부모 body 가 다시 호출됨 → 그 안의 다른 자식도 갱신.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `ContentView` 에 `@State private var isSidebarVisible = false` 가 있다 (private 포함)
- [x] `FloatingToolbar` 가 `@Binding var isSidebarVisible: Bool` 멤버 (default 값 없음) 를 받는다
- [x] ContentView 호출부가 `$isSidebarVisible` 으로 binding 을 전달
- [x] 사이드바 버튼 액션이 `isSidebarVisible.toggle()` (또는 그에 준하는 갱신)
- [x] 토글 동작이 콘솔/임시 Text 로 검증 가능
- [x] 임시 디버그 코드 (print/Text) 가 단계 종료 후 제거되거나 주석으로 남았는지

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **`@State` 의 저장소 비밀**: `@State` 가 struct 안에 있는데도 값이 바뀔 수 있는 이유 — 실제 저장소는 SwiftUI 가 별도로 관리하고, `@State` 는 그것을 가리키는 wrapper. struct 가 매번 새로 만들어져도 같은 view-identity 사이에선 저장소가 유지된다. 이 메커니즘이 React 의 useState 와 매우 비슷한 발상.
- **Observable 객체로 끌어올리기**: 화면 여러 곳에서 같은 토글을 만져야 할 만큼 복잡해지면 `@Observable` class 로 옮겨, environment 로 어디서든 받을 수 있게 한다 — SwiftUI 판 "store" 패턴 (Vue 의 pinia, React 의 Context+useReducer 와 같은 발상). 이 앱 규모에선 아직 과함.
- **타입 단축 init 트릭**: 호출 측을 짧게 하고 싶으면 자식에 `init(isSidebarVisible: Binding<Bool>)` 을 직접 정의해 default 처리할 수도 있는데, 자동 init 으로도 충분하므로 지금은 안 건든다.
