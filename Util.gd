extends Node

const FLOAT_EPSILON = 0.00001


static func compare_floats(a: float, b: float, epsilon = FLOAT_EPSILON) -> bool:
	return abs(a - b) <= epsilon


static func float_is_zero(a: float, epsilon = FLOAT_EPSILON) -> bool:
	return abs(a) <= epsilon

static func str_includes(str1: String, str2: String) -> bool:
    return str2 in str1