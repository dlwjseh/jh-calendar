# 단계 5: 일 팝업 read-only 처리

> 새 Swift/SwiftUI 개념 없음. 기존 패턴 조합 + UX 의사결정.

## 작업 목표
- 일 팝업 (`DayPopupDialog`) 에 그 날의 공휴일을 사용자 이벤트 위에 한 줄로 표시.
- 공휴일 행은 **컨텍스트 메뉴 "삭제" 없음**, **클릭해도 편집 다이얼로그 안 열림** (read-only).
- 시각적으로 사용자 이벤트와 구분되게 (빨강 색 + 작은 "공휴일" 표식).

## 사전 산출물
- [04-달력-표시](04-달력-표시.md) 완료 — 셀에 공휴일 보이는 상태.
- `HolidayStore.byDay` 가 `@EnvironmentObject` 로 접근 가능.

## 디자인 결정

### 표시 위치 — 사용자 이벤트 위? 아래?

| 옵션 | 장점 | 단점 |
|---|---|---|
| A: **공휴일 행이 가장 위** | 그 날의 "기본 컨텍스트" 가 먼저 보임 | 공휴일이 항상 첫 줄을 차지 |
| B: 시간순 정렬에 섞기 | 일관성 | 공휴일은 시간이 없어 정렬 키 모호. 사용자 이벤트와 섞이면 read-only 가 덜 명확. |

→ **A 채택** — 공휴일은 항상 첫 줄.

### 행 디자인

```
[빨강 점] 어린이날                    공휴일
```

- 좌측 점: 사용자 이벤트와 동일 모양 (`Circle().fill(.red)`).
- 이름: 빨강 텍스트.
- 우측 작은 회색 label "공휴일" — read-only 임을 안내.
- 클릭/호버 이벤트 없음 (hover 색상 변화 X). 사용자에게 "이건 누를 수 없음" 을 전달.

### `DayPopupEventRow` 재사용 vs 새 `HolidayRow`

`DayPopupEventRow` 는 `Event` (SwiftData @Model) 를 받음. `Holiday` 는 별 모델. 강제로 한 컴포넌트에 합치는 건 다음 두 가지를 더럽힘:

- `Event?` / `Holiday?` 분기 prop
- 컨텍스트 메뉴 / 호버 / 클릭 분기

→ **별도 `HolidayPopupRow` 신규 작성** 이 깔끔.

## 구현 가이드

### 1) 그 날의 공휴일 조회

`DayPopupDialog.swift`:

```swift
@EnvironmentObject private var holidayStore: HolidayStore

private var holiday: Holiday? {
    holidayStore.byDay[Calendar.current.startOfDay(for: date)]
}
```

### 2) `HolidayPopupRow` 새 파일

`JHCalendar/Features/Holiday/HolidayPopupRow.swift` (또는 `Features/Event/HolidayPopupRow.swift` — 일 팝업 안 행이므로 어디든 OK):

```swift
struct HolidayPopupRow: View {
    let holiday: Holiday
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.red)
                .frame(width: 9, height: 9)
            Text(holiday.name)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("공휴일")
                .foregroundStyle(.secondary)
                .font(.system(size: 10))
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        // hover 색상 X, contextMenu X, onTapGesture X — read-only
    }
}
```

> 참고: 기존 [DayPopupEventRow](../../JHCalendar/Features/Event/DayPopupEventRow.swift) 와 같은 padding/font 결로 정렬. 그래야 같은 팝업 안에서 어색하지 않음.

### 3) `DayPopupDialog` body — 공휴일 행 끼우기

```swift
VStack(spacing: 0) {
    if let holiday {                                  // ← 추가
        HolidayPopupRow(holiday: holiday)
    }
    
    if dayEvents.isEmpty && holiday == nil {
        Text("이날의 일정이 없습니다.")
            .foregroundStyle(.secondary)
            .font(.system(size: 11))
            .padding(.horizontal, 25)
    } else {
        ForEach(dayEvents) { event in
            DayPopupEventRow(event: event, date: date, onClick: onSelectEvent)
        }
    }
}
```

> 함정: 기존 "이날의 일정이 없습니다" 조건이 `dayEvents.isEmpty` 만 보고 있다. 공휴일만 있는 날에도 "일정 없음" 이 같이 뜨면 어색 → `&& holiday == nil` 추가.

### 4) 이벤트 다이얼로그 (편집) 영향

- 사용자가 셀을 탭하면 일 팝업이 열리고, 거기서 사용자 이벤트를 탭하면 편집 다이얼로그가 열린다.
- 공휴일 행은 onTap 자체가 없어 편집 다이얼로그가 안 열림 → **추가 분기 불필요**.
- 새 이벤트 추가 ("+" 버튼) 는 그대로 동작 — 사용자가 공휴일 날에 자기 이벤트를 추가하는 건 OK.

### 5) 빌드 + 시각 확인

- 1/1, 5/5 등 공휴일 날 셀 클릭 → 팝업 첫 줄에 공휴일.
- 공휴일만 있고 사용자 이벤트 없는 날 → 공휴일 한 줄, "일정 없음" 메시지 안 보임.
- 공휴일 + 사용자 이벤트 같이 있는 날 → 공휴일 위, 이벤트 아래.
- 공휴일 행에 마우스 올려도 hover 색상 변화 없음, 클릭 무반응.
- 공휴일 행에 컨텍스트 메뉴 (우클릭) 떠도 메뉴 자체가 없거나 빈 메뉴.

## 직접 구현하기
- [x] `HolidayPopupRow.swift` 신규 작성
- [x] `DayPopupDialog` 에 `@EnvironmentObject var holidayStore` + `holiday` computed
- [x] body 에 `if let holiday { HolidayPopupRow(holiday: holiday) }` 삽입
- [x] 빈 상태 메시지 조건에 `&& holiday == nil` 추가
- [x] 빌드 + 5개 시각 케이스 확인 (위 5번 항목)
- [x] README.md 의 단계 체크리스트 + 마스터 인덱스 상태 갱신

> 구현 메모: 우측 "공휴일" 회색 라벨은 의도적으로 생략(셀과 동일한 토마토색만으로 구분). 색은 `Color.holiday` 상수(`HolidayModels.swift`)로 추출해 셀/팝업 공유.

## 자가 점검
- 빌드 + 실행 OK?
- 공휴일 행이 사용자 이벤트 위에 표시되는가?
- 공휴일 행 클릭 → 아무 일 안 일어나는가?
- 공휴일 행 우클릭 → "삭제" 메뉴 안 뜨는가?
- 공휴일 없는 평일 → 기존 동작 그대로?
- 공휴일만 있는 날 → "일정 없음" 메시지 사라지는가?
- 퀴즈: `HolidayPopupRow` 가 hover/tap 없이 단순하면, `contentShape` / `pointerStyle` 도 빼는 게 자연스럽다 — 왜? — 클릭 가능한 UI 의 시그널을 일부러 안 줘야 read-only 가 시각적으로 명확.

## Claude 리뷰 체크리스트
- [ ] `HolidayPopupRow` 가 onTap / contextMenu / hover 색상 일체 없음
- [ ] 일 팝업의 빈 상태 메시지 조건에 `holiday == nil` 반영
- [ ] 공휴일 행이 기존 `DayPopupEventRow` 와 같은 padding/font 결로 정렬
- [ ] 새 이벤트 추가 ("+") 동작은 그대로 — 공휴일 날에도 사용자 이벤트 추가 가능

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 공휴일 행 옆에 "공휴일" 대신 작은 깃발 아이콘 (`Image(systemName: "flag.fill")`) 도 결이 깔끔.
- 같은 날 여러 공휴일 케이스가 실제로 나타나면 `ForEach` 로 다건 표시. 04에서 처리한 "첫 1건만" 룰을 일관되게 따를 것.
- 공휴일 이름을 시스템 알림 / 메뉴바 / 위젯에 노출하는 후속 작업이 가능 — `HolidayStore` 가 이미 `byDay` 사전이라 그대로 재사용.
