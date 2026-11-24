//============================================================================
// progseq_core : table-driven programmable Mealy FSM (design C)
//
//   address = {state, din}          entry = {match, next_state}
//   match   = enable & entry.match  (combinational Mealy output)
//   state  <= enable ? entry.next : 0
//
// - din is the LAST mux stage: din -> match crosses one 2:1 mux + one AND.
// - Table flops reset to 0 => "next = S0, match = 0".
// - lock is STICKY: once the lock input has been seen high, lock_q stays 1
//   until reset. Host writes are accepted only while enable=0 and not locked.
// - build (= busy of table_gen, from progseq_top) exempts table_gen's own
//   writes from the lock, so a lock raised in the middle of a build cannot
//   leave a half-written table (spec FR-16). A locked table can never START a
//   build (progseq_top rejects start), so this cannot modify a locked table.
//============================================================================
`timescale 1ns/1ps

module progseq_core #(
    parameter NUM_STATES = 8,                 // power of two
    parameter SW         = $clog2(NUM_STATES) // state bits
)(
    input               clk,
    input               rst_n,      // active-low, async assert
    input               enable,
    input               din,
    // table write port
    input               cfg_we,
    input  [SW:0]       cfg_addr,   // {state, din}
    input  [SW:0]       cfg_wdata,  // {match, next_state}
    input               lock,       // request: freeze table (sticky)
    input               build,      // table_gen owns the write port (busy)
    // outputs
    output              match,      // combinational Mealy output
    output reg          match_q,    // registered version
    output              locked      // table is frozen (lock seen since reset)
);
    localparam DEPTH = 2*NUM_STATES;

    reg [SW:0]   tbl [0:DEPTH-1];   // the "boxes"
    reg [SW-1:0] state;
    reg          lock_q;
    integer      n;

    assign locked = lock | lock_q;
    wire wr_ok = cfg_we & ~enable & (~locked | build);

    // ---------------- sticky lock ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)    lock_q <= 1'b0;
        else if (lock) lock_q <= 1'b1;
    end

    // ---------------- table storage ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (n = 0; n < DEPTH; n = n + 1)
                tbl[n] <= {(SW+1){1'b0}};
        end else if (wr_ok) begin
            tbl[cfg_addr] <= cfg_wdata;
        end
    end

    // ---------------- read: state picks the pair, din picks the entry ----
    wire [SW:0] e0    = tbl[{state, 1'b0}];
    wire [SW:0] e1    = tbl[{state, 1'b1}];
    wire [SW:0] entry = din ? e1 : e0;

    assign match = enable & entry[SW];

    // ---------------- state register ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)       state <= {SW{1'b0}};
        else if (!enable) state <= {SW{1'b0}};
        else              state <= entry[SW-1:0];
    end

    // ---------------- registered match ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) match_q <= 1'b0;
        else        match_q <= match;
    end
endmodule
