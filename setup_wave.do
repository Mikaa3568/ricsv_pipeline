# ============================================================================
# setup_wave.do - Chuan hoa cho ModelSim Altera / PE
# ============================================================================

# 1. Mo cua so Wave va xoa an toan
view wave
catch {delete wave *}

# 2. Xung Clock va Reset
add wave -noupdate -divider "CLOCKS & CONTROL"
add wave -noupdate -color yellow  -radix binary /PROCESSOR_PIPELINE_tb/clock
add wave -noupdate -color magenta -radix binary /PROCESSOR_PIPELINE_tb/reset
add wave -noupdate -color gray    -radix binary /PROCESSOR_PIPELINE_tb/zero

# 3. Con tro lenh PC va Ma lenh (He Hexadecimal)
add wave -noupdate -divider "PC & INSTRUCTION"
add wave -noupdate -color cyan    -radix hex -label "PC (Hex)"          /PROCESSOR_PIPELINE_tb/debug_pc
add wave -noupdate -color orange  -radix hex -label "Instruction (Hex)" /PROCESSOR_PIPELINE_tb/debug_instruction

# 4. Co bao xung dot Stall va Re nhanh (He Binary)
add wave -noupdate -divider "PIPELINE HAZARDS"
add wave -noupdate -color red     -radix binary -label "STALL Flag"       /PROCESSOR_PIPELINE_tb/debug_stall
add wave -noupdate -color green   -radix binary -label "BRANCH TAKEN"     /PROCESSOR_PIPELINE_tb/debug_branch_taken

# 5. Tin hieu chuyen tiep Forwarding va Ket qua ALU
add wave -noupdate -divider "DATA FORWARDING & ALU"
add wave -noupdate -color blue    -radix binary  -label "Forward A"       /PROCESSOR_PIPELINE_tb/uut/datapath_module/forward_a
add wave -noupdate -color blue    -radix binary  -label "Forward B"       /PROCESSOR_PIPELINE_tb/uut/datapath_module/forward_b
add wave -noupdate -color white   -radix decimal -label "ALU Result (Dec)" /PROCESSOR_PIPELINE_tb/uut/datapath_module/ex_alu_result

# 6. Du lieu ghi nguoc Write-Back (He Decimal)
add wave -noupdate -divider "WRITE-BACK DATA"
add wave -noupdate -color yellow  -radix decimal -label "WB Data (Dec)"   /PROCESSOR_PIPELINE_tb/debug_wb_data

# 7. Cac thanh ghi quan trong (He Decimal)
add wave -noupdate -divider "REGISTER FILE"
add wave -noupdate -color cyan    -radix decimal -label "x1 (ra) = 5"          {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[1]}
add wave -noupdate -color cyan    -radix decimal -label "x2 (sp) = 3"          {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[2]}
add wave -noupdate -color yellow  -radix decimal -label "x3 (gp) = 8 [Fwd]"    {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[3]}
add wave -noupdate -color green   -radix decimal -label "x10 (a0) = 8 [LW]"    {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[10]}
add wave -noupdate -color red     -radix decimal -label "x11 (a1) = 13 [Stall]" {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[11]}
add wave -noupdate -color orange  -radix hex     -label "x12 (a2) = 0x123"     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[12]}
add wave -noupdate -color orange  -radix hex     -label "x13 (a3) = 0x123"     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[13]}
add wave -noupdate -color white   -radix decimal -label "x16 (a6) = Counter"   {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[16]}
add wave -noupdate -color green   -radix decimal -label "x17 (a7) = Fib(6)=8"  {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[17]}
add wave -noupdate -color yellow  -radix decimal -label "x18 (s2) = Done 100"  {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[18]}

# 8. Chay lai de ve song
restart -f
run 1300ns
wave zoom full
