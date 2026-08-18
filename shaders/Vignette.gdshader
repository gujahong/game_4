// 화면을 덮되 한 자리만 뚫어 놓는 판. **등불이 비추는 만큼만 보인다.**
//
// 통짜 검은 판을 알파로 여닫으면 "화면이 흐려졌다 진해졌다" 할 뿐이다. 여기서는 구멍의
// 반경을 여닫으므로, 등불 쪽부터 세상이 드러나고 어둠은 바깥에서 조여든다.
shader_type canvas_item;

// 뚫린 자리(화면 비율 좌표)와 그 반경. 반경이 0이면 완전한 암전이다.
uniform vec2 light_position = vec2(0.5, 0.5);
uniform float radius : hint_range(0.0, 3.0) = 3.0;
// **가장자리가 넓어야 조리개 날이 아니라 빛의 경계가 된다.** 0.22로는 원이 또렷하게
// 보여서 기계 장치처럼 읽혔다. 넓게 잡으면 어둠이 스며드는 것으로 보인다.
uniform float softness : hint_range(0.001, 8.0) = 0.9;

// 뚫린 자리까지 덮는 정도. **구멍이 줄기만 하면 조리개처럼 보인다** - 남은 자리도 같이
// 흐려져야 어둠이 스며드는 것으로 읽힌다.
uniform float dim : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 off = SCREEN_UV - light_position;
	// 화면 비율 보정. 안 하면 구멍이 타원이 된다.
	off.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	// **번짐도 반경을 따라 줄어야 한다.** 반경만 0으로 두면 번짐의 꼬리가 남아서 그 자리에
	// 옅은 자국이 뜬다 - 완전한 암전이 안 된다. 여는 화면에서도 같은 것에 걸렸다.
	float soft = max(softness * min(radius, 1.0), 0.0005);
	float lit = 1.0 - smoothstep(radius, radius + soft, length(off));
	COLOR = vec4(0.0, 0.0, 0.0, 1.0 - lit * (1.0 - dim));
}
