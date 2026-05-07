# 단계 2: 버튼과 SF Symbols

## 학습 목표
- `Button { action } label: { ... }` 패턴 익히기 — trailing closure 두 개의 모양.
- SF Symbols 로 시스템 아이콘 사용하기 (`Image(systemName:)`).
- macOS 기본 버튼 chrome 을 `.buttonStyle(.plain)` 으로 벗기기.
- 클릭 가능 영역(hit area) 을 label 컨테이너의 frame 으로 확보하는 사고 방식.

## 사전 지식
- 단계 1 결과: `ContentView` 의 ZStack 안에 좌상단 floating 카드(HStack + 배경 + 모서리 + 그림자) 가 떠 있고, 그 안에 placeholder 박스 2개가 들어가 있다.
- 이 단계는 **시각적 추가가 아니라 placeholder 교체**다.

## Swift / SwiftUI 개념

### 1) Button — 두 가지 호출 형태

```swift
// (a) 텍스트 라벨
Button("저장") { print("clicked") }

// (b) 임의의 View 를 라벨로 (이번 단계에서 쓸 형태)
Button {
    print("clicked")
} label: {
    Image(systemName: "plus")
}
```

(b) 는 trailing closure 두 개를 명시적으로 분리한 형태. Swift 에서 `func Button(action: () -> Void, label: () -> some View)` 같은 함수를 호출할 때 마지막 두 클로저를 위와 같이 라벨링해서 쓴다.

> Java/JS 비유: 콜백을 두 개 받는 함수 호출인데, "어떤 게 어떤 인자인지" 가 명시적으로 보이는 형태.

### 2) SF Symbols — 시스템 아이콘

Apple 이 제공하는 수천 개의 벡터 아이콘. 이름만 알면 어디서나 쓴다.

```swift
Image(systemName: "sidebar.left")
Image(systemName: "plus")
```

찾는 법:
- [SF Symbols.app](https://developer.apple.com/sf-symbols/) 을 macOS 에 설치하면 검색 UI 제공
- Xcode 자동완성: `Image(systemName: "side` 까지 치면 후보 표시

사이드바 토글에 자주 쓰이는 후보:
- `sidebar.left`
- `sidebar.leading`
- `square.leftthird.inset.filled`
- `rectangle.leadinghalf.inset.filled`

마음에 드는 걸로 선택.

### 3) `.buttonStyle(.plain)` — 기본 chrome 벗기기

macOS 의 `Button` 은 기본적으로 회색 박스 같은 chrome 을 자동으로 입힌다. floating 카드 안에서는 그게 어색하다 → 벗긴다.

```swift
Button { ... } label: { Image(systemName: "plus") }
    .buttonStyle(.plain)
```

`.plain` 외 옵션:
- `.borderless` — 비슷하지만 호버 강조가 약간 다름
- `.bordered` — 명시적 테두리 박스
- `.borderedProminent` — accent color 강조

이번엔 `.plain`.

### 4) 아이콘 크기/색

SF Symbol 은 텍스트처럼 다뤄진다. `font` 와 `foregroundStyle` 이 그대로 적용.

```swift
Image(systemName: "plus")
    .font(.system(size: 14, weight: .medium))
    .foregroundStyle(.secondary)
```

`foregroundStyle` 의 hierarchical 옵션:
- `.primary` — 보통 짙은 색
- `.secondary` — 한 단계 옅은 색 (이번에 잘 어울림)
- `.tertiary` / `.quaternary` — 더 옅음

### 5) hit area — label 컨테이너의 frame 을 키운다

`Image` 자체에 `frame(width: 14, height: 14)` 을 주면 클릭 가능 영역이 14×14 밖에 안 된다. 보통은:

```swift
Button { ... } label: {
    Image(systemName: "plus")
        .font(.system(size: 14, weight: .medium))
        .frame(width: 28, height: 28)   // ← label 자체를 28×28 로
}
```

이렇게 하면 클릭 가능 영역이 28×28 로 확장된다 — 아이콘은 가운데 작게 그려지지만 주변 빈 공간도 클릭이 먹는다.

## 구현 가이드

수정할 파일: `JHCalendar/ContentView.swift`

단계 1 에서 만든 HStack 안의 placeholder 두 개를 `Button` 두 개로 교체.

골격:
```swift
HStack(spacing: 4) {
    Button {
        // TODO: 추후 사이드바 토글 (이번 단계는 비워두거나 print)
    } label: {
        Image(systemName: /* TODO: 사이드바 아이콘 이름 */)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
    }
    .buttonStyle(.plain)

    Button {
        // TODO: 추후 새 일정 추가
    } label: {
        Image(systemName: "plus")
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.secondary)
            .frame(width: 28, height: 28)
    }
    .buttonStyle(.plain)
}
```

힌트:
- 액션 클로저는 일단 비워두거나 `print("sidebar tapped")` 처럼 동작 확인용 출력만 넣기. 실제 기능은 이후 기능에서.
- `.buttonStyle(.plain)` 을 빼고 한 번 실행해 보면 차이를 직접 체감할 수 있다 — 학습 목적상 한 번쯤 비교 권장.
- 두 버튼 사이 spacing 은 0~6pt 사이가 자연스럽다 (단계 1 의 HStack `spacing` 값).

## 직접 구현하기
- [ ] HStack 안의 placeholder 2개를 `Button` 2개로 교체
- [ ] 첫 버튼: 사이드바 아이콘 (예: `sidebar.left`)
- [ ] 두 번째 버튼: `plus` 아이콘
- [ ] 두 버튼 모두 `.buttonStyle(.plain)`
- [ ] 액션 클로저는 빈 채로 두거나 `print(...)` 정도
- [ ] 각 버튼 label 의 `.frame(width: 28, height: 28)` 으로 hit area 확보
- [ ] ⌘B 빌드 → ⌘R 실행 → floating 카드 안에 아이콘 두 개가 보이는지 확인
- [ ] 클릭 시 print 가 콘솔에 찍히는지 확인 (print 를 넣었다면)
- [ ] (선택) `.buttonStyle(.plain)` 을 잠깐 빼보고 차이 비교

> 다 끝나면 "다 했어" 라고 알려줘. 리뷰할게.

## 자가 점검 (구현 후)
- 빌드 통과? ✅
- 두 버튼이 가로로 정렬돼 보이는가?
- 아이콘 위에 마우스를 올리면 손모양 커서 (또는 highlight) 가 나오는가?
- 자문자답: `Button("저장") { ... }` 와 `Button { ... } label: { ... }` 는 어떻게 다른가? (정답: 전자는 String 라벨, 후자는 임의 View 라벨)
- 자문자답: `.buttonStyle(.plain)` 을 빼면 화면이 어떻게 변하던가? (직접 비교한 인상으로 답해보기)

## Claude 리뷰 체크리스트
*(Claude 가 리뷰 시 사용)*
- [ ] `Button { } label: { }` 패턴이 정확히 쓰임 (action 자리에 view 가 들어가지 않았는지 등)
- [ ] 액션 클로저는 비어 있거나 print 만 (아직 실제 기능 X)
- [ ] `.buttonStyle(.plain)` 적용
- [ ] hit area 가 충분 (label 의 frame ≥ 24×24)
- [ ] 아이콘 크기/색이 floating 카드 톤과 어울림 (`.secondary` 정도)
- [ ] 두 버튼 spacing 이 단계 1 HStack 의 `spacing:` 인자 한 곳에서 일관되게 관리됨

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 호버 시 버튼 배경이 옅게 들어오는 효과: `.onHover` + `@State` 로 직접 구현하거나, 그냥 macOS 기본 hover 가 동작하는 buttonStyle 을 쓰는 방법도 있음.
- `Label("새 일정", systemImage: "plus")` — 텍스트+아이콘 콤보 라벨.
- 키보드 단축키: `.keyboardShortcut("n", modifiers: .command)` 한 줄이면 ⌘N 바인딩 끝.
- SF Symbols 의 **variant**: `Image(systemName: "plus.circle.fill")` 처럼 `.fill`, `.circle`, `.square` 등을 조합해 변형형 사용 가능.
