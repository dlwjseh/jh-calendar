# 단계 1: iOS 타겟 추가

## 학습 목표
이 단계를 마치면, Xcode 프로젝트 안에 **두 번째 타겟(iOS App)** 이 생기고, 그 타겟이 **빈 상태로 iPhone 시뮬레이터에서 빌드 성공** 한다. Target Membership 개념과 멀티 타겟의 폴더/스킴 구조를 이해한다.

## 사전 지식
- 현재 프로젝트는 macOS 타겟 **하나**만 있음 (`SDKROOT = macosx`, `MACOSX_DEPLOYMENT_TARGET = 15.0`)
- `Shared/` ↔ `Views/` 분리는 완료 — `iOS-리팩토링-정리.md` 참고
- 코드는 한 줄도 안 짠다. **Xcode UI 조작 + 빌드 확인** 단계.

## Swift / SwiftUI 개념

### Xcode 멀티 타겟이란
한 `.xcodeproj` 안에 **여러 빌드 산출물**(앱·프레임워크·CLI 등)이 공존할 수 있다. 각 산출물 = **타겟(Target)**. 이번엔 `JHCalendar` (macOS App) 옆에 `JHCalendar-iOS` (iOS App)를 추가한다.

> Spring/Maven 비유: 하나의 부모 POM 아래 여러 모듈이 있는 것. 단, 여기선 **소스 파일은 공유**하고 어떤 파일이 어떤 산출물에 들어갈지를 **Target Membership** 으로 고른다.

### Target Membership
파일 하나가 **어느 타겟의 빌드에 포함될지**를 결정하는 체크박스. Xcode 의 File Inspector(오른쪽 패널) 에서 본다.
- 예: `EventModels.swift` → macOS ✓ / iOS ✓ (둘 다 사용)
- 예: `TrafficLightController.swift` → macOS ✓ / iOS ✗ (AppKit 의존, iOS 에선 빌드 불가)
- 예: `JHCalendar_iOSApp.swift` → macOS ✗ / iOS ✓ (iOS 진입점)

### Sync Group 과 Target Membership 의 관계
`Shared/`, `Views/<Feature>/` 폴더들은 `PBXFileSystemSynchronizedRootGroup` (sync group) 이다.
- sync group 은 "폴더에 파일을 두면 자동 인식" 까진 해주지만, **어떤 타겟에 들어갈지는 별도**.
- 새 iOS 타겟이 `Shared/` 를 쓰려면 **그 타겟의 `fileSystemSynchronizedGroups` 에 `Shared` 참조를 추가**해야 한다. Xcode UI 에서 Shared 폴더 선택 → File Inspector → Target Membership 에서 iOS 타겟 체크.

### SDK / Deployment Target
- **SDK** (`SDKROOT`): 어떤 OS 의 API 를 쓰느냐. 타겟별로 `macosx`, `iphoneos` 등 다름.
- **Deployment Target**: 최소 지원 OS 버전. iOS 는 17.0 이상 권장 (SwiftData 가 17+ 부터).

## 구현 가이드

> 모두 **Xcode UI 조작**. 코드 작성 없음.

### 1. iOS 타겟 추가
Xcode 메뉴 → **File > New > Target...**
- Platform: **iOS**
- Template: **App**
- Next →
  - Product Name: `JHCalendar-iOS` (또는 원하는 이름. 단 하이픈/언더스코어 주의 — Swift 식별자로 변환 시 `_` 로 바뀜)
  - Team: 본인 계정 (없으면 None 으로 진행 가능, 실기기 배포만 안 됨)
  - Organization Identifier: 기존과 동일 (`com.jh`)
  - Bundle Identifier: 자동으로 `com.jh.JHCalendar-iOS`
  - Interface: **SwiftUI**
  - Language: **Swift**
  - Storage: **SwiftData** (체크. macOS 와 동일한 SwiftData 모델 공유 위함)
  - Include Tests: 체크 해제 (이번 학습엔 불필요)
- Finish

### 2. 생성된 것 확인
프로젝트 루트에 **새 폴더 `JHCalendar-iOS/`** 가 생긴다. 안에:
- `JHCalendar_iOSApp.swift` — iOS 앱 진입점 (이름은 자동 생성)
- `ContentView.swift` — 기본 "Hello, world" 화면
- `Assets.xcassets` — iOS 전용 에셋
- `JHCalendar-iOS.entitlements` — iOS 권한 설정

> 폴더명에 하이픈이 있어 Swift 파일명은 `_` 로 치환된다. 정상.

### 3. Run Destination 을 iPhone 시뮬레이터로 변경
Xcode 상단 스킴 선택기 옆 디바이스 드롭다운:
- 스킴: `JHCalendar-iOS` 선택 (새 타겟용 스킴이 자동 생성됨)
- 디바이스: **iPhone 16** (또는 임의의 iOS 시뮬레이터)

### 4. 빌드만 (⌘B)
이 단계에선 **실행까지 안 가도 된다.** "Build Succeeded" 가 뜨는지만 확인.
- 만약 SwiftData 관련 에러가 나면, `JHCalendar_iOSApp.swift` 의 `.modelContainer(for: Item.self)` 부분이 자동 생성된 더미 모델(`Item`) 참조라 그렇다. **이번 단계에선 그대로 두고 빌드만 통과시킨다** (자동 생성 그대로). 우리 모델(`Folder`, `Category`, `Event`)로 교체하는 건 03 단계에서.

### 5. (확인용) macOS 타겟도 여전히 빌드되는지
스킴을 다시 `JHCalendar` (macOS) 로 바꾸고 ⌘B. 둘 다 빌드 통과해야 함.

## 직접 구현하기
- [ ] File > New > Target 으로 iOS App 타겟 추가 (`JHCalendar-iOS`)
- [ ] Storage: SwiftData 체크, Tests 체크 해제
- [ ] 새 폴더 `JHCalendar-iOS/` 생성 확인
- [ ] iPhone 시뮬레이터로 Run Destination 변경
- [ ] iOS 타겟 ⌘B → Build Succeeded
- [ ] macOS 타겟 ⌘B → Build Succeeded (기존 동작 안 깨졌는지)

> 다 끝나면 "다 했어" 또는 막힌 부분 알려주면 리뷰.

## 자가 점검 (구현 후)
- Xcode Project Navigator(왼쪽) 에 `JHCalendar` 와 `JHCalendar-iOS` 두 폴더가 보이는가?
- 상단 스킴 드롭다운에서 두 스킴이 보이는가?
- iOS 타겟 빌드 시 시뮬레이터 다운로드를 요구하면, 한 번 받아두면 된다 (몇 GB).
- 퀴즈: 같은 `EventModels.swift` 파일이 두 타겟 모두에서 빌드되려면 무엇을 설정해야 하나? (답: Target Membership 양쪽 체크)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] 새 타겟 `JHCalendar-iOS` 가 pbxproj 에 등록됨
- [ ] iOS 타겟 SDK 가 `iphoneos`, Deployment Target 이 17+
- [ ] 두 타겟 모두 빌드 통과
- [ ] macOS 동작/구조에 영향 없음 (회귀 없음)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **멀티플랫폼 단일 타겟 vs 분리 타겟**: Xcode 14+ 부터 "한 타겟에서 macOS·iOS 동시 지원" 도 가능(Multiplatform App 템플릿). 코드 공유는 편하지만 폴더가 한 곳이라 **플랫폼별 UI 격리가 약해진다**. 우리는 학습 목적상 **분리 타겟** 으로 가서 경계를 눈으로 명확히 본다.
- pbxproj 의 `PBXNativeTarget` 두 개가 어떻게 다르게 생겼는지 한번 열어보면 멀티 타겟의 실체가 보인다.
