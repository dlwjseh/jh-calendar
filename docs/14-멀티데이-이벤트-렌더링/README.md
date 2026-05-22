# 멀티데이 이벤트 렌더링

## 목표
여러 날을 가로지르는 이벤트를 **셀이 아닌 주(week) 행 위에 연속 바** 로 그린다. 단일 일 이벤트와 한 셀 안에서 충돌 없이 공존하고, 같은 주에 멀티데이가 여러 개 겹치면 세로로 단(lane)을 쌓고, 주 경계를 넘으면 주마다 토막낸다.

표시 규칙:
- **종일 멀티데이**: 카테고리 색으로 채운 바, 안에 이벤트명
- **시간지정 멀티데이**: 같은 바에 작은 `clock` 아이콘 prepend
- **시작/끝 셀**: 좌/우 모서리 둥글기. 중간은 평평 (한 흐름 인상)
- **일 팝업**: 그 날에 걸쳐있는 멀티데이도 목록에 포함 (시간은 시작일에만)

## 의존 관계
- 사전 필요:
  - `05-월간-달력-UI` — `MonthlyCalendarView`, `DayCellView`, `CalendarStore.rows`
  - `11-달력-이벤트-표시` — `eventsByDay`, `DayCellView(events:)`, `+N` 오버플로우
  - `12-일-팝업` — `DayPopupDialog` 동적 `@Query` 패턴
- 이후 영향:
  - 멀티데이 이벤트의 **드래그 이동/리사이즈** (장기 후보)
  - 주(week) 뷰 / 일(day) 뷰 분리 시 같은 행 컨테이너 패턴 재사용

## 단계 체크리스트
- [x] 01 - `eventsByDay` 를 멀티데이까지 확장 (데이터)
- [x] 02 - 주(week) 행 컨테이너로 분리 (리팩토링)
- [x] 03 - `GeometryReader` 로 행 너비 측정 + 주 단위 멀티데이 필터링
- [x] 04 - 행 overlay 로 단색 멀티데이 바 (단일 lane, 한 주 안)
- [x] 05 - 셀에서 멀티데이 그리기 끄기 (분기)
- [x] 06 - 멀티데이 바 안 텍스트 + 시간지정 마커 (시계 → 작은 흰 동그라미)
- [x] 07 - 주 경계 토막 (`DateInterval` 교집합)
- [x] 08 - lane(트랙) 배치 — `assignLanes` 순수 함수
- [x] 09 - 셀 내부 컨텐츠 밀어내기 (셀별 lane 갯수만큼)
- [x] 10 - `+N` 오버플로우 합산
- [x] 11 - 좌/우 끝 모서리 캡
- [x] 12 - 일 팝업에 걸쳐있는 멀티데이 포함

## 이 기능에서 학습할 Swift / SwiftUI 개념

**새로 등장**:
- **`GeometryReader`** — 부모가 자식에게 준 공간을 측정 (행 너비 → 셀 너비 = `width / 7`)
- **`DateInterval.intersection(_:)`** — 두 기간의 교집합으로 새 `DateInterval` 반환 (주 경계 토막)
- **인터벌 색칠 그리디 알고리즘** — 시작순 정렬 후 빈 lane 에 배치하는 고전 패턴 (순수 함수로 캡슐화)
- **`UnevenRoundedRectangle`** (또는 부분 corner masking) — 모서리 일부만 둥글기

**다시 쓰는 개념** (링크):
- `Dictionary(grouping:by:)` → [11-03](../11-달력-이벤트-표시/03-날짜별-인덱스-성능핵심.md)
- 순수 함수로 표시 로직 분리 → [11-03](../11-달력-이벤트-표시/03-날짜별-인덱스-성능핵심.md)
- `Calendar` 산술 / `DateInterval` 기본 → [자주-쓰는-기술들/Calendar-와-Date.md](../자주-쓰는-기술들/Calendar-와-Date.md)
- `.overlay` / `.frame(maxWidth:, alignment:)` → [02-05](../02-상단-플로팅-툴바/05-HoverButton%20분리와%20hover%20배경.md), [08-03](../08-카테고리-추가-다이얼로그/03-다이얼로그%20컨테이너와%20어두운%20배경.md)
- 작은 SF Symbol → [02-02](../02-상단-플로팅-툴바/02-버튼과%20SF%20Symbols.md)
- enum 연관값 분기 / `.edit(Event)` 모드 → [12-04](../12-일-팝업/04-이벤트클릭-수정-프리필완성.md)

## 설계 한눈에

```
[Event]                                                          ← 이미 ready
   │
   │  (01) 멀티데이 시 start~end 모든 날에 키 등록
   ▼
[Date : [Event]]   ← eventsByDay (셀용)
   │                              ▲
   │  (셀: 단일 일만 그림 — 05)    │  (셀 ↔ 행 overlay 협력)
   ▼                              │
DayCellView         WeekRowView ──┘
   ▲                  │
   │                  │  (03) GeometryReader 로 행 너비
   │                  │  (03) 주 단위 멀티데이 필터링
   │                  │  (07) DateInterval.intersection 으로 주 토막
   │                  │  (08) assignLanes(events:) → [(event, lane)]
   │                  ▼
   │              .overlay { 멀티데이 바들 }  ← (04) 단색 → (06) 텍스트+아이콘 → (11) 캡
   │                  │
   └─ (09) lane 갯수만큼 셀 상단 reserved space
        (10) +N 합산 = 멀티데이 lane + 단일 일 - capacity
```

핵심 원칙:
1. **셀은 자기 칸을 못 벗어난다** → 멀티데이는 **상위(주 행) 의 `.overlay`** 가 담당.
2. **데이터/조회 함수는 순수 함수** → `eventsByDay`, `multidayEventsInWeek`, `assignLanes` 모두 입력 → 출력. 테스트·재사용 자유.
3. **단계 02 부터는 추가만, 빼는 게 없다** → 단계 끝마다 시각 결과가 자연스럽게 누적.
