// 그림의 **가장자리 띠를 스프레이처럼 흩는다.**
//
// 배경째 뽑힌 일러스트를 그냥 놓으면 화면에 정사각형 판 하나가 떠 있는 꼴이 된다. 배경은
// 그 자체로 서고라서 지우기 아깝다. 그래서 **테두리 띠만 점으로 흩어** 어둠에 묻는다.
//
// 여백을 둘러서 밖으로 뿌려도 봤는데 안 됐다 - 스프라이트는 제 그림 안에서만 그리므로
// 여백은 결국 잘리고, 뿌린 것이 여백 안에서 다 말라 아무것도 안 보인다.
// **밖으로 나갈 수 없으면 안쪽 끝을 흩는 수밖에 없다.**
//
// 점을 규칙적인 격자로 자르면 줄무늬가 보이므로 **칸마다 다른 난수**로 떨어뜨린다.
shader_type canvas_item;

// 여기까지는 그대로 두고, 그 바깥부터 흩기 시작한다(그림 반폭에 대한 비율. 0.5가 끝).
uniform float hold : hint_range(0.0, 0.5) = 0.465;
// 점 하나의 크기(화면 픽셀). 게임의 도트와 결이 맞아야 한다.
uniform float grain : hint_range(1.0, 16.0) = 4.0;
// 점이 옆에서 물어오는 폭(점 크기의 배수). 키우면 색이 튀어 흩날린 것처럼 보인다.
uniform float scatter : hint_range(0.0, 8.0) = 0.0;
// 자글거리는 빠르기(초당 몇 번 바뀌는가). **매 프레임 바꾸면 지글거려서 눈이 아프다** -
// 도트 게임의 애니메이션처럼 초당 열몇 번으로 끊어야 자글자글로 읽힌다.
uniform float shimmer : hint_range(0.0, 30.0) = 12.0;
// 맞았을 때 흰빛으로 섞이는 정도. **`modulate`로는 못 한다** - 그건 곱하기라 어두운 그림을
// 밝게 만들지 못하고 어둠을 걷어낼 뿐이다. 흰색 쪽으로 끌어당겨야 하얗게 튄다.
uniform float flash : hint_range(0.0, 1.0) = 0.0;
// 바깥으로 밀리는 폭. **가까운 변 쪽으로만 민다** - 위쪽 띠는 위로, 아래는 아래로.
// 그림 밖으로는 못 나가므로, 안쪽 색을 끌어와서 밀려 나간 것처럼 보이게 한다.
uniform float spread : hint_range(0.0, 0.3) = 0.07;

float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

// **밝기는 정점에서 받아 온다.** 조각 단계의 `COLOR`는 이미 텍스처 색이 곱해진 값이라,
// 거기에 또 곱하면 그림이 제 색으로 두 번 어두워진다. 정점의 `COLOR`가 곧 modulate다.
varying vec4 tint;

void vertex() {
	tint = COLOR;
}

void fragment() {
	// 네모의 가장자리까지의 거리. 가로세로 중 가까운 쪽이 정한다 - 원으로 깎으면 네 귀퉁이만
	// 잘려서 여전히 판으로 보인다.
	vec2 away = abs(UV - vec2(0.5));
	float edge = max(away.x, away.y);

	// 안쪽은 1, 가장자리로 갈수록 0. 이 값이 곧 점이 남을 확률이다.
	float keep = 1.0 - smoothstep(hold, 0.5, edge);

	vec2 cell = floor(FRAGCOORD.xy / grain);
	// **옆에서 조금씩 물어 온다.** 제자리 색만 쓰면 그냥 구멍이 뚫린 것이고, 흩어서 물어 와야
	// 종이 부스러기가 날린 것처럼 보인다.
	vec2 jitter = (vec2(hash(cell), hash(cell + 17.3)) - vec2(0.5))
		* scatter * grain * TEXTURE_PIXEL_SIZE;
	// **가까운 변 쪽이 바깥이다.** 네 변 중 어디에 붙었는지로 방향을 정한다.
	vec2 out_dir = vec2(0.0);
	if (away.x > away.y) {
		out_dir.x = sign(UV.x - 0.5);
	} else {
		out_dir.y = sign(UV.y - 0.5);
	}
	// 바깥으로 갈수록 안쪽 색을 더 멀리서 끌어온다 = 그림이 그쪽으로 밀려 나간다.
	vec2 pulled = UV - out_dir * (1.0 - keep) * spread;
	vec4 here = texture(TEXTURE, clamp(pulled + jitter, vec2(0.0), vec2(1.0)));

	// 시간을 칸 번호에 섞는다. 끊어 놓은 시간이라 점들이 초당 `shimmer`번 새로 뽑힌다.
	float beat = floor(TIME * shimmer);
	// **시간을 칸 번호에 더하면 안 된다.** 그러면 무늬가 매번 한 칸씩 밀려서 연기가 위로
	// 흐르는 것처럼 보인다. 자리는 그대로 두고 **뽑는 값만 다시 굴린다** - 황금비만큼
	// 더하면 앞뒤 값이 안 닮아서 매번 새로 뽑은 것이 된다.
	float roll = fract(hash(cell + vec2(91.7, 41.3)) + beat * 0.61803399);
	if (keep < roll) {
		discard;
	}
	vec4 lit = here * tint;
	COLOR = vec4(mix(lit.rgb, vec3(1.0), flash), lit.a);
}
