# PixelLab 공식 정리

**공식 자료만 모은 것이다.** 우리가 겪은 일은 넣지 않는다.

## 출처

| 표시 | 무엇 |
|---|---|
| **[문서]** | `pixellab.ai/docs` 공식 문서 원문 |
| **[화면]** | 실제 웹 도구 화면에서 직접 확인한 것 (2026-08-19) |
| **[영상]** | 공식 유튜브(@PixelLab_AI) 자막 원문 |

**셋이 어긋날 때는 [화면]이 우선이다.** 다만 **한 화면만 보고 단정하지 말 것** — 같은 도구가
들어가는 길(에디터 / Map Workshop / Creator)에 따라 **다른 선택지를 준다.** 문서에 있는데
화면에 없으면, 먼저 **다른 경로를 찾아봐야 한다**(§5.1의 64px 타일셋이 그런 경우였다).

---

# 1. 들어가는 길 여덟 가지

**[화면]** 계정 페이지 위쪽에 전부 나열돼 있다.

| | 성격 |
|---|---|
| | 성격 | 한계 |
|---|---|---|
| **Simple Creator** (`/create`) | 제일 빠른 생성기. **모바일 됨**.<br>PixFlux(중~특대) · BitForge(소~중) 모델 | 에디터보다 기능이 적다 |
| **Characters** (`/create-character`) | 4·8방향 캐릭터 + 애니메이션. 스프라이트 시트로 내보냄.<br>**애니메이션 미리보기 내장**. 모바일 됨 | |
| **Objects** (`/create-object`) | 오브젝트 전용. 모바일 됨 | |
| **Map Workshop** (`/maps`) | **Maps · Tilesets · Tiles** 세 탭.<br>**★ 64×64 타일셋은 여기에만 있다**(§5.1) | |
| **Pixelorama** (`/editor`) | 오픈소스 픽셀 에디터에 PixelLab을 통합한 것.<br>**도구가 제일 많다** | **모바일 안 됨** |
| **Aseprite 확장** | 계정 페이지에서 내려받는다 | **Aseprite v1.3+ 필요.<br>체험판은 확장을 지원 안 함** |
| **Vibe Coding** (`/mcp`) | AI 어시스턴트에 MCP로 연결 | 구독 필요 |
| **API** | 직접 호출. **Python SDK 있음** | 코딩 필요 |
| Game Builder | 준비 중 | |

**[화면]** Map Workshop의 세 탭:

```
Maps       만든 맵 목록. 이름 · 칸 수 · 타일 크기가 표시된다 (예: 36x22 · 32px, 4 terrains)
Tilesets   16×16 / 32×32 / 64×64 로 나뉜다.  New Tileset · Import
Tiles      모양별로 나뉜다 — All / Hex flat-top / Hex pointy-top / Isometric /
           Oblique / Square top-down.  New Tiles · Import
```

> **[화면]** *"타일 그룹은 모양이 있는 픽셀아트 세트(육각·아이소·사각 탑다운 등)를
> **함께 생성해 맵에 바로 칠할 수 있게** 만든 것이다."*

**[영상]** 웹에서 먼저 만들고 엔진으로 가져가는 것을 권한다.

> *"MCP로 바로 만들 수도 있지만, 웹의 생성 페이지에서 먼저 만드는 이유는 **튀는 픽셀이 있는지
> 눈으로 보고 고친 뒤** 엔진에 넣기 위해서다. MCP로 만들면 바로 편집을 못 하고 Aseprite나
> 웹으로 가야 한다. 프로토타이핑용이면 MCP만 써도 된다."*

---

# 2. ★★ 캔버스 크기가 모든 것을 정한다

**[문서]** 이 표가 PixelLab 전체에서 제일 중요하다. 크기 하나가 **결과 개수 · 참조 개수 ·
비용**을 한꺼번에 결정한다.

| 캔버스(긴 변) | 결과 프레임 | 비용 | 참조 최대 |
|---|---|---|---|
| ≤32px | **64장** (8×8) | 20 | 64장 |
| 33~42px | 64장 (8×8) | **25** | |
| 43~64px | **16장** (4×4) | 20 | 16장 |
| 65~85px | 16장 (4×4) | **25** | |
| 86~128px | **4장** (2×2) | 20 | 4장 |
| 129~170px | 4장 (2×2) | **25** | |
| 171~256px | **1장** | 20 | **1장** |
| 257~341px | 1장 | **25** | |
| 342~512px | 1장 | **40** | |

## 여기서 나오는 규칙 셋

**1. 32 / 64 / 128 / 256에 딱 맞춘다.**
64px는 20인데 **65px는 25**다. 1픽셀 차이로 25% 더 낸다.

**2. 작게 뽑으면 화풍을 많이 배우고, 크게 뽑으면 정밀해진다.**

> **[영상]** *"작은 해상도 = 화풍 학습이 많아지고, 큰 해상도 = 정밀도가 올라간다."*

**3. 참조 개수 = 결과 개수.**
256px를 뽑으면 참조를 **1장밖에** 못 넣는다. 즉 **큰 그림은 화풍을 배우는 구간이 아니다.**

**비정사각형도 된다** **[문서]** — 종횡비에 따라 최대가 다르다(1:1은 512×512, 16:9는
688×384까지). 비용은 격자 전체 넓이로 계산되므로 종횡비에 따라 달라진다.

---

# 3. 비용 — 도구마다 열 배 이상 다르다

**[화면]** 도구 화면에 `This tool costs N generations.`이 뜨는 것과 안 뜨는 것이 있다.

| 도구 | 비용 |
|---|---|
| **S-XL Image (New)** · **M-XL (pixflux)** | 표시 없음 |
| **Create Texture** | 표시 없음 |
| **Create Tileset — Top-Down / Sidescroller** | 표시 없음 |
| Create Tileset — **Pro (32px)** | **20** |
| Create Tileset — **Pro (64px)** | **40** ← Map Workshop에서만 |
| **Create Tiles (Pro)** | **20~25** (참조를 쓰면 20~40) |
| **S-XL Image (Pro)** | **20~40** (§2 표) |
| **style references (Pro)** | **20~40** (§2 표) |
| **Inpaint (v3)** | **20** |
| **Create UI from Layout** | **20** |

**[영상]** 애니메이션 비용:

```
Pro 애니메이션    결과물 하나당 20~40
V3 애니메이션     1~8 — 스프라이트 크기에 따라
```

> **[영상]** *"Pro도 있지만 **V3가 더 싸고 더 좋고 프레임도 더 많이** 된다."*

## 잔액 보는 곳

**[화면]** `pixellab.ai/account` → **Generations** 막대.
예: `1,576 / 2,000 · 79% used · Resets Sep 3`. 그 아래 **Credits**는 월 한도를 다 쓴 뒤에
쓰이는 별도 금액이다.

---

# 4. ★ 화풍 통일 — 이 도구의 핵심

## 4.1 앵커 한 장

**[영상]** 게임 한 편의 캐릭터·애니메이션·배경·UI·로고를 전부 생성으로 만든 사례의 결론이다.

> *"**'create small to large image' 도구로 만든 그림 한 장을 모든 것의 시각적 앵커로 삼았다.**
> 새 적, 다른 포즈, 다른 동작 — 같은 화풍, **화풍 이탈이 전혀 없었다(no visual drift at all).**
> 그 결정 하나가 서로 어울리는 에셋 세트를 만들 수 있게 했다."*

```
앵커 그림 1장을 공들여 만든다
      ↓
화풍 참조로 넣고 나머지를 전부 뽑는다
      ↓
잘 나온 결과를 다시 참조 목록에 추가한다   ← 참조가 늘수록 화풍이 안정된다
```

**UI도 같은 화풍 규칙을 따르게 한다.** 따로 디자인하지 않는다.

작업 순서에 대한 조언도 함께 나온다.

> *"기능부터 만든다. 격자, 정적 캐릭터 몇 개, 핵심 루프. 시각적으로는 뼈대만 있었지만
> 기계적으로는 돌아갔다. **일단 돌아가기 시작하면 기능 추가를 멈추고** 비주얼을 제대로 다시 만든다."*

## 4.2 ★ 참조에는 두 종류가 있다 — 완전히 다른 입력이다

**[영상]** 원문 그대로다.

| | 정하는 것 | 크기 제약 |
|---|---|---|
| **화풍 참조**(style reference) | **어떤 화풍으로** | **이미 픽셀아트여야 하고 32 / 64 / 128 / 256 중 하나** |
| **개념 참조**(concept image) | **무엇을** (캐릭터 디자인·지도·옷·팔레트·배경) | **아무 크기나. 픽셀아트가 아니어도 된다** |

> *"화풍 참조는 이미 픽셀아트여야 하고 지원 크기에 맞아야 한다. 개념 참조는 그냥 '이 아이디어를
> 바탕으로 만들어줘'라는 것이라 아무 크기나 된다."*

**둘을 동시에 쓰는 것이 제일 강력하다.**

> *"캐릭터 하나를 화풍 참조로, 다른 그림을 개념 참조로 쓴다. 개념 참조가 '무엇을' 정하고
> 화풍 참조가 '어떤 화풍으로'를 정한다. **캐릭터를 특정 픽셀아트 화풍으로 다시 디자인하고
> 싶을 때 아주 강력하다.**"*

## 4.3 ★ 무엇을 가져올지 고를 수 있다

**[화면]** S-XL (Pro) 화면에 체크박스 넷이 실제로 있다.

```
Style image (1칸)  +  Reference images (0/4)

Copy from style image:   ☑ Color Palette   ☑ Outline
                         ☑ Detail          ☑ Shading
```

> **[영상]** *"화풍 참조를 쓰면, 이 설정들이 **색 팔레트 / 외곽선 스타일 / 디테일 수준 /
> 명암 기법**을 참조에서 **얼마나 가져올지** 조절한다."*

**즉 색을 끄고 그림체만 가져올 수 있다.**

## 4.4 참조 고르는 기준

> **[영상]** *"핵심은 **일관성**이다. 비슷한 도트 밀도, 비슷한 외곽선, 비슷한 명암,
> 비슷한 비율이어야 한다. 보여주는 것은 '내가 원하는 시각 언어'다."*
>
> *"**많이 넣을 필요 없다. 좋은 5~10장이 무작위 60장보다 낫다.**"*

**[문서]** *"참조를 많이 넣을수록 모델이 원하는 화풍을 더 잘 이해한다"* — 다만 위의 일관성
조건이 먼저다.

## 4.5 참조는 주제만 바짝 잘라 넣는다

> **[영상]** *"**캔버스 전체가 아니라 캐릭터에 최대한 가깝게 잘라서** 넣는다. 그게 다음 도구에
> 붙여 넣는 최적의 방법이다."*

## 4.6 참조는 내용까지 복제한다

**[영상]** 장면을 참조로 넣고 장면을 뽑으면 그 장면이 거의 그대로 나온다. 화풍만 오는 것이 아니다.

---

# 5. 타일과 맵

## 5.1 `Create Tileset` — 두 지형의 전환 (싼 쪽)

**[문서]** 두 지형을 잇는 **Wang 타일셋**을 만든다.
내보내기: Wang tileset · **dual-grid 15-tileset** · **3×3 tileset**. Sprite Fusion에서 쓸 수 있다.

```
탭        Top-Down / Sidescroller / Pro
크기      Standard: 16 · 32      Pro: 16 · 32 · 64(실험적)
```

> **★ 64px는 Pixelorama 에디터가 아니라 Map Workshop에 있다.**
>
> **[화면]** Pixelorama 에디터의 `Create Tileset` → Pro 탭 드롭다운에는
> `16×16 (not supported yet)`과 `32×32`뿐이다. **하지만 그건 그 화면의 제약이다.**
>
> ```
> pixellab.ai/maps  →  Tilesets 탭  →  16×16 | 32×32 | 64×64
>                   →  Create Your First 64×64 Tileset
>                   (= pixellab.ai/create-tileset?tileSize=64)
> ```
>
> 거기서는 셋 다 고를 수 있다 — `16×16 [EXTRA EXPERIMENTAL]` · `32×32 [EXPERIMENTAL]` ·
> `64×64 [EXTRA EXPERIMENTAL]`. 안내문도 *"Test 64×64 Pro tilesets — Create large terrain
> tiles through the Pro tileset workflow"*라고 적혀 있다.
>
> **비용은 40 generations이다** (32px Pro의 20보다 두 배).
>
> **★ 교훈: 한 화면에 없다고 도구에 없는 것이 아니다.** 같은 도구가 들어가는 길에 따라
> 다른 선택지를 준다. 문서와 화면이 어긋나면 **다른 화면을 먼저 찾아볼 것.**

**Top-Down 손잡이** (전부 싼 탭에서 쓸 수 있다) **[문서]+[화면]**

| | |
|---|---|
| **참조 슬롯 셋** | `Lower elevation tile` / `Transition tile (Beta)` / `Higher elevation tile`.<br>*"당신의 텍스처를 바탕으로 타일셋을 만든다. 하나·둘·셋을 골라 쓸 수 있다"* |
| `Transition size` | 0이면 지형이 바로 만나고, 크면 전환 띠가 넓어진다(높이차가 생긴다) |
| `Edge shape` | square(계단 모서리) / round(진짜 원호) |
| `Roundness` · `Raggedness` | 경계의 성격 |
| `Side Wall Thickness` · `Placement` | 벽이 위 테와 앞면에서 얼마나 두꺼운지, 지형 밖으로 튀어나오는지 파고드는지 |
| `Reshuffle shape` | 같은 설정에서 모양만 다시 굴린다 |
| **`Enhance descriptions`** (기본 켜짐) | 지형 묘사를 고른 디테일·명암에 맞게 AI가 고쳐 쓰고 어울리는 바탕색을 고른다.<br>**원래 프롬프트는 메타데이터에 남는다** |
| **Live preview** | **실제로 나올 타일 시트를 그대로 미리 보여준다** |

**Sidescroller**는 옆에서 본 발판을 만든다 — 속 재료(예: 흙)와 윗면에 나는 것(예: 풀)을 따로 적는다.

**타일 개수** — 우리 쪽 코드가 16장 시트만 읽는 경우 이 값이 중요하다.

```
standard   transition 0.0 / 0.25 / 0.5  →  16장        1.0        →  25장
pro        0.0 / 0.25                   →  16장        0.5 / 1.0  →  25장
```

## 5.2 `Create Tiles (Pro)` — 네 종류 (20~25)

**[문서]** 크기 **16~128px**. **여기에만 64px 사각 탑다운이 있다** **[화면]**.

| 종류 | 무엇 |
|---|---|
| **Tiles (변형)** | 한 재료의 변형 여러 장. `1) grass 2) dirt path` 처럼 번호를 매기면 항목마다 한 장.<br>**화풍 참조 타일 사용 가능** (Creator 16장, Map Workshop 6장) |
| **Paths** | 길 오토타일 **18칸 세트**. 맵 에디터가 자동 배치 |
| **Tileset** | 지형 전환. 사각·아이소·오블리크는 **16장 코너 세트**, 육각은 32장 해안선 |
| **Building** | **건축 키트 — 바닥, 이어지는 벽 조각, 문간, 기둥, 계단.** 벽 높이 1~3칸 |

모양 **[화면]**: `Isometric` / `Hexagonal (flat-top)` / `Hexagonal (pointy-top)` /
`Octagonal` / `Square top-down`
크기 **[화면]**: 16 · 16×32 · 32 · 32×64 · 48 · 48×96 · **64** · 64×128 · 96 · 128

**★ 화풍 참조는 Tiles 종류에만 쓸 수 있다** — 이어지는 세트에는 못 쓴다 **[문서]**.

추가 손잡이: `Uneven boundary`(경계가 구불거리는 정도, 시드 재굴림) ·
`Terrain height`(첫 지형을 고원으로, 절벽면 생성) · `Step slope`(0이면 수직 절벽) ·
`Wall tilt`(오블리크 전용, 27도 캐비닛 ~ 45도 대각)

## 5.3 `Create Texture` — 이음매 없는 반복 무늬 (싼 쪽)

> **[문서]** *"**Create Tileset 도구와 함께 쓰라고 만든 것이다.**"*

즉 **텍스처를 먼저 만들고 → 타일셋의 참조 슬롯에 넣는** 것이 공식 흐름이다.
옵션: 묘사 · 명암/디테일 · guidance weight · **Init image** · **Target palette** · 출력 · 시드

## 5.4 맵은 겹치게 잘라 인페인팅으로 넓힌다

**[문서]** 공식 가이드 흐름이다.

```
1. 128x128 캔버스 (16px 타일 기준 8x8칸)
2. 선택 도구로 4x4칸을 고르고 → paint in selection 켬
3. 인페인트 레이어를 선택 안쪽에 검게 칠한다 (= 여기를 생성하라)
4. 묘사를 적고 생성
5. 넓힐 때: **이미 그려진 부분과 겹치게** 선택 → 러프 스케치를 그림 →
   생성할 자리만 검게 칠함 → init image strength 조절 → 생성
6. 다 그린 뒤 인페인팅으로 손본다
```

**★ 문서가 못 박는 두 가지**

> *"모델은 **선택 영역 안만 본다.** 화풍이 이어지고 타일 사이가 매끄러우려면
> **선택 전체를 인페인트하면 안 된다** — 그러면 모델이 참고할 것이 남지 않는다."*

> *"모델 학습 방식 때문에, **묘사는 선택 영역의 한가운데에 무엇이 있는지**를 적어야 결과가 제일 좋다."*

## 5.5 맵 에디터

**[영상]**

- **오토타일**이 코너와 전환 조각을 자동으로 고른다. 끄면 특정 타일을 직접 고른다
- **stack layer** — 높이 층을 나눠 위에 얹는다
- **brush height** — 칠하면서 타일을 세로로 쌓는다(벽·단)
- **add tile group** — 같은 종류의 타일셋을 한 맵에서 같이 쓴다
- **inpaint map** — 맵 위에 칠하고 `stairs`라고 쓰면 지형에 이어지는 계단이 생긴다
- **create object** — 같은 방식이되 **움직일 수 있는 물건**으로 나온다. 배치·복제 가능
- **Export** → zip에 타일셋 + 맵 합성본 + 오브젝트가 들어 있다.
  타일셋이 **15타일 포맷**이라 Godot 기본 TileMap으로는 안 되고 **TileMapDual 플러그인**이 필요하다
- 배경만 필요하면 **오브젝트를 숨기고** export

## 5.6 연결된 타일셋 만들기

**[문서]** `base tile ID`로 지형을 이어붙인다.

```
1. 첫 타일셋(바다→모래)을 만들고 완료를 기다린다
2. get_topdown_tileset으로 base tile ID를 받는다
3. 그 모래 ID를 다음 타일셋(모래→풀)의 lower_base_tile_id로 넘긴다
```

**타일셋 ID를 버리지 말 것.**

---

# 6. 시점과 방향

**[문서]** 각도가 명시돼 있다.

```
none            아무 시점도 유도하지 않는다
low top-down    약 20도로 내려다봄
high top-down   약 35도로 내려다봄
side            횡스크롤 시점
```

**방향**: none / north(등을 보임) / east(오른쪽) / south(카메라를 봄) / west(왼쪽)

> **★ [문서]** *"이 도구에서 시점과 방향 제어는 **꽤 약하다(quite weak).** **init image를
> 같이 쓰면** 결과가 훨씬 나아진다. 묘사에 낱말을 더하는 방법도 있다 — 오른쪽을 보는 안경 쓴
> 여자를 원하면 `woman with glasses in profile`처럼 적어라."*

> *"east와 west는 대개 중복이다 — 생성된 그림을 **좌우로 뒤집으면** 되기 때문이다."*

**맵 도구의 시점은 둘뿐이다**: `high top-down`(조감) / `sidescroller`.

---

# 7. 색과 팔레트

## 7.1 생성 단계에서 강제하기

**[문서]** 여러 도구에 붙어 있다.

```
Limit colors used   No / Color palette(현재 팔레트로 제한) / Current image(고른 그림의 팔레트로)
Force colors        Target Palette에 고른 팔레트를 반드시 지키게 한다
Quantization        Auto(개수 자동) / Specify colors(개수 지정) / Use palette(특정 팔레트)
Color reduction palette   줄일 목표 팔레트. **Pixelorama에서는 Lospec에서 가져올 수 있다**
Number of Colors    몇 색으로 줄일지
```

## 7.2 만든 뒤에 강제하기

**[영상]** 공식이 화풍 통일의 답으로 내놓는 방법이다.

```
캐릭터를 만든다 → Pixelorama에서 열고 → cleanup → reduce colors → use palette
        ↓
그 팔레트가 프로젝트 팔레트가 된다
        ↓
애니메이션 · UI · 타일셋 · 오브젝트에 전부 같은 팔레트를 적용한다
```

> *"**서로 다른 도구로, 다른 날 만든 에셋이라도 같은 색만 쓰게 된다.**"*

`reduce colors`의 적용 범위: 현재 프레임 / 고른 프레임 / **모든 프레임**(애니메이션은 이것).
출력: 새 레이어 / 현재 레이어 수정 / 새 프레임.
**적용 전에 지저분한 픽셀을 먼저 치울 것 — 깨끗한 입력이 결과가 좋다.**

**타일셋도 된다** — Pixelorama에서 팔레트를 적용하고 갤러리에 저장하면 **맵 에디터가 자동으로
갱신된다.** 맵을 다시 그릴 필요가 없다.

---

# 8. UI

## 8.1 사슬로 만든다

**[영상]** `Generate UI`의 핵심은 **직전 결과를 개념 참조로 계속 물려주는 것**이다.

```
1. 메인 패널을 먼저 만든다 (재질·색을 여기서만 지정)
2. 그 결과를 개념 참조로 넣고 → "health bar" 한 마디만
3. 또 그걸 넣고 → "round mini map frame"
4. 또 → "dialogue box, portrait frame"
```

> *"빨간 체력바를 그냥 요청하면 SF 스타일이 나오거나 나무 색조가 달라질 수 있다. 방금 만든
> 메뉴를 개념 참조로 넣으면 '**이 나뭇결, 이 금색 팔레트를 쓰라**'는 걸 안다."*
>
> *"**나무니 금색이니 설명하지 않는다.** 그냥 'round mini map frame'이라고 친다."*
>
> *"**새 스타일을 발명하지 않고, 이미 있는 스타일을 확장했다.**"*

- `description` — 짧게. **재질·색을 적지 말 것**(개념 참조가 담당)
- **`color palette`** — *"UI에는 이게 결정적이다"*
- **`remove background` 항상 켤 것** — *"나중에 흰 배경 지우느라 몇 시간 날리는 걸 아낀다"*

## 8.2 레이아웃에서 만들기

**[화면]** `Create UI from Layout` (20 gen). 캔버스에 요소를 직접 배치하고 프롬프트를 건다.

```
배치 가능한 조각   Button · Icon button · Toolbar · Tab · Panel · Window
                   Health bar · Avatar · Triangle · Pentagon · Hexagon · Octagon
조작               드래그로 이동 · 모서리로 크기 · 반지름 손잡이로 둥글기
캔버스             256×256 등
```

**[영상]** 생성 뒤:

- **split into elements** — 개별 에셋으로 쪼갠다
- **nine slice** — 수동으로 정확히 자른다 → Godot `StyleBoxTexture`에 바로 물린다
- **edit** — 튀는 픽셀 정리
- **states** — 체력바를 만들고 `empty health bar` 상태를 추가하는 식

프롬프트 예: `deep charcoal slate framed by cool iron and ignited by sharp hits of hearthfire orange`
— 재질·금속·강조색을 한 문장으로.

> *"인벤토리 칸처럼 **같은 화풍의 낱개 여러 개**는 UI 도구보다 **화풍 참조 도구**가 낫다.
> 큰 이미지 하나와 레이아웃을 신경 쓸 필요 없이 같은 화풍의 여러 옵션을 얻는다."*

---

# 9. 캐릭터

## 9.1 같은 화풍으로 여럿 만들기

**[영상]** 공식 워크플로.

```
1. Character Creator로 기준 캐릭터 1명 생성 (enhance prompt 켜고)
2. Pixelorama로 열어 8방향 회전을 먼저 정리(cleanup)
3. 그 캐릭터를 선택 도구로 복사   ← 캔버스가 아니라 캐릭터에 바짝 붙여서
4. Create from style reference (Pro)에 붙여넣기
5. 만들고 싶은 캐릭터들을 **한 번에 나열**해서 프롬프트
6. remove background 켜고 생성 → 스프라이트 시트로 여러 명이 한 번에
7. 마음에 드는 결과물을 다시 화풍 참조에 추가 → 참조가 늘수록 화풍이 안정됨
8. 각 캐릭터를 create character로 8방향 캐릭터로 승격
```

**한 번에 나열하는 예:**

```
a woman farmer, woman witch, male knight wearing a metal armor,
old man wearing a robe, anthropomorphic red dragon wearing a kimono, no held items
```

**비용 관점이 뒤집힌다** — 40회가 1명 값이라고 생각해도 한 번에 5명이 나오면 **8회/명**이다.

**포즈·표정 세트도 같은 요령이다.** `same character design`을 붙이고 상태를 나열한다.

```
catgirl with a blue outfit, different poses, idle, hurt, about to punch,
midwalk, midrun, jump, action poses, same character design
```

## 9.2 States — 캐릭터 변형

**[영상]** 숨은 용도가 **같은 캐릭터의 다른 모습**이다.

> *"다른 복장, 손상된 버전, 강화 버전, NPC 변형, 다른 갑옷을 입은 적 — **기본 캐릭터는 그대로
> 두고** 포즈나 디자인만 바꾸고 싶을 때."*

예: `same goblin, red outfit` · `same goblin wearing a Christmas outfit`
**단, 캐릭터 시스템에 등록된 캐릭터가 필요하다** — 낱장 PNG로는 못 쓴다.

- 애니메이션은 idle에서 시작하지 말고 **먼저 그 동작에 가까운 state를 만든 뒤** 거기서 시작하면
  결과가 훨씬 깔끔하다
- **세로로 긴 캔버스가 유리하다** — *"가로를 좁게 세로를 길게 주면 모델이 주변 공간을 낭비하지
  않고 캐릭터 형태에 집중한다"* (예: 32×44)
- **interpolation** — 시작·끝 프레임을 주면 사이 동작을 생성한다

## 9.3 회전

**[문서]/[영상]** 4방향 또는 8방향을 한 번에 만든다.
**동서는 미러링으로 아끼되, 미러링 전에 원본을 먼저 정리할 것.**

---

# 10. 오브젝트

**[영상]** `Object Creator`

- **"에셋 팩"으로 한 번에 여러 개** 프롬프트 가능 — 낱개로 뽑을 필요 없다
- 크기는 슬라이더로. **화풍 참조를 자기 에셋에서 드래그해 넣을 수 있다**
- 생성 후 **원하는 것만 골라 남기고, 태그 달고, 지운다**
- 화풍 참조를 안 쓰면 **perspective(top down / sidescroller)** 를 고를 수 있고,
  드롭다운에서 **항목별로 따로 설명**을 달 수 있다
- **8방향 회전 오브젝트**도 만들 수 있다
- 오브젝트에도 **state**가 있다 — `dirty` 하나로 더러워진 수도꼭지가 나온다

**비용**: 1/8방향 오브젝트 생성 **20~40**, 오브젝트 8방향 애니메이션 `pro`는
**방향당 20~40(8방향이면 160~320)**. **애니메이션은 `v3`(기본)를 쓸 것.**

---

# 11. 인페인팅과 편집

**[문서]** 도구가 여럿이다: `Inpaint` · `Inpaint v3`(20) · `Inpaint M-L (pixpatch v2)` ·
`Edit image` · `Edit image (Pro)`

**[화면]** Inpaint v3 옵션: `Paint in selection` · 묘사 · 출력 방식 ·
`Remove background` · `Crop to mask` · 고급 옵션

> **[문서/화면] `use selection tool to select painting area`(= Paint in selection) 옵션이
> 꺼져 있으면 늘린 영역을 아예 처리하지 않는다.** 캔버스를 넓혀 바깥을 그리게 할 때 반드시 켤 것.

**[홈페이지]** 인페인팅을 이 도구의 차별점으로 내세운다.

> *"다른 모델과 달리, 우리 도구는 편집하는 동안 **원본 이미지를 보고 이해한다.** 옷을 갈아입히거나
> 액세서리를 더하거나 환경을 고칠 때 화풍이 완벽하게 맞는 이유다."*

**[영상]** 공식이 미는 화풍 유지 수단이 **새 생성이 아니라 편집**이라는 점도 같은 맥락이다.

> *"**PixelLab은 당신이 이미 만들고 있는 픽셀아트를 이해한다.** 캐릭터를 편집하고, 옷을 바꾸고,
> 물건을 추가하고, 작은 디테일을 고쳐도 **스프라이트의 룩이 깨지지 않는다.**"*

---

## 11.1 ★ init image — 이 도구에서 제일 과소평가된 손잡이

**[문서]** 시점 제어가 약할 때 공식이 권하는 해법이 이것이다(§6).

> *"맨바닥에서 시작하는 대신 **init image를 줄 수 있다. 결과가 더 좋아지는 경우가 많고,
> 색과 원근을 잡아주는 효과적인 방법**이다."*

> *"어떤 도구에서는 init image가 이상해 보일 수 있다. 예를 들어 스케치 모델을 쓸 때 init
> image가 쓸모없다고 결론 내리면 **틀린 것이다.** 오히려 **생성될 그림의 색과 형태를
> 통제하는 데 아주 유용하다.**"*

### init image strength — 수치 구간이 문서에 있다

```
0 ~ 300     아주 거친 색 유도만
300 ~ 400   형태와 색을 거칠게. 색 덩어리를 대충 찍어놓고 자리를 잡을 때
400 ~ 600   중간. 기존 그림의 변형을 만들 때
600 ~ 900   세밀. 거의 완성된 그림에 디테일을 더하거나 조금만 고칠 때
```

## 11.2 인페인팅의 규칙

**[문서]**

```
1. "Inpainting" 레이어가 자동으로 생긴다
2. 고치고 싶은 자리를 **검게 칠한다** — 모델은 검은 부분만 바꾼다
3. 프롬프트는 **표시한 자리만이 아니라 모델이 보는 영역 전체**를 묘사한다
   (모델은 그림 전체를, 또는 "use selection"을 켰으면 선택 영역을 본다)
```

**지원 도구**: Inpaint · Style · Map · Rotate · Animation

> *"init image와 함께 쓰면 특히 강력하다 — 예를 들어 캐릭터 손에 무기를 쥐여 줄 때."*

**[문서]** 공식 예시 흐름(마법사 만들기):

```
러프 스케치를 init image로 → "Human mage" 생성
→ 머리가 이상하다 → 머리만 검게 칠하고, **생성된 그림을 init image로 삼고**,
   init strength를 조금 낮춰 자유를 주고, 출력을 "Modify current layer"로
→ 손이 이상하다 → **스케치를 조금 그려 넣고** 그 자리를 검게 칠해서 다시
```

**즉 init image와 인페인팅을 겹쳐 쓰면서 조금씩 조여 가는 것이 공식 워크플로다.**

---

# 12. 그 밖의 도구

**[화면]** Pixelorama 에디터 패널별 목록.

```
Create    Create Image · Style Reference(PRO) · 8-Direction Character · Image to Pixel Art
          Image to Image (Depth) · Same-Style Character · Portrait <-> Character(PRO BETA)
          Create Pixel Font(PRO BETA) · Character from Template(WEB)
UI        From Layout(PRO) · Elements(PRO) · Experimental(BETA)
Edit      Edit Image · Edit Animation(PRO) · Transfer Outfit(PRO)
          Multi-Image Edit(BETA) · Try On(BETA) · Resize(BETA)
Rotate    Rotate to 8 Rotations · Rotation
Animate   Animate with Text · Interpolate(NEW) · Edit Animation(PRO) · Transfer Outfit(PRO)
          Animated Object/Character(PRO) · Animate with Skeleton · Animation to Animation
Map       Create Tileset · Create Map (Pixflux) · Extend Map · Create Texture · Create Tiles
Inpaint   Inpaint (v3 / M-L / Legacy)
Cleanup   Remove Background · Reduce Colors · Unzoom Pixel Art · Pixel Art Correction(NEW)
```

**눈여겨볼 것 넷**

- **`Unzoom Pixel Art`** — 늘어난 그림을 진짜 1배 도트로 되돌린다
- **`Pixel Art Correction`** — 튀는 픽셀을 정리하고 정렬한다
- **`Interpolate`** — 시작·끝 프레임 사이를 채운다
- **`Image to Pixel Art`** — 아무 그림이나 픽셀아트로 바꾼다

---

---

# 12.5 옵션 사전 — 화면에서 보게 되는 항목 전부

**[문서]** 여러 도구에 공통으로 나오는 항목들이다. 뜻을 모르고 기본값으로 두는 일이 없게 모아둔다.

## 일반

| 항목 | 뜻 |
|---|---|
| **Paint in selection** | 선택한 영역 **안에만** 그리게 한다. 캔버스를 넓혀 바깥을 그릴 때 반드시 켤 것 |
| **Force symmetry** | 좌우 대칭을 강제한다.<br>**회전 도구에서는**: 남·북을 좌우 대칭으로, **서·동을 서로의 거울상으로** 만든다 |
| **Remove background** | 투명 배경으로 생성 |
| **Gray background guidance weight** | 배경 제거에 쓰이는 회색 배경 생성을 얼마나 유도할지 |
| **Pixel art style guidance weight** | 결과가 얼마나 픽셀아트답게 느껴질지를 **약하게** 조절 |
| **Seed** | 난수 씨앗. **같은 시드 + 작은 변경 = 아주 비슷한 결과.** `0`이면 무작위.<br>**고급 옵션을 켜야 보인다** |
| **Output method** | `New layer`(새 레이어) / `Modify current layer`(현재 레이어를 고침. init image를 썼다면 그것이 바뀐다) / `New frame`(새 프레임) |
| **Tile size** | 생성·확장할 타일 크기 |

## 유도(Guidance)

| 항목 | 뜻 |
|---|---|
| **Description** | 무엇을 만들지 **짧게** |
| **Negative description** | **무엇이 나오면 안 되는지.** 원치 않는 것을 밀어내는 데 쓴다 |
| **Guidance weight** | 지시를 얼마나 따를지. **과하면 과채도 같은 아티팩트가 생긴다** |
| **Fidelity** | 원본에 얼마나 충실할지 |
| **Style guidance weight** | 화풍 이미지를 얼마나 베낄지 |
| **Depth strength** | 참조의 깊이를 얼마나 베낄지 |

## 캐릭터

| 항목 | 뜻 |
|---|---|
| **Action description** | 프레임 사이를 채울 동작 — `walk` · `run` · `fire breath` 같은 것 |
| **Size of character** | 생성될 캐릭터의 크기 |
| **From view / To view** | 참조가 어떤 시점인지 / 결과가 어떤 시점이어야 하는지 |
| **From direction / To direction** | 참조가 보는 방향 / 결과가 볼 방향 |
| **Rotation / Tilt** | 돌릴 각도 / 기울일 각도 |
| **Character type** | 쓸 템플릿 — `Bipedal-realistic` / `Quadrupedal-tiny` / `Bipedal-semi-chibi` |
| **Direction type** | `Cardinal`(동서남북) / `Ordinal`(북동·북서·남동·남서) |
| **Scale** | 기본 크기에 대한 백분율 |

---

# 13. MCP / Vibe Coding

**[영상]** 공식이 Claude Code + Godot 조합을 직접 시연한다.

- MCP 도구: create character / animate character / top-down 타일셋 / 횡스크롤 타일셋 / 아이소메트릭 타일
- 설치는 pixellab.ai에서 IDE를 고르고 **터미널 명령 한 줄** 복사·실행(인증 토큰 포함)
- **캐릭터를 이름으로 찾아온다** — *"ID를 줄 필요도 없다. 이름만 말하면 알아서 찾아서 내려받고
  프로젝트에 넣는다"*
- 공식이 **Godot에는 Claude Code를 특히 권장**한다: *"GPT나 Gemini는 GDScript와 Godot 엔진,
  씬 만들기 같은 걸 어려워한다"*
- 웹 **API 탭**에 "AI documentation" 링크가 있다 — 그걸 AI에게 주면 알아서 API를 쓴다
- **백그라운드 작업은 최대 10개**까지 동시에
- **한 번에 너무 많은 애니메이션을 시키면 특정 방향에서 실패**한다 → 실패한 것만 다시 요청
- **프롬프트는 최대한 구체적으로.** 애매하면 엉뚱한 씬에 만들어 놓는다

## 13.1 연결 방식 — 설치할 패키지가 없다

**[문서]** 오해하기 쉬운 부분이라 문서가 못 박는다.

> *"PixelLab의 MCP는 **원격 HTTP 서버지 npm 패키지가 아니다.** 설치할 것이 없고
> `@pixellab/...`이나 `@anthropic/...` 같은 패키지도 없다."*

```
엔드포인트   https://api.pixellab.ai/mcp
인증         Authorization: Bearer <계정 페이지의 secret 토큰>
```

- **원격 HTTP MCP를 지원하는 클라이언트**는 그 주소를 그대로 가리키면 된다
- **stdio만 되는 클라이언트**(Codex CLI 등)는 `npx mcp-remote@latest`로 다리를 놓는다.
  **MCP 페이지가 그 조각을 만들어 주므로 직접 쓸 필요 없다**

## 13.2 MCP는 Claude 전용이 아니다

> *"MCP는 열린 프로토콜이지 Anthropic 전용이 아니다."*

**바로 쓸 설정을 주는 클라이언트** **[문서]**:

```
Claude Code · Claude Desktop · Codex CLI(OpenAI) · Cursor · VS Code · Gemini CLI
Windsurf · Zed · Cline · Continue · Droid · Kiro · Junie · Warp · BoltAI
LM Studio · Perplexity Desktop
```

MCP를 말하는 것이면 무엇이든 된다.

**[문서]** `pixellab.ai/mcp` = AI Agent Toolkit. API 문서는 `api.pixellab.ai/v1/docs`.
Python SDK도 있다.

---

# 14. 프롬프트 쓰는 법

## 14.1 화풍 참조를 쓸 때

> **[영상]** *"묘사 칸은 **화풍을 적는 데가 아니다. 화풍은 이미 그림에서 온다.** 여기엔
> **무엇을 만들지**만 적어라."*
>
> *"프롬프트를 쓴다기보다 **픽셀아트 화가에게 지시를 준다**고 생각하라."*

좋은 예: `medieval weapons` · `small slime enemies` · `fantasy character faces` ·
`magic potions and items` — **짧은 명사구**다.

## 14.2 타일셋

**[영상]** 영상에서 실제로 쓰는 값이다.

```
outline          켠다 (single color outline)
detail           low detail
shading          basic shading
transition_size  0.5      ← "대부분의 게임에서 보는 표준 벽"
묘사             두 단어   "sand to water" / "dungeon floor to lava"
```

**일러스트 감각으로 값을 올리면 작은 타일에서 뭉개진다.**

## 14.3 그 밖에

- **`enhance prompt` 버튼을 매번 누른다** (공식 권장)
- **`no held items`** 처럼 **빼고 싶은 것도 적는다**
- **`symmetrical`은 좌우 거울 복제를 부른다**
- 게임 타이틀·로고도 만든다:
  `a text title for a game called X, ~styled letters, fire coming out of the letters`
- **`seed`로 재현 가능.** 웹은 생성 후 시드를 알려주고 `Reuse seed` 버튼을 준다.
  **API/MCP는 시드를 안 돌려주므로 재현이 필요하면 호출할 때 직접 지정해야 한다**

---

# 15. ★ 공식이 반복하는 원칙

## 15.1 AI 결과를 그대로 쓰는 워크플로가 아니다

**[영상]** 모든 영상의 공통 메시지다. 영상 내내 ***"clean it up"***을 반복한다.

> *"생성 결과에 아티팩트가 섞이는 건 정상이고, **Pixelorama에서 손으로 정리하는 게 전제**인
> 워크플로다."*

공식 시연에서도 MCP로 만든 캐릭터가 **앞뒤 옷이 다르고 이상한 이펙트가 섞여** 나온다.

**뽑고 → 손보고 → 팔레트 맞추고 → 넣는 것까지가 한 벌이다.**

## 15.2 화풍은 "생성할 때 잡는 것"이 아니라 "만든 뒤 강제하는 것"

§7.2를 볼 것. 생성 단계에서 거드는 것(`target palette`,
`use color palette from reference`, 같은 시드·같은 파라미터)은 **도움은 되지만 보장은 안 된다.**

## 15.3 한 번에 여러 개를 나열하라

캐릭터든 오브젝트든 UI든, **한 프롬프트에 나열하면 시트로 한꺼번에 나온다.**
개당 비용이 몇 분의 일이 되고, 서로 같은 화풍으로 나온다.

## 15.4 편집이 재생성보다 낫다

같은 캐릭터의 변형이 필요하면 새로 뽑지 말고 **state를 더하거나 인페인팅으로 고친다.**

---

# 16. 확인 안 된 것

**직접 안 열어봤거나 확인이 안 된 것.** 짐작해서 채우지 않는다.

| | 왜 |
|---|---|
| **맵 편집 화면 · Export** | Maps 탭의 맵을 열었더니 **화면이 응답하지 않았다.** 무거운 편집기로 보인다.<br>Export 절차(§5.5)는 **[영상]에서 온 것이고 화면으로 확인 못 했다** |
| **Character Creator / Object Creator 전용 페이지** | 에디터 안 도구만 봤다 |
| `Building` 키트 결과물 | 문서 설명만 읽었다 |
| `Sidescroller` 타일셋 탭 옵션 | 탭 이름만 봤다 |
| **애니메이션 도구들의 화면상 비용** | 비용 수치는 **[영상]에서 온 것**이다. 화면으로 확인 못 했다 |
| `Portrait <-> Character` · `Create Pixel Font` · `Try On` · `Multi-Image Edit` · `Reshape` | 목록에만 있다 |
| Aseprite 확장 | 설치 안 함 |
| **표시 없는 도구의 실제 비용** | `This tool costs N` 표시가 없는 도구가 정말 1 gen인지 **확인 안 됨** |

---

# 17. 이 문서를 이어 쓰는 법

1. **화면에서 본 것과 문서에서 읽은 것을 구분해 적는다** — `[문서]` `[화면]` `[영상]`
2. **한 화면에 없다고 도구에 없는 것이 아니다.** 들어가는 길(에디터 / Map Workshop /
   Creator / Characters / Objects)마다 선택지가 다르다. §5.1의 64px가 그 예다
3. **비용은 반드시 화면의 `This tool costs N generations.`을 옮긴다.** 짐작하지 않는다
4. **확인 못 한 것은 §16에 적는다.** 비워두면 다음 사람이 확인된 사실로 오해한다
