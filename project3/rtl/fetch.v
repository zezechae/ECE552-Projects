module fetch #(
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire        clk,
    input  wire        rst_n,                 // active-low, synchronous
    input  wire        i_clu_branch,
    input  wire        i_clu_halt,
    input  wire        i_alu_branch_taken,
    input  wire        i_clu_jump,            // JAL or JALR
    input  wire        i_clu_targetSrc,       // 1 = JALR (rs1 + imm), 0 = PC + imm
    input  wire [31:0] i_rf_rs1_rdata,
    input  wire [31:0] i_imm_o_immediate,
    input  wire        i_clu_trap,

    output wire [31:0] o_instr_mem_rd_addr,
    output wire [31:0] o_pc_plus_4,           // rd write-back for JAL/JALR
    output wire [31:0] o_target,              // branch/jump target (for misalignment trap)
    output wire        o_redirect,            // 1 when branch/jump is actually taken
    output wire [31:0] o_next_pc,             // goes to o_retire_next_pc
    output reg  [31:0] PC
);

    wire [31:0] base = i_clu_targetSrc ? i_rf_rs1_rdata : PC;
    wire [31:0] sum  = base + i_imm_o_immediate;
    assign o_target  = i_clu_targetSrc ? {sum[31:1], 1'b0} : sum;

    assign o_pc_plus_4 = PC + 32'd4;
    assign o_redirect  = i_clu_jump | (i_clu_branch & i_alu_branch_taken);

    wire   pc_redirect = o_redirect & ~i_clu_trap; 
    assign o_next_pc   = pc_redirect ? o_target : o_pc_plus_4;

    always @(posedge clk) begin
        if (!rst_n)
            PC <= RESET_ADDR;
        else if (!i_clu_halt)
            PC <= o_next_pc;
    end

    assign o_instr_mem_rd_addr = PC;

endmodule