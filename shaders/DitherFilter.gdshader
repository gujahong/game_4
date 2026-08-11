// 컬러 그림 위에 "흑백 필터를 낀" 것처럼 보이게 만드는 필터.
//
// 하는 일은 넷이다.
//   1. 밝기만 뽑아서 계조를 levels 단으로 깎는다 (색을 버리는 게 아니라 명암 단계를 줄인다)
//   2. 깎을 때 8x8 오더드 디더로 경계를 흩뜨린다 - 2·4번 참고그림의 그 격자가 여기서 나온다
//   3. 회색이 된 부분에 tint 색을 얹는다 (장소마다 필터 색을 다르게 줄 수 있다)
//   4. 원본에서 채도가 높았던 곳만 색을 되살린다 - 스테인드글라스, 불, 피처럼
//      "그 그림에 꼭 있어야 하는 색"은 대개 원본에서도 채도가 높다는 전제다
shader_type canvas_item;

// 명암을 몇 단으로 깎을지. 2면 완전 1비트, 클수록 부드러워진다.
uniform int levels : hint_range(2, 16) = 4;
// 디더 격자의 세기. 0이면 격자 없이 딱딱하게 끊기고, 1 근처가 참고그림 느낌.
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;
// 살아남은 색을 얼마나 더 뺄지. 0이면 원래 색 그대로, 1이면 완전 흑백.
uniform float desaturate : hint_range(0.0, 1.0) = 0.5;
// 들어온 그림의 명암 범위를 맞추는 손잡이. **그림마다 다르게 준다.**
//
// 생성기가 뽑아주는 그림은 어떤 건 뿌옇고(성당) 어떤 건 대비가 세다(피라미드). 그대로 계조만
// 깎으면 뿌연 건 뿌연 채로 도트가 되어, 같은 게임 그림으로 안 보인다. 여기서 흑점과 백점을
// 잡아 **모든 그림을 같은 명암 범위로 끌어온 뒤에** 계조를 깎는다.
//
// input_black을 올리면 어두운 쪽이 눌려 까맣게 되고, input_white를 내리면 밝은 쪽이 날아간다.
uniform float input_black : hint_range(0.0, 1.0) = 0.0;
uniform float input_white : hint_range(0.0, 1.0) = 1.0;

// 이 채도를 넘는 곳만 색이 살아남는다. 높일수록 색이 남는 곳이 줄어든다.
uniform float sat_threshold : hint_range(0.0, 1.0) = 0.3;
// 색이 남는 곳과 안 남는 곳의 경계를 얼마나 부드럽게 이을지.
uniform float sat_softness : hint_range(0.01, 0.5) = 0.1;
// 회색 부분에 얹을 색.
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 이 층 전체를 누르는 값. 따로 뽑아 얹은 물건은 배경과 명암이 안 맞아 오려 붙인 티가 나는데,
// 이걸로 눌러서 맞춘다. 멀리 있는 층일수록 더 눌러주면 공기원근도 흉내낼 수 있다.
//
// 노드의 modulate를 쓰지 않는 이유: 아래에서 COLOR를 통째로 덮어쓰기 때문에 modulate가
// 조용히 버려진다. 아무 일도 안 일어나서 알아채기 어렵다.
uniform vec4 layer_modulate : source_color = vec4(1.0, 1.0, 1.0, 1.0);

const float BAYER8[64] = float[64](
	 0.0, 32.0,  8.0, 40.0,  2.0, 34.0, 10.0, 42.0,
	48.0, 16.0, 56.0, 24.0, 50.0, 18.0, 58.0, 26.0,
	12.0, 44.0,  4.0, 36.0, 14.0, 46.0,  6.0, 38.0,
	60.0, 28.0, 52.0, 20.0, 62.0, 30.0, 54.0, 22.0,
	 3.0, 35.0, 11.0, 43.0,  1.0, 33.0,  9.0, 41.0,
	51.0, 19.0, 59.0, 27.0, 49.0, 17.0, 57.0, 25.0,
	15.0, 47.0,  7.0, 39.0, 13.0, 45.0,  5.0, 37.0,
	63.0, 31.0, 55.0, 23.0, 61.0, 29.0, 53.0, 21.0
);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	vec3 c = src.rgb;

	float lum = dot(c, vec3(0.299, 0.587, 0.114));

	float hi = max(c.r, max(c.g, c.b));
	float lo = min(c.r, min(c.g, c.b));
	float sat = hi > 0.0 ? (hi - lo) / hi : 0.0;

	// 화면이 아니라 그림의 픽셀 격자에 디더를 고정한다. 확대해도 격자가 안 흐트러진다.
	ivec2 px = ivec2(UV / TEXTURE_PIXEL_SIZE);
	int idx = (px.y & 7) * 8 + (px.x & 7);
	float bias = (BAYER8[idx] + 0.5) / 64.0 - 0.5;

	float steps = float(levels - 1);
	float q = clamp(floor((lum + bias * dither_strength / steps) * steps + 0.5) / steps, 0.0, 1.0);

	vec3 gray = vec3(q) * tint.rgb;
	// 깎인 밝기는 그대로 쓰면서 원본의 색기만 다시 입힌다.
	vec3 colored = lum > 0.001 ? clamp(c * (q / lum), 0.0, 1.0) : vec3(q);

	float keep = smoothstep(sat_threshold, sat_threshold + sat_softness, sat) * (1.0 - desaturate);

	COLOR = vec4(mix(gray, colored, keep) * layer_modulate.rgb, src.a * layer_modulate.a);
}
