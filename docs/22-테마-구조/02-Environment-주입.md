# 단계 2: Environment 주입

## 학습 목표
이 단계를 마치면, 직접 만든 `CalendarTheme`을 **SwiftUI Environment에 흘려보내는 배선**을 깐다. 트리 꼭대기에서 `.classic`을 한 번 주입하고, 아무 뷰에서나 `@Environment(\.calendarTheme)`로 읽을 수 있게 된다.

## 사전 지식
- 01단계 산출물: `Shared/Theme/Theme.swift` 의 `CalendarTheme` + `.classic`
- 이미 써본 주입 방식들:
  - `@EnvironmentObject` → [07-사이드바-토글-다듬기/03-CalendarStore 도입 - ObservableObject.md](../07-사이드바-토글-다듬기/03-CalendarStore%20도입%20-%20ObservableObject.md)
  - `@Environment(\.modelContext)` (빌트인 값 읽기) → 09·10·15단계

## Swift / SwiftUI 개념
이번 새 포인트는 **커스텀 `EnvironmentKey`를 직접 정의**하는 것. (지금까진 *읽기*만 해봤지, 키를 *만들어* 본 적은 없다.)

세 가지 주입 방식을 정리하면:

| 방식 | 정체 | 쓰임 |
|---|---|---|
| `@EnvironmentObject` (07) | 참조 타입(`ObservableObject`) 주입 | **가변 공유 상태** (Store) |
| `@Environment(\.modelContext)` (09) | SwiftUI가 미리 만든 **빌트인 값** 읽기 | 시스템 제공 값 |
| `@Environment(\.calendarTheme)` ← **이번** | **내가 정의한 키**로 커스텀 값 흘리기 | **설정/구성 값** (테마) |

**언제 무엇을?**
- 자주 바뀌며 여러 곳이 구독하는 상태 객체 → `@EnvironmentObject`
- "위에서 한 번 정해 내려주는 값/설정" → 커스텀 `EnvironmentKey` + `@Environment`

테마는 후자에 가깝다(값 묶음).

> Vue 비유: `@Environment` 키 = provide 할 "키", `.environment(\.key, value)` = provide, `@Environment(\.key)` = inject.

커스텀 키의 뼈대:
```swift
// EnvironmentKey: 기본값을 반드시 제공해야 한다
private struct CalendarThemeKey: EnvironmentKey {
    static let defaultValue: CalendarTheme = .classic
}
// EnvironmentValues 에 접근자 추가 → \.calendarTheme 키패스 사용 가능
extension EnvironmentValues {
    var calendarTheme: CalendarTheme {
        get { self[CalendarThemeKey.self] }
        set { self[CalendarThemeKey.self] = newValue }
    }
}
```

## 구현 가이드
> 정답 풀코드는 없음. 위 뼈대를 참고해 직접.

**파일**: `JHCalendar/Shared/Theme/ThemeEnvironment.swift` (역시 `Shared/Theme/` → 자동 인식)

1. 위 뼈대대로 `CalendarThemeKey` + `EnvironmentValues.calendarTheme` 작성.
2. **주입** — 트리 꼭대기에 한 번:
   ```swift
   // JHCalendarApp 또는 ContentView 최상위에
   .environment(\.calendarTheme, .classic)   // TODO: 위치 정하기
   ```
3. **읽기 확인용** — 아무 뷰에 임시로:
   ```swift
   @Environment(\.calendarTheme) private var theme
   // ... 어딘가에서 theme.sunday 사용해보기 (확인 후 원복 or 03에서 본격 사용)
   ```

힌트:
- `defaultValue`가 있으니 주입을 깜빡해도, 프리뷰에서도 `.classic`으로 동작한다. 그래서 **이 단계만으로도 빌드/실행 정상**(화면 변화는 없음 — 아직 뷰가 theme를 안 쓰니까).
- 주입은 **한 곳, 최상위에서 한 번**. (provide는 트리 꼭대기)
- `private struct ...Key`로 키 타입은 외부에 숨기고, 공개 표면은 `\.calendarTheme` 키패스만.

## 직접 구현하기
- [ ] `ThemeEnvironment.swift` 에 `EnvironmentKey` + `EnvironmentValues` 확장
- [ ] 앱 루트에 `.environment(\.calendarTheme, .classic)` 주입
- [ ] 임시 뷰에서 `@Environment(\.calendarTheme)` 읽혀지는지 확인

> 다 되면 "이렇게 했어" 라고 알리면 리뷰.

## 자가 점검 (구현 후)
- 빌드/실행 통과? 화면은 그대로(정상 — 아직 미사용)
- 임시로 `theme.sunday`를 텍스트 색에 꽂아보면 적용되나?
- 퀴즈: `EnvironmentKey`가 `defaultValue`를 강제하는 이유는? / `@Environment(키)` 와 `@EnvironmentObject`는 각각 언제 쓰나?

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `defaultValue = .classic` 설정됨
- [ ] 주입이 최상위 한 곳
- [ ] 키 타입은 `private`, 공개 표면은 키패스만

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `.environment(\.calendarTheme, ...)`를 호출한 **그 지점 아래**의 뷰들만 값을 받는다. 그래서 최상위에 둬야 전체가 받는다. 중간에서 다시 주입하면 그 서브트리만 다른 테마로 덮을 수도 있다(나중에 부분 미리보기 등에 응용 가능).
