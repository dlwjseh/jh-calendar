# 폴더·카테고리 데이터 영속화

## 목표
지금까지 메모리상의 샘플 데이터(`Folder.sample`)였던 폴더/카테고리를 **SwiftData** 로 옮겨, 추가/편집/삭제가 디스크에 영속화되고 앱을 재시작해도 유지되게 만든다.

## 의존 관계
- 사전 필요: `04` (사이드바 카테고리 UI), `08` (카테고리 추가 다이얼로그)
- 이후 영향: 일정(Event) 도 SwiftData 로 올릴 때 동일한 패턴이 재사용됨. 카테고리 색상으로 일정을 분류하는 후속 기능의 기반.

## 핵심 변경 요약
- `Folder` / `Category` : `struct` → `@Model class` 로 전환
- `ContentView` 의 `@State private var folders = Folder.sample` 제거 → `@Query var folders: [Folder]` 로 교체
- `JHCalendarApp` 에 `.modelContainer(for: ...)` 부착
- `AddFolderDialog` / `AddCategoryDialog` 의 저장 버튼이 `print()` 대신 `modelContext.insert(...)` 호출
- 폴더/카테고리에 context menu → 삭제 / 편집

## 단계 체크리스트
- [x] 01 - SwiftData 도입 (Folder 를 @Model 로)
- [x] 02 - Category 도 @Model + Relationship
- [x] 03 - Color 영속화 (hex 변환)
- [x] 04 - 폴더 추가 저장
- [x] 05 - 카테고리 추가 저장
- [x] 06 - 삭제 (폴더 / 카테고리)
- [x] 07 - 편집 (폴더 이름 / 카테고리 이름·색상)

## 이 기능에서 학습할 Swift / SwiftUI 개념
- **SwiftData 매크로**: `@Model`, `@Attribute`, `@Relationship`
- **컨테이너 & 컨텍스트**: `ModelContainer`, `ModelContext`, `@Environment(\.modelContext)`
- **선언적 조회**: `@Query` 매크로와 정렬·필터
- **참조 타입 (class) 도입**: 지금까지 써온 `struct` (값 타입) 과의 차이, 그리고 SwiftData 가 왜 class 를 요구하는지
- **관계와 cascade 삭제 규칙**: `@Relationship(deleteRule: .cascade)`
- **직렬화 불가 타입 다루기**: SwiftUI `Color` 를 저장 가능한 형태(hex string)로 변환 후 computed property 로 노출
- **양방향 데이터 흐름과 컨텍스트 자동 저장**: JPA 의 dirty checking 과 닮은 모델

## 자바/스프링 비유 한 줄 매핑
| Spring (JPA) | SwiftData |
|---|---|
| `@Entity` | `@Model` |
| `@Id`, `UUID` 기본키 | `@Attribute(.unique)` 또는 모델의 PersistentIdentifier |
| `@OneToMany(cascade = ALL, orphanRemoval = true)` | `@Relationship(deleteRule: .cascade, inverse: \.folder)` |
| `EntityManagerFactory` | `ModelContainer` |
| `EntityManager` | `ModelContext` |
| `entityManager.persist(e)` | `modelContext.insert(e)` |
| `entityManager.remove(e)` | `modelContext.delete(e)` |
| JPQL `SELECT f FROM Folder f ORDER BY f.name` | `@Query(sort: \.name)` |
| dirty checking 자동 flush | `modelContext` 자동 변경 추적 + 자동 save |
