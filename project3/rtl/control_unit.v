`default_nettype none
module control_unit (
    input  wire [31:0] i_clu_inst,

    output wire        o_clu_Branch,
    output wire        o_clu_jump,
    output wire        o_clu_targetSrc,
    output wire        o_clu_halt,
    output wire        o_clu_illegal,
    output wire        o_clu_MemRead,
    output wire        o_clu_MemWrite,
    output wire        o_clu_MemtoReg,
    output wire        o_clu_RegWrite,
    output wire [1:0]  ALUSrc1,
    output wire [1:0]  ALUSrc2,
    output wire [1:0]  o_clu_ALUOp,
    output wire [5:0]  o_clu_imm_format
);

    wire [6:0] opcode = i_clu_inst[6:0];
    wire [2:0] funct3 = i_clu_inst[14:12];
    wire [6:0] funct7 = i_clu_inst[31:25];

    wire is_r      = (opcode == 7'b0110011);
    wire is_i_alu  = (opcode == 7'b0010011);
    wire is_load   = (opcode == 7'b0000011);
    wire is_store  = (opcode == 7'b0100011);
    wire is_branch = (opcode == 7'b1100011);
    wire is_jal    = (opcode == 7'b1101111);
    wire is_jalr   = (opcode == 7'b1100111);
    wire is_lui    = (opcode == 7'b0110111);
    wire is_auipc  = (opcode == 7'b0010111);
    wire is_ebreak = (i_clu_inst == 32'h00100073);

    // legality of the funct fields
    wire f7_zero  = (funct7 == 7'b0000000);
    wire f7_alt   = (funct7 == 7'b0100000);
    wire r_ok     = f7_zero | (f7_alt & ((funct3 == 3'b000) | (funct3 == 3'b101)));
    wire shift_i  = (funct3 == 3'b001) | (funct3 == 3'b101);
    wire i_ok     = ~shift_i | ((funct3 == 3'b001) ? f7_zero : (f7_zero | f7_alt));
    wire load_ok  = (funct3 == 3'b000) | (funct3 == 3'b001) | (funct3 == 3'b010) |
                    (funct3 == 3'b100) | (funct3 == 3'b101);
    wire store_ok = (funct3 == 3'b000) | (funct3 == 3'b001) | (funct3 == 3'b010);
    wire br_ok    = ~((funct3 == 3'b010) | (funct3 == 3'b011));
    //wire jalr_ok  = (funct3 == 3'b000); //Not mentioned in RV32 spec

    assign o_clu_illegal = ~((is_r & r_ok) | (is_i_alu & i_ok) | (is_load & load_ok) |
                             (is_store & store_ok) | (is_branch & br_ok) | is_jal |
                             (is_jalr) | is_lui | is_auipc | is_ebreak);

    // raw control signals; trap gating is done in hart
    assign o_clu_Branch    = is_branch;
    assign o_clu_jump      = is_jal | is_jalr;
    assign o_clu_targetSrc = is_jalr;
    assign o_clu_halt      = is_ebreak;
    assign o_clu_MemRead   = is_load;
    assign o_clu_MemWrite  = is_store;
    assign o_clu_MemtoReg  = is_load;
    assign o_clu_RegWrite  = is_r | is_i_alu | is_load | is_jal | is_jalr | is_lui | is_auipc;

    // 00 rs1, 01 PC+4, 10 PC, 11 zero
    assign ALUSrc1 = is_lui ? 2'b11 :
                     is_auipc ? 2'b10 :
                     (is_jal | is_jalr) ? 2'b01 : 2'b00;
    // 00 rs2, 01 imm, 10 zero
    assign ALUSrc2 = (is_r | is_branch) ? 2'b00 :
                     (is_jal | is_jalr) ? 2'b10 : 2'b01;

    // 00 add, 01 branch, 10 R-type, 11 I-type ALU
    // (00 add : LUI, AUIPC, LOAD, STORE, JAL, JALR)
    assign o_clu_ALUOp = is_r ? 2'b10 : is_i_alu ? 2'b11 : is_branch ? 2'b01 : 2'b00;

    // one-hot: [0]=R [1]=I [2]=S [3]=B [4]=U [5]=J
    assign o_clu_imm_format = {is_jal, (is_lui | is_auipc), is_branch, is_store,
                               (is_i_alu | is_load | is_jalr), is_r};
endmodule
`default_nettype wire