## Headless test runner: godot --headless --path . -s res://tests/run_tests.gd
## Runs every test_* method in res://tests/test_*.gd. Exit code 1 if anything fails.
extends SceneTree


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var only := OS.get_environment("TEST_ONLY")
	var files: Array[String] = []
	for f in DirAccess.get_files_at("res://tests"):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			if only == "" or f.contains(only):
				files.append(f)
	files.sort()
	var passed := 0
	var failed := 0
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			failed += 1
			print("FAIL %s: script did not load" % f)
			continue
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if not name.begins_with("test_"):
				continue
			var t = script.new()
			if t.has_method("set_tree"):
				t.set_tree(self)
			await t.call(name)  # plain tests return at once; tests that wait for frames finish first
			if t.failures.is_empty():
				passed += 1
				print("PASS %s.%s" % [f.get_basename(), name])
			else:
				failed += 1
				for msg in t.failures:
					print("FAIL %s.%s: %s" % [f.get_basename(), name, msg])
			if t.has_method("cleanup"):
				t.cleanup()
			paused = false  # a test that pauses and forgets to unpause must not freeze the next file's tests
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 or (passed == 0) else 0)
