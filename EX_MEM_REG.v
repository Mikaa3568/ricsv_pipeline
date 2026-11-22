// ============================================================================
// EX_MEM_REG.v - Pipeline Register between EX and MEM Stages
// ============================================================================

`timescale 1ns/1ps

module EX_MEM_REG (
    input             clock,
    input             reset,
    // Control signals in
    input             ex_regwrite,
    input      [1:0]  ex_memtoreg,
    input             ex_memread,
    input             ex_memwrite,
    // Data signals in
    input      [31:0] ex_alu_result,
    input      [31:0] ex_write_data,
    input      [4:0]  ex_rs2,
    input      [4:0]  ex_rd,
    input      [31:0] ex_pc_plus_4,
    input      [2:0]  ex_funct3,
    // Control signals out
    output reg        mem_regwrite,
    output reg [1:0]  mem_memtoreg,
    output reg        mem_memread,
    output reg        mem_memwrite,
    // Data signals out
    output reg [31:0] mem_alu_result,
    output reg [31:0] mem_write_data,
    output reg [4:0]  mem_rs2,
    output reg [4:0]  mem_rd,
    output reg [31:0] mem_pc_plus_4,
    output reg [2:0]  mem_funct3
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            mem_regwrite   <= 1'b0;
            mem_memtoreg   <= 2'b00;
            mem_memread    <= 1'b0;
            mem_memwrite   <= 1'b0;

            mem_alu_result <= 32'd0;
            mem_write_data <= 32'd0;
            mem_rs2        <= 5'd0;
            mem_rd         <= 5'd0;
            mem_pc_plus_4  <= 32'd0;
            mem_funct3     <= 3'b000;
        end
        else begin
            mem_regwrite   <= ex_regwrite;
            mem_memtoreg   <= ex_memtoreg;
            mem_memread    <= ex_memread;
            mem_memwrite   <= ex_memwrite;

            mem_alu_result <= ex_alu_result;
            mem_write_data <= ex_write_data;
            mem_rs2        <= ex_rs2;
            mem_rd         <= ex_rd;
            mem_pc_plus_4  <= ex_pc_plus_4;
            mem_funct3     <= ex_funct3;
        end
    end

endmodule