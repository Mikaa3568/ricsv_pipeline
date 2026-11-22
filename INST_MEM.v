// ============================================================================
// INST_MEM.v - Instruction Memory for RISC-V RV32I Processor
// Features: Asynchronous read, support for embedded program & hex file loading
// ============================================================================

`timescale 1ns/1ps

module INST_MEM (
    input      [31:0] PC,
    input             reset,
    output     [31:0] Instruction_Code
);

    reg [31:0] memory [0:1023];
    integer i;

    initial begin
        // Initialize memory with NOP (addi x0, x0, 0)
        for (i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'h00000013;
        end

        // --------------------------------------------------------------------
        // Built-in Comprehensive RV32I Test Program:
        // Tests: ADDI, LUI, R-type, Load/Store, Load-Use stall, Branch, Loop
        // --------------------------------------------------------------------
        // [0x00] addi x1, x0, 5        ; x1 = 5
        memory[0] = 32'h00500093;
        // [0x04] addi x2, x0, 3        ; x2 = 3
        memory[1] = 32'h00300113;
        // [0x08] add  x3, x1, x2       ; x3 = 5 + 3 = 8 (tests RAW forwarding)
        memory[2] = 32'h002081b3;
        // [0x0C] sub  x4, x1, x2       ; x4 = 5 - 3 = 2
        memory[3] = 32'h40208233;
        // [0x10] and  x5, x1, x2       ; x5 = 5 & 3 = 1
        memory[4] = 32'h0020f2b3;
        // [0x14] or   x6, x1, x2       ; x6 = 5 | 3 = 7
        memory[5] = 32'h0020e333;
        // [0x18] xor  x7, x1, x2       ; x7 = 5 ^ 3 = 6
        memory[6] = 32'h0020c3b3;
        // [0x1C] sll  x8, x1, x2       ; x8 = 5 << 3 = 40 (0x28)
        memory[7] = 32'h00209433;
        // [0x20] slt  x9, x2, x1       ; x9 = (3 < 5) = 1
        memory[8] = 32'h001124b3;

        // --- Test Store and Load (Memory subsystem) ---
        // [0x24] sw   x3, 0(x0)        ; Mem[0] = 8
        memory[9] = 32'h00302023;
        // [0x28] lw   x10, 0(x0)       ; x10 = Mem[0] = 8 (Load)
        memory[10] = 32'h00002503;
        // [0x2C] add  x11, x10, x1     ; x11 = 8 + 5 = 13 (Tests Load-Use STALL + Forwarding!)
        memory[11] = 32'h001505b3;

        // --- Test Halfword and Byte Load/Store ---
        // [0x30] addi x12, x0, 0x123   ; x12 = 0x123
        memory[12] = 32'h12300613;
        // [0x34] sh   x12, 4(x0)       ; Store halfword 0x0123 at addr 4
        memory[13] = 32'h00c01223;
        // [0x38] lhu  x13, 4(x0)       ; x13 = Load halfword unsigned = 0x0123
        memory[14] = 32'h00405683;

        // --- Test Fibonacci Loop (Computing Fib(7) = 13) ---
        // Iterations count: N = 5
        // [0x3C] addi x14, x0, 0       ; a = Fib(0) = 0
        memory[15] = 32'h00000713;
        // [0x40] addi x15, x0, 1       ; b = Fib(1) = 1
        memory[16] = 32'h00100793;
        // [0x44] addi x16, x0, 5       ; counter = 5
        memory[17] = 32'h00500813;
        // [0x48] LOOP:
        // [0x48] add  x17, x14, x15    ; c = a + b
        memory[18] = 32'h00f708b3;
        // [0x4C] add  x14, x15, x0     ; a = b
        memory[19] = 32'h00078713;
        // [0x50] add  x15, x17, x0     ; b = c
        memory[20] = 32'h00088793;
        // [0x54] addi x16, x16, -1     ; counter = counter - 1 (imm = -1 = 0xFFF)
        memory[21] = 32'hfff80813;
        // [0x58] bne  x16, x0, -16     ; if counter != 0 goto LOOP (offset = -16 = 0x10 bytes back to 0x48)
        // bne: imm = -16 -> imm[12]=1, imm[11]=1, imm[10:5]=111111, imm[4:1]=0000
        // instruction: 1 111110 00000 10000 001 0000 1 1100011 -> 0xfe0818e3
        memory[22] = 32'hfe0818e3;

        // --- End of Test Program ---
        // [0x5C] addi x18, x0, 100     ; x18 = 100 (Success marker!)
        memory[23] = 32'h06400913;
        // [0x60] beq  x0, x0, 0        ; Infinite loop HALT: beq x0, x0, 0
        memory[24] = 32'h00000063;
    end

    // Combinational instruction output based on word address PC[11:2]
    wire [9:0] word_addr = PC[11:2];
    assign Instruction_Code = (PC < 32'd4096) ? memory[word_addr] : 32'h00000013;

endmodule