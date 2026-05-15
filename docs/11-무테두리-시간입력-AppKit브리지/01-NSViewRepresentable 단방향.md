# 단계 1: NSViewRepresentable 단방향 (무테두리 피커 띄우기)

## 학습 목표
- `NSViewRepresentable` 로 AppKit 의 `NSDatePicker` 를 SwiftUI 화면에 띄울 수 있다.
- `makeNSView` / `updateNSView` 의 역할(라이프사이클)을 구분해 설명할 수 있다.
- `isBordered = false` / `drawsBackground = false` 로 테두리·배경이 없는 시간 입력을 만든다.
- 이 단계 끝에는 **SwiftUI → AppKit 단방향**까지만 — 피커에서 바꾼 값은 아직 안 돌아온다(의도된 미완성, 02 에서 완성).

## 사전 지식
- `@State`, `@Binding` → [01-타이틀바-호버표시](../01-타이틀바-호버표시/) 참고
- 10 단계 산출물 — `JHCalendar/Features/Event/AddEventDialog.swift` 의 "시작" 행에 `startDate: Date` 와 시간 DatePicker 가 있음
- 빈 stub 파일 `JHCalendar/Features/Event/BorderlessTimePicker.swift` 가 이미 존재 (여기 채운다)
- AppKit 을 만져본 적 있음 — [TrafficLightController.swift](../../JHCalendar/Features/TitleBar/TrafficLightController.swift) 에서 `NSApplication`/`NSButton` 사용. 단 거긴 "AppKit 호출"이고, 이번엔 "AppKit **뷰를 SwiftUI 안에 심는**" 것이라 결이 다름.

## Swift / SwiftUI 개념

### 1) `NSViewRepresentable` — SwiftUI 안의 AppKit 뷰

SwiftUI 는 선언형이고 AppKit 은 명령형(`NSView` 인스턴스를 만들고 속성을 set)이다. 둘을 잇는 공식 어댑터가 `NSViewRepresentable` 프로토콜.

> **Vue 비유**: Vue 컴포넌트 안에서 옛 jQuery 플러그인을 쓰려고 `mounted()` 에서 DOM 노드를 만들고, `props` 가 바뀌면 `watch` 로 위젯을 갱신하는 래퍼 컴포넌트. `makeNSView` ≈ `mounted` (1회 생성), `updateNSView` ≈ `watch`(prop 변화 시 반영).

핵심 메서드 두 개:

```swift
struct BorderlessTimePicker: NSViewRepresentable {
    @Binding var date: Date

    // ① 뷰를 "한 번" 만든다. 초기 설정은 전부 여기서.
    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        // ... 설정 ...
        return picker
    }

    // ② SwiftUI 상태가 바뀔 때마다 호출 — 그 값을 AppKit 뷰에 "밀어넣기"
    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        nsView.dateValue = date
    }
}
```

| 메서드 | 호출 시점 | 방향 | 비유 |
|---|---|---|---|
| `makeNSView` | 최초 1회 | — | Vue `mounted` / 생성자 |
| `updateNSView` | SwiftUI 상태 변경마다 | **SwiftUI → AppKit** | Vue `watch(prop)` |

> `associatedtype NSViewType` 은 반환 타입(`NSDatePicker`)으로 **자동 추론**되므로 직접 안 적어도 됨.

### 2) `NSDatePicker` 의 무테두리 설정

AppKit `NSDatePicker` 가 SwiftUI `DatePicker` 와 다른 점은 **테두리/배경 스위치를 노출**한다는 것:

```swift
picker.datePickerStyle = .textFieldDatePickerStyle  // 세그먼트 클릭 → 키보드 입력
picker.datePickerElements = .hourMinuteDatePickerElementFlag  // 시/분만
picker.isBordered = false        // ← 테두리 OFF (SwiftUI DatePicker엔 없는 스위치)
picker.drawsBackground = false   // ← 배경 OFF
```

- `.textFieldDatePickerStyle` — 우리가 원하던 "세그먼트 클릭 → 파란 하이라이트 → 타이핑" 동작
- 스피너 화살표까지 빼려면 elements 에 stepper 플래그를 안 넣으면 됨 (위처럼 `.hourMinute...` 만)

> 열거형 이름이 길다(`.textFieldDatePickerStyle`). Xcode 자동완성에서 `.textField` 까지 치면 후보가 나옴. 짧은 별칭(`.textField`)이 되는 경우도 있으니 자동완성 후보를 보고 고를 것.

### 3) `@Binding var date: Date` — 부모와 공유

10 의 `AddEventDialog` 가 `@State var startDate` 를 갖고 있고, 이 컴포넌트엔 `$startDate` 를 넘긴다. `@Binding` 은 09/10 에서 쓰던 그 바인딩과 동일 개념 — [10/02-AddEventDialog UI.md](../10-이벤트-추가-다이얼로그/02-AddEventDialog%20UI.md) 의 Toggle `isOn: $isAllDay` 와 같은 결.

## 구현 가이드
> 정답 풀코드는 제공하지 않는다. 골격 + 힌트만.

### 파일
- `JHCalendar/Features/Event/BorderlessTimePicker.swift` (이미 빈 struct 있음 — 채우기)

### 핵심 골격

```swift
import SwiftUI
import AppKit

struct BorderlessTimePicker: NSViewRepresentable {
    @Binding var date: Date

    func makeNSView(context: Context) -> NSDatePicker {
        let picker = NSDatePicker()
        // TODO: datePickerStyle / datePickerElements 설정
        // TODO: isBordered = false / drawsBackground = false
        // TODO: picker.dateValue 초기값 (date)
        return picker
    }

    func updateNSView(_ nsView: NSDatePicker, context: Context) {
        // TODO: SwiftUI 의 date 를 nsView 에 반영 (단방향)
    }
}
```

### 쓰는 쪽 (AddEventDialog 의 "시작" 행, 기존 시간 DatePicker 교체)

```swift
// 기존: DatePicker("", selection: $startDate, displayedComponents: .hourAndMinute)
//         .datePickerStyle(.field) ...
// 교체:
BorderlessTimePicker(date: $startDate)
    .frame(width: 70)   // intrinsic size 가 작거나 0 일 수 있어 폭 지정
```

### 막힐 만한 지점 — 힌트
- **피커가 안 보이거나 폭이 0** — `NSViewRepresentable` 은 intrinsic content size 가 불안정할 때가 있음. `.frame(width:)` 또는 `.fixedSize()` 로 크기를 명시.
- **`.textFieldDatePickerStyle` 이름을 못 찾음** — Xcode 자동완성에서 `NSDatePicker.Style` 후보 확인. 버전에 따라 `.textField` 별칭이 있을 수 있음.
- **시:분만 나오게** — `datePickerElements` 에 `.hourMinute...` 만. (시:분:초까지 나오면 second 플래그가 섞인 것)
- **이 단계에서 피커를 돌려도 다이얼로그의 다른 곳 값이 안 변함** — **정상**. 아직 단방향. 02 에서 Coordinator 로 역방향을 연결한다.
- **`updateNSView` 가 비어도 빌드는 됨** — 단방향 확인하려면 `nsView.dateValue = date` 한 줄은 채워야 startDate 초기값이 보임.

## 직접 구현하기
- [ ] `import AppKit` + `@Binding var date: Date`
- [ ] `makeNSView` — `NSDatePicker` 생성, `.textField` 스타일, `.hourMinute` elements
- [ ] `isBordered = false`, `drawsBackground = false`
- [ ] `makeNSView` 안에서 `picker.dateValue = date` 초기 반영
- [ ] `updateNSView` — `nsView.dateValue = date`
- [ ] `AddEventDialog` 시간 자리를 `BorderlessTimePicker(date: $startDate)` 로 교체
- [ ] 빌드 통과 (⌘B)

## 자가 점검
- 빌드 OK?
- 다이얼로그에서 시작 행의 시간이 **테두리·배경 없이** 표시되나?
- 시간 세그먼트를 클릭하면 파란 하이라이트가 뜨고 키보드 입력이 되나? (값이 SwiftUI 로 안 돌아오는 건 아직 정상)
- 옆 날짜 `Text` 와 세로 정렬이 맞나? (안 맞으면 03 에서 정리 — 지금은 chrome 제거만 확인)
- 이해도 퀴즈
  1. `makeNSView` 와 `updateNSView` 중, 부모의 `@State startDate` 가 바뀌었을 때 호출되는 건?
  2. SwiftUI `DatePicker` 로는 왜 테두리 제거가 안 되고 `NSDatePicker` 로는 되나? (어떤 속성 차이?)
  3. 이 단계까지 데이터 흐름은 단방향이다. 어느 방향인가? (SwiftUI → AppKit? 그 반대?)

## Claude 리뷰 체크리스트
- [ ] `NSViewRepresentable` 채택 + `@Binding var date`
- [ ] `makeNSView` 에 초기 설정 집중 / `updateNSView` 에 상태 반영 — 역할 분리 적절
- [ ] `isBordered`/`drawsBackground` 로 무테두리 달성
- [ ] `.textFieldDatePickerStyle` + `.hourMinute` 로 원하는 입력 동작
- [ ] AddEventDialog 의 기존 인라인 `.field` DatePicker 가 교체됨
- [ ] 빌드 통과 (역방향 미구현은 이 단계에선 OK)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `NSViewRepresentable` 과 짝이 되는 iOS 쪽 `UIViewRepresentable` — 이름만 다르고 구조 동일. 크로스플랫폼 코드에서 분기하는 패턴.
- `sizeThatFits` / intrinsicContentSize — AppKit 뷰 크기를 SwiftUI 레이아웃에 더 잘 맞추는 방법.
