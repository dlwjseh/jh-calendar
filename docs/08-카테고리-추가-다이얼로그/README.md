# 08 — 카테고리 추가 다이얼로그

## 목표
사이드바 우상단 `+` 버튼을 누르면 **화면 중앙에 다이얼로그가 뜨고 배경이 어두워지는** 모달 UI 를 만든다. 다이얼로그 안에서 **카테고리 이름** 을 입력하고 **12 색 팔레트** 에서 색을 골라 "저장 / 취소" 할 수 있다.

> 이번 기능은 **UI 만**. 저장 버튼을 눌러도 실제 카테고리 배열에는 추가되지 않고 콘솔 `print` 만 한다. 실제 추가 로직은 다음 기능에서.

## 의존 관계
- 사전 필요:
  - 기능 03 (사이드바 슬라이드) — 사이드바 컨테이너와 `isSidebarVisible` 패턴
  - 기능 04 (사이드바 카테고리 UI) — `Category`, `Folder` 모델
- 이후 영향:
  - 다음 기능: 저장 버튼이 실제 카테고리 배열에 새 항목을 추가하도록 연결 (Store/Binding 정리)
  - 추후 "카테고리 수정" 기능에서 같은 다이얼로그 컴포넌트 재사용 (편집 모드 추가)

## 범위
- 포함:
  - 사이드바 우상단 `+` 버튼
  - 화면 중앙 다이얼로그 + 어두운 배경
  - 닫는 방법 3종: **취소 버튼 / 배경 클릭 / ESC 키**
  - 이름 입력 (`TextField`)
  - 12 색 팔레트 그리드 (4 × 3), 선택 표시
  - 저장 버튼 (이름이 비어있으면 disabled)
- 제외 (다음 기능):
  - 실제 카테고리 배열에 추가
  - 폴더 선택 (어느 폴더에 추가할지)
  - 수정 / 삭제

## 단계 체크리스트
- [ ] 01 - 사이드바 헤더 + `+` 버튼 (상태 끌어올리기)
- [ ] 02 - 다이얼로그 컨테이너 + 어두운 배경 + 닫기 3종
- [ ] 03 - 다이얼로그 폼 (이름 + 12 색 팔레트 + 저장/취소)

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **모달 overlay 패턴** — `ZStack` 의 위쪽 레이어로 dim 배경 + 카드. 시스템 `.sheet` 와의 차이.
- **`.onTapGesture`** — 임의 view 에 클릭 핸들러. 이벤트 전파 (배경은 닫고, 카드 내부 클릭은 닫지 않게).
- **`.onKeyPress` / `.keyboardShortcut`** — 키보드 입력 받기. ESC 로 닫기.
- **`TextField`** — Vue 의 `v-model` 같은 양방향 바인딩. `@State var text = ""` + `TextField("placeholder", text: $text)`.
- **`LazyVGrid` + `GridItem`** — 격자 레이아웃. CSS Grid 의 `grid-template-columns: repeat(4, 1fr)` 와 유사한 발상.
- **`Color(red:green:blue:)` / hex 초기화** — 시스템 컬러가 아닌 임의 컬러 정의 방법.
- **선택 상태 시각화** — `Color == selectedColor` 비교 + 조건부 border/overlay. `Color` 는 `Equatable`.
- **`.disabled(...)`** — 조건부 버튼 비활성화. `name.isEmpty` 패턴.
- **상태 끌어올리기 재확인** — `isAddCategoryPresented` 를 어디에 둘지. (`+` 버튼은 사이드바 안인데 다이얼로그는 전체 화면을 덮어야 함 → 부모로 끌어올림.)

## 파일 구조 (예정)
```
JHCalendar/Features/Sidebar/
├── Sidebar.swift                  ← 헤더 + '+' 버튼 추가 (수정)
├── SidebarModels.swift            ← 그대로
├── CategoryRow.swift              ← 그대로
├── AddCategoryDialog.swift        ← 신설 (단계 02~03)
└── CategoryColorPalette.swift     ← 신설 (단계 03) — 12 색 정의

JHCalendar/
└── ContentView.swift              ← @State 추가 + 다이얼로그 overlay (수정)
```

## 결과물 (이 기능 완료 후)
- 사이드바 우상단의 `+` 버튼을 누르면 화면 중앙에 다이얼로그가 뜬다.
- 다이얼로그 뒤 영역은 어둡게 흐려진다.
- 다이얼로그 안: 이름 입력란, 12 색 팔레트 (선택 가능, 선택된 색이 표시됨), 저장 / 취소 버튼.
- 닫기: 취소 버튼 / 어두운 배경 클릭 / ESC 키 — 셋 다 동작.
- 저장 버튼은 이름이 비어있으면 비활성화. 활성 상태에서 누르면 콘솔에 입력값을 `print` 하고 닫힘.
