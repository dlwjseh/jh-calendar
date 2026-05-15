# 무테두리 시간 입력 — NSDatePicker AppKit 브리지

## 목표
SwiftUI 기본 `DatePicker` 는 `.field`/`.compact` 스타일에 **테두리·배경(chrome)이 내장**돼 있어 제거가 안 된다. macOS 기본 캘린더처럼 **테두리 없이, 세그먼트 클릭 → 키보드로 바로 입력**되는 시간 입력을 만들기 위해, `NSViewRepresentable` 로 AppKit 의 `NSDatePicker` 를 직접 감싸 `isBordered = false` 로 끈다. 더불어 SwiftUI ↔ AppKit **양방향 바인딩**(Coordinator 패턴)을 익힌다.

## 의존 관계
- 사전 필요: `10` (AddEventDialog — 시작/시간 입력 행이 이미 있음), `@State`/`@Binding` (01)
- 이후 영향: 종료 시각·날짜 입력도 같은 컴포넌트 재사용. 향후 AppKit 위젯(NSColorWell, NSTextView 등)을 SwiftUI 에 끌어올 때 같은 패턴 재적용.

## 왜 이 단계가 생겼나 (배경)
10 단계에서 시작 시간을 `DatePicker(...).datePickerStyle(.field)` 로 인라인 배치했더니:
1. 둥근 회색 박스(chrome)가 다이얼로그 본문에 박혀 보임 — `.background`/`.overlay` 로 못 지움
2. 그 박스의 내부 padding 때문에 옆 날짜 `Text` 와 **세로 정렬이 어긋남**

→ 순수 SwiftUI `DatePicker` 의 한계. AppKit 레벨에서 `isBordered`/`drawsBackground` 를 꺼야만 해결됨 → 본 단계.

## 단계 체크리스트
- [ ] 01 - NSViewRepresentable 단방향 (무테두리 피커 띄우기)
- [ ] 02 - Coordinator 로 양방향 바인딩 완성
- [ ] 03 - AddEventDialog 통합 + 날짜·시간 공용화

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **`NSViewRepresentable`** — SwiftUI(선언형) 안에서 AppKit(명령형) 뷰를 쓰게 해주는 어댑터. `makeNSView` / `updateNSView` 라이프사이클.
- **Coordinator 패턴** — AppKit 의 target/action·delegate 콜백을 받아 SwiftUI `@Binding` 으로 되돌리는 중개 객체. `makeCoordinator()`.
- **Objective-C 런타임 상호작용** — `NSObject` 상속, `@objc`, `#selector`. 왜 필요한지(target/action 이 런타임 기반).
- (응용) 단방향 vs 양방향 데이터 흐름을 직접 배선해보며 SwiftUI 바인딩의 내부 감각 익히기.

## 자바/스프링·Vue 비유 한 줄 매핑
| 다른 기술 | 이 단계에 대응 |
|---|---|
| Vue: 네이티브/jQuery 위젯을 `ref` 로 감싸 `change` → `emit('update:modelValue')` 하는 래퍼 컴포넌트 | `NSViewRepresentable` + Coordinator |
| Java: 프레임워크 ↔ 네이티브 사이 JNI 브리지 | SwiftUI ↔ AppKit 브리지 |
| Java: `@Override` 가 컴파일러용 표식이듯, `@objc` 는 "이 메서드를 ObjC 런타임에 노출" 표식 | `@objc func changed(_:)` |
| Java: 메서드 레퍼런스 `Coordinator::changed` | `#selector(Coordinator.changed(_:))` |
| Spring: 이벤트 리스너 빈이 콜백을 받아 모델 갱신 | Coordinator 가 action 받아 `@Binding` 갱신 |
