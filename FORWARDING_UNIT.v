// ============================================================================
// FORWARDING_UNIT.v - Data Forwarding Logic for RISC-V 5-Stage Pipeline
// Features: Resolves RAW hazards for EX stage ALU inputs and MEM stage Store data
// ============================================================================

`timescale 1ns/1ps

module FORWARDING_UNIT (
    input      [4:0] id_ex_rs1,
    input      [4:0] id_ex_rs2,
    input      [4:0] ex_mem_rs2,
    input      [4:0] ex_mem_rd,
    input            ex_mem_regwrite,
    input      [4:0] mem_wb_rd,
    input            mem_wb_regwrite,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b,
    output reg       forward_mem_data
);

    always @(*) begin
        // Default: No forwarding
        forward_a = 2'b00;
        forward_b = 2'b00;

        // --------------------------------------------------------------------
        // Forward A (Operand 1 to EX stage)
        // --------------------------------------------------------------------
        // EX Hazard: Forward from EX/MEM
        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs1)) begin
            forward_a = 2'b10;
        end
        // MEM Hazard: Forward from MEM/WB
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs1)) begin
            forward_a = 2'b01;
        end

        // --------------------------------------------------------------------
        // Forward B (Operand 2 to EX stage)
        // --------------------------------------------------------------------
        // EX Hazard: Forward from EX/MEM
        if (ex_mem_regwrite && (ex_mem_rd != 5'd0) && (ex_mem_rd == id_ex_rs2)) begin
            forward_b = 2'b10;
        end
        // MEM Hazard: Forward from MEM/WB
        else if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == id_ex_rs2)) begin
            forward_b = 2'b01;
        end

        // --------------------------------------------------------------------
        // MEM Stage Store Data Forwarding (Load-Store forwarding)
        // --------------------------------------------------------------------
        if (mem_wb_regwrite && (mem_wb_rd != 5'd0) && (mem_wb_rd == ex_mem_rs2)) begin
            forward_mem_data = 1'b1;
        end
        else begin
            forward_mem_data = 1'b0;
        end
    end

endmodule