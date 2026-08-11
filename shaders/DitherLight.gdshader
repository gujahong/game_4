// 빛(등불 불빛, 메뉴의 빛줄기)을 도트로 흩뿌린다.
//
// 배경과 적은 DitherFilter를 통과해 전부 도트로 흩어져 있는데 빛만 매끈한 그라디언트면 혼자
// 겉돈다. 그래서 **같은 8x8 오더드 디더**를 빛의 투명도에도 씌운다 - 부드럽게 사라지는 대신
// 점이 성기게 흩어지면서 사라진다.
//
// DitherFilter와 달리 색은 안 건드린다. 빛은 이 게임에서 색을 가진 유일한 것이라 탈색하면 안 된다.
shader_type canvas_item;
render_mode blend_add;

// 빛의 세기를 몇 단으로 끊을지. 적을수록 도트가 굵고 거칠다.
uniform int levels : hint_range(2, 12) = 5;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;

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
	// 텍스처가 있으면 그 알파를, 없으면(draw_polygon 등) 흰 텍스처라 꼭짓점 색이 그대로 온다.
	vec4 src = texture(TEXTURE, UV) * COLOR;

	// 화면 픽셀 격자에 디더를 고정한다. 내부 해상도가 640x360이라 여기가 곧 도트 하나다.
	ivec2 px = ivec2(FRAGCOORD.xy);
	float bias = (BAYER8[(px.y & 7) * 8 + (px.x & 7)] + 0.5) / 64.0 - 0.5;

	float steps = float(levels - 1);
	float a = clamp(floor((src.a + bias * dither_strength / steps) * steps + 0.5) / steps, 0.0, 1.0);

	COLOR = vec4(src.rgb, a);
}
