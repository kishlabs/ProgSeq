`timescale 1ns/1ps
//============================================================================
// Self-checking testbench for progseq_top
// Reference model: sliding window of the last L bits compared with the
// pattern (independent of the table method used by the DUT).
// Parameter N = NUM_STATES (power of two, >= 4).
//============================================================================
module tb_progseq;
    parameter N  = 8;
    localparam SW = $clog2(N);

    reg clk = 0, rst_n = 0, enable = 0, din = 0, start = 0, overlap = 1, lock = 0;
    reg ext_we = 0;
    reg [N-1:0] pattern = 0;
    reg [SW:0]  length = 1, ext_addr = 0, ext_wdata = 0;
    wire match, match_q, busy, done, locked, start_err;

    progseq_top #(.NUM_STATES(N)) dut (
        .clk(clk), .rst_n(rst_n), .enable(enable), .din(din),
        .start(start), .pattern(pattern), .length(length), .overlap(overlap),
        .ext_we(ext_we), .ext_addr(ext_addr), .ext_wdata(ext_wdata), .lock(lock),
        .match(match), .match_q(match_q), .busy(busy), .done(done),
        .locked(locked), .start_err(start_err));

    always #5 clk = ~clk;

    integer errors = 0, checks = 0, nmatch = 0, nreject = 0;

    // ---------------- reference model state ----------------
    reg [N-1:0] hist, mP;
    integer     cnt, mL;
    reg         mOvl;
    reg         prev_exp, prev_valid;

    task fail(input [255:0] msg);
        begin errors = errors + 1; $display("ERR %0s t=%0t", msg, $time); end
    endtask

    // ---------------- program the DUT through table_gen ----------------
    task program_dut(input [N-1:0] p, input integer l, input ovl);
        begin
            @(negedge clk); enable = 0; pattern = p; length = l; overlap = ovl; start = 1;
            @(negedge clk); start = 0;
            wait (done);
            @(negedge clk); @(negedge clk);
        end
    endtask

    task set_model(input [N-1:0] p, input integer l, input ovl);
        begin mP = p; mL = l; mOvl = ovl; hist = 0; cnt = 0; prev_valid = 0; end
    endtask

    task program_pattern(input [N-1:0] p, input integer l, input ovl);
        begin program_dut(p, l, ovl); set_model(p, l, ovl); end
    endtask

    // start with an invalid length or while locked: must be rejected
    task try_start_reject(input integer l);
        begin
            @(negedge clk); enable = 0; length = l; start = 1;
            @(negedge clk); start = 0;
            if (start_err !== 1'b1 || busy !== 1'b0 || done !== 1'b0) fail("start not rejected");
            @(negedge clk);
            if (start_err !== 1'b0 || busy !== 1'b0) fail("start_err not a single pulse");
            nreject = nreject + 1;
        end
    endtask

    // ---------------- one clock: drive bit, check match ----------------
    task step(input bitv);
        reg [N-1:0] nh;
        reg expv;
        integer m;
        begin
            @(negedge clk);
            if (prev_valid && (match_q !== prev_exp)) begin
                errors = errors + 1;
                $display("ERR match_q t=%0t exp=%b got=%b", $time, prev_exp, match_q);
            end
            din = bitv; enable = 1; #1;
            nh   = {hist[N-2:0], bitv};
            expv = (cnt + 1 >= mL);
            for (m = 0; m < mL; m = m + 1)
                if (nh[m] !== mP[mL-1-m]) expv = 0;
            checks = checks + 1;
            if (match !== expv) begin
                errors = errors + 1;
                $display("ERR match t=%0t L=%0d pat=%b ovl=%b exp=%b got=%b",
                         $time, mL, mP, mOvl, expv, match);
            end
            if (expv) nmatch = nmatch + 1;
            hist = nh; cnt = cnt + 1;
            if (expv && !mOvl) cnt = 0;
            prev_exp = expv; prev_valid = 1;
        end
    endtask

    task run_stream(input integer n);
        integer t, m;
        begin
            // enable restarts the detector at S0, so the model restarts too
            hist = 0; cnt = 0; prev_valid = 0;
            t = 0;
            while (t < n) begin
                if (($urandom % 6) == 0) begin           // inject the pattern
                    for (m = 0; m < mL; m = m + 1) begin step(mP[m]); t = t + 1; end
                end else begin
                    step($urandom % 2); t = t + 1;
                end
            end
            @(negedge clk); prev_valid = 0; enable = 0; din = 0;
        end
    endtask

    task ext_write(input integer a, input m, input integer nx);
        begin
            @(negedge clk); ext_we = 1; ext_addr = a; ext_wdata = (m << SW) | nx;
            @(negedge clk); ext_we = 0;
        end
    endtask

    integer trial, m_start, l;
    reg [N-1:0] p;

    initial begin
        #1; hist = 0; cnt = 0; mL = 1; mP = 0; mOvl = 1; prev_valid = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;

        // ---- directed 1: 1011 overlapping, stream 1011011 -> 2 matches
        // pattern[k] = k-th received bit -> P0..P3 = 1,0,1,1 -> 4'b1101
        program_pattern(8'b0000_1101, 4, 1);
        m_start = nmatch;
        step(1); step(0); step(1); step(1); step(0); step(1); step(1);
        if (nmatch - m_start != 2) begin errors = errors + 1; $display("ERR directed 1011: %0d matches", nmatch - m_start); end
        else $display("directed 1011011 -> 2 matches OK");

        // ---- directed 2: 01110 (palindrome), needs N >= 5
        if (N >= 5) begin
            program_pattern(8'b0000_1110, 5, 1);
            m_start = nmatch; step(0); step(1); step(1); step(1); step(0);
            step(1); step(1); step(1); step(0);
            if (nmatch - m_start != 2) begin errors = errors + 1; $display("ERR directed 01110: %0d", nmatch - m_start); end
            else $display("directed 011101110 -> 2 matches OK");
        end

        // ---- directed 3: 1011 non-overlapping, stream 1011011 -> 1 match
        program_pattern(8'b0000_1101, 4, 0);
        m_start = nmatch;
        step(1); step(0); step(1); step(1); step(0); step(1); step(1);
        if (nmatch - m_start != 1) begin errors = errors + 1; $display("ERR non-overlap: %0d", nmatch - m_start); end
        else $display("non-overlap 1011011 -> 1 match OK");

        // ---- random patterns, lengths 1..N, both modes (junk above length)
        for (trial = 0; trial < 200; trial = trial + 1) begin
            p = $urandom; l = 1 + ($urandom % N);
            program_pattern(p, l, $urandom % 2);
            run_stream(400);
        end

        // ---- extreme lengths and pattern change (old table must be cleared)
        program_pattern({N{1'b1}}, N, 1); run_stream(200);
        program_pattern(1, 1, 1);         run_stream(200);

        // ---- invalid length: rejected, old table untouched
        program_pattern(8'b0000_1101, 4, 1);
        try_start_reject(0);
        try_start_reject(N + 1);
        try_start_reject((2*N) - 1);
        run_stream(300);
        $display("invalid-length starts rejected, old pattern intact");

        // ---- sticky lock: start rejected, ext writes ignored, lock survives lock=0
        @(negedge clk); lock = 1;
        @(negedge clk);
        if (locked !== 1'b1) fail("locked not set");
        try_start_reject(3);
        ext_write(1, 1, 1);                      // must be ignored
        run_stream(300);                         // still detects 1011
        lock = 0;
        @(negedge clk);
        if (locked !== 1'b1) fail("lock not sticky");
        try_start_reject(3);
        run_stream(100);
        // reset clears lock and table
        @(negedge clk); rst_n = 0; @(negedge clk); rst_n = 1; @(negedge clk);
        if (locked !== 1'b0) fail("reset did not clear lock");
        $display("sticky lock behaviour OK");

        // ---- FR-16: lock raised in the middle of a build -> build completes, table complete
        // (table is all-zero after the reset above, so any dropped write is visible)
        @(negedge clk); enable = 0; pattern = {N{1'b0}}; length = N; overlap = 1; start = 1;
        @(negedge clk); start = 0;
        repeat (5) @(negedge clk);
        if (busy !== 1'b1) fail("build not running");
        lock = 1;
        wait (done);
        @(negedge clk); @(negedge clk);
        if (locked !== 1'b1) fail("lock request lost");
        set_model({N{1'b0}}, N, 1);
        run_stream(400);
        lock = 0;
        $display("lock during build: table complete OK");
        @(negedge clk); rst_n = 0; @(negedge clk); rst_n = 1; @(negedge clk);

        // ---- external table write (no table_gen): load 1011 by hand
        ext_write(0, 0, 0); ext_write(1, 0, 1); ext_write(2, 0, 2); ext_write(3, 0, 1);
        ext_write(4, 0, 0); ext_write(5, 0, 3); ext_write(6, 0, 2); ext_write(7, 1, 1);
        set_model(8'b0000_1101, 4, 1);
        run_stream(300);

        // ---- FR-6: enable = 0 -> match = 0 even with the pattern on din
        // length 1 is the case where state 0 itself carries a match word, so only the
        // enable gate keeps match low
        program_pattern(8'b0000_0001, 1, 1);
        @(negedge clk); enable = 0; din = 1; #1;
        if (match !== 1'b0) fail("match while enable=0 (length 1)");
        program_pattern(8'b0000_1101, 4, 1);
        begin : en_low
            integer q; reg [3:0] seq; seq = 4'b1101;          // 1,0,1,1 in time order (seq[0] first)
            for (q = 0; q < 4; q = q + 1) begin
                @(negedge clk); enable = 0; din = seq[q]; #1;
                if (match !== 1'b0) fail("match while enable=0");
            end
        end

        // ---- FR-7: reset clears the table (pattern no longer detected)
        @(negedge clk); rst_n = 0; @(negedge clk); rst_n = 1; @(negedge clk);
        begin : rst_tbl
            integer q; reg [3:0] seq; seq = 4'b1101;
            for (q = 0; q < 4; q = q + 1) begin
                @(negedge clk); enable = 1; din = seq[q]; #1;
                if (match !== 1'b0) fail("match after reset cleared the table");
            end
            @(negedge clk); enable = 0; din = 0;
        end

        // ---- FR-9: host writes ignored while enable = 1
        program_pattern(8'b0000_1101, 4, 1);
        @(negedge clk); enable = 1; din = 0;                  // S0 stays S0 on 0
        ext_write(1, 1, 1);                                   // would make (S0,1) a match if accepted
        run_stream(300);

        // ---- FR-17 / FR-18: handshake timing; start while busy ignored; inputs latched
        @(negedge clk); rst_n = 0; @(negedge clk); rst_n = 1; @(negedge clk);
        @(negedge clk); enable = 0; pattern = 8'b0000_1101; length = 4; overlap = 1; start = 1;
        @(negedge clk); start = 0;
        if (busy !== 1'b1) fail("busy not high in the cycle after start");
        pattern = 8'b0000_0110; length = 3; start = 1;        // second start while busy, other pattern
        @(negedge clk); start = 0;
        if (start_err !== 1'b0) fail("start while busy flagged as error");
        wait (done);
        @(negedge clk);
        if (done !== 1'b1 || busy !== 1'b1) fail("done must be the last busy cycle");
        @(negedge clk);
        if (done !== 1'b0 || busy !== 1'b0) fail("busy/done not cleared after the done cycle");
        set_model(8'b0000_1101, 4, 1);                        // first start won; inputs were latched
        run_stream(300);

        // ---- FR-19: valid start while enable = 1 interrupts detection, resumes from S0
        program_pattern(8'b0000_1101, 4, 1);
        @(negedge clk); enable = 1; din = 1;
        @(negedge clk); pattern = 8'b0000_0110; length = 3; overlap = 1; start = 1;   // new pattern 0,1,1
        @(negedge clk); start = 0;
        while (!done) begin
            @(negedge clk);
            if (match !== 1'b0) fail("match during build");
        end
        @(negedge clk);                                       // first active cycle: din = 1 keeps S0
        set_model(8'b0000_0110, 3, 1);
        run_stream(300);
        $display("directed FR-6/7/9/17/18/19 OK");

        $display("-----------------------------------------");
        $display("N=%0d checks=%0d matches=%0d rejects=%0d errors=%0d", N, checks, nmatch, nreject, errors);
        if (errors == 0 && nmatch > 100 && nreject == 5) $display("PASS");
        else                                             $display("FAIL");
        $finish;
    end

    initial begin #2_000_000_000; $display("FAIL: timeout"); $finish; end
endmodule
