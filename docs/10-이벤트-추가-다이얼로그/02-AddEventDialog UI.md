# 단계 2: AddEventDialog UI (Toggle · Mode enum)

## 학습 목표
- SwiftUI `Toggle` 로 Bool 상태를 스위치/체크박스로 표현할 수 있다.
- 09 의 `AddCategoryDialog` mode enum 패턴을 같은 형태로 재사용해 **추가/편집 다이얼로그 한 벌** 을 만든다.
- 이번 단계는 **UI만** — 저장/연결은 03 단계에서.

## 사전 지식
- 09 산출물 — `AddCategoryDialog`, `DialogBackdrop`, `HoverButton`, mode enum (`.add` / `.edit(...)`)
- `@State`, `@Binding` → [01-타이틀바-호버표시](../01-타이틀바-호버표시/) 참고
- `Menu` (카테고리 선택용), `TextField`, mode enum 패턴 → [09/05-카테고리 추가 저장.md](../09-폴더-카테고리-데이터-영속화/05-카테고리%20추가%20저장.md), `JHCalendar/Features/Sidebar/AddCategoryDialog.swift` 참고

## Swift / SwiftUI 개념

### 1) `Toggle` — Bool 을 스위치/체크박스로

가장 단순한 형태:

```swift
@State private var isAllDay = false

var body: some View {
    Toggle("종일", isOn: $isAllDay)
}
```

- `isOn:` 에 **`Binding<Bool>`** 을 넘긴다 (그래서 `$isAllDay`). 09 의 `Bindable`/`@State` 와 같은 결.
- 라벨은 `String` 직접 또는 `{ Text(...) }` 형태 둘 다 가능.

#### toggleStyle 로 모양 바꾸기

| Style | 모양 | 사용처 |
|---|---|---|
| 기본 (`.automatic`) | macOS: 체크박스, iOS: 스위치 | 플랫폼 관용 |
| `.switch` | 둥근 스위치 | 강조된 on/off |
| `.checkbox` (macOS) | 체크박스 | 폼 안 부속 옵션 |

```swift
Toggle("종일", isOn: $isAllDay)
    .toggleStyle(.switch)     // 또는 .checkbox
```

> JS 비교: HTML `<input type="checkbox" checked={isAllDay} onChange={...} />` 와 같은 위치. SwiftUI 는 단방향 콜백 대신 **양방향 binding** 으로 표현.
> Java/Swing 비교: `JCheckBox` 와 동치. 상태를 직접 들고/꺼내는 부분만 SwiftUI 식 `@State` + `Binding`.

#### 라벨 정렬 — 기본은 "라벨 — 스페이서 — 토글"

`Toggle("종일", isOn: $isAllDay)` 의 기본 레이아웃은 라벨이 leading, 컨트롤이 trailing 으로 자동 배치된다. 09 다이얼로그처럼 `Text("종일")` + `frame(width: 50, alignment: .leading)` 패턴으로 폼 정렬을 맞추고 싶다면, **라벨 비우고 따로 두는 방식** 이 깔끔:

```swift
HStack(spacing: 0) {
    Text("종일")
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .frame(width: 50, alignment: .leading)

    Toggle("", isOn: $isAllDay)
        .toggleStyle(.switch)
        .labelsHidden()         // 빈 라벨 공간 제거
}
```

### 2) Mode enum 패턴 재활용

09 의 `CategoryDialogMode` 와 같은 형태:

```swift
enum EventDialogMode {
    case add
    case edit(Event)
}
```

`init` 에서 `.edit` 면 기존 인스턴스 값을 `@State` 초기값으로 주입 — [AddCategoryDialog.swift:25-34](../../JHCalendar/Features/Sidebar/AddCategoryDialog.swift) 참고.

## 구현 가이드

### 파일 변경 계획
- `JHCalendar/Features/Event/AddEventDialog.swift` 신설 (01 단계에서 폴더를 안 만들었다면 이 단계에 만들기 — sync group 등록 권장)
- 09 의 `AddCategoryDialog.swift` 를 옆에 펴두고 같은 구조로 시작:
  - 상단 아이콘 + 타이틀 — `calendar` 또는 `calendar.badge.plus` SF Symbol 추천
  - 폼 3행: **카테고리(Menu) · 이름(TextField) · 종일(Toggle)**
  - 하단 취소/저장 버튼 (저장 동작은 아직 빈 클로저 또는 `print` 로 둠 — 03 단계에서 채움)
  - `DialogBackdrop` 은 09 패턴 그대로 `ContentView` 에서 같이 띄울 예정 (이 단계에선 다이얼로그 본체만 만들면 됨)
- 카테고리 옵션은 "모든 폴더의 카테고리를 평탄화" — 폴더별로 묶어 보이게 하려면 `Menu` 안에 `Section(folder.name)` 으로 그룹.

### 핵심 골격

```swift
import SwiftUI

enum EventDialogMode {
    case add
    case edit(Event)
}

struct AddEventDialog: View {
    @State private var selectedCategory: Category? = nil
    @State private var name = ""
    @State private var isAllDay = false
    let mode: EventDialogMode
    let folders: [Folder]      // 카테고리 옵션 펼치기용
    var onDismiss: () -> Void

    init(mode: EventDialogMode, folders: [Folder], onDismiss: @escaping () -> Void) {
        self.mode = mode
        self.folders = folders
        self.onDismiss = onDismiss
        if case .edit(let event) = mode {
            _selectedCategory = State(initialValue: event.category)
            _name = State(initialValue: event.name)
            _isAllDay = State(initialValue: event.isAllDay)
        }
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }
    private var isSaveEnabled: Bool {
        selectedCategory != nil && !trimmedName.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            // 1) 헤더 (아이콘 + 타이틀)
            // TODO: HStack { Image(systemName: "calendar.badge.plus"); Text("이벤트 추가") }

            VStack(alignment: .leading, spacing: 19) {
                // 2) 카테고리 Menu — folders 를 펼쳐 Section 으로 그룹
                // TODO: Menu { ForEach(folders) { Section(folder.name) { ForEach(folder.categories) { ... } } } }

                // 3) 이름 TextField
                // TODO: TextField("이벤트 이름", text: $name)

                // 4) 종일 Toggle
                // TODO: Toggle("", isOn: $isAllDay).toggleStyle(.switch).labelsHidden()
            }

            // 5) 취소 / 저장 — 저장 액션은 이 단계에선 비워둠 (03 에서 채움)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 25)
        .frame(width: 320)
        .background(.background)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
    }
}
```

### 막힐 만한 지점 — 힌트

- **카테고리 옵션을 어떻게 펼치나** — 가장 간단한 형태는 평탄화 `folders.flatMap(\.categories)`. 폴더 그룹을 보여주고 싶다면 `Menu` 안에서:
  ```swift
  ForEach(folders) { folder in
      Section(folder.name) {
          ForEach(folder.categories) { category in
              Button(category.name) { selectedCategory = category }
          }
      }
  }
  ```
- **카테고리 라벨 옆에 색 점 보여주기** — `Button` 의 label 을 `HStack { Circle().fill(category.color).frame(width: 8, height: 8); Text(category.name) }` 로. 09 의 `CategoryRow` 와 같은 결.
- **`labelsHidden()` 빼먹으면 Toggle 라벨 자리가 비어 폼이 어긋남** — 라벨 영역을 따로 `Text("종일")` 으로 빼내는 패턴이라 반드시 같이.
- **`.toggleStyle(.switch)` vs `.checkbox`** — 캘린더 앱에서는 시각적으로 강조되는 `.switch` 가 자연스럽지만 취향 영역. 둘 다 시도해보고 결정.
- **저장 버튼 액션은 이 단계에선 비워둔다** — `print("저장")` 또는 빈 클로저 + `onDismiss()`. 진짜 저장은 03 단계.
- **빌드는 통과하지만 다이얼로그가 안 보임** — 정상. 이 단계에선 `ContentView` 에 띄우는 코드를 아직 안 붙였음. 미리 확인하고 싶다면 09 의 `categoryDialog` 옆에 임시로 `.constant(EventDialogMode?.add)` 띄우는 코드를 잠깐 끼워봐도 OK (커밋 전 원복).

## 직접 구현하기
- [ ] `EventDialogMode` enum 선언
- [ ] `AddEventDialog` 본체 + `init(mode:folders:onDismiss:)` — `.edit` 분기에서 기존 인스턴스 값 주입
- [ ] 헤더 (아이콘 + 타이틀) — `.add` / `.edit` 에서 다른 문구로 분기 가능
- [ ] 카테고리 `Menu` — 폴더별 Section + 색 점 표시
- [ ] 이름 `TextField`
- [ ] 종일 `Toggle` — `.switch` 또는 `.checkbox`
- [ ] 취소/저장 버튼 (저장은 비워둠) — `isSaveEnabled` 로 비활성 처리
- [ ] 빌드 통과

## 자가 점검
- 빌드 OK?
- 09 의 `AddCategoryDialog` 와 시각적으로 일관된가 (폼 행 간격, 라벨 폭, 색·모양)?
- 카테고리 미선택 또는 이름 빈 상태에서 저장이 비활성인가?
- 이해도 퀴즈
  1. `Toggle("종일", isOn: $isAllDay)` 에서 `$` 가 의미하는 게 뭔가? (`@State` 의 binding 변환)
  2. mode enum 에서 `.edit(event)` 가 가져가는 `event` 는 값 복사인가 참조인가? — `Event` 가 `@Model class` 이므로 답은?

## Claude 리뷰 체크리스트
- [ ] `EventDialogMode` enum 이 `.add` / `.edit(Event)` 로 09 패턴과 일관
- [ ] `init` 에서 `.edit` 일 때 `_state = State(initialValue: ...)` 로 초기값 주입
- [ ] `Toggle` 사용 — `labelsHidden()` 또는 라벨 명시 중 하나로 정렬 깔끔
- [ ] 저장/취소 버튼이 09 와 동일한 모양 (HoverButton · keyboardShortcut · disabled 처리)
- [ ] 빌드 통과 (저장 액션 비어 있어도 OK)

## 회고
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 카테고리 선택 라벨에 **현재 선택된 카테고리 색 점** 표시 — Menu label 에서 `selectedCategory?.color` 사용.
- `.edit` 모드일 때 타이틀을 "이벤트 편집" 으로, 아이콘은 `pencil` 로 바꿔보기 — 09 카테고리 편집과 일관되게.
