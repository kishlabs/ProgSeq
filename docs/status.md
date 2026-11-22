# Project Status

**Last updated:** 22 Nov 2026 | **Release target:** v1.0 | **Overall:** early stage (paper design done, core RTL simulated)

## Dashboard

| Milestone | State | Progress | Notes |
|---|---|---|---|
| M0 Setup | In progress | Scaffold ready | Repo, ChipIN ticket and PDK still to confirm |
| M1 Paper design | Mostly done | A, generalization, C sketch done | Moore paper design and `table_gen` controller equations remaining |
| M2 RTL | In progress | C + `table_gen` done | A and A' remaining |
| M3 Verification | In progress | C testbench passing | A, A', equivalence, coverage remaining |
| M4 Synthesis (Genus 25.1) | Not started | | Waiting for PDK |
| M5 Place and route (Innovus 25.1) | Not started | | Waiting for PDK |
| M6 Signoff (Tempus, Voltus, Pegasus) | Not started | | |
| M7 Release v1.0 | Not started | | |

States: Not started, In progress, Mostly done, Done, Blocked.

## Verified so far

| Check | Result |
|---|---|
| Directed: 1011 overlapping on `1011011` | 2 matches, pass |
| Directed: 01110 on `011101110` | 2 matches, pass |
| Directed: 1011 non-overlapping on `1011011` | 1 match, pass |
| 200 random patterns, lengths 1..N, both modes, junk above length | pass, N = 4, 8, 16, 32 |
| Pattern replacement leaves no residue | pass |
| Sticky `lock`; rejected `start` (locked or invalid length) with `start_err` | pass |
| External table write path | pass |
| Simulator | Icarus Verilog 12 (Xcelium run still to do) |
| `table_gen` worst-case build time | 180 clocks (N=8), 1000 (N=16): exact, matches the closed form |

## Next actions (in order)

1. Create the public repo, commit the scaffold, confirm CI is green (T-01 to T-03).
2. Send the ChipIN ticket and note the reply date (T-04).
3. Write design A (`fsm_1011.v`) from the paper equations (T-21).
4. Equivalence test: C loaded with the 1011 table versus A (T-32).
5. Moore paper design and RTL (T-16, T-22).

## Blockers

| Blocker | Owner | Since |
|---|---|---|
| PDK and standard-cell library location and node unknown | ChipIN / institution | ticket pending |

## Decisions pending

| Decision | Options | Needed by |
|---|---|---|
| Target clock period | Set after PDK node is known | M4 |
| Which corners to sign off | Depends on library | M6 |

## Not confirmed yet (please verify and tick)

- [ ] Paper pages scanned into `paper/`
- [ ] GitHub repo created and named
- [ ] ChipIN ticket sent

## How to update this file

At the end of each work session: update the dashboard rows, move finished items to "Verified so far", rewrite "Next actions", and add one line to [`log.md`](log.md).
