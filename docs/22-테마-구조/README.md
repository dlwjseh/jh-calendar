# 22 - 테마 구조

## 목표
UI 골격(레이아웃·간격·폰트)은 그대로 두고 **색만 테마로 갈아끼울 수 있는 구조**를 만든다.
이번엔 **구조까지만** — 실제 테마 추가와 각 테마의 색 결정은 추후(04 단계가 연결점).

## 의존 관계
- 사전 필요: `Shared/` · `Views/` 폴더 구조(완료), 여러 View에 흩어진 색 사용처
- 이후 영향: 새 테마 추가(색만 채우면 됨), 다크모드 커스텀 등

## 핵심 발상 한 줄
흩어진 색 리터럴(`.red`/`.blue`/`Color.holiday`/`gray.opacity`) → **의미론적 슬롯**(`CalendarTheme`)으로 모으고 → SwiftUI **Environment**로 트리 꼭대기에서 한 번 주입 → 모든 뷰가 거기서 읽는다.

> Vue 의 provide/inject, Spring 의 컨텍스트 주입과 같은 발상. "색을 어디서 가져올지"를 뷰마다 정하지 않고, 위에서 한 번 내려준다.

## 테마가 다루는 색 / 안 다루는 색
- ✅ **UI 크롬**: 주말 빨강/파랑, 오늘 표시, 공휴일, 그리드 선, 텍스트 색
- ❌ **사용자 카테고리 색**(`category.color`, `CategoryColorPalette`): 사용자가 직접 고르는 **데이터** → 테마가 건드리지 않는다

## 의미론적 슬롯 (현재 색 → 슬롯 매핑)
| 슬롯 | 현재 색 | 쓰는 곳 |
|---|---|---|
| `sunday` | `.red` | 일요일·공휴일 날짜 숫자, 일요일 헤더 |
| `saturday` | `.blue` | 토요일 날짜·헤더 |
| `weekdayText` | `.primary` | 평일 숫자/이벤트명 |
| `subtleText` | `.secondary` | 이전·다음달, 보조 텍스트, 평일 헤더 |
| `todayFill` | `.red` | 오늘 동그라미 배경 |
| `todayText` | `.white` | 오늘 숫자 |
| `holiday` | `Color.holiday`(토마토) | 공휴일 이름 라벨 |
| `gridLine` | `gray.opacity(0.2)` | 셀 경계선 |
| `accent` | `Color.accentColor` | 저장 버튼 등 강조 |

> 배경(`.background`/머티리얼)·그림자·호버는 라이트/다크 자동 대응이라 **1차에선 테마 제외**. 위 9개 슬롯만 잡는다(나중에 확장 가능).

## 단계 체크리스트
- [ ] 01 - 테마 모델 (`CalendarTheme` + `.classic`)
- [ ] 02 - Environment 주입 (커스텀 `EnvironmentKey`)
- [ ] 03 - 뷰 색 교체 (하드코딩 → `theme.xxx`)
- [ ] 04 - (선택/추후) 테마 전환 골격 (`@AppStorage` 선택 + 루트 재주입)

이번 목표는 **01~03**. 04는 테마/색 고민이 끝나면 진행하는 연결점만 남겨둔다.

## 이 기능에서 학습할 Swift / SwiftUI 개념
- 의미론적 색 추상화 — 값 타입 `struct`로 "설정 묶음" 만들기
- SwiftUI **Environment 시스템**: 커스텀 `EnvironmentKey` + `EnvironmentValues` 확장
- `@Environment(\.커스텀키)` 로 읽기 — 기존 `@EnvironmentObject`(07단계)·`@Environment(\.modelContext)`(09단계)와의 차이
- (04) `@AppStorage`로 선택 영속화 — 20단계에서 다룸, 링크만
