# 단계 1: Folder / Category 모델 + 더미 데이터셋

## 학습 목표
- Swift 의 `struct` 로 데이터 모델을 정의한다 — Java 의 record / Vue 의 plain object 대신.
- `Identifiable` 프로토콜을 채택해 SwiftUI 의 `ForEach` 가 element 를 식별할 수 있게 한다.
- `UUID` 로 자동 식별자 만드는 관용 패턴을 익힌다.
- SwiftUI 의 `Color` 타입을 데이터 모델에 직접 넣어도 되는지 (yes) 의 직관 형성.
- struct (값 타입) 와 class (참조 타입) 의 핵심 차이를 한 번 짚는다 — 단계 03 의 mutation 흐름을 이해하기 위한 토대.

## 사전 지식
- 단계 03 (사이드바 슬라이드) 완료 — `Features/Sidebar/Sidebar.swift` 가 살아 있고 240pt 폭의 placeholder 상태.
- Swift 기본 문법은 단계 02~03 에서 어느 정도 만져봄 (struct, View 정의 등).

## Swift / SwiftUI 개념

### 1) struct — Swift 의 데이터 모델 기본형

Swift 의 `struct` 는 Java 의 **record** 에 가장 가깝다.

```swift
struct Category {
    var name: String
    var color: Color
    var isChecked: Bool
}
```

특징:
- **자동 memberwise init**: `Category(name: "집", color: .red, isChecked: true)` 같은 생성자가 컴파일러 자동 생성. `let` 으로 선언한 프로퍼티는 init 인자로 강제 등장 (default 값 주면 optional).
- **값 타입 (value type)**: 변수에 할당/함수에 전달할 때 **복사** 됨. Java 의 record 와 같음. JS 객체와는 다름 (JS 는 항상 참조).
- **mutability** 는 `let` (불변) / `var` (가변) 으로 결정. 위에선 `var` 라 mutation 가능 — 단계 03 의 toggle 에 필요.

> Java 비유: `record Category(String name, Color color, boolean isChecked)` 와 거의 1:1. 차이는 Swift 가 자동으로 mutation 가능하게 만들 수도 있다는 것 (`var` 프로퍼티).

### 2) class 가 아닌 struct 를 쓰는 이유 (간단히)

Swift 는 **struct 우선**. class 는 다음 중 하나일 때만 쓴다:
- 참조 의미가 본질일 때 (예: 같은 인스턴스를 여러 곳이 동시에 보고 mutation 을 공유)
- Objective-C / 시스템 framework 와의 상호작용 필요할 때
- 상속이 필요할 때

SwiftUI 의 데이터는 **struct + @State / @Binding** 조합이 표준이다. 값 타입은 SwiftUI 의 "diff & re-render" 모델과 잘 맞고, 의도치 않은 공유 mutation 버그를 컴파일 타임에 차단해 준다.

> Java 비유: 모든 데이터가 클래스인 Java 와 정반대 방향. JS 의 immutable update (Redux 의 `{ ...state, foo: bar }`) 와 정신적으로 비슷.

### 3) `Identifiable` 프로토콜

```swift
protocol Identifiable {
    associatedtype ID: Hashable
    var id: ID { get }
}
```

이게 전부. **`id` 프로퍼티 하나만 있으면 적합.** SwiftUI 의 `ForEach` 가 컬렉션을 그릴 때 각 element 를 식별하기 위해 사용.

채택 방법:

```swift
struct Category: Identifiable {
    let id = UUID()
    var name: String
    // ...
}
```

- `let id = UUID()` — 인스턴스가 만들어지는 시점에 자동으로 무작위 ID 부여. 메모리 주소가 아닌 안정 식별자.
- protocol 채택 (`: Identifiable`) 만 적으면 됨 — Swift 가 컴파일 타임에 conformance 확인.

> Java 비유: interface implements. 차이는 `id` 프로퍼티만 자동으로 매칭되면 끝 — boilerplate 없음.

### 4) `UUID` — Foundation 의 식별자 타입

`import Foundation` 후 `UUID()` 로 새 ID 생성. 128-bit 무작위. 파일에 `import SwiftUI` 만 있어도 SwiftUI 가 Foundation 을 transitively import 하므로 추가 import 불필요.

> Java 비유: `java.util.UUID.randomUUID()` 와 같음.

### 5) `Color` 를 모델에 넣어도 되나?

OK. SwiftUI 의 `Color` 는 **값 타입** 이고 immutable. 모델 프로퍼티로 직접 갖고 다녀도 무리 없다.

대안 (학습 후순위):
- 색상을 `enum` (예: `.red`, `.blue`, `.yellow`) 으로 추상화 → view 단에서 Color 로 변환. 데이터-뷰 분리가 더 깔끔하지만 코드 양이 늘어남. 이번 단계에선 직접 `Color` 넣기.

`Color` 사용:
```swift
.red                    // 시스템 빨강
.blue                   // 시스템 파랑
.yellow                 // 시스템 노랑
.purple                 // 시스템 보라
.gray                   // 시스템 회색
Color(red: 1.0, green: 0.5, blue: 0.5)  // 임의 RGB
```

이미지에 맞추려면 시스템 색 중에서 `.red`, `.yellow`, `.blue`, `.gray`, `.purple` 정도로 충분.

### 6) Folder = Categories 컬렉션을 가진 struct

```swift
struct Folder: Identifiable {
    let id = UUID()
    var name: String
    var categories: [Category]
}
```

- `[Category]` 는 `Array<Category>` — Swift 의 표준 배열, 값 타입.
- `var` 라 추후 `categories.append(...)` 같은 mutation 가능 (이번 단계엔 안 씀).

### 7) 더미 데이터 — 어디에 둘까?

여러 패턴이 있음:

(a) 모듈 최상위 `let sampleData: [Folder] = [...]` — 단순. 본 단계 권장.

(b) `extension Folder { static let sample: [Folder] = [...] }` — namespace 가 깔끔. 약간 더 관용적.

(c) 별도 `SampleData.swift` 파일 — 데이터가 커지면.

이번 단계는 (a) 또는 (b) 중 하나로. 둘 다 학습 가치 있음. (b) 가 살짝 Swift 답.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다.

### 새 파일: `JHCalendar/Features/Sidebar/SidebarModels.swift`

```swift
import SwiftUI

struct Category: Identifiable {
    let id = UUID()
    var name: String
    var color: Color
    var isChecked: Bool
}

struct Folder: Identifiable {
    let id = UUID()
    var name: String
    var categories: [Category]
}

// 더미 데이터 — 이미지에 맞춰 채우기
// (a) let sampleFolders: [Folder] = [ ... ]
// 또는 (b) extension Folder { static let sample: [Folder] = [ ... ] }
```

이미지 매핑 (참고):
- **iCloud** 폴더
  - 집 / `.red` / checked
  - 직장 / `.yellow` / unchecked
- **기타** 폴더
  - 예정된 미리 알림 / `.blue` / checked
  - 생일 / `.gray` / unchecked
  - 대한민국 공휴일 / `.purple` / checked
  - Siri 제안 / `.yellow` / checked

> isChecked 의 true/false 는 본인 판단으로 OK — 단계 02 에서 시각 확인 시 적절히 보이는 조합으로 정하면 됨. 위는 이미지 색의 진하기에서 추정한 값.

### Xcode 프로젝트 등록

새 파일을 만들면 `JHCalendar.xcodeproj/project.pbxproj` 의 4 군데에 등록해야 빌드 대상에 포함된다 (`CLAUDE.md` 의 "새 기능을 추가할 때" 참고). `Features/Sidebar/` 그룹의 children 에 추가.

### 빌드 / 실행 확인

이번 단계만으로는 화면에 아무것도 안 변함 (모델만 추가). 빌드 통과만 확인.

```bash
xcodebuild -project JHCalendar.xcodeproj -scheme JHCalendar -configuration Debug build
```

### 힌트

- `Color` 가 `Equatable` 이지만 `Hashable` 은 아님. 모델 자체를 `Hashable` 로 만들고 싶으면 `struct Category: Identifiable, Hashable` 로 적되 `Color` 가 Hashable 이 아니라 컴파일 에러가 날 수 있음. 이번 단계엔 `Hashable` 안 채택해도 됨.
- `id` 가 `UUID` 면 자동 default `Hashable` (UUID 가 Hashable 이라). `Identifiable` 의 associatedtype `ID: Hashable` 조건이 자동 만족.
- 더미 데이터를 (b) `static let sample` 패턴으로 만들 땐 `extension Folder` 안에 `[Folder]` 를 두는 게 자연스러움 — 자기 자신 타입의 컬렉션 sample.
- 처음엔 `var isChecked: Bool` 로 `var` 임을 잊지 말 것 — `let` 이면 단계 03 에서 toggle 못 함. (Swift 컴파일러가 mutation 시점에 친절히 알려주긴 함.)

## 직접 구현하기
- [x] `JHCalendar/Features/Sidebar/SidebarModels.swift` 생성
- [x] `Category` struct 정의 (Identifiable, name/color/isChecked)
- [x] `Folder` struct 정의 (Identifiable, name/categories) — 본 구현은 `CategoryFolder` 로 명명
- [x] 이미지에 맞춰 `sampleFolders` 또는 `Folder.sample` 더미 데이터 작성
- [x] ~~`JHCalendar.xcodeproj/project.pbxproj` 의 4 군데에 새 파일 등록~~ — `Sidebar/` 가 `PBXFileSystemSynchronizedRootGroup` 이라 자동 포함
- [x] ⌘B 빌드 통과

> 다 끝나면 "다 했어" 라고 알려줘. 이번 단계는 시각 변화 없음 — 단계 02 에서 그릴 것.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: `struct` 와 `class` 의 차이? (정답: struct 는 값 타입 (복사), class 는 참조 타입 (공유). SwiftUI 데이터는 struct 우선.)
- 자문자답: `Identifiable` 채택은 왜 필요? (정답: ForEach 가 컬렉션 element 를 식별해 효율적인 diff & re-render 를 하기 위함. id 프로퍼티 하나만 있으면 자동 적합.)
- 자문자답: `let id = UUID()` 의 의미? (정답: 인스턴스 생성 시점에 무작위 128-bit ID 부여. 메모리 주소와 무관한 안정 식별자.)
- 자문자답: 모델에 `Color` 같은 SwiftUI 타입을 넣는 게 OK 인 이유? (정답: Color 는 값 타입 + immutable. 모델 프로퍼티로 안전. 다만 데이터-뷰 분리가 엄격히 필요한 경우 enum 추상화 가능.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `Category` / `Folder` 모두 `struct` (class 아님)
- [x] `Identifiable` 채택 + `let id = UUID()`
- [x] `Category.isChecked` 가 `var` (단계 03 의 toggle 위해)
- [x] 더미 데이터가 이미지의 색/이름과 매칭 (일부 색·체크 상태는 학습 편의로 변형)
- [x] ~~새 파일이 xcodeproj 의 4 군데 (PBXFileReference, PBXBuildFile, group children, PBXSourcesBuildPhase) 모두 등록~~ — `Sidebar/` 가 PBXFileSystemSynchronizedRootGroup 으로 등록돼 있어 폴더 동기화. 일반 그룹과 다르게 수동 등록 불필요
- [x] 빌드 통과

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 실제 구현 메모
- `Folder` → `CategoryFolder` 로 명명. 도메인 명확성 우선.
- `Sidebar/` 폴더가 Xcode 의 **PBXFileSystemSynchronizedRootGroup** (= 폴더 동기화) 으로 등록돼 있어 새 Swift 파일을 만들면 자동으로 빌드 대상에 포함됨. 일반 PBXGroup 일 때 필요한 `pbxproj` 4 군데 수동 등록은 이 폴더에선 불필요.
- 더미 데이터에서 `isChecked` 일부를 `false` 로 두어, 단계 02 의 시각 검증 시 체크/미체크 차이가 보이게 함.

## 조금 더 (선택)
- **`Hashable` 채택**: `Color` 가 Hashable 이 아니라서 자동 합성이 안 됨. 직접 `func hash(into:)` 구현하거나 `id` 만 비교하는 식으로 우회. 학습 후순위.
- **색상을 `enum` 으로 추상화**: `enum CategoryColor { case red, yellow, blue, ... }` → view 단에서 Color 로 변환. 데이터-뷰 분리가 더 엄격해지지만 코드 양이 늘어남. 후속 기능에서 색상 커스터마이징을 도입할 때 다시 고려.
- **모델을 별도 모듈/폴더로 분리**: 데이터 모델이 늘어나면 `Models/` 같은 별도 폴더 — 지금은 `Features/Sidebar/` 안에 같이 둬도 OK.
- **`Codable` 채택**: 추후 디스크 저장/네트워크 통신을 위해 `: Codable` 추가. 지금은 불필요하지만 미리 채택해도 비용 거의 없음.
