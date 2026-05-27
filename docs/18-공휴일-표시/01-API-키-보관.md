# 단계 1: API 키 보관 (xcconfig + Info.plist)

## 학습 목표
- 공공데이터포털 API 키를 **소스 코드 / git 에 노출하지 않고** 빌드에 주입하는 표준 패턴을 익힌다.
- `xcconfig` (빌드 설정 파일) → `Info.plist` (변수 주입) → `Bundle.main` (런타임 조회) 3계층 흐름을 이해한다.
- 다음 단계에서 호출할 네트워크 코드의 **상수 위치를 미리 확보**.

## 사전 산출물
- 공공데이터포털에서 "한국천문연구원_특일 정보" API 신청 완료 + **Encoding 된 서비스키** 발급 완료.
  - 보통 두 가지를 준다: "Encoding" / "Decoding". 우리는 URL 쿼리에 넣을 거니 **Encoding 본** 을 사용.

## Swift / SwiftUI 개념

### xcconfig 파일이 뭐고 왜 쓰나

`.xcconfig` 는 Xcode 의 **빌드 설정을 key=value 텍스트** 로 적는 파일이다. 빌드 시점에 Xcode 가 읽어서 컴파일/링크/Info.plist 생성에 반영한다.

```text
// Secrets.xcconfig
HOLIDAY_API_KEY = aBc123XyZ...
```

- 일반 코드에서 `import` 하는 게 아니다. **빌드 입력** 일 뿐.
- 이 파일을 `.gitignore` 에 넣어 두면 키가 저장소에 안 올라감.
- 팀원에게는 "이 파일을 직접 만들어 키 넣으세요" 라고 안내 (`.example` 본 같이 빈 본을 commit).

> Spring 비유: `application-secret.yml` 을 `.gitignore` 에 넣고 환경별로 다른 본을 두는 방식 + `@Value("${...}")` 주입.
>
> JS 비유: `.env` 파일 + `process.env.HOLIDAY_API_KEY` 와 결이 같음.

### Info.plist 변수 주입

xcconfig 의 값은 **그 자체로는 Swift 코드에서 못 읽는다.** 한 번 더 통로가 필요하다 — 빌드 시 `Info.plist` 에 박아 넣고, 코드에서 `Bundle.main` 으로 읽는 방식.

Info.plist 예 (key 1개 추가):

```xml
<key>HOLIDAY_API_KEY</key>
<string>$(HOLIDAY_API_KEY)</string>
```

- `$(HOLIDAY_API_KEY)` 는 **빌드 변수 치환** 문법. Xcode 가 이 자리에 xcconfig 의 값을 박는다.
- 결과적으로 빌드된 앱 번들의 `Info.plist` 에는 실제 키 문자열이 들어가 있다.

> 키가 빌드 산출물에는 들어간다 — 클라이언트에서 호출되는 API 의 한계. 진짜 비밀이 필요하면 자체 서버를 거쳐야 함. 본 프로젝트의 공공데이터포털 키는 그 수준의 비밀은 아니라 클라이언트 임베드로 충분.

### Bundle 로 Info.plist 읽기

런타임에:
```swift
let key = Bundle.main.object(forInfoDictionaryKey: "HOLIDAY_API_KEY") as? String
```

- `Bundle.main` 은 현재 실행 중인 앱 번들. (Java 의 `getClass().getClassLoader()` 위치 정도의 결.)
- `object(forInfoDictionaryKey:)` 는 `Any?` 반환 → `as? String` 으로 다운캐스트.
- 옵셔널 → 다음 단계에서 nil 일 때 어떻게 다룰지는 거기서.

## 구현 가이드

### 1) `.gitignore` 먼저

가장 먼저 비밀 파일을 무시하도록 `.gitignore` 에 추가. `Secrets.xcconfig` 가 실수로 커밋 안 되게.

```gitignore
# API keys / local config
Secrets.xcconfig
```

> 순서 중요. 파일 만들기 **전에** ignore 부터.

### 2) `Secrets.xcconfig` 생성

Xcode 좌측 프로젝트 트리에서 프로젝트 우클릭 → New File → "Configuration Settings File" → 이름 `Secrets.xcconfig`. 위치는 프로젝트 루트.

내용:
```text
HOLIDAY_API_KEY = <Encoding 본 서비스키 전체 — 따옴표 X>
```

- xcconfig 는 `//` 가 주석이라 **값에 `//` 가 있으면 잘린다.** Encoding 본 키에 `+`, `=`, `%` 는 흔하지만 `//` 는 거의 없을 것. 혹시 있다면 `${SLASH}${SLASH}` 같은 우회 필요. (실제로 부딪힐 가능성 낮음.)

### 3) Build Configurations 에 xcconfig 연결

프로젝트 설정 → PROJECT (앱 타깃이 아닌 상위 프로젝트) → **Info** 탭 → **Configurations** 섹션. Debug / Release 각각 옆 화살표 펼치면 두 줄이 나옴 (프로젝트 / 타깃). 거기서 우측 풀다운에 `Secrets` 선택.

- "프로젝트 / 타깃 둘 다 같은 값" 으로 두면 가장 단순. Debug, Release 모두 같은 키 사용.
- 별 따로 운영 키 / 개발 키 분리하고 싶으면 Debug 용 `Secrets-Debug.xcconfig` 따로 둘 수도. 본 단계에서는 단일.

### 4) Info.plist 에 키 추가

이 프로젝트는 Info.plist 가 자동 생성식인지 파일 직접 두는지부터 확인.

```bash
ls JHCalendar | grep -i info.plist
```

- **파일 있음** (직접 관리) → 파일 열어서 `HOLIDAY_API_KEY = $(HOLIDAY_API_KEY)` 추가.
- **파일 없음** (auto-generated) → Xcode 타깃 → Build Settings → "Info.plist Values" 카테고리 (또는 검색창에 `INFOPLIST_KEY`) 에 **`INFOPLIST_KEY_HOLIDAY_API_KEY = $(HOLIDAY_API_KEY)`** 추가. 이게 자동 생성 모드에서의 변수 주입 방식.

> 본 프로젝트는 macOS 14+ Xcode 의 기본 자동 생성 모드일 가능성이 높음. Build Settings 쪽이 정답일 것.

### 5) 빌드 후 결과 확인

```bash
xcodebuild -project JHCalendar.xcodeproj -scheme JHCalendar -configuration Debug build
```

빌드 산출물에서 Info.plist 확인:

```bash
# 빌드 결과 디렉토리 안의 Info.plist 위치는 환경마다 다르지만 보통:
find ~/Library/Developer/Xcode/DerivedData -name "Info.plist" -path "*JHCalendar*"
```

- `plutil -p <Info.plist 경로>` 로 출력해 `HOLIDAY_API_KEY` 가 실제 키로 치환됐는지 확인.

### 6) 임시 코드로 런타임 조회 확인

`JHCalendarApp.swift` 든 어디든 잠깐 한 줄:

```swift
.task {
    print("HOLIDAY KEY =", Bundle.main.object(forInfoDictionaryKey: "HOLIDAY_API_KEY") ?? "nil")
}
```

- 실행 → 콘솔에 키가 찍히면 성공.
- 다음 단계 들어가기 전에 이 임시 print 는 **지운다** (혹은 검증용 함수로 옮긴다).

## 직접 구현하기
- [ ] `.gitignore` 에 `Secrets.xcconfig` 추가, commit
- [ ] `Secrets.xcconfig` 파일 만들고 키 한 줄 작성
- [ ] PROJECT Info → Configurations 에서 Debug/Release 둘 다 `Secrets` 로 지정
- [ ] Info.plist 또는 Build Settings 의 `INFOPLIST_KEY_HOLIDAY_API_KEY` 에 `$(HOLIDAY_API_KEY)` 주입
- [ ] `xcodebuild ... build` 통과
- [ ] 임시 print 로 키가 런타임에서 조회되는지 확인 (확인 후 print 제거)
- [ ] `git status` 로 `Secrets.xcconfig` 가 untracked 인지 다시 확인 (커밋되면 안 됨)

## 자가 점검
- 빌드 통과?
- `git status` 에 `Secrets.xcconfig` 가 untracked 로만 나타나는가? (Modified/Added 면 ignore 가 잘못된 것)
- `Bundle.main.object(forInfoDictionaryKey: "HOLIDAY_API_KEY")` 가 nil 아닌 실제 키 문자열을 반환하는가?
- 퀴즈: `xcconfig` 값이 빈 문자열이면 `Bundle.main.object(...)` 는 무엇을 돌려주는가? — 빈 문자열 (`""`). nil 이 아니다. 다음 단계에서 "비어있는지" 도 함께 체크할 것.
- 퀴즈: `Info.plist` 에 박힌 키는 **빌드 산출물에 평문** 으로 들어간다. 그래도 OK 인 이유? — 공공데이터포털 키는 rate limit 정도의 통제. 진짜 비밀 (DB 비번 등) 은 클라이언트 임베드 X. 자체 백엔드 경유.

## Claude 리뷰 체크리스트
- [ ] `Secrets.xcconfig` 가 git 에 안 올라옴
- [ ] xcconfig 값이 Info.plist 까지 정상 주입
- [ ] 코드에서 키 조회 위치가 한 곳 (전역 상수든 함수든) — 여러 곳에 흩뿌리지 X
- [ ] 키가 nil / 빈 문자열 케이스에 대한 처리 방향이 다음 단계에 메모됨

## 회고
- 막혔던 부분?
- 추가로 궁금했던 점?
> *(직접 채우는 영역)*

## 조금 더 (선택)
- 팀 협업 시 `Secrets.xcconfig.example` 을 커밋해 두면 "어떤 변수가 필요한가" 가 명시적. 신규 멤버 셋업 가이드가 단순해진다.
- 키를 사용하는 코드 측에서 **한 번만 조회**하고 정적 상수로 캐싱해 두는 게 깔끔:
  ```swift
  enum Secrets {
      static let holidayApiKey: String = {
          guard let raw = Bundle.main.object(forInfoDictionaryKey: "HOLIDAY_API_KEY") as? String,
                !raw.isEmpty else {
              fatalError("HOLIDAY_API_KEY 누락 — Secrets.xcconfig 확인")
          }
          return raw
      }()
  }
  ```
  부재 시 `fatalError` 로 빌드 직후 즉시 실패하게 두면, 운영 중에 한참 뒤에 알아채는 사고를 막을 수 있다. (개발 단계 한정 — 운영용은 UI 알림이 더 적절.)
