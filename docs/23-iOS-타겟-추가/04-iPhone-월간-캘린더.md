# 단계 4: iPhone 월간 캘린더 표시 (조회 전용)

## 학습 목표
이 단계를 마치면, iPhone 화면에 **월간 그리드(요일 헤더 + 6주 × 7일)** 가 보이고, 각 셀에 **날짜 숫자와 (있다면) 이벤트가 점/줄로 표시**된다. 인터랙션(터치, 다이얼로그) 없음 — **순수 조회**.

## 사전 지식
- 단계 03 완료 (iOS 빈 화면 표시)
- `Shared/Stores/CalendarStore.swift` — `referenceDate`, `monthGrid` (또는 유사) 제공
- `Shared/Logic/CalendarMath.swift` — 월간 6×7 그리드 계산
- `Shared/Logic/EventIndex.swift` — 날짜→이벤트 매핑
- macOS `Views/MonthlyCalendar/` 의 구조 (참고용; 그대로 베끼지 X)

## Swift / SwiftUI 개념

이번엔 **새 SwiftUI 문법은 없다.** (LazyVGrid, GeometryReader, @StateObject, @Query, @EnvironmentObject 모두 macOS 단계에서 이미 사용)

새로 신경 쓸 부분은 **iPhone 화면 크기에 맞게 같은 컴포넌트를 다시 짜는 감각**:
- macOS 는 셀 가로 폭이 100px+ 라 이벤트 제목이 한 줄 들어감 → iPhone 은 한 셀이 ~50px → 이벤트는 **점 또는 막대로 압축**
- macOS 헤더는 큰 폰트 → iPhone 은 작게
- 그리드 간격, 폰트 사이즈 등을 **GeometryReader 로 화면 폭 기반 계산** 하거나 **고정 비율**로

## 작업 가이드

> macOS 의 `Views/MonthlyCalendar` 폴더를 열어 구조만 참고하고, **iOS 용은 새로 작성**. 같은 `CalendarStore`/`CalendarMath`/`EventIndex` 를 쓰므로 데이터 로직은 다시 안 짠다.

### 1. 파일 배치
`JHCalendar-iOS/Views/MonthlyCalendar/` (폴더 신설) 안에:
- `IOSMonthlyCalendarView.swift` — 루트 (헤더 + 그리드)
- `IOSDayCell.swift` — 한 칸 (날짜 숫자 + 이벤트 인디케이터)

> `JHCalendar-iOS/` 폴더 안에서 새 폴더/파일을 만들면 sync group 으로 자동 인식되는지 확인. 안 되면 일반 그룹으로 등록.

### 2. `IOSMonthlyCalendarView` 의 골격
```swift
import SwiftUI
import SwiftData

struct IOSMonthlyCalendarView: View {
    @StateObject private var store = CalendarStore()
    @Query private var events: [Event]
    @EnvironmentObject private var holidayStore: HolidayStore
    @Environment(\.calendarTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // TODO: 월/년 헤더 (예: "2026년 6월")
            // TODO: 요일 헤더 (일~토, 일=theme.sunday, 토=theme.saturday)
            // TODO: 6주 × 7일 그리드 (LazyVGrid columns: 7)
        }
    }
}
```

힌트:
- `store.monthGrid` (또는 macOS 에서 쓰던 이름) 으로 6×7 날짜 배열 받음.
- 각 셀에 넘길 이벤트 = `EventIndex(events).events(on: date)`.
- 이전/다음달 날짜는 `theme.subtleText` 색.

### 3. `IOSDayCell` 의 골격
```swift
struct IOSDayCell: View {
    let date: Date
    let isInCurrentMonth: Bool
    let isToday: Bool
    let events: [Event]
    let holiday: Holiday?
    @Environment(\.calendarTheme) private var theme

    var body: some View {
        VStack(spacing: 2) {
            // 날짜 숫자 (오늘이면 동그라미 배경)
            // 이벤트 인디케이터 — iPhone 은 좁으니 점 2~3개 또는 1줄 막대
        }
        .frame(maxWidth: .infinity, minHeight: 56)
    }
}
```

힌트:
- 날짜 색 결정 순서: **오늘 > 공휴일/일요일 > 토요일 > 평일/이전·다음달**
- 이벤트 인디케이터는 학습 우선 — 처음엔 그냥 **카테고리 색 점 최대 3개** 정도가 간단. 멀티데이 막대(`14-멀티데이`) 까지 가면 복잡하니 이번엔 생략 OK.

### 4. `ContentView` 에 연결
03 단계의 placeholder `Text("월간 캘린더 자리")` 를 `IOSMonthlyCalendarView()` 로 교체.

### 5. 데이터 확인
SwiftData 스토어가 비어 있으니 화면엔 이벤트 없음.
- macOS 에서 만든 데이터는 **iOS 스토어에 없음** (App Sandbox 분리).
- 검증용으로 **임시 시드 데이터**를 넣고 싶다면 `IOSMonthlyCalendarView.onAppear` 에서 `modelContext.insert(Event(...))` 한번. 검증 후 제거.

## 직접 구현하기
- [ ] `JHCalendar-iOS/Views/MonthlyCalendar/` 폴더 신설
- [ ] `IOSMonthlyCalendarView` — 월 헤더 + 요일 헤더 + 6×7 그리드
- [ ] `IOSDayCell` — 날짜 숫자 + (간단한) 이벤트 인디케이터
- [ ] `ContentView` 에서 placeholder → `IOSMonthlyCalendarView()`
- [ ] iPhone 시뮬레이터 실행 → 월간 그리드 보임, 오늘 강조됨
- [ ] (선택) 임시 이벤트 시드 → 점/막대로 표시 확인 후 시드 제거
- [ ] macOS 회귀 없음

> 다 끝나면 알려주면 리뷰.

## 자가 점검 (구현 후)
- 오늘 날짜가 동그라미 배경으로 강조되는가?
- 일요일/토요일 색이 테마대로 다른가?
- 이전·다음달 날짜가 흐릿하게(`theme.subtleText`) 보이는가?
- 셀이 화면 폭에 맞게 균등 분할되는가? (`maxWidth: .infinity`)
- 퀴즈: 같은 `EventIndex` 가 macOS / iOS 양쪽에서 동작하는 이유는? (답: 로직이 `Foundation` 만 의존, UI 프레임워크 무관 → 크로스플랫폼)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `Shared/Logic` / `Shared/Stores` 의 로직을 **그대로 재사용**, 중복 구현 없음
- [ ] iPhone 셀이 좁은 폭에서 깨지지 않음 (텍스트 truncation, frame 계산)
- [ ] 테마 색이 macOS 와 의미적으로 동일하게 적용됨
- [ ] macOS UI 코드 import 없음 (`Views/MonthlyCalendar/*` 참조 X)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **GeometryReader vs 고정 비율**: iPhone 세로 화면 폭은 고정에 가까워 `LazyVGrid` 의 `.flexible()` 만으로 충분. `GeometryReader` 까지 가는 건 가로 회전/iPad 까지 고려할 때.
- **멀티데이 이벤트 막대 (`14` 단계)** 의 iPhone 적응: 좁은 셀에서 가로 막대가 보기 안 좋아 **상단 1줄 막대 + 이벤트 제목 1자 truncation** 정도로 축약하는 방식이 흔함. 다음 기능에서.
