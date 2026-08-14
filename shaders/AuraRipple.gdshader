// 둥근 것의 가장자리에서 기운이 **바깥으로 퍼져 나가게** 한다.
//
// `PortalWave`는 세로로만 미는 물건이라 원형에는 안 맞았다. 여기서는 가운데에서 바깥으로
// 향하는 방향으로 밀고, 그 물결이 밖으로 흘러나간다.
//
// **가운데는 멎어 있다**(`calm_radius`). 고리와 눈은 그대로 있고 바깥의 기운만 일렁여야
// 물건이 물결치는 게 아니라 거기서 뭔가 뿜어져 나오는 것으로 읽힌다.
shader_type canvas_item;

// 밀어내는 폭(픽셀). 가장자리에서 이만큼이고 안쪽으로 갈수록 줄어든다.
uniform float amplitude : hint_range(0.0, 64.0) = 14.0;
// 물결 하나의 길이(픽셀).
uniform float wavelength : hint_range(4.0, 512.0) = 80.0;
// 퍼져 나가는 속도.
uniform float speed : hint_range(0.0, 8.0) = 1.6;
// 이 반지름(그림 반폭에 대한 비율) 안쪽은 멎어 있다.
//
// **바깥 테만 흔들려야 한다.** 이 값이 작으면 고리와 눈까지 물결쳐서 물건이 통째로
// 흔들리는 것으로 보인다. 0.42면 바깥 8분의 1쯤에서만 일렁인다.
uniform float calm_radius : hint_range(0.0, 0.5) = 0.42;

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;
	vec2 away = UV - vec2(0.5);
	float r = max(length(away), 0.0001);
	vec2 out_dir = away / r;

	// 가운데는 멎고 가장자리로 갈수록 세진다.
	float grow = smoothstep(calm_radius, 0.5, r);

	// 시간을 빼야 마루가 바깥으로 나가는 방향으로 흐른다.
	float phase = (r / texel.x) / wavelength * 6.28318 - TIME * speed;
	float push = sin(phase) * amplitude * grow;

	COLOR = texture(TEXTURE, UV + out_dir * push * texel);
}
