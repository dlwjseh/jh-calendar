# 단계 1: SwiftData 도입 (Folder 를 @Model 로)

## 학습 목표
- `struct` → `@Model class` 전환의 의미를 이해한다 (값 타입 vs 참조 타입).
- 앱 진입점에 `ModelContainer` 를 부착하는 흐름을 익힌다.
- `@Query` 매크로로 SwiftData 에서 선언적으로 데이터를 읽어오는 방식을 안다.

## 사전 지식
- `04-사이드바-카테고리-UI` 의 `Folder` / `Category` 모델 (현재 `SidebarModels.swift`)
- `@State`, `@Binding` 의 차이 → [04-사이드바-카테고리-UI/02-...](../04-사이드바-카테고리-UI) 참고
- Java 의 `@Entity` / Spring Data 의 `JpaRepository` 개념 (직관 형성용)

## Swift / SwiftUI 개념

### 1) 값 타입(struct) vs 참조 타입(class) — *이 단계의 핵심*

Swift 의 `struct` 는 **값 타입** 이다. 변수에 담을 때 복사가 일어나고, `let` 으로 잡으면 안의 프로퍼티도 못 바꾼다. SwiftUI 의 `@State` 가 작은 모델을 추적할 수 있는 건 이 "값으로 복사된 새 인스턴스" 가 바뀜을 감지하기 때문이다.

반면 `class` 는 **참조 타입** — Java/Kotlin 의 보통 객체와 같다. 같은 인스턴스를 여러 곳에서 가리킨다.

> Java 의 `String` 도 사실상 불변이지만 객체(참조). Swift 의 `struct` 는 거기서 한 발 더 나아가 "복사 시점에 값이 별도" 가 보장된다. Vue 에서 `reactive(obj)` vs `ref(primitive)` 의 차이와도 약간 닮음.

**SwiftData 는 class 만 모델로 받는다.** 데이터베이스에 있는 한 레코드를 여러 뷰가 함께 보고 같이 수정해야 하므로, 같은 인스턴스를 공유하는 참조 타입이 자연스럽기 때문.

```swift
// 지금까지
struct Folder: Identifiable {
    let id = UUID()
    var name: String
}

// 이번 단계 이후
@Model
final class Folder {
    var name: String
    init(name: String) { self.name = name }
}
```

### 2) `@Model` 매크로

`@Model` 은 그 클래스를 **영속화 가능한 모델** 로 표시한다. Java JPA 의 `@Entity` 와 거의 같은 위치.

`@Model` 을 붙이면 컴파일러가 뒤에서:
- 영속화 메타데이터(스키마)를 만들어두고
- 프로퍼티 변경을 자동으로 감지(dirty tracking)하고
- `Identifiable`, `Observable` 같은 프로토콜을 자동 추가한다 (= `id` 직접 만들 필요 없음)

### 3) `ModelContainer` & `.modelContainer(for:)` modifier

`ModelContainer` 는 **JPA 의 `EntityManagerFactory`**. 어떤 모델들을 다룰지, 어디(파일)에 저장할지를 들고 있는 최상위 객체.

SwiftUI 앱에서는 보통 진입점 `WindowGroup` 에 한 번 부착한다:

```swift
@main
struct JHCalendarApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
            .modelContainer(for: Folder.self)
    }
}
```

이러면 자식 뷰 어디서든 환경(environment)에서 `ModelContext` 를 꺼내 쓸 수 있다.

### 4) `@Query` — 선언적 조회

```swift
@Query(sort: \Folder.name) private var folders: [Folder]
```

Spring Data 의 `findAll(Sort.by("name"))` 같은 느낌인데, 더 강력한 점이 두 가지:

1. **자동 재조회**: 백그라운드에서 데이터가 바뀌면 뷰가 자동으로 다시 그려진다 (Vue 의 reactive ref 와 비슷).
2. **선언만 하면 끝**: `@State` 처럼 가만히 뒀다가 SwiftUI 가 살아 있는 결과셋을 흘려넣어 준다.

## 구현 가이드

### 파일 변경 계획
- `JHCalendar/Features/Sidebar/SidebarModels.swift` 수정 — `Folder` 를 `@Model class` 로. **`Category` 는 이번 단계에서 일단 그대로 둬도 된다** (다음 단계에서 전환). 단, `Folder.categories: [Category]` 프로퍼티는 다음 단계에서 본격 다룰 거니, 이번 단계에선 임시로 **빼거나 빈 배열로 둔다.**
- `JHCalendar/JHCalendarApp.swift` 수정 — `.modelContainer(for: Folder.self)` 부착.
- `JHCalendar/ContentView.swift` 수정 — `@State private var folders = Folder.sample` 을 `@Query private var folders: [Folder]` 로 교체.
- `Folder.sample` 정적 프로퍼티는 잠시 주석 처리(또는 삭제) — 다음 단계까지는 빈 사이드바가 보일 것.

### 핵심 골격

```swift
// SidebarModels.swift
import SwiftUI
import SwiftData

@Model
final class Folder {
    var name: String
    // 카테고리 관계는 다음 단계에서 추가
    init(name: String) {
        self.name = name
    }
}
```

```swift
// JHCalendarApp.swift
import SwiftUI
import SwiftData

@main
struct JHCalendarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // TODO: .modelContainer(for: Folder.self) 부착
    }
}
```

```swift
// ContentView.swift
import SwiftUI
import SwiftData

struct ContentView: View {
    // TODO: @Query 로 교체
    // @State private var folders = Folder.sample  ← 이 줄을 ...
    // @Query private var folders: [Folder]        ← 이렇게

    var body: some View {
        // 기존 코드. Sidebar 에 folders 넘기는 부분도
        // @Query 결과를 그대로 넘기면 된다.
        // 단, Sidebar 의 @Binding var folders: [Folder] 는
        // 이번 단계에선 일단 그대로 둬도 빌드는 통과한다
        // (다음 단계 이후 다듬을 예정 — 막히면 임시로 const 전달).
    }
}
```

### 막힐 만한 지점 — 힌트

- **`@Model` 을 붙였더니 빌드 에러: `init` 이 없다는 식의 오류** → `@Model` 클래스는 기본 생성자 자동 추가가 안 된다. 모든 저장 프로퍼티를 받는 `init` 을 직접 작성해야 한다.
- **`final class` 키워드** — `@Model` 은 보통 `final class` 로 쓴다. 상속하지 않을 거란 신호이자 컴파일러 최적화에도 유리.
- **`@Query` 는 `View` 안에서만 쓴다** — `@State` 와 같은 위치(뷰의 저장 프로퍼티)에서 선언. 변수 안에 옮기거나 함수 안에서 만들면 동작 안 함.
- **사이드바가 비어 보이는 것이 정상** — 아직 시드/추가가 없으니 빈 상태가 맞다. 4단계에서 채운다.

#### 값 타입 → 참조 타입 전환에 따라 같이 손봐야 하는 두 곳

`Folder` 가 `struct` → `@Model class` 가 되면서 "값 복사" 가 "참조 공유" 로 바뀐다. 이 차이가 다음 두 곳에서 빌드 에러로 드러난다.

**(1) `Sidebar` 의 `ForEach($folders) { $folder in ... }` 가 안 컴파일된다**

증상:
```
No exact matches in call to initializer
Inferred projection type 'Int' is not a property wrapper
```

원인: `$`(바인딩 프로젝션) 은 값 타입 배열에서만 동작한다. `@Model class` 는 참조 타입이라 같은 인스턴스를 공유하므로 `Binding` 자체가 필요 없다 — `folder.name = "X"` 한 줄이면 SwiftUI 가 자동으로 다시 그린다 (`@Model` 이 `@Observable` 까지 깔아주기 때문).

수정:
- `Sidebar` 의 `@Binding var folders: [Folder]` → `var folders: [Folder]`
- `ContentView` 에서 `folders: .constant(folders)` → `folders: folders`
- `ForEach($folders) { $folder in ... }` → `ForEach(folders) { folder in ... }`
- 안쪽 `ForEach($folder.categories) { ... }` 는 이번 단계에서 `Folder.categories` 를 뺐으니 임시로 주석 처리하거나 placeholder 로 둔다 (02 단계에서 `@Relationship` 으로 복원).

**(2) `AddCategoryDialog` 에서 `selectedFolderID: UUID?` 가 안 맞는다**

증상:
```
Cannot convert value of type 'UUID?' to expected argument type 'PersistentIdentifier'
Cannot assign value of type 'PersistentIdentifier' to type 'UUID'
```

원인: `@Model` 매크로가 `PersistentModel` 프로토콜을 자동 채택시키는데, 거기서 정의된 `var id: PersistentIdentifier` 가 너의 `let id = UUID()` 를 가린다. 그래서 `folder.id` 의 타입이 `UUID` 가 아니라 `PersistentIdentifier` 로 바뀜.

수정 — **id 가 아니라 `Folder` 객체 자체를 들고 있는 게 자연스럽다**:

- `@State private var selectedFolderID: UUID? = nil` → `@State private var selectedFolder: Folder? = nil`
- 계산 프로퍼티 `selectedFolder` (folders.first(where:) ...) 삭제 — 이제 `selectedFolder` 가 곧 상태
- `Button(folder.name) { selectedFolderID = folder.id }` → `{ selectedFolder = folder }`
- `isSaveEnabled` 의 `selectedFolderID != nil` → `selectedFolder != nil`

이유:
- `Folder` 가 참조 타입이라 어디서 잡든 같은 인스턴스. 굳이 id 로 우회할 필요가 없음 — 객체를 직접 들면 됨.
- 저장 시점에 `category.folder = selectedFolder` 처럼 **관계 연결** 도 자연스럽다 (02 단계 `@Relationship` 으로 바로 이어짐).

> struct 시대엔 "값 복사" 때문에 id 로 추적하는 게 안전 패턴이었고, class/@Model 시대엔 "참조 공유" 라서 객체를 직접 들고 있는 게 자연스럽다 — 이번 단계에서 챙겨갈 직관.

## 직접 구현하기
- [x] `Folder` 를 `@Model final class` 로 전환 (`categories` 는 일단 제외)
- [x] `Folder.sample` 주석 처리 또는 삭제
- [x] `JHCalendarApp` 에 `.modelContainer(for: Folder.self)` 부착
- [x] `ContentView` 의 `folders` 를 `@Query` 로 교체
- [x] 빌드 통과 + 실행 시 사이드바가 **비어 있는 채로** 정상 표시되는지 확인

## 자가 점검 (구현 후)
- 빌드 통과? (`xcodebuild -project JHCalendar.xcodeproj -scheme JHCalendar -configuration Debug build` 또는 ⌘B)
- 앱 실행 시 사이드바를 열면 폴더 영역이 **빈 채로** 보이는가? (`+` 메뉴 자체는 그대로 떠야 함)
- 이해도 퀴즈
  1. 왜 SwiftData 는 `struct` 가 아닌 `class` 를 모델로 요구할까?
  2. `@Query` 가 `@State` 와 가장 다른 점 하나를 말해보라.

## Claude 리뷰 체크리스트
- [x] `Folder` 가 `@Model final class` 로 선언되었고 `init` 이 작성됨
- [x] `ModelContainer` 가 앱 진입점에 정확히 한 번 부착됨
- [x] `ContentView` 가 `@Query` 로 폴더를 읽고 있음 (메모리 샘플 의존 제거)
- [x] 빌드 통과 / 런타임 크래시 없음
- [x] 값→참조 전환에 따라 `Sidebar` 의 `$folders` 와 `AddCategoryDialog` 의 `selectedFolderID` 도 같이 정리됨

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `ModelContainer(for: Folder.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))` — 테스트/프리뷰용 인메모리 컨테이너. 다음 단계 이후 Preview 가 깨질 때 유용.
- WWDC23 "Meet SwiftData" 세션 — 30분짜리 도입 영상.
