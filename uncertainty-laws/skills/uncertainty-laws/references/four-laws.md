# Four laws — napkin detail

Procedure companion for `uncertainty-laws`. Keep emits short; expand here only when the agent needs a formula.

## Law 1 — Expected value

\[
EV = \sum_i p_i \cdot x_i
\]

- You are paid for **mispricing**, not for being correct.
- Right 90% of the time on a 95¢ price → lose. Right 30% on a 20¢ price → edge.
- Lotteries: often ~half EV of ticket price (feeling markup).
- Insurance: usually **negative EV** and still often correct once Law 3 is in view.

**Ask:** What am I offered, and what is it worth?

## Law 2 — Base rates (Bayes)

\[
P(A\mid B) = \frac{P(B\mid A)\,P(A)}{P(B)}
\]

Evidence **updates** a prior; it does not replace one.

Classic trap: disease 1/1000, test 99% → positive ≈ 9%, not 99%.

**Ask:** How many of these are there to begin with?

Applies to win-rate heroes, screening alarms, and “sure” letters of confidence.

## Law 3 — Variance / ruin (your one path)

Population average ≠ your compounded path.

Toy: +50% / −40% fair coin has **positive** arithmetic EV but **negative** growth for one path. Crowds hide the wipeouts that drag averages up.

- 50% loss needs 100% gain to recover.
- Zero is **absorbing**.
- Survival is not a constraint on the strategy — **it is the strategy**.

**Ask:** If the bad branch hits, am I still in the game?

## Law 4 — Kelly (size)

\[
f^\* = \frac{bp - q}{b}
\]

\(p\) win prob, \(q=1-p\), \(b\) net odds.

Even-money 60% coin → \(f^\*=0.2\). Double that size → edge can vanish or go negative while still being “right” most of the time.

Practice: **half-Kelly** is common (less growth, much less volatility). Your edge is smaller than you think → never over-Kelly.

**Ask:** How big without dying?

## Sequence (do not reorder)

1. Is the price wrong in my favour?  
2. Am I fooling myself about the evidence?  
3. Can this path kill me?  
4. How big should this be?

If (3) fails, stop. Do not “Kelly” a ruin path.
