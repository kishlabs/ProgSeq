//============================================================================
// table_gen : builds the FSM table for a given pattern ("card writer")
//
// Convention : pattern[k] = k-th bit RECEIVED (first bit to arrive = pattern[0])
//              length    = number of valid bits, MUST satisfy 1 <= length <= NUM_STATES
//                          (progseq_top rejects any other value before start)
//              overlap   = 1 overlapping, 0 non-overlapping
//
// For every box (i = state, b = din):
//   received string = P[0..i-1], b
//   next  = longest k such that last k received bits == first k pattern bits
//           (k <= length-1 : a full match is never counted as the answer)
//   match = (i == length-1) && (b == P[length-1])
//   boxes with i >= length are written as 0 (clears any old pattern)
//
// Datapath registers : P, L, addr={i,b}, k ("Trying"), j ("which bit"), nxt
// Controller         : IDLE, SETUP, CMP, WRITE, DONE
// Width note         : k <= N-1 and j <= N-2, so SW bits suffice for both;
//                      pos wraps cleanly in SW bits (0 <= pos <= i-1 < N).
//============================================================================
module table_gen #(
    parameter NUM_STATES = 8,
    parameter SW         = $clog2(NUM_STATES)
)(
    input                    clk,
    input                    rst_n,
    input                    start,        // 1-clock pulse (ignored while busy)
    input  [NUM_STATES-1:0]  pattern,
    input  [SW:0]            length,
    input                    overlap,
    // table write port (tg_* : table_gen side, before the write-port mux)
    output                   tg_we,
    output [SW:0]            tg_addr,
    output [SW:0]            tg_wdata,
    output                   busy,
    output                   done
);
    localparam [2:0] IDLE = 3'd0, SETUP = 3'd1, CMP = 3'd2, WRITE = 3'd3, DONE = 3'd4;

    reg [2:0]            st;
    reg [NUM_STATES-1:0] P;
    reg [SW:0]           L;
    reg                  ovl;
    reg [SW:0]           addr;     // {i, b}
    reg [SW-1:0]         k;        // "Trying"
    reg [SW-1:0]         j;        // "which bit"
    reg [SW-1:0]         nxt;
    reg                  mreg;

    // ---------------- box being filled ----------------
    wire [SW-1:0] i     = addr[SW:1];
    wire          b     = addr[0];
    wire [SW:0]   i_ext = {1'b0, i};

    wire [SW:0]   lm1        = L - 1'b1;
    wire          last_state = (i_ext == lm1);
    wire          unused     = (i_ext >= L);
    wire          m_calc     = last_state & (b == P[lm1[SW-1:0]]);
    wire [SW:0]   kstart     = last_state ? i_ext : (i_ext + 1'b1);

    // ---------------- comparison datapath ----------------
    wire [SW:0]   k_ext    = {1'b0, k};
    wire [SW:0]   j_ext    = {1'b0, j};
    // During CMP with !last_col, 0 <= i+1-k+j <= i-1 < 2**SW, so SW-bit mod arithmetic is exact
    wire [SW-1:0] pos      = i + 1'b1 - k + j;
    wire          last_col = ((j_ext + 1'b1) == k_ext);   // this column is the new bit b
    wire          recv     = last_col ? b : P[pos];
    wire          pat      = P[j];
    wire          eq       = (recv == pat);

    // ---------------- controller + registers ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st   <= IDLE;
            P    <= {NUM_STATES{1'b0}};
            L    <= {(SW+1){1'b0}};
            ovl  <= 1'b1;
            addr <= {(SW+1){1'b0}};
            k    <= {SW{1'b0}};
            j    <= {SW{1'b0}};
            nxt  <= {SW{1'b0}};
            mreg <= 1'b0;
        end else begin
            case (st)
                IDLE: if (start) begin
                    P    <= pattern;
                    L    <= length;
                    ovl  <= overlap;
                    addr <= {(SW+1){1'b0}};
                    st   <= SETUP;
                end

                SETUP: begin
                    mreg <= m_calc;
                    if (unused || (m_calc && !ovl) || (kstart == 0)) begin
                        nxt <= {SW{1'b0}};
                        st  <= WRITE;
                    end else begin
                        k  <= kstart[SW-1:0];
                        j  <= {SW{1'b0}};
                        st <= CMP;
                    end
                end

                CMP: begin
                    if (eq) begin
                        if (last_col) begin           // all k bits matched
                            nxt <= k;
                            st  <= WRITE;
                        end else begin                // next column
                            j <= j + 1'b1;
                        end
                    end else begin
                        if (k == 1) begin             // no guess left -> 0
                            nxt <= {SW{1'b0}};
                            st  <= WRITE;
                        end else begin                // lower the guess, restart
                            k <= k - 1'b1;
                            j <= {SW{1'b0}};
                        end
                    end
                end

                WRITE: begin
                    if (&addr) st <= DONE;
                    else begin
                        addr <= addr + 1'b1;
                        st   <= SETUP;
                    end
                end

                DONE:    st <= IDLE;
                default: st <= IDLE;
            endcase
        end
    end

    // ---------------- outputs ----------------
    assign tg_we    = (st == WRITE);
    assign tg_addr  = addr;
    assign tg_wdata = {mreg, nxt};
    assign busy     = (st != IDLE);
    assign done     = (st == DONE);
endmodule
