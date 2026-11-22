# Integration Guide

How to use `progseq_top` in a design or a testbench.

## 1. Instantiation

```verilog
progseq_top #(.NUM_STATES(8)) u_det (
    .clk(clk), .rst_n(rst_n),
    .enable(enable), .din(din),
    .start(start), .pattern(pattern), .length(length), .overlap(overlap),
    .ext_we(1'b0), .ext_addr({4{1'b0}}), .ext_wdata({4{1'b0}}),   // widths are log2(N)+1
    .lock(lock),
    .match(match), .match_q(match_q), .busy(busy), .done(done),
    .locked(locked), .start_err(start_err));
```

Source files: `rtl/progseq_top.v`, `rtl/progseq_core.v`, `rtl/table_gen.v`.

## 2. Clock and reset

- One clock, rising edge. All inputs must be synchronous to `clk`. If `din` comes from another clock domain, synchronise it (2 flip-flops) before this block; an on-chip synchronizer is planned for v1.1.
- `rst_n` is asynchronous-assert, active low. Release it synchronously to `clk` (use the SoC's reset synchronizer).
- Reset clears the detector state and the whole table.

## 3. Programming by pattern (recommended)

```text
cycle  action
  0    enable = 0
  1    pattern, length, overlap valid; start = 1
  2    start = 0 (busy rises)
  ...  wait for done (busy falls afterwards)
  n    enable = 1; stream din
```

- `pattern[k]` is the k-th bit **received**. For `1011`: `pattern = 8'b0000_1101`, `length = 4`.
- `length` must be between 1 and `NUM_STATES`. Otherwise (or if the table is locked) `start` is rejected and `start_err` pulses for one clock; nothing else changes.
- Check `start_err` (or wait for `done`) before assuming the pattern was loaded.
- Build time is at most 180 clocks for `NUM_STATES=8` and 1000 for 16 (see the specification).

## 4. Programming by table (host-controlled)

With `enable=0` and `lock=0`, write each box once:

```text
ext_addr  = {state, din}
ext_wdata = {match, next_state}
ext_we    = 1 for one clock
```

Use `scripts/` (planned) to generate the writes for any pattern. Unwritten entries behave as "next state 0, no match".

## 5. Detecting

`match` is high during the cycle in which the last bit of the pattern is present on `din`. It is combinational from `din`, so register it (or use `match_q`, which is `match` delayed by one clock) before using it across timing-critical boundaries.

## 6. Locking

Pulse or hold `lock` once: the table becomes read-only **until the next reset**, even if `lock` is released. `locked` reports the state. While locked, writes are ignored and `start` is rejected (`start_err` pulses). Use it after boot to prevent software from changing the detector.

## 7. Timing notes

- The path `din` to `match` is combinational. Constrain it with input and output delays.
- All other paths are register to register.

## 8. Limitations (v1.0)

- Single pattern, no wildcards (planned in v1.1 with the shift-register architecture).
- `NUM_STATES` is 8 or 16.
- `length` outside `1..NUM_STATES` is rejected.
