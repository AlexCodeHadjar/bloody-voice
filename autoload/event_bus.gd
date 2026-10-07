extends Node
## Global signals. Systems talk through these instead of holding references to each other.
## Only GameState emits game-flow signals; screens listen.

signal content_loaded(errors: PackedStringArray)
signal run_started
signal run_loaded
signal day_changed(day: int)
signal money_changed(money: int)
signal hero_moved(district: StringName)
signal district_state_changed(target: StringName, old_state: StringName, new_state: StringName)
signal loadout_changed
signal combat_started
signal combat_updated
signal combat_finished(outcome: StringName)
