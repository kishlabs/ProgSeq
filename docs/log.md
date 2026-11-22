# Work Log

One entry per session: what was done, what broke, how it was fixed, what is next. Bugs and their fixes are interview material, so keep them.

## 2026-11-22

- Wrote and simulated `table_gen`, `progseq_core`, `progseq_top` and the self-checking testbench; passes at N=8 and N=16.
- Measured `table_gen` build time: max 180 clocks (N=8) and 1000 (N=16) over random patterns.
- Created the repository scaffold: README, docs, Makefile, CI, `.gitignore`.
- Issue: the testbench failed to compile in SystemVerilog mode because `before` and `matches` are reserved words. Renamed the variables.
- Next: create the repo, send the ChipIN ticket, write design A.

- Architecture review (external AI tool) raised six issues; all confirmed against the RTL and fixed:
  - `lock` was a plain input in RTL but "until reset" in the docs. Made it sticky (`lock_q`, `locked` output).
  - A `start` under lock ran a useless build and still pulsed `done`. Now rejected with `start_err`.
  - `length` outside `1..N` was undefined. Now rejected at the top.
  - Moore decoded output is not glitch-free; claim corrected.
  - Arithmetic unit count understated; documented in full. `k`, `j` narrowed to `SW` bits (30 and 43 `table_gen` flops).
  - Write-port names unified: `tg_*` (table_gen), `ext_*` (host), `cfg_*` (core).
- Testbench bug found while retesting: the model kept history across `run_stream` calls while the DUT restarts at S0 when `enable` drops. Model now restarts with the stream.
- Measured exact worst-case build time: `1 + 4N + (N^2-1)(N+6)/6` = 42, 180, 1000 clocks for N = 4, 8, 16 (exhaustive simulation).
- RTL now simulates clean at N = 4, 8, 16, 32.

## Template

```text
## YYYY-MM-DD
- Done:
- Problems and fixes:
- Measurements:
- Next:
```
