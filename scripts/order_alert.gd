extends RefCounted
const INTERVAL = preload("res://scripts/street_content.gd").ORDER_ALERT_SECONDS
var remaining := 0.0

func tick(waiting: bool, delta: float, enabled: bool = true) -> bool:
	remaining = maxf(0.0,remaining-maxf(0.0,delta))
	if not enabled or not waiting or remaining>0: return false
	remaining = INTERVAL
	return true
