extends RichTextLabel
class_name EmberText

## 글이 **한 단어씩 불붙듯** 떠오르는 글판.
##
## 오프닝에서 경구가 떠오르는 그 연출을 떼어 낸 것이다(`Opening.gd`). 한 줄이 통째로 툭
## 나타나면 시스템이 알려주는 것이 되고, 한 단어씩 번지면 **누가 읽어 주는 것**이 된다.
##
## 단어가 떠오르는 시간(`WORD_FADE`)이 단어 사이 간격(`WORD_STEP`)보다 길어야 한다 - 그래야
## 하나씩 딱딱 켜지지 않고 앞 단어가 아직 밝아지는 중에 다음이 붙어서 이어 번진다.

const WORD_FADE := 0.5
const WORD_STEP := 0.11

## 갓 떠오른 글자의 색과 다 떠오른 뒤의 색. 등불 색에서 시작해 뼈색으로 가라앉는다.
const EMBER := Color(1.0, 0.60, 0.25)
const BONE := Color(0.86, 0.84, 0.79)

var _words: PackedStringArray = PackedStringArray()
var _gaps: PackedStringArray = PackedStringArray()
var _time := 0.0


func _init() -> void:
	bbcode_enabled = true
	fit_content = true
	autowrap_mode = TextServer.AUTOWRAP_OFF
	scroll_active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


## 새 글을 처음부터 떠오르게 한다. 앞의 글은 지운다 - 기록을 쌓는 판이 아니라 지금 벌어진
## 일을 말해 주는 판이다.
## 다 떠오르는 데 걸리는 시간을 돌려준다. **긴 문장은 오래 걸린다** - 읽을 시간을 정하는 쪽이
## 이걸 모르면 다 뜨기도 전에 다음 줄로 갈아치운다.
func say(line: String) -> float:
	_split(line)
	_time = 0.0
	_paint()
	set_process(true)
	return reveal_time()


func reveal_time() -> float:
	return WORD_STEP * float(_words.size()) + WORD_FADE


func _process(delta: float) -> void:
	_time += delta
	_paint()
	if _time >= reveal_time():
		set_process(false)   # 다 떠오른 뒤에는 매 프레임 다시 지을 것이 없다


## 글을 단어와 그 뒤의 여백으로 갈라둔다. 단어마다 색을 따로 입히려면 이렇게 나눠야 하고,
## 여백을 같이 들고 있어야 다시 이어 붙일 때 줄바꿈이 살아난다.
func _split(line: String) -> void:
	_words = PackedStringArray()
	_gaps = PackedStringArray()
	var word := ""
	var gap := ""
	for i in line.length():
		var letter: String = line[i]
		if letter == " " or letter == "\n":
			gap += letter
			continue
		if not gap.is_empty():
			_words.append(word)
			_gaps.append(gap)
			word = ""
			gap = ""
		word += letter
	if not word.is_empty():
		_words.append(word)
		_gaps.append("")


## 단어마다 진하기를 달리한 BBCode를 짓는다.
func _paint() -> void:
	var out := "[center]"
	for i in _words.size():
		var rising: float = clampf((_time - float(i) * WORD_STEP) / WORD_FADE, 0.0, 1.0)
		# 끝으로 갈수록 느려지게 해야 불이 붙듯 스르르 떠오른다.
		var lit: float = rising * rising * (3.0 - 2.0 * rising)
		var colour: Color = EMBER.lerp(BONE, lit)
		colour.a = lit
		out += "[color=#%s]%s[/color]%s" % [colour.to_html(true), _words[i], _gaps[i]]
	text = out + "[/center]"
