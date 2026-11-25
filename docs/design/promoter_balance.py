#!/usr/bin/env python3
"""Planning estimates, NOT the live economy or a campaign pacing test.

Run: python3 docs/design/promoter_balance.py
Inputs mirror the forecast formula at 0d7bb90; proposed bonuses are explicit.
No saves, production files, random state or game currency are changed.
"""
import json
import math

PRICE = 55
STOCK_COST = 14
CONTRACT = 1200
COMMISSION = 0.10
BONUSES = [4.8, 6.0, 7.2]
MIX = [0.40, 0.35, 0.25]
AFFINITY = [1.5, 1.0, 0.5]


def arrivals(weight, traffic=7.3, rivals=()):
    return sum(traffic * mix * weight * affinity /
               (5 + (weight + sum(rivals)) * affinity)
               for mix, affinity in zip(MIX, AFFINITY))


def scenario(name, base, capacity, service, bonus=BONUSES[0], traffic=7.3,
             rivals=(), manual_welcome=0):
    before = arrivals(base + manual_welcome, traffic, rivals)
    after = arrivals(base + max(manual_welcome, bonus), traffic, rivals)
    # Current forecast: two orders per visit, 90-second average visit.
    sold_before = min(before, capacity / 1.5) * 2
    sold_after = min(after, capacity / 1.5) * 2
    sold_before = min(sold_before, service)
    sold_after = min(sold_after, service)
    delta = sold_after * (PRICE * (1 - COMMISSION) - STOCK_COST)
    delta -= sold_before * (PRICE - STOCK_COST)
    return dict(name=name, arrivals_before=round(before, 3),
                arrivals_after=round(after, 3), sales_before=round(sold_before, 3),
                sales_after=round(sold_after, 3), delta_margin_per_min=round(delta, 2),
                payback_open_minutes=round(CONTRACT / delta, 1) if delta > 0 else None,
                ten_day_delta_at_130_open_minutes=round(delta * 130 - CONTRACT, 2))


def seating(level, stage=1, pool=1, comfort=1):
    furniture = pool * 2 + comfort
    recovered = min(3, furniture) if level == 3 else 0
    return [6, 12, 20][stage - 1] + level * 2 - furniture + recovered


def pack(stock, capacity, cash):
    return (stock + 6, cash - 84) if capacity - stock >= 6 and cash >= 84 else (stock, cash)


def main():
    base = 4 + 15 / 80 * 1.5  # Fresh beer bar, reputation 15, ordinary noon.
    rows = [
        scenario("Base owner; no extra service", base, 12, 6),
        scenario("Six-second pouring; spare seats", base, 12, 10),
        scenario("Same owner already welcoming continuously", base, 12, 10, manual_welcome=1.2),
        scenario("Full layout limits sales", base, 3, 10),
        scenario("Base bartender alone", base, 12, 2.4),
        scenario("Sign and pool; base promoter", base + 3.5, 12, 12.4),
        scenario("Sign and pool; trained promoter", base + 3.5, 18, 12.4, bonus=BONUSES[1]),
        scenario("Low season approximation; sign", base + 2, 12, 10, traffic=7.3 * .7),
        scenario("Second similar bar competes", base, 12, 10, rivals=(base,)),
    ]
    # Boundary calculations for the proposal, not claims about runtime behaviour.
    assert [seating(level, pool=0, comfort=0) for level in range(4)] == [6, 8, 10, 12]
    assert [seating(level) for level in range(4)] == [3, 5, 7, 12]
    assert seating(3, 2, 2, 1) == 16  # A second pool table retains its space cost.
    assert pack(24, 30, 84) == (30, 0)
    assert pack(25, 30, 1000) == (25, 1000)
    assert pack(24, 30, 83) == (24, 83)
    assert pack(66, 70, 1000) == (66, 1000)
    assert 2 * arrivals(base, rivals=(base,)) < 7.3
    assert rows[0]["sales_before"] == rows[0]["sales_after"]
    print(json.dumps(dict(
        status="Analytical estimates only; campaign simulation still required",
        source_commit="0d7bb90", commission_basis="All drink receipts in steady on-duty trading",
        price=PRICE, stock_cost=STOCK_COST, contract=CONTRACT, bonuses=BONUSES,
        assumptions=["Continuous demand and capacity, perfect replenishment, no queue abandonment",
                     "No dirt, regulars, peaks, discounts, premium orders or pool income",
                     "Unchanged overhead/wages cancel in the incremental comparison",
                     "130 trading minutes assumes ten complete noon-to-1am days with overnight skips",
                     "Low-season row varies traffic only; real event also changes audience/attraction"],
        scenarios=rows, packs=dict(size=6, price=84),
        break_even_extra_sales_at_baseline_6=round((.1 * PRICE * 6 + CONTRACT / 130) /
                                                   (PRICE * .9 - STOCK_COST), 3),
        standalone_contract_margin_drinks=math.ceil(CONTRACT / (PRICE * .9 - STOCK_COST))
    ), indent=2))


if __name__ == "__main__":
    main()
