# Glossary and Conventions

| Term | Meaning |
|---|---|
| Soft IP | A reusable design delivered as synthesizable RTL (plus testbench, constraints, docs) |
| Mealy FSM | Output depends on state **and** current input; drawn on transitions |
| Moore FSM | Output depends on state only |
| State | Number of pattern bits currently matched (state `i` = last `i` bits equal `P0..P(i-1)`) |
| Table / box / card | The set of `(state, din)` entries `{match, next_state}` the core stores; one entry is a "box" |
| Card writer | `table_gen`, the block that computes the table |
| Suffix rule | Next state = longest ending of (bits seen + `din`) that is also a beginning of the pattern |
| Overlapping | A match may start inside the previous match |
| `pattern[k]` | The k-th bit received (first received bit at index 0) |
| Trying (`k`) | In `table_gen`, the current guess for the next state |
| `j` | In `table_gen`, the column currently compared |
| PDK | Process Design Kit: foundry data for a technology |
| Standard cell | Pre-designed gate/flip-flop used by synthesis and P&R |
| `.lib` / LEF / QRC / GDS | Timing / abstract layout / parasitic / final layout views |
| MMMC | Multi-mode multi-corner setup in Innovus |
| SDC | Synopsys Design Constraints (timing constraints) |
| STA | Static timing analysis |
| CTS | Clock tree synthesis |
| DRC / LVS | Design rule check / layout versus schematic |
| GDS | Final layout stream file |
| Critical path | The path that limits the clock frequency or I/O timing |

Naming: modules `snake_case`; active-low signals end in `_n`; parameters upper case; one module per file named after the module.
