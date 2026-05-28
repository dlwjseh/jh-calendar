# 공휴일 표시

## 목표
한국천문연구원 특일 정보 API 로 받아온 **법정 공휴일** 을 달력에 마치 이벤트가 등록된 것처럼 표시한다. 사용자 이벤트와 달리 read-only — 추가/수정/삭제 불가, 일 셀과 일 팝업에서만 보여준다.

## 의존 관계
- 사전 필요:
  - `05-월간-달력-UI` — `DayCellView`, `WeekRowView` 의 day number / 이벤트 표시 구조
  - `06-주말-색상` — 일/토 색상 분기 (`textColor`)
  - `11-달력-이벤트-표시` — 이벤트 렌더링 패턴 (allDay bar 등)
  - `12-일-팝업` — `DayPopupDialog` 의 행 구조
  - `17-오늘-표시-와-버튼` — `textColor` 우선순위 규칙
- 이후 영향: 음력 표기, 사용자 커스텀 캘린더(반차/생일 등) 도 동일 패턴으로 확장 가능

## 단계 체크리스트
- [x] 01 - API 키 보관 (xcconfig + Info.plist)
- [x] 02 - 공휴일 API 호출 + JSON 디코딩 (PoC)
- [x] 03 - HolidayStore + 연 단위 캐싱
- [x] 04 - 달력 셀에 공휴일 표시
- [ ] 05 - 일 팝업 / 이벤트 다이얼로그 read-only 처리

## 이 기능에서 학습할 Swift / SwiftUI 개념

**새로 등장**:
- **xcconfig 파일** + **Info.plist 변수 주입** (`$(VARIABLE)`) — 비밀값을 코드/git 에서 분리하는 표준 패턴. (Spring 의 `application-secret.yml` 분리 + `@Value` 주입 결.)
- **`URLSession` + `async / await`** — Swift Concurrency 의 첫 진입. (Java 의 `CompletableFuture` 보다는 JS `async/await` 와 거의 동일한 모양.)
- **`Codable` (`Decodable`)** + `JSONDecoder` — JSON ↔ struct 자동 매핑. Jackson 의 `ObjectMapper.readValue(json, MyClass.class)` 와 결이 같다.
- **`do / try / catch`** + `throws` 함수 — Swift 의 검사 가능한 에러 핸들링. Java `throws` 와 비슷하지만 함수 시그니처에 `throws` 단어 하나만 붙는다.
- **`Bundle.main.object(forInfoDictionaryKey:)`** — Info.plist 값을 런타임에 읽기.
- **`URLComponents` + `URLQueryItem`** — 쿼리스트링 안전하게 조립 (직접 문자열 연결 X).
- **`@Observable` 매크로** (Swift 5.9+) — `ObservableObject` + `@Published` 의 후속 단순화 매크로. (단, 이미 `CalendarStore` 가 `ObservableObject` 라 이번 단계는 일관성 위해 `ObservableObject` 를 그대로 쓸 수도 있음. 03 단계에서 결정.)
- **`.task` modifier** — view 가 화면에 올라올 때 비동기 작업 실행, 사라지면 자동 cancel. `onAppear` 의 async 버전.
- **`UserDefaults` + Codable JSON** — 작은 비밀번호·설정 저장소. (Spring 의 `application.properties` 비교 X — 그건 정적, 이건 런타임 가변 KV.)

**다시 쓰는 개념** (링크):
- `Calendar.current.startOfDay(for:)` 로 날짜 키 정규화 → [Calendar-와-Date](../자주-쓰는-기술들/Calendar-와-Date.md)
- 이벤트 렌더링 패턴 (`background(RoundedRectangle)` + `.foregroundStyle(.white)`) → [11-04 종일 이벤트 바 렌더링](../11-달력-이벤트-표시/04-종일-이벤트-바-렌더링.md)
- `textColor` 우선순위 분기 → [17-01](../17-오늘-표시-와-버튼/01-오늘-셀-강조.md)
- `DayPopupDialog` 의 `@Query` 구조, `DayPopupEventRow` 의 컨텍스트 메뉴 → [12-일-팝업](../12-일-팝업/README.md)

## 데이터 소스
- **한국천문연구원 특일 정보 서비스** — 공공데이터포털 (`apis.data.go.kr/B090041/openapi/service/SpcdeInfoService`)
- **endpoint**: `getRestDeInfo` — 법정 공휴일만 (대체공휴일, 임시공휴일 포함)
- **인증**: 서비스키 (Encoding 된 키를 `serviceKey` 쿼리 파라미터로 전달)
- **응답 포맷**: 기본 XML. `_type=json` 파라미터로 JSON 도 가능 → **JSON 사용** (학습 가벼움)
- **호출 단위**: 연도 + (선택)월 — 본 프로젝트는 **연 단위** 로 한 번에 받아 캐싱

## 캐싱 전략
- **저장소**: `UserDefaults` (key: `holidays.YYYY`, value: `Data` — `HolidayCacheEntry { holidays, cachedAt }` 의 Codable JSON)
- **갱신**:
  - 매 앱 실행 시 표시 중인 달의 연도가 캐시에 없으면 fetch → 디스크 + 메모리에 저장
  - 같은 세션 안에서는 `loadedYears: Set<Int>` 가드로 중복 호출 방지
- **TTL**:
  - **현재 연도**: 7일. `cachedAt + 7일` 지나면 stale → 다음 앱 실행 시 재요청. 임시공휴일 (정부가 연중에 지정) 반영용.
  - **과거 연도**: 영구. 사후 변경되는 일이 사실상 없음.
  - **미래 연도**: 영구. 사용자가 거기까지 갈 일이 드물고 임시공휴일 추가 가능성도 낮다는 단순화 가정.
- **stale fallback**: 네트워크 실패 + stale 캐시 존재 → stale 데이터라도 화면에 띄움 (오프라인일 때 "비어보이는" 것보다 나음).
- **이유**:
  - 공휴일은 거의 변하지 않는 데이터 → SwiftData 까지 갈 필요 X
  - 사용자가 수정하지 않음 → 단순 캐시면 충분
  - 임시공휴일 대비는 필요 → TTL 한 줄로 해결
  - 학습 가치: `UserDefaults + Codable` 조합 + `Date` + `TimeInterval` 기반 TTL 패턴은 macOS/iOS 에서 매우 자주 쓰임

## 동작 규칙
- 공휴일 셀의 **일 숫자는 빨강** (일요일과 동일)
- 일 셀 안 일정 영역에 공휴일 이름이 **빨강 텍스트** 로 (또는 옅은 빨강 배경 + 흰 글자 — 04 단계에서 결정)
- 일 팝업에도 동일하게 표시. 단 **컨텍스트 메뉴 "삭제" 없음**, 클릭해도 편집 다이얼로그 안 열림
- 사용자가 같은 날짜에 자신의 이벤트를 추가하는 것은 가능

## 가정 / 비범위
- 음력 공휴일·24절기·기타 기념일 (`getHoliDeInfo` 외 endpoint) 은 **다루지 않음** — `getRestDeInfo` 의 법정 공휴일만.
- 다국가 공휴일·언어 전환 없음 — 한국 공휴일 한정.
- 오프라인 첫 실행 시 그 해 공휴일 못 받는 케이스는 "다음 온라인 호출 시 받음" 으로 처리 (재시도 UI 따로 없음).
