# 단계 2: ForEach 로 사이드바 채우기 (정적 렌더링)

## 학습 목표
- `ForEach` 를 사용해 컬렉션 → SwiftUI view 변환을 익힌다.
- `VStack(alignment:spacing:)` 으로 좌측 정렬 리스트 레이아웃을 잡는다.
- 폴더 헤더 (작은 회색 caption) + 카테고리 행 (색깔 네모 + 텍스트) 의 시각 위계를 만든다.
- `RoundedRectangle` + `.fill(...)` + 안쪽 체크 표시 (`Image(systemName: "checkmark")`) 의 조합을 익힌다.
- 이번 단계에선 **정적 렌더링** 만 — 데이터의 `isChecked` 를 그대로 표시할 뿐, 클릭 안 됨. 토글은 단계 03.

## 사전 지식
- 단계 01 완료 — `SidebarModels.swift` 에 `Folder`, `Category`, `sampleFolders` (또는 `Folder.sample`) 가 살아 있음.
- `Sidebar.swift` 가 placeholder 상태 (`Color.gray.opacity(0.08).frame(width: 240)`).

## Swift / SwiftUI 개념

### 1) `ForEach` — 컬렉션을 view 로 변환

```swift
ForEach(items) { item in
    Text(item.name)
}
```

- Swift 의 collection (Array, Range 등) 을 받아서 각 element 를 클로저에 넘기고, 그 결과 view 들을 모음.
- `items` 가 `Identifiable` 이면 별도 `id:` 인자 불필요. 단계 01 에서 채택했으므로 OK.
- 만약 `Identifiable` 이 아니면: `ForEach(items, id: \.self)` (element 자체가 Hashable 일 때) 또는 `ForEach(items, id: \.someProperty)`.

> Vue 비유: `<div v-for="item in items" :key="item.id">{{ item.name }}</div>` 와 1:1. SwiftUI 는 key 자리에 `Identifiable.id` 를 자동 사용.

### 2) Nested `ForEach` — 폴더 안의 카테고리

```swift
ForEach(folders) { folder in
    Text(folder.name)        // 폴더 헤더
    ForEach(folder.categories) { category in
        // 카테고리 행
    }
}
```

위 코드가 자연스럽게 잘 작동한다. SwiftUI 의 `ViewBuilder` 가 두 view 를 묶어 처리.

### 3) `VStack(alignment:spacing:)` — 세로 리스트의 정렬과 간격

```swift
VStack(alignment: .leading, spacing: 8) {
    // ...
}
```

- `.leading`: 모든 자식이 좌측에 정렬. 폴더 헤더와 카테고리 행 모두 왼쪽에서 시작.
- `spacing`: 자식들 사이 세로 간격. 8~12pt 정도가 macOS 사이드바 표준.

> 만약 `.leading` 을 안 주면 default `.center` — 모든 자식이 가운데 정렬. 사이드바엔 어색함.

### 4) 폴더 헤더 — 작고 흐릿한 caption

```swift
Text("iCloud")
    .font(.caption)
    .foregroundStyle(.secondary)
```

- `.font(.caption)`: 시스템에서 정의한 작은 글씨 스타일. 매직 사이즈 안 박고 시맨틱 이름 사용.
- `.foregroundStyle(.secondary)`: 시스템이 정의한 "보조" 색상. 라이트/다크 모드에서 알아서 적절한 회색 톤. (구버전 `.foregroundColor(.gray)` 보다 권장.)

### 5) 카테고리 행 — HStack { 네모 + 텍스트 }

```swift
HStack(spacing: 8) {
    // 색깔 네모
    Text(category.name)
}
```

색깔 네모 골격:

```swift
RoundedRectangle(cornerRadius: 4)
    .fill(category.color)
    .frame(width: 16, height: 16)
    .overlay {
        if category.isChecked {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
    }
```

핵심:
- `RoundedRectangle(cornerRadius: 4)` — 모서리 살짝 둥근 사각형.
- `.fill(...)` — 색 채우기.
- `.frame(width:height:)` — 16x16 정도가 macOS 캘린더 톤.
- `.overlay { ... }` — 채워진 사각형 위에 체크 표시를 올림. `if` 로 조건부 — `false` 일 땐 overlay 가 비어 있음.
- `Image(systemName: "checkmark")` — SF Symbols 의 체크 (단계 02-2 에서 다뤘음).

> `.overlay` 는 단계 03-2 에서 트래픽라이트 hover 영역에 쓴 것과 동일한 modifier. 부모 size 에 종속된 위에 올리는 layer.

### 6) 정적 렌더링 + 시각 변화 = isChecked 만 따라감

이번 단계는 **클릭 안 됨**. 데이터의 `isChecked` 가 true 면 체크 표시가 보이고, false 면 안 보임. 그게 전부.

> 만약 직접 데이터의 `isChecked` 값을 바꿔보면서 빌드 → 실행을 반복해 보면, 화면이 따라 바뀌는 게 보일 것. SwiftUI 의 선언형이 작동하고 있다는 증거.

### 7) `isChecked == false` 일 때 색을 흐릿하게? — 일단 단순화

이미지를 보면 unchecked 카테고리 (`직장`, `생일`) 는 색이 옅어 보인다. 이를 흉내내려면 `.opacity(category.isChecked ? 1.0 : 0.4)` 같은 식으로 `RoundedRectangle` 에 modifier 추가.

이번 단계는 **선택**: 시각적으로 더 그럴 듯해 보이고 싶으면 적용. 핵심 학습은 ForEach + 레이아웃이므로 안 해도 OK.

## 구현 가이드

> 정답 풀코드는 제공하지 않는다.

### `Sidebar.swift` 수정

기존 placeholder 를 지우고 본격적인 내용으로 대체:

```swift
struct Sidebar: View {
    var body: some View {
        VStack(alignment: /* 어디 */, spacing: /* 얼마 */) {
            ForEach(/* 단계 01 의 sampleFolders 또는 Folder.sample */) { folder in
                // 폴더 헤더 텍스트
                
                ForEach(folder.categories) { category in
                    // 카테고리 행 (HStack { 색깔 네모 + Text })
                }
            }
        }
        .frame(width: 240, alignment: /* 어디 */)
        .padding(/* ... */)
        .background(Color.gray.opacity(0.08))
    }
}
```

힌트:
- `VStack` 자체는 자식 크기에 맞춰 줄어들려고 함. 사이드바 폭 240 을 유지하려면 `.frame(width: 240)` 유지.
- `.frame(width:alignment:)` 의 alignment 도 `.leading` 또는 `.topLeading` — 안 주면 가운데로 몰림.
- 윗부분 (트래픽라이트 영역) 에 컨텐츠가 너무 붙으면 어색. `.padding(.top, 50)` 정도 또는 폴더 헤더 자체에 top padding.
- 좌우도 살짝 padding (12~16pt).

### 시각 검증

- 사이드바를 열면 (단계 03 의 토글 버튼) 두 폴더 (`iCloud`, `기타`) 와 카테고리들이 좌측 정렬로 보인다.
- 각 카테고리는 색깔 네모 + 이름. `isChecked == true` 인 것은 네모 안에 흰 체크 표시.
- 폴더 헤더는 작고 회색 톤 — 카테고리 텍스트와 시각 위계가 구분됨.
- 사이드바 토글 시 (단계 03 의 슬라이드) 자연스럽게 함께 슬라이드.
- 라이트/다크 모드 양쪽에서 글자 색이 자동으로 적응 (`.foregroundStyle(.secondary)` 와 `.primary` 가 그 일을 함).

### 힌트

- 첫 시도에서 카테고리들이 사이드바 우측 끝까지 늘어나 보이는 게 어색하다면, HStack 마지막에 `Spacer()` 를 추가하지 *않은* 게 정답 — 자식이 자기 크기만큼만 차지하게. 단, HStack 자체의 frame 이 사이드바 폭에 맞춰지도록 부모 VStack 의 `.frame(width: 240, alignment: .leading)` 이 잘 잡혀 있어야 함.
- 폴더 헤더 위에 약간 더 큰 spacing 을 주고 싶다면 `Section` 사이 빈 줄 효과 — `ForEach(folders) { folder in VStack(alignment: .leading, spacing: 8) { /* 헤더 + 카테고리들 */ } }` 같이 폴더당 그룹을 만들고 바깥 VStack 의 spacing 을 더 크게.
- 16x16 네모가 너무 작거나 크면 14~18 사이 시도. 텍스트 font size 와의 비율 감각이 맞아야 함.

### 더 갈 수 있는 지점 (선택)

- `Section { ... } header: { ... }` 를 사용한 List 기반 구현 — macOS 표준 사이드바 스타일과 가까움. 단 List 는 이번 학습 범위 밖이라 후순위.
- unchecked 카테고리의 색 opacity 처리 (위 7번 절 참고).
- `RoundedRectangle` 대신 `Image(systemName: "checkmark.square.fill")` 같은 single SF Symbol 로 체크박스를 표현 — 색 일관성 (`.foregroundStyle(category.color)`) 으로 코드가 짧아질 수도 있음. 단 이미지의 둥근 사각형 톤과는 약간 다름.

## 직접 구현하기
- [x] `Sidebar.swift` 의 placeholder 를 VStack + ForEach 구조로 대체
- [x] 폴더 헤더 텍스트 (`.font(.caption)` + `.foregroundStyle(.secondary)`)
- [x] 카테고리 행 (HStack { RoundedRectangle 색깔 네모 + Text })
- [x] 색깔 네모 안에 `isChecked` 일 때만 체크 표시 (`.overlay { if ... }`)
- [x] `frame(width: 240, alignment: .leading)` 등 사이드바 폭/정렬 유지
- [x] padding 으로 윗쪽 (트래픽라이트 영역) 과 좌우 여백 확보
- [x] ⌘B 빌드 통과 / ⌘R 실행
- [x] 사이드바 토글 시 자연스럽게 슬라이드 + 안의 컨텐츠 표시
- [x] 라이트/다크 모드 양쪽에서 텍스트 가독성 OK
- [ ] (선택) unchecked 색 opacity 흐릿하게

> 다 끝나면 "다 했어" 라고 알려줘.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 자문자답: `ForEach(folders)` 가 별도 `id:` 인자 없이 작동하는 이유? (정답: 단계 01 에서 `Folder: Identifiable` 채택했고 `id` 가 있으므로 자동.)
- 자문자답: `.font(.caption)` / `.foregroundStyle(.secondary)` 같은 시맨틱 이름의 장점? (정답: 라이트/다크 모드/시스템 폰트 크기 변화에 자동 적응. 매직 넘버를 박지 않아 macOS 표준 톤 유지.)
- 자문자답: `.overlay { if category.isChecked { ... } }` 가 의도대로 동작하는 원리? (정답: SwiftUI body 안의 `if` 는 `_ConditionalContent` 로 변환 — 단계 03-2 에서 다룬 내용과 동일. 조건이 false 면 overlay 자식이 view-tree 에서 빠짐.)
- 자문자답: 데이터의 `isChecked` 값을 코드에서 직접 바꾸고 빌드/실행하면 어떻게 되나? (정답: 화면이 따라 바뀜. 이게 단계 03 토글의 토대 — SwiftUI 가 데이터 변화를 자동으로 view 에 반영함.)
- 자문자답: 만약 `VStack` 의 alignment 를 안 주면? (정답: default `.center` 로 모든 자식이 가운데 정렬됨. 사이드바엔 어색.)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [x] `Sidebar.swift` 가 VStack + nested ForEach 로 폴더/카테고리를 그림
- [x] `ForEach` 가 `Identifiable` 자동 식별 사용 (별도 `id:` 인자 없음)
- [x] 폴더 헤더와 카테고리 행의 시각 위계가 구분됨 (font/color)
- [x] 색깔 네모 + 체크 표시가 `RoundedRectangle` + `.fill` + `.overlay { if isChecked }` 패턴
- [x] `.foregroundStyle(.secondary)` 등 시맨틱 색 사용 (매직 색 코드 피함)
- [x] 사이드바 폭 240 이 유지되고 정렬은 leading
- [x] 라이트/다크 모드 양쪽에서 어색함 없음
- [x] 단계 03 의 슬라이드 + push 와 어울림

### 리뷰 메모 (2026-05-11)
- `.frame` 을 두 번 호출 → `.frame(width: 240, maxHeight: .infinity, alignment: .topLeading)` 한 줄로 합칠 수 있음. 동작 동일, 가독성↑. (단계 03 진입 전 또는 그 안에서 정리)
- `Folder.sample` 직접 참조는 단계 03 에서 `@State` 로 끌어올릴 예정이라 지금은 OK.

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- **`Section` 으로 그룹 표현**: SwiftUI 의 `Section { ... } header: { ... }` 를 사용하면 폴더-카테고리 관계가 더 명시적. List 와 함께 쓰면 macOS 표준 사이드바 스타일.
- **List 기반으로 옮겨보기**: `List` 안의 `Section` + `ForEach` — macOS 사이드바의 표준 컨테이너. 단 default 스타일/Selection/scroll 동작이 따라와서 학습 비용 있음. 후속 기능에서 본격 도입.
- **시각 polish**: unchecked 의 opacity, 행 간격 미세 튜닝, 폴더 사이 빈 줄. macOS 캘린더 톤에 맞춰 실험.
- **카테고리 행 클릭 영역 (preview)**: 단계 03 의 미리보기로 색깔 네모를 `Button` 안에 넣어보고 클릭이 들어오는지 print 로 찍어보기. 토글 동작은 단계 03 에서 본격 도입.
