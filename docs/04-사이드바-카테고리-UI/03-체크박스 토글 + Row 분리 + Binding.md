# 단계 3: 체크박스 토글 + Row 컴포넌트 분리 + `@Binding<Category>`

## 학습 목표
- 카테고리 행을 별도 view (`CategoryRow`) 로 분리하면서 부모↔자식 데이터 흐름을 다시 정리한다.
- `@Binding<Category>` 패턴을 익힌다 — 단계 03-1 의 `@Binding<Bool>` 의 일반화. struct 자체를 양방향 참조로 자식에 전달.
- `ForEach($folders) { $folder in ... }` 의 **`$` projected value + ForEach binding 분리** 관용을 손에 익힌다.
- nested binding chain (`$folder.categories` → 각 `Binding<Category>`) 으로 깊은 구조도 한 줄로 표현.
- 색깔 네모를 클릭하면 `category.isChecked.toggle()` 한 번으로 부모 데이터가 mutation 되고 SwiftUI 가 자동 re-render 하는 흐름을 본다.

## 사전 지식
- 단계 01~02 완료. `Sidebar.swift` 가 VStack + ForEach 로 폴더/카테고리를 정적으로 그림.
- 단계 03-1 의 `@Binding` 개념 (Vue `v-model` 비유) — 부모의 `@State` 에서 `$` 로 추출한 양방향 참조.

## Swift / SwiftUI 개념

### 1) Row 분리의 의미

지금 (단계 02) 까지의 `Sidebar.swift` 는 ForEach 안에 카테고리 행 코드가 인라인으로 들어가 있다. 이걸 별도 view 로 빼면:

- view 트리가 깔끔 — `Sidebar` 는 폴더/카테고리 구조만 보이고, 카테고리 행 디테일은 `CategoryRow` 안.
- 재사용 가능 — 다른 화면에서도 같은 row 표현이 필요하면 그대로 가져다 씀.
- **데이터 흐름이 명시됨** — `CategoryRow` 가 받는 입력 (`@Binding var category: Category`) 으로 부모와의 계약이 코드에 박힘.

> Vue 비유: 인라인 `<div>` 를 컴포넌트로 빼는 것과 같음. props 가 명시되면서 의존성이 분명해짐.

### 2) `@Binding<Bool>` 에서 `@Binding<Category>` 로

단계 03-1 에서 `@Binding<Bool>` 을 다뤘다 (`isSidebarVisible` 토글). 거기서 본 원리는 **type T 가 무엇이든** 그대로 적용:

```swift
struct CategoryRow: View {
    @Binding var category: Category
    
    var body: some View {
        Button {
            category.isChecked.toggle()  // ← 부모 데이터 mutation
        } label: {
            // 색깔 네모 + 체크 표시
        }
    }
}
```

- `@Binding var category: Category` — Category struct 자체에 대한 양방향 참조.
- `category.isChecked.toggle()` 은 단순한 mutation 처럼 보이지만, **Binding 이 setter 를 들고 있어 부모의 `[Folder]` 안 해당 element 까지 변화가 전파**.
- struct 가 값 타입이라도 Binding 이 우회 — Binding 은 `get { }` + `set { }` 한 쌍을 패키지로 들고 있다.

> Vue 비유: `defineModel<Category>()` 를 쓰는 것과 거의 같음. Vue 도 props down + emit up 이지만 v-model 은 그걸 한 줄로 묶어줌. SwiftUI 의 `@Binding` 도 같은 발상.

### 3) `@State var folders: [Folder]` + `$folders` projection

`Sidebar` 가 데이터를 소유:

```swift
struct Sidebar: View {
    @State private var folders: [Folder] = Folder.sample
    // 또는 @State private var folders = sampleFolders
}
```

- `@State` 는 view 의 own state. 단계 03-1 에서 본 `isSidebarVisible` 과 같은 메커니즘.
- 단계 01 의 `sampleFolders` (또는 `Folder.sample`) 를 초기값으로 복사 (값 타입이라 진짜로 복사). Sidebar 가 그 후로는 자기만의 사본을 mutation.
- `$folders` 는 `Binding<[Folder]>` — projected value.

> 단계 01 에서 만든 sampleFolders 가 `let` 이라도 OK — `@State` 는 자기 변수를 만들어 거기로 복사. 원본은 안 바뀜.

### 4) `ForEach($folders) { $folder in ... }` 의 마법

```swift
ForEach($folders) { $folder in
    // $folder 는 Binding<Folder>
    // folder 는 그 .wrappedValue (Folder)
    
    Text(folder.name)  // 읽기만
    
    ForEach($folder.categories) { $category in
        // $category 는 Binding<Category>
        CategoryRow(category: $category)
    }
}
```

핵심 통찰:
- `$folders` (Binding<[Folder]>) 를 ForEach 에 넘기면, ForEach 가 각 element 를 **`Binding<Folder>` 로 자동 분리**해서 클로저에 넘긴다.
- 클로저 인자에서 `$folder` 같이 **`$` 를 붙여 pattern destructure** 하면 그 binding 자체를 받음. `folder` (`$` 없이) 면 `.wrappedValue` 의 Folder.
- `$folder.categories` — Binding 의 dynamic member lookup 을 통해 nested Binding 자동 추출. → `Binding<[Category]>`.
- 다시 `ForEach($folder.categories) { $category in ... }` — 같은 패턴 한 번 더 → `Binding<Category>`.

> 이게 SwiftUI 의 가장 매끄러운 부분 중 하나. 외부 라이브러리 도움 없이 nested mutable collection 을 한 줄로 다룬다. Java/Vue 에서는 보통 index 추적이나 emit-bubbling 이 필요한 일.

### 5) Button + `.buttonStyle(.plain)` — 클릭 영역과 시스템 스타일 제거

```swift
Button {
    category.isChecked.toggle()
} label: {
    // 색깔 네모 + 체크
}
.buttonStyle(.plain)
```

- `Button` 의 두 클로저: action (클릭 시) + label (보이는 모습).
- `.buttonStyle(.plain)` — macOS 의 default 버튼 스타일 (회색 배경 + 테두리) 을 제거. label 그대로 보이게.
- **단계 02-2 (HoverButton) 에서 비슷한 패턴을 봄** — 거기선 Hover 효과까지 더한 wrapper. 여기선 일단 간단히 plain Button.

### 6) 시각 토글 — overlay 의 if 가 알아서 켜고 꺼짐

단계 02 의 overlay 패턴:

```swift
.overlay {
    if category.isChecked {
        Image(systemName: "checkmark")
            // ...
    }
}
```

이미 `category.isChecked` 가 변하면 view 가 자동 re-render. 이번 단계에서 추가 코드 없음 — Binding mutation → 부모 `@State` 변경 → view diff → overlay 안의 `if` 다시 평가 → 체크 표시 등장/퇴장.

### 7) (선택) 토글에 애니메이션?

체크 표시가 그냥 깜빡 나타나/사라지는 게 어색하면 `withAnimation`:

```swift
Button {
    withAnimation(.snappy) {
        category.isChecked.toggle()
    }
} label: { ... }
```

단계 03-3 에서 본 패턴. `.snappy` 가 클릭 즉답 톤에 맞음. 본 단계 메인 학습은 binding 흐름이므로 애니메이션은 선택.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다.

### 새 파일: `JHCalendar/Features/Sidebar/CategoryRow.swift`

```swift
import SwiftUI

struct CategoryRow: View {
    @Binding var category: Category
    
    var body: some View {
        // HStack {
        //     Button {
        //         // category.isChecked.toggle()
        //     } label: {
        //         // 단계 02 의 색깔 네모 + 체크 overlay 코드를 그대로 가져옴
        //     }
        //     .buttonStyle(.plain)
        //     
        //     Text(category.name)
        // }
    }
}

#Preview {
    // CategoryRow(category: .constant(Category(...)))  
    // — @Binding 의 init 규칙: 반드시 명시 전달, .constant 로 preview 우회 (단계 03-1)
}
```

힌트:
- 단계 02 에서 인라인으로 작성한 카테고리 행 코드를 거의 그대로 옮긴다. 차이는 클릭 가능한 영역을 `Button` 으로 감싸고 그 액션이 `category.isChecked.toggle()` 라는 점.
- `Text(category.name)` 부분은 Button 바깥 — 이름 클릭은 토글 안 함, 색깔 네모만 클릭으로. (이미지에서 보이는 macOS 캘린더 동작과 일치.)
- `#Preview` 에서 `@Binding` 을 만족시키려면 단계 03-1 에서 본 `.constant(_:)` 사용.

### `Sidebar.swift` 수정

```swift
struct Sidebar: View {
    @State private var folders: [Folder] = Folder.sample  // 또는 sampleFolders
    
    var body: some View {
        VStack(/* ... */) {
            ForEach($folders) { $folder in
                // 폴더 헤더
                Text(folder.name).font(.caption).foregroundStyle(.secondary)
                
                ForEach($folder.categories) { $category in
                    CategoryRow(category: $category)
                }
            }
        }
        // 단계 02 에서 잡은 frame/padding/background 그대로
    }
}
```

핵심 변경:
- 데이터 소스: `sampleFolders` (let, 외부) → `@State var folders: [Folder]` (Sidebar 의 own state).
- ForEach: `ForEach(folders)` → `ForEach($folders) { $folder in ... }`.
- inner ForEach: `ForEach(folder.categories)` → `ForEach($folder.categories) { $category in ... }`.
- 카테고리 행 인라인 코드 → `CategoryRow(category: $category)` 호출.

### Xcode 프로젝트 등록

`CategoryRow.swift` 를 `JHCalendar.xcodeproj/project.pbxproj` 의 4 군데에 등록 (`Features/Sidebar/` 그룹).

### 시각 검증

- 사이드바를 열고 카테고리의 색깔 네모를 클릭 → 체크 표시가 켜지고 꺼짐.
- 같은 폴더 안 다른 카테고리는 영향 없음 — Binding 이 element 별로 정확히 분리됨.
- 빠른 연속 클릭에 jitter 없이 반응.
- (선택) `withAnimation(.snappy)` 적용 시 체크 등장/퇴장이 살짝 부드러움.

### 힌트

- 빌드 에러 "Cannot find `$folder` in scope" 가 난다면: `ForEach($folders) { $folder in ... }` 에서 `$folder` 는 클로저 인자 패턴으로 받아야 함. `ForEach($folders) { folder in ... }` 라고 쓰면 `folder` 는 그냥 `Folder` 라 `$folder` 표현이 없음.
- "Cannot convert value of type `Binding<Category>` to expected argument type `Category`" — `CategoryRow(category: category)` 처럼 `$` 없이 넘긴 것. `$category` 로 binding 자체를 넘겨야 함.
- preview 가 깨지면 `@Binding` 초기화에 `.constant(...)` 빠뜨린 것. 단계 03-1 에서 본 규칙.
- 만약 클릭이 들어왔는데 화면이 안 바뀐다면: `@State` 가 어디 있는지 다시 확인. `let folders` 로 두면 Binding 이 작동 안 함 (mutation 불가). `@State` 가 핵심.
- "Generic struct 'ForEach' requires that 'Binding<...>' conform to 'RandomAccessCollection'" 류 에러: `$folder.categories` 가 `Binding<[Category]>` 인데 ForEach 가 RandomAccessCollection 만 받는다고 착각하는 경우 — Xcode 가 가끔 추론 실패. 한 번 clean build (⇧⌘K) 후 다시 빌드.

### 더 갈 수 있는 지점 (선택)

- `withAnimation(.snappy) { category.isChecked.toggle() }` 으로 토글 살짝 부드럽게.
- `CategoryRow` 가 실제로는 행 전체 hover 영역을 가질 수도 있음 (단계 02-5 의 HoverButton 패턴 응용). 지금은 색깔 네모만 클릭 영역.
- 이미지에서 보이는 unchecked 색 흐림을 `.opacity(category.isChecked ? 1.0 : 0.4)` 로 적용 (단계 02 의 선택 항목과 같음).

## 직접 구현하기
- [ ] `JHCalendar/Features/Sidebar/CategoryRow.swift` 생성
- [ ] `@Binding var category: Category` 받아 색깔 네모 (Button) + Text 구성
- [ ] Button action: `category.isChecked.toggle()` + `.buttonStyle(.plain)`
- [ ] `#Preview` 에서 `.constant(...)` 로 binding 우회
- [ ] `Sidebar.swift` 의 `let sampleFolders` 사용을 `@State var folders` 로 전환
- [ ] ForEach 를 `ForEach($folders) { $folder in ... ForEach($folder.categories) { $category in CategoryRow(category: $category) } }` 패턴으로 수정
- [ ] xcodeproj 의 4 군데에 `CategoryRow.swift` 등록
- [ ] ⌘B 빌드 통과 / ⌘R 실행
- [ ] 색깔 네모 클릭 시 해당 카테고리만 체크 토글
- [ ] 빠른 연속 클릭 jitter 없음
- [ ] 라이트/다크 모드 양쪽 시각 OK
- [ ] (선택) `withAnimation(.snappy)` 로 토글 보간

> 다 끝나면 "다 했어" 라고 알려줘.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: `$folders` 와 `folders` 의 차이? (정답: `$folders` 는 `Binding<[Folder]>` (projected value), `folders` 는 `[Folder]` (wrapped value). `$` 가 양방향 참조 추출 prefix.)
- 자문자답: struct 는 값 타입인데 Row 에서 `category.isChecked.toggle()` 한 게 어떻게 부모 `@State` 까지 반영되는가? (정답: `@Binding` 이 단순한 값 wrapper 가 아니라 setter/getter 한 쌍을 들고 있는 구조. 자식의 mutation 호출이 setter 를 통해 부모 state 변경 → SwiftUI re-render.)
- 자문자답: `ForEach(folders)` 와 `ForEach($folders) { $folder in ... }` 의 차이? (정답: 전자는 read-only collection iteration, 각 element 는 `Folder` (값 복사). 후자는 binding-aware iteration, 각 element 는 `Binding<Folder>` 로 mutation 가능.)
- 자문자답: `CategoryRow(category: category)` 라고 쓰면 컴파일 에러가 나는 이유? (정답: 자식의 `@Binding var category: Category` 는 `Binding<Category>` 를 기대. `category` (값) 가 아니라 `$category` (binding) 를 넘겨야 함.)
- 자문자답: 만약 `Sidebar` 의 `folders` 를 `@State` 가 아닌 `let` 으로 두면? (정답: Binding 의 setter 가 작동할 자리가 없음 — mutation 불가. 컴파일 에러 또는 런타임에 토글이 무반응.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `CategoryRow` 가 `@Binding var category: Category` 받음
- [ ] Row 의 클릭 영역이 `Button` + `.buttonStyle(.plain)` 으로 시스템 스타일 제거
- [ ] Button action 이 `category.isChecked.toggle()` 한 줄
- [ ] `Sidebar` 가 `@State var folders: [Folder]` 소유
- [ ] `ForEach($folders) { $folder in ... }` + nested `ForEach($folder.categories) { $category in CategoryRow(category: $category) }` 패턴
- [ ] preview 가 `.constant(...)` 로 binding 우회
- [ ] 토글 시 해당 카테고리만 변화 (다른 카테고리에 영향 없음)
- [ ] xcodeproj 등록 + 빌드 통과
- [ ] 라이트/다크 모드 양쪽 OK

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **HoverButton 응용**: 단계 02-5 의 `HoverButton<Label>` 을 색깔 네모 클릭 영역에 적용해 hover 시 살짝 톤 변화. 일관된 인터랙션 라이브러리 효과.
- **`@Observable` class 도입**: 데이터가 여러 view 에 공유되어야 한다면 `@State` 보단 `@Observable class CategoryStore` 패턴. 후속 기능 (실제 데이터 연동) 에서 도입 후보.
- **Selection 상태 추가**: 이미지의 `Siri 제안` 처럼 선택된 행 하이라이트. `@State var selectedID: Category.ID?` + `CategoryRow` 가 isSelected 플래그 받음. 별도 단계 또는 후속 기능.
- **Drag to reorder**: SwiftUI 의 `.onMove` modifier (List 와 함께) 로 행 순서 변경. 한참 후 학습.
- **테스트 가능성**: 모델이 struct + 값 타입이라 테스트가 쉽다. `XCTAssertEqual(folder.categories[0].isChecked, true)` 류로 토글 결과 검증. 테스트 도입은 별도 학습 트랙.
