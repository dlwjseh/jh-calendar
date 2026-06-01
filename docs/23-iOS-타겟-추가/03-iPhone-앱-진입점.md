# 단계 3: iPhone 앱 진입점 + 빈 화면

## 학습 목표
이 단계를 마치면, iOS 타겟의 **App 진입점이 우리 데이터(`Folder`/`Category`/`Event`) 와 환경(테마, HolidayStore) 을 주입한 상태**로, `NavigationStack` 안에 빈 화면("캘린더" 타이틀만) 을 띄운다. macOS 전용 API 를 일절 호출하지 않는다.

## 사전 지식
- 단계 01·02 완료 (iOS 타겟 빌드 통과)
- macOS 의 `JHCalendarApp.swift` 가 어떻게 환경을 주입했는지:
  - `@AppStorage("selectedThemeId")` 로 테마 ID 읽기
  - `HolidayStore()` 를 `@StateObject` 로 보유 → `.environmentObject(holidayStore)`
  - `.environment(\.calendarTheme, theme)` 로 테마 주입
  - `.modelContainer(for: [Folder.self, Category.self, Event.self])`
- macOS 의 `ContentView.swift` 가 호출하는 macOS-only:
  - `.windowStyle(.hiddenTitleBar)` (App 단)
  - `TrafficLightHoverArea()` (오버레이)
  - `.frame(minWidth: 900, minHeight: 600)`

## Swift / SwiftUI 개념

### `NavigationStack` (iOS 16+)
화면을 **스택으로 쌓는 iOS 표준 네비게이션 컨테이너**. macOS 는 `NavigationSplitView` 가 더 흔하지만, iPhone 폼팩터에선 `NavigationStack` 이 자연스럽다.

```swift
NavigationStack {
    SomeRootView()
        .navigationTitle("캘린더")
        .navigationBarTitleDisplayMode(.inline) // 또는 .large
}
```

- `.navigationTitle` 은 **타이틀 텍스트**, `.navigationBarTitleDisplayMode` 는 큰/작은 표시 모드.
- Push 는 `NavigationLink(destination:)` 또는 `.navigationDestination(for:)` (값 기반) — 이번엔 안 씀.

> 안드로이드의 Activity stack 비유가 가장 가깝지만, 사용자가 안 쓰는 스택이라 그냥: **"뒤로 가기 가능한 화면 스택" 컨테이너** 로 이해.

### macOS-only API 회피 패턴
같은 App 구조가 iOS 에선 다음 항목들이 **존재하지 않음**:
- `.windowStyle(...)` — iOS 는 윈도우 개념이 OS 가 관리
- `WindowGroup` 의 일부 modifier (commands, defaultSize 등)
- `onHover` — 터치엔 호버 없음
- `.frame(minWidth:minHeight:)` 는 iOS 에서 동작은 하지만 의미 없음 (화면 크기 고정)

해결: **iOS 앱 셸에선 처음부터 안 쓴다**. 같은 코드 공유가 아니라 **별도 App 파일 + 별도 루트 View** 로 시작.

### Scene Storage / App Storage
`@AppStorage` 는 iOS/macOS 공용 (`UserDefaults` 기반). 그대로 사용 가능.

## 구현 가이드

### 1. iOS App 진입점 정리 (`JHCalendar-iOS/JHCalendar_iOSApp.swift`)
Xcode 가 자동 생성한 초기 모습은 대략:
```swift
@main
struct JHCalendar_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Item.self)   // 자동 생성된 더미 모델
    }
}
```

이걸 macOS 의 `JHCalendarApp` 과 **같은 환경 구성**으로 맞춘다. macOS 와 다른 점만:
- ❌ `.windowStyle(.hiddenTitleBar)` — 제거
- ✅ 나머지(`@AppStorage`, `HolidayStore`, 테마 주입, `modelContainer`)는 동일

```swift
import SwiftUI
import SwiftData

@main
struct JHCalendar_iOSApp: App {
    @AppStorage("selectedThemeId") private var themeId = "classic"
    @StateObject private var holidayStore = HolidayStore()

    var body: some Scene {
        WindowGroup {
            let theme = resolveTheme(themeId)
            ContentView()
                .environmentObject(holidayStore)
                .environment(\.calendarTheme, theme)
                .preferredColorScheme(theme.colorScheme)
        }
        // TODO: Folder/Category/Event 모델 컨테이너
    }
}
```

힌트:
- macOS 의 `.modelContainer(for: [Folder.self, Category.self, Event.self])` 그대로 복붙.
- `resolveTheme`, `HolidayStore`, `\.calendarTheme` 는 모두 `Shared/` 에 있으니 02 단계에서 멤버십을 맞췄다면 자동 인식.

### 2. iOS 의 `ContentView` 를 비우고 NavigationStack 만 두기
자동 생성된 `JHCalendar-iOS/ContentView.swift` 의 내용은 통째로 갈아끼운다. **macOS 의 `ContentView` 를 가져오면 안 된다** — TrafficLightHoverArea, 사이드바, FloatingToolbar 등 macOS 전용 컴포넌트가 잔뜩 들어 있음.

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            Text("월간 캘린더 자리")
                .navigationTitle("캘린더")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
}
```

힌트:
- 이름이 두 타겟 모두 `ContentView` 라서 헷갈릴 수 있는데, **Target Membership 으로 격리**되어 충돌 안 함. iOS 타겟 빌드 시엔 `JHCalendar-iOS/ContentView.swift` 만 컴파일됨.
- 헷갈리면 `ContentView` 를 `IOSRootView` 같은 이름으로 바꿔도 됨 (Xcode UI 에서 자동 생성한 이름을 유지하는 것도 좋고, 본인 취향).

### 3. iOS 시뮬레이터 실행 (⌘R)
- 빈 화면에 상단 네비게이션 바 + "캘린더" 타이틀 + 가운데 "월간 캘린더 자리" 텍스트
- 다크 모드 토글(시뮬레이터 메뉴 → Features > Toggle Appearance)이 정상 반영되는지 (`preferredColorScheme` 가 주입된 덕)

## 직접 구현하기
- [ ] `JHCalendar_iOSApp.swift` 의 더미 모델 컨테이너를 우리 모델로 교체
- [ ] `@AppStorage` / `HolidayStore` / 테마 / `preferredColorScheme` 주입 (macOS 와 동일하게)
- [ ] `.windowStyle(...)` 호출 없음 확인
- [ ] iOS 의 `ContentView.swift` 를 `NavigationStack { Text(...) }` 형태로 비움
- [ ] ⌘R → iPhone 시뮬레이터에 빈 화면 + 타이틀 표시
- [ ] macOS 타겟 ⌘B → 회귀 없음

> 다 끝나면 알려주면 리뷰.

## 자가 점검 (구현 후)
- iOS 앱이 켜질 때 SwiftData 컨테이너가 정상적으로 만들어지는가? (콘솔에 SwiftData 관련 에러 없음)
- 시뮬레이터 다크 모드 토글 → 텍스트 색이 자동 반전되는가?
- 퀴즈: macOS App 과 iOS App 두 진입점이 **같은 `Folder`/`Category`/`Event` 모델**을 쓰는데, 데이터는 공유되나? (답: **공유 안 됨** — App Sandbox 가 달라 각자의 SwiftData 스토어를 가짐. 공유하려면 CloudKit 동기화 필요)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] iOS `App` 파일에 `.windowStyle` / `onHover` / `NSWindow` 등 macOS API 호출 없음
- [ ] 환경 주입(테마/HolidayStore/modelContainer) 이 macOS 와 동등
- [ ] iOS `ContentView` 가 macOS 의 ContentView 를 import/참조하지 않음 (분리 유지)
- [ ] iPhone 시뮬레이터 실행 → 빈 화면 + 타이틀 정상

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **데이터 공유**: 같은 사용자가 macOS 와 iOS 양쪽에서 같은 캘린더를 보고 싶다면 → SwiftData + CloudKit 동기화 (`ModelConfiguration(cloudKitDatabase: .private(...))` ). 이번 학습 범위 밖이지만 자연스러운 다음 주제.
- **`NavigationSplitView` vs `NavigationStack`**: iPad 가로 모드 또는 macOS 의 사이드바-디테일 패턴은 `NavigationSplitView` 가 적합. iPhone 세로면 `NavigationStack`. 두 폼팩터 다 지원하려면 `NavigationSplitView` 가 자동 적응하기도 함 — 이건 iPad 대응 단계에서.
