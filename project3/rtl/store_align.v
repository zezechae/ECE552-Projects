`default_nettype none
module store_align
(
    input  wire [31:0] i_rs2_data,
    input  wire [1:0]  i_funct3,    // inst[13:12]: 00 sb, 01 sh, 10 sw
    input  wire [1:0]  i_offset,    // alu result [1:0]

    output reg  [31:0] o_wdata
);

// Move the store data into the byte lane the access targets
// (the same lane that dmem_mask_gen enables). Constant shift amounts only.
always @(*) begin
    case ({i_funct3, i_offset})
        4'b00_00: o_wdata = i_rs2_data;
        4'b00_01: o_wdata = {i_rs2_data[23:0], 8'b0};
        4'b00_10: o_wdata = {i_rs2_data[15:0], 16'b0};
        4'b00_11: o_wdata = {i_rs2_data[7:0], 24'b0};
        4'b01_00,
        4'b01_01: o_wdata = i_rs2_data;
        4'b01_10,
        4'b01_11: o_wdata = {i_rs2_data[15:0], 16'b0};
        default : o_wdata = i_rs2_data;
    endcase
end

endmodule
`default_nettype wire