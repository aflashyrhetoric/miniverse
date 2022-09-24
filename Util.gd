extends Node

const FLOAT_EPSILON = 0.00001

static func compare_floats(a: float, b: float, epsilon = FLOAT_EPSILON) -> bool:
    return abs(a - b) <= epsilon

static func float_is_zero(a: float, epsilon = FLOAT_EPSILON) -> bool:
    return abs(a) <= epsilon