# 23 - iOS 타겟 추가

## 목표
현재 macOS 전용 프로젝트에 **iOS App 타겟**을 추가하고, **iPhone 시뮬레이터에서 월간 캘린더가 (조회만) 보이는 상태**까지 도달한다.
이번엔 **타겟 추가 + 최소 화면**까지. 사이드바·이벤트 추가/편집·다이얼로그의 iPhone 적응은 별도 기능(24~)으로 분리.

## 의존 관계
- 사전 필요: `Shared/` 분리 완료(`iOS-리팩토링-정리.md`), `Views/` 의 macOS 전용 UI 격리 완료, `ColorHex` 의 `#if canImport(UIKit)` 분기(이미 들어가 있음 — 실전 검증은 02에서)
- 이후 영향: iPhone 사이드바, iPhone 이벤트 다이얼로그, iPhone 일 팝업 등 **iOS UI 작업의 기반**

## 핵심 발상 한 줄
**모델·Store·로직은 그대로 재사용**, **UI는 새로 짠다.** 두 타겟이 한 프로젝트 안에서 `Shared/` 만 공유하고 각자의 View 폴더를 갖는 멀티 타겟 구조.

> Spring 비유: 하나의 멀티 모듈 프로젝트에서 `core` 모듈(도메인·서비스)은 공유하고, `web-api` / `web-admin` 컨트롤러 모듈만 별도로 두는 것.

## 폴더 배치 (이번 작업으로 만들어질 구조)
```
JH-CALENDAR/
├─ JHCalendar.xcodeproj/
├─ JHCalendar/                   ← macOS 타겟 (기존)
│  ├─ JHCalendarApp.swift
│  ├─ ContentView.swift
│  ├─ Secrets.swift
│  ├─ Shared/                    ← ★ 두 타겟이 공유 (멤버십 양쪽 다)
│  └─ Views/                     ← macOS 전용 UI
└─ JHCalendar-iOS/               ← ★ 새 iOS 타겟 폴더 (Xcode 가 자동 생성)
   ├─ JHCalendar_iOSApp.swift    ← iOS 앱 진입점
   ├─ ContentView.swift          ← iOS 루트 (NavigationStack)
   └─ Views/                     ← iOS 전용 UI (월간 캘린더 등)
```

> "Option A — `ViewsIOS/` 신설" 의 실전 형태. Xcode 가 새 타겟을 만들 때 **타겟명 기준 폴더를 자동 생성**하므로, 그 폴더가 곧 iOS UI 의 자리가 된다.

## 단계 체크리스트
- [ ] 01 - iOS 타겟 추가 (Xcode 멀티 타겟 + Target Membership)
- [ ] 02 - Shared 코드 iOS 빌드 통과 (`#if canImport(...)` 실전 검증)
- [ ] 03 - iPhone 앱 진입점 + 빈 화면 (`NavigationStack`, macOS-only API 회피)
- [ ] 04 - iPhone 월간 캘린더 표시 (조회 전용, Shared 로직 재활용)
- [ ] 05 - 시뮬레이터 실행 확인 + 회고 (Run Destination, 시뮬레이터/실기기)

## 이 기능에서 학습할 Swift / SwiftUI 개념
- Xcode **멀티 타겟** 구조와 **Target Membership** (어떤 파일이 어떤 타겟에 들어가는가)
- `#if canImport(UIKit)` / `#if os(iOS)` **조건부 컴파일** 실전 (지금까진 `ColorHex` 안에 한 번만 등장)
- iOS SwiftUI 차이: `NavigationStack`, safe area, iOS 에 없는 macOS API (`.windowStyle`, `onHover`, traffic light) 회피
- iOS 적응형 레이아웃 — 좁은 화면에 월간 그리드 맞추기
- Xcode **Run Destination** (시뮬레이터 / 실기기 전환)

## 이 기능에서 일부러 안 하는 것
- **이벤트 추가/편집 다이얼로그 iPhone 적응** — 다음 기능
- **사이드바 (카테고리/폴더) iPhone 적응** — 다음 기능
- **일 팝업 iPhone 적응** — 다음 기능
- **실제 디바이스 배포(App Store / TestFlight)** — 학습 범위 밖. 5단계에서 "자유 계정으로 본인 폰에 설치"까지만(선택).
