class_name Score

static var _score: int = 0

static func reset():
	_score = 0

static func add_points(points: int):
	_score += points

static func get_score() -> int:
	return _score
