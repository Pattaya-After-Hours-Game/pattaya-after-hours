# First-week momentum and recruitment

Implemented 28 November 2026. The player found days three to seven too quiet,
then enjoyed day seven's faster, profitable trading. Give the first week two
smaller opportunities and make investment choices legible; retain the seats →
service → appeal → seats cycle and expansion pacing bounds.

## Opening-week calendar

| Day | Gathering | Hours | Shared traffic | Blue Hour appeal | Drinking duration |
| --- | --- | --- | --- | --- | --- |
| 3 | Pim's Soundcheck | 18:00–22:00 | ×1.20 | +1 | ×0.85 |
| 5 | The Locals' Warm-Up | 18:00–22:00 | ×1.30 | +1.5 | ×0.80 |
| 7 | Anong's Birthday | Noon–1am | ×1.40 | +2 | ×0.75 |

Only the first two are new. Each uses the existing celebration ledger, extra
planned round (maximum three, non-stacking with club), ten seconds of patience,
finite traffic and real orders. Drinking durations are rounded to seconds.
Normal prices, wages, paid stock and pool rules apply. There is no entry charge,
free inventory, payout or quest reward. Existing visit plans and paid orders
remain intact. Extra attraction requires the flagship to be open. Forecasts,
menu and offline time cannot run parties or create income.

Events, the banner and Journal announce tomorrow's gathering. Both early
nights happen once; later weekly events continue normally. Old campaigns past
day five receive no retroactive event or money. The birthday remains the large
first-week payoff.

## Random recruits and contract exits

Hiring assigns the rolled person's existing saved profile. It does not reroll
individual statistics on opening a panel or renewing. Initial rarity totals stay
70/24/5/1% common/uncommon/rare/legendary. Within common, bartenders have 60%
ordinary crew + 10% Gabby; hosts have 60% ordinary crew + 10% Daisy. Dancers
retain 70% ordinary crew. Owned named identities, including expired ones,
return their chance to ordinary crew. Nida keeps her separate direct hire.

The approved refund is:

`floor(paid contract price × remaining live term / 14,400 × 0.80)`

At 20% elapsed, a ฿1,200 contract returns **฿768**, not ฿720. An immediate
exit returns ฿960; an expired contract returns nothing. The fee is 20% of the
unused value. Training is not refunded. Subsequent hires cost the full price
and draw again, so even an immediate replacement has a real cost.

Team → select floor worker shows the exact live refund and remaining fraction.
Busy/away workers must finish commitments before leaving. Removing a roster
slot preserves other workers' booking/event indices. The callback binds the
person, so a stale control cannot dismiss their replacement. Repeated exits
cannot refund the same contract twice. Nida uses Off duty instead.

Named staff's training, service deadline and actual-service history are archived
on exit and restored if randomly rediscovered. Generic replacement hires are
new people. Ordinary expiry/renewal still retains every worker's identity and
training, without a roll. AFK never recruits a replacement for an ended contract.
Earned tips and paid reports stay with the venue and settle normally.

Refunds enter shared cash as labelled finance transactions, outside customer
revenue, manager margins and the five-second trading sample. New/renewed
contracts save their actual fee; role-change supplements increase that paid
basis. Existing contracts without a receipt use their current listed role fee.
No save migration automatically grants a refund or changes staff.

## Readable investment choices

Upgrade help compares estimated customer-trading baht/second before and after,
both with owner service and with automatic service. It explains the projected
bottleneck. Near-zero improvement points to another limiting factor rather than
promising that every purchase earns more. Estimates exclude tips, purchase cost
and stock interruptions. The comparison uses cloned state and existing forecast
functions; it cannot roll recruits, advance clocks, sell or buy anything.

## Evidence and limits

`tests/first_week_balance.gd` compares ordinary/day-three/day-five/birthday
18:00–22:00 trading over 20 identical seeds per treatment. With the same prepared
bar, contribution totals were ฿38,264 / ฿45,916 / ฿46,962 / ฿47,980; sales were
897 / 1,053 / 1,066 / 1,070. Early nights improved contribution about 20% and 23%.
These are matched prepared-bar comparisons, not promises for every fresh game.
A full fridge and sufficient service still matter.

Fresh campaign pacing stays in the existing regression suite. Cancellation,
paid tips, reload, stale UI inputs, busy staff, archived skills and AFK behavior
are tested in `tests/first_week_check.gd`. Production art remains unchanged;
Team and Soundcheck previews are checked at 960×540 and 1280×720. Simulations
cannot establish whether a week feels fun: physical-device and player feedback
remain the next balance evidence.
