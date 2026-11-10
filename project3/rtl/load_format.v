`default_nettype none
module load_format
(
    input wire[31:0] i_dmem_rdata,
    input wire[2:0]  i_funct3,
    input wire[1:0]  i_offset,

    output reg[31:0] o_load_data
);

always @(*) begin
    case({i_funct3[1:0], i_offset})
        4'b00_00: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[7:0]} : 
                                              {{24{i_dmem_rdata[7]}}, i_dmem_rdata[7:0]};
        4'b00_01: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[15:8]} : 
                                              {{24{i_dmem_rdata[15]}}, i_dmem_rdata[15:8]};
        4'b00_10: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[23:16]} : 
                                              {{24{i_dmem_rdata[23]}}, i_dmem_rdata[23:16]};
        4'b00_11: o_load_data = i_funct3[2] ? {24'b0, i_dmem_rdata[31:24]} : 
                                              {{24{i_dmem_rdata[31]}}, i_dmem_rdata[31:24]};
        4'b01_00,
        4'b01_01: o_load_data = i_funct3[2] ? {16'b0, i_dmem_rdata[15:0]} : 
                                              {{16{i_dmem_rdata[15]}}, i_dmem_rdata[15:0]};
        4'b01_10,
        4'b01_11: o_load_data = i_funct3[2] ? {16'b0, i_dmem_rdata[31:16]} : 
                                              {{16{i_dmem_rdata[31]}}, i_dmem_rdata[31:16]};
        4'b10_00,
        4'b10_01,
        4'b10_10,
        4'b10_11: o_load_data = i_dmem_rdata;
        default : o_load_data = 32'b0;
    endcase

end

endmodule 
`default_nettype wire