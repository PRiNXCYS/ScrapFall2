## Base class for tests: every method named test_* is run by tests/run_tests.gd.
class_name TestCase
extends RefCounted

var failures: Array[String] = []
var tree: SceneTree


func set_tree(t: SceneTree) -> void:
	tree = t


## Waits n rendered frames (game logic keeps running).
func frames(n: int) -> void:
	for i in n:
		await tree.process_frame


func assert_eq(actual, expected, msg := "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_num(actual) and _is_num(expected)):
		failures.append("%s expected %s (%s) got %s (%s)" % [msg, str(expected), type_string(typeof(expected)), str(actual), type_string(typeof(actual))])
	elif actual != expected:
		failures.append("%s expected %s got %s" % [msg, str(expected), str(actual)])


func assert_true(cond: bool, msg := "") -> void:
	if not cond:
		failures.append(msg if msg != "" else "expected true")


func _is_num(v) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT
