# 단계 4: 행 overlay 로 단색 멀티데이 바 (단일 lane, 한 주 안)

> 새 개념은 거의 없음. `.overlay` + `.frame(width:, alignment:)` + 산수로 좌표/길이 계산.
> `.overlay` → [02-05](../02-상단-플로팅-툴바/05-HoverButton%20분리와%20hover%20배경.md), [08-03](../08-카테고리-추가-다이얼로그/03-다이얼로그%20컨테이너와%20어두운%20배경.md) 참고.

## 작업 목표
03 단계에서 얻은 `rowWidth` 와 `weekMultidays` 를 이용해, 각 멀티데이 이벤트를 **`WeekRowView` 위에 가로지르는 단색 바** 로 그린다. 이번 단계는 **단순화 가정** 으로 시작:

- 한 주에 멀티데이가 여러 개 있어도 **세로로 겹쳐서 다 같은 자리** 에 (lane 배치는 08 에서)
- **이벤트가 그 주 안에 완전히 들어간다고 가정** (주 경계 토막은 07 에서)
- 텍스트/아이콘/캡 없음, 단색 직사각형만 (06, 11 에서)

→ 셀 안 토막바와 **겹쳐서** 표시되어도 OK. 다음 단계 05 에서 셀 토막을 끈다.

## 사전 지식
- [02-05](../02-상단-플로팅-툴바/05-HoverButton%20분리와%20hover%20배경.md) — `.overlay` 의 기본
- 셀 너비 = `rowWidth / 7` 임을 받아들이기 (행 너비를 7등분)

## 작업 가이드

**1) 멀티데이 한 개의 가로 위치/길이 계산**

이벤트가 "그 주 안에 완전히 들어간다" 고 가정하면:

```swift
// 주의 일요일 = row.first!.date (의 startOfDay)
// 이벤트 시작 칸 인덱스 = (event.startDate 의 startOfDay - 주 시작) / 1일
// 이벤트 일수      = (event.endDate 의 startOfDay - event.startDate 의 startOfDay) / 1일 + 1
```

코드로:

```swift
private func barFrame(for event: Event, weekStart: Date, rowWidth: CGFloat) -> (x: CGFloat, width: CGFloat) {
    let cellWidth = rowWidth / 7
    let startKey = cal.startOfDay(for: event.startDate)
    let endKey   = cal.startOfDay(for: event.endDate)
    let startCol = max(0, cal.dateComponents([.day], from: weekStart, to: startKey).day ?? 0)
    let dayCount = (cal.dateComponents([.day], from: startKey, to: endKey).day ?? 0) + 1
    let endCol   = min(7, startCol + dayCount)            // 주 경계 안으로 클램프
    return (x: CGFloat(startCol) * cellWidth,
            width: CGFloat(endCol - startCol) * cellWidth)
}
```

- `cal.dateComponents([.day], from: a, to: b).day` 로 두 날 사이 일수 차이 (→ [Calendar-와-Date 3-7](../자주-쓰는-기술들/Calendar-와-Date.md))
- `endCol = min(7, ...)` 클램프는 다음 단계(07) 전에 임시로 주 안에 가두기 위함. 07 에서 본격 토막은 `DateInterval.intersection` 으로 더 깔끔하게 다시 함.

**2) `.overlay` 로 행 위에 바 얹기**

`GeometryReader` 안, `HStack` 위에 overlay 를 단다:

```swift
GeometryReader { geo in
    let rowWidth = geo.size.width
    let weekStart = cal.startOfDay(for: row.first?.date ?? Date())

    HStack(spacing: 0) { /* 셀들 */ }
        .overlay(alignment: .topLeading) {
            // 멀티데이 바들
            ZStack(alignment: .topLeading) {
                ForEach(weekMultidays) { event in
                    let f = barFrame(for: event, weekStart: weekStart, rowWidth: rowWidth)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(event.color)
                        .frame(width: f.width, height: 16)
                        .offset(x: f.x, y: 24)       // y 는 day 번호 텍스트 아래 정도
                }
            }
        }
}
```

핵심 modifier 들:
- **`.overlay(alignment: .topLeading)`** — 좌상단 기준으로 안에 layer 얹기. 위치 계산이 left/top 기준으로 직관적.
- **`ZStack(alignment: .topLeading)`** — 이벤트 여러 개를 같은 기준점으로 쌓기.
- **`.frame(width:, height:)`** + **`.offset(x:, y:)`** — 폭/길이 명시 + 정확한 위치 이동.

> `.frame(maxWidth: .infinity, alignment: .leading)` 도 아래쪽에 자주 나왔는데, 그건 부모 안에서 "남는 공간을 다 쓰되 왼쪽 정렬" 의도. 여기선 **정확한 폭**을 줘야 하므로 `width:` 를 직접 지정.

**3) y 위치는 일단 대충**

`offset(y: 24)` 같은 마법수는 다음 단계들에서 정리됨:
- 05: 셀 내부 토막 끄기
- 08~09: lane 인덱스 × bar 높이 + spacing 으로 y 계산
- 09: 셀 내부 컨텐츠가 멀티데이 아래로 자연스럽게 위치

지금은 "day 번호 텍스트 아래에 보이도록" 만 맞추면 됨.

## 직접 구현하기
- [ ] `barFrame(for:weekStart:rowWidth:)` 함수 추가 (또는 인라인 계산)
- [ ] `WeekRowView` body 의 `HStack` 에 `.overlay { ZStack { ForEach { Rect } } }` 추가
- [ ] 멀티데이 한 개 만들어 보고, 시작 칸~끝 칸 가로질러 단색 바가 보이는지
- [ ] 같은 주에 멀티데이 2~3개 만들어 보고, 세로로 겹쳐서 다 그려지는지 (lane 배치 X 라 겹침이 정상)
- [ ] 셀 안 토막 바와 같이 보임 → 정상 (단계 05 에서 셀 토막을 끈다)

## 자가 점검
- 빌드 통과?
- 바의 가로 위치가 셀 경계와 잘 맞는지 (예: 화 ~ 목 멀티데이 → 화 셀의 왼쪽 끝부터 목 셀의 오른쪽 끝까지)
- 다음 단계(05) 와 헷갈리지 않도록 — 지금은 **셀 안 토막 + 행 overlay 바** 둘 다 보이는 게 정상.
- 퀴즈: `.offset` 대신 `.padding(.leading, f.x)` 를 써도 같은 효과? 차이는?

## Claude 리뷰 체크리스트
- [ ] 가로 좌표 계산이 `dateComponents([.day], from:to:)` 한 곳으로 통일 (수동 timestamp 산술 없음)
- [ ] `endCol = min(7, ...)` 클램프 — 주 경계 안으로 가둠 (다음 단계 07 에서 진짜 토막 처리로 대체될 임시)
- [ ] `.overlay(alignment: .topLeading)` + `ZStack(alignment: .topLeading)` 으로 좌상단 기준 통일
- [ ] `.frame(width: f.width, height: 16)` + `.offset(x: f.x, y: 24)` — width 는 정확히 지정, y 는 임시값

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `.offset` 은 **레이아웃에 영향을 주지 않는 시각적 이동** (뒤 형제 layout 계산에 안 잡힘). 정확한 자리 잡기엔 OK. 만약 layout flow 안에서 자리를 차지하게 하려면 `Spacer` / `padding` 조합.
- 바의 `cornerRadius: 3` 은 임시 — 11 단계에서 좌/우 끝 셀에서 둥글, 중간은 평평하게 분기.
