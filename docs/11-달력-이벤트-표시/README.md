# 달력 이벤트 표시 (단일 일 일정)

## 목표
월간 달력의 각 일(day) 셀에 그 날의 이벤트를 표시한다. **이번 기능은 단일 일(하루짜리) 일정만** 다룬다. 멀티 데이(여러 날 걸치는) 일정은 데이터 모델·인덱스 설계에만 미리 반영해 두고 렌더링은 다음 기능으로 미룬다.

표시 방식 2가지:
- **종일 이벤트**: 카테고리 색으로 채운 바(bar) 안에 이벤트명
- **시간 지정 이벤트**: 카테고리 색 동그라미 + 이벤트명

## 의존 관계
- 사전 필요:
  - `05-월간-달력-UI` — `DayCellView`, `CalendarStore`, `CalendarMath`
  - `10-이벤트-추가-다이얼로그` — `Event` @Model, `AddEventDialog`
  - `09-폴더-카테고리-데이터-영속화` — SwiftData `modelContainer`, `@Query`
- 이후 영향:
  - **멀티 데이 일정 렌더링** (주(week) 행을 가로지르는 연속 바 / lane 배치) — 06 문서에 로드맵 정리
  - 이벤트 클릭 → 편집 다이얼로그(`.edit`) 연결

## 단계 체크리스트
- [ ] 01 - 이벤트 날짜 필드 영속화 (`startDate` / `endDate` + AddEventDialog 연동)
- [ ] 02 - 표시 범위 이벤트 조회 (`@Query` + `#Predicate` 날짜 범위 + 정렬)
- [ ] 03 - 날짜별 인덱스 만들기 (성능 핵심 — `[Date: [Event]]`)
- [ ] 04 - 종일 이벤트 바 렌더링 (`DayCellView` 에 이벤트 전달)
- [ ] 05 - 시간 지정 동그라미 + 정렬 + 오버플로우(+N)
- [ ] 06 - 멀티 데이 로드맵 & 회고 (문서 전용, 코드 없음)

## 이 기능에서 학습할 Swift / SwiftUI 개념
- SwiftData 모델 스키마 변경(필드 추가)과 lightweight migration
- `@Query` 의 `#Predicate` 필터 + 정렬 (DB의 `WHERE` / `ORDER BY` 에 해당)
- `Dictionary` 와 `Dictionary(grouping:by:)` — 컬렉션을 키로 묶기 (Java `Collectors.groupingBy`, JS reduce-to-map 대응)
- `Calendar.startOfDay(for:)` 로 날짜 정규화 → Dictionary 키로 사용
- 순수 함수로 표시 로직 분리 (테스트 용이 + 성능 + 멀티데이 확장 지점 격리)
- 셀당 O(1) 조회로 만드는 성능 설계 (naive 셀당 필터 O(셀×이벤트) 와 비교)

## 설계 한눈에 (왜 이렇게 쪼갰나)

```
Event(@Model)  ──@Query(#Predicate: 표시범위, sort: startDate)──▶  [Event]
      │                                                              │
   startDate                                          eventsByDay(_:in:)  ← 순수 함수 (멀티데이 확장 지점)
   endDate                                                            │
                                                              [Date : [Event]]   ← 날짜별 인덱스(성능 핵심)
                                                                       │  startOfDay 키로 O(1) 조회
                                                              DayCellView(events:)  ← "멍청한" 셀, 필터 안 함
```

핵심: **셀은 필터링하지 않는다.** 부모가 한 번 인덱스를 만들고, 각 셀은 자기 날짜로 O(1) 조회만 한다. 멀티데이로 갈 때 바뀌는 곳은 `eventsByDay(_:in:)` 한 곳뿐이도록 격리한다.
