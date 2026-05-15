# 단계 2: Coordinator 로 양방향 바인딩 완성

## 학습 목표
- `Coordinator` 가 왜 필요한지(AppKit → SwiftUI 역방향) 설명할 수 있다.
- `makeCoordinator()` / `context.coordinator` 의 흐름을 안다.
- AppKit 의 target/action 을 `@objc` + `#selector` 로 Swift 메서드에 연결할 수 있다.
- 이 단계 끝에는 **피커에서 시간을 바꾸면 `startDate` 가 갱신**된다(양방향 완성).

## 사전 지식
- 01 산출물 — `BorderlessTimePicker` 가 단방향(SwiftUI → AppKit)까지 동작. 피커에서 바꾼 값은 아직 안 돌아옴.
- `@Binding`, `@State` → [01-타이틀바-호버표시](../01-타이틀바-호버표시/) 참고 (재설명 X)
- 01 의 `makeNSView`/`updateNSView` 구조

## Swift / SwiftUI 개념

### 1) 왜 Coordinator 가 필요한가 — 역방향의 부재

01 까지 데이터 흐름:

```
SwiftUI @State startDate ──(updateNSView)──▶ NSDatePicker   (단방향, 됨)
SwiftUI @State startDate ◀──     ???     ── NSDatePicker   (역방향, 없음)
```

사용자가 피커에서 시간을 바꿔도, AppKit 은 SwiftUI 의 `@Binding` 존재를 모른다. **AppKit 의 이벤트(target/action)를 받아 `@Binding` 에 되써주는 중개 객체**가 필요 — 그게 `Coordinator`.

> **Vue 비유**: 네이티브 위젯 래퍼에서 위젯의 `change` 이벤트 핸들러를 등록하고, 그 핸들러가 `emit('update:modelValue', newVal)` 로 부모에게 값을 올려보내는 것. Coordinator = 그 "이벤트 핸들러를 담고 부모 참조를 쥔" 객체.
> **Spring 비유**: 이벤트 리스너 빈이 콜백을 받아 모델을 갱신하는 것과 같은 위치.

### 2) `makeCoordinator()` 와 라이프사이클

`NSViewRepresentable` 이 제공하는 세 번째 메서드:

```swift
func makeCoordinator() -> Coordinator {
    Coordinator(self)   // self(=현재 representable, @Binding 포함)를 넘겨 보관
}
```

- SwiftUI 가 **최초 1회** 호출해 만든 뒤, 뷰 갱신 동안 **계속 유지**해준다 (state 처럼 안 사라짐).
- 만들어진 인스턴스는 `makeNSView(context:)` / `updateNSView(_:context:)` 안에서 **`context.coordinator`** 로 접근.
- 호출 순서: `makeCoordinator()` → `makeNSView()` → (상태 변할 때마다) `updateNSView()`.

### 3) target/action + `@objc` + `#selector`

AppKit 컨트롤(`NSDatePicker`, `NSButton` 등)은 값이 바뀌면 **target 객체의 action 메서드**를 호출한다 (옛 Objective-C 메커니즘).

```swift
picker.target = context.coordinator
picker.action = #selector(Coordinator.changed(_:))
```

- **`#selector(...)`** — "이벤트가 나면 이 메서드를 호출해" 라는 메서드 포인터. Java 의 메서드 레퍼런스 `Coordinator::changed` 와 같은 역할이지만, Objective-C 런타임이 이름으로 찾는 방식이라 대상 메서드에 `@objc` 가 필요.
- **`@objc`** — "이 메서드를 Objective-C 런타임에 노출" 표식. Java 의 `@Override`/리플렉션용 애너테이션처럼 **컴파일러·런타임용 메타 정보**. 안 붙이면 `#selector` 가 못 찾아 런타임 크래시 또는 컴파일 에러.
- **`NSObject` 상속** — target/action·KVC 같은 ObjC 런타임 기능을 쓰려면 Coordinator 가 `NSObject` 를 상속해야 함.

### 4) 콜백에서 `@Binding` 에 쓰기

Coordinator 가 `parent`(= representable 인스턴스)를 들고 있으므로, 콜백에서 `parent.date = sender.dateValue` 한 줄이면 `@Binding` 을 통해 부모 `@State` 까지 전파된다. (`$` 아님 — `parent.date` 에 직접 대입하면 binding setter 가 돈다.)

## 구현 가이드
> 정답 풀코드는 제공하지 않는다. 골격 + 힌트만.

### 채울 3조각

```swift
struct BorderlessTimePicker: NSViewRepresentable {
    @Binding var date: Date

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        // (01 에서 한 설정들 그대로)
        // TODO ③: picker.target / picker.action 연결
        return picker
    }

    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        nsView.dateValue = date
    }

    // TODO ②: makeCoordinator() 추가

    // TODO ①: Coordinator 클래스 (중첩)
    class Coordinator: NSObject {
        var parent: BorderlessTimePicker
        init(_ parent: BorderlessTimePicker) { self.parent = parent }

        @objc func changed(_ sender: NSDatePicker) {
            // TODO: parent 의 binding 에 sender.dateValue 쓰기
        }
    }
}
```

### 막힐 만한 지점 — 힌트
- **`#selector` 가 컴파일 안 됨 / "method not found"** — 대상 메서드에 `@objc` 빠졌거나, Coordinator 가 `NSObject` 상속을 안 함. 둘 다 필수.
- **`#selector(Coordinator.changed(_:))` 표기** — 인자 라벨 포함. `changed(_:)` 처럼 underscore 라벨까지 적는다.
- **값이 여전히 안 돌아옴** — `picker.target`/`picker.action` 을 `makeNSView` 에서 설정했는지 확인. target 은 `context.coordinator` 여야 함(새 객체 만들지 말 것).
- **무한 루프/깜빡임 의심** — `updateNSView` 에서 매번 `dateValue` 를 쓰는 건 보통 문제없음(같은 값이면 AppKit 이 무시). 이상하면 값이 실제로 달라졌을 때만 쓰도록 가드.
- **`@Binding` 에 쓰는 법** — `parent.date = sender.dateValue`. `parent.$date` 가 아니라 `parent.date`.

## 직접 구현하기
- [ ] `Coordinator: NSObject` 중첩 클래스 — `parent` 보관 + `init`
- [ ] `@objc func changed(_ sender: NSDatePicker)` — `parent.date = sender.dateValue`
- [ ] `makeCoordinator() -> Coordinator` 구현
- [ ] `makeNSView` 에서 `picker.target = context.coordinator` / `picker.action = #selector(Coordinator.changed(_:))`
- [ ] 빌드 통과
- [ ] 동작 확인 — 피커에서 시간 변경 → 다른 곳(저장 디버그 출력 등)에서 `startDate` 갱신 확인

## 자가 점검
- 빌드 OK?
- 피커에서 시:분을 바꾸면 SwiftUI 쪽 `startDate` 가 실제로 갱신되나? (예: 저장 버튼 액션의 `print(startDate)` 로 확인, 또는 날짜 popover 와 같은 `Date` 라 popover 재오픈 시 반영 확인)
- 날짜 popover 에서 날짜를 바꿔도 시간 부분이 안 깨지나? (같은 `Date` 공유 — 날짜/시간이 서로의 값을 안 지우는지)
- 이해도 퀴즈
  1. `makeCoordinator()` 는 몇 번 호출되나? 그 결과는 어디서 다시 꺼내 쓰나?
  2. `@objc` 를 빼면 무슨 일이 일어나나? 왜?
  3. 콜백에서 `parent.date = ...` 가 부모 `@State` 까지 전파되는 이유는? (`@Binding` 의 정체)

## Claude 리뷰 체크리스트
- [ ] `Coordinator` 가 `NSObject` 상속 + `parent` 보관
- [ ] `@objc func changed(_:)` 에서 `@Binding` 갱신
- [ ] `makeCoordinator()` 구현, `makeNSView` 에서 `context.coordinator` 를 target 으로 연결
- [ ] `#selector` 표기 정확 (`changed(_:)`)
- [ ] 양방향 동작 — 피커 변경이 `startDate` 로 전파, 날짜/시간 상호 비파괴
- [ ] 빌드 통과

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- delegate 패턴 — `NSDatePicker` 는 `NSDatePickerCellDelegate` 도 제공. target/action 과 delegate 의 차이(단일 액션 vs 풍부한 콜백).
- `Coordinator` 가 SwiftUI 어디서나 쓰이는 패턴 — `UIViewRepresentable`, `UIViewControllerRepresentable` 도 동일하게 Coordinator 로 역방향을 잇는다.
