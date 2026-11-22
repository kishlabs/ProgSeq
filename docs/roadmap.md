# Roadmap

The plan, in order. Check items off here as they finish and record the day-to-day detail in [`log.md`](log.md). Current position: [`status.md`](status.md).

**Rules**

1. Finish in order: paper, RTL, verification, clean GDS, then sweeps.
2. Scope is frozen per release. New ideas go to the backlog, not into the current milestone.
3. A milestone is done only when its **exit criteria** are met.
4. Effort split: Design 35% | Physical Design 40% | Verification 15% | Documentation 10%.

Task IDs (`T-nn`) can be used as GitHub issue titles.

## v1.0 scope

Designs **A** (fixed Mealy), **A'** (fixed Moore) and **C** (programmable FSM with `table_gen`). See [specification](specification.md).

---

## M0: Project setup

| ID | Task | Done |
|---|---|---|
| T-01 | Create the public GitHub repo `progseq`, add Apache-2.0 license | [ ] |
| T-02 | Commit this scaffold (docs, RTL, testbench, CI) | [ ] |
| T-03 | Confirm CI badge is green; replace `OWNER` in README | [ ] |
| T-04 | Send the ChipIN ticket for PDK and standard-cell library and the setup guide | [x] drafted, [ ] sent |
| T-05 | Receive PDK; record node, library name, corners and tool versions in [`pd_plan.md`](pd_plan.md) | [ ] |
| T-06 | Genus/Innovus smoke test on a tiny design (counter) | [ ] |

**Exit:** repo public with green CI; PDK location known; both tools run a counter to GDS.

## M1: Paper design

| ID | Task | Done |
|---|---|---|
| T-10 | Fixed 1011 Mealy: diagram, table, minimization, state assignment, excitation table, logic circuit | [x] |
| T-11 | Logisim simulation of design A | [x] |
| T-12 | Tables for 1101, 1001, 10110 and non-overlapping 1011 | [x] |
| T-13 | Design C block diagram, memory image, storage cost table | [x] |
| T-14 | Table_gen method worked by hand (1011, 01110) | [x] |
| T-15 | table_gen controller state table, K-map and equations (3 flops) | [ ] |
| T-16 | Moore 1011: diagram, 5-state table, assignment, equations, circuit | [ ] |
| T-17 | Mealy vs Moore comparison table (states, flops, latency, gates) | [ ] |
| T-18 | Hand estimate of A vs C gate/flop cost | [ ] |
| T-19 | Scan all pages into `paper/` with an index | [ ] |

**Exit:** every paper step scanned and indexed; hand estimates recorded for comparison with Genus.

## M2: RTL

| ID | Task | Done |
|---|---|---|
| T-20 | `progseq_core.v`, `table_gen.v`, `progseq_top.v` | [x] |
| T-21 | `fsm_1011.v` (A) from the paper equations | [ ] |
| T-22 | `fsm_1011_moore.v` (A') | [ ] |
| T-23 | Python reference model / table generator in `scripts/` | [ ] |
| T-24 | Lint clean with the Cadence lint tool (HAL) | [ ] |

**Exit:** all three designs written, lint clean, freeze tag `rtl-v1.0`.

## M3: Verification

| ID | Task | Done |
|---|---|---|
| T-30 | Self-checking testbench for C with sliding-window reference model | [x] |
| T-31 | Testbench for A and A' (directed plus random) | [ ] |
| T-32 | Equivalence by simulation: C loaded with the 1011 table versus A, every cycle | [ ] |
| T-33 | Mealy/Moore latency check (A' output is one cycle after A) | [ ] |
| T-34 | Table check: every entry written by `table_gen` equals the Python golden table | [ ] |
| T-35 | Assertions (SVA): reset, no X on outputs, lock, busy/enable | [ ] |
| T-36 | State and transition coverage in Xcelium | [ ] |
| T-37 | Port tests to Xcelium and record results | [ ] |

**Exit:** all checks in the [verification plan](verification_plan.md) pass in Xcelium; coverage closed.

## M4: Synthesis (Genus 25.1)

| ID | Task | Done |
|---|---|---|
| T-40 | SDC for A, A', C (clock, I/O delays, explicit `din` to `match` constraint) | [ ] |
| T-41 | Genus script (`synth/genus.tcl`): read, elaborate, synthesize, report, write netlist | [ ] |
| T-42 | Synthesize A, A', C at a relaxed clock; check no latches and expected flop counts | [ ] |
| T-43 | Gate-level simulation of each netlist with the same testbench | [ ] |
| T-44 | Compare hand estimates with Genus area/flop counts | [ ] |

**Exit:** all netlists meet timing, gate-level sims match RTL.

## M5: Place and route (Innovus 25.1)

| ID | Task | Done |
|---|---|---|
| T-50 | MMMC file and `pd/innovus.tcl` (import, floorplan, power, place, CTS, route, fill) | [ ] |
| T-51 | Run C to GDS; fix connectivity, DRC, then timing in that order | [ ] |
| T-52 | Run A and A' with the same script | [ ] |
| T-53 | Checkpoints saved after place, CTS, route | [ ] |

**Exit:** GDS for A, A', C with setup/hold slack >= 0 and no DRC/connectivity violations in Innovus.

## M6: Signoff and analysis

| ID | Task | Done |
|---|---|---|
| T-60 | Tempus signoff timing (setup/hold, multi-corner if available) | [ ] |
| T-61 | Voltus power using switching activity from Xcelium gate-level simulation | [ ] |
| T-62 | Pegasus DRC and LVS | [ ] |
| T-63 | Experiments: clock-period sweep, constraint sweep, Mealy vs Moore, A vs C, `table_gen` area share | [ ] |
| T-64 | Critical-path analysis of `din` to `match` | [ ] |

**Exit:** signoff clean; [results](results.md) table complete.

## M7: Release v1.0

| ID | Task | Done |
|---|---|---|
| T-70 | Fill [`results.md`](results.md), add plots | [ ] |
| T-71 | README finalised with headline results; screenshots only if permitted | [ ] |
| T-72 | Integration guide checked against the final RTL | [ ] |
| T-73 | Tag `v1.0`, update CHANGELOG, create GitHub release | [ ] |
| T-74 | 2-page summary for the portfolio | [ ] |

**Exit:** a stranger can clone, run `make sim`, read the results, and understand the design.

---

## Backlog: v1.1 and later

| Item | Value |
|---|---|
| **Design B**: shift-register matcher with pattern and mask registers | FSM vs parallel comparison; native wildcards |
| Wildcard analysis for C (subset construction, state blow-up) | Shows where each architecture wins |
| Multi-pattern: parallel engines first, shared automaton later | Multiple flags |
| Event counter and logger (width, saturate/wrap, overflow) | Useful IP feature |
| Gray and one-hot state encodings | Flop count and timing comparison |
| Reset synchronizer, input synchronizer, clock gating | IP robustness, power |
| Formal equivalence (A vs C) | Proof, not just simulation |
| Parallel-comparison `table_gen` | Area vs build-time trade-off |
| Latch-based table storage | Area vs risk trade-off |

## Risks

| Risk | Impact | Mitigation |
|---|---|---|
| PDK or licence access is delayed | M4 to M6 blocked | Finish M1 to M3 first; keep RTL tool-neutral; chase the ChipIN ticket |
| Limited lab or tool hours | Slow PD | Script everything in Tcl; run sweeps in batch; use Icarus at home |
| Scope creep | Never finishing | Backlog rule; frozen spec |
| PD debugging takes long | Schedule slip | Smoke test early (T-06); checkpoint after every step |
| Publication restrictions on PDK-derived data | Fewer visuals | Check the policy early ([pd_plan](pd_plan.md#8-publication-policy)); publish scripts and summarised numbers |
