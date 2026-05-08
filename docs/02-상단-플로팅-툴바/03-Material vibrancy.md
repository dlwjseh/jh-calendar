# 단계 3: Material 배경으로 vibrancy

## 학습 목표
- macOS 의 `Material` 시스템 이해 — 단순 색이 아닌 **뒤 배경을 흐리게 비춰주는** 반투명 재질.
- 단계 1 에서 깐 단색 배경을 `Material` 로 교체.
- 다크/라이트 모드 자동 대응을 체감.

## 사전 지식
- 단계 1, 2 가 끝난 상태: 좌상단 floating 카드 안에 사이드바 + plus 버튼 두 개가 있다.
- 현재 배경은 단색 (예: `Color.white` 또는 `Color(NSColor.controlBackgroundColor)`).

## Swift / SwiftUI 개념

### 1) Material — 무엇인가

"창 너머의 배경" 을 흐리게 비춰주는 효과. macOS 시스템 패널/사이드바/툴바가 모두 이걸 쓴다 — 그래서 데스크톱 배경 색에 따라 자연스럽게 톤이 변한다.

> Vue/JS 비유는 직접 대응이 어렵다. 비슷한 발상으로는 CSS 의 `backdrop-filter: blur(...)` 가 있다. macOS 의 Material 은 그것보다 한 단계 더 시스템 적응형이라 이해하면 좋다.

5 단계 (얇은 → 두꺼운):
- `.ultraThinMaterial`
- `.thinMaterial`
- `.regularMaterial`  ← floating 카드에 가장 무난
- `.thickMaterial`
- `.ultraThickMaterial`

### 2) 사용법

```swift
SomeView()
    .background(.regularMaterial)
```

`.background(_:)` 는 `Color`, `Material`, 그 외 다양한 `ShapeStyle` 을 받는다 — 같은 modifier 가 여러 타입을 받는 것은 SwiftUI 의 `ShapeStyle` 프로토콜 덕분.

> Java 비유: 메서드가 인터페이스 (`ShapeStyle`) 를 받기 때문에 그 인터페이스를 구현한 모든 타입을 인자로 넘길 수 있는 것과 같다.

### 3) 모서리와 함께

Material 도 `.clipShape` 로 둥글게 잘린다. 단계 1 에서 이미 깔아 둔 `.clipShape(RoundedRectangle(...))` 가 그대로 적용되므로, **추가 modifier 없이 단색 → Material 한 줄만 교체**하면 된다.

### 4) 다크/라이트 자동 대응

단색 배경은 시스템 외관 변경 시 직접 다뤄야 하지만, Material 은 자동으로 적응한다.
- 시스템 설정 → 모양 → 라이트/다크 토글
- 또는 Xcode Preview 의 `colorScheme` modifier 로 미리 확인 가능

### 5) Material 은 사실 NSVisualEffectView 의 wrapper

내부적으로 macOS 의 `NSVisualEffectView` 를 SwiftUI 로 감싼 것. SwiftUI Material 만으로 부족할 때는 `NSViewRepresentable` 로 직접 wrap 하는 패턴이 사이드바/툴바 구현에서 자주 등장 — 이번 단계에선 SwiftUI Material 한 줄로 충분.

## 구현 가이드

수정할 파일: `JHCalendar/ContentView.swift`

단계 1 에서 깐 `.background(...)` 한 줄만 교체.

```swift
// 단계 1 에서 단색이었던 것:
.background(Color.white)
// 또는
.background(Color(NSColor.controlBackgroundColor))

//                ↓ 이렇게

.background(.regularMaterial)
```

힌트:
- `.thinMaterial` 도 좋다 — 배경이 더 비치고 더 가벼워 보임. 둘 다 시도하고 선호하는 쪽으로.
- 그림자가 너무 진하면 Material 의 가벼운 느낌과 충돌한다. 단계 1 에서 grey opacity 0.2 정도였다면 0.1~0.15 로 줄여도 됨.
- 다크모드 전환 후 카드가 너무 어두워 보이면 `.thinMaterial` 로 한 단계 얇게.

## 직접 구현하기
- [x] `.background` 의 단색 인자를 Material 로 교체 (`.regularMaterial` 또는 `.thinMaterial`)
- [x] ⌘B 빌드 → ⌘R 실행
- [x] 데스크톱 배경 색이 살짝 비치는지 확인 (윈도우를 사진/컬러풀한 배경 위로 옮겨서 비교)
- [x] 시스템 설정에서 라이트 ↔ 다크 모드 전환 → 카드가 자동으로 톤이 바뀌는지 확인
- [x] (선택) 그림자 강도 미세 조정
- [ ] (선택) `.regularMaterial` ↔ `.thinMaterial` ↔ `.ultraThinMaterial` 비교

> 다 끝나면 "다 했어" 라고 알려줘. 리뷰할게.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 데스크톱 배경 위에서 카드가 약간 비쳐 보이는가?
- 다크 모드로 전환해도 카드가 자연스러워 보이는가?
- 자문자답: 왜 `.background(.white)` 대신 Material 이 macOS-native 한가? (정답: 시스템 외관·배경 변화에 자동 적응 + 다른 시스템 chrome 과 톤이 일관)
- 자문자답: `.background` 가 `Color`, `Material` 둘 다 받는 건 어떤 메커니즘 때문일까? (정답: 두 타입 모두 `ShapeStyle` 프로토콜을 구현하기 때문)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `.background(.regularMaterial)` 또는 `.thinMaterial` 로 교체됨
- [x] `.clipShape` 가 여전히 동작 (Material 도 잘림)
- [x] 다크/라이트 모드 모두 자연스러움
- [x] 그림자 강도가 Material 의 가벼움과 어울림
- [x] modifier 순서가 단계 1 에서 정한 흐름을 깨지 않음 (background 위치만 바뀜)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 더 세밀한 vibrancy 제어가 필요하면 `NSVisualEffectView` 를 `NSViewRepresentable` 로 wrap 하는 패턴: `.material` (`.sidebar`, `.titlebar`, `.menu` 등), `.blendingMode` (`.behindWindow` vs `.withinWindow`), `.state` 까지 제어 가능.
- `Material` + 호버 시 `.opacity` 또는 추가 색 overlay 로 버튼 hover 강조도 가능.
- iOS 와 같은 API 라 코드 호환성이 좋다 — 같은 ContentView 를 iPad 앱에 쓸 일이 있다면 Material 그대로 작동.
