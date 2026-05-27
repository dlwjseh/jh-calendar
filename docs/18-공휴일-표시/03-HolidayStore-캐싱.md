# 단계 3: HolidayStore + 연 단위 캐싱 (+ 현재 연도 TTL)

## 학습 목표
- DTO → 도메인 모델 (`Holiday`) 변환을 익힌다 — 디코딩 타입과 앱이 쓰는 타입을 분리하는 이유.
- 연 단위 캐시를 가진 **스토어** 를 만들고 SwiftUI 에서 `@EnvironmentObject` 로 주입한다.
- `UserDefaults` 에 Codable JSON 을 직렬화/역직렬화 해 디스크에 캐싱한다.
- **TTL (Time-To-Live)** 개념을 익힌다 — `cachedAt: Date` 메타데이터 + `Date` 비교로 stale 판정.
- `.task` modifier 와 비동기 흐름 + 메인 액터 격리를 익힌다.

## 사전 산출물
- [02-API-호출-JSON](02-API-호출-JSON.md) 의 `fetchHolidays(year:)` 가 동작.
- `HolidayDTO`, `HolidayAPIError` 정의.

## Swift / SwiftUI 개념

### DTO vs 도메인 모델

`HolidayDTO` (02 단계의 디코딩 타입) 는 응답 구조 그대로다 — `locdate: Int = 20260301`, `isHoliday: String = "Y"`. UI 가 다루기엔 어색하다.

→ 앱이 쓰는 **도메인 모델** 을 따로 둔다:

```swift
struct Holiday: Identifiable, Hashable, Codable {
    let id: UUID = UUID()
    let date: Date           // 2026-03-01 00:00 (startOfDay)
    let name: String         // "삼일절"
}
```

- `Identifiable` — `ForEach` 에 쓰기 위함.
- `Hashable` — `Set` / dictionary key.
- `Codable` — `UserDefaults` 저장용.

> Spring 비유: 외부 API DTO 와 내부 도메인 객체를 분리하는 헥사고날 결. 외부가 바뀌어도 도메인은 안전.

DTO → Domain 변환:

```swift
extension HolidayDTO {
    var asHoliday: Holiday? {
        guard isHoliday == "Y" else { return nil }
        // 20260301 → Date
        let s = String(locdate)
        guard s.count == 8,
              let y = Int(s.prefix(4)),
              let m = Int(s.dropFirst(4).prefix(2)),
              let d = Int(s.suffix(2)) else { return nil }
        var comps = DateComponents()
        comps.year = y; comps.month = m; comps.day = d
        guard let date = Calendar.current.date(from: comps) else { return nil }
        return Holiday(date: Calendar.current.startOfDay(for: date), name: dateName)
    }
}
```

> 함정: `Date` 는 시각까지 가진다 → 캘린더 표시는 `startOfDay` 로 정규화한 키여야 사용자 이벤트와 매칭 비교가 쉽다.

### `UserDefaults` + Codable + **TTL 메타데이터**

캐시 값에 **데이터 + 받은 시각** 을 함께 저장한다. 단순 `[Holiday]` 만 저장하면 "언제 받은 건지" 알 수 없어 stale 판정이 안 된다.

```swift
struct HolidayCacheEntry: Codable {
    let holidays: [Holiday]
    let cachedAt: Date
}

// 쓰기
let entry = HolidayCacheEntry(holidays: holidays, cachedAt: Date())
let data = try JSONEncoder().encode(entry)
UserDefaults.standard.set(data, forKey: "holidays.\(year)")

// 읽기
if let data = UserDefaults.standard.data(forKey: "holidays.\(year)"),
   let entry = try? JSONDecoder().decode(HolidayCacheEntry.self, from: data) {
    return entry  // (holidays, cachedAt)
}
```

- `UserDefaults.standard` 는 macOS 의 plist 기반 KV store. 작은 데이터 (수십 KB 이내) 에 적합. 공휴일 한 해는 수십 항목이라 충분.
- 인코딩 실패는 거의 없지만 디코딩은 형식 변경 시 깨질 수 있음 → `try?` 로 nil 흡수 후 재 fetch.

> Spring 비유: 적합한 비유 없음. JS 의 `localStorage` 와 결이 비슷 (KV 영속).

### TTL — `Date` + `TimeInterval` 로 stale 판정

```swift
enum HolidayCachePolicy {
    static let currentYearTTL: TimeInterval = 7 * 24 * 60 * 60  // 7일 (초 단위)

    static func isStale(entry: HolidayCacheEntry, for year: Int, now: Date = Date()) -> Bool {
        let currentYear = Calendar.current.component(.year, from: now)
        guard year == currentYear else { return false }       // 과거/미래 연도는 영구 캐시
        return now.timeIntervalSince(entry.cachedAt) > currentYearTTL
    }
}
```

- `TimeInterval` 은 그냥 `Double` typealias. 단위는 **초**. `7 * 24 * 60 * 60` 처럼 적어두면 의미가 명확.
- `Date.timeIntervalSince(_:)` — 두 시각의 차이를 초 (Double) 로 반환. 음수면 미래 시점.
- **정책**: 현재 연도만 TTL 7일 적용. 과거 연도는 확정 데이터라 영구. 미래 연도도 일단 영구 (사용자가 거기까지 가는 일이 드물고, 거기 갔을 때 임시공휴일이 추가됐을 가능성은 낮다는 가정).

> **왜 TTL 이 필요한가?** 한국 정부는 연중에 **임시공휴일** 을 지정하기도 한다 (대선/총선/광복절 80주년 같은 일회성). 영구 캐시면 그 해 1월에 받은 데이터 그대로 — 6월에 발표된 임시공휴일이 평생 안 들어옴. 7일 정도면 발표 후 다음 주에 자동 반영, 사용자 API 호출량도 미미 (앱 켤 때 1주에 1회).

> Spring 비유: `@Cacheable` + Caffeine 의 `expireAfterWrite(7, DAYS)` 와 같은 결. JS 의 SWR 라이브러리에서 `dedupingInterval` 비슷.

### `@MainActor` + `ObservableObject` 스토어

```swift
@MainActor
final class HolidayStore: ObservableObject {
    @Published private(set) var byDay: [Date: Holiday] = [:]
    private var loadedYears: Set<Int> = []

    func load(year: Int) async {
        guard !loadedYears.contains(year) else { return }   // 같은 세션 중복 호출 가드
        // 1) 캐시 시도 — fresh 면 그대로 사용
        if let cached = readCache(year: year),
           !HolidayCachePolicy.isStale(entry: cached, for: year) {
            merge(cached.holidays); loadedYears.insert(year); return
        }
        // 2) 네트워크 (cache miss 또는 stale)
        do {
            let dtos = try await fetchHolidays(year: year)
            let holidays = dtos.compactMap { $0.asHoliday }
            writeCache(year: year, holidays: holidays)
            merge(holidays); loadedYears.insert(year)
        } catch {
            // 네트워크 실패 — stale 캐시라도 있으면 일단 띄움 (graceful degrade)
            if let cached = readCache(year: year) {
                merge(cached.holidays); loadedYears.insert(year)
            }
            print("⚠️ holiday fetch failed:", error)
        }
    }
}
```

- `@MainActor` → 이 클래스의 모든 멤버는 메인 스레드에서만 접근. `@Published` 변경이 UI 업데이트를 안전하게 트리거.
- `byDay: [Date: Holiday]` — `startOfDay(for:)` 키 사전. 셀에서 `dict[startOfDay] != nil` 한 번에 조회 ([EventIndex.swift](../../JHCalendar/Features/MonthlyCalendar/EventIndex.swift) 의 `eventsByDay` 같은 결).
- `loadedYears` — **같은 세션** 안에서 중복 요청 방지. 디스크 TTL 과는 독립.
  - 즉 앱이 켜져 있는 동안에는 stale 이 돼도 재요청 안 함 → 사용자가 앱을 1주 이상 켜둔 채로 임시공휴일이 발표되는 케이스는 무시. 앱 재시작 시점에만 stale 체크.
- **stale fallback**: 네트워크가 죽었는데 stale 캐시가 있으면 그거라도 보여줌. "오프라인이라 비어보임" 보다 낫다.

### `.task(id:)` modifier

```swift
.task(id: store.referenceDate) {
    let year = Calendar.current.component(.year, from: store.referenceDate)
    await holidayStore.load(year: year)
}
```

- `.task` 는 view 가 화면에 올라올 때 비동기 task 실행.
- `id:` 파라미터를 주면 그 값이 바뀔 때마다 task 가 **취소되고 다시 실행** — 월을 옮겨 연도가 바뀌면 자동 재요청.
- 같은 연도 안에서 월 이동만 하면 `load(year:)` 의 `loadedYears` 가드로 빠르게 return.

> JS 의 `useEffect(() => {...}, [year])` 와 결이 같음. Swift 는 cancel 까지 자동.

## 구현 가이드

### 1) `Holiday` 도메인 모델 + 변환

`JHCalendar/Features/Holiday/HolidayModels.swift` (또는 `HolidayAPI.swift` 와 같은 파일):

```swift
struct Holiday: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let name: String

    init(id: UUID = UUID(), date: Date, name: String) {
        // TODO
    }
}

extension HolidayDTO {
    var asHoliday: Holiday? {
        // TODO: locdate Int → Date 변환, isHoliday=="Y" 만 통과
    }
}
```

> 함정: `id: UUID = UUID()` 를 그대로 `Codable` 로 만들면 매번 디코드할 때 새 id 가 들어간다. 캐시 일관성 측면에서는 OK (그 해 안에서만 살아있는 id). 만약 일관 id 가 필요하면 `locdate + seq` 기반으로 deterministic id 를 만들 것.

### 2) 캐시 엔트리 + TTL 정책

같은 폴더 `HolidayCache.swift` (또는 `HolidayStore.swift` 안에 같이):

```swift
struct HolidayCacheEntry: Codable {
    let holidays: [Holiday]
    let cachedAt: Date
}

enum HolidayCachePolicy {
    static let currentYearTTL: TimeInterval = 7 * 24 * 60 * 60  // 7일

    static func isStale(entry: HolidayCacheEntry, for year: Int, now: Date = Date()) -> Bool {
        // TODO: 현재 연도일 때만 cachedAt + TTL 비교
    }
}
```

체크포인트:
- [ ] 과거/미래 연도는 항상 fresh 로 판정 (영구 캐시)
- [ ] 현재 연도이고 7일 초과 → stale

> `now: Date = Date()` 처럼 기본값 파라미터를 두면 테스트가 쉽다 — 가짜 "현재 시각" 을 주입 가능. (이번 단계는 테스트 안 쓰지만 idiom 으로 익혀둘 만함.)

### 3) `HolidayStore`

같은 폴더 `HolidayStore.swift`:

```swift
@MainActor
final class HolidayStore: ObservableObject {
    @Published private(set) var byDay: [Date: Holiday] = [:]
    private var loadedYears: Set<Int> = []

    func load(year: Int) async {
        // TODO: loadedYears 가드 → 캐시 read → stale 체크 → fresh 면 merge / stale·miss 면 네트워크
    }

    private func readCache(year: Int) -> HolidayCacheEntry? {
        // TODO: UserDefaults.standard.data(forKey: "holidays.\(year)") → JSONDecoder
    }

    private func writeCache(year: Int, holidays: [Holiday]) {
        // TODO: HolidayCacheEntry(holidays:, cachedAt: Date()) → JSONEncoder → UserDefaults
    }

    private func merge(_ holidays: [Holiday]) {
        // TODO: byDay[startOfDay(for:)] = holiday
    }
}
```

체크포인트:
- [ ] `load(year:)` 가 같은 연도 중복 호출 시 즉시 return
- [ ] 캐시 hit + fresh → 네트워크 호출 X
- [ ] 캐시 hit + stale → 네트워크 호출, 성공 시 새 `cachedAt` 으로 덮어쓰기
- [ ] 캐시 miss → 네트워크 호출
- [ ] 네트워크 실패 + stale 캐시 존재 → stale 데이터라도 merge (graceful degrade)
- [ ] `merge` 는 dict 키를 반드시 `startOfDay(for:)` 정규화
- [ ] `writeCache` 의 `cachedAt` 은 항상 **저장 시점의 `Date()`**

### 4) 앱 진입점에서 주입

`JHCalendarApp.swift`:

```swift
@StateObject private var holidayStore = HolidayStore()

WindowGroup {
    ContentView()
        .environmentObject(holidayStore)
}
```

> 참고: `CalendarStore` 도 같은 패턴으로 이미 들어가 있을 것 — 그 옆에 한 줄 더.

### 5) `MonthlyCalendarView` 에서 `.task(id:)`

`MonthlyCalendarView.swift`:

```swift
@EnvironmentObject private var holidayStore: HolidayStore

var body: some View {
    VStack { ... }
        .task(id: store.referenceDate) {
            let year = Calendar.current.component(.year, from: store.referenceDate)
            await holidayStore.load(year: year)
        }
}
```

- 첫 진입 + 월 이동 시 모두 트리거. 같은 연도 안에서는 store 가 빠르게 return.
- 12월 → 1월 같은 경계 전환 시 자동으로 새 연도 로드.

### 6) 임시 로그로 동작 확인

PoC 답게 (다음 단계 들어가기 전 일회용):
```swift
.task(id: store.referenceDate) {
    let year = Calendar.current.component(.year, from: store.referenceDate)
    await holidayStore.load(year: year)
    print("holidays byDay.count =", holidayStore.byDay.count)
}
```

- 첫 실행: 네트워크 호출 → byDay 가 채워짐.
- 앱 재시작 (1주 이내): 캐시 hit + fresh → 네트워크 안 침.
- 앱 재시작 (1주 초과): 캐시 hit + stale → 네트워크 다시 침. (TTL 직접 검증은 아래 "TTL 검증 팁" 참고.)
- 연도 이동: 캐시 없는 해는 다시 네트워크.

### 7) TTL 검증 팁

실제로 7일 기다리긴 어려우니, 한 번만 임시로 TTL 을 작게 잡고 확인:

```swift
// 임시
static let currentYearTTL: TimeInterval = 60  // 1분
```

- 앱 실행 → 캐시 저장 → 종료 → 1분 후 재실행 → 네트워크 호출이 다시 일어나는지 콘솔로 확인.
- 검증 끝나면 **반드시 7일 값으로 되돌릴 것**.

> 또는 `now: Date` 파라미터를 활용해 `Date().addingTimeInterval(10*24*60*60)` 을 가짜 현재 시각으로 주입해 stale 판정이 동작하는지 확인할 수도 있다.

### 8) 함정 대응 — 응답 0건 / 에러 본문

02 단계에서 보류한 케이스:
- 응답에서 `body.items` 가 빈 문자열로 올 때 → `JSONDecoder` 가 실패 → `do/catch` 에서 잡힘 → stale fallback 이 있으면 그걸 사용, 없으면 store 는 빈 상태 유지.
- 한 건짜리 연도 (`item` 이 객체 1개로 옴) → 거의 안 일어나지만 안전 위해 디코더에 single-or-array 처리를 더 깔 수도. **본 단계 생략**, 부딪히면 그때 보강.

## 직접 구현하기
- [x] `Holiday` struct 정의 (Codable, Identifiable, Hashable)
- [x] `HolidayDTO.asHoliday` 변환 (`locdate` Int → Date)
- [x] `HolidayCacheEntry` (holidays + cachedAt) 정의
- [x] `HolidayCachePolicy.isStale(...)` — 현재 연도만 7일 TTL
- [x] `HolidayStore` 작성 (`@MainActor`, `byDay`, `loadedYears`, `load`, 캐시 R/W, merge, stale fallback)
- [x] `JHCalendarApp` 에서 `@StateObject` + `.environmentObject(...)`
- [x] `MonthlyCalendarView` 에 `@EnvironmentObject` + `.task(id:)`
- [x] 첫 실행 — 네트워크 호출 발생, byDay 채워짐 (콘솔로 확인)
- [x] 앱 재시작 (즉시) — UserDefaults 에서 캐시 읽기 (네트워크 호출 0회)
- [x] TTL 검증 — 임시로 TTL=60초로 줄여, 1분 후 재실행 시 네트워크 다시 호출되는지 확인 → 7일로 복원
- [x] 월 이동으로 연도 경계 넘기기 — 새 연도 캐시 미스 → 네트워크 호출

## 자가 점검
- 빌드 + 실행 OK?
- 첫 실행 시 byDay 가 채워지는가? (예: 2026 → 약 15건)
- 앱을 완전히 종료 후 재실행해도 같은 byDay 가 즉시 채워지는가?
- 임시로 TTL=60초로 줄였을 때, 1분 후 재실행 시 네트워크 호출이 다시 일어나는가? (콘솔 로그 또는 Charles/Proxyman 으로 확인 가능)
- 12월에서 1월로 넘어가면 새 연도 fetch 가 일어나는가?
- 퀴즈: `@MainActor` 가 안 붙어있으면 무슨 문제가 생기는가? — `@Published` 업데이트가 백그라운드 스레드에서 일어나면 SwiftUI 가 경고. 비결정 동작 가능.
- 퀴즈: 과거 연도를 영구 캐시로 두는 게 안전한 이유는? — 정부가 과거 공휴일을 사후 변경하는 일은 사실상 없다 (있어도 그건 기록 정정이지 표시 정정 아님). 미래 데이터만 변동성 있음.
- 퀴즈: `loadedYears` 와 디스크 TTL 이 따로 있는 이유는? — `loadedYears` 는 **같은 앱 세션 안에서** 메모리 중복 호출 방지용. TTL 은 **세션 간** 갱신 정책. 둘은 시간 스케일이 다르다.

## Claude 리뷰 체크리스트
- [ ] `Holiday` 가 `Codable` (UserDefaults 저장 가능)
- [ ] `HolidayCacheEntry` 에 `cachedAt: Date` 가 항상 포함, write 시 `Date()` 로 갱신
- [ ] `isStale` 이 현재 연도에만 TTL 적용, 과거/미래는 항상 false
- [ ] `byDay` 키가 `startOfDay(for:)` 로 정규화
- [ ] 캐시 hit + fresh 시 네트워크 호출 안 일어남
- [ ] 캐시 hit + stale 시 네트워크 호출, 성공 시 cachedAt 갱신
- [ ] 네트워크 실패 시 stale 캐시라도 띄움 (graceful degrade)
- [ ] `.task(id:)` 의 id 가 적절 (연도가 바뀔 때만 실제 fetch)
- [ ] `@MainActor` 격리

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 진짜 빨리 띄우려면 **stale-while-revalidate** 패턴 — stale 캐시를 일단 화면에 띄우고, 백그라운드로 fetch 해서 끝나면 갱신. 본 프로젝트는 fetch 가 빠르고 빈도가 낮아 그냥 await.
- `HolidayStore` 를 `@Observable` 매크로 버전으로 마이그레이션해 `@Published` / `ObservableObject` 보일러를 줄일 수 있음. 다만 `CalendarStore` 가 아직 `ObservableObject` 라 일관성 차원에서 보류.
- TTL 을 데이터 종류별로 다르게: 임시공휴일 발표 시즌 (대선/총선 직전) 만 짧게, 평상시는 길게 등. 본 프로젝트 오버킬.
- `UserDefaults` 대신 `FileManager` + `~/Library/Caches/` — 캐시는 사실 `Caches` 디렉토리가 정석 (OS 가 용량 부족 시 지울 수 있음, 다음 fetch 로 자연 복구). 본 프로젝트는 데이터가 작아 `UserDefaults` 가 더 간편.
