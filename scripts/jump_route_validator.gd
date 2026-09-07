class_name JumpRouteValidator
extends RefCounted

## Checks that a planned jump from platform A to B is possible for a kid
## holding jump (full arc). Constants match scripts/player.gd.
##
## Layout rules (tile = 64px). Single jump ~2.6 tiles; head at apex ~3.3 tiles.
## Double jump ~4.5 tiles; head ~5.3 tiles.
## - 2-tile rise: overlap ~1 tile in X. The platform TWO hops later sits 4 tiles
##   up and MUST NOT overlap this one — a held jump hits it.
## - Reverse direction only after 6 tiles of rise, or with a 3-tile double jump
##   (then the return ledge is 5+ tiles up and may overlap).
## - 3-tile rise: designated double jump, ~1 tile overlap, jump from the edge.

const TILE := 64.0
const GRAVITY := 2000.0
const JUMP_V := 820.0
const DOUBLE_V := 700.0
const MOVE_SPEED := 220.0
const PLAYER_HALF_W := 16.0
const PLAYER_FEET := 27.0
const PLAYER_HEAD := 19.0
const EDGE_MARGIN := 12.0
## Tree sprite size must match FruitPlant HEIGHT / texture.
const TREE_HEIGHT := 156.0
const TREE_TEX_W := 248.0
const TREE_TEX_H := 353.0
const TREE_SINK := 12.0

static func single_jump_height() -> float:
	return JUMP_V * JUMP_V / (2.0 * GRAVITY)


static func double_jump_height() -> float:
	return single_jump_height() + DOUBLE_V * DOUBLE_V / (2.0 * GRAVITY)


static func head_reach(double_jump: bool) -> float:
	var rise := double_jump_height() if double_jump else single_jump_height()
	return PLAYER_FEET + PLAYER_HEAD + rise


static func max_air_distance(double_jump: bool) -> float:
	var t := 2.0 * JUMP_V / GRAVITY
	if double_jump:
		t += 2.0 * DOUBLE_V / GRAVITY * 0.55
	return MOVE_SPEED * t


static func rect_of(p: Dictionary) -> Rect2:
	return Rect2(p.tx * TILE, p.ty * TILE, p.w * TILE, p.h * TILE)


static func tree_rect(tx: float, ty: int) -> Rect2:
	var plant_scale := TREE_HEIGHT / TREE_TEX_H
	var width := TREE_TEX_W * plant_scale
	var stand := Vector2((tx + 0.5) * TILE, ty * TILE + TREE_SINK)
	return Rect2(stand.x - width * 0.5, stand.y - TREE_HEIGHT, width, TREE_HEIGHT)


static func _stand_platform(tx: float, ty: int, platforms: Array) -> Dictionary:
	for p in platforms:
		if int(p.ty) != ty:
			continue
		if tx >= float(p.tx) and tx < float(p.tx + p.w):
			return p
	return {}


static func tree_hits_platform(tx: float, ty: int, platforms: Array) -> String:
	var canopy := tree_rect(tx, ty)
	canopy = canopy.grow(-4.0)
	for p in platforms:
		if int(p.ty) >= ty:
			continue
		if canopy.intersects(rect_of(p)):
			return str(p.id)
	return ""


static func nudge_tree(tx: float, ty: int, platforms: Array) -> float:
	if tree_hits_platform(tx, ty, platforms) == "":
		return tx
	var stand := _stand_platform(tx, ty, platforms)
	if stand.is_empty():
		return tx
	var min_tx := float(stand.tx) + 0.2
	var max_tx := float(stand.tx + stand.w) - 1.2
	var best := tx
	var best_dist := INF
	var t := min_tx
	while t <= max_tx + 0.001:
		if tree_hits_platform(t, ty, platforms) == "":
			var d := absf(t - tx)
			if d < best_dist:
				best_dist = d
				best = t
		t += 0.25
	if best_dist < INF:
		print("Tree nudged from tile %.2f to %.2f (was overlapping a platform)" % [tx, best])
		return best
	push_warning("Tree at tile %.2f, y=%d still overlaps a platform" % [tx, ty])
	return tx


static func validate_path(platforms: Array, path_ids: Array) -> PackedStringArray:
	var errors: PackedStringArray = []
	var by_id := {}
	for p in platforms:
		by_id[p.id] = p
	for i in range(path_ids.size() - 1):
		var a_id: String = path_ids[i]
		var b_id: String = path_ids[i + 1]
		if not by_id.has(a_id) or not by_id.has(b_id):
			errors.append("Missing platform %s -> %s" % [a_id, b_id])
			continue
		var err := validate_hop(by_id[a_id], by_id[b_id], platforms)
		if err != "":
			errors.append("%s -> %s: %s" % [a_id, b_id, err])
	return errors


static func validate_hop(a: Dictionary, b: Dictionary, platforms: Array) -> String:
	var ar := rect_of(a)
	var br := rect_of(b)
	var rise := ar.position.y - br.position.y
	var need_double := rise > single_jump_height() - 8.0
	if rise > double_jump_height() - 8.0:
		return "rise %.0fpx is higher than a double jump (%.0fpx)" % [rise, double_jump_height()]

	var takeoff := _uncovered_top(ar, platforms, need_double)
	if takeoff.is_empty():
		var lids := ", ".join(_covering_ids(a, platforms, need_double))
		if lids == "":
			return "no uncovered takeoff on %s" % a.id
		return "no uncovered takeoff on %s (covered by %s)" % [a.id, lids]

	var land_left: float = br.position.x + EDGE_MARGIN
	var land_right: float = br.position.x + br.size.x - EDGE_MARGIN
	if land_right <= land_left:
		return "landing %s is too narrow" % b.id

	var gap := _gap_between(takeoff, Vector2(land_left, land_right))
	if rise <= 8.0:
		need_double = gap > max_air_distance(false)
	var max_dist := max_air_distance(need_double)
	if gap > max_dist:
		return "horizontal gap %.0fpx is farther than jump distance %.0fpx" % [gap, max_dist]

	var corridor := _shortest_corridor(takeoff, Vector2(land_left, land_right))
	var blocker := _ceiling_in_corridor(a, b, corridor, ar.position.y, platforms, need_double)
	if blocker != "":
		return "ceiling '%s' blocks the jump arc" % blocker
	return ""


static func _uncovered_top(ar: Rect2, platforms: Array, need_double: bool) -> PackedVector2Array:
	var left := ar.position.x + EDGE_MARGIN
	var right := ar.position.x + ar.size.x - EDGE_MARGIN
	var segs: Array = [Vector2(left, right)]
	var reach := head_reach(need_double)
	var head_stand := ar.position.y - (PLAYER_FEET + PLAYER_HEAD)
	var apex := ar.position.y - reach
	for p in platforms:
		var r := rect_of(p)
		if r.position.y >= ar.position.y:
			continue
		if r.end.y <= apex or r.position.y >= head_stand:
			continue
		if r.end.x <= left or r.position.x >= right:
			continue
		segs = _cut(segs, r.position.x + 4.0, r.end.x - 4.0)
	var out: PackedVector2Array = []
	for s in segs:
		if s.y - s.x >= PLAYER_HALF_W * 2.0:
			out.append(s)
	return out


static func _covering_ids(a: Dictionary, platforms: Array, need_double: bool) -> PackedStringArray:
	var ar := rect_of(a)
	var left := ar.position.x + EDGE_MARGIN
	var right := ar.position.x + ar.size.x - EDGE_MARGIN
	var reach := head_reach(need_double)
	var head_stand := ar.position.y - (PLAYER_FEET + PLAYER_HEAD)
	var apex := ar.position.y - reach
	var ids: PackedStringArray = []
	for p in platforms:
		if p.id == a.id:
			continue
		var r := rect_of(p)
		if r.position.y >= ar.position.y:
			continue
		if r.end.y <= apex or r.position.y >= head_stand:
			continue
		if r.end.x <= left or r.position.x >= right:
			continue
		ids.append(str(p.id))
	return ids


static func _cut(segs: Array, cut_a: float, cut_b: float) -> Array:
	var next: Array = []
	for s in segs:
		if cut_b <= s.x or cut_a >= s.y:
			next.append(s)
			continue
		if cut_a > s.x:
			next.append(Vector2(s.x, minf(cut_a, s.y)))
		if cut_b < s.y:
			next.append(Vector2(maxf(cut_b, s.x), s.y))
	return next


static func _gap_between(takeoff: PackedVector2Array, land: Vector2) -> float:
	var best := INF
	for s in takeoff:
		if s.y >= land.x and s.x <= land.y:
			return 0.0
		if s.y < land.x:
			best = minf(best, land.x - s.y)
		elif s.x > land.y:
			best = minf(best, s.x - land.y)
	return best


static func _shortest_corridor(takeoff: PackedVector2Array, land: Vector2) -> Vector2:
	var best_t := land.x
	var best_l := land.x
	var best_d := INF
	for s in takeoff:
		var closest_t := s.x
		var closest_l := land.x
		if s.y < land.x:
			closest_t = s.y
			closest_l = land.x
		elif s.x > land.y:
			closest_t = s.x
			closest_l = land.y
		else:
			var overlap_a := maxf(s.x, land.x)
			var overlap_b := minf(s.y, land.y)
			closest_t = (overlap_a + overlap_b) * 0.5
			closest_l = closest_t
		var d := absf(closest_t - closest_l)
		if d < best_d:
			best_d = d
			best_t = closest_t
			best_l = closest_l
	var pad := PLAYER_HALF_W + TILE * 0.6
	return Vector2(minf(best_t, best_l) - pad, maxf(best_t, best_l) + pad)


static func _corridor(takeoff: PackedVector2Array, land: Vector2) -> Vector2:
	var left := land.x
	var right := land.y
	for s in takeoff:
		left = minf(left, s.x)
		right = maxf(right, s.y)
	return Vector2(left - PLAYER_HALF_W, right + PLAYER_HALF_W)


static func _ceiling_in_corridor(
	a: Dictionary,
	b: Dictionary,
	corridor: Vector2,
	from_top: float,
	platforms: Array,
	need_double: bool
) -> String:
	var apex := from_top - head_reach(need_double)
	var head_stand := from_top - (PLAYER_FEET + PLAYER_HEAD)
	for p in platforms:
		if p.id == a.id or p.id == b.id:
			continue
		var r := rect_of(p)
		if r.end.x <= corridor.x or r.position.x >= corridor.y:
			continue
		if r.end.y <= apex or r.position.y >= head_stand:
			continue
		return str(p.id)
	return ""
