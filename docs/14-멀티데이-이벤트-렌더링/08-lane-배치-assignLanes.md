# 단계 8: lane(트랙) 배치 — `assignLanes` 순수 함수

## 학습 목표
- 한 주 안에 여러 멀티데이가 시간적으로 겹칠 때 **세로로 단(lane)을 쌓는** 알고리즘을 이해하고 직접 구현.
- "**인터벌 색칠 그리디 알고리즘**" 이라는 고전 패턴을 익힌다.

## 사전 지식
- 07 단계의 슬라이스 `[(event: Event, interval: DateInterval)]` 가 입력.
- 순수 함수 분리 원칙 → [11-03](../11-달력-이벤트-표시/03-날짜별-인덱스-성능핵심.md)

## 알고리즘 — 인터벌 색칠 그리디

문제: N 개의 시간 구간이 있다. 각 구간에 0, 1, 2, ... 번호(lane)를 매기되, **같은 lane 안의 두 구간은 서로 겹치면 안 된다**. 가능한 한 작은 번호부터 채운다.

**전략**:
1. 구간들을 **시작 시각 오름차순으로 정렬**.
2. 각 구간을 하나씩 보면서, **가장 작은 빈 lane** 을 찾아 배치.
3. lane 별로 "마지막 구간의 end" 만 기억하면 충분 — 새 구간의 start 가 그 end 이후이면 그 lane 에 넣을 수 있음.

```swift
struct LanedSlice {
    let event: Event
    let interval: DateInterval
    let lane: Int
}

func assignLanes(_ slices: [(event: Event, interval: DateInterval)]) -> [LanedSlice] {
    let sorted = slices.sorted { $0.interval.start < $1.interval.start }
    var laneEnds: [Date] = []           // index = lane, value = 그 lane 의 가장 마지막 end
    var result: [LanedSlice] = []

    for slice in sorted {
        // 1) 빈 lane 찾기: laneEnds[i] <= slice.interval.start 인 가장 작은 i
        let lane: Int
        if let i = laneEnds.firstIndex(where: { $0 <= slice.interval.start }) {
            lane = i
            laneEnds[i] = slice.interval.end           // 이 lane 의 end 갱신
        } else {
            // 빈 lane 없음 → 새 lane 추가
            lane = laneEnds.count
            laneEnds.append(slice.interval.end)
        }
        result.append(LanedSlice(event: slice.event, interval: slice.interval, lane: lane))
    }
    return result
}
```

> Java 비유: `PriorityQueue<LaneEnd>` 로 가장 빨리 끝나는 lane 만 뽑는 변형도 가능 — O(N log N). 위 구현은 단순 배열 선형 탐색 O(N · L) 인데 한 주 안 멀티데이 수가 작으므로 충분히 빠르다.

### 왜 시작순 정렬?
끝나는 시각이 빠른 lane 부터 빈 자리가 생긴다. 들어오는 구간을 시작순으로 보면, "그 시점에 끝난 lane" 들 중 어느 곳에든 넣을 수 있다 → 가장 위 lane(작은 번호)부터 채우면 시각적으로 빈 자리가 안 생긴다.

## 구현 가이드

**1) 새 함수 `assignLanes(_:)` 추가**

`EventIndex.swift` 또는 새 파일 `MultidayLayout.swift` 에 둔다. **순수 함수** 라 View 와 무관.

```swift
struct LanedSlice {
    let event: Event
    let interval: DateInterval
    let lane: Int
}
```

테스트는 안 하지만, 구조가 명확해 추후 unit test 붙이기 쉽다 (입력 → 출력의 결정적 함수).

**2) `WeekRowView` 에서 사용**

```swift
let slices = slices(for: weekMultidays, in: weekInterval)
let laned = assignLanes(slices)

ForEach(laned, id: \.event.id) { l in
    let f = barFrame(for: (l.event, l.interval), weekStart: weekStart, rowWidth: rowWidth)
    // 본문 (06 단계의 HStack)
        .offset(x: f.x, y: 24 + CGFloat(l.lane) * (16 + 2))
        // y = 베이스 + lane × (바높이 + 간격)
}
```

- **lane 0** 은 가장 위. lane 1, 2, ... 이 아래로 쌓임.
- **`16` 은 04 단계의 바 높이**, **`2` 는 lane 간 간격**. 추후 한 곳에서 관리하려면 상수화 (`private let barHeight: CGFloat = 16`, `private let barGap: CGFloat = 2`).

**3) (선택) lane 갯수 노출 — 09 단계 준비**

09 단계의 "셀 내부 컨텐츠 밀어내기" 는 **그 주의 lane 갯수** 를 알아야 한다. `assignLanes` 결과의 `lane` 최댓값 + 1 = lane 갯수.

```swift
let laneCount = (laned.map(\.lane).max() ?? -1) + 1
```

- 빈 배열일 때 `-1 + 1 = 0` 으로 자연스럽게 처리.
- 이 값을 09 단계에서 자식 셀에 prop 으로 또는 환경값으로 전달.

## 직접 구현하기
- [x] `LanedSlice` 구조체 + `assignLanes(_:)` 함수 추가
- [x] `WeekRowView` 의 `ForEach` 를 `laned` 기준으로 교체
- [x] `.offset(y: ...)` 에 lane 인덱스 반영
- [x] 같은 주에 멀티데이 2~3개 시작·끝이 겹치게 만들어 보고, **세로로 단** 이 나뉘는지 확인
- [x] 안 겹치는 두 멀티데이는 같은 lane 0 에 들어가 깔끔하게 일렬로 늘어서는지

## 자가 점검
- 빌드 통과?
- 같은 주에 멀티데이 A(월~수), B(화~목), C(목~금) → A=lane0, B=lane1, C=lane0 (또는 비슷한 합리적 배치) 인가?
- A(월~수), B(목~금) 처럼 끝과 시작이 같은 날이지만 시작은 더 뒤 → 같은 lane?
- 퀴즈: `assignLanes` 가 **결정적**(같은 입력 → 같은 출력) 인가? 만약 입력 정렬이 불안정하면 어떻게 되는가?

## Claude 리뷰 체크리스트
- [ ] `assignLanes` 가 순수 함수 (입력 → 출력만, View 모름)
- [ ] 시작순 정렬 → 빈 lane 우선 배치 그리디
- [ ] lane 인덱스가 0-based, 가장 위가 0
- [ ] 빈 입력에서도 안전 (`laneEnds` 빈 채로 시작)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 알고리즘 정확한 이름: **interval graph coloring** (구간 그래프 색칠). 일반 그래프 색칠은 NP-hard 지만, 인터벌 그래프는 위 그리디로 **최적해 O(N log N)**.
- 같은 시작 시각의 동률 처리 — 위 코드는 `sorted` 가 stable 하지 않다고 가정해야 하므로, 보조 정렬 키 (예: `event.id` 또는 endDate) 를 명시하면 결정적.
- 캘린더 앱들의 흔한 변종: **표시 가능 lane 수 상한** (예: max 2 lane, 넘치면 "+N more"). 이건 09~10 단계와 함께 다듬을 만한 디테일.
