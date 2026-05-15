# 단계 3: AddEventDialog 통합 + 날짜·시간 공용화

> 이 단계는 **새로 배울 Swift/SwiftUI 문법이 없다.** 01·02 에서 만든 `BorderlessTimePicker` 와 이미 익힌 `@Binding`·컴포넌트 추출을 **조합·정리**하는 작업 단계다. 그래서 "Swift / SwiftUI 개념" 섹션은 생략하고 **작업 가이드** 만 둔다. (CLAUDE.md 학습포인트 작성 원칙 3)

## 작업 목표
- 01·02 의 `BorderlessTimePicker` 를 `AddEventDialog` "시작" 행에 정식 통합하고, 10 단계에서 어긋났던 **날짜 ↔ 시간 세로 정렬**을 맞춘다.
- `NSDatePicker` 는 `datePickerElements` 만 바꾸면 날짜용으로도 쓸 수 있다 → **날짜·시간 공용 컴포넌트**로 일반화해, "시작"과 (이후) "종료" 행이 복붙 없이 재사용되게 한다.

## 사전 지식
- 01·02 산출물 — `BorderlessTimePicker` 양방향 동작
- 10 산출물 — `AddEventDialog` 의 "시작" 행 구조(라벨 `Text` + 날짜 Button/popover + 시간 입력)
- 컴포넌트 추출 패턴은 이미 함 — `CategoryChip` ([JHCalendar/Features/Event/CategoryChip.swift](../../JHCalendar/Features/Event/CategoryChip.swift)) 와 같은 결

## 작업 가이드
> 정답 풀코드는 제공하지 않는다.

### A. 정렬 정리 (필수)
10 단계 어긋남의 원인은 "날짜는 순수 Text, 시간은 chrome 있는 `.field` DatePicker" 라 높이가 달랐던 것. 02 까지 오면 시간이 무테두리가 되므로 다시 점검:

- "시작" 행 `HStack` 의 정렬을 확인 — 기본 `.center`. 날짜 `Text` 와 `BorderlessTimePicker` 의 높이가 비슷해졌는지 본다.
- `BorderlessTimePicker` 에 `.frame(width:)` 만 주고 height 는 자연 크기에 맡긴다. 미세하게 안 맞으면 `HStack(alignment: .firstTextBaseline)` 또는 양쪽 `.font` 통일로 맞춘다.
- 10 에서 지적된 날짜 `Text` 의 `.font` 누락도 이때 같이 정리(날짜·시간 동일 size 명시).

### B. 날짜·시간 공용화 (권장)
`NSDatePicker` 는 `datePickerElements` 값만 다르면 날짜도 시간도 된다. `BorderlessTimePicker` 를 일반화:

- 이름을 의미에 맞게 (예: `BorderlessDatePicker`) 바꾸고, **어떤 요소를 보일지**를 파라미터로 받게 한다.
  ```swift
  struct BorderlessDatePicker: NSViewRepresentable {
      @Binding var date: Date
      let elements: NSDatePicker.ElementFlags   // .yearMonthDay / .hourMinute
      // makeNSView 에서 picker.datePickerElements = elements
  }
  ```
- 호출:
  ```swift
  BorderlessDatePicker(date: $startDate, elements: .yearMonthDayDatePickerElementFlag)  // 날짜
  BorderlessDatePicker(date: $startDate, elements: .hourMinuteDatePickerElementFlag)     // 시간
  ```
- 이러면 10 에서 만든 "날짜는 커스텀 Text + popover" 방식을 이걸로 대체할지 결정 가능. (대체하면 코드가 더 단순해지지만, popover 캘린더 UX 를 유지하고 싶으면 날짜는 그대로 두고 시간만 이 컴포넌트로 둬도 됨 — 선택.)

> 굳이 popover 캘린더를 포기하기 싫다면 B 는 "시간만 무테두리, 날짜는 기존 유지" 로 끝내도 학습 목표는 충족. 공용화는 어디까지나 중복 제거 목적.

### C. (선택) 종일 토글 연동
`isAllDay == true` 면 시간 입력 숨김:
```swift
if !isAllDay {
    BorderlessDatePicker(date: $startDate, elements: .hourMinute...)
}
```
`if` 를 `body` 안에 직접 — Vue `v-if` 와 같은 결(10 에서 이미 다룬 패턴).

## 직접 구현하기
- [ ] `AddEventDialog` "시작" 행에 `BorderlessTimePicker`(또는 일반화한 컴포넌트) 통합
- [ ] 날짜 ↔ 시간 세로 정렬 맞춤, 날짜 `Text` font 명시
- [ ] (권장) `elements` 파라미터화로 날짜·시간 공용 컴포넌트화
- [ ] (선택) `isAllDay` 일 때 시간 입력 숨김
- [ ] 빌드 통과 + 시각 확인
- [ ] 10 단계 README/마스터 인덱스와 충돌 없는지 확인 후 본 README 체크박스 갱신

## 자가 점검
- 시작 행에서 날짜·시간이 **한 줄에 테두리 없이** 가지런히 정렬되나?
- 시간 변경이 `startDate` 에 반영되고, 날짜 변경이 시간을 안 지우나? (같은 `Date`)
- (공용화 시) 같은 컴포넌트가 날짜/시간 둘 다로 동작하나?
- 이해도 퀴즈
  1. 하나의 `BorderlessDatePicker` 가 날짜도 시간도 되는 이유는? (어떤 한 속성?)
  2. 날짜/시간이 같은 `startDate` 를 공유하는데 서로의 값을 안 망치는 이유는? (`NSDatePicker` 가 자기 elements 부분만 건드림)

## Claude 리뷰 체크리스트
- [ ] 시작 행 정렬·폰트 일관
- [ ] `BorderlessTimePicker`/공용 컴포넌트가 AddEventDialog 에 깔끔히 통합 (인라인 `.field` DatePicker 잔재 없음)
- [ ] (공용화 시) 파라미터 설계가 군더더기 없는가 (CategoryChip 수준의 단순 재사용)
- [ ] 종일 토글 연동 시 `if` 위치/동작 적절
- [ ] 빌드 통과 + 실제 화면 확인

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- "종료" 행을 추가하고 시작/종료에 같은 공용 컴포넌트를 재사용 — 종료 < 시작 금지 같은 검증은 어디에 둘지 생각해보기.
- `BorderlessDatePicker` 에 `in: ClosedRange<Date>` 를 받아 `NSDatePicker.minDate/maxDate` 로 매핑 — SwiftUI DatePicker 의 `in:` 을 AppKit 으로 재현.
