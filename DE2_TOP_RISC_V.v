// ============================================================================
// DE2_TOP_RISC_V.v - Top-level Board Wrapper for Altera DE2 (Cyclone II EP2C35)
// Connects 5-Stage RISC-V Pipeline with DE2 peripherals (Clock, Keys, SW, HEX, LEDs)
// ============================================================================

`timescale 1ns/1ps

module DE2_TOP_RISC_V (
    input         CLOCK_50,    // 50 MHz Onboard Crystal (PIN_N2)
    input  [3:0]  KEY,         // Pushbuttons: KEY[0]=Step Clock, KEY[1]=Reset (Active Low)
    input  [17:0] SW,          // Switches:
                               //   SW[4:0]  : Chon so hieu thanh ghi (x0 - x31) can xem
                               //   SW[17]   : Che do xung nhip: 0 = BAM TUNG BUOC (KEY[0]), 1 = TU DONG
                               //   SW[16]   : Toc do tu dong: 0 = Cham (~2Hz quan sat duoc), 1 = Nhanh (50MHz)
    output [6:0]  HEX0,        // 7-Doan hien thi gia tri thanh ghi (Byte thap: bit 3..0)
    output [6:0]  HEX1,        // 7-Doan hien thi gia tri thanh ghi (bit 7..4)
    output [6:0]  HEX2,        // 7-Doan hien thi gia tri thanh ghi (bit 11..8)
    output [6:0]  HEX3,        // 7-Doan hien thi gia tri thanh ghi (bit 15..12)
    output [6:0]  HEX4,        // 7-Doan so hieu thanh ghi dang chon (bit 3..0 cua SW[4:0])
    output [6:0]  HEX5,        // 7-Doan so hieu thanh ghi dang chon (bit 4 cua SW[4:0])
    output [6:0]  HEX6,        // 7-Doan hien thi con tro lenh PC[3:0]
    output [6:0]  HEX7,        // 7-Doan hien thi con tro lenh PC[7:4]
    output [17:0] LEDR,        // Den LED do hien thi du lieu ghi WB va co hoan thanh
    output [8:0]  LEDG         // Den LED xanh hien thi cac co trang thai Pipeline
);

    // ------------------------------------------------------------------------
    // 1. Xu ly Reset va Xung Nhip (Clock Generator & Debouncer)
    // ------------------------------------------------------------------------
    wire reset = ~KEY[1];      // Nhan KEY[1] de Reset (Active-Low tren board DE2)

    // Bo chia tan so 50MHz xuong ~1.5Hz de mat nguoi quan sat duoc
    reg [24:0] clk_div;
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset)
            clk_div <= 25'd0;
        else
            clk_div <= clk_div + 1'b1;
    end
    wire clk_slow = clk_div[24]; // ~1.5 Hz (0.67s moi chu ky)

    // Khử rung phím bấm nút KEY[0] để bấm từng bước xung nhịp thủ công (Manual Step)
    reg key0_d1, key0_d2, key0_pulse;
    always @(posedge CLOCK_50 or posedge reset) begin
        if (reset) begin
            key0_d1    <= 1'b1;
            key0_d2    <= 1'b1;
            key0_pulse <= 1'b0;
        end
        else begin
            key0_d1    <= KEY[0];
            key0_d2    <= key0_d1;
            // Phat hien suon xuong khi nhan phim KEY[0]
            key0_pulse <= (key0_d2 == 1'b1 && key0_d1 == 1'b0);
        end
    end

    // Chon nguon xung nhip dua vao SW[17] va SW[16]
    wire cpu_clock;
    assign cpu_clock = (SW[17] == 1'b1) ? ((SW[16] == 1'b1) ? CLOCK_50 : clk_slow) : key0_d1;

    // ------------------------------------------------------------------------
    // 2. Ket noi Bo Xu Ly RISC-V Pipeline Top Module
    // ------------------------------------------------------------------------
    wire [31:0] cpu_pc;
    wire [31:0] cpu_instruction;
    wire        cpu_stall;
    wire        cpu_branch_taken;
    wire [31:0] cpu_wb_data;
    wire [31:0] cpu_reg_data;
    wire        cpu_zero;

    PROCESSOR_PIPELINE cpu (
        .clock(cpu_clock),
        .reset(reset),
        .zero(cpu_zero),
        .debug_reg_addr(SW[4:0]),
        .debug_reg_data(cpu_reg_data),
        .debug_pc(cpu_pc),
        .debug_instruction(cpu_instruction),
        .debug_stall(cpu_stall),
        .debug_branch_taken(cpu_branch_taken),
        .debug_wb_data(cpu_wb_data)
    );

    // ------------------------------------------------------------------------
    // 3. Hien thi LED Don (LEDG va LEDR)
    // ------------------------------------------------------------------------
    // LED xanh hien thi cac co dieu khien Pipeline
    assign LEDG[0] = cpu_zero;                // Co Zero cua ALU
    assign LEDG[1] = cpu_stall;               // Sang khi xay ra xung dot Load-Use (Stall)
    assign LEDG[2] = cpu_branch_taken;        // Sang khi co Re nhanh (Branch taken) hoac Nhay (Jump)
    assign LEDG[3] = cpu_clock;               // Chop tat theo xung nhip CPU dang chay
    assign LEDG[8:4] = 5'd0;

    // LED do hien thi trang thai va 16-bit du lieu Write-Back
    assign LEDR[15:0] = cpu_wb_data[15:0];    // Du lieu duoc ghi ve thanh ghi o tang WB
    assign LEDR[16]   = (cpu_pc >= 32'h00000060); // Sang khi CPU dat den vong lap Halt
    assign LEDR[17]   = (cpu_reg_data == 32'd100 && SW[4:0] == 5'd18); // Sang khi testbench thanh cong (x18 = 100)

    // ------------------------------------------------------------------------
    // 4. Giai ma LED 7-Doan (HEX0 den HEX7)
    // ------------------------------------------------------------------------
    // HEX7 - HEX6: Hien thi gia tri con tro lenh PC (Hex 8-bit thap: 0x00 -> 0x60)
    SEG7_LUT seg_pc_high (.hex(cpu_pc[7:4]), .seg(HEX7));
    SEG7_LUT seg_pc_low  (.hex(cpu_pc[3:0]), .seg(HEX6));

    // HEX5 - HEX4: Hien thi so hieu thanh ghi dang chon xem qua SW[4:0] (00 -> 31)
    SEG7_LUT seg_rn_high (.hex({3'b000, SW[4]}), .seg(HEX5));
    SEG7_LUT seg_rn_low  (.hex(SW[3:0]),         .seg(HEX4));

    // HEX3 - HEX0: Hien thi gia tri 16-bit thap cua thanh ghi dang chon
    SEG7_LUT seg_val_3   (.hex(cpu_reg_data[15:12]), .seg(HEX3));
    SEG7_LUT seg_val_2   (.hex(cpu_reg_data[11:8]),  .seg(HEX2));
    SEG7_LUT seg_val_1   (.hex(cpu_reg_data[7:4]),   .seg(HEX1));
    SEG7_LUT seg_val_0   (.hex(cpu_reg_data[3:0]),   .seg(HEX0));

endmodule


// ============================================================================
// Module Giai Ma 4-bit Hex sang 7-Doan (Active-LOW: 0=Sang, 1=Tat)
// ============================================================================
module SEG7_LUT (
    input      [3:0] hex,
    output reg [6:0] seg
);
    always @(*) begin
        case (hex)
            4'h0: seg = 7'b1000000; // 0
            4'h1: seg = 7'b1111001; // 1
            4'h2: seg = 7'b0100100; // 2
            4'h3: seg = 7'b0110000; // 3
            4'h4: seg = 7'b0011001; // 4
            4'h5: seg = 7'b0010010; // 5
            4'h6: seg = 7'b0000010; // 6
            4'h7: seg = 7'b1111000; // 7
            4'h8: seg = 7'b0000000; // 8
            4'h9: seg = 7'b0010000; // 9
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // Tat het
        endcase
    end
endmodule

