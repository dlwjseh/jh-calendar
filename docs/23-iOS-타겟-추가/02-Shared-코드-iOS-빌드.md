# 단계 2: Shared 코드 iOS 빌드 통과

## 학습 목표
이 단계를 마치면, `Shared/` 의 **모든 파일이 iOS 타겟의 빌드에 포함되고 컴파일 통과** 한다. 도중에 마주칠 플랫폼 의존 코드는 `#if canImport(...)` 로 분기해 해결한다.

## 사전 지식
- 단계 01 완료 (iOS 타겟 존재)
- `Shared/` 폴더 구성 — `Models/`, `Stores/`, `Logic/`, `Networking/`, `Util/`, `Theme/`
- `ColorHex.swift` 는 이미 `#if canImport(AppKit) ... #elseif canImport(UIKit) ...` 분기되어 있음 (이전 리팩토링)

## Swift / SwiftUI 개념

### 조건부 컴파일 `#if canImport(...)` / `#if os(...)`
컴파일러 지시문으로 **현재 빌드 타겟에서 해당 모듈이 import 가능한지** 보고 코드 블록을 켜고/끈다.

```swift
#if canImport(AppKit)
import AppKit
let color = NSColor.red       // macOS 에서만 컴파일
#elseif canImport(UIKit)
import UIKit
let color = UIColor.red       // iOS 에서만 컴파일
#endif
```

- `canImport(AppKit)` ≈ macOS, `canImport(UIKit)` ≈ iOS/iPadOS/tvOS/visionOS
- `os(macOS)` / `os(iOS)` 도 있음. 더 명시적이지만, UI 프레임워크 의존이면 `canImport` 가 의도가 더 분명.
- 컴파일 단계에서 제거되므로 런타임 비용 없음. (Spring 의 `@Profile` 과 달리 **컴파일 타임** 분기)

> Java 엔 동일 개념 없음. 굳이 비유하면 **빌드 프로필별 src 디렉토리 분리** (e.g. Maven `src/main/jvm` vs `src/main/android`) 와 비슷한 목적을 한 파일 안에서 해결.

## 구현 가이드

### 1. Shared/ 폴더를 iOS 타겟에 등록
**가장 빠른 방법** — Project Navigator 에서 `Shared` 폴더(노란 폴더 아이콘) 선택 → File Inspector → **Target Membership** 에 `JHCalendar-iOS` 체크.
- `Shared/` 가 sync group 이므로 **하위 파일 전부가 자동으로 iOS 타겟 멤버십 획득**.
- 개별 파일 하나하나 체크 안 해도 됨.

`Secrets.swift` 도 iOS 가 (HolidayAPI 키 때문에) 필요하므로 같이 멤버십 추가.

### 2. iOS 타겟 빌드 → 에러 잡기
⌘B 로 iOS 타겟 빌드. **십중팔구 에러가 난다.** 종류별로:

#### (a) `NSColor`/`NSImage`/`NSEvent` 같은 AppKit 타입 → 조건부 컴파일 필요
- 해결: `#if canImport(AppKit) ... #endif` 로 감싸고 iOS 쪽 분기 추가(필요시).
- `ColorHex.swift` 는 이미 처리됨. **다른 곳에 AppKit 잔재가 남아 있는지 점검**.

#### (b) `windowStyle` / `onHover` / `Window` Scene 등
- 이건 **`Shared/` 안에 있으면 안 되는 코드**. `Views/` 로 옮기거나, 이미 `Views/` 에 있으면 무시. (`Views/` 는 iOS 멤버십 추가 안 함)

#### (c) SwiftData 관련
- `@Model`, `@Query`, `ModelContainer` 는 iOS 17+/macOS 14+ 공용 → **그대로 동작**해야 함. 에러가 난다면 Deployment Target 확인.

### 3. ColorHex iOS 동작 검증
컴파일은 통과해도 실제 iOS 에서 동작이 맞는지 확인 필요(`UIColor` 의 색공간 처리가 미세하게 다를 수 있음).

검증 방법 — `Shared/Util/ColorHex.swift` 옆에 임시 Preview 또는 03 단계에서 화면에 띄울 때 카테고리 색이 macOS 와 같은지 눈으로.
- 이번 단계에선 **빌드 통과까지만**. 시각 검증은 04 단계에서 카테고리 색이 정상적으로 보이는지로 자연스럽게.

### 4. 에러가 안 나는 게 정상적인 시나리오
이전 리팩토링(`iOS-리팩토링-정리.md`) 때 이미 `Shared/` 를 정리했으니, **추가 분기 없이 그대로 빌드 통과**할 가능성이 높다.
- 그러면 이 단계의 **학습 포인트는 "왜 통과하는지" 를 설명할 수 있는 것**: Foundation/SwiftUI/SwiftData 가 크로스플랫폼이고, AppKit 잔재가 한 곳(`ColorHex`) 만 있었고 그건 이미 분기됨.

## 직접 구현하기
- [ ] `Shared/` 폴더 Target Membership → iOS 타겟 추가
- [ ] `Secrets.swift` Target Membership → iOS 타겟 추가
- [ ] iOS 타겟 ⌘B
- [ ] 에러 발생 시: 어떤 파일/어떤 타입 때문인지 한 줄로 정리하고 → `#if canImport(...)` 분기로 해결
- [ ] iOS 타겟 ⌘B → Build Succeeded
- [ ] macOS 타겟 ⌘B → 회귀 없음 확인

> 다 끝나면 알려주면 리뷰. 만약 에러가 한 건도 없으면 그것도 보고("그대로 통과했어").

## 자가 점검 (구현 후)
- 빌드 통과한 후, `Shared/` 안에 `import AppKit` 또는 `import UIKit` 가 **분기 없이** 등장하는 파일이 있는가? → 있으면 잠재적 폭탄.
- 퀴즈: `#if os(macOS)` 와 `#if canImport(AppKit)` 의 차이는? (답: 전자는 OS, 후자는 모듈 존재. Catalyst 같은 환경에선 macOS 에서 UIKit 도 import 가능 → 의도에 따라 골라 쓴다)
- 퀴즈: iOS 타겟이 `Shared/` 의 모든 파일을 컴파일하는데, 그 안의 `ContentView.swift` (macOS 루트)는 왜 안 들어가는가? (답: 루트의 `ContentView.swift` 는 `JHCalendar/` 직속이고 `Shared/` 가 아니라서 iOS 타겟에 추가되지 않았기 때문)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `Shared/` 의 iOS 타겟 멤버십이 sync group 레벨에서 추가됨 (개별 파일 멤버십 산발 X)
- [ ] 새 `#if canImport(...)` 분기가 들어갔다면 macOS 경로가 깨지지 않았는지
- [ ] iOS 빌드 + macOS 빌드 양쪽 통과
- [ ] `Shared/` 안에 분기 없는 AppKit/UIKit import 없음

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **Build Settings 비교** — 두 타겟의 `SDKROOT`, `SUPPORTED_PLATFORMS`, `TARGETED_DEVICE_FAMILY` 가 어떻게 다른지 한 번 보면 멀티 타겟의 빌드 분리가 구체적으로 보인다.
- **iOS 에서 NSColor 없는 게 왜인지** — AppKit 자체가 iOS 에 없는 프레임워크. iOS 는 UIKit. SwiftUI 가 둘을 추상화해주지만, 색의 RGB 추출처럼 추상 너머의 API 가 필요할 땐 분기 불가피.
