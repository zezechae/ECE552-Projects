`default_nettype none

// The register file is effectively a single cycle memory with 32-bit words
// and depth 32. It has two asynchronous read ports, allowing two independent
// registers to be read at the same time combinationally, and one synchronous
// write port, allowing a register to be written to on the next clock edge.
// The register `x0` is hardwired to zero, and writes to it are ignored.
module rf #(
    // When this parameter is set to 1, "RF bypass" mode is enabled. This
    // allows data at the write port to be observed at the read ports
    // immediately without having to wait for the next clock edge. This is
    // a common forwarding optimization in a pipelined core (project 5), but
    // will cause a single-cycle processor to behave incorrectly.
    //
    // You are required to implement and test both modes. In project 3 and 4,
    // you will set this to 0, before enabling it in project 5.
    parameter BYPASS_EN = 0
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Both read register ports are asynchronous (zero-cycle). That is, read
    // data is visible combinationally without having to wait for a clock.
    //
    // Register read port 1, with input address [0, 31] and output data.
    input  wire [ 4:0] i_rs1_raddr,
    output wire [31:0] o_rs1_rdata,
    // Register read port 2, with input address [0, 31] and output data.
    input  wire [ 4:0] i_rs2_raddr,
    output wire [31:0] o_rs2_rdata,
    // The register write port is synchronous. When write is enabled, the
    // write data is visible after the next clock edge.
    //
    // Write register enable, address [0, 31] and input data.
    input  wire        i_rd_wen,
    input  wire [ 4:0] i_rd_waddr,
    input  wire [31:0] i_rd_wdata
);
    // TODO: Fill in your implementation here.
    reg [31:0] register_file [0:31];

    always @(posedge i_clk) begin
        if(i_rst) begin
            register_file[0] <= 32'b0;
            register_file[1] <= 32'b0;
            register_file[2] <= 32'b0;
            register_file[3] <= 32'b0;
            register_file[4] <= 32'b0;
            register_file[5] <= 32'b0;
            register_file[6] <= 32'b0;
            register_file[7] <= 32'b0;
            register_file[8] <= 32'b0;
            register_file[9] <= 32'b0;
            register_file[10] <= 32'b0;
            register_file[11] <= 32'b0;
            register_file[12] <= 32'b0;
            register_file[13] <= 32'b0;
            register_file[14] <= 32'b0;
            register_file[15] <= 32'b0;
            register_file[16] <= 32'b0;
            register_file[17] <= 32'b0;
            register_file[18] <= 32'b0;
            register_file[19] <= 32'b0;
            register_file[20] <= 32'b0;
            register_file[21] <= 32'b0;
            register_file[22] <= 32'b0;
            register_file[23] <= 32'b0;
            register_file[24] <= 32'b0;
            register_file[25] <= 32'b0;
            register_file[26] <= 32'b0;
            register_file[27] <= 32'b0;
            register_file[28] <= 32'b0;
            register_file[29] <= 32'b0;
            register_file[30] <= 32'b0;
            register_file[31] <= 32'b0;
        end
        else if(i_rd_wen && (i_rd_waddr != 5'b00000)) begin
            register_file[i_rd_waddr] <= i_rd_wdata;
        end
    end

    assign o_rs1_rdata = (i_rs1_raddr == 5'b0) ? 32'b0 : 
                         (i_rs1_raddr == i_rd_waddr && BYPASS_EN && i_rd_wen) ? i_rd_wdata : 
                         register_file[i_rs1_raddr];

    assign o_rs2_rdata = (i_rs2_raddr == 5'b0) ? 32'b0 : 
                         (i_rs2_raddr == i_rd_waddr && BYPASS_EN && i_rd_wen) ? i_rd_wdata : 
                         register_file[i_rs2_raddr];

endmodule

`default_nettype wire
