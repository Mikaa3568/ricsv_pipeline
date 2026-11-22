# BẢNG TỔNG HỢP MÔ PHỎNG VÀ HIỂN THỊ KẾT QUẢ TRÊN BOARD ALTERA DE2
## Đồ án Thiết kế 1: Bộ xử lý RISC-V RV32I Kiến trúc 5-Stage Pipeline
*Chip FPGA: Cyclone II EP2C35F672C6 | Board: Altera DE2*

---

## 1. QUY ƯỚC NGOẠI VI TRÊN BOARD DE2

| Ngoại vi | Chân FPGA | Chức năng quy ước trong Project |
| :--- | :--- | :--- |
| **`CLOCK_50`** | `PIN_N2` | Nguồn xung thạch anh chuẩn 50 MHz trên board DE2 |
| **`KEY[1]`** | `PIN_N23` | **Nút bấm Reset** hệ thống (Nhấn = Reset về 0, nhả = Hoạt động) |
| **`KEY[0]`** | `PIN_G26` | **Nút bấm phát từng xung nhịp (Manual Step):** Mỗi lần nhấn là CPU chạy đúng 1 chu kỳ clock |
| **`SW[17]`** | `PIN_V2` | **Gạt chọn chế độ Clock:** <br>• Gạt xuống (`0`): Chế độ bấm tay từng bước bằng `KEY[0]` *(Khuyên dùng khi báo cáo)* <br>• Gạt lên (`1`): Chế độ tự động chạy |
| **`SW[16]`** | `PIN_V1` | **Gạt chọn tốc độ tự động:** <br>• Gạt xuống (`0`): Chạy chậm ~1.5 Hz (mắt người kịp nhìn từng lệnh) <br>• Gạt lên (`1`): Chạy tốc độ tối đa 50 MHz |
| **`SW[4:0]`** | `PIN_AF14..PIN_N25` | **5 công tắc chọn thanh ghi $x_0 \sim x_{31}$** muốn soi giá trị trên LED 7 đoạn |
| **`HEX7 - HEX6`** | 2 LED 7 đoạn bên trái | **Hiển thị con trỏ lệnh PC** dạng Hex (`00`, `04`, `08`, ..., `60`) |
| **`HEX5 - HEX4`** | 2 LED 7 đoạn ở giữa | **Hiển thị số hiệu thanh ghi** đang chọn qua `SW[4:0]` (Ví dụ `01`, `02`, `0A`, `11`) |
| **`HEX3 - HEX0`** | 4 LED 7 đoạn bên phải | **Hiển thị giá trị 16-bit của thanh ghi** đang chọn dạng Hex |
| **`LEDG[0]`** | Đèn xanh số 0 | Cờ **Zero flag** của ALU |
| **`LEDG[1]`** | Đèn xanh số 1 | Cờ **Stall flag** (SÁNG CHÓI khi vi xử lý bị dừng do xung đột Load-Use) |
| **`LEDG[2]`** | Đèn xanh số 2 | Cờ **Branch/Jump Taken** (SÁNG khi có rẽ nhánh hoặc nhảy địa chỉ) |
| **`LEDG[3]`** | Đèn xanh số 3 | Đèn báo nhịp xung clock CPU đang đập |
| **`LEDR[15:0]`** | 16 Đèn đỏ | Dữ liệu tầng Write-Back (`wb_write_data[15:0]`) |
| **`LEDR[16]`** | Đèn đỏ số 16 | **Báo HALT:** Sáng khi CPU chạy đến lệnh dừng vô tận cuối cùng |
| **`LEDR[17]`** | Đèn đỏ số 17 | **Báo THÀNH CÔNG:** Sáng khi $x_{18} = 100$ (Hoàn tất toàn bộ chuỗi test) |

---

## 2. BẢNG MÔ PHỎNG CHI TIẾT TỪNG LỆNH VÀ KẾT QUẢ TRÊN BOARD DE2

> **Ghi chú cách đọc bảng:**
> * Giá trị hiển thị trên LED 7 đoạn là hệ thập lục phân (**Hexadecimal**).
> * Khi gạt công tắc `SW[4:0]` tương ứng với thanh ghi nào, cụm LED `HEX3-HEX0` sẽ hiển thị tức thì giá trị đang lưu trong thanh ghi đó.

| Bước | PC (Hex) | Lệnh Hợp ngữ (ASM) | Mã máy (Hex) | `HEX7-HEX6` (Hiển thị PC) | Gạt `SW[4:0]` chọn xem | `HEX5-HEX4` (Mã thanh ghi) | `HEX3-HEX0` (Giá trị thanh ghi) | Đèn LED nổi bật | Cơ chế Pipeline & Ý nghĩa hoạt động |
| :---: | :---: | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| **0** | `00` | *Sau khi bấm Reset (`KEY[1]`)* | — | `00` | `00000` ($x_0$) | `00` | `0000` | `LEDG[0]=1` | Reset toàn bộ hệ thống, PC = 0x00, các thanh ghi = 0. |
| **1** | `00` | `addi x1, x0, 5` | `00500093` | `04` | `00001` ($x_1$) | `01` | `0005` | `LEDR = 0005` | Khởi tạo $x_1 = 0 + 5 = 5$. |
| **2** | `04` | `addi x2, x0, 3` | `00300113` | `08` | `00010` ($x_2$) | `02` | `0003` | `LEDR = 0003` | Khởi tạo $x_2 = 0 + 3 = 3$. |
| **3** | `08` | `add  x3, x1, x2` | `002081b3` | `0C` | `00011` ($x_3$) | `03` | `0008` | `LEDR = 0008` | **EX Forwarding:** Lấy ngay $x_2$ từ tầng trước, tính $5 + 3 = 8$. |
| **4** | `0C` | `sub  x4, x1, x2` | `40208233` | `10` | `00100` ($x_4$) | `04` | `0002` | `LEDR = 0002` | Phép trừ: $5 - 3 = 2$. |
| **5** | `10` | `and  x5, x1, x2` | `0020f2b3` | `14` | `00101` ($x_5$) | `05` | `0001` | `LEDR = 0001` | Phép AND logic: $5 \ \& \ 3 = 1$. |
| **6** | `14` | `or   x6, x1, x2` | `0020e333` | `18` | `00110` ($x_6$) | `06` | `0007` | `LEDR = 0007` | Phép OR logic: $5 \ \| \ 3 = 7$. |
| **7** | `18` | `xor  x7, x1, x2` | `0020c3b3` | `1C` | `00111` ($x_7$) | `07` | `0006` | `LEDR = 0006` | Phép XOR logic: $5 \oplus 3 = 6$. |
| **8** | `1C` | `sll  x8, x1, x2` | `00209433` | `20` | `01000` ($x_8$) | `08` | `0028` | `LEDR = 0028` | Dịch trái logic: $5 \ll 3 = 40$ (Hex: `0x0028`). |
| **9** | `20` | `slt  x9, x2, x1` | `001124b3` | `24` | `01001` ($x_9$) | `09` | `0001` | `LEDR = 0001` | So sánh có dấu: $3 < 5$ đúng $\rightarrow x_9 = 1$. |
| **10** | `24` | `sw   x3, 0(x0)` | `00302023` | `28` | `00011` ($x_3$) | `03` | `0008` | `LEDG[3]` nhấp nháy | Ghi giá trị $x_3 = 8$ vào ô nhớ RAM địa chỉ 0. |
| **11** | `28` | `lw   x10, 0(x0)` | `00002503` | `2C` | `01010` ($x_{10}$) | `0A` | `0008` | `LEDR = 0008` | Nạp dữ liệu từ RAM địa chỉ 0 vào thanh ghi $x_{10} = 8$. |
| **12** | **`2C`** | **`add  x11, x10, x1`** | `001505b3` | **Giữ `2C` (1 nhịp)** | `01011` ($x_{11}$) | `0B` | Đang tính | **`LEDG[1]=1` (SÁNG CHÓI)** | **LOAD-USE HAZARD:** Bộ Hazard phát hiện lệnh nạp đang chưa có dữ liệu $\rightarrow$ **Dừng 1 chu kỳ (Stall)**, đèn xanh `LEDG[1]` sáng báo hiệu. |
| **13** | `2C` | *(Tiếp tục chu kỳ sau)* | — | `30` | `01011` ($x_{11}$) | `0B` | `000D` | `LEDR = 000D` | **Load-Forwarding:** Dữ liệu từ RAM được chuyển tiếp vào ALU, $8 + 5 = 13$ (Hex: `0x000D`). |
| **14** | `30` | `addi x12, x0, 0x123` | `12300613` | `34` | `01100` ($x_{12}$) | `0C` | `0123` | `LEDR = 0123` | Nạp số tức thời lớn: $x_{12} = \text{0x0123}$. |
| **15** | `34` | `sh   x12, 4(x0)` | `00c01223` | `38` | `01100` ($x_{12}$) | `0C` | `0123` | Bình thường | Ghi nửa từ (Halfword) `0x0123` vào RAM tại địa chỉ 4. |
| **16** | `38` | `lhu  x13, 4(x0)` | `00405683` | `3C` | `01101` ($x_{13}$) | `0D` | `0123` | `LEDR = 0123` | Nạp nửa từ không dấu (LHU) từ RAM: $x_{13} = \text{0x0123}$. |
| **17** | `3C` | `addi x14, x0, 0` | `00000713` | `40` | `01110` ($x_{14}$) | `0E` | `0000` | Bình thường | Khởi tạo biến Fibonacci: $a = \text{Fib}(0) = 0$. |
| **18** | `40` | `addi x15, x0, 1` | `00100793` | `44` | `01111` ($x_{15}$) | `0F` | `0001` | Bình thường | Khởi tạo biến Fibonacci: $b = \text{Fib}(1) = 1$. |
| **19** | `44` | `addi x16, x0, 5` | `00500813` | `48` | `10000` ($x_{16}$) | `10` | `0005` | Bình thường | Khởi tạo biến đếm vòng lặp: $\text{counter} = 5$. |
| **20-24** | `48`..`58` | **VÒNG LẶP FIBONACCI (Lặp 5 lần)** | Nhiều lệnh | Nhảy lùi giữa `48` và `58` | `10001` ($x_{17}$) | `11` | Giá trị tăng dần: `1` $\rightarrow$ `2` $\rightarrow$ `3` $\rightarrow$ `5` $\rightarrow$ **`8`** | **`LEDG[2]=1` (Nhấp nháy mỗi khi rẽ nhánh)** | **CONTROL HAZARD:** Lệnh `bne x16, x0, -16` kiểm tra đếm $\neq 0$. Mỗi lần rẽ nhánh nhảy lùi về `0x48`, đèn `LEDG[2]` chớp sáng, đường ống tự động hủy 2 lệnh sai (Flush) và tính ra $\text{Fib}(6) = 8$. |
| **25** | `58` | `bne  x16, x0, -16` *(Lần 5: counter = 0)* | `fe0818e3` | `5C` | `10000` ($x_{16}$) | `10` | `0000` | `LEDG[2]=0` | Vòng lặp kết thúc vì counter đã giảm về 0, không rẽ nhánh nữa, đi thẳng tới `0x5C`. |
| **26** | `5C` | `addi x18, x0, 100` | `06400913` | `60` | `10010` ($x_{18}$) | `12` | `0064` | **`LEDR[17]=1` (SÁNG CHÓI)** | Ghi cờ hoàn tất: $x_{18} = 100$ (Hex: `0x0064`). Đèn đỏ `LEDR[17]` bật sáng xác nhận mọi bài test PASSED! |
| **27** | `60` | `beq  x0, x0, 0` | `00000063` | **`60` (Dừng lại)** | Bất kỳ | Theo switch | Theo switch | **`LEDR[16]=1` (SÁNG BÁO DỪNG)** | Lệnh dừng HALT: Vòng lặp vô tận tại chỗ để giữ nguyên kết quả trên board, CPU không bị chạy lung tung. |

---

## 3. BẢNG TỔNG KẾT GIÁ TRỊ CÁC THANH GHI KHI KẾT THÚC CHƯƠNG TRÌNH

Sau khi chạy xong chương trình, bạn gạt `SW[4:0]` để kiểm tra từng thanh ghi, giá trị hiển thị trên `HEX3-HEX0` sẽ đúng như sau:

| Tên thanh ghi | Địa chỉ nhị phân `SW[4:0]` | Hiển thị `HEX5-HEX4` | Hiển thị `HEX3-HEX0` (Hex) | Giá trị thập phân | Ý nghĩa kết quả |
| :---: | :---: | :---: | :---: | :---: | :--- |
| **$x_0$ (zero)** | `00000` | `00` | `0000` | 0 | Hằng số 0 chuẩn RISC-V |
| **$x_1$ (ra)** | `00001` | `01` | `0005` | 5 | Giá trị nạp ban đầu |
| **$x_2$ (sp)** | `00010` | `02` | `0003` | 3 | Giá trị nạp ban đầu |
| **$x_3$ (gp)** | `00011` | `03` | `0008` | 8 | Kết quả $x_1 + x_2$ (Forwarding) |
| **$x_4$ (tp)** | `00100` | `04` | `0002` | 2 | Kết quả $x_1 - x_2$ |
| **$x_5$ (t0)** | `00101` | `05` | `0001` | 1 | Kết quả $x_1 \ \& \ x_2$ |
| **$x_6$ (t1)` | `00110` | `06` | `0007` | 7 | Kết quả $x_1 \ \| \ x_2$ |
| **$x_7$ (t2)** | `00111` | `07` | `0006` | 6 | Kết quả $x_1 \oplus x_2$ |
| **$x_8$ (s0)** | `01000` | `08` | `0028` | 40 | Kết quả $x_1 \ll 3$ |
| **$x_9$ (s1)** | `01001` | `09` | `0001` | 1 | Kết quả so sánh $3 < 5$ |
| **$x_{10}$ (a0)** | `01010` | `0A` | `0008` | 8 | Đọc từ bộ nhớ RAM (`lw`) |
| **$x_{11}$ (a1)** | `01011` | `0B` | `000D` | 13 | Kết quả sau khi Stall Load-Use |
| **$x_{12}$ (a2)** | `01100` | `0C` | `0123` | 291 | Nạp tức thời `0x123` |
| **$x_{13}$ (a3)** | `01101` | `0D` | `0123` | 291 | Đọc nửa từ RAM (`lhu`) |
| **$x_{14}$ (a4)** | `01110` | `0E` | `0005` | 5 | Số Fibonacci $F_5$ |
| **$x_{15}$ (a5)** | `01111` | `0F` | `0008` | 8 | Số Fibonacci $F_6$ |
| **$x_{16}$ (a6)** | `10000` | `10` | `0000` | 0 | Biến đếm vòng lặp giảm về 0 |
| **$x_{17}$ (a7)** | `10001` | `11` | `0008` | 8 | **Kết quả Fibonacci cuối cùng: 8** |
| **$x_{18}$ (s2)** | `10010` | `12` | `0064` | 100 | **Cờ thành công (Success Marker = 100)** |

---

## 4. HƯỚNG DẪN THAO TÁC TRỰC QUAN KHI BÁO CÁO VỚI THẦY CÔ

Khi đứng trước board thí nghiệm Altera DE2 để demo:
1. **Bước 1 - Reset:** Nhấn nút **`KEY[1]`** một cái. Bạn sẽ thấy `HEX7-HEX6` hiển thị `00`, tất cả thanh ghi về `0000`.
2. **Bước 2 - Chọn chế độ bấm tay (Manual Step):** Gạt công tắc **`SW[17]` xuống (`0`)**. Lúc này CPU đứng yên chờ nhịp xung từ tay bạn.
3. **Bước 3 - Tiến từng bước:** Mỗi lần bạn nhấn nút **`KEY[0]`**, con trỏ lệnh trên `HEX7-HEX6` sẽ nhảy: `04` $\rightarrow$ `08` $\rightarrow$ `0C`...
4. **Bước 4 - Thể hiện tính năng Load-Use Stall:**
   * Khi PC đạt đến `2C` (lệnh số 12), bạn bấm `KEY[0]` thêm 1 lần thì thấy **PC vẫn đứng yên ở `2C`** và **đèn xanh `LEDG[1]` sáng rực lên**.
   * Bạn giải thích cho thầy cô: *"Thưa thầy/cô, đây là cơ chế phát hiện xung đột phụ thuộc dữ liệu Load-Use (Hazard Detection Unit), CPU đang chèn 1 bong bóng NOP để chờ dữ liệu từ bộ nhớ nạp về nên PC đứng yên 1 nhịp và đèn Stall sáng!"*
5. **Bước 5 - Thể hiện tính năng Rẽ nhánh (Branch Loop):**
   * Khi PC chạy vào vòng lặp từ `48` đến `58`, bạn bấm `KEY[0]` sẽ thấy PC nhảy lùi từ `58` về `48` lặp lại 5 lần, đồng thời **đèn xanh `LEDG[2]` chớp sáng** để báo hiệu rẽ nhánh thành công và hủy 2 lệnh sai (Flush).
6. **Bước 6 - Xác nhận hoàn tất:**
   * Khi PC đạt đến `60`, **đèn đỏ `LEDR[17]` và `LEDR[16]` sáng rực**.
   * Bạn gạt `SW[4:0]` thành `10010` ($x_{18}$), màn hình `HEX3-HEX0` hiển thị `0064` (chính là 100 thập phân). Chương trình chạy chuẩn xác 100%!
