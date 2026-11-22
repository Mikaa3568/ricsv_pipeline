# ============================================================================
# DE2_pins.tcl - Pin Assignments for Altera DE2 Board (Cyclone II EP2C35F672C6)
# Huong dan su dung trong Quartus II:
#   Cach 1: Mo Quartus -> Tools -> Tcl Scripts... -> Chon DE2_pins.tcl -> Run
#   Cach 2: Trong cua so Tcl Console o duoi Quartus, go: source DE2_pins.tcl
# ============================================================================

package require ::quartus::project

# 1. Thiet lap Top-level Entity
set_global_assignment -name TOP_LEVEL_ENTITY DE2_TOP_RISC_V

# 2. Xung Nhip (Clock 50MHz)
set_location_assignment PIN_N2 -to CLOCK_50

# 3. Nut bam (Push Buttons - Active Low)
set_location_assignment PIN_G26 -to KEY[0]
set_location_assignment PIN_N23 -to KEY[1]
set_location_assignment PIN_P23 -to KEY[2]
set_location_assignment PIN_W26 -to KEY[3]

# 4. Cong tac gat (Slide Switches SW[17:0])
set_location_assignment PIN_N25 -to SW[0]
set_location_assignment PIN_N26 -to SW[1]
set_location_assignment PIN_P25 -to SW[2]
set_location_assignment PIN_AE14 -to SW[3]
set_location_assignment PIN_AF14 -to SW[4]
set_location_assignment PIN_AD13 -to SW[5]
set_location_assignment PIN_AC13 -to SW[6]
set_location_assignment PIN_C13 -to SW[7]
set_location_assignment PIN_B13 -to SW[8]
set_location_assignment PIN_A13 -to SW[9]
set_location_assignment PIN_N1 -to SW[10]
set_location_assignment PIN_P1 -to SW[11]
set_location_assignment PIN_P2 -to SW[12]
set_location_assignment PIN_T7 -to SW[13]
set_location_assignment PIN_U3 -to SW[14]
set_location_assignment PIN_U4 -to SW[15]
set_location_assignment PIN_V1 -to SW[16]
set_location_assignment PIN_V2 -to SW[17]

# 5. Den LED 7-Doan HEX0 (Active Low)
set_location_assignment PIN_AF10 -to HEX0[0]
set_location_assignment PIN_AB12 -to HEX0[1]
set_location_assignment PIN_AC12 -to HEX0[2]
set_location_assignment PIN_AD11 -to HEX0[3]
set_location_assignment PIN_AE11 -to HEX0[4]
set_location_assignment PIN_V14 -to HEX0[5]
set_location_assignment PIN_V13 -to HEX0[6]

# 6. Den LED 7-Doan HEX1 (Active Low)
set_location_assignment PIN_V20 -to HEX1[0]
set_location_assignment PIN_V21 -to HEX1[1]
set_location_assignment PIN_W21 -to HEX1[2]
set_location_assignment PIN_Y22 -to HEX1[3]
set_location_assignment PIN_AA24 -to HEX1[4]
set_location_assignment PIN_AA23 -to HEX1[5]
set_location_assignment PIN_AB24 -to HEX1[6]

# 7. Den LED 7-Doan HEX2 (Active Low)
set_location_assignment PIN_AB23 -to HEX2[0]
set_location_assignment PIN_V22 -to HEX2[1]
set_location_assignment PIN_AC25 -to HEX2[2]
set_location_assignment PIN_AC26 -to HEX2[3]
set_location_assignment PIN_AB26 -to HEX2[4]
set_location_assignment PIN_AB25 -to HEX2[5]
set_location_assignment PIN_Y24 -to HEX2[6]

# 8. Den LED 7-Doan HEX3 (Active Low)
set_location_assignment PIN_Y23 -to HEX3[0]
set_location_assignment PIN_AA25 -to HEX3[1]
set_location_assignment PIN_AA26 -to HEX3[2]
set_location_assignment PIN_Y26 -to HEX3[3]
set_location_assignment PIN_Y25 -to HEX3[4]
set_location_assignment PIN_U22 -to HEX3[5]
set_location_assignment PIN_W24 -to HEX3[6]

# 9. Den LED 7-Doan HEX4 (Active Low)
set_location_assignment PIN_U9 -to HEX4[0]
set_location_assignment PIN_U1 -to HEX4[1]
set_location_assignment PIN_U2 -to HEX4[2]
set_location_assignment PIN_T4 -to HEX4[3]
set_location_assignment PIN_R7 -to HEX4[4]
set_location_assignment PIN_R6 -to HEX4[5]
set_location_assignment PIN_T3 -to HEX4[6]

# 10. Den LED 7-Doan HEX5 (Active Low)
set_location_assignment PIN_T2 -to HEX5[0]
set_location_assignment PIN_P6 -to HEX5[1]
set_location_assignment PIN_P7 -to HEX5[2]
set_location_assignment PIN_T9 -to HEX5[3]
set_location_assignment PIN_R5 -to HEX5[4]
set_location_assignment PIN_R4 -to HEX5[5]
set_location_assignment PIN_R3 -to HEX5[6]

# 11. Den LED 7-Doan HEX6 (Active Low)
set_location_assignment PIN_R2 -to HEX6[0]
set_location_assignment PIN_P4 -to HEX6[1]
set_location_assignment PIN_P3 -to HEX6[2]
set_location_assignment PIN_M9 -to HEX6[3]
set_location_assignment PIN_M8 -to HEX6[4]
set_location_assignment PIN_M7 -to HEX6[5]
set_location_assignment PIN_M6 -to HEX6[6]

# 12. Den LED 7-Doan HEX7 (Active Low)
set_location_assignment PIN_M5 -to HEX7[0]
set_location_assignment PIN_M4 -to HEX7[1]
set_location_assignment PIN_M3 -to HEX7[2]
set_location_assignment PIN_M2 -to HEX7[3]
set_location_assignment PIN_K9 -to HEX7[4]
set_location_assignment PIN_K8 -to HEX7[5]
set_location_assignment PIN_K7 -to HEX7[6]

# 13. Den LED Xanh (LEDG[8:0])
set_location_assignment PIN_AE22 -to LEDG[0]
set_location_assignment PIN_AF22 -to LEDG[1]
set_location_assignment PIN_W19 -to LEDG[2]
set_location_assignment PIN_V18 -to LEDG[3]
set_location_assignment PIN_U18 -to LEDG[4]
set_location_assignment PIN_U17 -to LEDG[5]
set_location_assignment PIN_AA20 -to LEDG[6]
set_location_assignment PIN_Y18 -to LEDG[7]
set_location_assignment PIN_Y12 -to LEDG[8]

# 14. Den LED Do (LEDR[17:0])
set_location_assignment PIN_AE23 -to LEDR[0]
set_location_assignment PIN_AF23 -to LEDR[1]
set_location_assignment PIN_AB21 -to LEDR[2]
set_location_assignment PIN_AC22 -to LEDR[3]
set_location_assignment PIN_AD22 -to LEDR[4]
set_location_assignment PIN_AD23 -to LEDR[5]
set_location_assignment PIN_AD21 -to LEDR[6]
set_location_assignment PIN_AC21 -to LEDR[7]
set_location_assignment PIN_AA14 -to LEDR[8]
set_location_assignment PIN_Y13 -to LEDR[9]
set_location_assignment PIN_AA13 -to LEDR[10]
set_location_assignment PIN_AC14 -to LEDR[11]
set_location_assignment PIN_AD15 -to LEDR[12]
set_location_assignment PIN_AE15 -to LEDR[13]
set_location_assignment PIN_AF13 -to LEDR[14]
set_location_assignment PIN_AE13 -to LEDR[15]
set_location_assignment PIN_AE12 -to LEDR[16]
set_location_assignment PIN_AD12 -to LEDR[17]

# Luu cac thiet lap vao QSF
project_save
puts ">>> [THANH CONG] Da gan toan bo chan cho Board Altera DE2 vao du an Quartus! <<<"

