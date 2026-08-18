// 그림의 **가장자리를 스프레이처럼 바깥으로 흩뿌린다.**
//
// 배경째 뽑힌 일러스트를 그냥 놓으면 화면에 정사각형 판 하나가 떠 있는 꼴이 된다. 배경은
// 그 자체로 서고라서 지우기 아깝고, 안쪽을 깎으면 그림이 먹힌다. 그래서 **테두리를 바깥으로
// 뿌린다** - 끝 색을 여백 쪽으로 끌어내되, 규칙적인 격자가 아니라 **칸마다 다른 난수**로
// 점을 떨어뜨린다. 그러면 줄무늬가 안 생기고 스프레이로 뿌린 자국이 된다.
//
// 쓰려면 그림에 투명 여백이 둘러져 있어야 한다(`tools/_pad.gd`). 여백이 없으면 뿌릴 자리가
// 없다 - 스프라이트는 제 그림 밖으로 한 점도 못 그린다.
shader_type canvas_item;

// 원본이 차지하는 비율. 704 안에 512면 0.727이다.
uniform float inner : hint_range(0.1, 1.0) = 0.727;
// 뿌려 나가는 길이(원본 반폭에 대한 비율).
uniform float reach : hint_range(0.0, 1.0) = 0.35;
// 점 하나의 크기(화면 픽셀). 게임의 도트와 결이 맞아야 한다.
uniform float grain : hint_range(1.0, 16.0) = 2.0;
// 점이 옆으로 튀는 폭(점 크기의 배수). 0이면 곧게 나가고, 키우면 흩어진다.
uniform float scatter : hint_range(0.0, 6.0) = 2.2;

// 칸 번호로 뽑는 난수. 같은 칸은 늘 같은 값이라 화면이 지글거리지 않는다.
float hash(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// 여백을 뺀 원본 좌표. 0~1 안이면 그림, 밖이면 뿌려지는 자리다.
	vec2 at = (UV - vec2(0.5)) / inner + vec2(0.5);
	bool inside = at.x >= 0.0 && at.x <= 1.0 && at.y >= 0.0 && at.y <= 1.0;

	if (inside) {
		COLOR = texture(TEXTURE, at);
	} else {
		vec2 cell = floor(FRAGCOORD.xy / grain);

		// **점마다 조금씩 딴 데서 물어 온다.** 곧게 끌어내면 색이 죽 늘어난 자국이 되는데,
		// 흩어서 물어 와야 종이가 부스러져 날린 것처럼 보인다.
		vec2 jitter = (vec2(hash(cell), hash(cell + 17.3)) - vec2(0.5))
			* scatter * grain * TEXTURE_PIXEL_SIZE / inner;
		vec2 edge = clamp(at + jitter, vec2(0.0), vec2(1.0));
		vec4 spray = texture(TEXTURE, edge);

		// 멀수록 성기게. 제곱이라 끝에서 급하게 마른다.
		float away = length(at - clamp(at, vec2(0.0), vec2(1.0))) / max(reach, 0.001);
		float left = 1.0 - clamp(away, 0.0, 1.0);
		left = left * left;

		// **난수로 떨어뜨린다.** 정렬된 격자로 자르면 줄이 보이고, 난수라야 뿌린 자국이 된다.
		if (hash(cell + 91.7) > left) {
			discard;
		}
		COLOR = spray;
	}
}
