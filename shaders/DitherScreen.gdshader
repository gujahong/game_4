// DitherFilter를 **화면 전체**에 한 번 씌우는 판. 이미 그려진 화면을 다시 읽어서 변환한다.
//
// 노드마다 필터를 붙이던 방식(FilteredSprite)은 맵처럼 노드가 많아지면 관리가 안 된다.
// 이걸 쓰면 필터가 진짜로 **하나**가 된다 - 이 판보다 아래에 그려진 것은 전부 같은 필터를 통과한다.
//
// **등불은 이 판보다 위에 놓는다.** 그래야 필터를 안 거치고 제 색을 지킨다.
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform int levels : hint_range(2, 16) = 4;
uniform float dither_strength : hint_range(0.0, 2.0) = 1.0;
uniform float desaturate : hint_range(0.0, 1.0) = 0.5;
uniform float sat_threshold : hint_range(0.0, 1.0) = 0.3;
uniform float sat_softness : hint_range(0.01, 0.5) = 0.1;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float brightness : hint_range(0.0, 1.0) = 1.0;

// 등불이 비추는 자리. 화면 비율 좌표(0~1)로 준다.
uniform vec2 light_position = vec2(0.5, 0.5);
uniform float light_radius : hint_range(0.0, 1.0) = 0.16;
uniform float light_softness : hint_range(0.01, 1.0) = 0.22;
// 빛이 안 닿는 곳의 밝기. 0이면 완전한 암흑이라 아무것도 안 보인다.
uniform float ambient : hint_range(0.0, 1.0) = 0.1;

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
	vec3 c = texture(screen_texture, SCREEN_UV).rgb;

	// 등불이 닿는 만큼만 밝다. 계조를 깎기 **전에** 곱해야 빛의 감쇠까지 디더로 흩어진다 -
	// 나중에 곱하면 빛 가장자리만 매끈해져서 혼자 겉돈다.
	vec2 offset = SCREEN_UV - light_position;
	offset.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;  // 화면 비율 보정
	float lit = 1.0 - smoothstep(light_radius, light_radius + light_softness, length(offset));
	c *= mix(ambient, 1.0, lit);

	float lum = dot(c, vec3(0.299, 0.587, 0.114));
	float hi = max(c.r, max(c.g, c.b));
	float lo = min(c.r, min(c.g, c.b));
	float sat = hi > 0.0 ? (hi - lo) / hi : 0.0;

	ivec2 px = ivec2(FRAGCOORD.xy);
	float bias = (BAYER8[(px.y & 7) * 8 + (px.x & 7)] + 0.5) / 64.0 - 0.5;

	float steps = float(levels - 1);
	float q = clamp(floor((lum + bias * dither_strength / steps) * steps + 0.5) / steps, 0.0, 1.0);

	vec3 gray = vec3(q) * tint.rgb;
	vec3 colored = lum > 0.001 ? clamp(c * (q / lum), 0.0, 1.0) : vec3(q);
	float keep = smoothstep(sat_threshold, sat_threshold + sat_softness, sat) * (1.0 - desaturate);

	COLOR = vec4(mix(gray, colored, keep) * brightness, 1.0);
}
