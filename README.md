# 습작4

어둠 속을 등불 하나로 걷는 다크 판타지 픽셀아트 게임. Godot 4.7.1.

**이 게임의 규칙 하나** — *등불이 비추는 것만 실재한다.* 화면에서 색을 가진 것은 등불뿐이고,
보이는 것도 등불이 닿는 데까지다. 전투에서 불을 줄이면 세상도 UI도 같이 죽는다. 그래서
남은 기름을 나타내는 눈금이 따로 필요 없다 — **화면이 곧 게이지다.**

## 켜기

```bash
"C:\Users\진로교육원\Desktop\Godot_v4.7.1-stable_win64.exe" --path . res://scenes/Opening.tscn
```

| 보고 싶은 것 | 여는 씬 |
|---|---|
| 처음부터 (경구 → 관문) | `scenes/Opening.tscn` |
| 조우 복도 → 전투 | `scenes/Encounter.tscn` |
| 전투 구도만 (25초 건너뜀) | `scenes/Encounter.tscn` 뒤에 `-- --battle` |
| 등불 밝기 확인 사진 | `scenes/Battle.tscn` 뒤에 `-- --capture` |

`Esc`로 끄고 `F11`로 전체화면. 화면은 **960x540**을 정수배로만 늘린다.

## 구조

로직과 화면을 가른다. **규칙은 화면을 모르고, 화면은 규칙을 안다.**

```
scripts/
  walk/Encounter.gd      1점 투시 복도. 걷기 → 붙잡힘 → 암전 → 빛살 → 전투를 얹음
  battle/
    Battle.gd            전투 규칙. 화면을 전혀 모른다 (시그널만 쏨)
    BattleStage.gd       전투를 아무 씬에나 얹는 무대. 카메라를 돌리고 규칙과 글자를 잇는다
    BattleHud.gd         글자와 메뉴. 배치도 연출도 모른다
    LightMenu.gd         등불에서 뻗는 빛줄기 메뉴
    EnemyDef.gd          적 하나 = 리소스 하나. 전투 코드는 안 건드린다
    TalkOption.gd        말길 하나. 무엇이 뜰지도 무슨 일이 벌어질지도 적이 정한다
  Music.gd  Sfx.gd  EmberText.gd
```

전투는 **씬을 갈아타지 않는다.** 조우 화면 위에 `BattleStage`가 얹히고, 서 있던 그것과 내가
좌우로 옮겨 앉는다 — 아무것도 사라지지 않으니 카메라만 돈 것으로 읽힌다.

## 만드는 것들

그림도 소리도 **코드로 찍는다.** `tools/`의 스크립트는 전부 0원이고 몇 번이든 다시 돌릴 수 있다.

```bash
Godot --headless --path . --script res://tools/_sfx.gd          # 효과음 열여섯 개
Godot --headless --path . --script res://tools/_lantern_big.gd  # 전투용 큰 등불
Godot --headless --path . --script res://tools/_probe_sfx.gd    # 소리가 실제로 담겼는지 잼
```

PixelLab로 뽑는 것(인물·적)은 **다섯 단계 통틀어 200생성**이 상한이다. 뽑기 전에 프롬프트와
비용을 확인받는다.

## 그림 규칙

**놓일 크기 그대로 뽑는다.** 크게 뽑아 줄이거나 작게 뽑아 늘리지 않는다. 내부 해상도가
960x540이고 화면 전체를 정수배로만 확대하므로, 놓일 크기로 만들면 도트 하나가 화면 픽셀
정수 개에 딱 떨어진다. 크기가 안 맞으면 **확대/축소 대신 투명 여백을 자르거나 덧붙인다.**

같은 이유로 픽셀 글꼴은 네이티브 크기(16px)의 정수배로만 쓴다.

## 더 읽을 것

- `작업일지.md` — 지금 어디까지 왔고, 최근에 뭘 왜 그렇게 정했고, 다음에 뭘 할지.
  **다른 컴퓨터에서 이어 할 때 여기부터 읽는다.**
- `CLAUDE.md` — 작업 규칙
- `PIXELLAB.md` — PixelLab 사용법과 한도
