extends RefCounted

static func buy(st: RefCounted, kind: int) -> void:
	st.action("buy",kind)

static func legacy(_m: RefCounted) -> void:
	# Legacy saves already use the same shared balance.
	pass
