extends RefCounted

# Company cash remains s.cash for legacy company actions. Venue cash never aliases it.
var s: Dictionary

func _init(state: Dictionary) -> void:
	s = state

static func fields() -> Dictionary:
	return {"cash":0,"earnings_net":0,"earnings_seconds":0,"net_per_second":0.0,"manager_bonus_carry":0}

func total() -> int:
	var amount := int(s.cash)
	for bar in s.street.bars: amount += int(bar.cash)
	return amount

func transfer(bar: Dictionary, amount: int, deposit: bool) -> bool:
	if amount<=0 or not s.street.bars.any(func(owned: Dictionary) -> bool: return is_same(owned,bar)): return false
	if deposit:
		if bar.cash<amount: return false
		bar.cash -= amount
		s.cash += amount
	else:
		if s.cash<amount: return false
		s.cash -= amount
		bar.cash += amount
	return true

func migrate(economy: RefCounted, fresh: bool) -> void:
	if s.get("practice",false): return
	if fresh:
		s.street.bars[0].cash = int(s.cash)
		s.cash = 0
		s.reserve = 0
		return
	if int(s.get("version",1))>=16: return
	var available := maxi(0,int(s.cash)+int(s.get("reserve",0)))
	var targets: Array[int] = []
	var needed := 0
	for bar in s.street.bars:
		var target: int = economy.working_cash(bar)
		targets.append(target)
		needed += target
	var allocated := 0
	for i in targets.size():
		var amount := targets[i] if available>=needed else int(available*targets[i]/maxi(1,needed))
		s.street.bars[i].cash = amount
		allocated += amount
	if available<needed:
		for i in available-allocated: s.street.bars[i%targets.size()].cash += 1
		allocated = available
	s.cash = available-allocated
	s.reserve = 0
