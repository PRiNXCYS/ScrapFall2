## Phone controls drawn in one Control: it tracks every finger itself so two thumbs work at once.
## Modes: "drive" (halves steer, BOOST, CAM, STOP), "foot" (stick, drag to look, FIRE, DRIVE), "camp" (tap to place, GUN, WALL, START).
class_name TouchControls
extends Control

signal pressed(button: String)
signal tapped(at: Vector2)  # a tap on empty screen (camp placement)

var mode := "drive"
var show_stop := false
var show_board := false
var show_start := true
var camp_kind := "gun"
var _touches := {}  # index -> {"pos": Vector2, "start": Vector2, "on": String}
var _look := Vector2.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Button rectangles for a screen size. Every button is at least 64 px tall and inside the screen.
func layout(sz: Vector2) -> Dictionary:
	var h := maxf(64.0, sz.y * 0.12)
	var w := h * 2.1
	var m := maxf(16.0, sz.y * 0.03)
	var r := {}
	match mode:
		"drive":
			r["boost"] = Rect2(sz.x - w - m, sz.y - h - m, w, h)
			r["cam"] = Rect2(sz.x - w * 0.7 - m, m, w * 0.7, h)
			if show_stop:
				r["stop"] = Rect2(sz.x - w - m, sz.y - 2 * h - 2 * m, w, h)
		"foot":
			r["fire"] = Rect2(sz.x - w - m, sz.y - h * 1.3 - m, w, h * 1.3)
			r["stick"] = Rect2(m, sz.y - h * 2.6 - m, h * 2.6, h * 2.6)
			if show_board:
				r["board"] = Rect2(sz.x - w - m, sz.y - h * 2.3 - 2 * m, w, h)
		"camp":
			r["gun"] = Rect2(sz.x / 2 - w - m / 2, sz.y - h - m, w, h)
			r["wall"] = Rect2(sz.x / 2 + m / 2, sz.y - h - m, w, h)
			if show_start:
				r["start"] = Rect2(sz.x - w * 1.2 - m, m, w * 1.2, h)
	return r


func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch or ev is InputEventScreenDrag:
		if handle(ev):
			get_viewport().set_input_as_handled()


## Feed one touch event (tests call this directly). Returns true when a control used it.
func handle(ev: InputEvent) -> bool:
	var r := layout(size)
	if ev is InputEventScreenTouch:
		if ev.pressed:
			var on := ""
			for k in r:
				if r[k].has_point(ev.position):
					on = k
			_touches[ev.index] = {"pos": ev.position, "start": ev.position, "on": on}
			if on != "" and on != "stick":
				if on == "gun" or on == "wall":
					camp_kind = on
				pressed.emit(on)
			queue_redraw()
			return true
		var t = _touches.get(ev.index)
		_touches.erase(ev.index)
		if t != null and t["on"] == "" and mode == "camp" and t["start"].distance_to(ev.position) < 24.0:
			tapped.emit(ev.position)
		queue_redraw()
		return true
	if ev is InputEventScreenDrag and _touches.has(ev.index):
		var t: Dictionary = _touches[ev.index]
		if mode == "foot" and t["on"] == "" and t["start"].x > size.x * 0.4:
			_look += ev.relative
		t["pos"] = ev.position
		queue_redraw()
		return true
	return false


## -1..1, positive = left. Drive mode: a thumb held on the left/right half (not on a button).
func steer() -> float:
	if mode != "drive":
		return 0.0
	var s := 0.0
	for t in _touches.values():
		if t["on"] == "":
			s += 1.0 if t["pos"].x < size.x / 2 else -1.0
	return clampf(s, -1.0, 1.0)


func boost_held() -> bool:
	return _held("boost")


func fire_held() -> bool:
	return _held("fire")


## Foot mode: the virtual stick as x (right +) / y (forward +).
func stick() -> Vector2:
	for t in _touches.values():
		if t["on"] == "stick":
			var r: Rect2 = layout(size)["stick"]
			var v: Vector2 = (t["pos"] - r.get_center()) / (r.size.x * 0.4)
			return Vector2(v.x, -v.y).limit_length(1.0)
	return Vector2.ZERO


## Foot mode: look drag since the last call.
func take_look() -> Vector2:
	var l := _look
	_look = Vector2.ZERO
	return l


func _held(name: String) -> bool:
	for t in _touches.values():
		if t["on"] == name:
			return true
	return false


func _draw() -> void:
	var r := layout(size)
	var font := get_theme_default_font()
	var labels := {"boost": "BOOST", "cam": "CAM", "stop": "STOP", "fire": "FIRE", "stick": "", "board": "DRIVE",
		"gun": "GUN 10", "wall": "WALL 3", "start": "START NIGHT"}
	for k in r:
		var rect: Rect2 = r[k]
		var down: bool = _held(k) or (mode == "camp" and k == camp_kind)
		if k == "stick":
			draw_circle(rect.get_center(), rect.size.x / 2, Color(0, 0, 0, 0.25))
			draw_circle(rect.get_center() + stick() * Vector2(1, -1) * rect.size.x * 0.4, rect.size.x * 0.18, Color(1, 1, 1, 0.35))
			continue
		draw_rect(rect, Color(0.85, 0.35, 0.1, 0.9) if down else Color(0.06, 0.08, 0.11, 0.7))
		draw_rect(rect, Color(1, 0.75, 0.3, 0.8), false, 2.0)
		var fs := int(rect.size.y * 0.32)
		var tw := font.get_string_size(labels[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, rect.position + Vector2((rect.size.x - tw) / 2, rect.size.y / 2 + fs * 0.35), labels[k], HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
