// 화면 전체를 CRT 모니터처럼 보이게 하는 후처리. 볼록렌즈 왜곡 + 가로 주사선 + 가장자리 어둡게.
//
// 화면에 이미 그려진 것을 다시 읽어서(screen_texture) 비틀기 때문에, 다른 모든 것보다 위에
// 있어야 한다(`CrtOverlay`가 layer 200에 놓는다).
//
// filter_nearest인 이유: 우리 화면은 640x360이고 도트가 살아 있어야 한다. 부드럽게 읽으면
// 왜곡된 자리에서 도트가 뭉개져 화풍이 무너진다. 거칠게 읽으면 가장자리가 계단처럼 울렁이는데,
// 그게 오히려 진짜 CRT에 가깝다.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// 클수록 평평하다. 작을수록 렌즈가 볼록해진다.
uniform float curvature : hint_range(1.0, 16.0) = 6.0;
// 가로 주사선의 진하기.
uniform float scanline : hint_range(0.0, 1.0) = 0.22;
// 주사선 간격(픽셀). 2면 한 줄 걸러 하나.
uniform float scanline_step : hint_range(1.0, 6.0) = 2.0;
// 가장자리를 얼마나 어둡게 할지. 0이면 안 어둡게.
uniform float vignette : hint_range(0.0, 2.0) = 0.35;

vec2 curve(vec2 uv, float amount) {
	uv = uv * 2.0 - 1.0;
	vec2 bulge = abs(uv.yx) / amount;
	uv += uv * bulge * bulge;
	return uv * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = curve(SCREEN_UV, curvature);

	// 렌즈 밖으로 밀려난 자리는 화면이 없는 곳이다.
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 c = texture(screen_texture, uv).rgb;

		float row = floor(uv.y / SCREEN_PIXEL_SIZE.y);
		c *= 1.0 - scanline * step(1.0, mod(row, scanline_step));

		vec2 edge = uv * (1.0 - uv.yx);
		c *= clamp(pow(edge.x * edge.y * 24.0, vignette), 0.0, 1.0);

		COLOR = vec4(c, 1.0);
	}
}
