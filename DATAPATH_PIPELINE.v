// ============================================================================
// DATAPATH_PIPELINE.v - Complete 5-Stage Pipelined Datapath for RISC-V RV32I
// Contains: IF/ID, ID/EX, EX/MEM, MEM/WB registers
//           ALU, ImmGen, Control, RegFile, DataMem, Forwarding & Hazard Units
// ============================================================================

`timescale 1ns/1ps

module DATAPATH_PIPELINE (
    input             clock,
    input             reset,
    input      [31:0] if_instruction,
    input      [31:0] if_pc,
    input      [31:0] if_pc_plus_4,
    output            stall_pc,
    output            ex_pc_src,
    output     [31:0] ex_pc_target,
    output     [31:0] wb_write_data,
    output     [4:0]  wb_rd,
    output            wb_regwrite,
    output            zero_flag,
    input      [4:0]  debug_reg_num,
    output     [31:0] debug_reg_data
);

    // ========================================================================
    // IF/ID Pipeline Register Signals
    // ========================================================================
    wire [31:0] id_instruction;
    wire [31:0] id_pc;
    wire [31:0] id_pc_plus_4;
    wire        stall_if_id;
    wire        flush_if_id;

    // ========================================================================
    // ID Stage Signals
    // ========================================================================
    wire [6:0]  id_opcode = id_instruction[6:0];
    wire [4:0]  id_rd     = id_instruction[11:7];
    wire [2:0]  id_funct3 = id_instruction[14:12];
    wire [4:0]  id_rs1    = id_instruction[19:15];
    wire [4:0]  id_rs2    = id_instruction[24:20];
    wire [6:0]  id_funct7 = id_instruction[31:25];

    wire [31:0] id_imm;
    wire [31:0] id_read_data1, id_read_data2;
    wire        id_regwrite;
    wire [1:0]  id_memtoreg;
    wire        id_memread;
    wire        id_memwrite;
    wire        id_branch;
    wire        id_jump;
    wire        id_jalr;
    wire        id_alusrc;
    wire        id_auipc;
    wire [3:0]  id_alu_control;

    // ========================================================================
    // ID/EX Pipeline Register Signals
    // ========================================================================
    wire        flush_id_ex;
    wire        ex_regwrite;
    wire [1:0]  ex_memtoreg;
    wire        ex_memread;
    wire        ex_memwrite;
    wire        ex_branch;
    wire        ex_jump;
    wire        ex_jalr;
    wire        ex_alusrc;
    wire        ex_auipc;
    wire [3:0]  ex_alu_control;

    wire [31:0] ex_pc;
    wire [31:0] ex_pc_plus_4;
    wire [31:0] ex_read_data1, ex_read_data2;
    wire [31:0] ex_imm;
    wire [2:0]  ex_funct3;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;

    // ========================================================================
    // EX Stage Signals
    // ========================================================================
    wire [1:0]  forward_a, forward_b;
    wire        forward_mem_data;
    wire [31:0] ex_alu_input_a_fwd;
    wire [31:0] ex_alu_input_b_fwd;
    wire [31:0] ex_alu_in1;
    wire [31:0] ex_alu_in2;
    wire [31:0] ex_alu_result;
    wire        ex_zero;

    // ========================================================================
    // EX/MEM Pipeline Register Signals
    // ========================================================================
    wire        mem_regwrite;
    wire [1:0]  mem_memtoreg;
    wire        mem_memread;
    wire        mem_memwrite;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_write_data;
    wire [4:0]  mem_rs2;
    wire [4:0]  mem_rd;
    wire [31:0] mem_pc_plus_4;
    wire [2:0]  mem_funct3;
    wire [31:0] mem_read_data;
    wire [31:0] mem_store_data_final;

    // ========================================================================
    // MEM/WB Pipeline Register Signals
    // ========================================================================
    wire [1:0]  wb_memtoreg;
    wire [31:0] wb_alu_result;
    wire [31:0] wb_read_data;
    wire [31:0] wb_pc_plus_4;

    assign zero_flag = ex_zero;

    // ========================================================================
    // 1. IF/ID Pipeline Register
    // ========================================================================
    IF_ID_REG if_id_reg (
        .clock(clock),
        .reset(reset),
        .stall(stall_if_id),
        .flush(flush_if_id),
        .if_pc(if_pc),
        .if_pc_plus_4(if_pc_plus_4),
        .if_instruction(if_instruction),
        .id_pc(id_pc),
        .id_pc_plus_4(id_pc_plus_4),
        .id_instruction(id_instruction)
    );

    // ========================================================================
    // 2. ID Stage: Decode, Control, ImmGen, RegFile
    // ========================================================================
    IMM_GEN imm_generator (
        .instruction(id_instruction),
        .imm_ext(id_imm)
    );

    CONTROL control_unit (
        .opcode(id_opcode),
        .funct3(id_funct3),
        .funct7(id_funct7),
        .regwrite(id_regwrite),
        .memtoreg(id_memtoreg),
        .memread(id_memread),
        .memwrite(id_memwrite),
        .branch(id_branch),
        .jump(id_jump),
        .jalr(id_jalr),
        .alusrc(id_alusrc),
        .auipc(id_auipc),
        .alu_control(id_alu_control)
    );

    REG_FILE reg_file (
        .clock(clock),
        .reset(reset),
        .regwrite(wb_regwrite),
        .read_reg_num1(id_rs1),
        .read_reg_num2(id_rs2),
        .write_reg(wb_rd),
        .write_data(wb_write_data),
        .read_data1(id_read_data1),
        .read_data2(id_read_data2),
        .debug_reg_num(debug_reg_num),
        .debug_reg_data(debug_reg_data)
    );

    // Hazard Detection Unit
    HAZARD_DETECTION hazard_unit (
        .id_ex_rd(ex_rd),
        .id_ex_memread(ex_memread),
        .if_id_rs1(id_rs1),
        .if_id_rs2(id_rs2),
        .if_id_opcode(id_opcode),
        .branch_taken_ex(ex_pc_src),
        .stall_pc(stall_pc),
        .stall_if_id(stall_if_id),
        .flush_if_id(flush_if_id),
        .flush_id_ex(flush_id_ex)
    );

    // ========================================================================
    // 3. ID/EX Pipeline Register
    // ========================================================================
    ID_EX_REG id_ex_reg (
        .clock(clock),
        .reset(reset),
        .flush(flush_id_ex),
        .id_regwrite(id_regwrite),
        .id_memtoreg(id_memtoreg),
        .id_memread(id_memread),
        .id_memwrite(id_memwrite),
        .id_branch(id_branch),
        .id_jump(id_jump),
        .id_jalr(id_jalr),
        .id_alusrc(id_alusrc),
        .id_auipc(id_auipc),
        .id_alu_control(id_alu_control),
        .id_pc(id_pc),
        .id_pc_plus_4(id_pc_plus_4),
        .id_read_data1(id_read_data1),
        .id_read_data2(id_read_data2),
        .id_imm(id_imm),
        .id_funct3(id_funct3),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_rd(id_rd),
        .ex_regwrite(ex_regwrite),
        .ex_memtoreg(ex_memtoreg),
        .ex_memread(ex_memread),
        .ex_memwrite(ex_memwrite),
        .ex_branch(ex_branch),
        .ex_jump(ex_jump),
        .ex_jalr(ex_jalr),
        .ex_alusrc(ex_alusrc),
        .ex_auipc(ex_auipc),
        .ex_alu_control(ex_alu_control),
        .ex_pc(ex_pc),
        .ex_pc_plus_4(ex_pc_plus_4),
        .ex_read_data1(ex_read_data1),
        .ex_read_data2(ex_read_data2),
        .ex_imm(ex_imm),
        .ex_funct3(ex_funct3),
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .ex_rd(ex_rd)
    );

    // ========================================================================
    // 4. EX Stage: Forwarding, ALU, Branch Evaluation
    // ========================================================================
    FORWARDING_UNIT forwarding_unit (
        .id_ex_rs1(ex_rs1),
        .id_ex_rs2(ex_rs2),
        .ex_mem_rs2(mem_rs2),
        .ex_mem_rd(mem_rd),
        .ex_mem_regwrite(mem_regwrite),
        .mem_wb_rd(wb_rd),
        .mem_wb_regwrite(wb_regwrite),
        .forward_a(forward_a),
        .forward_b(forward_b),
        .forward_mem_data(forward_mem_data)
    );

    // Forwarding Muxes
    assign ex_alu_input_a_fwd = (forward_a == 2'b10) ? mem_alu_result :
                                (forward_a == 2'b01) ? wb_write_data :
                                ex_read_data1;

    assign ex_alu_input_b_fwd = (forward_b == 2'b10) ? mem_alu_result :
                                (forward_b == 2'b01) ? wb_write_data :
                                ex_read_data2;

    // ALU input selection
    assign ex_alu_in1 = (ex_auipc)  ? ex_pc : ex_alu_input_a_fwd;
    assign ex_alu_in2 = (ex_alusrc) ? ex_imm : ex_alu_input_b_fwd;

    ALU alu_inst (
        .in1(ex_alu_in1),
        .in2(ex_alu_in2),
        .alu_control(ex_alu_control),
        .alu_result(ex_alu_result),
        .zero_flag(ex_zero)
    );

    // Branch condition evaluation
    reg branch_condition_met;
    always @(*) begin
        case (ex_funct3)
            3'b000: branch_condition_met = (ex_alu_input_a_fwd == ex_alu_input_b_fwd);                    // BEQ
            3'b001: branch_condition_met = (ex_alu_input_a_fwd != ex_alu_input_b_fwd);                    // BNE
            3'b100: branch_condition_met = ($signed(ex_alu_input_a_fwd) < $signed(ex_alu_input_b_fwd));  // BLT
            3'b101: branch_condition_met = ($signed(ex_alu_input_a_fwd) >= $signed(ex_alu_input_b_fwd)); // BGE
            3'b110: branch_condition_met = (ex_alu_input_a_fwd < ex_alu_input_b_fwd);                    // BLTU
            3'b111: branch_condition_met = (ex_alu_input_a_fwd >= ex_alu_input_b_fwd);                   // BGEU
            default: branch_condition_met = 1'b0;
        endcase
    end

    wire branch_taken = ex_branch & branch_condition_met;
    assign ex_pc_src = branch_taken | ex_jump;
    assign ex_pc_target = (ex_jalr) ? ((ex_alu_input_a_fwd + ex_imm) & ~32'd1) : (ex_pc + ex_imm);

    // ========================================================================
    // 5. EX/MEM Pipeline Register
    // ========================================================================
    EX_MEM_REG ex_mem_reg (
        .clock(clock),
        .reset(reset),
        .ex_regwrite(ex_regwrite),
        .ex_memtoreg(ex_memtoreg),
        .ex_memread(ex_memread),
        .ex_memwrite(ex_memwrite),
        .ex_alu_result(ex_alu_result),
        .ex_write_data(ex_alu_input_b_fwd),
        .ex_rs2(ex_rs2),
        .ex_rd(ex_rd),
        .ex_pc_plus_4(ex_pc_plus_4),
        .ex_funct3(ex_funct3),
        .mem_regwrite(mem_regwrite),
        .mem_memtoreg(mem_memtoreg),
        .mem_memread(mem_memread),
        .mem_memwrite(mem_memwrite),
        .mem_alu_result(mem_alu_result),
        .mem_write_data(mem_write_data),
        .mem_rs2(mem_rs2),
        .mem_rd(mem_rd),
        .mem_pc_plus_4(mem_pc_plus_4),
        .mem_funct3(mem_funct3)
    );

    // ========================================================================
    // 6. MEM Stage: Data Memory
    // ========================================================================
    assign mem_store_data_final = (forward_mem_data) ? wb_write_data : mem_write_data;

    DATA_MEM data_memory (
        .clock(clock),
        .reset(reset),
        .mem_read(mem_memread),
        .mem_write(mem_memwrite),
        .funct3(mem_funct3),
        .address(mem_alu_result),
        .write_data(mem_store_data_final),
        .read_data(mem_read_data)
    );

    // ========================================================================
    // 7. MEM/WB Pipeline Register
    // ========================================================================
    MEM_WB_REG mem_wb_reg (
        .clock(clock),
        .reset(reset),
        .mem_regwrite(mem_regwrite),
        .mem_memtoreg(mem_memtoreg),
        .mem_alu_result(mem_alu_result),
        .mem_read_data(mem_read_data),
        .mem_pc_plus_4(mem_pc_plus_4),
        .mem_rd(mem_rd),
        .wb_regwrite(wb_regwrite),
        .wb_memtoreg(wb_memtoreg),
        .wb_alu_result(wb_alu_result),
        .wb_read_data(wb_read_data),
        .wb_pc_plus_4(wb_pc_plus_4),
        .wb_rd(wb_rd)
    );

    // ========================================================================
    // 8. WB Stage: Write Back Mux
    // ========================================================================
    assign wb_write_data = (wb_memtoreg == 2'b00) ? wb_alu_result :
                           (wb_memtoreg == 2'b01) ? wb_read_data :
                           (wb_memtoreg == 2'b10) ? wb_pc_plus_4 :
                           wb_alu_result;

endmodule