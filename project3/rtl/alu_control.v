`default_nettype none
module alu_control (
    input  wire [1:0] i_ALUOp,      // 00 add, 01 branch, 10 R-type, 11 I-type ALU
    input  wire [2:0] i_funct3,     // inst[14:12]
    input  wire       i_funct7_5,   // inst[30]

    output wire [2:0] o_opsel,
    output wire       o_sub,
    output wire       o_unsigned,
    output wire       o_arith,
    output wire       o_bcomp,      // branch: 0 = use o_eq, 1 = use o_slt
    output wire       o_bnot        // branch: invert the selected flag
);

//All operations are divided into 4 categories: R, I , B, Other(Add)

wire is_branch = (i_ALUOp == 2'b01);
wire is_r      = (i_ALUOp == 2'b10);
wire is_i      = (i_ALUOp == 2'b11);
wire use_f3    = is_r | is_i;

assign o_sub = is_r & i_funct7_5; //For R type only
assign o_unsigned = is_branch ? i_funct3[1] : (use_f3 & i_funct3[0]);
assign o_arith = use_f3 & i_funct7_5; //For both R & I type

assign o_opsel = use_f3 ? i_funct3 : 3'b000;

assign o_bcomp = i_funct3[2]; //branch checking is not required as they are seperate outputs
assign o_bnot  = i_funct3[0];

endmodule

`default_nettype wire