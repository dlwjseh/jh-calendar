# 단계 7: BorderlessTimePicker ↔ startDate 양방향 바인딩

> 지금 `BorderlessTimePicker` 는 내부 `@State` 로 시/분/오전오후를 따로 들고 있어 `AddEventDialog` 의 `startDate` 와 **완전히 단절** 돼 있다(장식 상태).
> 이 단계에서 **`@Binding<Date>` 로 연결** 해, 타임피커가 `startDate` 의 "시각" 부분을 읽고/쓰게 만든다. ("날짜" 부분은 기존 popover `DatePicker` 가 계속 담당 — 같은 `Date` 하나를 둘이 나눠 만짐.)

## 학습 목표
이 단계를 마치면:
- 내부 `@State` 로 자기 상태를 들던 컴포넌트를 **`@Binding` 으로 외부 상태에 종속(controlled)** 시키는 리팩터링을 할 수 있다.
- `Calendar` / `DateComponents` 로 **`Date` ↔ (시, 분)** 를 분해·재조립할 수 있다.
- **12시제 ↔ 24시제 변환** 의 함정(특히 12 AM=0시, 12 PM=12시)을 정확히 처리할 수 있다.
- 결과물: `BorderlessTimePicker(date: $startDate)`. 숫자/↑↓ 로 바꾼 시각이 `startDate` 에 즉시 반영되고, 반대로 `startDate` 가 바뀌면 표시도 따라온다.

## 사전 지식
- 06 산출물: `BorderlessTimePicker` — 내부 `@State hour/minute/meridiem` + `.onKeyPress` 클램프 버퍼 + `.onMoveCommand` 토글
- `AddEventDialog`:
  - `@State private var startDate = Date()` (line 14)
  - 날짜 popover `DatePicker(selection: $startDate, displayedComponents: .date)` — **년/월/일만** 편집
  - `BorderlessTimePicker()` 인자 없이 호출 (line 114) → 이번에 `(date: $startDate)` 로 바꿈
- `@Binding` / projected value `$` → 이미 다룸, **재설명 X**, 링크만: [03/01-state 끌어올리기와 @Binding.md](../03-사이드바-슬라이드/01-state%20끌어올리기와%20@Binding.md)
- `.onKeyPress` 버퍼·`@FocusState`·`.onMoveCommand` → [05](./05-시%20숫자입력.md)/[04](./04-시간입력%20오전오후%20토글.md) (그대로 활용)

## Swift / SwiftUI 개념 (이 단계에서 **새로** 배우는 것만)

### 1) "uncontrolled → controlled" 컴포넌트 — `@Binding` 적용 관점

`@Binding` 문법 자체는 03 에서 배웠다. **새로운 건 "이미 내부 `@State` 로 동작하던 컴포넌트의 진실원본(source of truth)을 바깥으로 옮기는" 리팩터링 관점.**

- 지금: `BorderlessTimePicker` 가 `@State hour` 등을 **소유** → 바깥은 그 값을 모름 (uncontrolled).
- 목표: `@Binding var date: Date` 를 받아 **표시값을 `date` 에서 파생**, 사용자가 바꾸면 **`date` 에 되써넣음** (controlled).

> **Vue 비유** (네 경험 기준): `v-model` 그 자체다. 자식이 내부 `data()` 로 들고 있던 걸, `props` + `emit('update:modelValue')` 로 부모 상태에 양방향 묶는 것. SwiftUI `@Binding` 은 그 get/set 쌍을 한 타입으로 합친 것.
> **React 비유는 안 함** (네 스택 아님). 굳이 한 줄: "controlled input" 개념과 동일.

### 2) `Calendar` / `DateComponents` — `Date` 분해·재조립

`Date` 는 "시각의 한 점"(타임스탬프)일 뿐, "9시 30분" 같은 사람이 읽는 필드는 **`Calendar` 를 거쳐** 꺼낸다.

```swift
let cal = Calendar.current

// 분해: Date → 시(0~23), 분
let comp = cal.dateComponents([.hour, .minute], from: date)
let hour24 = comp.hour ?? 0
let minute = comp.minute ?? 0

// 재조립: 기존 날짜(년·월·일)는 두고 시·분만 교체
var newComp = cal.dateComponents([.year, .month, .day], from: date)
newComp.hour = /* 24시제 시 */
newComp.minute = /* 분 */
let newDate = cal.date(from: newComp)   // Date?
```

> **Java 비유** (네 메인 스택): `java.time.LocalDateTime` 의 `getHour()` / `getMinute()` 로 꺼내고 `withHour(h).withMinute(m)` 로 새 인스턴스 만드는 것과 똑같은 결. `Date` ≈ `Instant`(타임스탬프), `Calendar`+`DateComponents` ≈ `LocalDateTime` 분해/조립 + 타임존 규칙. 핵심 공통점: **원본을 바꾸는 게 아니라 새 값을 만들어 대입** (불변).

### 3) 12시제 ↔ 24시제 변환 — 함정은 "12"

`Calendar` 가 주는 `hour` 는 **0~23**. 화면 표시는 **1~12 + 오전/오후**. 변환표 (이거 그대로):

**24h → (표시 시, 오전/오후)**

| hour24 | 표시 | 오전/오후 |
|---|---|---|
| 0 | 12 | 오전 |
| 1~11 | 그대로 | 오전 |
| 12 | 12 | 오후 |
| 13~23 | −12 | 오후 |

**(표시 시, 오전/오후) → 24h**

| 입력 | hour24 |
|---|---|
| 오전 12 | 0 |
| 오전 1~11 | 그대로 |
| 오후 12 | 12 |
| 오후 1~11 | +12 |

> 함정: "오전 12 = 0시(자정)", "오후 12 = 12시(정오)". `+12` 를 무지성으로 하면 오전 12 가 12시가 돼 버린다. 위 표의 12 행을 **특수 케이스로 먼저** 처리할 것.

## 구현 가이드
> 정답 풀코드는 제공하지 않는다. 시그니처·변환표·골격·힌트만.

### 파일 변경 계획
- `BorderlessTimePicker.swift`:
  - `@State private var hour/minute/meridiem` **제거**, 대신 `@Binding private var date: Date` 하나.
  - 표시값은 `date` 에서 파생되는 **computed property** 로: `displayHour: Int`, `displayMinute: Int`, `displayMeridiem: Meridiem`.
  - 값 변경(숫자 입력 / ↑↓ 토글)은 전부 **새 시각을 만들어 `date` 에 대입** 하는 한 곳(예: `private func commit(hour12:minute:meridiem:)`)을 거치게.
  - `@FocusState` (시/분/오전오후 포커스)는 **그대로 내부 유지** — 이건 UI 포커스라 바깥과 무관.
- `AddEventDialog.swift` line 114: `BorderlessTimePicker()` → `BorderlessTimePicker(date: $startDate)`

### 골격 스니펫
```swift
struct BorderlessTimePicker: View {
    @Binding var date: Date
    @FocusState private var isHourFocused: Bool
    @FocusState private var isMinuteFocused: Bool
    @FocusState private var isMeridiemFocused: Bool

    private let cal = Calendar.current

    private var displayHour: Int {
        // TODO: cal.dateComponents([.hour], from: date).hour → 24h → 12h 표시값
    }
    private var displayMinute: Int { /* TODO */ }
    private var displayMeridiem: Meridiem { /* TODO: hour24 기준 오전/오후 */ }

    /// 12시제 입력을 24h 로 환산해 date 에 되써넣는 단일 통로
    private func commit(hour12: Int, minute: Int, meridiem: Meridiem) {
        // TODO: 변환표(표시→24h) 적용 → 기존 년/월/일 유지하고 hour/minute 교체 → cal.date(from:) → date = ...
    }

    var body: some View {
        HStack(spacing: 0) {
            // 오전/오후: displayMeridiem 표시, onMoveCommand 에서 commit(... 토글한 meridiem ...)
            // 시: String(format:"%02d", displayHour), onKeyPress 클램프 후 commit(...)
            // ":" 그대로
            // 분: String(format:"%02d", displayMinute), onKeyPress 클램프 후 commit(...)
        }
    }
}
```

### 입력 규칙은 그대로, "어디에 쓰느냐"만 바뀐다
- 시 클램프(`candidate<=12?candidate:d`, 0이면 오전/오후 토글+12), 분 클램프(`<60`) 로직은 **05/06 과 동일**.
- 달라지는 것: 결과를 `@State` 에 직접 넣는 대신 **`commit(...)` 으로 보내 `date` 갱신**. "0이면 meridiem 토글" 도 `commit` 에 넘기는 meridiem 을 뒤집어 전달하면 됨.

### 막힐 만한 지점 — 힌트
- **`@Binding` 인데 미리보기/단독 사용이 깨짐** — `#Preview` 에서는 `@Previewable @State var d = Date()` 후 `BorderlessTimePicker(date: $d)`. 그냥 `.constant(Date())` 는 변경이 안 보이니 디버깅엔 부적합.
- **오전 12 가 12시로 튐** — 12/24 변환표의 "12" 행을 `+12` 일반식보다 **먼저** 분기. (오전 12→0, 오후 12→12)
- **시·분 바꿨더니 날짜(년/월/일)가 사라지거나 튐** — 재조립 시 `dateComponents([.year,.month,.day], from: date)` 로 **기존 날짜를 먼저 복사** 한 뒤 hour/minute 만 덮어야 함. 빈 `DateComponents()` 에 hour/minute 만 넣으면 0001년 같은 게 나옴.
- **`cal.date(from:)` 가 `Date?`** — 옵셔널. 실패 시(보통 안 남) 기존 `date` 유지하도록 `if let`.
- **무한 루프/버벅임 우려** — computed 파생이라 따로 동기화 코드 필요 없음. `date` 가 단일 진실원본.
- **저장은 이 단계 범위 아님** — `Event` 에 날짜 필드 없음 + `isSaveEnabled` 가 `false` 하드코딩(line 32). 그래서 "저장 후 확인" 이 아니라 **다이얼로그 안에서** 검증한다(아래 자가 점검). 영속화는 08 단계.

## 직접 구현하기
- [ ] `BorderlessTimePicker`: `@State hour/minute/meridiem` 제거 → `@Binding var date: Date`
- [ ] `displayHour` / `displayMinute` / `displayMeridiem` computed (24h→12h 변환표 적용)
- [ ] `commit(hour12:minute:meridiem:)` — 12h→24h, 년월일 유지, `date` 대입 (단일 통로)
- [ ] 시 `.onKeyPress` 클램프 → `commit(...)` 경유 (0이면 meridiem 뒤집어 전달)
- [ ] 분 `.onKeyPress` 클램프(<60) → `commit(...)` 경유
- [ ] 오전/오후 `.onMoveCommand` 토글 → `commit(...)` 경유
- [ ] `AddEventDialog` line 114 → `BorderlessTimePicker(date: $startDate)`
- [ ] `#Preview` 를 `@Previewable @State` 로 갱신
- [ ] 빌드 통과

> 다 되면 "다 했어" 라고 알리면 리뷰할게.

## 자가 점검
- 빌드 OK? (⌘B)
- (임시) `AddEventDialog` 에 `Text("\(startDate)")` 한 줄 잠깐 띄워두고 확인 (확인 후 제거):
  - 타임피커에서 시/분 바꾸면 `startDate` 의 시각이 따라 바뀌는가?
  - **날짜 popover 로 다른 날 선택해도 타임피커의 시·분은 유지** 되는가? (년월일/시분 분리 검증)
  - 오전 12 입력 → `startDate` 가 00:xx (자정) 인가? 오후 12 → 12:xx (정오) 인가?
- 이해도 퀴즈
  1. `Date` 에서 바로 `.hour` 를 못 꺼내고 `Calendar` 를 거치는 이유는? (타임존/달력 규칙 한 줄, Java `Instant` vs `LocalDateTime` 비유)
  2. controlled 로 바꾼 뒤 내부에 `@State hour` 가 남아 있으면 왜 문제인가? (진실원본 이중화)
  3. 오전 12 를 `+12` 로 처리하면 무슨 시각이 되나? 왜 틀렸나?

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] 내부 시/분/오전오후 `@State` 제거, `@Binding var date: Date` 단일 진실원본 (이중 상태 없음)
- [ ] 표시값은 `date` 파생 computed, 변경은 `commit` 단일 통로로 `date` 갱신
- [ ] 12/24 변환 정확 — 특히 오전 12=0시, 오후 12=12시 특수 케이스
- [ ] 재조립 시 기존 년/월/일 보존 (`dateComponents([.year,.month,.day]...)` 복사 후 시·분 교체)
- [ ] 05/06 클램프 규칙 그대로, "어디에 쓰는지"만 commit 경유로 변경
- [ ] `AddEventDialog` 호출부 `(date: $startDate)`, `#Preview` `@Previewable @State`
- [ ] `@Binding` 등 03/04/05 개념 재설명 없이 활용만 (dedup 원칙)
- [ ] 빌드 통과

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(사용자가 단계 진행 후 직접 채우는 영역)*

## 조금 더 (선택) — 다음 단계 예고 (08)
- **`Event` 영속화**: `Event` `@Model` 에 `startDate: Date` 추가(SwiftData 스키마 변경 — 09 에서 다룬 패턴), `.add`/`.edit` 저장 로직에 `startDate` 반영, `isSaveEnabled` 를 실제 조건(카테고리·이름 등)으로 정상화. 그래야 타임피커가 진짜로 "저장" 까지 이어짐.
- **칸 ←/→ 이동**: `@FocusState` Bool 3개 → `@FocusState var focused: Field?` enum 바인딩 리팩터링.
