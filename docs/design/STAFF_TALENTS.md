# Discoverable staff

Ordinary paid hiring can reveal eight fictional adult specialists. Bartender
hires use the bartender pool; Hostess bar host and gogo dancer hires share the
entertainer pool. Contracts still cost ฿1,200 / ฿4,500 and last ten game days.
Normal wages, venue capacity, training gates and shared cash apply.

Before any discoveries, each pool contains 70% regular crew, 24% uncommon,
5% rare and 1% legendary. Each uncommon character has a 12% chance. Team's
hiring help shows the current exact odds. There is no additional roll fee.

| Recruit | Rarity | Base service | Appeal multiplier | Extra tips |
| --- | --- | --- | --- | --- |
| Copper | Uncommon | 23s | — | — |
| Rose | Uncommon | 30s | — | ฿10 per drink she serves |
| Ruby | Rare | 18s | — | ฿5 per drink she serves |
| Platinum | Legendary | 13s | — | ฿15 per drink she serves |
| Violet | Uncommon | Does not serve | 1.5× | ฿5 |
| Goldie | Uncommon | Does not serve | 1.2× | ฿20 |
| Scarlet | Rare | Does not serve | 2× | ฿10 |
| Onyx | Legendary | Does not serve | 3× | ฿30 |

An entertainer's bonus applies to each actual paid hosted drink when working as
a host. A dancer's bonus applies to a customer's first actual drink during the
existing performance window (live seconds 40–79 of the 120-second set cycle).
Only the highest eligible dancer bonus applies. On-duty, contracted and available
staff are required. An invitation, empty bar, repeated pose or offline estimate
earns no talent tips. Hosts and dancers never serve ordinary orders.

Bartender training multiplies the existing service interval by Copper 0.9,
Rose 1.2, Ruby 0.72 or Platinum 0.5, rounded up, with a three-second minimum.
New staff start ready for a real order. Training changes future recovery only;
the saved current deadline remains unchanged. Host/dancer multipliers improve
the person's existing trained attraction, competing for finite shared demand.
They do not create customers or increase street traffic.

Tips accumulate separately in `bar.talent_tips` and count with the real venue jar
at closing or nightly settlement. They are excluded from manager bonuses,
healthy-service margins and the five-second trading sample. Existing ฿10 first
visit tips, matched-drink bonuses and Gabby's tips remain intact. Counting tips
clears the jar and retains the paid receipt, including after save/reload.

Each named discovery occupies one roster slot across the entire street,
including after expiry. Owned characters' probability returns to regular crew;
it does not increase the other rare chances. Renewal keeps identity, training,
rota behavior and service deadlines. Specialists retain their original role.
Gabby, Daisy and Nida keep their direct hiring controls. Existing workers are
never rerolled, and the isolated practice tutorial keeps ordinary recruits.

Recruitment advances a separate saved `street.hiring_seed` only after a valid,
affordable hire. Save/reload gives the same next result. Menus, forecasts, failed
hires, renewals and offline claims do not advance it or the traffic RNG. The
optional schema-17 identity/seed/tip fields are validated without granting old
campaigns new staff, cash or tips. Ryan's contract rule remains: absence pauses
contracts; live closed hours and skipped nights still age them.

Violet and Onyx decline private bookings. Goldie and Scarlet retain the existing
consent, availability and capacity rules. Private activity remains off-screen.

Implementation: `street_content.gd` owns profile data, `economy.gd` owns draws,
service, appeal and tip accounting, `campaign.gd` validates saves, and the art
catalog/UI present those results. See [the sprite sources](../../art/staff-pack-v1/README.md)
and [verification](../TESTING.md).
