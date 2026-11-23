## Radio lines: a queue, typed out at 45 characters a second, each shown 1.6 s + 0.05 s per character.
class_name Radio
extends RefCounted

const CHARS_PER_SEC := 45.0

var _queue: Array = []
var _who := ""
var _text := ""
var _t := 0.0
var _left := 0.0


func say(who: String, text: String) -> void:
	_queue.append([who, text])


## Advances time; returns {"who", "text" (typed so far), "full", "new" (true on the frame a line starts)}.
func step(dt: float) -> Dictionary:
	var started := false
	_left -= dt
	_t += dt
	if _left <= 0.0:
		if _queue.is_empty():
			_who = ""
			_text = ""
		else:
			var r: Array = _queue.pop_front()
			_who = r[0]
			_text = r[1]
			_t = dt
			_left = 1.6 + _text.length() * 0.05
			started = true
	var shown := _text.substr(0, mini(_text.length(), ceili(_t * CHARS_PER_SEC)))
	return {"who": _who, "text": shown, "full": _text, "new": started}


static func voice_path(text: String) -> String:
	return "res://voice/%s.ogg" % text.md5_text().substr(0, 10)
