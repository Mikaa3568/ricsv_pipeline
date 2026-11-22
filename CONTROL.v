// ============================================================================
// CONTROL.v - Main Control Unit for RISC-V RV32I Architecture
// Supports all 37 base integer instructions
// ============================================================================

`timescale 1ns/1ps

module CONTROL (
    input      [6:0] opcode,
    input      [2:0] funct3,
    input      [6:0] funct7,
    output reg       regwrite,
    output reg [1:0] memtoreg,   // 00: ALU, 01: Mem, 10: PC+4, 11: Imm
    output reg       memread,
    output reg       memwrite,
    output reg       branch,
    output reg       jump,
    output reg       jalr,
    output reg       alusrc,
    output reg       auipc,
    output reg [3:0] alu_control
);

    // ALU Operation Codes
    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_SUB  = 4'b0110;
    localparam ALU_SLT  = 4'b0100;
    localparam ALU_SLTU = 4'b0101;
    localparam ALU_XOR  = 4'b0111;
    localparam ALU_SLL  = 4'b1000;
    localparam ALU_SRL  = 4'b1001;
    localparam ALU_SRA  = 4'b1010;
    localparam ALU_PASS = 4'b1111;

    always @(*) begin
        // Default control signals
        regwrite    = 1'b0;
        memtoreg    = 2'b00;
        memread     = 1'b0;
        memwrite    = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        jalr        = 1'b0;
        alusrc      = 1'b0;
        auipc       = 1'b0;
        alu_control = ALU_ADD;

        case (opcode)
            // ----------------------------------------------------------------
            // R-type instructions (opcode: 0110011)
            // ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            // ----------------------------------------------------------------
            7'b0110011: begin
                regwrite = 1'b1;
                alusrc   = 1'b0;
                memtoreg = 2'b00;

                case (funct3)
                    3'b000: alu_control = (funct7[5]) ? ALU_SUB : ALU_ADD; // SUB / ADD
                    3'b001: alu_control = ALU_SLL;                         // SLL
                    3'b010: alu_control = ALU_SLT;                         // SLT (signed)
                    3'b011: alu_control = ALU_SLTU;                        // SLTU (unsigned)
                    3'b100: alu_control = ALU_XOR;                         // XOR
                    3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL; // SRA / SRL
                    3'b110: alu_control = ALU_OR;                          // OR
                    3'b111: alu_control = ALU_AND;                         // AND
                    default: alu_control = ALU_ADD;
                endcase
            end

            // ----------------------------------------------------------------
            // I-type Arithmetic/Logic instructions (opcode: 0010011)
            // ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            // ----------------------------------------------------------------
            7'b0010011: begin
                regwrite = 1'b1;
                alusrc   = 1'b1;
                memtoreg = 2'b00;

                case (funct3)
                    3'b000: alu_control = ALU_ADD;                         // ADDI
                    3'b001: alu_control = ALU_SLL;                         // SLLI
                    3'b010: alu_control = ALU_SLT;                         // SLTI
                    3'b011: alu_control = ALU_SLTU;                        // SLTIU
                    3'b100: alu_control = ALU_XOR;                         // XORI
                    3'b101: alu_control = (funct7[5]) ? ALU_SRA : ALU_SRL; // SRAI / SRLI
                    3'b110: alu_control = ALU_OR;                          // ORI
                    3'b111: alu_control = ALU_AND;                         // ANDI
                    default: alu_control = ALU_ADD;
                endcase
            end

            // ----------------------------------------------------------------
            // Load instructions (opcode: 0000011)
            // LB, LH, LW, LBU, LHU
            // ----------------------------------------------------------------
            7'b0000011: begin
                regwrite    = 1'b1;
                alusrc      = 1'b1;
                memtoreg    = 2'b01; // From Data Memory
                memread     = 1'b1;
                alu_control = ALU_ADD;
            end

            // ----------------------------------------------------------------
            // Store instructions (opcode: 0100011)
            // SB, SH, SW
            // ----------------------------------------------------------------
            7'b0100011: begin
                alusrc      = 1'b1;
                memwrite    = 1'b1;
                alu_control = ALU_ADD;
            end

            // ----------------------------------------------------------------
            // Branch instructions (opcode: 1100011)
            // BEQ, BNE, BLT, BGE, BLTU, BGEU
            // ----------------------------------------------------------------
            7'b1100011: begin
                branch      = 1'b1;
                alusrc      = 1'b0;
                alu_control = ALU_SUB;
            end

            // ----------------------------------------------------------------
            // JAL instruction (opcode: 1101111)
            // ----------------------------------------------------------------
            7'b1101111: begin
                regwrite = 1'b1;
                jump     = 1'b1;
                jalr     = 1'b0;
                memtoreg = 2'b10; // PC + 4
            end

            // ----------------------------------------------------------------
            // JALR instruction (opcode: 1100111)
            // ----------------------------------------------------------------
            7'b1100111: begin
                regwrite = 1'b1;
                jump     = 1'b1;
                jalr     = 1'b1;
                memtoreg = 2'b10; // PC + 4
            end

            // ----------------------------------------------------------------
            // LUI instruction (opcode: 0110111)
            // ----------------------------------------------------------------
            7'b0110111: begin
                regwrite    = 1'b1;
                alusrc      = 1'b1;
                memtoreg    = 2'b00;
                alu_control = ALU_PASS; // Pass immediate to ALU result
            end

            // ----------------------------------------------------------------
            // AUIPC instruction (opcode: 0010111)
            // ----------------------------------------------------------------
            7'b0010111: begin
                regwrite    = 1'b1;
                alusrc      = 1'b1;
                auipc       = 1'b1;     // Select PC as ALU operand A
                memtoreg    = 2'b00;
                alu_control = ALU_ADD;  // PC + imm
            end

            default: begin
                // NOP / default values
            end
        endcase
    end

endmodule