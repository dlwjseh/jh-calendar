# 단계 2: 공휴일 API 호출 + JSON 디코딩 (PoC)

## 학습 목표
- `URLSession` + `async / await` 로 HTTP GET 호출하는 가장 기본 형태를 손으로 짜본다.
- `Codable` (`Decodable`) struct 로 JSON 응답을 매핑한다.
- `do / try / catch` 로 throws 함수를 호출·처리한다.
- 이 단계에서는 **모델 / 저장은 하지 않는다.** 받아온 JSON 을 print 로만 확인 → 03 에서 스토어로 묶음.

## 사전 산출물
- [01-API-키-보관](01-API-키-보관.md) 에서 `Bundle.main.object(forInfoDictionaryKey: "HOLIDAY_API_KEY")` 으로 키가 잘 조회되는 상태.
- `Secrets` enum 같은 정적 접근점 (`Secrets.holidayApiKey`) — 권장.

## Swift / SwiftUI 개념

### URLSession 한 줄로 GET 요청

```swift
let (data, response) = try await URLSession.shared.data(from: url)
```

- `URLSession.shared` — 기본 세션. 커스텀 설정 (timeout, header) 안 필요하면 이거면 충분.
- `data(from:)` 는 `async throws` — `try await` 둘 다 필요.
- 반환: `(Data, URLResponse)` — 응답 본문 바이트 + 메타정보 (status code 등).

> Java 비유: `HttpClient.send(request, BodyHandlers.ofString())` 의 동기 호출 모양과 흐름이 같은데, 스레드를 안 막고 suspend.
>
> JS 비유: `const r = await fetch(url); const data = await r.arrayBuffer();` 와 거의 동일. Swift 는 두 await 를 한 번에.

### async / await

```swift
func fetchHolidays(year: Int) async throws -> [HolidayDTO] {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(Response.self, from: data).response.body.items.item
}
```

- 함수에 `async` 키워드 → "이 함수는 suspend 될 수 있음".
- 호출 측에서는 반드시 `await` 로 호출. `try` 와 함께 쓰면 `try await`.
- 일반 동기 함수에서는 `async` 함수를 직접 못 부른다 — `Task { await ... }` 으로 비동기 컨텍스트를 열어 진입.

> JS 의 `async/await` 와 거의 동일. 차이: Swift 는 `throws` 가 별도 표시.

### `do / try / catch` + throws

```swift
do {
    let items = try await fetchHolidays(year: 2026)
    print(items)
} catch {
    print("실패:", error)
}
```

- `try` 가 붙은 호출이 throw 하면 같은 `do` 블록의 `catch` 로 점프.
- `catch` 의 암묵 변수 `error` 는 `Error` 프로토콜 타입.
- 다중 catch 패턴 매칭 가능 (`catch let e as URLError`, `catch DecodingError.keyNotFound(...)`).

> Java 의 try/catch 와 결이 같다. 차이: 모든 throws 호출 앞에 `try` 명시 필요 — "여기서 던질 수 있다" 가 코드에 항상 보이게.

### Codable struct 로 JSON 매핑

한국천문연구원 응답은 중첩이 깊다 — 그대로 매핑할 struct 트리를 만든다.

```json
{
  "response": {
    "header": { "resultCode": "00", "resultMsg": "NORMAL SERVICE." },
    "body": {
      "items": {
        "item": [
          { "dateKind": "01", "dateName": "1월1일", "isHoliday": "Y", "locdate": 20260101, "seq": 1 },
          ...
        ]
      },
      "numOfRows": 10,
      "pageNo": 1,
      "totalCount": 15
    }
  }
}
```

> 함정 ①: `item` 이 **단일 객체일 때와 배열일 때가 다르게** 옴. (공공데이터포털 공통 패턴 — 결과가 1개면 `{...}`, 2개 이상이면 `[{...}, ...]`.) JSON 사용 시에도 그런 경우가 종종 있음.
>
> 우리는 연 단위 호출이라 항상 다건 → 배열로 와야 정상. 다만 안전 장치로 단일 객체 케이스도 처리하면 더 robust. **본 단계에서는 일단 배열만 가정하고 동작 확인 → 한 건짜리 연도(거의 없음)/에러 케이스는 03에서 보완.**

```swift
struct HolidayResponse: Decodable {
    let response: Body
    struct Body: Decodable {
        let header: Header
        let body: Items
    }
    struct Header: Decodable {
        let resultCode: String
        let resultMsg: String
    }
    struct Items: Decodable {
        let items: ItemList
    }
    struct ItemList: Decodable {
        let item: [HolidayDTO]
    }
}

struct HolidayDTO: Decodable {
    let dateName: String   // "삼일절"
    let isHoliday: String  // "Y" / "N" — getRestDeInfo 는 항상 "Y"
    let locdate: Int       // 20260301
}
```

- 함정 ②: 응답이 **에러 / 결과 0건** 일 때 `body.items` 가 `""` (빈 문자열) 로 오는 경우가 있다. 그러면 `Items` 의 `items` 디코딩이 깨진다. 본 PoC 에서는 정상 결과만 가정, 03 단계에서 `try?` + 기본값 패턴으로 보강.

### URLComponents 로 쿼리 안전 조립

```swift
var comp = URLComponents(string: "https://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo")!
comp.queryItems = [
    URLQueryItem(name: "solYear", value: "2026"),
    URLQueryItem(name: "numOfRows", value: "100"),
    URLQueryItem(name: "_type", value: "json"),
    URLQueryItem(name: "ServiceKey", value: Secrets.holidayApiKey)
]
let url = comp.url!
```

- 문자열 연결로 만들면 인코딩 사고가 잦다 (`+`, `=`, `&` 등). `URLQueryItem` 은 자동 percent-encoding.
- **함정 ③**: 공공데이터포털 키는 보통 **이미 인코딩된** 문자열을 준다. 그걸 `URLQueryItem(value:)` 에 그대로 넣으면 **이중 인코딩** 이 일어나 인증 실패. → 받은 키를 한 번 **디코딩해서** 넣거나, 직접 query 문자열 조립.

이 함정을 어떻게 다룰지 두 선택지:

**A. 디코딩 본 사용**: `Encoding 본` 을 `removingPercentEncoding` 해서 `URLQueryItem` 에 넣기.
```swift
let raw = Secrets.holidayApiKey.removingPercentEncoding ?? Secrets.holidayApiKey
URLQueryItem(name: "ServiceKey", value: raw)
```

**B. `percentEncodedQuery` 직접 조립**: `URLComponents.percentEncodedQuery` 에 직접 문자열 박기 — 자동 인코딩 우회.
```swift
comp.percentEncodedQuery = "solYear=2026&numOfRows=100&_type=json&ServiceKey=\(Secrets.holidayApiKey)"
```

> 권장: **A**. 두 본 (Encoding/Decoding) 중 어느 본을 받았든 `removingPercentEncoding` 한 번 통과시키면 깨끗한 원문. 이중 인코딩 회피.

## 구현 가이드

이 PoC 는 SwiftUI view 가 아니라 **별도 함수** 한 개로. 위치는 새 파일 `JHCalendar/Features/Holiday/HolidayAPI.swift`.

### 1) `HolidayDTO` + `HolidayResponse`

위 "Codable struct" 그대로 옮긴다. 같은 파일 내 또는 `HolidayModels.swift` 로 분리해도 OK.

### 2) `fetch(year:)` 함수

```swift
enum HolidayAPIError: Error {
    case missingApiKey
    case http(status: Int)
    case decoding(Error)
}

func fetchHolidays(year: Int) async throws -> [HolidayDTO] {
    // TODO: URLComponents 조립 + ServiceKey 디코딩
    // TODO: URLSession.shared.data(from:)
    // TODO: HTTPURLResponse status 검증 (200대만 통과)
    // TODO: JSONDecoder().decode(HolidayResponse.self, from: data)
    // TODO: response.body.items.item 반환
}
```

### 3) view 에서 한번 호출해보기

`ContentView` 또는 임시 위치에 `.task` 한 줄:

```swift
.task {
    do {
        let items = try await fetchHolidays(year: 2026)
        print("✅ \(items.count) 건")
        items.prefix(5).forEach { print($0) }
    } catch {
        print("❌", error)
    }
}
```

- `.task` 는 view 가 화면에 올라올 때 실행, 사라지면 자동 cancel. (`onAppear` + `Task {}` 보다 권장 — cancel 자동.)
- 콘솔에 공휴일 목록이 찍히면 단계 OK.

### 4) HTTP 에러 / 디코딩 에러 분리

`do / try / catch` 에서 어떤 단계에서 실패했는지 구분되게 에러 enum 을 쓴다. 위 `HolidayAPIError` 참고.

- 키 누락 → `missingApiKey`
- HTTP status 비-2xx → `http(status:)`
- decode 실패 → `decoding(underlying)`

> 학습 포인트: Swift 에서 도메인별 에러는 **enum + associated value** 패턴이 표준. (Java 의 커스텀 Exception 클래스 vs Swift 의 case-기반 enum 비교)

### 5) 키가 nil/빈 문자열인 경우

```swift
guard !Secrets.holidayApiKey.isEmpty else { throw HolidayAPIError.missingApiKey }
```

- 01 단계에서 fatalError 까지 쓸 수도 있지만, 운영 시 다른 화면이 살아있을 수도 있으므로 throws 가 더 부드러움.

## 직접 구현하기
- [ ] `JHCalendar/Features/Holiday/` 폴더 생성 (sync group 으로 인식됨)
- [ ] `HolidayAPI.swift` 안에 `HolidayDTO`, `HolidayResponse`, `HolidayAPIError`, `fetchHolidays(year:)` 작성
- [ ] `Secrets` enum (Bundle 조회 + isEmpty 가드) 작성 — 01 단계에서 안 만들었으면 여기서
- [ ] `ContentView` (또는 임시 View) 에 `.task { ... }` 로 한 번 호출, print 확인
- [ ] 빌드 + 실행 → 콘솔에 공휴일 목록 (10건 내외) 출력
- [ ] 실패 케이스 한 번 일부러 만들어 보기 — 키 한 글자 망가뜨려 인증 실패 → 어떤 에러가 어떻게 잡히는지 관찰
- [ ] PoC 확인 후 `.task` 임시 코드 제거 (다음 단계에서 정식 위치로 옮길 것)

## 자가 점검
- 빌드 + 실행 OK?
- 콘솔에 공휴일 객체들이 출력되는가? (1월 1일, 삼일절, 어린이날, ...)
- 인증 실패 시 디코딩 에러가 아니라 본인의 `HolidayAPIError.http` 가 잡히는가? — HTTP 200 인데 본문이 에러 XML 일 수도 있으니 그 경우는 디코딩에서 잡힘. 그래도 OK.
- 퀴즈: `try?` 와 `try!` 와 `try` 의 차이? — `try`: 호출자가 do/catch 또는 throws 로 처리. `try?`: 실패하면 nil. `try!`: 실패하면 crash. 본 단계에서는 `try` (또는 `try await`).
- 퀴즈: `URLSession.shared.data(from:)` 가 던질 수 있는 에러? — 네트워크 단절, DNS 실패, 타임아웃 등 `URLError`.

## Claude 리뷰 체크리스트
- [ ] `async / await` + `throws` 시그니처가 정확
- [ ] `Decodable` 트리가 응답 구조와 일치 (불필요한 필드 없음, `CodingKey` 가 맞음)
- [ ] `URLComponents` + `URLQueryItem` 으로 URL 조립 (문자열 연결 X)
- [ ] 키 이중 인코딩 회피 (`removingPercentEncoding` 또는 동등 처리)
- [ ] 에러를 enum 으로 도메인별 분리, do/catch 에서 자연스럽게 잡힘
- [ ] 빌드 산출물에 print 가 남아있지 않음 (다음 단계로 정리)

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- `JSONDecoder.dateDecodingStrategy` 로 `locdate` (Int → Date) 변환을 디코더 단계에서 처리하는 방법도 있다. 단, `20260301` 같은 Int 는 표준 strategy 로 안 풀려 `init(from:)` 커스텀이 필요 — 03 단계 도메인 변환에서 다루는 게 깔끔.
- `URLSession` 의 timeout 을 짧게 두고 싶으면 `URLSessionConfiguration.default` 를 복제해 `timeoutIntervalForRequest` 수정. 공휴일은 한 번만 받으면 되는 거라 기본값으로 충분.
- 실제 응답을 한 번 파일로 떨궈 두면 (`data.write(to:)`) 단위 테스트 작성이 쉬워진다. 본 프로젝트는 테스트 없음 → 그대로 print.
