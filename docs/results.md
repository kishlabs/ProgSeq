# Results

Filled in as runs complete. Every row must trace to a script and a run directory. Absolute values are subject to the [publication policy](pd_plan.md#8-publication-policy).

## 1. Hand estimates (from paper design)

| Design | State flops | Table flops | Gates / mux (hand estimate) |
|---|---|---|---|
| A (Mealy) | 2 | 0 | TBD from circuit |
| A' (Moore) | 3 | 0 | TBD |
| C, N=8 | 3 | 64 | read mux 60 (2:1 equiv.), decoder 16 outputs |
| C, N=16 | 4 | 160 | read mux 155, decoder 32 outputs |

## 2. Synthesis (Genus 25.1)

Constraints: clock `___` ns, I/O delay 30%.

| Design | Config | Flops | Cells | Area | Setup slack | Power (est.) | Run |
|---|---|---|---|---|---|---|---|
| A | | | | | | | |
| A' | | | | | | | |
| C | N=8, with `table_gen` | | | | | | |
| C | N=8, core only | | | | | | |
| C | N=16, with `table_gen` | | | | | | |

## 3. Place and route (Innovus 25.1)

| Design | Utilization | Core area | Worst setup | Worst hold | DRC | Connectivity | Run |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

## 4. Signoff (Tempus, Voltus, Pegasus)

| Design | fmax | Dynamic power | Leakage | DRC | LVS | Run |
|---|---|---|---|---|---|---|
| | | | | | | |

## 5. Experiments

| Experiment | Finding |
|---|---|
| Mealy vs Moore | |
| Fixed vs programmable | |
| `table_gen` area share | |
| Clock-period sweep | |
| Hand vs tool | |
| Critical path | |

## 6. Verification summary

| Check | Result |
|---|---|
| RTL simulation, N=8 and N=16 | pass, 0 errors (Icarus) |
| Xcelium regression | TBD |
| Coverage | TBD |
| Gate-level simulation | TBD |
