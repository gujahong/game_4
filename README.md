# 습작4

세계를 건너다니는 수호자의 이야기. 다크 판타지 픽셀아트 게임.

> 세계를 건너다니는 자에게는 그곳이 온전히 보이지 않는다.
> 등불이 비추는 것만 실재한다.

**이 문서는 "무엇이 어디 있는가"를 적는다.** "지금 어디까지 왔고 왜 그렇게 정했는가"는
[`작업일지.md`](작업일지.md)에, 지켜야 할 규칙은 [`CLAUDE.md`](CLAUDE.md)에, PixelLab 쓰는
법은 [`PIXELLAB.md`](PIXELLAB.md)에 있다. **새로 들어오면 `작업일지.md`부터 읽을 것.**

---

## 돌려보기

Godot 4.7.1. 메인 씬은 `scenes/Opening.tscn`이다.

```bash
"C:\Users\진로교육원\Desktop\Godot_v4.7.1-stable_win64.exe" --path . 
```

씬을 골라 여는 것도 된다.

| 씬 | |
|---|---|
| `scenes/Opening.tscn` | 여는 화면. 어둠 → 글 → 등불 → 관문 |
| `scenes/Room.tscn` | 서고를 걸어다닌다. **여기서 시작하면 조우·전투까지 이어진다** |
| `scenes/Encounter.tscn` | 조우 연출. 검은 화면에 흰 선 |
| `scenes/Battle.tscn` | 1인칭 턴제 전투 |
| `scenes/Walk.tscn` | 옛 조우 연출(일러스트 한 장). 안 쓰지만 남겨둠 |
| `scenes/DialogueTest.tscn` · `PhotoTest.tscn` | 확인용 |

자산을 새로 넣은 뒤에는 한 번 들여와야 한다.

```bash
"C:\...\Godot_v4.7.1-stable_win64.exe" --headless --path . --import
```

---

## 게임의 뼈대

```
여는 화면 (Opening)
      ↓
서고를 걷는다 (Room)  →  조우 자리에 닿는다  →  조우 연출 (Encounter)
                                                      ↓  ↑를 눌러 다가간다
                                              1인칭 전투 (Battle)
```

---

## 정해진 것

| | |
|---|---|
| 내부 해상도 | **960x540.** 정수배로만 확대(1080p x2, 4K x4) |
| 화풍 | 컬러로 뽑고 **실행 중에 디더 필터를 씌운다.** "색이 있는데 흑백 필터를 낀 느낌" |
| 색 | **화면에서 색을 가진 것은 등불뿐.** 등불은 필터 판보다 위 레이어에 둔다 |
| 그림 크기 | **놓일 크기 그대로 만든다.** 늘리거나 줄이지 않는다 |
| 세계관 | 세상들은 초월적인 무언가의 **꿈**이다. 주인공은 그 꿈으로 건너가는 비밀 결사의 수호자 |
| 거점 | 아카식 서고 — 모든 것이 기록된 곳 |
| 전투 | **등불에서 무기를 뽑는다. 뽑을수록 등불이 어두워진다** — 빛 자체가 탄약이다 |

---

## 코드

**로직과 화면을 가른다.** 로직 쪽은 화면을 모르고, 화면 쪽은 규칙을 모른다. 새 적은 리소스
파일 하나, 새 UI는 화면 쪽만 손대면 되게 하려는 것이다.

### 맵 (`scripts/map/`)

| | |
|---|---|
| `Hero.gd` | 자리와 이동 규칙. **화면을 모른다.** 4방향만 쓰고 대각선을 여기서 거른다 |
| `HeroSprite.gd` | 방향과 걷는지만 받아 그림을 고른다. **규칙을 모른다.** 떠 있는 등불도 여기서 얹는다 |
| `Walker.gd` | 둘을 엮고 카메라·등불빛·필터를 맡는다. 조우 자리도 여기 |
| `TilesetRoom.gd` | PixelLab Wang 타일셋(16장 시트 + metadata)을 읽어 코드로 TileSet을 세운다 |

### 전투 (`scripts/battle/`)

| | |
|---|---|
| `Battle.gd` | 전투 진행. **화면을 모르고 시그널만 쏜다** |
| `BattleScreen.gd` | 그 시그널을 받아 그린다 |
| `Lantern.gd` | 등불 5단계. 밝기별 수치표가 전부 여기 |
| `LightMenu.gd` | 메뉴가 상자가 아니라 **등불에서 뻗는 빛줄기**다 |
| `EnemyDef.gd` | 적 정의(Resource). **새 적 = 리소스 하나**, 코드 무수정 |

### 대사 (`scripts/dialogue/`)

`DialogueController.gd`(진행) / `DialogueUI.gd`(화면). 우주쓰레기게임에서 옮겨왔고 겉모습만
새로 짰다. **주석에 남은 버그 기록이 코드보다 값어치가 있다.**

### 그 밖에

| | |
|---|---|
| `scripts/Opening.gd` | 여는 화면 전체. 시간 하나로 화면을 정해서 아무 시점이나 캡처된다 |
| `scripts/walk/Encounter.gd` | 조우 연출(선). 소실점 하나 + 그것 |
| `scripts/walk/WalkScene.gd` | 옛 조우 연출(일러스트). 조우 → 전투 전환이 여기 있다 |
| `scripts/LampGlow.gd` | 등불 빛. **필터 판보다 위**에 있어야 색을 지킨다 |
| `scripts/KoreanFont.gd` | Neo둥근모 16px. **정수배로만 쓴다** |

---

## 셰이더 (`shaders/`)

| | |
|---|---|
| `DitherFilter.gdshader` | 노드 하나에 씌우는 디더 |
| `DitherScreen.gdshader` | **화면 전체**에 한 번 씌우는 판. 이 아래는 전부 같은 필터를 통과한다 |
| `DitherLight.gdshader` | 등불 빛도 같은 격자로 흩어지게 |
| `PortalWave.gdshader` | 문 너머가 제자리에서 떤다 |
| `PortalLeak.gdshader` | 관문에서 세계가 새어 나온다. 방향이 있고 멀수록 커진다 |
| `CrtScreen.gdshader` | 확정 아님 |

**디더 격자는 화면에 못 박혀 있다**(`dither_on_screen`). 그림에 붙여두면 확대할 때 격자가
다시 짜여서 그물이 표면 위를 기어다닌다.

---

## 도구 (`tools/`)

전부 `--headless --script`로 돌리는 일회용 스크립트다. **비용이 0이고 몇 번이고 다시 돌린다.**

| | |
|---|---|
| `_lantern.gd` | 등불 그림을 찍는다 |
| `_silhouette.gd` | 등불 든 순례자 실루엣(여는 화면용) |
| `_frames.gd` | 방향별 프레임을 `SpriteFrames`로 엮는다 |
| `_reference.gd` | v3 회전에 넣을 참조 그림. **캔버스를 잘라서** 넣어야 한다 |
| `_hood.gd` | 두건 속 얼굴을 검게 지운다 |
| `_cutbg.gd` | 배경을 도려낸다. `no_background`가 안 먹었을 때 |
| `_unlantern.gd` | 손에 든 등불을 지운다 |
| `_cutout.gd` · `_extend.gd` | 관문 도려내기 / 옆으로 늘리기 |
| `_split.gd` | 좌우로 갈라진 그림을 이음매에서 자른다 |
| `_zoom.gd` · `_palette.gd` | 확대해 보기 / 쓰인 색 세어 보기 |

`tools/_*.png`는 확인용 캡처라 `.gitignore`에 걸려 있다.

---

## 자산

```
assets/characters/pilgrim_rot/   지금 쓰는 주인공. 16x32, 4방향, 손이 빈 순례자
assets/characters/pilgrim*/      앞선 판들(등불 든 것 등). 안 쓰지만 남겨둠
assets/enemies/watcher.png       그것 — 눈으로 뒤덮인 고리
assets/photos/                   일러스트. gate_4_wide(여는 화면), archive(서고)
assets/tilesets/marble_void_*    서고 바닥 ↔ 공허. 32px Wang 16장
assets/fonts/NeoDunggeunmo.ttf   글꼴. 갈무리 두 벌은 안 쓰고 남아 있다
```

---

## 아직 안 고친 것

- 조우 화면에 **입체감이 없다.** 사각 테가 소실점을 중심으로 균등하게 벌어져 터널 정면으로 읽힌다
- `DitherFilter`의 `input_black` / `input_white`가 uniform과 슬라이더만 있고 `fragment()`에서 안 쓰인다
- `PhotoStack.PHOTO_SIZE`가 448인데 실제 사진은 대부분 320이다
- `chapel448.png`가 하얗게 날아가 있다
- `assets/fonts/Galmuri*.ttf` 10MB가 안 쓰이고 남아 있다
