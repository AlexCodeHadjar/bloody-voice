extends Node
## Loads and validates all content once at start-up. If `errors` is not empty the game must not start.

const DATA_ROOT := "res://data"

var data: ContentData = ContentData.new()
var errors: PackedStringArray = []


func _ready() -> void:
	reload()


func reload() -> void:
	var errs := ErrorLog.new()
	data = ContentLoader.load_all(DATA_ROOT, errs)
	ContentValidator.validate(data, errs)
	errors = errs.messages
	for e: String in errors:
		push_error("[content] " + e)
	EventBus.content_loaded.emit(errors)


func is_ok() -> bool:
	return errors.is_empty()
