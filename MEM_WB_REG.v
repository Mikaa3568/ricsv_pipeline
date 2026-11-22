// ============================================================================
// MEM_WB_REG.v - Pipeline Register between MEM and WB Stages
// ============================================================================

`timescale 1ns/1ps

module MEM_WB_REG (
    input             clock,
    input             reset,
    // Control signals in
    input             mem_regwrite,
    input      [1:0]  mem_memtoreg,
    // Data signals in
    input      [31:0] mem_alu_result,
    input      [31:0] mem_read_data,
    input      [31:0] mem_pc_plus_4,
    input      [4:0]  mem_rd,
    // Control signals out
    output reg        wb_regwrite,
    output reg [1:0]  wb_memtoreg,
    // Data signals out
    output reg [31:0] wb_alu_result,
    output reg [31:0] wb_read_data,
    output reg [31:0] wb_pc_plus_4,
    output reg [4:0]  wb_rd
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            wb_regwrite   <= 1'b0;
            wb_memtoreg   <= 2'b00;
            wb_alu_result <= 32'd0;
            wb_read_data  <= 32'd0;
            wb_pc_plus_4  <= 32'd0;
            wb_rd         <= 5'd0;
        end
        else begin
            wb_regwrite   <= mem_regwrite;
            wb_memtoreg   <= mem_memtoreg;
            wb_alu_result <= mem_alu_result;
            wb_read_data  <= mem_read_data;
            wb_pc_plus_4  <= mem_pc_plus_4;
            wb_rd         <= mem_rd;
        end
    end

endmodule