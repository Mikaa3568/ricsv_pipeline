// ============================================================================
// REG_FILE.v - 32x32 Register File for RISC-V RV32I
// Features: x0 hardwired to 0, asynchronous read, internal write-through forwarding
// ============================================================================

`timescale 1ns/1ps

module REG_FILE (
    input             clock,
    input             reset,
    input             regwrite,
    input      [4:0]  read_reg_num1,
    input      [4:0]  read_reg_num2,
    input      [4:0]  write_reg,
    input      [31:0] write_data,
    output     [31:0] read_data1,
    output     [31:0] read_data2,
    // Debug port for FPGA Board display
    input      [4:0]  debug_reg_num,
    output     [31:0] debug_reg_data
);

    reg [31:0] reg_memory [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            reg_memory[i] = 32'd0;
        end
    end

    // Synchronous Write
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                reg_memory[i] <= 32'd0;
            end
        end
        else begin
            i = 0;
            if (regwrite && (write_reg != 5'd0)) begin
                reg_memory[write_reg] <= write_data;
            end
        end
    end

    // Asynchronous Read with internal bypass (WB-to-ID forwarding)
    assign read_data1 = (read_reg_num1 == 5'd0) ? 32'd0 :
                        (regwrite && (write_reg == read_reg_num1)) ? write_data :
                        reg_memory[read_reg_num1];

    assign read_data2 = (read_reg_num2 == 5'd0) ? 32'd0 :
                        (regwrite && (write_reg == read_reg_num2)) ? write_data :
                        reg_memory[read_reg_num2];

    // Debug asynchronous read port
    assign debug_reg_data = (debug_reg_num == 5'd0) ? 32'd0 :
                            (regwrite && (write_reg == debug_reg_num)) ? write_data :
                            reg_memory[debug_reg_num];

endmodule