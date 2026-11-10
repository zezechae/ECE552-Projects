`default_nettype none
module dmem_mask_gen
(
    input wire[1:0] i_funct3,
    input wire[1:0] i_offset,
    input wire      i_is_mem, //load or store

    output reg[3:0] o_mask,   
    output wire     o_misaligned
);

//For byte o_mask : 0001, 0010, 0100, 1000
//For half word   : 0011, 1100
//For word        : 1111

//i_offset
//i_funct3 : 000 => byte, 001 => half-word, 010 => word

/*o_misaligned:
Half is misaligned when offset[0] == 1.
Word is misaligned when offset[1:0] != 2'b00.
Byte is never misaligned.
The result is valid only when i_is_mem is set, so it stays 0 for non-memory instructions.*/

assign o_misaligned = (((i_funct3 == 2'b01) & i_offset[0]) | 
                      ((i_funct3 == 2'b10) & (i_offset[1:0]!=2'b00))) & i_is_mem;

always @(*) begin
    case ({i_funct3, i_offset})
        4'b00_00: o_mask = 4'b0001;
        4'b00_01: o_mask = 4'b0010;
        4'b00_10: o_mask = 4'b0100;
        4'b00_11: o_mask = 4'b1000;
        4'b01_00,
        4'b01_01: o_mask = 4'b0011;
        4'b01_10,
        4'b01_11: o_mask = 4'b1100;
        4'b10_00,
        4'b10_01,
        4'b10_10,
        4'b10_11: o_mask = 4'b1111;
        default : o_mask = 4'b0000;
    endcase
end

endmodule
`default_nettype wire