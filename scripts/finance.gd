extends RefCounted

# One shared balance. Venue ledgers attribute trade, never hold spendable money.
var s: Dictionary

func _init(state: Dictionary) -> void:
	s = state

static func fields() -> Dictionary:
	return {"earnings_net":0,"earnings_seconds":0,"net_per_second":0.0,"manager_bonus_carry":0}

func total() -> int:
	return int(s.cash)

static func change(state: Dictionary, amount: int, reason: String, venue: String = "Street") -> void:
	if amount==0: return
	assert(not reason.is_empty())
	state.cash += amount
	if not state.has("street"): return
	var book: Array = state.street.get("cashbook",[])
	var entry := {"day":int(state.day),"minute":int(state.street.minute),"venue":venue,"reason":reason,"amount":amount}
	if not book.is_empty() and book[0].day==entry.day and book[0].venue==venue and book[0].reason==reason and signi(int(book[0].amount))==signi(amount):
		book[0].amount += amount
		book[0].minute = entry.minute
	else:
		book.push_front(entry)
		if book.size()>60: book.pop_back()
	state.street.cashbook = book

func migrate(_economy: RefCounted, fresh: bool) -> void:
	if not fresh:
		s.cash += int(s.get("reserve",0))
		if int(s.get("version",1))==16:
			for bar in s.street.bars: s.cash += int(bar.get("cash",0))
	s.reserve = 0
	for bar in s.street.bars: bar.erase("cash")
	s.street.merge({"cashbook":[]})
