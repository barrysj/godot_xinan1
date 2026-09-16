extends RefCounted
## Shared pose inspection, with no sampling lifecycle or character assumptions.

static func descendants(node: Node) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for child in node.get_children():
		if child is Node2D: result.append(child)
		result.append_array(descendants(child))
	return result

static func distance(a: Variant, b: Variant) -> float:
	if a is Vector2: return a.distance_to(b)
	if a is Color: return maxf(maxf(absf(a.r-b.r), absf(a.g-b.g)), maxf(absf(a.b-b.b), absf(a.a-b.a)))
	return absf(float(a)-float(b))
