# 단계 2: DayCell id 안정화 — 자연키 패턴

## 학습 목표
- SwiftUI 의 **view identity** 가 무엇인지 정확히 안다 — 같은 위치에 있어도 `id` 가 달라지면 SwiftUI 입장에선 다른 뷰.
- `Identifiable` 의 `id` 를 **무엇으로 정할지** 가 시각 동작을 가른다는 사실을 익힌다.
- **자연키 (natural key)** 로 `id` 를 노출하는 패턴을 익힌다.

## 사전 지식
- `Identifiable` / `UUID` 기본 사용 → [04-1](../04-사이드바-카테고리-UI/01-Folder%20Category%20모델%20+%20더미%20데이터.md)
- 단계 01 완료 — 사이드바 토글이 frame 기반 애니메이션으로 동작

## 문제 재현

단계 01 적용 후에도 토글 시 **일 그리드 영역이 흐릿하게 페이드아웃 / 페이드인** 되는 현상이 남아 있다.

원인 흐름:
1. `isSidebarVisible` 토글 → `ContentView.body` 재평가
2. body 안의 `MonthlyCalendarView()` 가 새 struct 로 만들어짐 → `init()` 실행
3. `init()` 이 `makeDayCells(for: Date())` 호출 → **42개 DayCell 이 새 UUID 와 함께 생성**
4. SwiftUI 의 `ForEach(row)` 는 DayCell 의 `id` 로 식별 → 이전 셀들은 "사라진 뷰", 새 셀들은 "추가된 뷰"
5. `withAnimation(.smooth) { ... }` 컨텍스트 안이라 사라짐/추가에 **기본 transition (`.opacity`)** 가 시간 보간되어 발동
6. 그리드 전체 페이드 아웃 → 페이드 인

## Swift / SwiftUI 개념

### 1) View identity — 같은 위치, 같은 타입으로 충분하지 않다

SwiftUI 는 view tree 를 diff 할 때 두 가지 identity 를 본다:

- **Structural identity**: 그 위치의 부모-자식 관계 + 타입. `ForEach` 밖에선 보통 이것만으로 충분.
- **Explicit identity**: `Identifiable.id` 또는 `.id(...)` modifier 로 명시한 값. **`ForEach` 안에선 반드시 이것** 으로 식별.

`ForEach(row) { cell in DayCellView(cell: cell) }` — 여기서 SwiftUI 가 보는 건 `cell.id`. 두 번의 body 재평가에서 같은 `cell.id` 가 다시 등장하면 → "같은 뷰, 데이터만 업데이트". 다른 id 면 → "이전 뷰 사라짐, 새 뷰 등장" → transition 발동.

### 2) `let id = UUID()` 의 함정

```swift
struct DayCell: Identifiable {
    let id = UUID()     // ← stored property, default value = init 마다 새 UUID
    ...
}
```

`let id = UUID()` 는 stored property 의 default value — **인스턴스가 생성될 때마다 새 UUID** 가 발급된다. 그래서:

- `makeDayCells(for: Date())` 호출 시점마다 42개 다른 UUID
- 본질적으로 "같은 날짜 (2026-05-15)" 인데도 UUID 가 다르면 SwiftUI 입장에선 다른 뷰

UUID 는 **고유성 (uniqueness)** 을 보장하지만 **동일성 (identity)** 을 보장하지 않는다. 같은 도메인 개체 (같은 날짜) 가 매번 새 UUID 를 받으면 안 된다.

> Java/JPA 비유: Entity 에 `@Id UUID id = UUID.randomUUID()` 를 필드 초기화로 박아두고, `equals/hashCode` 를 그 id 로 구현한 셈. DB 에 영속화하기 전까진 매 `new` 마다 다른 엔티티 — 같은 논리적 개체인데도. 정상적인 방식은 **자연키 (학번/사번/날짜)** 또는 영속화 후 부여된 id.

### 3) 자연키 (natural key) 로서의 id

`DayCell` 의 정체성은 **그 날짜** 다. 같은 날짜를 가리키는 셀은 같은 뷰. 그래서:

```swift
struct DayCell: Identifiable {
    let date: Date
    var id: Date { date }    // ← computed property, date 가 곧 id
    let day: Int
    let weekday: Int
    let isInCurrentMonth: Bool
}
```

핵심:
- `let id = UUID()` (stored, init 시 새 값) → `var id: Date { date }` (computed, date 와 동일)
- `Date` 는 `Hashable` 이므로 `Identifiable.ID` 타입 조건을 충족 (Identifiable 정의: `associatedtype ID: Hashable`)
- 같은 날짜의 cell 은 매 body 재평가에서 같은 id → SwiftUI 가 "같은 뷰, 데이터만 업데이트" 로 식별

> `let` 은 stored 만, `var` 는 stored 와 computed 둘 다 가능. computed property 는 매 접근마다 `{ ... }` 안을 평가해 값을 반환 — 별도 저장 공간 없음.

### 4) 그래서 transition 이 안 발동되는 이유

이전엔 ForEach 안의 셀이 매 body 재평가마다 "사라졌다 새로 등장" → `withAnimation` 컨텍스트 안에서 기본 `.opacity` transition 이 fade out / in 으로 시간 보간되어 보였다.

이제는 같은 id → "같은 뷰, 데이터만 업데이트" → transition 대상 아님 → 페이드 X.

> Java 비유: `equals/hashCode` 를 자연키로 바꾸면 HashMap 이 "같은 키" 로 인식해 새 엔트리를 만들지 않고 갱신만 하는 것과 같음.

## 구현 가이드

`CalendarMath.swift` 의 `DayCell.id` 선언을 `let id = UUID()` 에서 computed property 로 바꾼다. 한 줄 수정.

힌트:
- `var id: Date { date }` 형태
- `date` 프로퍼티는 이미 있으므로 새 저장 공간 추가 X
- `let` (stored) → `var` (computed) 차이 주의. computed 는 `var` 만 가능.

## 직접 구현하기
- [x] `DayCell.id` 를 `var id: Date { date }` 로 교체
- [x] 빌드 통과 (⌘B)
- [x] 사이드바 토글 → 일 그리드가 더 이상 페이드되지 않음

## 자가 점검
- 빌드 통과?
- 시각 검증: 토글 시 일 그리드 영역이 페이드 없이 그대로 유지되는가?
- 자문자답: `Identifiable.ID` 의 타입 제약은?
  > `Hashable`. UUID, Int, String, Date 등 모두 가능.
- 자문자답: 만약 같은 그리드에 같은 날짜가 두 번 등장한다면?
  > 이 앱에선 그럴 일이 없지만, 만약 그렇다면 id 가 중복되어 SwiftUI 가 런타임 경고 / 동작 이상. 자연키도 도메인상 unique 해야 함.
- 자문자답: `let id = UUID()` 가 좋은 선택인 경우는?
  > 도메인상 자연키가 없는 경우 — 예: 사용자가 임의로 만든 메모. 단, 한 번 만든 UUID 를 다시 init 마다 새로 발급하면 안 됨. 보통 상위 (DB / Store) 에서 1회 발급 후 유지.

## Claude 리뷰 체크리스트
- [x] `DayCell.id` 가 computed property 로 `date` 를 반환
- [x] 토글 시 일 그리드 페이드 사라짐
- [ ] (선택) 자연키 패턴의 의미를 본인 말로 설명 가능한가

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `.id(_:)` modifier — Identifiable 외에 view 자체에 id 를 명시 부여. 의도적으로 view 를 "다른 뷰" 로 강제 reset 하고 싶을 때 (예: 탭 전환 시 강제 초기화).
- `EquatableView` — view 가 Equatable 이면 SwiftUI 가 body 재평가를 스킵 가능. 큰 view tree perf 최적화에 종종 등장. 본 케이스엔 불필요.
- `Hashable` 자동 합성 — struct 의 모든 stored property 가 Hashable 이면 자동 합성. `Date` 가 Hashable 이라 `DayCell` 도 `Hashable` 채택만 적으면 자동 완성됨.
