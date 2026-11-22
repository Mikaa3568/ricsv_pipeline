// ============================================================================
// PROCESSOR_PIPELINE_tb.v - Comprehensive Testbench for RISC-V RV32I Pipeline
// ============================================================================

`timescale 1ns/1ps

module PROCESSOR_PIPELINE_tb;

    reg clock;
    reg reset;
    wire zero;
    wire [31:0] debug_reg_data;
    wire [31:0] debug_pc;
    wire [31:0] debug_instruction;
    wire        debug_stall;
    wire        debug_branch_taken;
    wire [31:0] debug_wb_data;

    PROCESSOR_PIPELINE uut (
        .clock(clock),
        .reset(reset),
        .zero(zero),
        .debug_reg_addr(5'd0),
        .debug_reg_data(debug_reg_data),
        .debug_pc(debug_pc),
        .debug_instruction(debug_instruction),
        .debug_stall(debug_stall),
        .debug_branch_taken(debug_branch_taken),
        .debug_wb_data(debug_wb_data)
    );

    // Clock generation - 10ns period (100MHz)
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end

    // Test sequence
    initial begin
        $display("\n========================================================");
        $display("   STARTING RISC-V RV32I 5-STAGE PIPELINE SIMULATION   ");
        $display("========================================================");
        
        reset = 1;
        #25;
        @(negedge clock);
        reset = 0;
        $display("[Time=%0t ns] Reset deasserted successfully.", $time);
        
        // Wait enough cycles for arithmetic, load/store, load-use stall,
        // forwarding, and the Fibonacci branch loop to finish.
        #1200;
        
        $display("\n========================================================");
        $display("             FINAL REGISTER FILE VALUES                 ");
        $display("========================================================");
        $display("x1  (ra)  = %0d (Expected: 5)",   uut.datapath_module.reg_file.reg_memory[1]);
        $display("x2  (sp)  = %0d (Expected: 3)",   uut.datapath_module.reg_file.reg_memory[2]);
        $display("x3  (gp)  = %0d (Expected: 8)",   uut.datapath_module.reg_file.reg_memory[3]);
        $display("x4  (tp)  = %0d (Expected: 2)",   uut.datapath_module.reg_file.reg_memory[4]);
        $display("x5  (t0)  = %0d (Expected: 1)",   uut.datapath_module.reg_file.reg_memory[5]);
        $display("x6  (t1)  = %0d (Expected: 7)",   uut.datapath_module.reg_file.reg_memory[6]);
        $display("x7  (t2)  = %0d (Expected: 6)",   uut.datapath_module.reg_file.reg_memory[7]);
        $display("x8  (s0)  = %0d (Expected: 40)",  uut.datapath_module.reg_file.reg_memory[8]);
        $display("x9  (s1)  = %0d (Expected: 1)",   uut.datapath_module.reg_file.reg_memory[9]);
        $display("x10 (a0)  = %0d (Expected: 8  - Load Word)", uut.datapath_module.reg_file.reg_memory[10]);
        $display("x11 (a1)  = %0d (Expected: 13 - Load-Use Stall & Forward)", uut.datapath_module.reg_file.reg_memory[11]);
        $display("x12 (a2)  = 0x%03x (Expected: 0x123)", uut.datapath_module.reg_file.reg_memory[12]);
        $display("x13 (a3)  = 0x%03x (Expected: 0x123 - Load Halfword Unsigned)", uut.datapath_module.reg_file.reg_memory[13]);
        $display("x16 (a6)  = %0d (Counter final value: 0)", uut.datapath_module.reg_file.reg_memory[16]);
        $display("x17 (a7)  = %0d (Fibonacci Fib(6) result: 8)", uut.datapath_module.reg_file.reg_memory[17]);
        $display("x18 (s2)  = %0d (Success flag: 100)", uut.datapath_module.reg_file.reg_memory[18]);
        $display("========================================================");

        // Automated Verification Assertions
        if (uut.datapath_module.reg_file.reg_memory[3]  == 8  &&
            uut.datapath_module.reg_file.reg_memory[4]  == 2  &&
            uut.datapath_module.reg_file.reg_memory[10] == 8  &&
            uut.datapath_module.reg_file.reg_memory[11] == 13 &&
            uut.datapath_module.reg_file.reg_memory[13] == 32'h123 &&
            uut.datapath_module.reg_file.reg_memory[17] == 8  &&
            uut.datapath_module.reg_file.reg_memory[18] == 100) begin
            $display("\n>>> [PASSED] ALL RISC-V PIPELINE RV32I VERIFICATION TESTS PASSED SUCCESSFULLY! <<<\n");
        end
        else begin
            $display("\n>>> [FAILED] ONE OR MORE VERIFICATION ASSERTIONS FAILED! <<<\n");
        end

        $finish;
    end

    // Signal Monitor
    initial begin
        $monitor("[Time=%0t] PC=0x%08h | Instr=0x%08h | Stall=%b | BranchTaken=%b", 
                 $time,
                 uut.ifu_module.if_pc,
                 uut.ifu_module.if_instruction,
                 uut.stall_pc,
                 uut.ex_pc_src);
    end

    // VCD waveform dump
    initial begin
        $dumpfile("processor_pipeline_wave.vcd");
        $dumpvars(0, PROCESSOR_PIPELINE_tb);
    end

endmodule