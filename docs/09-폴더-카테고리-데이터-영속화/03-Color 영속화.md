# 단계 3: Color 영속화 (hex 변환)

## 학습 목표
- SwiftData 가 직접 저장할 수 없는 타입(`Color`)을 **저장 가능한 형태(hex `String`)** 로 우회하는 패턴을 익힌다.
- 저장은 String, UI 노출은 `Color` 인 **computed property** 분리 방식을 적용한다.

## 사전 지식
- 2단계 산출물 — `Category` 가 `@Model` 로 전환되어 있어야 함
- `Color` 의 기본 사용 → [04-사이드바-카테고리-UI](../04-사이드바-카테고리-UI) / [06-주말-색상](../06-주말-색상) 참고
- `@Model`, `@Relationship` → [02-Category @Model + Relationship.md](./02-Category%20@Model%20%2B%20Relationship.md) 참고

## Swift / SwiftUI 개념

### 1) 왜 `Color` 는 그대로 저장 못 하나
SwiftData 는 내부적으로 SQLite 에 저장한다. 기본 지원 타입은 String / Int / Double / Bool / Date / UUID / Data / 위 타입들의 옵셔널·배열, 그리고 다른 `@Model`. `Color` 는 SwiftUI 의 시각 표현용 wrapper 라 자체 직렬화가 안 된다.

### 2) 우회 패턴: 저장은 평문 + 노출은 computed

Spring 에서 `LocalDateTime` 을 그대로 JSON 직렬화 못 할 때 `@JsonSerialize` 로 String 변환하는 패턴과 비슷. **저장 프로퍼티는 원시 타입, 도메인 API 는 변환된 값**.

```swift
@Model
final class Category {
    var name: String
    var isChecked: Bool
    var colorHex: String          // ← 실제 저장
    var folder: Folder?

    init(name: String, color: Color, isChecked: Bool = true) {
        self.name = name
        self.isChecked = isChecked
        self.colorHex = color.toHex()   // 헬퍼 호출
    }

    var color: Color {                 // ← UI 에서 쓰는 것
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() }
    }
}
```

> 주의: SwiftData 는 `@Model` 클래스의 **저장 프로퍼티만** 영속화한다. `var color: Color { ... }` 처럼 computed 면 자동으로 제외된다 — 우리가 원하는 그림.

### 3) `Color` ↔ hex 변환 — NSColor 경유

macOS 에서 SwiftUI `Color` 의 RGB 성분을 꺼내려면 `NSColor` 로 한 번 변환하는 게 가장 안정적이다 (Color 자체에는 component 접근 API 가 빈약).

핵심 흐름:
1. `NSColor(color).usingColorSpace(.sRGB)` 로 sRGB 공간 NSColor 얻기
2. `.redComponent` / `.greenComponent` / `.blueComponent` 에서 0~1 값 추출
3. 0~255 정수로 변환 후 `String(format: "#%02X%02X%02X", r, g, b)`

반대 방향(hex → Color)은 String 파싱:
1. `#` 떼고 16진수 6자리 → UInt32
2. 비트 시프트 + 마스킹으로 R/G/B 추출
3. `Color(red: r, green: g, blue: b)` 에 0~1 스케일로 전달

## 구현 가이드

### 파일 변경 계획
- **새 파일** `JHCalendar/Features/Sidebar/ColorHex.swift` — `Color` 의 hex 변환 헬퍼 (`extension Color`)
- `SidebarModels.swift` — `Category` 에 `colorHex: String` 저장 프로퍼티 추가, `var color: Color { get/set }` computed 노출
- `CategoryColorPalette.swift` — 팔레트가 지금 `Color` 배열이라면 그대로 둬도 되고, 미리 hex 로 정의해두면 일관성 ↑

### 핵심 골격

```swift
// ColorHex.swift
import SwiftUI
import AppKit

extension Color {
    func toHex() -> String {
        // TODO: NSColor 로 변환 → sRGB component → "#RRGGBB" 문자열
        return "#000000"
    }

    init(hex: String) {
        // TODO: "#RRGGBB" → 정수 파싱 → Color(red:green:blue:)
        // 잘못된 입력에도 크래시 없이 기본색(예: .gray) 으로 폴백
        self = .gray
    }
}
```

### 막힐 만한 지점 — 힌트

- **`NSColor(color)` 가 nil 처럼 보일 수 있다** — system color (`.red`, `.blue`) 는 대부분 잘 변환되지만, 다이나믹 색상(다크모드 변형 등) 은 색공간을 명시해야 안전하다. 항상 `.usingColorSpace(.sRGB)` 거치자.
- **0~1 vs 0~255 헷갈림** — NSColor 의 component 는 0~1 (CGFloat). 정수 hex 만들 때 `Int(round(r * 255))` 처럼 명시적으로 변환.
- **`Scanner` 로 hex 파싱하는 게 깔끔** — `var n: UInt64 = 0; Scanner(string: cleaned).scanHexInt64(&n)` 한 줄.
- **흐릿한 색감이 나오면** color space 가 generic 으로 잡혔을 가능성 — sRGB 변환 누락 의심.
- 영속된 hex 의 대소문자/유무 (`"FF0000"` vs `"#ff0000"`) 에 너그럽게: 파싱 전 `replacingOccurrences(of: "#", with: "")` + `uppercased()`.

### 카테고리 팔레트 일관성

`CategoryColorPalette.all` 에 정의된 12색을 hex 로 한 번 굴려보고 다시 Color 로 복원했을 때 시각적으로 같아 보이는지 눈으로 확인. 안 같으면 색공간 변환에서 손실이 있다는 신호.

## 직접 구현하기
- [ ] `ColorHex.swift` 작성 (`Color.toHex()`, `Color.init(hex:)`)
- [ ] `Category` 에 `colorHex: String` 저장 + `var color: Color` computed 추가
- [ ] `Category.init` 이 `Color` 를 받아 내부에서 hex 로 변환
- [ ] `CategoryRow` / `AddCategoryDialog` 등 사용처가 여전히 `category.color` 를 자연스럽게 쓰는지 확인
- [ ] 빌드 통과 + (다음 단계에서 실제 추가/저장하면 색이 살아 있는지 검증 가능)

## 자가 점검
- `Color.red.toHex()` 의 결과를 `print` 해보고 `#FF0000` 근방이 나오는가?
- `Color(hex: "#3478F6").toHex()` 가 다시 `#3478F6` 으로 되돌아오는가? (라운드트립)
- 이해도 퀴즈
  1. 왜 저장 프로퍼티는 String 이고 도메인 API 는 computed `Color` 로 분리했는가?
  2. computed property 가 SwiftData 의 자동 영속화에서 제외되는 이유는?

## Claude 리뷰 체크리스트
- [ ] `Color.toHex()` / `Color.init(hex:)` 가 sRGB 색공간 변환을 명시하고 폴백을 가짐
- [ ] `Category.colorHex` 가 저장 프로퍼티이고 `color` 는 computed
- [ ] 사용처 코드가 hex 노출 없이 그대로 `Color` 를 쓰고 있음

## 회고
> *(직접 채우는 영역)*

## 조금 더 (선택)
- iOS 17+ 에서는 `CodableColor` 같은 wrapper 를 만들고 `@Attribute(.transformable(by:))` 로 직접 매핑하는 방식도 있음. 학습 후 비교해보면 재미있는 주제.
