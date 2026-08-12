// 문 너머의 세계가 일렁이게 한다. 세로로 밀리는 양이 가로 위치마다 달라서 물결처럼 흔들린다.
//
// **밀림을 정수 픽셀로 끊는다**(`floor(... + 0.5)`). 부드럽게 밀면 도트가 반 칸씩 어긋나 뭉개지는데,
// 정수로 끊으면 도트가 통째로 한 칸씩 뛴다 - 손으로 찍은 픽셀 애니메이션이 그렇게 움직인다.
//
// 저 안은 꿈이고 여긴 아니라는 것을 움직임으로 말하는 장치이기도 하다. 관문 밖은 멎어 있다.
shader_type canvas_item;

// 위아래로 흔들리는 폭(픽셀). 크면 물결이 심해진다.
uniform float amplitude : hint_range(0.0, 16.0) = 3.0;
// 물결 하나의 길이(픽셀). 짧으면 잘게 떨고 길면 크게 굼실거린다.
uniform float wavelength : hint_range(4.0, 512.0) = 96.0;
// 흐르는 속도.
uniform float speed : hint_range(0.0, 4.0) = 0.5;
// 세로로도 위상을 어긋나게 해서 결이 사선으로 흐르게 한다. 0이면 세로줄이 통째로 같이 움직인다.
uniform float skew : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;
	vec2 px = UV / texel;  // 텍스처 안의 픽셀 좌표

	float phase = (px.x + px.y * skew) / wavelength * 6.28318 + TIME * speed;
	// 정수 픽셀로 끊는 것이 핵심이다.
	float shift = floor(sin(phase) * amplitude + 0.5);

	COLOR = texture(TEXTURE, UV + vec2(0.0, shift * texel.y));
}
