# iOS(iPhone) 대비 리팩토링 정리

> 날짜: 2026-05-29
> 목적: 나중에 **iOS 타겟을 추가**할 때 재사용 코드를 그대로 가져다 쓸 수 있도록,
> **재사용 계층(Shared)** 과 **플랫폼 UI 계층(Views)** 의 경계를 폴더로 명확히 분리.

핵심 원칙: SwiftUI 앱에서 iOS 포팅 시 실제로 갈리는 선은 "View vs Service"가 아니라

- **버린다(다시 그림)** = 플랫폼에 묶인 View (레이아웃·onHover·windowStyle·신호등)
- **지킨다(그대로 재사용)** = 모델 + Store + 순수 로직 + 네트워킹

그래서 이번 작업은 **새 구조를 만든 게 아니라, 이미 나뉘어 있던 경계를 폴더로 가시화**한 것이다.
(Spring으로 치면 service·domain 계층을 한 모듈로 모으고, controller·view 계층을 분리해 둔 것과 같다.)

---

## 1. 폴더 구조 변경

### Before
```
JHCalendar/
├─ JHCalendarApp.swift / ContentView.swift / Secrets.swift
└─ Features/            ← 모델·Store·로직·View가 기능별로 섞여 있음
   ├─ Event/  Sidebar/  MonthlyCalendar/  Holiday/  FloatingToolbar/  TitleBar/
```

### After
```
JHCalendar/
├─ JHCalendarApp.swift / ContentView.swift / Secrets.swift   ← macOS 앱 셸 (루트 유지)
├─ Shared/             ← ★ 플랫폼 무관, iOS 100% 재사용 가능
│  ├─ Models/          EventModels, SidebarModels, HolidayModels
│  ├─ Stores/          CalendarStore, HolidayStore
│  ├─ Logic/           CalendarMath, EventIndex, RecurrenceExpander, LunarDate
│  ├─ Networking/      HolidayAPI, HolidayCache
│  └─ Util/            ColorHex
└─ Views/              ← (구 Features) macOS 전용 UI 계층
   ├─ Event/  Sidebar/  MonthlyCalendar/  Holiday/  FloatingToolbar/  TitleBar/
```

`Features/` 디렉토리를 통째로 `Views/` 로 이름만 바꿨고, 그 안에서 재사용 파일만 빼서 `Shared/` 로 옮겼다.

---

## 2. 이동한 파일 (12개)

기능 폴더 안에서 **모델·Store·로직·네트워킹·유틸**만 골라 `Shared/` 로 이동. 내용은 그대로(ColorHex 제외).

| 분류 | 파일 | 기존 위치 → 새 위치 |
|---|---|---|
| Models | EventModels.swift | Features/Event → Shared/Models |
| Models | SidebarModels.swift | Features/Sidebar → Shared/Models |
| Models | HolidayModels.swift | Features/Holiday → Shared/Models |
| Stores | CalendarStore.swift | Features/MonthlyCalendar → Shared/Stores |
| Stores | HolidayStore.swift | Features/Holiday → Shared/Stores |
| Logic | CalendarMath.swift | Features/MonthlyCalendar → Shared/Logic |
| Logic | EventIndex.swift | Features/MonthlyCalendar → Shared/Logic |
| Logic | RecurrenceExpander.swift | Features/Event → Shared/Logic |
| Logic | LunarDate.swift | Features/Event → Shared/Logic |
| Networking | HolidayAPI.swift | Features/Holiday → Shared/Networking |
| Networking | HolidayCache.swift | Features/Holiday → Shared/Networking |
| Util | ColorHex.swift | Features/Sidebar → Shared/Util |

> `git mv` 로 옮겨서 git 히스토리가 rename으로 추적된다.

---

## 3. 코드 변경 — ColorHex 크로스플랫폼화 (유일한 실제 iOS 차단 요소)

`ColorHex.swift` 는 `import AppKit` + `NSColor` 를 썼는데, **iOS엔 NSColor가 없어 컴파일이 안 된다.**
→ macOS 경로는 **기존 그대로 보존**하고, iOS(UIKit) 분기만 추가했다.

```swift
import SwiftUI
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

func toHex() -> String {
    #if canImport(AppKit)
    // 기존 macOS 코드 그대로 (NSColor)
    #elseif canImport(UIKit)
    var r/g/b/a; UIColor(self).getRed(&r, green:&g, blue:&b, alpha:&a)
    #endif
    return String(format: "#%02X%02X%02X", ...)
}
```

- macOS 동작은 **한 글자도 안 바뀜** → 저장된 카테고리 색 데이터에 영향 없음.
- iOS 경로(UIKit)는 동등한 구현이지만 **iOS 타겟에서 실제로 한번 검증 필요** (UIColor의 색공간 처리가 NSColor와 미세하게 다를 수 있음).
- `init(hex:)` 는 원래부터 `Color(red:green:blue:)` 라 크로스플랫폼 → 변경 없음.

> 그 외 `Shared/` 의 파일들은 `Foundation` / `SwiftUI`(크로스플랫폼) 만 쓰므로 손대지 않았다.
> SwiftData(@Model)도 iOS 17+/macOS 14+ 공용이라 그대로 간다.

---

## 4. 프로젝트 파일(pbxproj) 변경

기존 기능 폴더들은 이미 `PBXFileSystemSynchronizedRootGroup`(폴더에 파일 두면 자동 인식)이라,
파일 이동은 자동으로 따라왔다. 수동 편집은 **새 `Shared/` 폴더 등록 + 폴더명 변경**뿐:

1. `Shared` 를 새 sync root group 으로 추가 (`PBXFileSystemSynchronizedRootGroup` 섹션)
2. `JHCalendar` 그룹 children + 타겟 `fileSystemSynchronizedGroups` 에 `Shared` 참조 추가
3. `Features` 그룹의 `path` 를 `Views` 로 변경

→ 개별 파일을 PBXFileReference/BuildFile 로 일일이 등록하는 구식 작업은 **불필요**했다.

---

## 5. 일부러 안 한 것 — CalendarStore 애니메이션 분리 (보류)

처음 계획엔 "CalendarStore에서 `withAnimation`/`DispatchQueue` 를 View로 빼서 Store를 순수하게" 가 있었는데, **이번엔 의도적으로 보류**했다.

**이유**
1. **iOS 차단 요소가 아니다.** `withAnimation`·`DispatchQueue` 는 macOS/iOS 공용 코드라 그대로 iOS에서도 돈다. 즉 포팅을 막지 않는다. (NSColor와 달리 "고쳐야만 컴파일되는" 문제가 아님)
2. **타이밍이 깨지기 쉽다.** `CalendarStore.prevMonth/nextMonth` 는
   `direction` 을 먼저 세팅 → 다음 런루프에서 `withAnimation { rebuild }` 하는 **2단계**로 동작한다.
   `MonthlyCalendarView` 의 슬라이드 전환(`.id(referenceDate)` + `.transition(slide)`)이 이 순서에 의존한다.
   한 트랜잭션에 합치면 전환 방향이 어긋나거나 애니메이션이 안 먹을 수 있다.
3. **눈으로 검증이 필요하다.** 슬라이드 애니메이션은 헤드리스 빌드로는 확인 불가 → 잘못 옮기면 조용히 깨진다.

**나중에 학습 단계로 하면 좋은 형태**
- Store는 데이터(`referenceDate`, `direction`)만 바꾸고, 애니메이션은 View가 건다.
- 예: 버튼에서 `withAnimation { store.nextMonth() }`, direction 선반영은 별도 처리.
- **반드시 앱 실행해서 월 이동 슬라이드 방향을 눈으로 확인**하면서 진행.

---

## 6. 빌드 검증

```
xcodebuild -project JHCalendar.xcodeproj -scheme JHCalendar -configuration Debug build
→ ** BUILD SUCCEEDED **
```

macOS 동작/구조는 그대로, 컴파일 통과 확인 완료.

---

## 7. 앞으로 iOS 타겟을 추가할 때

1. Xcode에서 새 iOS App 타겟 추가 (또는 멀티플랫폼 타겟).
2. 그 타겟의 빌드 멤버십에 **`Shared/` 폴더 전체 + `Secrets.swift`** 포함. → 모델·Store·로직·네트워킹 즉시 재사용.
3. `Views/`(macOS UI)는 iOS 타겟에 **넣지 않음**. 대신 iPhone용 UI를 새로 작성:
   - `TitleBar/`(신호등) → 불필요, `NavigationStack` 으로 대체
   - `.windowStyle(.hiddenTitleBar)`(JHCalendarApp) → iOS엔 없음
   - `onHover` → 터치엔 없음, 탭/롱프레스로 재설계
   - 사이드바·플로팅툴바·월그리드 → 좁은 화면용 레이아웃으로
4. iPad부터 붙이면 가로 화면이라 현재 구조와 가장 가까워 제일 쉽다.

## 8. 유지 규칙 (이게 이번 작업의 진짜 결론)

> **`Shared/` 안에는 `import AppKit` / `import UIKit` / `NSColor` / `windowStyle` / `onHover` 같은 플랫폼 전용 코드를 절대 넣지 않는다.**
> 새 기능을 만들 때 모델·Store·로직은 `Shared/` 의 해당 하위 폴더에, View는 `Views/` 에 둔다.
> 이 경계만 지키면 iOS 포팅은 "새로 짜기"가 아니라 "기존 로직 위에 UI만 얹기"가 된다.

---

### 참고: 손대지 않은 것
- `JHCalendarApp.swift` / `ContentView.swift` / `Secrets.swift` — 루트의 앱 셸/설정. 수동 등록 상태 그대로 유지(이동 시 pbxproj 수동 편집 위험이 있어 보류). Secrets는 플랫폼 무관이라 나중에 Shared로 옮겨도 됨.
- `CLAUDE.md` 의 디렉토리 구조/"새 기능 추가" 섹션은 아직 `Features/` 기준이라 **stale** 하다. 이번 구조에 맞게 갱신이 필요하면 알려줘.
