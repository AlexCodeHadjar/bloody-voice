extends TestSuite


func test_same_inputs_same_sequence() -> void:
	var a := SeededRng.make_stream(42, &"rumors", 3)
	var b := SeededRng.make_stream(42, &"rumors", 3)
	for i: int in 10:
		eq(a.randi(), b.randi(), "draw %d" % i)


func test_streams_are_independent() -> void:
	var a := SeededRng.make_stream(42, &"rumors", 3)
	var b := SeededRng.make_stream(42, &"shop", 3)
	var c := SeededRng.make_stream(42, &"rumors", 4)
	var x := a.randi()
	check(x != b.randi(), "different system -> different stream")
	check(x != c.randi(), "different day -> different stream")
