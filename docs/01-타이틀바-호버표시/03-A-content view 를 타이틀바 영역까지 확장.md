# 단계 3-A: content view 를 타이틀바 영역까지 확장

## 이 단계가 추가된 배경

단계 3 진행 중 호버 감지 영역 위치를 눈으로 확인하려고 임시로 `Color.clear` → `Color.red` 로 바꿔봤는데, 빨간 박스가 **윈도우 최상단에 붙지 않고 약 28pt 아래** 에서 시작했다.

```
┌────────────────────────────────┐
│  ↕ ~28pt 빈 공간               │ ← 사라진 줄 알았던 타이틀바 영역
│  ┌──────┐                       │
│  │ 빨간 │                       │ ← 좌상단(.topLeading)에 배치했는데 안 붙음
│  └──────┘                       │
│                                 │
```

원인은 단계 1 의 **미완성**:
- `.windowStyle(.hiddenTitleBar)` 는 타이틀바를 **시각적으로만** 숨긴다.
- layout 상 그 영역은 여전히 NSWindow 가 차지하고, **SwiftUI content 는 그 아래** 에서 시작한다.
- 그래서 `ZStack(alignment: .topLeading)` 의 좌상단 = "윈도우 최상단" 이 아니라 "타이틀바 아래의 content 영역 최상단".

이건 단계 1 의 보강이지만 단계 3 의 디버깅 중에 드러났기 때문에 별도 단계로 분리한다. 이 단계가 끝나야 단계 3 의 호버 영역이 트래픽라이트 위치(좌상단)와 정확히 겹치고, 단계 4 에서 alphaValue 토글이 의미를 가진다.

> **추가 발견**: 처음엔 NSWindow 의 `.fullSizeContentView` 만 켜면 끝날 줄 알았는데, 그것만으론 여전히 ~28pt 가 비었다. 그 위에서 **SwiftUI 가 자체적으로 safe area inset 을 적용** 하고 있어서 한 단계 더 풀어줘야 했다. 그래서 이 단계는 결국 **AppKit + SwiftUI 두 레이어의 inset 을 모두 푸는 작업** 이 됐다.

## 학습 목표
- Swift 의 **OptionSet** 개념을 이해한다 — 비트 플래그를 타입 안전하게 다루는 컬렉션.
- `NSWindow.styleMask` 에 `.fullSizeContentView` 를 추가해 content view 가 타이틀바 영역까지 확장되게 만든다.
- SwiftUI 의 **safe area** 개념과 `.ignoresSafeArea()` 의 역할을 이해한다 — AppKit 윈도우 처리 위에 SwiftUI 가 한 번 더 inset 을 얹는다는 사실을 체감.
- "시각적 숨김" / "AppKit layout 확장" / "SwiftUI safe area 무시" — **세 레이어** 가 모두 맞아야 진짜 (0, 0) 좌상단을 얻는다는 점을 이해한다.

## 사전 지식
- 단계 1, 2, 3 진행 상태 — `ZStack` 안에 호버 영역이 들어 있고, `.onAppear` 에서 윈도우/버튼을 만지는 코드가 있다.
- 단계 3 에서 호버 박스 위치가 어긋난 현상을 직접 본 상태.

## Swift / SwiftUI 개념

### 1) OptionSet — Swift 의 비트 플래그 컬렉션

여러 옵션을 동시에 켤 수 있는 enum 같은 컬렉션. 내부적으로는 비트마스크지만, 사용 시엔 `Set` 처럼 다룬다.

```swift
// NSWindow.styleMask 는 OptionSet 타입이다.
window.styleMask = [.titled, .closable, .resizable]   // 여러 옵션을 동시에
window.styleMask.insert(.fullSizeContentView)         // 기존을 유지하며 하나 추가
window.styleMask.remove(.resizable)                   // 하나 제거
window.styleMask.contains(.titled)                    // 포함 여부 확인
```

| 환경 | 등가 |
|---|---|
| Java | `EnumSet.of(Modifier.PUBLIC, Modifier.STATIC)` — `EnumSet<E>` 와 가장 가깝다 |
| Spring | `@RequestMapping(method = {RequestMethod.GET, RequestMethod.POST})` — 여러 enum 동시 표현 |
| Vue/JS | 직접 대응 없음. 비트마스크 (`flags & FLAG_X`) 를 raw 하게 다루는 정도 |
| Swift | `OptionSet` — 타입 안전 + Set 인터페이스 |

핵심:
- **`=` 로 통째로 덮어쓰면 기존 옵션이 날아간다**. 기존을 유지하며 하나만 추가하려면 `.insert(_:)` 를 쓴다.
- `[.a, .b, .c]` 배열 리터럴처럼 보이지만 실제론 OptionSet 의 union 표현.

### 2) `NSWindow.styleMask` 와 `.fullSizeContentView`

`styleMask` 는 윈도우의 외형/동작 옵션 묶음.

대표 값들:
- `.titled` — 타이틀바 있음
- `.closable` / `.miniaturizable` / `.resizable` — 닫기/축소/리사이즈 가능
- `.fullSizeContentView` — **content view 가 타이틀바 영역까지 확장**
- `.borderless` — 모든 chrome 제거 (단, 단축키도 같이 사라짐 — 우리 목적엔 부적합)

이번에 켤 것은 단 하나, `.fullSizeContentView`.

### 3) SwiftUI 의 Safe Area 와 `.ignoresSafeArea()`

`.fullSizeContentView` 를 켰는데도 SwiftUI 콘텐츠가 여전히 ~28pt 아래에서 시작한다면, **두 번째 layer 의 inset** 이 적용된 거다.

SwiftUI 는 자기만의 **safe area** 시스템을 갖고 있다 — 시스템 chrome (notch, 타이틀바, 키보드 등) 에 콘텐츠가 가려지지 않도록 자동으로 inset 을 주는 메커니즘.

```
[NSWindow content view]   ← .fullSizeContentView 로 0,0 부터 시작
  └─ [SwiftUI 가 다시 ~28pt safe area inset 적용]
      └─ [너의 ZStack]   ← 결국 ~28pt 아래에서 시작
```

iOS 비유 (가장 직관적):
- 아이폰의 **notch 영역에 글자가 가려지지 않도록** SwiftUI 가 콘텐츠를 자동 inset 해주는 그 메커니즘.
- macOS 에선 "notch" 자리에 **타이틀바** 가 있는 셈.

웹 비유:
- CSS 의 `env(safe-area-inset-top)` 가 자동 적용된 상태. 풀어주려면 명시적으로 무시해야 한다.

해결: 해당 view 에 `.ignoresSafeArea()` modifier 를 붙이면 SwiftUI 가 "이 view 는 safe area 신경 안 씀, 자유롭게 확장해" 로 판단한다.

```swift
ZStack(alignment: .topLeading) { ... }
    .ignoresSafeArea()
```

옵션도 받는다 — `.ignoresSafeArea(edges: .top)` 처럼 위쪽만 무시할 수도 있지만, 윈도우 chrome 을 통째로 제거한 우리 케이스에선 그냥 `.ignoresSafeArea()` 면 충분.

### 4) 세 레이어 정리

이번 기능을 마치려면 **세 개의 처리** 가 모두 맞아야 한다:

| 레이어 | 처리 | 효과 | 코드 위치 |
|---|---|---|---|
| AppKit (시각) | `.windowStyle(.hiddenTitleBar)` | 타이틀바 줄/제목 시각 숨김 | `JHCalendarApp.swift` (단계 1) |
| AppKit (시각) | `standardWindowButton(...).alphaValue = 0` | 트래픽라이트 시각 숨김 (단축키 유지) | `.onAppear` (단계 2) |
| AppKit (layout) | `styleMask.insert(.fullSizeContentView)` | NSWindow content view 영역을 타이틀바까지 확장 | `.onAppear` (이 단계) |
| SwiftUI (layout) | `.ignoresSafeArea()` | SwiftUI 의 자동 safe area inset 무시 | `ZStack` (이 단계) |

앞 두 개는 "안 보이게", 뒤 두 개는 "내 영역으로 끌어오게" — **AppKit 과 SwiftUI 양쪽 모두에서 풀어줘야** 한다는 점이 핵심.

## 구현 가이드

수정할 파일: `JHCalendar/ContentView.swift` (두 줄 추가 — AppKit 측 한 줄 + SwiftUI 측 한 줄).

### 어디에?

- **AppKit 측**: 이미 `.onAppear` 에서 `if let window = NSApplication.shared.windows.first { ... }` 로 window 객체를 가져오고 있다. **같은 if let 블록 안** 에 한 줄 추가하면 끝. window 를 두 번 가져올 필요 없다.
- **SwiftUI 측**: `ZStack` 자체에 modifier 한 줄 추가.

### 골격

```swift
ZStack(alignment: .topLeading) {
    // ... 단계 3 의 호버 영역 ...
}
// TODO: SwiftUI safe area 무시 modifier 추가
.onAppear {
    if let window = NSApplication.shared.windows.first {
        // TODO: styleMask 에 .fullSizeContentView 추가
        //       (힌트: OptionSet 의 .insert(_:) 사용)

        let buttonTypes: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        for buttonType in buttonTypes {
            window.standardWindowButton(buttonType)?.alphaValue = 0
        }
    }
}
```

### 힌트

- `styleMask` 에 `=` 로 덮어쓰지 말 것. 그러면 `.titled`, `.closable` 같은 다른 옵션들이 날아가서 닫기/리사이즈 등이 망가진다. 반드시 `.insert(_:)`.
- styleMask 추가 위치는 `for` 루프보다 **위** 가 자연스럽다 — 윈도우 자체 설정 → 그 윈도우의 버튼 설정 순서.
- `.ignoresSafeArea()` 는 ZStack 전체에 붙이는 게 직관적이다. `.onAppear` 와는 별개의 modifier 라 순서는 자유롭지만, **layout modifier → lifecycle modifier** 순서가 보통 더 읽기 좋다.
- 검증 순서:
  1. AppKit 측만 추가 → 빨간 박스 위치를 본다 (보통 여전히 ~28pt 밀려 있음 → SwiftUI safe area 의 존재를 체감)
  2. `.ignoresSafeArea()` 까지 추가 → (0, 0) 에 붙는지 확인
- 빨간 박스는 **검증용으로 잠깐 그대로 둔다**. layout 이 정확한지 눈으로 확인한 다음 단계 3 으로 돌아가서 `Color.clear` 로 되돌리기.

## 직접 구현하기
- [x] `.onAppear` 의 if let 블록 안, for 루프 위에 `window.styleMask.insert(.fullSizeContentView)` 한 줄 추가
- [x] 빌드/실행 → 빨간 박스 위치 확인 (실제로 여전히 ~28pt 밀려 있었음 — SwiftUI safe area 의 존재를 직접 체감)
- [x] `ZStack` 에 `.ignoresSafeArea()` modifier 한 줄 추가
- [x] 빌드/실행 → **빨간 박스가 윈도우 좌상단 (0, 0) 에 정확히 붙는지** 확인
- [x] 트래픽라이트 버튼은 여전히 안 보이는지 확인 (단계 2 효과 유지)
- [x] ⌘W / ⌘M 단축키 동작 확인 (`.titled` 등 다른 옵션이 살아있는지)
- [x] 호버 시 콘솔에 `hover: true/false` 가 찍히는지 재확인 (단계 3 효과 유지)
- [x] 모두 OK 면 `Color.red` → `Color.clear` 로 되돌리기

> 다 끝나면 알려줘.

## 자가 점검 (구현 후)
- 빨간 박스가 (0, 0) 에 붙는가?
- 단축키(⌘W, ⌘M) 가 여전히 동작하는가?
- 자문자답:
  - `styleMask = [.fullSizeContentView]` 로 했다면 어떻게 됐을까? (정답: 기존의 `.titled`, `.closable`, `.resizable` 등이 모두 사라져서 닫기/리사이즈 불가, 단축키도 잃음)
  - `.fullSizeContentView` 만 켜고 단계 1 의 `.windowStyle(.hiddenTitleBar)` 를 빼면? (정답: content 는 확장되지만 타이틀바 줄/제목이 다시 보인다 — 시각적 숨김은 별개)
  - `.fullSizeContentView` 만 켜고 `.ignoresSafeArea()` 를 빼면? (정답: AppKit 레벨에선 content 가 확장되지만, 그 위에서 SwiftUI 가 자기 safe area inset 을 적용해서 콘텐츠는 여전히 ~28pt 밀려 보인다)
  - `.ignoresSafeArea()` 만 켜고 `.fullSizeContentView` 를 빼면? (정답: SwiftUI 는 무시할 inset 자체가 없어서 변화 없음 — NSWindow content view 자체가 타이틀바 아래에서 시작하기 때문)
  - OptionSet 이 일반 enum 과 다른 점은? (정답: enum 은 한 번에 하나의 case만, OptionSet 은 여러 옵션을 동시에 보유)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `=` 가 아닌 `.insert(_:)` 로 추가됐는가
- [x] 기존 if let window 블록 안에 합쳐졌는가 (window 를 두 번 가져오지 않음)
- [x] for 루프와의 순서가 자연스러운가 (윈도우 → 버튼 순)
- [x] `.ignoresSafeArea()` 가 ZStack 에 붙었는가 (호버 영역 한 곳에만 붙이지 않음 — 전체 layout 이 확장돼야 함)
- [x] modifier 순서가 자연스러운가 (layout → lifecycle, 즉 `.ignoresSafeArea()` → `.onAppear`)
- [x] 검증 후 `Color.red` 가 `Color.clear` 로 복구됐는가

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `NSWindow.titlebarAppearsTransparent = true` 도 비슷한 맥락의 옵션 — 타이틀바 영역을 투명하게 만들어 그 아래 content 가 비치게 한다. `.fullSizeContentView` 와 함께 쓰면 시너지가 난다.
- `OptionSet` 은 직접 만들 수도 있다 (예: 권한 플래그 `[.read, .write, .admin]`). `RawRepresentable` 과 `OptionSet` 프로토콜을 채택하면 된다 — 나중에 모델 설계할 때 다시 만날 패턴.
- `.ignoresSafeArea(_:edges:)` 는 옵션을 받는다. 예: `.ignoresSafeArea(.container, edges: .top)` — 위쪽 safe area 만 무시. 우리 케이스는 윈도우 chrome 을 통째로 제거했기에 인자 없이도 충분.
- 반대 방향 도구도 있다: `.safeAreaInset(edge: ..., alignment: ...) { ... }` — 특정 변에 safe area 영역을 명시적으로 끼워넣는 modifier. 사이드바/툴바 디자인에서 다시 마주칠 패턴.
- `NSApplication.shared.windows.first` 는 macOS 14+ 에서 Scene 기반 lifecycle 과 잘 안 맞는 경우가 있다. 더 견고한 대안(`NSWindow` 를 SwiftUI 환경에서 직접 받는 방식 등) 은 후속 기능에서 다룰 수 있다.
