// ============================================================================
// ALU.v - 32-bit Arithmetic Logic Unit for RISC-V RV32I
// Supports all arithmetic, logic, shift, and comparison operations
// ============================================================================

`timescale 1ns/1ps

module ALU (
    input  [31:0] in1,
    input  [31:0] in2, 
    input  [3:0]  alu_control,
    output reg [31:0] alu_result,
    output wire   zero_flag
);

    // ALU Operation Codes
    localparam ALU_AND  = 4'b0000;
    localparam ALU_OR   = 4'b0001;
    localparam ALU_ADD  = 4'b0010;
    localparam ALU_SUB  = 4'b0110;
    localparam ALU_SLT  = 4'b0100; // Signed comparison
    localparam ALU_SLTU = 4'b0101; // Unsigned comparison
    localparam ALU_XOR  = 4'b0111;
    localparam ALU_SLL  = 4'b1000;
    localparam ALU_SRL  = 4'b1001;
    localparam ALU_SRA  = 4'b1010; // Arithmetic right shift
    localparam ALU_PASS = 4'b1111; // Pass operand 2 (for LUI)

    always @(*) begin
        case (alu_control)
            ALU_AND:  alu_result = in1 & in2;
            ALU_OR:   alu_result = in1 | in2;
            ALU_ADD:  alu_result = in1 + in2;
            ALU_SUB:  alu_result = in1 - in2;
            ALU_SLT:  alu_result = ($signed(in1) < $signed(in2)) ? 32'd1 : 32'd0;
            ALU_SLTU: alu_result = (in1 < in2) ? 32'd1 : 32'd0;
            ALU_XOR:  alu_result = in1 ^ in2;
            ALU_SLL:  alu_result = in1 << in2[4:0];
            ALU_SRL:  alu_result = in1 >> in2[4:0];
            ALU_SRA:  alu_result = $signed(in1) >>> in2[4:0];
            ALU_PASS: alu_result = in2;
            default:  alu_result = 32'd0;
        endcase
    end

    assign zero_flag = (alu_result == 32'd0);

endmodule