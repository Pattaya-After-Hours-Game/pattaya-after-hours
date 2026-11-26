extends RefCounted

static func buy(st: RefCounted, kind: int) -> void:
	var source: Dictionary = st.selected()
	var amount := maxi(0,int(source.cash)/2)
	st.finance.transfer(source,amount,true)
	var count: int = st.s.street.bars.size()
	st.action("buy",kind)
	if st.s.street.bars.size()>count and st.s.cash>0:
		st.finance.transfer(st.selected(),int(st.s.cash),false)

static func legacy(m: RefCounted) -> void:
	if not m.s.has("street"): return
	if not m.s.street.bars[0].has("cash"): return
	m.s.cash = m.street.finance.total()
	for bar in m.s.street.bars: bar.cash = 0
