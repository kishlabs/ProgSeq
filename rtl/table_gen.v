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
//   non-overlapping: the match word is written with next = 0
//
// Datapath (start-offset form):
//   A guess k is tried as a start offset s = (i+1) - k into the received
//   string. Column j compares received position p = s + j with P[j].
//     - the newest bit b sits at position i  -> last column  <=> p == i
//     - guess k = 1 is the last guess        <=> s == i
//     - on a full match the answer k = j + 1
//   s, p and j are plain registers updated by incrementers, so no
//   multi-operand adder sits in front of the P[p] selector.
//   The register holding length-1 (Lm1) replaces length: it needs SW bits and
//   removes the L-1 decrementer from the SETUP decision path.
// Controller : IDLE, SETUP, CMP, WRITE, DONE
//============================================================================
`timescale 1ns/1ps

module table_gen #(
    parameter NUM_STATES = 8,                 // power of two, >= 4
    parameter SW         = $clog2(NUM_STATES)
)(
    input                    clk,
    input                    rst_n,
    input                    start,        // 1-clock pulse (qualified by progseq_top)
    input  [NUM_STATES-1:0]  pattern,
    // verilator lint_off UNUSEDSIGNAL
    input  [SW:0]            length,       // MSB only marks length = N (low bits 0): not needed
    // verilator lint_on UNUSEDSIGNAL
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
    reg [SW-1:0]         Lm1;      // length - 1  (0 .. N-1)
    reg                  ovl;
    reg [SW:0]           addr;     // {i, b}
    reg [SW-1:0]         s;        // start offset of the current guess
    reg [SW-1:0]         p;        // received position compared now (s + j)
    reg [SW-1:0]         j;        // column
    reg [SW-1:0]         nxt;
    reg                  mreg;

    // ---------------- box being filled ----------------
    wire [SW-1:0] i          = addr[SW:1];
    wire          b          = addr[0];
    wire          last_state = (i == Lm1);
    wire          unused     = (i > Lm1);
    wire          m_calc     = last_state & (b == P[Lm1]);
    wire          no_guess   = last_state & (i == {SW{1'b0}});   // length = 1

    // ---------------- comparison datapath ----------------
    wire          last_col = (p == i);            // received position p is the new bit b
    wire          s_is_i   = (s == i);            // current guess is k = 1 (the last one)
    wire          recv     = last_col ? b : P[p];
    wire          pat      = P[j];
    wire          eq       = (recv == pat);

    wire [SW-1:0] s_inc    = s + 1'b1;
    wire [SW-1:0] j_inc    = j + 1'b1;

    // ---------------- controller + registers ----------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st   <= IDLE;
            P    <= {NUM_STATES{1'b0}};
            Lm1  <= {SW{1'b0}};
            ovl  <= 1'b1;
            addr <= {(SW+1){1'b0}};
            s    <= {SW{1'b0}};
            p    <= {SW{1'b0}};
            j    <= {SW{1'b0}};
            nxt  <= {SW{1'b0}};
            mreg <= 1'b0;
        end else begin
            case (st)
                IDLE: if (start) begin
                    P    <= pattern;
                    Lm1  <= length[SW-1:0] - 1'b1;   // exact for 1..N (N wraps to N-1)
                    ovl  <= overlap;
                    addr <= {(SW+1){1'b0}};
                    st   <= SETUP;
                end

                SETUP: begin
                    mreg <= m_calc;
                    if (unused || no_guess) begin
                        nxt <= {SW{1'b0}};
                        st  <= WRITE;
                    end else begin
                        // first guess: k = i+1 (s = 0), or k = i in the last state (s = 1)
                        s  <= {{(SW-1){1'b0}}, last_state};
                        p  <= {{(SW-1){1'b0}}, last_state};
                        j  <= {SW{1'b0}};
                        st <= CMP;
                    end
                end

                CMP: begin
                    if (eq) begin
                        if (last_col) begin           // all k bits matched: answer k = j + 1
                            nxt <= j_inc;
                            st  <= WRITE;
                        end else begin                // next column
                            j <= j_inc;
                            p <= p + 1'b1;
                        end
                    end else begin
                        if (s_is_i) begin             // no guess left -> 0
                            nxt <= {SW{1'b0}};
                            st  <= WRITE;
                        end else begin                // shorter guess: s + 1, restart columns
                            s <= s_inc;
                            p <= s_inc;
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
    // Non-overlapping mode: the match word returns to state 0. Applied here, on the
    // registered mreg, so that the SETUP decision does not depend on the P[Lm1] selector.
    wire          zero_next = mreg & ~ovl;
    assign tg_wdata = {mreg, nxt & {SW{~zero_next}}};
    assign busy     = (st != IDLE);
    assign done     = (st == DONE);
endmodule
