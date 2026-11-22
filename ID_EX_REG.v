// ============================================================================
// ID_EX_REG.v - Pipeline Register between ID and EX Stages
// ============================================================================

`timescale 1ns/1ps

module ID_EX_REG (
    input             clock,
    input             reset,
    input             flush,
    // Control signals in
    input             id_regwrite,
    input      [1:0]  id_memtoreg,
    input             id_memread,
    input             id_memwrite,
    input             id_branch,
    input             id_jump,
    input             id_jalr,
    input             id_alusrc,
    input             id_auipc,
    input      [3:0]  id_alu_control,
    // Data signals in
    input      [31:0] id_pc,
    input      [31:0] id_pc_plus_4,
    input      [31:0] id_read_data1,
    input      [31:0] id_read_data2,
    input      [31:0] id_imm,
    input      [2:0]  id_funct3,
    input      [4:0]  id_rs1,
    input      [4:0]  id_rs2,
    input      [4:0]  id_rd,
    // Control signals out
    output reg        ex_regwrite,
    output reg [1:0]  ex_memtoreg,
    output reg        ex_memread,
    output reg        ex_memwrite,
    output reg        ex_branch,
    output reg        ex_jump,
    output reg        ex_jalr,
    output reg        ex_alusrc,
    output reg        ex_auipc,
    output reg [3:0]  ex_alu_control,
    // Data signals out
    output reg [31:0] ex_pc,
    output reg [31:0] ex_pc_plus_4,
    output reg [31:0] ex_read_data1,
    output reg [31:0] ex_read_data2,
    output reg [31:0] ex_imm,
    output reg [2:0]  ex_funct3,
    output reg [4:0]  ex_rs1,
    output reg [4:0]  ex_rs2,
    output reg [4:0]  ex_rd
);

    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ex_regwrite    <= 1'b0;
            ex_memtoreg    <= 2'b00;
            ex_memread     <= 1'b0;
            ex_memwrite    <= 1'b0;
            ex_branch      <= 1'b0;
            ex_jump        <= 1'b0;
            ex_jalr        <= 1'b0;
            ex_alusrc      <= 1'b0;
            ex_auipc       <= 1'b0;
            ex_alu_control <= 4'b0000;

            ex_pc          <= 32'd0;
            ex_pc_plus_4   <= 32'd0;
            ex_read_data1  <= 32'd0;
            ex_read_data2  <= 32'd0;
            ex_imm         <= 32'd0;
            ex_funct3      <= 3'b000;
            ex_rs1         <= 5'd0;
            ex_rs2         <= 5'd0;
            ex_rd          <= 5'd0;
        end
        else if (flush) begin
            ex_regwrite    <= 1'b0;
            ex_memtoreg    <= 2'b00;
            ex_memread     <= 1'b0;
            ex_memwrite    <= 1'b0;
            ex_branch      <= 1'b0;
            ex_jump        <= 1'b0;
            ex_jalr        <= 1'b0;
            ex_alusrc      <= 1'b0;
            ex_auipc       <= 1'b0;
            ex_alu_control <= 4'b0000;

            ex_pc          <= 32'd0;
            ex_pc_plus_4   <= 32'd0;
            ex_read_data1  <= 32'd0;
            ex_read_data2  <= 32'd0;
            ex_imm         <= 32'd0;
            ex_funct3      <= 3'b000;
            ex_rs1         <= 5'd0;
            ex_rs2         <= 5'd0;
            ex_rd          <= 5'd0;
        end
        else begin
            ex_regwrite    <= id_regwrite;
            ex_memtoreg    <= id_memtoreg;
            ex_memread     <= id_memread;
            ex_memwrite    <= id_memwrite;
            ex_branch      <= id_branch;
            ex_jump        <= id_jump;
            ex_jalr        <= id_jalr;
            ex_alusrc      <= id_alusrc;
            ex_auipc       <= id_auipc;
            ex_alu_control <= id_alu_control;

            ex_pc          <= id_pc;
            ex_pc_plus_4   <= id_pc_plus_4;
            ex_read_data1  <= id_read_data1;
            ex_read_data2  <= id_read_data2;
            ex_imm         <= id_imm;
            ex_funct3      <= id_funct3;
            ex_rs1         <= id_rs1;
            ex_rs2         <= id_rs2;
            ex_rd          <= id_rd;
        end
    end

endmodule