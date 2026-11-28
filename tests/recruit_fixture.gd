extends RefCounted

static func seed_for(draw: int) -> int:
	for candidate in range(1,10000):
		if (candidate*48271)%2147483647%100==draw: return candidate
	return 1

static func named(st: RefCounted, identity: String) -> String:
	var role := 0 if identity=="gabby" else 1
	if (identity=="gabby" and not st.economy.gabby_venue().is_empty()) or (identity=="daisy" and not st.economy.daisy_venue().is_empty()): return st.action("hire_"+identity)
	st.s.street.hiring_seed = seed_for(60)
	return st.action("hire",role)
