class_name TestSuite
extends RefCounted
## Base class for test suites. Every method named test_* is a test.

var failures: PackedStringArray = []
var current_test: String = ""


func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append("%s — %s" % [current_test, message])


func eq(actual: Variant, expected: Variant, message: String = "") -> void:
	check(actual == expected, "%s expected <%s> got <%s>" % [message, expected, actual])


func near(actual: float, expected: float, message: String = "", eps: float = 0.0001) -> void:
	check(absf(actual - expected) <= eps, "%s expected ~%f got %f" % [message, expected, actual])


## Real game content, loaded fresh (no autoloads needed).
func load_content(check_files: bool = true) -> ContentData:
	var errs := ErrorLog.new()
	var data := ContentLoader.load_all("res://data", errs)
	ContentValidator.validate(data, errs, check_files)
	check(errs.is_empty(), "content errors: %s" % "; ".join(errs.messages))
	return data
