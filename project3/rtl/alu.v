`default_nettype none

module alu (
    input  wire [ 2:0] i_opsel,
    input  wire        i_sub,
    input  wire        i_unsigned,
    input  wire        i_arith,
    input  wire [31:0] i_op1,
    input  wire [31:0] i_op2,
    output wire [31:0] o_result,
    output wire        o_eq,
    output wire        o_slt
);
    reg [31:0] result_internal;
    assign o_result = result_internal;

    wire [4:0] shamt = i_op2[4:0];

    // Signed less-than via plain bit logic (no `signed` type, no $signed()).
    // For same-signed numbers, comparing raw bits as unsigned gives the
    // same order as signed comparison; only differing signs need special-casing.
    wire a_sign = i_op1[31];
    wire b_sign = i_op2[31];
    wire lt_unsigned = i_op1 < i_op2;
    wire slt_signed = (a_sign & ~b_sign) | ((a_sign ~^ b_sign) & lt_unsigned);

    assign o_slt = i_unsigned ? lt_unsigned : slt_signed;
    assign o_eq  = (i_op1 == i_op2);

    // Shift left logical - one constant-amount case per possible shamt value
    reg [31:0] sll_result;
    always @(*) begin
        case (shamt)
            5'd0: sll_result = i_op1;
            5'd1: sll_result = {i_op1[30:0], 1'b0};
            5'd2: sll_result = {i_op1[29:0], 2'b0};
            5'd3: sll_result = {i_op1[28:0], 3'b0};
            5'd4: sll_result = {i_op1[27:0], 4'b0};
            5'd5: sll_result = {i_op1[26:0], 5'b0};
            5'd6: sll_result = {i_op1[25:0], 6'b0};
            5'd7: sll_result = {i_op1[24:0], 7'b0};
            5'd8: sll_result = {i_op1[23:0], 8'b0};
            5'd9: sll_result = {i_op1[22:0], 9'b0};
            5'd10: sll_result = {i_op1[21:0], 10'b0};
            5'd11: sll_result = {i_op1[20:0], 11'b0};
            5'd12: sll_result = {i_op1[19:0], 12'b0};
            5'd13: sll_result = {i_op1[18:0], 13'b0};
            5'd14: sll_result = {i_op1[17:0], 14'b0};
            5'd15: sll_result = {i_op1[16:0], 15'b0};
            5'd16: sll_result = {i_op1[15:0], 16'b0};
            5'd17: sll_result = {i_op1[14:0], 17'b0};
            5'd18: sll_result = {i_op1[13:0], 18'b0};
            5'd19: sll_result = {i_op1[12:0], 19'b0};
            5'd20: sll_result = {i_op1[11:0], 20'b0};
            5'd21: sll_result = {i_op1[10:0], 21'b0};
            5'd22: sll_result = {i_op1[9:0], 22'b0};
            5'd23: sll_result = {i_op1[8:0], 23'b0};
            5'd24: sll_result = {i_op1[7:0], 24'b0};
            5'd25: sll_result = {i_op1[6:0], 25'b0};
            5'd26: sll_result = {i_op1[5:0], 26'b0};
            5'd27: sll_result = {i_op1[4:0], 27'b0};
            5'd28: sll_result = {i_op1[3:0], 28'b0};
            5'd29: sll_result = {i_op1[2:0], 29'b0};
            5'd30: sll_result = {i_op1[1:0], 30'b0};
            5'd31: sll_result = {i_op1[0:0], 31'b0};
            default: sll_result = 32'b0;
        endcase
    end

    // Shift right logical (fill with 0)
    reg [31:0] srl_result;
    always @(*) begin
        case (shamt)
            5'd0: srl_result = i_op1;
            5'd1: srl_result = {1'b0, i_op1[31:1]};
            5'd2: srl_result = {2'b0, i_op1[31:2]};
            5'd3: srl_result = {3'b0, i_op1[31:3]};
            5'd4: srl_result = {4'b0, i_op1[31:4]};
            5'd5: srl_result = {5'b0, i_op1[31:5]};
            5'd6: srl_result = {6'b0, i_op1[31:6]};
            5'd7: srl_result = {7'b0, i_op1[31:7]};
            5'd8: srl_result = {8'b0, i_op1[31:8]};
            5'd9: srl_result = {9'b0, i_op1[31:9]};
            5'd10: srl_result = {10'b0, i_op1[31:10]};
            5'd11: srl_result = {11'b0, i_op1[31:11]};
            5'd12: srl_result = {12'b0, i_op1[31:12]};
            5'd13: srl_result = {13'b0, i_op1[31:13]};
            5'd14: srl_result = {14'b0, i_op1[31:14]};
            5'd15: srl_result = {15'b0, i_op1[31:15]};
            5'd16: srl_result = {16'b0, i_op1[31:16]};
            5'd17: srl_result = {17'b0, i_op1[31:17]};
            5'd18: srl_result = {18'b0, i_op1[31:18]};
            5'd19: srl_result = {19'b0, i_op1[31:19]};
            5'd20: srl_result = {20'b0, i_op1[31:20]};
            5'd21: srl_result = {21'b0, i_op1[31:21]};
            5'd22: srl_result = {22'b0, i_op1[31:22]};
            5'd23: srl_result = {23'b0, i_op1[31:23]};
            5'd24: srl_result = {24'b0, i_op1[31:24]};
            5'd25: srl_result = {25'b0, i_op1[31:25]};
            5'd26: srl_result = {26'b0, i_op1[31:26]};
            5'd27: srl_result = {27'b0, i_op1[31:27]};
            5'd28: srl_result = {28'b0, i_op1[31:28]};
            5'd29: srl_result = {29'b0, i_op1[31:29]};
            5'd30: srl_result = {30'b0, i_op1[31:30]};
            5'd31: srl_result = {31'b0, i_op1[31:31]};
            default: srl_result = 32'b0;
        endcase
    end

    // Shift right arithmetic (fill with sign bit)
    reg [31:0] sra_result;
    always @(*) begin
        case (shamt)
            5'd0: sra_result = i_op1;
            5'd1: sra_result = {{1{i_op1[31]}}, i_op1[31:1]};
            5'd2: sra_result = {{2{i_op1[31]}}, i_op1[31:2]};
            5'd3: sra_result = {{3{i_op1[31]}}, i_op1[31:3]};
            5'd4: sra_result = {{4{i_op1[31]}}, i_op1[31:4]};
            5'd5: sra_result = {{5{i_op1[31]}}, i_op1[31:5]};
            5'd6: sra_result = {{6{i_op1[31]}}, i_op1[31:6]};
            5'd7: sra_result = {{7{i_op1[31]}}, i_op1[31:7]};
            5'd8: sra_result = {{8{i_op1[31]}}, i_op1[31:8]};
            5'd9: sra_result = {{9{i_op1[31]}}, i_op1[31:9]};
            5'd10: sra_result = {{10{i_op1[31]}}, i_op1[31:10]};
            5'd11: sra_result = {{11{i_op1[31]}}, i_op1[31:11]};
            5'd12: sra_result = {{12{i_op1[31]}}, i_op1[31:12]};
            5'd13: sra_result = {{13{i_op1[31]}}, i_op1[31:13]};
            5'd14: sra_result = {{14{i_op1[31]}}, i_op1[31:14]};
            5'd15: sra_result = {{15{i_op1[31]}}, i_op1[31:15]};
            5'd16: sra_result = {{16{i_op1[31]}}, i_op1[31:16]};
            5'd17: sra_result = {{17{i_op1[31]}}, i_op1[31:17]};
            5'd18: sra_result = {{18{i_op1[31]}}, i_op1[31:18]};
            5'd19: sra_result = {{19{i_op1[31]}}, i_op1[31:19]};
            5'd20: sra_result = {{20{i_op1[31]}}, i_op1[31:20]};
            5'd21: sra_result = {{21{i_op1[31]}}, i_op1[31:21]};
            5'd22: sra_result = {{22{i_op1[31]}}, i_op1[31:22]};
            5'd23: sra_result = {{23{i_op1[31]}}, i_op1[31:23]};
            5'd24: sra_result = {{24{i_op1[31]}}, i_op1[31:24]};
            5'd25: sra_result = {{25{i_op1[31]}}, i_op1[31:25]};
            5'd26: sra_result = {{26{i_op1[31]}}, i_op1[31:26]};
            5'd27: sra_result = {{27{i_op1[31]}}, i_op1[31:27]};
            5'd28: sra_result = {{28{i_op1[31]}}, i_op1[31:28]};
            5'd29: sra_result = {{29{i_op1[31]}}, i_op1[31:29]};
            5'd30: sra_result = {{30{i_op1[31]}}, i_op1[31:30]};
            5'd31: sra_result = {32{i_op1[31]}};
            default: sra_result = 32'b0;
        endcase
    end

    wire [31:0] shr_result = i_arith ? sra_result : srl_result;

    always @(*) begin
        result_internal = 32'b0;

        case (i_opsel)
        3'b000 : result_internal = i_sub ? i_op1 - i_op2 : i_op1 + i_op2;
        3'b001 : result_internal = sll_result;
        3'b010,
        3'b011 : result_internal = {31'b0, o_slt};
        3'b100 : result_internal = i_op1 ^ i_op2;
        3'b101 : result_internal = shr_result;
        3'b110 : result_internal = i_op1 | i_op2;
        3'b111 : result_internal = i_op1 & i_op2;
        default: result_internal = 32'b0;
        endcase
    end
endmodule

`default_nettype wire