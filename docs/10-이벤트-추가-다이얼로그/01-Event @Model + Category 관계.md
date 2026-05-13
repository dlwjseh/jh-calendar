# 단계 1: Event @Model + Category 관계

## 작업 목표
`Event` 모델을 SwiftData `@Model` 로 신설하고, `Category` 와 1:N 양방향 관계로 묶는다. 빌드 통과·시각 변화는 없음(다이얼로그가 아직 없으니 표면에 안 보임) — **다음 단계에서 폼이 붙는 데이터 토대** 만 준비.

> 새 Swift 개념은 없다. 09 의 `Folder ↔ Category` 패턴을 `Category ↔ Event` 로 한 번 더 적용하는 단계.
> 단, **deleteRule 선택** 은 09 와 의도적으로 다르게 간다 — 아래 참고.

## 사전 지식
- 09 의 산출물 — `Folder`, `Category` 가 `@Model` 로 영속화돼 있음
- `@Model`, `@Relationship`, `ModelContainer` → [09/01-SwiftData 도입.md](../09-폴더-카테고리-데이터-영속화/01-SwiftData%20도입.md), [09/02-Category @Model + Relationship.md](../09-폴더-카테고리-데이터-영속화/02-Category%20@Model%20%2B%20Relationship.md) 참고
- `.cascade` 의미 → [09/02-Category @Model + Relationship.md](../09-폴더-카테고리-데이터-영속화/02-Category%20@Model%20%2B%20Relationship.md) 참고

## 작업 가이드

### deleteRule 은 `.cascade` 가 아니라 `.nullify`

09 에서 폴더 ↔ 카테고리 는 `.cascade` 였다 (폴더가 죽으면 카테고리도 같이 죽어야 자연스러움).
하지만 카테고리 ↔ 이벤트 는 다르다 — **카테고리를 지웠다고 그 안의 일정까지 같이 지우면 사용자가 당황한다.** 보통 캘린더 앱은 카테고리만 삭제하고 일정은 "미분류" 상태로 남긴다.

| 규칙 | 사용처 | 이번 단계 |
|---|---|---|
| `.cascade` | 폴더 → 카테고리 (09) | ✗ |
| `.nullify` | 카테고리 → 이벤트 | ✓ |

> JPA 비교: `@OneToMany(orphanRemoval = true)` 였다면 `.cascade`, `orphanRemoval = false` 면 `.nullify` 와 가깝다.

### 파일 변경 계획
- `JHCalendar/Features/` 아래에 **`Event/` 폴더 신설** (CLAUDE.md 의 "새 기능을 추가할 때" 참고 — sync group 으로 등록하면 이후 파일 추가가 자유로움)
  - 이 단계에선 모델 한 파일만 들어가지만, 다음 단계 다이얼로그도 같은 폴더로.
  - 빠르게 가려면 일단 **`SidebarModels.swift` 옆에 `EventModels.swift` 로 같이 둬도 OK** — 09 의 `SidebarModels.swift` 가 이미 sync group 안에 있어서 등록 작업이 0. 다음 단계에서 다이얼로그 만들 때 폴더 분리하면 됨.
- `EventModels.swift` (또는 통합 위치) — `Event` `@Model` 정의
- `SidebarModels.swift` — `Category` 에 역방향 `events: [Event]` 관계 추가
- `JHCalendarApp.swift` — `.modelContainer(for: ...)` 등록 리스트에 `Event.self` 명시 추가

### 핵심 골격

```swift
import SwiftData

@Model
final class Event {
    var name: String
    var isAllDay: Bool
    var category: Category?

    init(name: String, isAllDay: Bool, category: Category? = nil) {
        self.name = name
        self.isAllDay = isAllDay
        self.category = category
    }
}
```

`Category` 쪽 변경 — `inverse:` 는 한쪽에만 적는다는 규칙([09/02](../09-폴더-카테고리-데이터-영속화/02-Category%20@Model%20%2B%20Relationship.md)) 그대로:

```swift
@Model
final class Category {
    var name: String
    var colorHex: String
    var isChecked: Bool
    var folder: Folder?

    @Relationship(deleteRule: .nullify, inverse: \Event.category)
    var events: [Event] = []
    // ↑ 추가

    // init 은 그대로
}
```

### 막힐 만한 지점 — 힌트
- **`ModelContainer` 에 새 모델을 등록 안 하면 — 런타임 크래시는 안 나도 저장이 누락되는 경우 발생.** `JHCalendarApp.swift` 의 `.modelContainer(for: [Folder.self, Category.self, Event.self])` 식으로 명시.
- **컴파일 에러 `Cannot find type 'Event' in scope`** — 같은 모듈이라 import 는 필요 없지만, 파일이 빌드 타깃에 안 들어가 있을 가능성. `Features/Event/` 를 새로 만들었으면 sync group 등록 확인.
- **양쪽에 `inverse:` 를 적어서 빌드 에러** — 9에서 한 번 겪었던 패턴. `Category.events` 쪽에만 적고 `Event.category` 는 그냥 두기.
- **시각 확인이 없는 단계라 "정말 됐는지" 불안할 수 있음** — 이 단계는 빌드 통과만 합격 기준. 데이터 검증은 03 단계에서.

## 직접 구현하기
- [ ] `Event` `@Model` 작성 (`name`, `isAllDay`, `category`)
- [ ] `Category` 에 `@Relationship(deleteRule: .nullify, inverse: \Event.category) var events: [Event] = []` 추가
- [ ] `ModelContainer` 등록 목록에 `Event.self` 명시
- [ ] (선택) `Features/Event/` 폴더 신설 + sync group 등록
- [ ] 빌드 통과

## 자가 점검
- 빌드 OK?
- `Category` 인스턴스에서 `.events` 컬렉션, `Event` 인스턴스에서 `.category` 가 양쪽에서 접근 가능한가?
- 이해도 퀴즈
  1. 왜 카테고리 → 이벤트 는 `.cascade` 가 아니라 `.nullify` 가 자연스러울까?
  2. `Event` 의 `category` 가 Optional (`Category?`) 인 이유는 `.nullify` 와 어떻게 연결되나?

## Claude 리뷰 체크리스트
- [ ] `Event` 가 `@Model final class` 이고 세 프로퍼티(name/isAllDay/category)가 정확히 존재
- [ ] `@Relationship(deleteRule: .nullify, inverse: \Event.category)` 가 한쪽(Category)에만 선언됨
- [ ] `ModelContainer` 에 `Event.self` 명시
- [ ] 빌드 통과

## 회고
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `Event` 에 `startDate: Date`, `endDate: Date` 를 지금 같이 넣어두는 것도 가능 — 다만 이번 기능 범위 밖이라 다음 기능에서 도입.
- "미분류" 이벤트를 사이드바에서 어떻게 노출할지(가상 카테고리 / 별도 섹션) — 후속 기능 주제.
