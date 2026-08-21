# 이펙트 설명서

화면에서 **움직이고 번지고 흩어지는 것**을 만드는 법. 셰이더 여덟 개와 `_draw()` 다섯 군데가
이미 있는데 이름 없이 짜여 있어서, 먼저 이름을 붙이고 안 써본 층을 적어둔다.

`SOUND.md`가 소리 쪽에 하는 일을 그림 쪽에 하는 것이다.

## 이 문서의 규칙

**출처에 우선순위가 있다.**

1. **공식 문서** — Godot 문서. 변수 이름과 동작
2. **업계 관행** — 게임 이펙트·손맛 글. 방향
3. **우리 경험** — 맨 아래(§9). 위와 어긋나면 **위가 맞다**

**확인 안 된 것은 "확인 안 됨"이라고 적는다.**

---

## 1. 이펙트는 다섯 층 중 하나에서 만든다

| 층 | 하는 일 | 우리 상태 |
|---|---|---|
| **셰이더** | 픽셀 하나하나를 GPU가 계산 | 여덟 개. 제일 많이 쓴다 |
| **`_draw()`** | 도형을 코드로 그린다 | 다섯 군데 |
| **트윈** | 값 하나를 시간에 따라 움직인다 | 쓴다. **곡선은 두 종류만** |
| **파티클** | 알갱이 수백 개를 GPU가 굴린다 | **한 번도 안 썼다** |
| **2D 조명** | `PointLight2D` + 그림자 | **안 쓴다.** 셰이더로 흉내 낸다 |

**고르는 기준은 "개수"와 "무엇이 변하는가"다.**

```
그림 전체가 한꺼번에 변한다        → 셰이더   (디더, 비네트, 물결)
개수가 많고 제각각 살다 죽는다     → 파티클   (불티, 부스러기, 먼지)
몇 개 안 되고 규칙이 있다          → _draw()  (빛줄기, 낱장, 복도 선)
값 하나가 A에서 B로 간다           → 트윈     (자리 옮김, 밝기, 유니폼)
```

**층을 잘못 고르면 코드가 세 배가 된다.** 우리가 `Pages`를 노드 대신 `_draw()`로 짠 것,
`EdgeBleed`를 파티클 대신 셰이더로 짠 것이 다 이 판단이다.

---

## 2. 셰이더 (`shader_type canvas_item`)

### 내장 변수 — 이것만 알면 2D는 거의 다 된다

| | 어디서 | 무엇 |
|---|---|---|
| `UV` | 정점·프래그먼트 | 그림 안 좌표. 0~1 |
| `COLOR` | 둘 다 | **뜻이 다르다. 아래 ★ 참고** |
| `TEXTURE` | 프래그먼트 | 이 스프라이트의 그림 |
| `TEXTURE_PIXEL_SIZE` | 둘 다 | 도트 한 칸이 UV로 얼마인가. **픽셀 단위로 계산할 때 쓴다** |
| `SCREEN_UV` | 프래그먼트 | 화면 좌표. 0~1 |
| `SCREEN_PIXEL_SIZE` | 프래그먼트 | 화면 픽셀 한 칸. **화면비 보정에 쓴다**(`Vignette`) |
| `TIME` | 어디서나 | 흐른 초. `Engine.time_scale`을 따른다 |
| `VERTEX` | 정점 | 로컬 좌표. 여기를 밀면 그림이 통째로 움직인다 |
| `FRAGCOORD` | 프래그먼트 | 화면 픽셀 좌표(정수) |

`render_mode`로 섞는 법을 바꾼다 — `blend_mix`(기본) `blend_add`(빛) `blend_sub` `blend_mul`
`unshaded` `light_only`. **우리는 `DitherLight`에서만 `blend_add`를 쓴다.**

### ★ COLOR의 뜻이 정점과 프래그먼트에서 다르다 (우리가 하루를 태운 것)

공식 문서 그대로다.

```
정점        COLOR = 정점색 × CanvasItem의 modulate × self_modulate
프래그먼트   COLOR = (위의 정점 COLOR) × TEXTURE에서 읽은 색
```

그래서 이렇게 하면 **`modulate`가 통째로 사라진다.**

```glsl
void fragment() {
    COLOR = texture(TEXTURE, UV);   // ← modulate가 날아간다
}
```

그리고 이렇게 하면 **두 번 곱해져서 어두워진다.**

```glsl
COLOR = texture(TEXTURE, UV) * COLOR;   // ← 프래그먼트 COLOR엔 이미 텍스처가 들어 있다
```

**정답은 정점에서 받아 두는 것이다**(`EdgeBleed`가 이렇게 한다).

```glsl
varying vec4 tint;
void vertex()   { tint = COLOR; }
void fragment() { vec4 lit = texture(TEXTURE, UV) * tint; COLOR = lit; }
```

`fragment()` 안에서는 **`return`을 못 쓴다.** 건너뛰려면 `discard`거나 `if`로 감싼다.

### 화면을 다시 읽기

Godot 4에서 `SCREEN_TEXTURE`는 없어졌다. 유니폼으로 직접 받는다.

```glsl
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
// vec3 under = texture(screen_texture, SCREEN_UV).rgb;
```

**세 가지 함정이 있다.**

1. **복사는 그리기 순서상 처음 읽는 노드에서 한 번만 일어난다.** 뒤에 오는 노드를 위해 다시
   뜨지 않는다 — 화면 읽는 셰이더 둘을 겹쳐 쌓으면 뒤엣것이 앞엣것의 결과를 못 본다
2. **알파가 1.0으로 강제된다.** 투명도를 읽어 쓸 수 없다
3. **밉맵을 켜면 값이 비싸다.** 흐리게 할 때만 쓴다

우리 것: `CrtScreen`(layer 200) · `DitherScreen` · `Vignette`. **순서가 곧 화면이라서
`CanvasLayer`의 층 번호가 이 셋의 관계를 정한다.**

### 도트를 지키는 세 가지

우리 셰이더 주석에 흩어져 있는 규칙이다.

| | 어떻게 | 우리 것 |
|---|---|---|
| **거칠게 읽는다** | `filter_nearest` | `CrtScreen`, `DitherScreen` |
| **밀림을 정수로 끊는다** | `floor(x + 0.5)` | `PortalWave` |
| **시간도 끊는다** | `floor(TIME * hz)` | `EdgeBleed`의 `shimmer` |

세 번째가 제일 값어치 있다. **매 프레임 바꾸면 지글거려서 눈이 아프다.** 손으로 찍은 도트
애니메이션이 초당 열몇 장이므로, 셰이더의 난수도 그 박자로 끊어야 같은 화면에 산다.

### 우리 것에는 이름이 있다

| 우리 셰이더 | 이름 | |
|---|---|---|
| `DitherFilter` / `DitherScreen` | **오더드 디더링(Bayer 8×8) + 포스터라이즈** | 계조를 깎고 경계를 격자로 흩는다 |
| `DitherLight` | 같은 것을 **알파에** | 빛도 도트로 흩어진다 |
| `EdgeBleed` | **디졸브** (임계값 + 해시 난수) | 픽셀마다 뽑은 난수보다 작으면 `discard` |
| `PortalWave` / `PortalLeak` / `AuraRipple` | **UV 디스토션 / 도메인 워핑** | 읽는 자리를 옮겨 그림을 흔든다 |
| `Vignette` | **마스크 / 비네트** | 원 하나로 화면을 여닫는다 |
| `CrtScreen` | **배럴 왜곡 + 스캔라인** | 후처리 |
| `hash(cell)`로 뽑는 난수 | **값 잡음(value noise)** | 좌표를 넣으면 늘 같은 수가 나온다 |

### 아직 안 써본 것

- **SDF(부호 있는 거리 함수)** — 점 하나에서 "그 도형까지 얼마나 먼가"를 재는 함수. 원·상자·
  선분 공식이 다 나와 있고, `min`/`max`로 도형을 합치고 깎을 수 있다. **텍스처 없이 도형을
  만드는 방법**이라 빛줄기·마법진·테두리에 맞는다
- **`FastNoiseLite` / `NoiseTexture2D`** — 우리는 해시를 직접 짜서 쓴다. 노이즈 텍스처를
  유니폼으로 넣으면 펄린·심플렉스·셀룰러를 골라 쓸 수 있고, **`seamless`를 켜면 이음매가
  없어진다.** `Gradient`로 색까지 입힌다
- **팔레트 강제** — 우리 디더는 계조만 깎는다. 정해둔 색 목록에서 **가장 가까운 색을 찾아
  바꾸는** 방식이 따로 있다(OKLAB 색공간에서 비교하면 눈에 더 맞는다고 한다)
- **`light()` 함수** — 2D 조명이 이 스프라이트에 어떻게 닿을지를 직접 쓴다. 우리가 조명을
  안 쓰므로 아직 쓸 일이 없다

---

## 3. 코드로 그리기 — `_draw()`

`CanvasItem`이면 아무 노드에서나 `_draw()`를 덮어쓸 수 있다.

**`_draw()`는 한 번만 불리고 결과가 저장된다.** 계속 움직이려면 `queue_redraw()`를 불러야
한다(우리는 움직인 다음에 부른다 — `scripts/map/Pages.gd:86`).

```
선     draw_line  draw_polyline  draw_multiline
면     draw_rect  draw_circle  draw_arc  draw_polygon  draw_colored_polygon
그림   draw_texture
글자   draw_string
좌표   draw_set_transform     ← 노드를 안 옮기고 그리는 자리만 돌린다
```

**노드를 수백 개 만드는 것보다 싸다.** 낱장 종이, 빛줄기, 복도 선처럼 **같은 것이 여러 개**면
`_draw()` 하나가 맞다.

우리 것: `Pages.gd`(흩날리는 낱장) · `LightMenu.gd`(빛줄기 원뿔) · `Encounter.gd`(복도 선 둘) ·
`PhotoStack.gd` · `WalkScene.gd`.

### ★ 반드시 `.round()`

```gdscript
var at: Vector2 = _at[i].round()   # Pages.gd
```

소수점 자리에 그리면 화면이 정수배로 확대될 때 가장자리가 흐려져 **도트가 아니게 된다.**
`_draw()`를 쓸 때마다 걸리는 함정이라 좌표를 넘기기 직전에 무조건 반올림한다.

---

## 4. 트윈

`create_tween()`으로 만든다. **`Tween.new()`는 동작하지 않는다.** 트윈은 만든 노드에 매여
있어서 그 노드가 죽으면 같이 죽는다(그래서 씬을 갈아탈 때 안전하다).

### 곡선 — 우리는 열두 개 중 둘만 쓴다

| `TRANS_` | 느낌 | |
|---|---|---|
| `LINEAR` | 기계적. **죽은 것처럼 보인다** | 되도록 쓰지 않는다 |
| `SINE` | 부드럽게 | 우리가 쓴다 |
| `QUAD` `CUBIC` `QUART` `QUINT` | 차수가 높을수록 급하다 | **`CUBIC`만 쓴다** |
| `EXPO` | 아주 급하다 | 딱 끊기는 움직임에 |
| `CIRC` | 제곱근 | |
| `BACK` | **끝에서 살짝 지나쳤다 돌아온다** | 안 써봤다 |
| `ELASTIC` | 끝에서 출렁인다 | 안 써봤다 |
| `SPRING` | 용수철처럼 | 안 써봤다 (4.1부터) |
| `BOUNCE` | 끝에서 튄다 | 안 써봤다 |

`EASE_IN`(느리게 출발) · `EASE_OUT`(빠르게 출발해 잦아듦) · `EASE_IN_OUT` · `EASE_OUT_IN`.

**때리고 맞는 데는 `EASE_OUT`이 기본이다** — 사건은 시작이 제일 세고 뒤로 갈수록 잦아든다.
`BACK`+`EASE_OUT`은 "살짝 지나쳤다 제자리"라서 UI가 살아난다고 알려져 있는데 **안 써봤다.**

### 손잡이

```gdscript
tween_property(대상, "속성", 목표, 시간)   # "position:x" 처럼 성분만도 된다
tween_method(함수, 시작, 끝, 시간)         # ★ 셰이더 유니폼을 움직이는 유일한 길
tween_callback(함수)
tween_interval(초)
set_parallel() / chain()                   # 동시에 / 다시 차례대로
set_loops()
await tween.finished                       # 무한 반복이면 절대 안 온다
```

**`tween_method`가 특히 중요하다.** 유니폼은 속성이 아니라서 `tween_property`로 못 건드린다 —
우리 `_enemy_struck()`이 `hold` 값을 이걸로 되돌린다.

---

## 5. 파티클 — 아직 한 번도 안 썼다

`GPUParticles2D` + `ParticleProcessMaterial`이 짝이다(`CPUParticles2D`는 저사양용이고
**앞으로 새 기능이 안 들어간다**).

| 속성 | |
|---|---|
| `amount` | 몇 개 |
| `lifetime` | 하나가 사는 초 |
| `one_shot` | 한 번 뿜고 멈춘다. **터지는 것은 이걸 켠다** |
| `explosiveness` | 0이면 고르게, **1이면 한꺼번에** |
| `preprocess` | 켤 때 이미 몇 초 흐른 상태로 시작 (연기·먼지에 필요) |
| `randomness` | 값을 흩뜨리는 정도 |
| `local_coords` | 켜면 노드를 따라다니고, 끄면 뿌린 자리에 남는다 |
| `draw_order` | 뿌린 순서 / 남은 수명 순 |
| `fixed_fps` | **정해진 박자로만 굴린다** |
| `visibility_rect` | 이 밖은 안 그린다. 안 맞추면 통째로 사라진다 |

**우리 화면에 쓰려면 두 가지를 조심해야 한다**(확인 안 됨).

1. 알갱이가 소수점 자리에 놓이면 도트가 깨진다 → `fixed_fps`를 낮게 잡고 알갱이 그림을
   도트로 찍어 넣는다
2. 알갱이 그림도 **놓일 크기 그대로**여야 한다 (`CLAUDE.md` 그림 규칙)

쓸 자리: **종이 부스러기**(종이 적을 때릴 때) · **불티**(등불) · **먼지**(발밑) ·
**깨진 유리**(등불이 꺼질 때). 지금은 이걸 다 셰이더나 `_draw()`로 흉내 내고 있다.

---

## 6. 2D 조명 — 안 쓰고 셰이더로 흉내 낸다

Godot의 정식 방법은 셋을 조합하는 것이다.

```
CanvasModulate     화면 전체의 바탕 어둠. 빛이 안 닿는 곳의 색
PointLight2D       텍스처를 얹어서 밝히는 빛
LightOccluder2D    그림자를 만드는 가림막. 모양을 따로 그려줘야 한다
```

**우리는 `Vignette` 셰이더 하나로 대신한다** — 등불 자리에 구멍을 뚫고 반경을 여닫는 방식.
이 게임이 "등불이 비추는 것만 실재한다"는 한 문장 위에 서 있어서, **빛이 물체에 가려지는
것보다 빛이 닿는 범위 자체가 중요했기 때문이다.**

정식 조명으로 갈아타면 얻는 것 — **책장이 그림자를 드리운다.** 잃는 것 — 가림막 폴리곤을
전부 그려야 하고, 꼭짓점이 많으면 느려진다. **아직 저울질 안 해봤다.**

---

## 7. 손맛(juice) — 때린 티를 내는 법

업계에서 이름이 붙어 있는 것들이다. 우리 `_enemy_struck()`이 이미 절반쯤 하고 있다.

| 이름 | 무엇 | 우리 |
|---|---|---|
| **화면 흔들기** | 카메라를 몇 픽셀 차고 **빨리** 잦아들게 | `_quake()`. UI도 45%로 같이 흔든다 |
| **히트스톱** | 맞는 순간 몇십 ms 시간을 멈춘다 | **안 씀** |
| **번쩍임** | 한두 프레임 흰색 | **버렸다** (§9 참고) |
| **밀림** | 맞은 쪽이 뒤로 밀렸다 돌아온다 | `STRUCK_BACK` |
| **떨림** | 밀리면서 잘게 떤다 | `shiver` 트윈 |
| **이징** | 선형으로 움직이지 않는다 | `TRANS_CUBIC` + `EASE_OUT` |

**세기를 사건에 비례시킨다.** 우리 `force = clamp(damage/10, 0.35, 1.6)`이 그거다.

**히트스톱의 함정** — Godot에서 흔한 방법은 `Engine.time_scale`을 잠깐 0 가까이 내리는
것인데, **이건 게임 전체를 멈춘다.** UI도 소리도 같이 멈춘다. 멈추지 말아야 할 것은
`process_mode`를 따로 잡아줘야 한다. (확인 안 됨)

**터뜨리는 순서가 있다.** 다 같은 프레임에 몰면 서로 가려서 아무것도 안 보인다 —
소리에서 겪은 마스킹과 같은 일이 화면에서도 일어난다.

```
0ms     멈춤(히트스톱)          ← 제일 짧고 제일 세다
그다음  번쩍 / 찢김
그다음  밀림 + 흔들림           ← 제일 길다
```

---

## 8. ★ 클로드에게 이펙트를 시키는 법

**내가 잘하는 것과 못하는 것이 갈린다.** 이 절이 이 문서에서 제일 실용적이다.

| | |
|---|---|
| **잘한다** | 셰이더를 처음부터 짜는 것. GLSL 문법과 공식은 안다 |
| **잘한다** | 층을 고르는 것(§1). 셰이더냐 `_draw()`냐 파티클이냐 |
| **잘한다** | 남의 셰이더를 읽고 우리 것으로 옮기는 것 |
| **못한다** | **값을 맞추는 것.** 0.42가 맞는지 0.38이 맞는지 나는 모른다 |
| **못한다** | **화면을 보는 것.** 실행 중인 게임 창이 나에게는 안 보인다 |

### 이 둘을 메우는 도구가 이미 있다

```bash
Godot --path . scenes/Encounter.tscn -- --tune    # 슬라이더. F5로 tools/_tune.txt에 저장
Godot --path . scenes/Encounter.tscn -- --shot    # 화면을 PNG로 찍는다
Godot --path . scenes/Encounter.tscn -- --hit     # 때린 순간을 찍는다
```

**찍은 PNG는 내가 읽을 수 있다.** 이게 결정적이다 — "안 보인다"는 말을 코드를 노려봐서
푸는 게 아니라 **찍어서 가르면** 한 번에 끝난다.

### 시킬 때의 요령

- **한 판에 하나만 고치게 할 것.** 셋을 같이 고치면 뭐가 먹혔는지 아무도 모른다
- **유니폼으로 빼게 할 것.** 상수로 박아두면 그때부터 나한테 물어봐야 한다
- **주석에 "왜"를 적게 할 것.** 다음 세션의 나는 오늘의 나와 남남이다
- **셰이더는 문법 검사가 안 된다.** `.gd`는 `--check-only`로 잡히지만 `.gdshader`는 **띄워봐야**
  안다. 오류는 STDERR로 나오므로 반드시 같이 받을 것

---

## 9. 우리 경험

**여기 있는 것은 확인된 사실이 아니라 우리가 겪은 일이다.** 위 절과 충돌하면 위가 맞다.

### 셰이더에서 데인 것 (2026-08-18)

1. **★ `fragment()`에서 `COLOR`에 덮어쓰면 `modulate`가 사라진다.** 정점에서 `varying`으로
   받아 곱해야 한다 → §2에 문서 근거가 있다
2. **★ 프래그먼트의 `COLOR`에는 이미 텍스처가 곱해져 있다.** 다시 곱하면 두 번 어두워진다
3. **★ 유니폼이 있는지 묻지 말 것.** 한 번도 안 넣은 유니폼은 `get_shader_parameter()`가
   `null`을 주고 `has_parameter()`도 거짓을 준다. **그냥 `set_shader_parameter`를 부르면 된다**

이 셋 때문에 흰 섬광 하나에 하루를 태웠다. **원인을 세 번 잘못 짚는 동안 회원님은 계속
"안 보인다"고 말하고 있었다.** 화면을 찍어 갈랐으면 첫 판에 끝났다.

### 그 밖에 겪은 것

- **`modulate`로는 흰 섬광을 못 만든다.** 곱하기라서 어두운 그림은 아무리 곱해도 안 밝아진다.
  더하기(`blend_add`)나 셰이더 안에서 `mix(rgb, white, f)`여야 한다
- **시간을 좌표에 더하면 무늬가 흘러간다.** 자글거리게 하려고 `hash(cell + TIME)`을 썼더니
  연기가 위로 올라가는 것처럼 보였다. **자리는 그대로 두고 난수만 다시 뽑아야** 제자리에서
  자글거린다 — 황금비(0.61803399)를 더해 `fract`로 자르는 방법이 이걸 한다
- **스프라이트는 제 그림 밖으로 못 나간다.** 가장자리를 밖으로 뿌리려고 투명 여백을 둘렀더니,
  뿌린 것이 여백 안에서 다 말라 아무것도 안 보였다. **밖으로 못 나가면 안쪽 끝을 흩는다**
- **여백은 크기도 망친다.** 여백을 두르면 같은 높이로 놓았을 때 주제가 작아진다
- **정수 픽셀에 안 놓으면 도트가 아니게 된다** — `_draw()`도, 셰이더의 밀림도, 노드 위치도
- **흰색으로 덮는 피격 연출은 이 게임에 안 맞았다.** 화면이 통째로 어두운 게임이라 흰 덩어리가
  이질적으로 튄다. **찢어서 흩는 쪽**(`EdgeBleed`의 `hold`를 잠깐 줄이는 것)으로 갈아탔다

### 창을 띄우는 것 (다시 겪지 말 것)

**★ Bash로 백그라운드에 띄운 Godot은 명령이 끝나면 같이 죽는다.** 회원님이 여러 번
"바뀐 게 없다"고 하신 것이 전부 이것 때문이었다 — 옛 창을 보고 계셨다.

```powershell
Start-Process "C:\...\Godot_v4.7.1-stable_win64.exe" -ArgumentList "--path",".","scenes/Encounter.tscn"
(Get-Process -Name "Godot*").Count    # ← 반드시 세어서 확인한다
```

---

## 10. 더 읽을 것

- [Godot — canvas_item 셰이더 레퍼런스](https://docs.godotengine.org/en/stable/tutorials/shaders/shader_reference/canvas_item_shader.html) — 내장 변수 전부
- [Godot — 화면을 읽는 셰이더](https://docs.godotengine.org/en/stable/tutorials/shaders/screen-reading_shaders.html)
- [Godot — 2D 커스텀 드로잉](https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html)
- [Godot — 2D 파티클](https://docs.godotengine.org/en/stable/tutorials/2d/particle_systems_2d.html) · [ParticleProcessMaterial 2D](https://docs.godotengine.org/en/stable/tutorials/2d/particle_process_material_2d.html)
- [Godot — 2D 조명과 그림자](https://docs.godotengine.org/en/stable/tutorials/2d/2d_lights_and_shadows.html)
- [Godot — Tween](https://docs.godotengine.org/en/stable/classes/class_tween.html) · [NoiseTexture2D](https://docs.godotengine.org/en/stable/classes/class_noisetexture2d.html)
- **[The Book of Shaders — 도형](https://thebookofshaders.com/07/)** — **텍스처 없이 도형을
  만드는 법**을 처음부터 가르친다. 우리에게 제일 부족한 부분이다
- [Inigo Quilez — 거리 함수 모음](https://iquilezles.org/articles/distfunctions/) — SDF 공식의 원전
- [Ronja — 2D SDF 기초](https://www.ronja-tutorials.com/post/034-2d-sdf-basics/) — 더 쉬운 입구
- [godotshaders.com](https://godotshaders.com/) — 남이 짠 것을 그대로 가져다 쓸 수 있다.
  [픽셀 디졸브](https://godotshaders.com/shader/pixelated-dissolve-with-block-size/) ·
  [2D 외곽선](https://godotshaders.com/shader/efficient-2d-pixel-outlines/) ·
  [팔레트 감축 + 오더드 디더](https://godotshaders.com/shader/arbitrary-color-reduction-ordered-dithering/)
- [게임에 즙 짜 넣기](https://www.gamedeveloper.com/design/squeezing-more-juice-out-of-your-game-design-) — 손맛의 고전 글
- `SOUND.md` — 소리 쪽. **마스킹 이야기는 화면에도 그대로 통한다**
