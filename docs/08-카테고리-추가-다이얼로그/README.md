# 08 — 카테고리 추가 다이얼로그

## 목표
사이드바 우상단 `+` 버튼을 누르면 **말풍선 모양의 작은 메뉴 (팝오버)** 가 떠서 **폴더 / 카테고리** 중 하나를 고를 수 있게 한다. 선택한 항목에 따라 **폴더 추가 다이얼로그** 또는 **카테고리 추가 다이얼로그** 가 화면 중앙에 모달로 뜬다.

- **폴더 추가** — 폴더명만 입력.
- **카테고리 추가** — 어느 폴더에 넣을지 선택 + 이름 + 12 색 팔레트.

> 이번 기능은 **UI 만**. 저장 버튼을 눌러도 실제 데이터(`folders`)엔 추가되지 않고 콘솔 `print` 만 한다. 실제 추가 로직은 다음 기능에서 (`CalendarStore` 메서드 + 호출).

## 의존 관계
- 사전 필요:
  - 기능 03 (사이드바 슬라이드) — 사이드바 컨테이너와 `@Binding` 패턴
  - 기능 04 (사이드바 카테고리 UI) — `Category`, `Folder` 모델
  - 기능 07 (사이드바 토글 다듬기) — `CalendarStore` (folders 를 들고 있는 ObservableObject)
- 이후 영향:
  - 다음 기능: 저장 버튼이 실제로 `CalendarStore.folders` 에 새 항목을 추가하도록 연결
  - 추후 "수정 / 삭제" 기능에서 동일 다이얼로그 컴포넌트 재사용 (편집 모드 추가)

## 범위
- 포함:
  - 사이드바 우상단 `+` 버튼
  - `+` 버튼에서 화살표가 튀어나온 **말풍선 팝오버** (폴더 / 카테고리 메뉴)
  - 화면 중앙 다이얼로그 (어두운 배경 + 카드)
  - 닫는 방법 3종: **취소 버튼 / 배경 클릭 / ESC 키**
  - **폴더 다이얼로그**: 이름 (`TextField`) + 저장/취소
  - **카테고리 다이얼로그**: 폴더 선택 (`Menu`) + 이름 + 12 색 팔레트 (4 × 3) + 저장/취소
  - 저장 버튼: 이름 비어있으면 disabled
- 제외 (다음 기능):
  - 실제 `folders` 배열에 추가 (`CalendarStore` 메서드 호출)
  - 수정 / 삭제

## 단계 체크리스트
- [x] 01 - 사이드바 헤더 + `+` 버튼 (메뉴 토글)
- [x] 02 - 추가 메뉴 팝오버 (말풍선)
- [x] 03 - 다이얼로그 컨테이너 + 어두운 배경 + 닫기 3종
- [x] 04 - 폴더 추가 다이얼로그 (폴더명만)
- [ ] 05 - 카테고리 추가 다이얼로그 폼 (폴더 선택 + 이름 + 12색)

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **`.popover(isPresented:, attachmentAnchor:, arrowEdge:)`** — macOS NSPopover. 시스템 제공 말풍선 + 화살표. 외부 클릭 시 자동으로 닫힘.
- **모달 overlay 패턴** — `ZStack` 위쪽 레이어로 dim 배경 + 카드. 시스템 `.sheet` 와의 차이.
- **`.onTapGesture` / 이벤트 전파** — 배경 클릭은 닫고 카드 내부 클릭은 닫지 않게.
- **`.keyboardShortcut(.cancelAction)`** — ESC 키 자동 매핑.
- **`TextField`** — Vue 의 `v-model` 과 같은 양방향 바인딩 (`text: $name`).
- **`Menu` (드롭다운)** — 카테고리 다이얼로그의 폴더 선택. macOS 시스템 메뉴 스타일.
- **`LazyVGrid` + `GridItem`** — 12 색 격자. CSS Grid `repeat(4, 1fr)` 와 유사.
- **`Color(hex:)` extension** — 임의 색 정의 + Swift extension 문법.
- **선택 상태 시각화** — `Color: Equatable` 비교 + 조건부 border/overlay.
- **`.disabled(...)`** — 조건부 버튼 비활성.
- **상태 끌어올리기 재확인** — 팝오버 상태는 Sidebar 내부 (`@State`), 다이얼로그 상태는 ContentView (`@State`) + Sidebar 로 `@Binding`. **두 상태가 다른 위치에 사는 이유** 를 짚는다.

## 파일 구조 (예정)
```
JHCalendar/Features/Sidebar/
├── Sidebar.swift                  ← 헤더 + '+' 버튼 + 팝오버 (수정)
├── SidebarModels.swift            ← 그대로
├── CategoryRow.swift              ← 그대로
├── AddMenuPopover.swift           ← 신설 (단계 02) — 폴더/카테고리 선택 메뉴
├── AddFolderDialog.swift          ← 신설 (단계 04)
├── AddCategoryDialog.swift        ← 신설 (단계 03~05)
└── CategoryColorPalette.swift     ← 신설 (단계 05) — 12 색 정의

JHCalendar/
└── ContentView.swift              ← @State 추가 + 다이얼로그 overlay (수정)
```

## 결과물 (이 기능 완료 후)
- 사이드바 우상단 `+` 버튼을 누르면 **버튼 아래에 말풍선** (둥근 사각형 + `+` 버튼 쪽으로 화살표) 이 나타나고, 그 안에 **폴더 / 카테고리** 메뉴가 있다.
- 메뉴에서 **폴더** 클릭 → 폴더명만 받는 작은 다이얼로그가 중앙에 뜸.
- 메뉴에서 **카테고리** 클릭 → 폴더 선택 + 이름 + 12색 팔레트 다이얼로그가 중앙에 뜸.
- 두 다이얼로그 모두:
  - 닫기 3종 (취소 / 배경 클릭 / ESC) 동작
  - 저장 버튼은 이름이 비어있으면 비활성, 활성 상태에서 누르면 콘솔에 `print` 후 닫힘
- 팝오버 바깥 클릭 시 팝오버는 자동으로 닫힘.
