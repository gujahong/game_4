// 관문에서 세계가 새어 나오는 것처럼 보이게 한다. 늘려 붙인 왼쪽 안개에 건다.
//
// `PortalWave`와 다른 점이 둘이다.
//
// 1. **방향이 있다.** 물결이 이음새에서 바깥쪽으로 진행한다. 제자리에서 떠는 것과 흘러나오는
//    것은 눈에 전혀 다르게 읽힌다 - 진행 방향이 있어야 "새어 나온다"가 된다.
// 2. **멀수록 커진다.** 문 바로 옆은 거의 멎어 있고, 멀어질수록 흔들림도 세로로 늘어나는 양도
//    커진다. 치즈가 늘어지듯 끝으로 갈수록 형태가 무너진다.
//
// 세로로 늘리는 것(`stretch`)이 "주욱 흘러나옴"의 핵심이다. 위아래로 밀기만 하면 굼실거릴 뿐
// 늘어나 보이지 않는다.
//
// 도트가 뭉개질 걱정은 없다 - 프로젝트 기본 텍스처 필터가 Nearest라 어떤 좌표로 읽어도
// 원본 도트 하나가 통째로 나온다.
shader_type canvas_item;

// 물결이 흘러나오는 자리(가로 비율). 여기가 0이고 왼쪽 끝으로 갈수록 1이 된다.
// 이음새보다 조금 오른쪽에 두면 원본 그림 쪽으로도 살짝 넘어가 늘어난다.
uniform float source_x : hint_range(0.0, 1.0) = 0.674;

// 가장 먼 끝에서의 위아래 흔들림(픽셀). 이음새에서는 0이다.
uniform float amplitude : hint_range(0.0, 64.0) = 12.0;
// 나오는 자리에서의 물결 길이(픽셀). 흘러가면서 이보다 길어진다.
uniform float wavelength : hint_range(8.0, 1024.0) = 140.0;
// 흘러나오는 속도.
uniform float speed : hint_range(0.0, 4.0) = 0.6;

// 끝으로 갈수록 물결이 길어지는 정도. 4면 왼쪽 끝의 물결이 5배 길다.
//
// **이것이 "끝으로 갈수록 빨리 흐른다"를 만드는 장치다.** 시간 주파수는 어디서나 같으니,
// 물결이 길어진 만큼 마루가 그 배로 빨리 지나간다. 속도값 자체를 위치마다 다르게 주면
// 되지 않는다 - 그러면 시간이 갈수록 위상차가 무한정 벌어져서 무늬가 점점 잘게 부서진다.
//
// 흘러가며 늘어나는 물결이라 보기에도 맞는다. 문 옆에서 잘게 일다가 멀어질수록 길게 늘어진다.
uniform float flow_gain : hint_range(0.0, 12.0) = 4.0;

// 가장 먼 끝에서 세로로 늘어나는 비율. 1.2면 2.2배로 늘어난다.
uniform float stretch : hint_range(0.0, 4.0) = 1.2;

// 끝에서 몰아치는 정도. 클수록 마지막에 급하게 터진다.
uniform float falloff : hint_range(0.5, 8.0) = 4.0;
// 곧은 경사를 얼마나 섞을지. 0이면 곧게만 늘고, 1이면 `falloff`대로 끝에서만 몰아친다.
//
// **끝에서만 몰아치게 두면 늘어지기 시작하는 자리가 갑자기로 읽힌다.** 문 근처에서 아무 일도
// 안 일어나다가 어느 지점부터 움직이니 거기에 선이 보이는 것이다. 곧은 경사를 조금 섞어
// 처음부터 미세하게 늘어나게 해두면, 시작하는 자리가 사라지고 끝의 폭발만 남는다.
uniform float surge : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	vec2 texel = TEXTURE_PIXEL_SIZE;

	// 이음새에서 얼마나 멀어졌나. 0 = 관문 바로 옆, 1 = 왼쪽 끝.
	float away = clamp((source_x - UV.x) / max(source_x, 0.001), 0.0, 1.0);
	float grow = mix(away, pow(away, falloff), surge);

	// 물결이 흘러온 거리. 파장이 가면서 길어지므로 그냥 거리가 아니라 **파장 몇 개분을
	// 지나왔는지**를 세야 한다. 파장이 거리에 비례해 늘어나니 그 합이 로그가 된다.
	float span = source_x / texel.x;  // 이음새에서 왼쪽 끝까지의 픽셀 수
	float travelled = flow_gain > 0.001
		? span * log(1.0 + flow_gain * away) / flow_gain
		: span * away;

	// 시간을 빼야 마루가 멀어지는 방향으로 간다.
	float phase = travelled / wavelength * 6.28318 - TIME * speed;
	float shift = sin(phase) * amplitude * grow * texel.y;

	// 세로로 늘린다. 읽는 범위를 좁히면 그만큼 늘어나 보인다.
	float scale = 1.0 + stretch * grow;
	float y = (UV.y - 0.5) / scale + 0.5;

	COLOR = texture(TEXTURE, vec2(UV.x, y + shift));
}
