`default_nettype none

module hart #(
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire        i_clk,
    input  wire        i_rst,
    output wire [31:0] o_imem_raddr,
    input  wire [31:0] i_imem_rdata,
    output wire [31:0] o_dmem_addr,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_wdata,
    output wire [ 3:0] o_dmem_mask,
    input  wire [31:0] i_dmem_rdata,
    output wire        o_retire_valid,
    output wire [31:0] o_retire_inst,
    output wire        o_retire_trap,
    output wire        o_retire_halt,
    output wire [ 4:0] o_retire_rs1_raddr,
    output wire [ 4:0] o_retire_rs2_raddr,
    output wire [31:0] o_retire_rs1_rdata,
    output wire [31:0] o_retire_rs2_rdata,
    output wire [ 4:0] o_retire_rd_waddr,
    output wire [31:0] o_retire_rd_wdata,
    output wire [31:0] o_retire_pc,
    output wire [31:0] o_retire_next_pc
`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);

    // ------------------------------------------------------------------
    // Instruction fields
    // ------------------------------------------------------------------
    wire [31:0] inst     = i_imem_rdata;
    wire [4:0]  rs1_addr = inst[19:15];
    wire [4:0]  rs2_addr = inst[24:20];
    wire [4:0]  rd_addr  = inst[11:7];
    wire [2:0]  funct3   = inst[14:12];

    // ------------------------------------------------------------------
    // Control unit (pure function of the instruction word)
    // ------------------------------------------------------------------
    wire        clu_branch, clu_jump, clu_target_src, clu_halt, clu_illegal;
    wire        clu_mem_read, clu_mem_write, clu_mem_to_reg, clu_reg_write;
    wire [1:0]  alu_src1_sel, alu_src2_sel, alu_op;
    wire [5:0]  imm_format;

    control_unit u_control (
        .i_clu_inst       (inst),
        .o_clu_Branch     (clu_branch),
        .o_clu_jump       (clu_jump),
        .o_clu_targetSrc  (clu_target_src),
        .o_clu_halt       (clu_halt),
        .o_clu_illegal    (clu_illegal),
        .o_clu_MemRead    (clu_mem_read),
        .o_clu_MemWrite   (clu_mem_write),
        .o_clu_MemtoReg   (clu_mem_to_reg),
        .o_clu_RegWrite   (clu_reg_write),
        .ALUSrc1          (alu_src1_sel),
        .ALUSrc2          (alu_src2_sel),
        .o_clu_ALUOp      (alu_op),
        .o_clu_imm_format (imm_format)
    );

    // ------------------------------------------------------------------
    // Immediate generator
    // ------------------------------------------------------------------
    wire [31:0] immediate;

    imm u_imm (
        .i_inst      (inst),
        .i_format    (imm_format),
        .o_immediate (immediate)
    );

    // ------------------------------------------------------------------
    // Register file (BYPASS_EN must be 0 in a single-cycle design)
    // ------------------------------------------------------------------
    wire [31:0] rs1_rdata, rs2_rdata;
    wire [31:0] rd_wdata;
    wire        rf_wen;

    rf #(.BYPASS_EN(0)) u_rf (
        .i_clk       (i_clk),
        .i_rst       (i_rst),
        .i_rs1_raddr (rs1_addr),
        .o_rs1_rdata (rs1_rdata),
        .i_rs2_raddr (rs2_addr),
        .o_rs2_rdata (rs2_rdata),
        .i_rd_wen    (rf_wen),
        .i_rd_waddr  (rd_addr),
        .i_rd_wdata  (rd_wdata)
    );

    // ------------------------------------------------------------------
    // ALU operand muxes
    //   src1: 00 rs1, 01 PC+4, 10 PC, 11 zero
    //   src2: 00 rs2, 01 imm,  10 zero (11 unused -> zero)
    // ------------------------------------------------------------------
    wire [31:0] pc, pc_plus_4, target_addr, next_pc;
    wire        redirect;

    wire [31:0] alu_op1 = (alu_src1_sel == 2'b00) ? rs1_rdata :
                          (alu_src1_sel == 2'b01) ? pc_plus_4 :
                          (alu_src1_sel == 2'b10) ? pc        : 32'b0;

    wire [31:0] alu_op2 = (alu_src2_sel == 2'b00) ? rs2_rdata :
                          (alu_src2_sel == 2'b01) ? immediate : 32'b0;

    // ------------------------------------------------------------------
    // ALU control + ALU
    // ------------------------------------------------------------------
    wire [2:0]  alu_opsel;
    wire        alu_sub, alu_unsigned, alu_arith, bcomp, bnot;
    wire [31:0] alu_result;
    wire        alu_eq, alu_slt;

    alu_control u_alu_control (
        .i_ALUOp    (alu_op),
        .i_funct3   (funct3),
        .i_funct7_5 (inst[30]),
        .o_opsel    (alu_opsel),
        .o_sub      (alu_sub),
        .o_unsigned (alu_unsigned),
        .o_arith    (alu_arith),
        .o_bcomp    (bcomp),
        .o_bnot     (bnot)
    );

    alu u_alu (
        .i_opsel    (alu_opsel),
        .i_sub      (alu_sub),
        .i_unsigned (alu_unsigned),
        .i_arith    (alu_arith),
        .i_op1      (alu_op1),
        .i_op2      (alu_op2),
        .o_result   (alu_result),
        .o_eq       (alu_eq),
        .o_slt      (alu_slt)
    );

    wire branch_taken = (bcomp ? alu_slt : alu_eq) ^ bnot;

    // ------------------------------------------------------------------
    // Trap detection
    // ------------------------------------------------------------------
    wire mem_misaligned;
    wire trap = clu_illegal | mem_misaligned | (redirect & (target_addr[1:0] != 2'b00));

    // ------------------------------------------------------------------
    // Fetch / PC
    // ------------------------------------------------------------------
    fetch #(.RESET_ADDR(RESET_ADDR)) u_fetch (
        .clk                 (i_clk),
        .rst_n               (~i_rst),
        .i_clu_branch        (clu_branch),
        .i_clu_halt          (clu_halt),
        .i_alu_branch_taken  (branch_taken),
        .i_clu_jump          (clu_jump),
        .i_clu_targetSrc     (clu_target_src),
        .i_rf_rs1_rdata      (rs1_rdata),
        .i_imm_o_immediate   (immediate),
        .i_clu_trap          (trap),
        .o_instr_mem_rd_addr (o_imem_raddr),
        .o_pc_plus_4         (pc_plus_4),
        .o_target            (target_addr),
        .o_redirect          (redirect),
        .o_next_pc           (next_pc),
        .PC                  (pc)
    );

    // ------------------------------------------------------------------
    // Data memory interface
    // ------------------------------------------------------------------
    wire [31:0] load_data;

    dmem_mask_gen u_mask_gen (
        .i_funct3     (inst[13:12]),
        .i_offset     (alu_result[1:0]),
        .i_is_mem     (clu_mem_read | clu_mem_write),
        .o_mask       (o_dmem_mask),
        .o_misaligned (mem_misaligned)
    );

    store_align u_store_align (
        .i_rs2_data (rs2_rdata),
        .i_funct3   (inst[13:12]),
        .i_offset   (alu_result[1:0]),
        .o_wdata    (o_dmem_wdata)
    );

    load_format u_load_format (
        .i_dmem_rdata (i_dmem_rdata),
        .i_funct3     (funct3),
        .i_offset     (alu_result[1:0]),
        .o_load_data  (load_data)
    );

    assign o_dmem_addr = {alu_result[31:2], 2'b00};
    assign o_dmem_ren  = clu_mem_read  & ~trap;
    assign o_dmem_wen  = clu_mem_write & ~trap;

    // ------------------------------------------------------------------
    // Write-back
    // ------------------------------------------------------------------
    assign rd_wdata = clu_mem_to_reg ? load_data : alu_result;
    assign rf_wen   = clu_reg_write & ~trap;

    // ------------------------------------------------------------------
    // Retire interface
    // ------------------------------------------------------------------
    assign o_retire_valid     = 1'b1;
    assign o_retire_inst      = inst;
    assign o_retire_trap      = trap;
    assign o_retire_halt      = clu_halt;
    assign o_retire_rs1_raddr = rs1_addr;
    assign o_retire_rs2_raddr = rs2_addr;
    assign o_retire_rs1_rdata = rs1_rdata;
    assign o_retire_rs2_rdata = rs2_rdata;
    assign o_retire_rd_waddr  = rf_wen ? rd_addr : 5'd0;
    assign o_retire_rd_wdata  = rd_wdata;
    assign o_retire_pc        = pc;
    assign o_retire_next_pc   = next_pc;

endmodule

`default_nettype wire
