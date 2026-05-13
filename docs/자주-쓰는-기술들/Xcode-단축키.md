# Xcode 단축키 모음

> SwiftUI / macOS 앱 개발하면서 손이 자주 가는 단축키만 추렸다. IntelliJ / VSCode 와 매핑되는 것은 같이 적어두었다.

표기:
- `⌘` Command, `⌥` Option, `⌃` Control, `⇧` Shift, `↩` Return

---

## 1. 빌드 / 실행 / 정지

| 단축키 | 동작 | 메모 |
|---|---|---|
| `⌘B` | Build | IntelliJ 의 ⌘F9 |
| `⌘R` | Run (Build + 실행) | |
| `⌘.` | Stop | 실행 중인 앱 종료. **이거 하나만 외워도 일단 산다.** |
| `⌘U` | Test 실행 | |
| `⇧⌘K` | Clean Build Folder | 빌드 캐시 꼬였을 때 |
| `⌥⇧⌘K` | Clean Build Folder (Deep) | 정말 안 풀릴 때. 그래도 안 되면 `~/Library/Developer/Xcode/DerivedData` 통째 삭제 |
| `⌃⌘R` | Run without Building | 이미 빌드된 바이너리 재실행 |

> Gradle/Maven 캐시 비슷한 게 `DerivedData`. "왜 빌드가 이상하지?" → 일단 ⇧⌘K.

---

## 2. SwiftUI Preview / Canvas

SwiftUI 개발의 핵심. 매일 쓴다.

| 단축키 | 동작 |
|---|---|
| `⌥⌘↩` | Canvas (Preview) 토글 — 켜기/끄기 |
| `⌥⌘P` | Resume Preview — Preview 가 멈췄을 때 다시 빌드 |
| `⌘↩` | Live Preview ↔ Selectable 토글 |
| Canvas 안에서 `⌘` + 뷰 클릭 | Modifier 메뉴 (Embed in VStack, Add Modifier 등) |

> Preview 가 자주 "Failed to build" 로 죽는다. 패닉하지 말고 `⌥⌘P` 한 번 누른다. 그래도 안 되면 ⇧⌘K → Run.

---

## 3. 네비게이션 (파일/심볼 점프)

| 단축키 | 동작 | IntelliJ 비유 |
|---|---|---|
| `⇧⌘O` | Open Quickly | "Search Everywhere" (Double Shift) |
| `⌘⇧J` | Reveal in Project Navigator | 현재 편집 중인 파일을 좌측 트리에서 찾아 하이라이트 |
| `⌘1` ~ `⌘9` | 좌측 사이드바 탭 전환 | 1: Project, 4: Find, 7: Issue, 9: Source Control 등 |
| `⌘0` | 좌측 Navigator 토글 | |
| `⌥⌘0` | 우측 Inspector 토글 | |
| `⌘⏎` | Editor 만 표시 (Navigator/Inspector 동시 숨김) | 화면 좁을 때 |
| `⌃⌘←` / `⌃⌘→` | 뒤로/앞으로 이동 (히스토리) | IntelliJ 의 ⌘[ / ⌘] |
| `⌘L` | Jump to Line | |
| `⌃6` | 현재 파일의 심볼 목록 (메서드/프로퍼티 점프) | IntelliJ 의 ⌘F12 |

### 정의로/사용처로 이동

| 단축키 | 동작 |
|---|---|
| `⌘` + 클릭 | Jump to Definition |
| `⌃⌘J` | Jump to Definition (키보드 버전) |
| `⇧⌃⌘J` | Show Callers — 어디서 호출하는지 |
| `⌥` + 클릭 | Quick Help (마우스 위 심볼 문서 팝업) |

> 자바 IDE 의 ⌘B / Ctrl+클릭 과 같은 감각.

---

## 4. 코드 편집

### 기본

| 단축키 | 동작 |
|---|---|
| `⌃I` | Re-indent (선택 영역 들여쓰기 재정렬) |
| `⌘/` | 주석 토글 |
| `⌘[` / `⌘]` | 들여쓰기 감소/증가 |
| `⌥⌘[` / `⌥⌘]` | 줄 위/아래로 이동 |

### 멀티 커서 / 일괄 편집

| 단축키 | 동작 |
|---|---|
| `⌃⇧` + 클릭 | 클릭 지점에 커서 추가 (멀티 커서) |
| `⌃⇧↑` / `⌃⇧↓` | 위/아래 줄로 커서 확장 |
| `⌃⌘E` | Edit All in Scope — **현재 스코프의 동일 변수명을 한 번에 수정** |

> `⌃⌘E` 가 진짜 자주 쓴다. 변수 하나 클릭 후 ⌃⌘E 누르면 함수 내 모든 같은 이름이 동시 편집됨. 함수 시그니처는 안 건드림 → 안전.

### Refactor

| 단축키 | 동작 |
|---|---|
| `⌘⇧A` | Show Code Actions (Refactor 메뉴) — Rename, Extract Function 등 |
| 우클릭 → Refactor → Rename | 프로젝트 전체에서 이름 바꾸기 (참조까지) |

### 자동 정렬

- `⌃M` — **Wrap by Comma**. 함수 호출/배열에서 인자를 줄바꿈으로 정리. SwiftUI modifier 체인 정리할 때 유용.

```swift
// 커서를 함수 호출 위에 두고 ⌃M
Button("Save", action: handleSave)
// ↓
Button(
    "Save",
    action: handleSave
)
```

---

## 5. 검색

| 단축키 | 동작 |
|---|---|
| `⌘F` | 현재 파일 내 찾기 |
| `⌥⌘F` | 현재 파일 내 찾기 + 치환 |
| `⌘⇧F` | 프로젝트 전체 찾기 (Find Navigator) |
| `⌥⌘⇧F` | 프로젝트 전체 찾기 + 치환 |
| `⌘G` / `⌘⇧G` | 다음/이전 검색 결과 |

> `⌘⇧F` 결과 화면에서 Replace 버튼 누르면 안전하게 한 건씩 치환 가능. IntelliJ 의 "Replace in Files" 와 동등.

---

## 6. 디버깅

| 단축키 | 동작 |
|---|---|
| `⌘\` | 현재 줄 브레이크포인트 토글 |
| `⌘Y` | 모든 브레이크포인트 활성화 / 비활성화 |
| `F6` (또는 `⌃⌥⇧⌘F6`) | Step Over |
| `F7` | Step Into |
| `F8` | Step Out |
| `⌃⌘Y` | Continue (다음 브레이크포인트까지) |
| `⌘⇧Y` | 디버그 영역 (콘솔) 토글 |
| `⌘K` | 콘솔 비우기 (콘솔에 포커스 둔 상태) |

> Mac 노트북은 `F6~F8` 누르려면 `Fn` 같이 눌러야 함. 시스템 환경설정에서 "Use F1, F2 as standard function keys" 켜두면 편함.

---

## 7. 자주 쓰는 메뉴 단축키

| 단축키 | 동작 |
|---|---|
| `⌘,` | Xcode 환경설정 (Preferences) |
| `⌘⇧,` | 현재 Scheme 편집 (Run/Test/Archive 설정) |
| `⌥` + Run 버튼 클릭 | Run Scheme 옵션 (인자/환경변수) 띄우기 |
| `⌃` + Run 버튼 클릭 | Scheme 선택 메뉴 |

---

## 8. 의사결정 치트시트 (외울 우선순위)

처음엔 아래 10 개만 외우면 일상이 편해진다.

| 우선순위 | 단축키 | 동작 |
|---|---|---|
| ★★★ | `⌘R` | Run |
| ★★★ | `⌘.` | Stop |
| ★★★ | `⌘B` | Build |
| ★★★ | `⇧⌘O` | Open Quickly (파일 빠르게 열기) |
| ★★★ | `⌘⇧F` | 프로젝트 전체 검색 |
| ★★★ | `⌥⌘P` | Preview 재개 |
| ★★ | `⌘/` | 주석 토글 |
| ★★ | `⌃⌘E` | Edit All in Scope |
| ★★ | `⌥` + 클릭 | Quick Help |
| ★★ | `⌘` + 클릭 | Jump to Definition |

그 다음에 디버깅(`⌘\`, F6~F8) 과 Canvas 토글(`⌥⌘↩`) 까지 가면 충분히 손에 익은 상태.

---

## 9. 알아두면 좋은 것들

### Quick Open (`⇧⌘O`) 검색 팁

- 파일명 일부만 쳐도 됨: `ContView` → `ContentView.swift`
- 카멜케이스 약자도 인식: `cv` → `ContentView`
- `심볼명:` 으로 함수/타입 직접 검색도 됨

### 두 파일 나란히 보기 (Assistant Editor)

- `⌃⌥⌘⏎` — 보조 에디터 열기
- Tab 안에서 `⌘T` 로 새 탭, `⌘⇧T` 로 닫은 탭 복구

### Source Control

- `⌘9` — Source Control Navigator (브랜치/커밋 트리)
- `⌘⌥C` — Commit 다이얼로그

> 단, 본격적인 git 작업은 터미널 / `gh` CLI 가 더 빠르다. Xcode 내장 git 은 가벼운 diff 확인 정도에 쓴다.

---

## 10. 단축키 직접 바꾸기

`Xcode → Settings → Key Bindings` (`⌘,` → Key Bindings 탭) 에서 모든 단축키 재할당 가능.

- 자주 쓰는데 단축키가 없는 명령: 검색 후 직접 할당
- 충돌나면 Xcode 가 알려준다 (양쪽에서 그 단축키가 더 이상 작동 안 함)

> macOS 자체 단축키 (`⌘Space` Spotlight, `⌘Tab` 앱 전환) 와 겹치는 건 피한다. 시스템 단축키가 우선이다.
