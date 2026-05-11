# 단계 3: 날짜 그리드 — LazyVGrid + 셀 + 회색 구분선

## 학습 목표
- **`LazyVGrid` + `GridItem`** 으로 7열 2차원 그리드를 만든다. 행 수는 데이터(28/35/42) 에 따라 자동.
- 한 칸을 **`DayCellView`** 라는 별도 view 로 분리한다. (04 의 `CategoryRow` 분리와 같은 패턴.)
- 셀 경계에 **흐린 회색 구분선** 을 그린다 — `overlay` 로 사각 테두리를 그리는 가장 단순한 방법부터.

## 사전 지식
- 단계 01: `DayCell` 모델 + `makeDayCells(for:)` 함수
- 단계 02: `MonthlyCalendarView` 에 년월 / 요일 헤더가 이미 자리잡고 있음
- 컴포넌트 분리 / `ForEach` 사용 ([04-3](../04-사이드바-카테고리-UI/03-체크박스%20토글%20+%20Row%20분리%20+%20Binding.md))
- `frame(maxWidth: .infinity)` 균등 분할 ([단계 02](02-년월%20헤더%20+%20요일%20헤더.md))

## Swift / SwiftUI 개념

### 1) `LazyVGrid` — 새 개념
- **세로 방향으로 자라는 2차원 그리드**. (`HGrid` 도 존재.)
- **컬럼 정의 배열 (`[GridItem]`) 만 정해주면** 자식 view 들을 1차원 흐름으로 받아 자동 줄바꿈.
- "Lazy" — 화면에 보이는 부분만 그린다 (성능).

```swift
let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 0),
                                count: 7)

LazyVGrid(columns: columns, spacing: 0) {
    ForEach(cells) { cell in
        DayCellView(cell: cell)
    }
}
```

### 2) `GridItem` — 컬럼 정의
세 가지 사이즈 모드가 핵심:
- `.flexible(minimum:maximum:)` — 남는 공간을 균등하게 나눠 가짐. 이번에 쓸 것.
- `.fixed(_:)` — 고정 폭.
- `.adaptive(minimum:)` — 폭이 허락하는 만큼 칸을 더 만든다 (사진 그리드 같은 거).

> 일곱 컬럼 모두 동일하게 늘어나야 하므로 `.flexible()` 7개 반복.

### 3) `overlay` — 새 개념
- 어떤 view 위에 다른 view 를 **같은 크기로** 얹는다. 보통 **테두리 / 배지 / 그라데이션** 을 그릴 때 쓴다.
- 셀 사각 테두리는 `Rectangle().stroke(...)` 를 overlay 로 얹는 게 가장 단순.

```swift
DayCellView(cell: cell)
    .overlay(
        Rectangle()
            .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
    )
```

### 4) `border` 와의 차이
- `.border(Color, width:)` 는 한 줄짜리 단축 표현 — 거의 같은 결과를 낸다.
  ```swift
  .border(Color.gray.opacity(0.2), width: 0.5)
  ```
- `overlay(Rectangle().stroke(...))` 는 더 유연 (둥근 모서리, 그라데이션 stroke 등). 이번에는 어느 쪽을 써도 무방.

### 5) 셀 안의 "위쪽 가운데 정렬"
- `VStack(alignment: .center)` 안에 `Text("\(cell.day)")` + `Spacer()` 패턴.
- 또는 `Text` 한 줄을 `frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)` 로 셀 전체 영역에 깔고 위쪽 정렬.

```swift
VStack {
    Text("\(cell.day)")
        .font(.caption)
    Spacer()
}
.frame(maxWidth: .infinity, maxHeight: .infinity)
.padding(.top, 6)
```

### 6) 이번 달 외 날짜의 흐림 처리
- `cell.isInCurrentMonth == false` 이면 글자색을 더 흐리게.
- `.foregroundStyle(cell.isInCurrentMonth ? .primary : .tertiary)` 같은 식.

## 구현 가이드

### 새 파일
`JHCalendar/Features/MonthlyCalendar/DayCellView.swift`

```swift
import SwiftUI

struct DayCellView: View {
    let cell: DayCell

    var body: some View {
        VStack(spacing: 0) {
            Text("\(cell.day)")
                .font(.caption)
                .foregroundStyle(cell.isInCurrentMonth ? .primary : .tertiary)
                // TODO: 폰트/패딩 디테일은 시각 맞춰가며 조정

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 6)
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
}
```

### `MonthlyCalendarView` 수정
- 단계 02 에서 자리 잡아둔 `Spacer()` 자리에 `LazyVGrid` 가 들어간다.
- `makeDayCells(for: referenceDate)` 결과를 한 번만 계산해 `let cells = …` 으로.

```swift
struct MonthlyCalendarView: View {
    private let referenceDate = Date()
    private let cells: [DayCell]

    init() {
        self.cells = makeDayCells(for: Date())
    }

    private static let yearMonthFormatter: DateFormatter = { /* 단계 02 */ }()
    private let weekdayLabels = ["일", "월", "화", "수", "목", "금", "토"]

    private let columns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 0),
        count: 7
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Self.yearMonthFormatter.string(from: referenceDate))
                .font(.title2)

            HStack(spacing: 0) {
                ForEach(weekdayLabels, id: \.self) { label in
                    Text(label)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.secondary)
                }
            }

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(cells) { cell in
                    DayCellView(cell: cell)
                }
            }
        }
        .padding()
    }
}
```

### 셀 높이가 너무 작게 나올 때
- `LazyVGrid` 자체는 자식이 요청하는 만큼만 높이를 잡는다 (`Text` 한 줄 분량).
- 화면 전체를 채우려면 `DayCellView` 에 **최소 높이** 를 주거나, 그리드를 `frame(maxHeight: .infinity)` 로 늘리고 셀이 그걸 균등 분할하게 한다.
- 간단한 방법: 셀에 `.frame(minHeight: 80)` 같은 기준값. 정확한 수치는 시각적으로 맞추기.

```swift
.frame(maxWidth: .infinity, minHeight: 80, maxHeight: .infinity, alignment: .top)
```

### Xcode 프로젝트 등록
- `DayCellView.swift` 를 pbxproj 의 4 곳에 추가 (단계 01 에서 한 것과 동일 패턴).

## 직접 구현하기
- [ ] `DayCellView.swift` 신설 — 숫자만 위쪽 가운데 + overlay 회색 테두리
- [ ] `MonthlyCalendarView` 에 `LazyVGrid(columns:)` 적용
- [ ] `cells = makeDayCells(for: referenceDate)` 연결
- [ ] 이번 달 외 날짜는 `.tertiary` 등으로 흐리게
- [ ] 셀 높이 조정 — 시각적으로 이미지와 비슷하게
- [ ] `project.pbxproj` 등록
- [ ] 빌드 + 실행 → 4~6주 가변 그리드가 정확히 나오는지 확인

## 자가 점검 (구현 후)
- 그리드가 정확히 **7열** 인가?
- 행 수가 그 달에 맞게 자동으로 **4 / 5 / 6** 중 하나로 나오는가? (예: 2026년 5월은 6행)
- 1일이 그 달의 진짜 요일 칸에 들어가는가? (오늘 달력 앱과 비교)
- 이번 달 외 날짜 (앞뒤 회색칸) 도 정확한 day 숫자로 표시되는가?
- 창 크기를 늘리면 셀이 균등하게 함께 늘어나는가?

### 이해도 퀴즈
1. `LazyVGrid` 와 `Grid` (iOS 16+) 의 차이는? 왜 이번엔 `LazyVGrid` 가 적합한가?
2. `GridItem(.flexible())` 7개를 `GridItem(.fixed(100))` 7개로 바꾸면 어떻게 동작이 달라질까?

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `columns` 가 `.flexible()` 7개로 정의됨
- [ ] `DayCellView` 가 별도 파일/타입으로 분리되었는가
- [ ] 셀 내부 정렬: 숫자가 **위쪽 가운데** 인가
- [ ] 이번 달 외 날짜의 흐림 처리가 들어갔는가
- [ ] 셀 경계가 **흐린 회색** (너무 진하지 않게) 인가
- [ ] `pbxproj` 4 곳 모두 갱신되어 빌드가 깨지지 않는가
- [ ] 사이드바 토글 / 창 리사이즈 시 레이아웃이 깨지지 않는가

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(사용자가 단계 진행 후 직접 채우는 영역)*

## 조금 더 (선택)
- 인접 셀끼리 테두리가 **이중으로 겹치는 현상** — `overlay(Rectangle().stroke())` 의 단점. 해결책: 셀에는 top/leading 두 변만 그리고, 그리드 자체에 trailing/bottom 마무리. 또는 단일 `Path` 로 한 번에 그리기.
- macOS 13+ 의 `Grid` (Lazy 가 아닌) — 행/열을 명시적으로 짜는 신형 그리드. 셀 정렬에 더 강력.
- 셀 클릭 / 오늘 강조 / 월 이동 → 후속 기능에서.
