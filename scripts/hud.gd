## Screen info: truck health and boost, distance and scrap, a phase banner, the radio box, game over and pause.
class_name Hud
extends Control

signal retry
signal resume

var _hp: ColorRect
var _boost: ColorRect
var _stats: Label
var _banner: Label
var _radio: PanelContainer
var _who: Label
var _line: Label
var _over: PanelContainer
var _over_stats: Label
var _pause: PanelContainer
var _hp_extra: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := _label(self, 28, Color(1.0, 0.75, 0.3))
	title.text = "SCRAPFALL 2: ROAD WAR"
	title.position = Vector2(24, 14)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, .55)
	bg.position = Vector2(24, 56)
	bg.size = Vector2(300, 22)
	add_child(bg)
	_hp = ColorRect.new()
	_hp.position = Vector2(27, 59)
	_hp.size = Vector2(294, 16)
	add_child(_hp)
	_boost = ColorRect.new()
	_boost.color = Color(1.0, 0.6, 0.2)
	_boost.position = Vector2(27, 84)
	_boost.size = Vector2(294, 8)
	add_child(_boost)
	_stats = _label(self, 22)
	_stats.position = Vector2(24, 96)
	_hp_extra = _label(self, 20, Color(0.6, 1, 0.6))
	_hp_extra.position = Vector2(24, 126)
	_banner = _label(self, 30, Color(0.55, 0.85, 1.0))
	_banner.anchor_right = 1.0
	_banner.offset_top = 70
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_radio = PanelContainer.new()
	_radio.add_theme_stylebox_override("panel", _box(Color(0.04, 0.06, 0.09, .82)))
	_radio.anchor_left = 0.5
	_radio.anchor_right = 0.5
	_radio.anchor_top = 1.0
	_radio.anchor_bottom = 1.0
	_radio.offset_left = -360
	_radio.offset_right = 360
	_radio.offset_top = -250
	_radio.offset_bottom = -170
	_radio.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_radio)
	var vb := VBoxContainer.new()
	_radio.add_child(vb)
	_who = _label(vb, 18)
	_line = _label(vb, 22)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD
	_over = _panel_center("TRUCK DOWN", Color(1, .35, .2), "DRIVE AGAIN", func() -> void: retry.emit())
	_over_stats = _over.get_child(0).get_child(1)
	_pause = _panel_center("PAUSED", Color(1, .75, .3), "RESUME", func() -> void: resume.emit())
	_pause.process_mode = Node.PROCESS_MODE_ALWAYS


func _label(parent: Control, fs: int, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, .8))
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _box(col: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


func _panel_center(title: String, col: Color, button: String, on_press: Callable) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(Color(0.05, 0.03, 0.03, .9)))
	p.set_anchors_preset(Control.PRESET_CENTER)
	p.offset_left = -240
	p.offset_right = 240
	p.offset_top = -130
	p.offset_bottom = 130
	p.visible = false
	add_child(p)
	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	p.add_child(v)
	var t := _label(v, 40, col)
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var s := _label(v, 22)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b := Button.new()
	b.text = button
	b.custom_minimum_size = Vector2(260, 72)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_stylebox_override("normal", _box(Color(0.12, 0.15, 0.2, .9)))
	b.add_theme_stylebox_override("pressed", _box(Color(0.85, 0.35, 0.1, .9)))
	b.add_theme_stylebox_override("hover", _box(Color(0.18, 0.22, 0.28, .9)))
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(on_press)
	v.add_child(b)
	return p


func show_state(hp: float, boost: float, dist: float, scrap: int, extra := "") -> void:
	var h := clampf(hp / TruckDrive.MAX_HP, 0.0, 1.0)
	_hp.size.x = 294.0 * h
	_hp.color = Color(0.4, 0.85, 0.35).lerp(Color(1, .25, .15), 1.0 - h)
	_boost.size.x = 294.0 * boost
	_stats.text = "%d m    scrap %d" % [int(dist), scrap]
	_hp_extra.text = extra


func banner(text: String) -> void:
	_banner.text = text


func show_radio(r: Dictionary) -> void:
	_radio.visible = r["who"] != ""
	_who.text = r["who"]
	_who.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0) if r["who"] == "MARA" else Color(1.0, 0.75, 0.3))
	_line.text = r["text"]


func game_over(dist: float, scrap: int) -> void:
	_over_stats.text = "%d m driven   %d scrap" % [int(dist), scrap]
	_over.visible = true


func set_paused(on: bool) -> void:
	_pause.visible = on
