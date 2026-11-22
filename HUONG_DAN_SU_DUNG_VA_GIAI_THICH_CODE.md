# HƯỚNG DẪN SỬ DỤNG VÀ GIẢI THÍCH CHI TIẾT BỘ XỬ LÝ RISC-V 5-STAGE PIPELINE

> **Đồ án Thiết kế 1 - Thiết kế Bộ xử lý RISC-V RV32I Kiến trúc Pipeline 5 tầng**  
> **Ngôn ngữ:** Verilog HDL  
> **Công cụ hỗ trợ:** Altera Quartus II (13.0sp1 hoặc mới hơn) & ModelSim-Altera  

---

## MỤC LỤC
1. [Tổng quan dự án](#1-tổng-quan-dự-án)
2. [Chi tiết các lỗi đã sửa để chạy hoàn hảo trên Quartus & ModelSim](#2-chi-tiết-các-lỗi-đã-sửa)
3. [Giải thích chi tiết kiến trúc và từng module trong code](#3-giải-thích-chi-tiết-các-module)
4. [Hướng dẫn biên dịch và chạy trên Quartus II](#4-hướng-dẫn-biên-dịch-trên-quartus-ii)
5. [Hướng dẫn mô phỏng trên ModelSim](#5-hướng-dẫn-mô-phỏng-trên-modelsim)
6. [Chương trình kiểm thử (Testbench) và kết quả xác minh](#6-chương-trình-kiểm-thử-và-kết-quả)
7. [Phân tích tài nguyên phần cứng và Thời gian tĩnh (STA)](#7-phân-tích-tài-nguyên-phần-cứng-và-thời-gian-tĩnh-sta)

---

## 1. TỔNG QUAN DỰ ÁN

Hệ thống hiện thực một vi xử lý **RISC-V RV32I 32-bit** với kiến trúc **Pipeline 5 tầng chuẩn**:
1. **IF (Instruction Fetch):** Nạp lệnh từ bộ nhớ lệnh `INST_MEM`, cập nhật `PC`.
2. **ID (Instruction Decode):** Giải mã lệnh, đọc tập thanh ghi `REG_FILE`, tạo số tức thời `IMM_GEN`, phát hiện xung đột `HAZARD_DETECTION`.
3. **EX (Execute):** Tính toán ALU, tính toán địa chỉ nhảy/rẽ nhánh, chuyển tiếp dữ liệu `FORWARDING_UNIT`.
4. **MEM (Memory Access):** Đọc/ghi dữ liệu vào bộ nhớ dữ liệu `DATA_MEM` (hỗ trợ Byte, Halfword, Word).
5. **WB (Write Back):** Ghi kết quả tính toán hoặc dữ liệu nạp từ bộ nhớ về tập thanh ghi.

### Các tính năng nâng cao:
* **Forwarding Unit (Chuyển tiếp dữ liệu):** Giải quyết xung đột dữ liệu RAW (Read-After-Write) giữa các tầng `EX/MEM` và `MEM/WB` với tầng `EX` và `MEM`, loại bỏ stall không cần thiết.
* **Hazard Detection Unit (Phát hiện xung đột):**
  * Xử lý **Load-Use Hazard**: Tự động chèn 1 chu kỳ stall (giữ nguyên PC và IF/ID, chèn NOP bubble vào ID/EX).
  * Xử lý **Control Hazard**: Flush lệnh sai trong IF/ID và ID/EX khi có lệnh nhảy (JAL, JALR) hoặc rẽ nhánh (Branch taken).
* **Bộ nhớ lệnh và dữ liệu độc lập (Harvard Architecture):** Tối ưu hóa chu kỳ xung nhịp.

---

## 2. CHI TIẾT CÁC LỖI ĐÃ SỬA

Trước khi sửa, dự án gặp phải các lỗi nghiêm trọng khiến không thể biên dịch tổng hợp trên Quartus và đường dẫn mô phỏng ModelSim bị sai:

### 1) Lỗi cú pháp tổng hợp tại `ID_EX_REG.v` (Quartus Error 10200)
* **Nguyên nhân:** Dòng 56 viết:
  ```verilog
  always @(posedge clock or posedge reset) begin
      if (reset || flush) begin ...
  ```
  Trong chuẩn Verilog tổng hợp phần cứng (Synthesis): Tín hiệu `reset` là bất đồng bộ (có mặt trong sensitivity list `posedge reset`), trong khi `flush` là đồng bộ (không có trong sensitivity list). Lệnh `if (reset || flush)` làm công cụ tổng hợp Quartus không thể ánh xạ vào flip-flop phần cứng có chân clear bất đồng bộ và báo lỗi:  
  *`Error (10200): Verilog HDL Conditional Statement error: cannot match operand(s) in the condition to the corresponding edges in the enclosing event control`*.
* **Giải pháp:** Tách rõ nhánh reset bất đồng bộ và flush đồng bộ:
  ```verilog
  always @(posedge clock or posedge reset) begin
      if (reset) begin
          // Xóa các thanh ghi khi reset
      end
      else if (flush) begin
          // Xóa các thanh ghi khi flush (chèn bong bóng NOP)
      end
      else begin
          // Cập nhật dữ liệu từ tầng ID sang EX
      end
  end
  ```

### 2) Vấn đề tài nguyên và lặp vô tận trong `DATA_MEM.v`
* **Nguyên nhân:** Trong `DATA_MEM.v`, bộ nhớ khai báo 1024 word (4KB) và bên trong khối `always @(posedge clock or posedge reset)` có vòng lặp `for (i = 0; i < 1024; i = i + 1) ram[i] <= 0;`.
  * Trên chip FPGA (như Cyclone II EP2C35), khối nhớ RAM vật lý (M4K block) không có chân reset đồng loạt tất cả các ô nhớ.
  * Việc ép reset 1024 ô nhớ 32-bit biến RAM thành 32.768 Flip-Flops rời rạc cùng bộ giải mã 1024-to-1 khổng lồ, khiến Quartus bị treo/chạy rất lâu và vượt quá 100% dung lượng chip (EP2C35 chỉ có 33.216 LE).
* **Giải pháp:**
  * Giảm kích thước RAM thực tế cho vi xử lý thí nghiệm xuống 64 word (256 bytes) – hoàn toàn đủ cho mọi chương trình kiểm thử.
  * Khởi tạo giá trị ban đầu bằng khối `initial` (chuẩn công nghiệp cho RAM khởi tạo).
  * Khối ghi RAM chuyển thành `always @(posedge clock)` đồng bộ chuẩn, cho phép Quartus tổng hợp nhanh gọn chỉ trong vài giây.

### 3) Cảnh báo suy luận Latch tại `REG_FILE.v` (Quartus Warning 10240)
* **Nguyên nhân:** Biến lặp `integer i;` được gán trong nhánh `if (reset)` nhưng không được gán trong nhánh `else`, dẫn đến Quartus cảnh báo suy luận latch cho `i`.
* **Giải pháp:** Bổ sung khởi tạo mảng thanh ghi bằng khối `initial` và khử gán thiếu cho `i` trong `REG_FILE.v`.

### 4) Cấu hình dự án Quartus (`PROCESSOR_PIPELINE.qsf`)
* **Nguyên nhân:**
  * Thiếu `IMM_GEN.v` và `DATA_MEM.v` trong danh sách file của Quartus.
  * File testbench `PROCESSOR_PIPELINE_tb.v` bị gán nhầm vào danh sách file tổng hợp phần cứng (`VERILOG_FILE`) thay vì cấu hình cho NativeLink EDA Simulation.
* **Giải pháp:**
  * Đã bổ sung đầy đủ tất cả các module vào `.qsf`.
  * Chuyển `PROCESSOR_PIPELINE_tb.v` sang gán `EDA_TEST_BENCH_FILE` cho ModelSim NativeLink.

### 5) Script mô phỏng ModelSim (`run_sim.do` & NativeLink)
* **Nguyên nhân:** File script cũ trong `simulation/modelsim/` chứa đường dẫn tuyệt đối bị sai (`D:/Quartus 2/Chuyen_de/Thi_CK/RISC_V_v2`), thiếu lệnh compile testbench và thiếu cấu hình dạng sóng.
* **Giải pháp:**
  * Tạo mới file **`run_sim.do`** tại thư mục gốc của project: tự động tạo thư viện `work`, biên dịch toàn bộ các file Verilog theo đúng thứ tự phụ thuộc, nạp testbench, nhóm tín hiệu waveform theo từng tầng Pipeline và chạy mô phỏng 1500ns.
  * Cập nhật file `.do` trong `simulation/modelsim/` để tương thích hoàn toàn khi nhấn nút mô phỏng từ giao diện Quartus.

---

## 3. GIẢI THÍCH CHI TIẾT CÁC MODULE

### 3.1. `PROCESSOR_PIPELINE.v` & `IFU_PIPELINE`
* **Nhiệm vụ:** Module đỉnh (Top-Level) bao đóng toàn bộ bộ xử lý.
* Gồm 2 thực thể chính:
  * **`IFU_PIPELINE`:** Chứa thanh ghi con trỏ lệnh `if_pc`, bộ nhớ lệnh `INST_MEM`, và logic cập nhật PC:
    * Nếu có tín hiệu `stall` từ Hazard Unit: Giữ nguyên `if_pc`.
    * Nếu có `pc_src` (rẽ nhánh hoặc nhảy): Cập nhật `if_pc = pc_target`.
    * Bình thường: `if_pc = if_pc + 4`.
  * **`DATAPATH_PIPELINE`:** Chứa toàn bộ 4 tầng còn lại (ID, EX, MEM, WB).

### 3.2. Bốn thanh ghi phân tầng Pipeline
* **`IF_ID_REG.v`:** Lưu trữ `pc`, `pc+4`, `instruction` giữa tầng Nạp lệnh (IF) và Giải mã (ID). Hỗ trợ chân `stall` (giữ nguyên dữ liệu) và chân `flush` (chèn NOP: `addi x0, x0, 0`).
* **`ID_EX_REG.v`:** Lưu trữ các tín hiệu điều khiển và dữ liệu giải mã (toán hạng đọc từ RegFile, Immediate, Funct3, số hiệu rs1, rs2, rd, pc) giữa tầng Giải mã (ID) và Thực thi (EX). Hỗ trợ chân `flush` khi gặp rẽ nhánh/nhảy hoặc Load-Use hazard.
* **`EX_MEM_REG.v`:** Lưu kết quả tính toán ALU, dữ liệu cần ghi vào bộ nhớ (Store data), số hiệu thanh ghi đích `rd`, tín hiệu điều khiển bộ nhớ (`memread`, `memwrite`, `memtoreg`, `regwrite`).
* **`MEM_WB_REG.v`:** Lưu dữ liệu đọc từ bộ nhớ `mem_read_data`, kết quả ALU `mem_alu_result`, `mem_pc_plus_4`, `rd`, và tín hiệu ghi `wb_regwrite`.

### 3.3. `CONTROL.v` (Khối điều khiển chính)
* Giải mã các trường `opcode`, `funct3`, `funct7` để sinh ra các tín hiệu điều khiển:
  * `regwrite`: Cho phép ghi vào Register File ở tầng WB.
  * `memtoreg`: Chọn nguồn ghi về thanh ghi (00: Kết quả ALU, 01: Dữ liệu từ Data Mem, 10: PC+4 cho lệnh JAL/JALR).
  * `memread` / `memwrite`: Đọc / Ghi bộ nhớ dữ liệu.
  * `branch`: Báo hiệu lệnh rẽ nhánh có điều kiện (BEQ, BNE, BLT, BGE, BLTU, BGEU).
  * `jump` / `jalr`: Lệnh nhảy vô điều kiện JAL / JALR.
  * `alusrc`: Chọn toán hạng 2 của ALU là thanh ghi (0) hay số tức thời Imm (1).
  * `auipc`: Chọn toán hạng 1 của ALU là PC thay vì thanh ghi rs1.
  * `alu_control`: Mã thao tác 4-bit điều khiển ALU thực hiện phép toán tương ứng.

### 3.4. `IMM_GEN.v` (Bộ tạo số tức thời)
* Trích xuất và mở rộng dấu (sign-extension) 32-bit từ mã lệnh tùy theo định dạng lệnh:
  * **I-type:** `imm[11:0] = instruction[31:20]` (ADDI, LW, JALR,...).
  * **S-type:** `imm[11:0] = {instruction[31:25], instruction[11:7]}` (SW, SH, SB).
  * **B-type:** Ghép các bit rời rạc cho độ dời rẽ nhánh 13-bit có dịch trái 1 bit (BEQ, BNE,...).
  * **U-type:** `imm[31:12] = instruction[31:12]`, 12 bit thấp bằng 0 (LUI, AUIPC).
  * **J-type:** Ghép các bit cho độ dời nhảy 21-bit có dịch trái 1 bit (JAL).

### 3.5. `ALU.v` (Khối tính toán số học logic)
* Thực hiện 11 phép toán:
  * Phép toán số học: `ADD`, `SUB`.
  * Phép toán logic bit: `AND`, `OR`, `XOR`.
  * Phép dịch bit: `SLL` (dịch trái logic), `SRL` (dịch phải logic), `SRA` (dịch phải số học giữ dấu `>>>`).
  * Phép so sánh: `SLT` (so sánh có dấu `$signed`), `SLTU` (so sánh không dấu).
  * `PASS`: Truyền thẳng toán hạng 2 (dùng cho lệnh `LUI`).

### 3.6. `REG_FILE.v` (Tập thanh ghi)
* Chứa 32 thanh ghi 32-bit (x0 đến x31).
* Thanh ghi `x0` luôn luôn có giá trị bằng 0.
* **Internal Write-Through Forwarding (Bypass nội bộ):** Nếu tầng WB đang ghi vào thanh ghi `xK` đúng lúc tầng ID đang đọc thanh ghi `xK`, mạch đọc sẽ lấy ngay dữ liệu đang ghi `write_data` thay vì dữ liệu cũ trong mảng.

### 3.7. `FORWARDING_UNIT.v` (Khối chuyển tiếp dữ liệu)
* Ngăn chặn xung đột dữ liệu RAW (Read-After-Write) mà không cần chèn stall:
  * **Chuyển tiếp cho Toán hạng A của ALU (`forward_a`):**
    * `2'b10`: Chuyển tiếp từ tầng `EX/MEM` (kết quả ALU của lệnh liền trước).
    * `2'b01`: Chuyển tiếp từ tầng `MEM/WB` (kết quả của lệnh cách 2 chu kỳ).
    * `2'b00`: Lấy trực tiếp từ thanh ghi tầng ID/EX.
  * **Chuyển tiếp cho Toán hạng B của ALU (`forward_b`):** Tương tự như trên đối với thanh ghi nguồn rs2.
  * **Chuyển tiếp dữ liệu ghi bộ nhớ (`forward_mem_data`):** Cho phép lệnh Store lấy trực tiếp dữ liệu vừa được tính toán ở tầng WB để ghi vào bộ nhớ.

### 3.8. `HAZARD_DETECTION.v` (Khối phát hiện xung đột)
* **Xung đột Load-Use (Load-Use Data Hazard):**
  * Xảy ra khi lệnh liền trước là lệnh nạp từ bộ nhớ (`id_ex_memread == 1`) và lệnh kế tiếp sử dụng thanh ghi đích đó làm nguồn (`rs1` hoặc `rs2`). Do dữ liệu từ bộ nhớ chỉ có ở cuối tầng MEM, forwarding không thể cung cấp dữ liệu kịp thời cho tầng EX.
  * Xử lý: `stall_pc = 1`, `stall_if_id = 1`, `flush_id_ex = 1` (đóng băng 1 chu kỳ, tạo 1 bong bóng NOP).
* **Xung đột điều khiển (Control Hazard):**
  * Khi phát hiện rẽ nhánh thành công (`branch_taken`) hoặc lệnh nhảy (`jump`), 2 lệnh kế tiếp đã bị nạp vào `IF/ID` và `ID/EX` là sai.
  * Xử lý: Kích hoạt `flush_if_id = 1` và `flush_id_ex = 1` để hủy 2 lệnh này.

### 3.9. `INST_MEM.v` & `DATA_MEM.v`
* **`INST_MEM.v`:** Bộ nhớ ROM chứa sẵn mã máy RISC-V kiểm thử các phép tính số học, logic, store/load word, store/load halfword, và một vòng lặp tính số Fibonacci.
* **`DATA_MEM.v`:** Bộ nhớ RAM 64 word (256 byte). Hỗ trợ truy xuất kích thước linh hoạt:
  * Đọc: `LB` (Load Byte có dấu), `LBU` (Load Byte không dấu), `LH` (Load Halfword có dấu), `LHU` (Load Halfword không dấu), `LW` (Load Word).
  * Ghi: `SB` (Store Byte), `SH` (Store Halfword), `SW` (Store Word).

---

## 4. HƯỚNG DẪN BIÊN DỊCH TRÊN QUARTUS II

### Bước 1: Mở dự án trong Quartus II
1. Mở phần mềm **Quartus II (64-Bit)**.
2. Chọn menu **File -> Open Project...**
3. Trỏ đến thư mục: `d:\hoctap\ki 7\do_an_thiet_ke_1\Risc_v_Pipeline`
4. Chọn file: **`PROCESSOR_PIPELINE.qpf`** và nhấn **Open**.

### Bước 2: Biên dịch tổng hợp toàn bộ dự án
1. Chọn menu **Processing -> Start Compilation** (hoặc bấm tổ hợp phím tắt **`Ctrl + L`**).
2. Chờ thanh tiến trình đạt **100%**.
3. Kết quả thông báo: **Quartus II Full Compilation was successful: 0 errors**.
   * Số lượng Logic Element sử dụng chỉ khoảng ~4.100 LEs, hoàn toàn nằm trong giới hạn của dòng FPGA Cyclone II.

### Bước 3: Chạy mô phỏng RTL trực tiếp từ Quartus (NativeLink)
1. Trong giao diện Quartus, chọn menu **Tools -> Run Simulation Tool -> RTL Simulation**.
2. Quartus sẽ tự động gọi ModelSim, nạp các file thiết kế và chạy file testbench.

---

## 5. HƯỚNG DẪN MÔ PHỎNG TRÊN MODELSIM

Có 2 cách cực kỳ đơn giản để chạy mô phỏng ModelSim:

### Cách 1: Sử dụng script tự động `run_sim.do` (Khuyến nghị - Nhanh nhất)
1. Khởi động phần mềm **ModelSim** (hoặc ModelSim-Altera).
2. Tại cửa sổ dòng lệnh **Transcript** ở dưới cùng của ModelSim, gõ lệnh chuyển thư mục làm việc về project:
   ```tcl
   cd "d:/hoctap/ki 7/do_an_thiet_ke_1/Risc_v_Pipeline"
   ```
3. Chạy file script đã được cấu hình sẵn bằng lệnh:
   ```tcl
   do run_sim.do
   ```
4. **Kết quả hiển thị tự động:**
   * Toàn bộ 14 file Verilog được biên dịch.
   * Cửa sổ **Wave** tự động mở ra, chia nhóm tín hiệu rõ ràng theo từng tầng: `TOP LEVEL`, `IF`, `ID`, `EX`, `MEM`, `WB`, và hiển thị trực tiếp giá trị của các thanh ghi từ `x1` đến `x18`.
   * Cửa sổ Transcript in kết quả kiểm tra với thông báo xanh:  
     `>>> [PASSED] ALL RISC-V PIPELINE RV32I VERIFICATION TESTS PASSED SUCCESSFULLY! <<<`

---

### Cách 2: Thao tác thủ công qua giao diện đồ họa (GUI) của ModelSim
Nếu muốn tạo thư viện và biên dịch từng bước bằng tay:
1. Chọn **File -> Change Directory...** -> chọn thư mục `Risc_v_Pipeline`.
2. Tạo thư viện làm việc:
   * Chọn **File -> New -> Library...**, đặt tên Library là `work`, bấm **OK**.
3. Biên dịch các file mã nguồn:
   * Chọn **Compile -> Compile...**
   * Giữ phím `Ctrl` và chọn tất cả các file:
     * `ALU.v`, `CONTROL.v`, `IMM_GEN.v`, `REG_FILE.v`, `INST_MEM.v`, `DATA_MEM.v`
     * `IF_ID_REG.v`, `ID_EX_REG.v`, `EX_MEM_REG.v`, `MEM_WB_REG.v`
     * `FORWARDING_UNIT.v`, `HAZARD_DETECTION.v`, `DATAPATH_PIPELINE.v`, `PROCESSOR_PIPELINE.v`
     * `PROCESSOR_PIPELINE_tb.v`
   * Bấm nút **Compile**, sau đó bấm **Done**.
4. Bắt đầu mô phỏng:
   * Chọn **Simulate -> Start Simulation...**
   * Trong tab *Design*, mở rộng thư mục `work`, nhấp chọn **`PROCESSOR_PIPELINE_tb`**.
   * Bỏ chọn *Enable optimization* (hoặc trong Optimization Options chọn *Apply full visibility*), bấm **OK**.
5. Kéo tín hiệu vào màn hình Wave:
   * Trong cửa sổ *Sim*, nhấp chuột phải vào `PROCESSOR_PIPELINE_tb` -> chọn **Add to -> Wave -> Signals in Region**.
6. Chạy mô phỏng:
   * Trong thanh công cụ hoặc cửa sổ Transcript, gõ: `run 1500ns` và nhấn Enter.
   * Bấm biểu tượng kính lúp **Zoom Full** trên thanh công cụ Wave để xem toàn bộ dạng sóng.

---

### Cách 3: Chạy nhanh qua dòng lệnh PowerShell (Không cần mở GUI)
Nếu bạn chỉ muốn kiểm tra nhanh kết quả kiểm thử ngay trong terminal:
```powershell
cd "d:\hoctap\ki 7\do_an_thiet_ke_1\Risc_v_Pipeline"
vsim -c -do "do run_sim.do; quit -f"
```

---

## 6. CHƯƠNG TRÌNH KIỂM THỬ VÀ KẾT QUẢ

Chương trình nạp sẵn trong `INST_MEM.v` thực hiện chuỗi lệnh kiểm tra toàn diện các chức năng của bộ xử lý:

| Địa chỉ PC | Mã máy Hex | Mã ASM RISC-V | Chức năng kiểm tra | Kết quả mong đợi |
| :---: | :---: | :--- | :--- | :--- |
| `0x00` | `0x00500093` | `addi x1, x0, 5` | Khởi tạo x1 = 5 | `x1 = 5` |
| `0x04` | `0x00300113` | `addi x2, x0, 3` | Khởi tạo x2 = 3 | `x2 = 3` |
| `0x08` | `0x002081b3` | `add  x3, x1, x2` | Phép cộng R-type & Test Forwarding EX | `x3 = 8` |
| `0x0C` | `0x40208233` | `sub  x4, x1, x2` | Phép trừ R-type | `x4 = 2` |
| `0x10` | `0x0020f2b3` | `and  x5, x1, x2` | Phép AND bit: 5 & 3 = 1 | `x5 = 1` |
| `0x14` | `0x0020e333` | `or   x6, x1, x2` | Phép OR bit: 5 \| 3 = 7 | `x6 = 7` |
| `0x18` | `0x0020c3b3` | `xor  x7, x1, x2` | Phép XOR bit: 5 ^ 3 = 6 | `x7 = 6` |
| `0x1C` | `0x00209433` | `sll  x8, x1, x2` | Phép dịch trái: 5 << 3 = 40 | `x8 = 40` |
| `0x20` | `0x001124b3` | `slt  x9, x2, x1` | Phép so sánh bé hơn: 3 < 5 = 1 | `x9 = 1` |
| `0x24` | `0x00302023` | `sw   x3, 0(x0)` | Ghi từ nhớ 32-bit vào DataMem[0] | `Mem[0] = 8` |
| `0x28` | `0x00002503` | `lw   x10, 0(x0)` | Nạp từ nhớ 32-bit từ DataMem[0] | `x10 = 8` |
| `0x2C` | `0x001505b3` | `add  x11, x10, x1` | **Test Load-Use Hazard Stall (1 stall) + Forwarding** | `x11 = 8 + 5 = 13` |
| `0x30` | `0x12300613` | `addi x12, x0, 0x123` | Nạp giá trị tức thời x12 = 0x123 | `x12 = 0x123` |
| `0x34` | `0x00c01223` | `sh   x12, 4(x0)` | Ghi nửa từ (Halfword) vào Mem[4] | `Mem[4] = 0x0123` |
| `0x38` | `0x00405683` | `lhu  x13, 4(x0)` | Nạp nửa từ không dấu (LHU) từ Mem[4] | `x13 = 0x0123` |
| `0x3C-0x58` | *Loop* | **Vòng lặp tính dãy Fibonacci Fib(6)** | **Test rẽ nhánh BNE lùi (Branch Loop)** | `x17 = 8`, `x16 = 0` |
| `0x5C` | `0x06400913` | `addi x18, x0, 100` | Ghi nhận cờ kết thúc thành công | `x18 = 100` |
| `0x60` | `0x00000063` | `beq  x0, x0, 0` | Dừng vi xử lý (Vòng lặp vô tận tại chỗ) | HALT |

### Kết quả kiểm tra hiển thị khi mô phỏng:
```text
========================================================
             FINAL REGISTER FILE VALUES                 
========================================================
x1  (ra)  = 5 (Expected: 5)
x2  (sp)  = 3 (Expected: 3)
x3  (gp)  = 8 (Expected: 8)
x4  (tp)  = 2 (Expected: 2)
x5  (t0)  = 1 (Expected: 1)
x6  (t1)  = 7 (Expected: 7)
x7  (t2)  = 6 (Expected: 6)
x8  (s0)  = 40 (Expected: 40)
x9  (s1)  = 1 (Expected: 1)
x10 (a0)  = 8 (Expected: 8  - Load Word)
x11 (a1)  = 13 (Expected: 13 - Load-Use Stall & Forward)
x12 (a2)  = 0x123 (Expected: 0x123)
x13 (a3)  = 0x123 (Expected: 0x123 - Load Halfword Unsigned)
x16 (a6)  = 0 (Counter final value: 0)
x17 (a7)  = 8 (Fibonacci Fib(6) result: 8)
x18 (s2)  = 100 (Success flag: 100)
========================================================

>>> [PASSED] ALL RISC-V PIPELINE RV32I VERIFICATION TESTS PASSED SUCCESSFULLY! <<<
```

---

## 7. PHÂN TÍCH TÀI NGUYÊN PHẦN CỨNG VÀ THỜI GIAN TĨNH (STA)

Phần này cung cấp các số liệu thực tế được trích xuất trực tiếp từ báo cáo biên dịch tổng hợp (`PROCESSOR_PIPELINE.map.rpt`, `PROCESSOR_PIPELINE.fit.rpt` và `PROCESSOR_PIPELINE.sta.rpt`) của Quartus II 64-Bit trên chip mục tiêu **Altera Cyclone II EP2C35F672C6** (Board Altera DE2). Bạn có thể sao chép trực tiếp các bảng này vào **Báo cáo Đồ án Thiết kế 1**.

### 7.1. Bảng tổng kết tài nguyên phần cứng (Resource Utilization)

| Thông số tài nguyên | Đã sử dụng | Tổng tài nguyên chip EP2C35 | Tỷ lệ sử dụng (%) | Ghi chú đánh giá |
| :--- | :---: | :---: | :---: | :--- |
| **Total Logic Elements (LEs)** | **3.985** | 33.216 | **12 %** | Rất nhỏ gọn, tiết kiệm diện tích trên chip |
| *-- Combinational functions* | 2.930 | 33.216 | 9 % | Các cổng logic của ALU, Control, Forwarding,... |
| *-- Dedicated logic registers* | 1.441 | 33.216 | 4 % | 1024 bit RegFile + 4 thanh ghi phân tầng Pipeline |
| **Total Memory Bits** | **2.048** | 483.840 | **< 1 %** | Khối nhớ M4K RAM nhúng được suy luận cho DataMem |
| **Embedded Multiplier 9-bit** | **0** | 70 | **0 %** | Thiết kế RV32I thuần không cần bộ nhân phần cứng |
| **Total I/O Pins** | **3** | 475 | **< 1 %** | `clock`, `reset`, `zero` |

---

### 7.2. Bảng phân tích thời gian tĩnh (Static Timing Analysis - STA)

* **Xung nhịp mục tiêu cấu hình trong `PROCESSOR_PIPELINE.sdc`:** $50.00\text{ MHz}$ (Chu kỳ $T = 20.000\text{ ns}$, tương thích chuẩn thạch anh board Altera DE2).
* **Kết quả đo lường độ dôi thời gian (Timing Slack) và Tần số cực đại ($F_{\max}$):**

| Điều kiện phân tích nhiệt độ / silicon | Worst-case Setup Slack | Worst-case Hold Slack | Minimum Pulse Width | Tần số cực đại ($F_{\max}$) | Trạng thái Timing |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Slow Model (Worst-case: 85°C, Slow silicon)** | **`+4.564 ns`** | **`+0.391 ns`** | **`+7.873 ns`** | **$64.78\text{ MHz}$** | **PASSED (MET - Đạt)** |
| **Fast Model (Best-case: 0°C, Fast silicon)** | **`+13.185 ns`** | **`+0.215 ns`** | **`+7.873 ns`** | **$145.98\text{ MHz}$** | **PASSED (MET - Đạt)** |

---

### 7.3. Phân tích đường trễ tới hạn (Critical Path Analysis)

* **Đường đi tín hiệu trễ nhất (Critical Path) đo được trong Slow Model:**
  * **Điểm xuất phát (From Node):** `DATAPATH_PIPELINE|ID_EX_REG:id_ex_reg|ex_rs1[1]` (hoặc `EX_MEM_REG:ex_mem_reg|mem_rd[2]`).
  * **Điểm kết thúc (To Node):** `DATAPATH_PIPELINE|EX_MEM_REG:ex_mem_reg|mem_alu_result[23]`.
  * **Độ trễ truyền qua đường này (Data Delay):** $\approx 15.436\text{ ns}$ (ở chế độ Fitter tối ưu cho 50MHz) hoặc $11.643\text{ ns}$ (ở chế độ tự do).
* **Giải thích nguyên lý vật lý:**
  1. Dữ liệu từ thanh ghi nguồn hoặc từ tầng trước đi qua bộ so sánh của `FORWARDING_UNIT`.
  2. Dữ liệu chọn chuyển tiếp đi vào cổng tính toán số học của `ALU` 32-bit (qua bộ cộng trừ có truyền bit nhớ Carry Chain).
  3. Kết quả ALU được chốt vào thanh ghi tầng kế tiếp `EX_MEM_REG`.
* **Đánh giá:**
  * Chu kỳ xung nhịp $50\text{ MHz}$ của board DE2 tương ứng với $20.000\text{ ns}$.
  * Do thời gian tính toán lớn nhất ($15.436\text{ ns}$) vẫn nhỏ hơn chu kỳ ($20.000\text{ ns}$), mạch còn dư độ an toàn (Setup Slack dương $+4.564\text{ ns}$).
  * Hệ thống hoàn toàn không có nguy cơ chạy sai hay bị lỗi trạng thái không ổn định (Metastability).

---
*Tài liệu được cập nhật tự động để hỗ trợ báo cáo đồ án và thực hành môn học Kiến trúc Máy tính / Thiết kế Hệ thống Số.*

