# 사이드바 카테고리 UI

## 목표
사이드바 안에 **폴더 (Folder) + 카테고리 (Category)** 형태의 리스트 UI 를 그린다.
- **폴더**: `iCloud`, `기타` 같은 섹션 헤더 텍스트
- **카테고리**: 색깔 네모 + 이름 + 체크 상태 (색깔 네모 클릭으로 toggle)
- 이번 단계에선 **UI 만** — 데이터는 이미지에 보이는 모습대로 더미 배열을 하드코딩.

> 이미지 참고: 폴더 두 개 (`iCloud` / `기타`), 폴더 안에 카테고리 여러 개. 색깔 네모를 클릭하면 체크가 토글됨.

## 의존 관계
- 사전 필요: 기능 03 (사이드바 슬라이드) — 사이드바 컨테이너 (`Sidebar.swift`) 가 살아 있고 240pt 폭의 placeholder 상태
- 이후 영향: 후속 기능에서 실제 데이터 (Reminders/EventKit, 또는 자체 저장소) 로 더미 배열을 대체

## 단계 체크리스트
- [x] 01 - Folder/Category 모델 + 더미 데이터셋
- [x] 02 - ForEach 로 사이드바 채우기 (정적 렌더링)
- [x] 03 - 체크박스 토글 + Row 컴포넌트 분리 + `@Binding<Category>`

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **`struct` 데이터 모델** — Java record 와 비슷한 값 타입. 자동 memberwise init.
- **값 타입 (struct) vs 참조 타입 (class)** — Swift 의 큰 갈림길. 왜 SwiftUI 가 struct 를 권장하는가.
- **`Identifiable` 프로토콜** — `var id: ...` 만 갖추면 적합. ForEach 가 식별에 사용.
- **`UUID` 자동 ID** — `let id = UUID()` 패턴 (Foundation).
- **`Color` 타입** — `.red`, `.blue`, … 시스템 기본색 + 임의 색상 (`Color(red:green:blue:)` 또는 hex).
- **`ForEach`** — Swift collection 을 SwiftUI view 로 변환 — Vue 의 `v-for` 와 같은 발상.
- **`VStack(alignment:spacing:)`** — 좌측 정렬 리스트.
- **컴포넌트 분리** — Row 를 별도 view 로 빼면서 부모↔자식 데이터 흐름을 다시 정리.
- **`@Binding<Category>`** — `@Binding<Bool>` (단계 03-1 에서 다룬) 의 일반화. struct 자체를 양방향 참조로 자식에 전달.
- **`ForEach($folders)` 의 `$` projected value** — `@State var folders: [Folder]` 에서 `$folders` 는 `Binding<[Folder]>`. ForEach 가 이것을 받으면 각 element 를 `Binding<Folder>` 로 자동 분리.
- **Nested binding chain** — `$folder.categories` → 각 `Binding<Category>`. 깊이 들어간 구조도 한 줄로 표현.
- **`Button { } label: { }` + `.buttonStyle(.plain)`** — 클릭 가능한 영역 + 시스템 기본 스타일 제거.
- **선언형 UI 의 진가** — 데이터를 바꾸면 view 가 자동으로 다시 그려짐. 부모가 데이터를 소유, 자식은 binding 으로 mutation 권한 위임.

## 결과물 (이 기능 완료 후)
- 사이드바 안에 두 폴더 (`iCloud`, `기타`) 와 그 아래 카테고리 행들이 보인다.
- 각 카테고리는 색깔 네모 + 이름. 색깔 네모 클릭 시 체크가 토글되고 SwiftUI 가 자동으로 다시 렌더한다.
- 데이터는 사이드바 (또는 그 부모) 가 `@State` 로 소유하고, Row 는 `@Binding<Category>` 로 받음 — 단방향 데이터 흐름 + 양방향 바인딩의 표준 패턴.
- 시각 디테일 (선택된 행 하이라이트, audio wave 아이콘 등) 은 본 기능 범위 밖 — 후속에 별도 기능으로.

## 파일 구조 (예정)
```
JHCalendar/Features/Sidebar/
├── Sidebar.swift              ← 기존, 단계 02~03 에서 채울 것
├── SidebarModels.swift        ← 단계 01 신설 (Folder, Category, sampleData)
└── CategoryRow.swift          ← 단계 03 신설 (Row 컴포넌트)
```
