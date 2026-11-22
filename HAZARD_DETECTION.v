// ============================================================================
// HAZARD_DETECTION.v - Hazard Detection Unit for RISC-V 5-Stage Pipeline
// Features: Load-Use Hazard Detection & Control Hazard (Branch/Jump Flush)
// ============================================================================

`timescale 1ns/1ps

module HAZARD_DETECTION (
    input      [4:0] id_ex_rd,
    input            id_ex_memread,
    input      [4:0] if_id_rs1,
    input      [4:0] if_id_rs2,
    input      [6:0] if_id_opcode,
    input            branch_taken_ex,  // Branch/Jump taken signal from EX stage
    output reg       stall_pc,
    output reg       stall_if_id,
    output reg       flush_if_id,
    output reg       flush_id_ex
);

    // Determine if the instruction in ID stage actually uses rs2
    // R-type (0110011), S-type (0100011), B-type (1100011) use rs2
    wire if_id_uses_rs2 = (if_id_opcode == 7'b0110011) ||
                          (if_id_opcode == 7'b0100011) ||
                          (if_id_opcode == 7'b1100011);

    // Determine if the instruction in ID stage uses rs1
    // LUI (0110111), AUIPC (0010111), JAL (1101111) do NOT use rs1
    wire if_id_uses_rs1 = !((if_id_opcode == 7'b0110111) ||
                            (if_id_opcode == 7'b0010111) ||
                            (if_id_opcode == 7'b1101111));

    always @(*) begin
        stall_pc    = 1'b0;
        stall_if_id = 1'b0;
        flush_if_id = 1'b0;
        flush_id_ex = 1'b0;

        // --------------------------------------------------------------------
        // 1. Control Hazard Resolution (Branch/Jump Taken in EX stage)
        // --------------------------------------------------------------------
        if (branch_taken_ex) begin
            flush_if_id = 1'b1; // Flush instruction currently in IF/ID
            flush_id_ex = 1'b1; // Flush instruction currently in ID/EX
        end
        // --------------------------------------------------------------------
        // 2. Load-Use Data Hazard Resolution
        // --------------------------------------------------------------------
        else if (id_ex_memread && (id_ex_rd != 5'd0) &&
                ((if_id_uses_rs1 && (id_ex_rd == if_id_rs1)) ||
                 (if_id_uses_rs2 && (id_ex_rd == if_id_rs2)))) begin
            stall_pc    = 1'b1; // Freeze Program Counter
            stall_if_id = 1'b1; // Freeze IF/ID Pipeline Register
            flush_id_ex = 1'b1; // Insert NOP Bubble into ID/EX Pipeline Register
        end
    end

endmodule