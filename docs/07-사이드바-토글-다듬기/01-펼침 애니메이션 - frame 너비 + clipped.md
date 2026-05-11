# 단계 1: 펼침 애니메이션 — frame 너비 + `.clipped()`

## 학습 목표
- 기능 03 의 `if` + `.transition(.move)` 방식과 frame width 애니메이션 방식의 차이를 안다.
- **두 겹 frame 트릭** — 내부 frame 으로 내용 layout 고정, 외부 frame 으로 보고할 너비만 애니메이션 — 을 익힌다.
- `.clipped()` 로 frame 바깥으로 삐져나가는 내용 잘라내기.

## 사전 지식
- `withAnimation` / `.transition` / spring preset → [03-3](../03-사이드바-슬라이드/03-slide%20애니메이션과%20transition.md)
- HStack push 레이아웃 → [03-2](../03-사이드바-슬라이드/02-Sidebar%20뷰와%20조건부%20레이아웃.md)

## Swift / SwiftUI 개념

### 1) 왜 이번엔 `if` + `.transition` 이 아닌 frame 너비를 쓰나

기능 03 에선 다음 이유로 `if` + `.transition` 을 권장했다:
- 의도가 코드에 잘 드러남 ("있다 / 없다")
- 안 보일 땐 view-tree 에서 빠져 measurement 비용이 없음

그런데 실제로 써보니 본 앱에선 부작용이 더 컸다:

- 사이드바와 형제인 일 그리드 영역이 `withAnimation` 컨텍스트 안에서 함께 reflow 되며, **일 그리드 셀들의 default transition (`.opacity`)** 까지 발동되어 흐릿하게 페이드아웃/인.

(이 페이드의 진짜 뿌리는 단계 02 에서 다룬다. 이 단계에선 토글 모양만 정돈.)

대안: **늘 존재하는 사이드바의 너비만 0 ↔ 240 으로 애니메이션**.
- 자식 추가/제거가 없으니 transition 발동 X
- HStack 의 layout 변화는 single 보간 → 일 그리드는 자연스럽게 좁아짐

### 2) `.clipped()` — frame 바깥으로 삐져나간 내용 자르기

```swift
SomeView()
    .frame(width: 100)
    .clipped()
```

- `frame` modifier 는 **보고할 size** 만 제한한다 — 자식이 더 크게 그려져도 SwiftUI 는 부모에게 "100 wide" 라고 보고할 뿐, 실제 그리는 영역은 자식의 본래 크기일 수 있다.
- `.clipped()` 는 그 frame 바깥으로 삐져나간 부분을 **렌더링에서 잘라낸다**.

> CSS 비유: `width: 100px; overflow: hidden;` 의 두 줄을 SwiftUI 에선 frame + `.clipped()` 로.

### 3) frame 두 겹 트릭

외부 frame 하나만으로는 부족하다. **사이드바 내용 자체가** 좁아진 frame 에 맞춰 줄어들면 (Text 줄바꿈, spacing 재계산 등) layout 이 흐트러진다. 그래서:

```swift
// Sidebar.swift 내부
.frame(width: 240, alignment: .leading)        // 내부 layout 항상 240 으로 고정

// ContentView.swift 에서
Sidebar()
    .frame(width: isOpen ? 240 : 0, alignment: .leading)   // 보고할 너비만 0~240
    .clipped()
```

- **내부 frame**: Sidebar 의 내용은 늘 240 wide 로 layout. Text 줄바꿈 / spacing 변화 없음.
- **외부 frame**: 부모(HStack) 에 보고할 너비만 0~240 사이로 애니메이션. `alignment: .leading` → 너비가 줄어들 때 **내용이 왼쪽 끝에 고정** 되고 오른쪽으로 삐져나감.
- **`.clipped()`**: 오른쪽으로 삐져나간 부분을 잘라냄 → 보고된 너비만큼만 보임.

결과: 사이드바가 왼쪽에 고정된 채로 **오른쪽 끝에서부터 잘려나간다 / 다시 드러난다**. HStack 은 외부 frame 의 너비를 기준으로 reflow → 일 그리드가 자연스럽게 좁아짐 / 넓어짐.

> 외부 frame 의 alignment 를 `.center` (생략 시 기본값) 로 두면 너비가 줄어들 때 내용이 양쪽에서 잘려 가운데가 보이는 이상한 모양이 된다. **`.leading` 필수**.

### 4) `if` vs frame — 트레이드오프 정리

| | `if` + `.transition` | frame 너비 + `.clipped()` |
|---|---|---|
| 의도 표현 | "있다 / 없다" — 명확 | 너비 0 인 view 가 늘 존재 — 의도 덜 직설 |
| 형제 view 에 default transition 영향 | **있음** (이번 페이드의 한 갈래) | 없음 |
| measurement 비용 | 안 보일 땐 0 | 항상 240 wide layout 계산 |
| 코드량 | 짧음 | frame 두 겹 + `.clipped()` |

작은 사이드바 한 덩어리라면 측정 비용은 무시할 만하다. 본 앱에선 frame 방식 채택.

## 구현 가이드

> 이 단계는 사용자가 이미 거의 구현한 상태에서 출발한다. 잔여 정리 위주.

### 1) `ContentView.swift` — `if` 를 frame 으로 교체

기존:
```swift
if isSidebarVisible {
    Sidebar()
        .transition(.move(edge: .leading))
}
```

목표 모양:
```swift
Sidebar()
    .frame(width: isSidebarVisible ? 240 : 0, alignment: .leading)
    .clipped()
```

체크포인트:
- 외부 frame 에 `alignment: .leading` 이 들어가 있나?
- `.clipped()` 가 frame 뒤에 붙어 있나? (잘라낼 frame 을 먼저 정한 뒤 clip)
- `.transition` 은 더 이상 필요 없으니 제거됐나?

### 2) `Sidebar.swift` — 내부 frame 유지 + 잡정리

내부 layout 고정용 frame 은 유지:
```swift
.frame(width: 240, alignment: .leading)
.frame(maxHeight: .infinity, alignment: .topLeading)
```

체크포인트:
- 내부 `.frame(width: 240, alignment: .leading)` 이 있는가?
- 의미 없는 `.frame(alignment: .leading)` (width/height 없는 형태) 가 남아있지 않은가?

### 3) 잡정리

- `CalendarMath.swift` 의 `import SwiftUI` ↔ `import Foundation` 변경은 이번 작업과 무관 — 별도 커밋으로 분리하거나 되돌릴 것. (`DayCell` 이 Color 등 SwiftUI 타입을 안 쓰면 Foundation 으로 충분하므로 정리 자체는 맞다.)
- `ContentView.body` 끝의 orphan `let _: [DayCell] = makeDayCells(for: Date())` — 죽은 코드. 제거 권장.

## 직접 구현하기
- [ ] ContentView 에 frame 두 겹 트릭 적용 — 외부 frame `alignment: .leading` 확인
- [ ] Sidebar 내부 `.frame(width: 240, ...)` 유지, 무의미한 빈 frame 제거
- [ ] 토글 → 사이드바가 왼쪽에서 펼쳐지면서 일 그리드가 부드럽게 좁아짐
- [ ] 닫을 때 페이드 없이 너비만 줄어듦 (단, **일 그리드 자체의 페이드는 이 단계에선 아직 남아있을 수 있음** — 단계 02 의 영역)
- [ ] orphan 코드 / 무관 import 정리

## 자가 점검
- 빌드 통과? (⌘B)
- 자문자답: `.frame(width: 100).clipped()` 와 `.frame(width: 100)` 의 차이는?
  > 후자는 자식이 100 보다 크게 그려져도 그대로 그려짐. 보고하는 너비만 100. 전자는 100 바깥으로 안 그림.
- 자문자답: 두 겹 frame 트릭에서 외부 alignment 를 `.center` 로 바꾸면 어떻게 보이나?
  > 너비가 줄어들 때 양쪽에서 잘려 가운데 부분만 보임 — 이상함.
- 자문자답: `if` 방식이 더 SwiftUI 다운데 왜 굳이 frame 방식으로 갔나?
  > 형제 view 에 default `.opacity` transition 이 묻어 들어와서. 이 결정의 진짜 이유는 단계 02 에서 더 깊이 드러남.

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] ContentView 의 `if` 가 frame width 애니메이션으로 대체됨
- [ ] 외부 frame 에 `alignment: .leading` 명시
- [ ] `.clipped()` 가 frame 뒤에 위치
- [ ] Sidebar 내부 `.frame(width: 240, ...)` 유지로 내부 layout 흐트러지지 않음
- [ ] 잡정리 (orphan 코드, 무의미한 빈 frame) 반영

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `.mask` modifier — `.clipped()` 와 비슷하지만 임의 모양으로 clip. 둥근 모서리로 자르려면 `.mask(RoundedRectangle(cornerRadius: 8))`.
- `frame` 의 `minWidth/maxWidth/idealWidth` — 표현 차이. 본 케이스엔 고정 width 가 깔끔.
- macOS 의 `NavigationSplitView` — 표준 사이드바 컨테이너. 학습 톤상 직접 빌드 유지.
