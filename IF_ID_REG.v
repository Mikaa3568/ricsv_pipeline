// ============================================================================
// IF_ID_REG.v - Pipeline Register between IF and ID Stages
// ============================================================================

`timescale 1ns/1ps

module IF_ID_REG (
    input             clock,
    input             reset,
    input             stall,
    input             flush,
    input      [31:0] if_pc,
    input      [31:0] if_pc_plus_4,
    input      [31:0] if_instruction,
    output reg [31:0] id_pc,
    output reg [31:0] id_pc_plus_4,
    output reg [31:0] id_instruction
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            id_pc          <= 32'd0;
            id_pc_plus_4   <= 32'd4;
            id_instruction <= 32'h00000013; // NOP (addi x0, x0, 0)
        end
        else if (flush) begin
            id_pc          <= 32'd0;
            id_pc_plus_4   <= 32'd4;
            id_instruction <= 32'h00000013; // NOP (addi x0, x0, 0)
        end
        else if (stall) begin
            id_pc          <= id_pc;
            id_pc_plus_4   <= id_pc_plus_4;
            id_instruction <= id_instruction;
        end
        else begin
            id_pc          <= if_pc;
            id_pc_plus_4   <= if_pc_plus_4;
            id_instruction <= if_instruction;
        end
    end

endmodule