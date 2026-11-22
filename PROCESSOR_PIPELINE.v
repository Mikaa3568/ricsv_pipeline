// ============================================================================
// PROCESSOR_PIPELINE.v - Top Module for 5-Stage Pipelined RISC-V RV32I Processor
// Stages: IF -> ID -> EX -> MEM -> WB
// Features: Forwarding, Load-Use Hazard Stall, Branch/Jump Prediction & Flush
// ============================================================================

`timescale 1ns/1ps

module PROCESSOR_PIPELINE ( 
    input         clock, 
    input         reset,
    output        zero,
    // Probes for FPGA Board display (optional)
    input  [4:0]  debug_reg_addr,
    output [31:0] debug_reg_data,
    output [31:0] debug_pc,
    output [31:0] debug_instruction,
    output        debug_stall,
    output        debug_branch_taken,
    output [31:0] debug_wb_data
);

    // ========================================================================
    // IF Stage Signals
    // ========================================================================
    wire [31:0] if_pc;
    wire [31:0] if_pc_plus_4;
    wire [31:0] if_instruction;
    wire        stall_pc;
    wire        ex_pc_src;
    wire [31:0] ex_pc_target;

    // ========================================================================
    // Pipeline Monitoring Outputs
    // ========================================================================
    wire [31:0] wb_write_data;
    wire [4:0]  wb_rd;
    wire        wb_regwrite;
    wire        zero_flag;

    assign zero = zero_flag;
    assign debug_pc = if_pc;
    assign debug_instruction = if_instruction;
    assign debug_stall = stall_pc;
    assign debug_branch_taken = ex_pc_src;
    assign debug_wb_data = wb_write_data;

    // ========================================================================
    // Instruction Fetch Unit (IF Stage)
    // ========================================================================
    IFU_PIPELINE ifu_module (
        .clock(clock),
        .reset(reset),
        .stall(stall_pc),
        .pc_src(ex_pc_src),
        .pc_target(ex_pc_target),
        .if_pc(if_pc),
        .if_pc_plus_4(if_pc_plus_4),
        .if_instruction(if_instruction)
    );

    // ========================================================================
    // Pipelined Datapath (ID, EX, MEM, WB Stages)
    // ========================================================================
    DATAPATH_PIPELINE datapath_module (
        .clock(clock),
        .reset(reset),
        .if_instruction(if_instruction),
        .if_pc(if_pc),
        .if_pc_plus_4(if_pc_plus_4),
        .stall_pc(stall_pc),
        .ex_pc_src(ex_pc_src),
        .ex_pc_target(ex_pc_target),
        .wb_write_data(wb_write_data),
        .wb_rd(wb_rd),
        .wb_regwrite(wb_regwrite),
        .zero_flag(zero_flag),
        .debug_reg_num(debug_reg_addr),
        .debug_reg_data(debug_reg_data)
    );

endmodule


// ============================================================================
// IFU_PIPELINE - Instruction Fetch Unit with Branch/Jump and Stall Support
// ============================================================================
module IFU_PIPELINE (
    input             clock,
    input             reset,
    input             stall,
    input             pc_src,
    input      [31:0] pc_target,
    output reg [31:0] if_pc,
    output     [31:0] if_pc_plus_4,
    output     [31:0] if_instruction
);

    assign if_pc_plus_4 = if_pc + 32'd4;

    // Instruction Memory
    INST_MEM instr_mem (
        .PC(if_pc),
        .reset(reset),
        .Instruction_Code(if_instruction)
    );

    // Program Counter with Stall and Branch/Jump redirection
    always @(posedge clock or posedge reset) begin
        if (reset)
            if_pc <= 32'h00000000;
        else if (stall)
            if_pc <= if_pc;          // Freeze PC during Load-Use hazard
        else if (pc_src)
            if_pc <= pc_target;      // Redirection on Branch/Jump taken
        else
            if_pc <= if_pc + 32'd4;  // Normal sequential execution
    end

endmodule