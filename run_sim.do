# ============================================================================
# run_sim.do - ModelSim Automated Simulation Script for RISC-V Pipeline
# Usage:
#   1. Open ModelSim
#   2. Run command: do "d:/hoctap/ki 7/do_an_thiet_ke_1/Risc_v_Pipeline/run_sim.do"
#      hoac:        cd "d:/hoctap/ki 7/do_an_thiet_ke_1/Risc_v_Pipeline"; do run_sim.do
#   3. Hoac chi can Double-click file "run_modelsim.bat"
# ============================================================================

# Tu dong chuyen thu muc lam viec ve thu muc chua code
if {![file exists "ALU.v"]} {
    cd "d:/hoctap/ki 7/do_an_thiet_ke_1/Risc_v_Pipeline"
}

# 1. Reset simulation environment
quit -sim
transcript on

# 2. Create and map working library
if {![file exists work]} {
    vlib work
}
vmap work work

# 3. Compile all design Verilog modules
vlog -vlog01compat -work work ALU.v
vlog -vlog01compat -work work CONTROL.v
vlog -vlog01compat -work work IMM_GEN.v
vlog -vlog01compat -work work REG_FILE.v
vlog -vlog01compat -work work INST_MEM.v
vlog -vlog01compat -work work DATA_MEM.v
vlog -vlog01compat -work work IF_ID_REG.v
vlog -vlog01compat -work work ID_EX_REG.v
vlog -vlog01compat -work work EX_MEM_REG.v
vlog -vlog01compat -work work MEM_WB_REG.v
vlog -vlog01compat -work work FORWARDING_UNIT.v
vlog -vlog01compat -work work HAZARD_DETECTION.v
vlog -vlog01compat -work work DATAPATH_PIPELINE.v
vlog -vlog01compat -work work PROCESSOR_PIPELINE.v

# 4. Compile Testbench
vlog -vlog01compat -work work PROCESSOR_PIPELINE_tb.v

# 5. Load simulation with full signal visibility
vsim -voptargs="+acc" work.PROCESSOR_PIPELINE_tb

# 6. Setup Waveform window
catch {delete wave *}

add wave -noupdate -divider {CLOCKS & CONTROL}
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/clock
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/reset
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/zero

add wave -noupdate -divider {IF - INSTRUCTION FETCH}
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/if_pc
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/if_instruction
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/stall_pc

add wave -noupdate -divider {ID - INSTRUCTION DECODE}
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_pc
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_instruction
add wave -noupdate -radix decimal     /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_rs1
add wave -noupdate -radix decimal     /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_rs2
add wave -noupdate -radix decimal     /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_rd
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_imm
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_read_data1
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/id_read_data2

add wave -noupdate -divider {EX - EXECUTION & ALU}
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/ex_alu_in1
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/ex_alu_in2
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/ex_alu_result
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/datapath_module/forward_a
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/datapath_module/forward_b
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/ex_pc_src
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/ex_pc_target

add wave -noupdate -divider {MEM - DATA MEMORY}
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/datapath_module/mem_memread
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/datapath_module/mem_memwrite
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/mem_alu_result
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/mem_write_data
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/mem_read_data

add wave -noupdate -divider {WB - WRITE BACK}
add wave -noupdate -radix binary      /PROCESSOR_PIPELINE_tb/uut/datapath_module/wb_regwrite
add wave -noupdate -radix decimal     /PROCESSOR_PIPELINE_tb/uut/datapath_module/wb_rd
add wave -noupdate -radix hexadecimal /PROCESSOR_PIPELINE_tb/uut/datapath_module/wb_write_data

add wave -noupdate -divider {KEY REGISTERS}
add wave -noupdate -label {x1 (ra)}  -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[1]}
add wave -noupdate -label {x2 (sp)}  -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[2]}
add wave -noupdate -label {x3 (gp)}  -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[3]}
add wave -noupdate -label {x4 (tp)}  -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[4]}
add wave -noupdate -label {x10 (a0)} -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[10]}
add wave -noupdate -label {x11 (a1)} -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[11]}
add wave -noupdate -label {x12 (a2)} -radix hexadecimal {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[12]}
add wave -noupdate -label {x13 (a3)} -radix hexadecimal {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[13]}
add wave -noupdate -label {x16 (a6)} -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[16]}
add wave -noupdate -label {x17 (a7)} -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[17]}
add wave -noupdate -label {x18 (s2)} -radix decimal     {/PROCESSOR_PIPELINE_tb/uut/datapath_module/reg_file/reg_memory[18]}

# 7. Run Simulation
run 1500ns
wave zoom full
