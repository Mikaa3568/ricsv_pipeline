// ============================================================================
// DATA_MEM.v - Data Memory for RISC-V RV32I
// Supports Byte, Halfword, and Word Read/Write (LB, LH, LW, LBU, LHU, SB, SH, SW)
// ============================================================================

`timescale 1ns/1ps

module DATA_MEM (
    input             clock,
    input             reset,
    input             mem_read,
    input             mem_write,
    input      [2:0]  funct3,
    input      [31:0] address,
    input      [31:0] write_data,
    output reg [31:0] read_data
);

    // 64 words = 256 bytes Data Memory
    reg [31:0] ram [0:63];
    
    wire [5:0] word_addr = address[7:2];
    wire [1:0] byte_offset = address[1:0];
    wire [31:0] raw_word = (address < 32'd256) ? ram[word_addr] : 32'd0;

    integer i;

    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            ram[i] = 32'd0;
        end
    end

    // Synchronous Write
    always @(posedge clock) begin
        if (mem_write && (address < 32'd256)) begin
            case (funct3)
                3'b000: begin // SB (Store Byte)
                    case (byte_offset)
                        2'b00: ram[word_addr][7:0]   <= write_data[7:0];
                        2'b01: ram[word_addr][15:8]  <= write_data[7:0];
                        2'b10: ram[word_addr][23:16] <= write_data[7:0];
                        2'b11: ram[word_addr][31:24] <= write_data[7:0];
                    endcase
                end
                3'b001: begin // SH (Store Halfword)
                    if (byte_offset[1] == 1'b0)
                        ram[word_addr][15:0]  <= write_data[15:0];
                    else
                        ram[word_addr][31:16] <= write_data[15:0];
                end
                3'b010: begin // SW (Store Word)
                    ram[word_addr] <= write_data;
                end
                default: begin
                    ram[word_addr] <= write_data;
                end
            endcase
        end
    end

    // Asynchronous Read with Sign/Zero extension
    always @(*) begin
        if (mem_read) begin
            case (funct3)
                3'b000: begin // LB - Load Byte (Sign Extended)
                    case (byte_offset)
                        2'b00: read_data = {{24{raw_word[7]}}, raw_word[7:0]};
                        2'b01: read_data = {{24{raw_word[15]}}, raw_word[15:8]};
                        2'b10: read_data = {{24{raw_word[23]}}, raw_word[23:16]};
                        2'b11: read_data = {{24{raw_word[31]}}, raw_word[31:24]};
                    endcase
                end
                3'b100: begin // LBU - Load Byte Unsigned (Zero Extended)
                    case (byte_offset)
                        2'b00: read_data = {24'd0, raw_word[7:0]};
                        2'b01: read_data = {24'd0, raw_word[15:8]};
                        2'b10: read_data = {24'd0, raw_word[23:16]};
                        2'b11: read_data = {24'd0, raw_word[31:24]};
                    endcase
                end
                3'b001: begin // LH - Load Halfword (Sign Extended)
                    if (byte_offset[1] == 1'b0)
                        read_data = {{16{raw_word[15]}}, raw_word[15:0]};
                    else
                        read_data = {{16{raw_word[31]}}, raw_word[31:16]};
                end
                3'b101: begin // LHU - Load Halfword Unsigned (Zero Extended)
                    if (byte_offset[1] == 1'b0)
                        read_data = {16'd0, raw_word[15:0]};
                    else
                        read_data = {16'd0, raw_word[31:16]};
                end
                3'b010: begin // LW - Load Word
                    read_data = raw_word;
                end
                default: begin
                    read_data = raw_word;
                end
            endcase
        end
        else begin
            read_data = 32'd0;
        end
    end

endmodule
