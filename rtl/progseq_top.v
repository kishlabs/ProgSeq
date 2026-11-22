//============================================================================
// progseq_top : programmable sequence detector (soft IP top)
//
//  Program by pattern : give pattern/length/overlap, pulse start,
//                       wait for done, then set enable.
//  Program by table   : write boxes through ext_we/ext_addr/ext_wdata
//                       while enable=0 and not locked.
//
//  start is REJECTED (nothing happens, start_err pulses) when
//    - the table is locked, or
//    - length is 0 or greater than NUM_STATES.
//  While table_gen is busy the detector is held idle and the write port
//  belongs to table_gen. A lock raised during a build takes effect at once
//  (locked = 1) but the build completes (build = busy exempts table_gen's
//  writes from the lock), so the table is frozen complete at done (FR-16).
//============================================================================
module progseq_top #(
    parameter NUM_STATES = 8,
    parameter SW         = $clog2(NUM_STATES)
)(
    input                    clk,
    input                    rst_n,
    input                    enable,
    input                    din,
    // pattern programming (uses table_gen)
    input                    start,
    input  [NUM_STATES-1:0]  pattern,
    input  [SW:0]            length,
    input                    overlap,
    // direct table programming (external host)
    input                    ext_we,
    input  [SW:0]            ext_addr,
    input  [SW:0]            ext_wdata,
    input                    lock,
    // outputs
    output                   match,
    output                   match_q,
    output                   busy,
    output                   done,
    output                   locked,
    output                   start_err
);
    wire          tg_we;
    wire [SW:0]   tg_addr, tg_wdata;

    // ---------------- start qualification ----------------
    wire len_ok   = (length != {(SW+1){1'b0}}) && (length <= NUM_STATES);
    wire start_ok = start & ~busy & ~locked & len_ok;

    reg start_err_q;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) start_err_q <= 1'b0;
        else        start_err_q <= start & ~busy & (locked | ~len_ok);
    end
    assign start_err = start_err_q;

    // ---------------- table generator ----------------
    table_gen #(.NUM_STATES(NUM_STATES)) u_tg (
        .clk(clk), .rst_n(rst_n),
        .start(start_ok),
        .pattern(pattern), .length(length), .overlap(overlap),
        .tg_we(tg_we), .tg_addr(tg_addr), .tg_wdata(tg_wdata),
        .busy(busy), .done(done)
    );

    // ---------------- write-port mux (busy ? table_gen : external) --------
    wire          cfg_we    = busy ? tg_we    : ext_we;
    wire [SW:0]   cfg_addr  = busy ? tg_addr  : ext_addr;
    wire [SW:0]   cfg_wdata = busy ? tg_wdata : ext_wdata;

    // ---------------- core ----------------
    progseq_core #(.NUM_STATES(NUM_STATES)) u_core (
        .clk(clk), .rst_n(rst_n),
        .enable(enable & ~busy),
        .din(din),
        .cfg_we(cfg_we), .cfg_addr(cfg_addr), .cfg_wdata(cfg_wdata),
        .lock(lock), .build(busy),
        .match(match), .match_q(match_q), .locked(locked)
    );
endmodule
