# 이벤트 삭제

## 목표
이벤트를 두 진입 경로에서 삭제할 수 있게 한다. 확인 다이얼로그 없이 즉시 삭제 (Category 삭제와 동일 톤).

진입 경로:
- **일 팝업 행 우클릭** → contextMenu "삭제"
- **이벤트 수정 다이얼로그** 안 좌측 하단 "삭제" 버튼

## 의존 관계
- 사전 필요:
  - `09-폴더-카테고리-데이터-영속화` — `modelContext.delete(_:)`, `.contextMenu` 패턴 ([09-06](../09-폴더-카테고리-데이터-영속화/06-삭제.md))
  - `12-일-팝업` — `DayPopupEventRow`, `DayPopupDialog`
  - `13-이벤트-다이얼로그-마무리` — `.edit(Event)` 모드의 `AddEventDialog`
- 이후 영향: 없음 (leaf 기능)

## 단계 체크리스트
- [x] 01 - 일 팝업 행 우클릭 → 삭제
- [x] 02 - 수정 다이얼로그 안 "삭제" 버튼
- [ ] 03 - 삭제 애니메이션 (페이드아웃)

## 이 기능에서 학습할 Swift / SwiftUI 개념

**새로 등장**: 없음 — 전부 09-06 / 12 / 13 에서 다룬 스킬의 재사용 + 조합.

**다시 쓰는 개념** (링크):
- `.contextMenu { ... }` + `Button(role: .destructive)` → [09-06](../09-폴더-카테고리-데이터-영속화/06-삭제.md)
- `@Environment(\.modelContext)`, `modelContext.delete(_:)` → [09-06](../09-폴더-카테고리-데이터-영속화/06-삭제.md)
- enum 연관값 분기 `.edit(Event)` / `.add(Date)` → [12-04](../12-일-팝업/04-이벤트클릭-수정-프리필완성.md), [13-4](../13-이벤트-다이얼로그-마무리/04-수정모드-타이틀.md)
- 다이얼로그 닫힘 `onDismiss()` 패턴 → [12-02](../12-일-팝업/02-일클릭-팝업-모달.md)

## 데이터 관계 확인
- `Event` 는 leaf — cascade 영향 없음. `modelContext.delete(event)` 한 줄.
- `Category` 와의 관계는 `var category: Category?` (Event 가 자식). Event 삭제는 Category 에 영향 X.
- 멀티데이도 같은 모델 인스턴스 하나 → 한 번 삭제로 모든 셀/주에서 사라짐.
