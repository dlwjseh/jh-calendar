# 단계 3: CalendarStore 도입 — ObservableObject + @StateObject

## 학습 목표
- View struct 가 매 body 재평가마다 재생성된다는 SwiftUI 의 기본 동작을 정확히 안다.
- 상태/계산을 View 밖으로 빼는 SwiftUI 표준 패턴 — **`ObservableObject` + `@Published` + `@StateObject`** — 을 익힌다.
- `@MainActor` 가 무엇을 보장하는지 안다.

## 사전 지식
- `@State` → [01-3](../01-타이틀바-호버표시/03-호버%20영역과%20상태%20관리.md)
- struct vs class → [04-1](../04-사이드바-카테고리-UI/01-Folder%20Category%20모델%20+%20더미%20데이터.md)
- 단계 02 완료 — `DayCell.id` 가 자연키 (date)

## 동기 — 왜 지금 도입하나

단계 02 의 id 안정화로 시각 버그는 사라졌지만, 구조적으로 남는 문제:

- `MonthlyCalendarView.init()` 이 body 재평가마다 실행됨 → `makeDayCells(for:)` 매번 호출
- 지금은 42개 셀 생성 + Calendar API 콜 정도 — 미미하지만,
- 앞으로 추가될 것들 (이벤트 fetch, 공휴일, 알람 매칭, 미리 알림 sync …) 도 같은 위치에 두면 토글마다 다 재실행 → 부하 누적

근본 해법: **View struct 는 "현재 상태를 어떻게 그릴지" 만, 상태 자체는 View 밖의 객체** 로.

## Swift / SwiftUI 개념

### 1) View struct 가 매번 재생성되는 이유

SwiftUI 의 View 는 **값 타입 (struct)**. body 가 재평가될 때마다 자식 View 들도 새 struct 로 만들어지고 (자식의 init 실행), SwiftUI 가 이전 트리와 diff 해서 실제 화면 업데이트는 차이만 반영한다.

이 모델의 장점:
- "이 상태를 이렇게 그린다" 의 선언적 단순함
- struct 는 값 타입이라 의도치 않은 mutation 공유 없음

대신 init 안 작업은 매번 반복 — 따라서 init 에는 **가벼운 wiring 만** 두는 게 컨벤션.

> Vue 비유: setup() 함수가 매 props 변화마다 재호출되는 게 아니라 인스턴스 단위로 한 번이지만 — SwiftUI 의 struct re-init 은 React 함수 컴포넌트의 매 렌더 호출에 더 가까움. JSX 안에서 `new ExpensiveClass()` 하면 안 되는 직관과 같다.

### 2) `class` (참조 타입) — 다시 짚기

상태를 View 밖에 두려면 **수명이 view 의 재생성과 무관** 한 그릇이 필요하다. struct 는 매번 새로 만들어지므로 부적합. **class** 가 필요한 시점.

```swift
final class CalendarStore { ... }
```

- `class` 는 참조 타입 — 변수에 할당하면 같은 인스턴스를 가리킴 (Java/JS 의 객체와 같음)
- `final` — 상속 막음 (성능 + 의도 명확)

### 3) `ObservableObject` + `@Published`

상태를 들고 있어도 view 가 "변경되었다" 를 알아채야 화면이 갱신된다. 그 매개체가 `ObservableObject`:

```swift
import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var rows: [[DayCell]] = []
    
    init(referenceDate: Date = Date()) {
        let cells = makeDayCells(for: referenceDate)
        self.rows = stride(from: 0, to: cells.count, by: 7).map { start in
            Array(cells[start..<start + 7])
        }
    }
}
```

- **`ObservableObject`**: "내가 바뀌면 알릴게" 프로토콜 (Combine 의 일부).
- **`@Published`**: 그 프로퍼티가 바뀌면 자동으로 변경 알림 emit. 구독한 view 가 body 재평가.
- **`private(set)`**: 외부에서 읽기만, 쓰기는 내부 메서드로만 (캡슐화).

> Spring 비유: `ObservableObject` 는 `@Service` 빈. `@Published` 는 그 빈이 발행하는 이벤트 (또는 Spring 의 `@EventListener` 메커니즘). 차이는 SwiftUI 가 emit → subscribe 의 wiring 을 자동으로 해준다는 점.
> Vue 비유: `reactive({ rows: ... })` + 컴포넌트의 자동 구독을 SwiftUI 가 ObservableObject + @Published 로 표현한 것.

### 4) `@StateObject` — view 가 store 를 "소유" 하기

view 가 store 를 들고 있는 방식이 두 개 있다:

```swift
@StateObject private var store = CalendarStore()    // (a) 이 view 가 store 의 주인
@ObservedObject var store: CalendarStore            // (b) 외부에서 만든 store 를 받아 사용
```

**`@StateObject`**:
- view 의 **수명 동안 정확히 1번** init 실행. body 재평가 무관.
- 그 view 가 store 의 주인 — view 가 사라질 때 store 도 해제.
- SwiftUI 가 storage 를 별도로 관리해 struct 재생성에 영향받지 않음.

**`@ObservedObject`**:
- view 가 store 를 만들지 않고 **외부에서 받음**. 만든 쪽이 수명 책임.
- 매 body 재평가마다 받은 인스턴스를 다시 wiring (인스턴스 자체가 같으면 OK).

> 본 단계에선 MonthlyCalendarView 가 자기 store 를 가지면 되므로 `@StateObject`.

### 5) `@MainActor`

`CalendarStore` 의 상태는 UI 가 직접 읽는다 → 메인 스레드에서만 접근해야 한다 (UIKit/AppKit/SwiftUI 의 thread 규칙).

```swift
@MainActor
final class CalendarStore: ObservableObject { ... }
```

- `@MainActor` 가 붙은 타입의 모든 메서드/프로퍼티 접근은 컴파일러가 **main thread 인지 강제 검사**.
- async 코드 (이벤트 fetch 등) 를 store 안에 두더라도, 이 어노테이션이 thread 안전성을 컴파일 타임에 보장.

> Java 비유: Swing 의 EDT (Event Dispatch Thread). Swing 엔 강제 검사가 없어서 런타임 에러나 race condition 으로 드러나지만, Swift 의 `@MainActor` 는 컴파일러가 잡아준다.

### 6) View ↔ Store 책임 분리 정리

| | View struct | Store class |
|---|---|---|
| 수명 | body 재평가마다 재생성 | view 수명 동안 1개 |
| 역할 | "현재 상태를 어떻게 그릴지" | 상태 보유 + 변경 메서드 |
| 무거운 일 | 안 함 | 여기에 둠 (fetch, 계산) |
| Swift 분류 | struct (값) | class (참조) |
| SwiftUI 와의 연결 | `body` | `ObservableObject` + `@Published` |

## 구현 가이드

### 1) 새 파일 `CalendarStore.swift`

위치: `JHCalendar/Features/MonthlyCalendar/CalendarStore.swift`

> `MonthlyCalendar` 는 sync group 으로 등록된 폴더이므로 파일을 두면 자동 인식 — pbxproj 편집 불필요. (CLAUDE.md 참고)

구조 골격:
```swift
import Foundation

@MainActor
final class CalendarStore: ObservableObject {
    @Published private(set) var rows: [[DayCell]] = []
    
    init(referenceDate: Date = Date()) {
        // TODO: makeDayCells 호출, stride 로 7개씩 묶어 rows 채우기
    }
    
    // 나중에 추가될 메서드 자리:
    // func goNextMonth() { ... }
    // func loadEvents() async { ... }
}
```

체크포인트:
- `import Foundation` 만으로 충분한가? (`@Published` 의 정체는 Combine 이지만 SwiftUI 환경에선 Foundation 만으로 컴파일 통과하는 게 보통. 안 되면 `import Combine` 추가.)
- `@MainActor` 가 붙어 있나?
- `final` 이 붙어 있나?
- `rows` 가 `@Published private(set)` 인가?

### 2) `MonthlyCalendarView.swift` 갈아끼우기

기존:
```swift
private let referenceDate = Date()
private let rows: [[DayCell]]

init() {
    let cells = makeDayCells(for: Date())
    self.rows = stride(from: 0, to: cells.count, by: 7).map { ... }
}
```

목표 골격:
```swift
@StateObject private var store = CalendarStore()

// body 안: 기존 `rows` 를 읽던 자리를 `store.rows` 로
```

체크포인트:
- `@StateObject` 인가? (`@ObservedObject` 면 매 body 재평가마다 새 store 가 생길 위험. 단 `=` 우변이 default 인스턴스 1개로 묶여있으니 실제론 안 그렇지만, **수명 책임의 명확성** 차원에서 StateObject 가 올바름.)
- 기존 `init()` / `referenceDate` / `rows` 프로퍼티는 제거됐나?
- body 안의 `ForEach(rows, ...)` 가 `ForEach(store.rows, ...)` 로 바뀌었나?

### 3) 검증 — init 1회 보장

`CalendarMath.swift` 의 `makeDayCells` 안에 이미 `print` 가 여러 개 있다 (기능 05 의 디버그 출력). 그걸 활용:

- 앱 실행 시 `print` 가 한 번만 찍히는지 확인.
- 사이드바 토글 시 `print` 가 추가로 찍히지 않으면 OK.
- 만약 토글마다 찍힌다면 `@StateObject` 가 아니라 `@ObservedObject` 로 잘못 썼거나, 다른 곳에서 store 를 또 만들고 있는 것.

> 검증 후 `print` 들은 정리하든 그대로 두든 자유 — 다음 기능에서 거슬리면 그때 정리.

## 직접 구현하기
- [x] `CalendarStore.swift` 새 파일 (`@MainActor` + `final` + `ObservableObject` + `@Published private(set) var rows`)
- [x] init 에서 `makeDayCells` 호출 후 `rows` 채우기
- [x] `MonthlyCalendarView` 의 init / referenceDate / rows 프로퍼티 제거
- [x] `@StateObject private var store = CalendarStore()` 추가
- [x] body 안 ForEach 의 데이터 소스를 `store.rows` 로 변경
- [x] 빌드 통과 (⌘B)
- [x] 앱 실행 시 `makeDayCells` 의 `print` 가 1회만 출력
- [x] 사이드바 토글 → 일 그리드 그대로, 페이드 없음, `print` 추가 출력 없음

> 추가 작업: 1차 리뷰에서 `CalendarStore.init` 이 파라미터 `referenceDate` 를 무시하고 `Date()` 를 직접 호출하던 버그 + `MonthlyCalendarView` 에 `referenceDate` 프로퍼티가 잔존하는 문제 발견 → store 에 `let referenceDate: Date` 를 추가하고 view 가 `store.referenceDate` 를 읽도록 통합. "기준 시점" 의 single source of truth 가 store 로 일원화됨.

## 자가 점검
- 자문자답: `@StateObject` 와 `@ObservedObject` 의 차이?
  > StateObject 는 view 가 주인 / 1회 init / view 수명 동안 storage 보장. ObservedObject 는 외부에서 받음 / 매 재평가마다 wiring.
- 자문자답: `@Published` 가 없으면 어떻게 되나?
  > 상태가 바뀌어도 view 가 알지 못해 화면이 갱신 안 됨.
- 자문자답: `@MainActor` 없이도 동작은 하나?
  > 동기 코드 + 메인 스레드에서만 접근하면 동작은 함. 하지만 async 코드를 넣기 시작하면 안전성 보장이 깨짐 — 미리 붙여두는 게 안전.
- 자문자답: 왜 store 는 class 인데 SwiftUI 가 받아들이나?
  > SwiftUI 는 View 만 struct 강제. 상태 보유체는 보통 class — 그게 ObservableObject 의 디자인 의도. View 의 diff 모델과 별개 트랙.

## Claude 리뷰 체크리스트
- [x] `CalendarStore.swift` 가 `@MainActor final class` + `ObservableObject` 채택
- [x] `rows` 가 `@Published private(set)`
- [x] `MonthlyCalendarView` 에 `@StateObject` 사용 (ObservedObject 아님)
- [x] init 안에서 `makeDayCells` 단 1회 호출 보장 (`print` 로 확인)
- [x] body 가 `store.rows` 를 읽음

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **Observation 매크로 (`@Observable`, macOS 14+)** — `ObservableObject` 의 차세대. `@Published` 없이 자동 추적. 본 단계에선 더 기초적인 `ObservableObject` 로 익혔지만, 새 코드는 `@Observable` 을 더 권장하는 추세.
- **Dependency injection** — store 를 `@EnvironmentObject` 로 트리 위쪽에서 한 번 만들고 자식들이 자동 주입받기. 본 앱이 자라면 `CalendarStore` 를 App 레벨로 끌어올릴 만함.
- **`@Published` 의 emit 시점** — `willSet` 직후. UI 갱신은 그 다음 runloop tick. 종종 미묘한 ordering 이슈의 원인이 되므로 알아둘 만.
- **Combine** — `@Published` 의 underlying. 더 깊은 reactive 사용 (다른 publisher 와 combine, debounce, …) 이 필요해지면 들어감.
