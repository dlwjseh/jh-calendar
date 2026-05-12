# 단계 2: Category 도 @Model + Relationship

## 학습 목표
- `Category` 를 `@Model` 로 전환하고, `Folder` 와의 **양방향 1:N 관계** 를 SwiftData 가 인식하게 만든다.
- `@Relationship(deleteRule:inverse:)` 로 cascade 삭제 규칙을 선언한다.
- 컬렉션 프로퍼티(`folder.categories`) 가 어떻게 SwiftData 의 관계로 매핑되는지 안다.

## 사전 지식
- 1단계 산출물: `Folder` 가 이미 `@Model` 로 전환됨, `JHCalendarApp` 에 `ModelContainer` 부착됨
- `@Model`, `ModelContainer`, `@Query` → [01-SwiftData 도입.md](./01-SwiftData%20도입.md) 참고
- `struct` vs `class` 차이 → [01-SwiftData 도입.md](./01-SwiftData%20도입.md) 참고

## Swift / SwiftUI 개념

### 1) `@Relationship` 매크로

SwiftData 에서 두 모델 간 관계는 **프로퍼티 타입만 적어도 자동 추론** 된다. 하지만 두 가지를 명시적으로 잡고 싶을 때 `@Relationship` 매크로를 쓴다:
- **`deleteRule`** — 부모가 삭제될 때 자식을 어떻게 할지 (`.cascade` / `.nullify` / `.deny` / `.noAction`).
- **`inverse`** — 양방향 관계에서 반대편 키패스. (둘 중 한쪽에만 적으면 충분.)

```swift
@Model
final class Folder {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Category.folder)
    var categories: [Category] = []
    init(name: String) { self.name = name }
}

@Model
final class Category {
    var name: String
    var folder: Folder?           // 반대편 — inverse 없어도 됨
    init(name: String) { self.name = name }
}
```

> Spring JPA 비교:
> - `@OneToMany(mappedBy = "folder", cascade = CascadeType.ALL, orphanRemoval = true)` ≈ `@Relationship(deleteRule: .cascade, inverse: \.folder)`
> - `mappedBy` 가 `inverse:` 와 같은 역할
> - JPA 에서 자주 까먹는 "양쪽 다 세팅해야 메모리 그래프가 일관" 문제는 SwiftData 도 동일. `folder.categories.append(c)` 하면 자동으로 `c.folder = folder` 로 묶이긴 하지만, 안전하게는 양쪽 다 세팅하는 게 좋다.

### 2) `.cascade` vs `.nullify`

| 규칙 | 의미 | 사용 예 |
|---|---|---|
| `.cascade` | 부모 삭제 → 자식도 같이 삭제 | 폴더 안의 카테고리 (자식의 독립적 의미 없음) |
| `.nullify` | 부모 삭제 → 자식의 부모 참조만 null | 카테고리에 속한 일정 (카테고리 삭제해도 일정 자체는 살려두기) |

이 단계에선 폴더 ↔ 카테고리 는 `.cascade` 가 자연스럽다.

### 3) Color 는 지금은 잠시 보류

Swift `Color` 는 그대로는 SwiftData 가 저장 못 한다. **3단계에서 hex string 으로 변환** 할 예정. 이번 단계에선 일단 `Category` 에 `colorHex: String` 정도로 자리만 잡아두거나, 임시로 색상 프로퍼티를 비워둬도 OK.

## 구현 가이드

### 파일 변경 계획
- `SidebarModels.swift` 수정
  - `Category` 를 `@Model final class` 로 전환 (Identifiable 자동 적용되므로 직접 `id` 만들 필요 없음)
  - `Category` 에 `var folder: Folder?` 추가 (반대편 참조)
  - `Folder` 에 `@Relationship(deleteRule: .cascade, inverse: \Category.folder) var categories: [Category] = []` 추가
  - `color` 는 잠시 보류 — 이 단계에서는 `// TODO: 3단계에서 colorHex 로 영속화` 주석만 남기거나, 임시로 빨강 고정 computed property 를 두자
  - `isChecked: Bool` 는 그대로 살린다 (체크박스 상태도 영속화 대상)
- `JHCalendarApp.swift` — `.modelContainer(for: Folder.self)` 에 `Category.self` 도 같이 등록할지 결정 (보통 Folder 만 등록해도 관계로 같이 잡히지만, 명시적으로 `[Folder.self, Category.self]` 로 적는 게 안전)
- `Sidebar.swift` / `CategoryRow.swift` — `@Binding` 으로 받던 카테고리·폴더가 이제 **참조 타입** 이라 binding 패턴이 달라진다. 자세한 건 막힐 만한 지점 참고.

### 핵심 골격

```swift
import SwiftUI
import SwiftData

@Model
final class Folder {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \Category.folder)
    var categories: [Category] = []
    init(name: String) { self.name = name }
}

@Model
final class Category {
    var name: String
    var isChecked: Bool
    var folder: Folder?
    // TODO(03 단계): colorHex 로 색상 영속화
    init(name: String, isChecked: Bool = true) {
        self.name = name
        self.isChecked = isChecked
    }
}
```

### 막힐 만한 지점 — 힌트

- **`@Binding var category: Category` 가 깨진다** — `Category` 가 이제 class 라서 binding 으로 감싸기 애매하다. 두 가지 방법:
  1. **그냥 인스턴스로 받기** — class 는 참조 타입이라 `category.isChecked.toggle()` 직접 변경해도 같은 인스턴스를 가리키는 다른 곳에 반영된다.
  2. **`@Bindable`** — class 에서 SwiftUI binding(`$category.isChecked`) 을 만들고 싶을 때 쓰는 매크로. 토글/텍스트필드처럼 `$` 가 필요한 곳에서 사용.

  ```swift
  struct CategoryRow: View {
      @Bindable var category: Category   // ← @Binding 아님
      var body: some View {
          Toggle("", isOn: $category.isChecked)
              .toggleStyle(...)
      }
  }
  ```

- **양방향 관계의 inverse 는 한 쪽에만** — Folder 쪽에 `inverse: \Category.folder` 한 번만 적으면 된다. 양쪽에 적으면 컴파일 에러.
- **Sidebar 의 `@Binding var folders: [Folder]`** — `[Folder]` 가 class 배열이라 binding 의 의미가 약해진다. ContentView 에서 `@Query` 결과를 **그냥 값으로** 넘기는 형태로 정리하자 (`folders: [Folder]`). `ForEach($folders) { $folder in ... }` 부분은 `ForEach(folders) { folder in ... }` 으로 단순화 — `folder.categories` 가 이미 class 라 binding 없이도 변경이 반영된다.
- **빌드는 통과하지만 사이드바가 여전히 빈 상태** — 정상. 다음 단계 + 4단계까지 가야 시드 데이터가 들어온다.

## 직접 구현하기
- [ ] `Category` 를 `@Model final class` 로 전환 + `var folder: Folder?` 추가
- [ ] `Folder` 에 `@Relationship(deleteRule: .cascade, inverse: \Category.folder) var categories: [Category] = []` 추가
- [ ] `ModelContainer` 등록 모델 목록에 `Category.self` 도 명시
- [ ] `Sidebar`, `CategoryRow` 등에서 `@Binding` → 인스턴스/`@Bindable` 로 다듬기
- [ ] 빌드 통과, 사이드바가 깨지지 않고 빈 상태로 떠야 함

## 자가 점검
- 빌드 OK?
- `Folder` ↔ `Category` 양쪽에서 서로 참조 가능한가 (`folder.categories`, `category.folder`)?
- 이해도 퀴즈
  1. `inverse:` 를 양쪽에 다 적으면 왜 안 될까?
  2. `.cascade` 와 `.nullify` 중 "카테고리를 삭제했을 때 그 안의 일정" 은 어느 쪽이 자연스러울까?

## Claude 리뷰 체크리스트
- [ ] `Category` 가 `@Model` 클래스이고 `folder: Folder?` 를 들고 있음
- [ ] `@Relationship` 이 한쪽(Folder)에만 적혀 있고 deleteRule + inverse 둘 다 명시됨
- [ ] `@Binding` 패턴이 class 모델에 맞게 정리됨 (`@Bindable` 사용 또는 인스턴스 직접 변경)
- [ ] 빌드 통과

## 회고
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `@Attribute(.unique)` 로 폴더 이름의 고유성을 강제할지 — 일단은 안 해도 됨 (사용자가 같은 이름으로 만드는 걸 막을 필요는 없음).
