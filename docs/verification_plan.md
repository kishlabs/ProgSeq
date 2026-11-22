# Verification Plan

Verification is the supporting pillar (about 15% of effort), kept lean but airtight: a weak testbench would make every later PD number untrustworthy.

## 1. Strategy

| Layer | What | Tool |
|---|---|---|
| Self-checking simulation | Directed plus constrained-random tests against an **independent** reference model | Icarus (home), Xcelium (lab) |
| Equivalence by simulation | C loaded with the 1011 table versus A, compared every cycle | same |
| Assertions | Small set of SVA properties | Xcelium |
| Coverage | State and transition coverage | Xcelium |
| Gate-level simulation | Genus netlist with the same testbench | Xcelium |
| Lint | Synthesizability and style | `make lint`, later HAL |

Independence of the reference model: the testbench compares `match` against a **sliding window** of the last `L` bits. It does not use the table method that `table_gen` implements, so a bug in `table_gen` cannot hide by agreeing with itself.

## 2. Testbench structure (`tb/tb_progseq.v`)

```text
program task  ->  DUT (progseq_top)  <-  din stream (random + injected pattern)
                       |
                match / match_q
                       |
      compare each cycle with the window model -> PASS / FAIL, error and match counts
```

Stimulus: random bits with the pattern injected about one time in six, because long patterns almost never occur in pure random data. Final pass requires zero errors and more than 100 matches (so a vacuous run cannot pass).

## 3. Requirement traceability

| Requirement | Check | Status |
|---|---|---|
| FR-1, FR-4 | Random streams, `match` compared every cycle | Done (C) |
| FR-2 | Random lengths 1..`NUM_STATES`, directed 1 and N | Done (C) |
| FR-3 | Directed overlap vs non-overlap on `1011011`; random both modes | Done (C) |
| FR-5 | `match_q` equals previous-cycle `match` | Done (C) |
| FR-6 | `enable=0` behaviour | Partial: add explicit directed test |
| FR-7 | Reset clears state and table | Partial: reset then external load is exercised; add reset-clears-table check |
| FR-8 | Sticky lock: start rejected, external writes ignored, lock survives release, reset clears it | Done (C) |
| FR-9 | Writes blocked while `enable=1`; detector idle while `busy` | To do |
| FR-10 | Table written by `table_gen` equals golden table; old pattern leaves no residue | Residue: done. Table equality: To do (T-34) |
| FR-11 | External write path loads 1011 | Done |
| FR-12 | N=4, 8, 16, 32 | Done (simulation) |
| FR-15 | Invalid length (0, N+1, 2N-1) and locked start rejected with a one-clock `start_err`, old table intact | Done (C) |
| FR-13 | Moore output one cycle after Mealy | To do (T-33) |
| FR-14 | A equals C loaded with 1011 table, every cycle | To do (T-32) |

## 4. Directed tests

| Test | Expected |
|---|---|
| 1011 overlapping, stream `1011011` | matches at bit 4 and 7 |
| 01110, stream `011101110` | 2 matches |
| 1011 non-overlapping, stream `1011011` | 1 match |
| Near-misses `1010`, `1001`, `11011` | no match |
| Back-to-back `10111011` | 2 matches |
| Reset in the middle of a pattern | restart from state 0 |
| `enable` low then high mid-stream | no match while low; state restarts |
| `length=1`, `length=NUM_STATES` | match per model |
| Pattern change after an old pattern | old pattern no longer detected |
| `lock=1`, new `start` | old pattern still detected |

## 5. Assertions (planned, T-35)

| Property | Meaning |
|---|---|
| `match` implies `enable` | no match while disabled |
| No X on `match`, `match_q`, `busy`, `done` after reset | clean outputs |
| `done` only after `busy` | handshake order |
| Table unchanged while `lock` | lock holds |
| `enable=0` implies next state 0 | idle behaviour |

## 6. Coverage goals (T-36)

100% of FSM states and transitions of A, A' and the `table_gen` controller; toggle coverage reported. Core table entries are data, so the equivalent measure is "every entry of the loaded table was read" for the directed patterns.

## 7. Gate-level simulation

The Genus netlist is simulated with the same testbench (cell Verilog models from the library). Outputs must match RTL. This also produces the switching activity file for Voltus.

## 8. Bug log

Record real bugs and which check caught them in [`log.md`](log.md). Example already logged: none yet.

## 9. Exit criteria

All checks above pass in Xcelium for A, A' and C at N=8 and N=16; coverage goals met; gate-level results equal RTL.
