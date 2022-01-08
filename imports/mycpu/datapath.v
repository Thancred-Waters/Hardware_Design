module datapath (
    input wire clk, rst,
    input wire [5:0] ext_int,
    
    //inst
    output wire [31:0] pcF,
    output wire [31:0] pc_next,
    output wire inst_enF,
    input wire [31:0] instrF,
    input wire i_cache_stall,
    output wire stallF,
    output wire stallM,

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,
    input wire [31:0] mem_rdataM,
    output wire [3:0] mem_wenM,
    output wire [31:0] mem_wdataM,
    input wire d_cache_stall,
    output wire [31:0] mem_addrE,
    output wire mem_read_enE,
    output wire mem_write_enE,

    //debug
    output wire [31:0]  debug_wb_pc,      
    output wire [3:0]   debug_wb_rf_wen,
    output wire [4:0]   debug_wb_rf_wnum, 
    output wire [31:0]  debug_wb_rf_wdata
);

//IF
    wire [31:0] pc_plus4F;
    wire pc_reg_ceF;
    wire [2:0] pc_sel;
    wire [31:0] instrF_temp;
    wire is_in_delayslot_iF;
//ID
    wire [31:0] instrD;
    wire [31:0] pcD, pc_plus4D;
    wire [4:0] rsD, rtD, rdD, saD;

    wire [31:0] rd1D, rd2D;
    wire [31:0] immD;
    wire sign_extD;
    wire [31:0] pc_branchD;
    wire pred_takeD;
    wire branchD;
    wire failedM;
    wire [31:0] pc_jumpD;
    wire jumpD;
    wire jump_conflictD;
    wire is_in_delayslot_iD;
    wire [4:0] alu_controlD;
    wire [4:0] branch_judge_controlD;
    wire is_divD;
//EX
    wire [31:0] pcE;
    wire [31:0] rd1E, rd2E;
    wire [4:0] rsE, rtE, rdE, saE;
    wire [31:0] immE;
    wire [31:0] pc_plus4E;
    wire pred_takeE;

    wire [1:0] reg_dstE;
    wire [4:0] alu_controlE;

    wire [31:0] src_aE, src_bE;
    wire [31:0] alu_outE;
    wire alu_imm_selE;
    wire [4:0] reg_writeE;
    wire [31:0] instrE;
    wire branchE;
    wire [31:0] pc_branchE;
    wire [31:0] pc_jumpE;
    wire jump_conflictE;
    wire reg_write_enE;
    wire div_stallE;
    wire [31:0] rs_valueE, rt_valueE;
    wire flush_jump_confilctE;
    wire is_in_delayslot_iE;
    wire overflowE;
    wire jumpE;
    wire actual_takeE;
    wire [4:0] branch_judge_controlE;
//MEM
    wire [31:0] pcM;
    wire [31:0] alu_outM;
    wire [4:0] reg_writeM;
    wire [31:0] instrM;
    wire mem_read_enM;
    wire mem_write_enM;
    wire reg_write_enM;
    wire mem_to_regM;
    wire [31:0] resultM;
    wire [31:0] resultM_without_rdata;
    wire actual_takeM;
    wire succM;
    wire pred_takeM;
    wire branchM;
    wire [31:0] pc_branchM;

    wire [31:0] mem_ctrl_rdataM;

    wire hilo_wenE;
    wire [31:0] hilo_oM;
    wire hilo_to_regM;
    wire riM;
    wire breakM;
    wire syscallM;
    wire eretM;
    wire overflowM;
    wire addrErrorLwM, addrErrorSwM;
    wire pcErrorM;

    wire [31:0] except_typeM;

    wire flush_exceptionM;
    wire [31:0] pc_exceptionM;
    wire pc_trapM;
    wire [31:0] badvaddrM;
    wire is_in_delayslot_iM;
    wire [4:0] rdM;
    wire cp0_to_regM;
    wire cp0_wenM;
    wire [31:0] rt_valueM;
//WB
    wire [31:0] pcW;
    wire reg_write_enW;
    wire [31:0] alu_outW;
    wire [4:0] reg_writeW;
    wire [31:0] resultW;

    wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_data_oW;
    
    wire [7:0] l_s_typeD, l_s_typeE, l_s_typeM;
    wire mult_stallE;
    wire is_multD;

    wire stallD, stallE, stallW;
    wire flushF, flushD, flushE, flushM, flushW;

    wire [1:0] forward_aE, forward_bE;

// stall

//--------------------debug---------------------
    assign debug_wb_pc          = datapath.pcM;
    assign debug_wb_rf_wen      = {4{reg_write_enM & ~stallW & ~flush_exceptionM}};
    assign debug_wb_rf_wnum     = datapath.reg_writeM;
    assign debug_wb_rf_wdata    = datapath.resultM;
//-------------------------------------------------------------------
    //WARNING!!!
    //修改组合逻辑的时候要小心，细微变动都可能导致时序不满足

    main_decoder main_dec(
        .clk(clk), .rst(rst),
        .instrD(instrD),
        
        .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushE(flushE), .flushM(flushM), .flushW(flushW),
        //ID
        .sign_extD(sign_extD),
        .is_divD(is_divD),
        .is_multD(is_multD),
        .l_s_typeD(l_s_typeD),
        //EX
        .reg_dstE(reg_dstE),
        .alu_imm_selE(alu_imm_selE),
        .reg_write_enE(reg_write_enE),
        .hilo_wenE(hilo_wenE),
        .mem_read_enE(mem_read_enE),
        .mem_write_enE(mem_write_enE),
        //MEM
        .mem_read_enM(mem_read_enM),
        .mem_write_enM(mem_write_enM),
        .reg_write_enM(reg_write_enM),
        .mem_to_regM(mem_to_regM),
        .hilo_to_regM(hilo_to_regM),
        .riM(riM),
        .breakM(breakM),
        .syscallM(syscallM),
        .eretM(eretM),
        .cp0_wenM(cp0_wenM),
        .cp0_to_regM(cp0_to_regM)

        //WB
    );
    alu_decoder alu_dec(
        .instrD(instrD),
        .alu_controlD(alu_controlD),
        .branch_judge_controlD(branch_judge_controlD)
    );
   
    hazard hazard(
        .clk(clk), .rst(rst),
        .l_s_typeE(l_s_typeE),

        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .mem_read_enM(mem_read_enM),
        .mem_write_enM(mem_write_enM),
        .div_stallE(div_stallE),
        .mult_stallE(mult_stallE),

        .flush_jump_confilctE   (flush_jump_confilctE),
        .flush_pred_failedM     (failedM),
        .flush_exceptionM       (flush_exceptionM),

        .rsE(rsE),  .rsD(rsD),
        .rtE(rtE),  .rtD(rtD),
        .reg_write_enM(reg_write_enM),
        .reg_write_enE(reg_write_enE),
        .reg_write_enW(reg_write_enW),
        .reg_writeE(reg_writeE),
        .reg_writeM(reg_writeM),
        .reg_writeW(reg_writeW),

        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushF(flushF), .flushD(flushD), .flushE(flushE), .flushM(flushM), .flushW(flushW),
        .forward_aE(forward_aE), .forward_bE(forward_bE)
    );

//IF
    assign pc_plus4F = pcF + 4;
    
    pc_ctrl pc_gen(
        //此处必须将选择信号放到一个独立模块中，不然可能会引起布局变化？导致时序不满足
        //vivado未解之谜
        //branch
        .branchD(branchD),              //D阶段是branch指令
        .branchM(branchM),              //M阶段是branch指令
        .pred_takeD(pred_takeD),        //D阶段预测跳转
        .succM(succM),                  //M阶段验证预测正确
        .actual_takeM(actual_takeM),    //M阶段判断跳转

        //jump + exception
        .pc_trapM(pc_trapM),            //M阶段异常
        .jumpD(jumpD),                  //D阶段是jump类指令
        .jump_conflictD(jump_conflictD),//D阶段jump数据冲突
        .jump_conflictE(jump_conflictE),//D阶段的jump冲突传到E阶段

        .pc_sel(pc_sel)
    );

    //根据上一步的选择信号生成下一步的PC
    assign pc_next = {32{pc_sel==3'b000}} & pc_plus4F |   //顺序执行
                     {32{pc_sel==3'b001}} & pc_branchD |  //分支预测跳转
                     {32{pc_sel==3'b010}} & pc_jumpD |    //普通跳转指令，或者jr类指令，但是没有发生写后读WAR相关
                     {32{pc_sel==3'b011}} & pc_jumpE |    //EXE阶段通过前推，获得了jrl类指令的地址
                     {32{pc_sel==3'b100}} & pc_branchM |  //预测不跳转，实际跳转，属于预测失误后刷新
                     {32{pc_sel==3'b101}} & pc_plus4E |   //预测跳转，实际不跳转，属于预测失误后刷新
                     {32{pc_sel==3'b110}} & pc_exceptionM;//流水线出现异常，跳转到0xbfc0_0380或者ERET的地址

    pc_reg pc(//pc寄存器
        .clk(clk),
        .stallF(stallF),
        .rst(rst),
        .pc_next(pc_next),

        .pc(pcF),
        .ce(pc_reg_ceF)
    );

    assign inst_enF = pc_reg_ceF & ~flush_exceptionM;//pcF是否有效

    assign instrF_temp = {32{~(|(pcF[1:0]))}} & instrF;
    assign is_in_delayslot_iF = branchD | jumpD;//上一条指令是跳转指令
    //IF_ID
    if_id if_id(
        .clk(clk), .rst(rst),
        .stallD(stallD),
        .flushD(flushD),
        .pcF(pcF),
        .pc_plus4F(pc_plus4F),
        .instrF(instrF_temp),
        .is_in_delayslot_iF(is_in_delayslot_iF),
        
        .pcD(pcD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .is_in_delayslot_iD(is_in_delayslot_iD)
    );

    //ID
    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];
    assign saD = instrD[10:6];
    assign immD = {{16{instrD[15] & sign_extD}}, instrD[15:0]};//直接将sign_extD与立即数高位与，得到要扩展的符号，代替mux2
    assign pc_branchD = {{14{instrD[15] & sign_extD}}, instrD[15:0], 2'b00} + pc_plus4D;//直接将立即数左移用符号扩展代替，并填入2'b00，与immD同步生成


    regfile regfile(//wb阶段写入
        .clk(clk),
        .stallW(stallW),
        .we3(reg_write_enM & ~flush_exceptionM),
        .ra1(rsD), 
        .ra2(rtD), 
        .wa3(reg_writeM), 
        .wd3(resultM),

        .rd1(rd1D), 
        .rd2(rd2D)
    );

    //branch
    branch_predict bpu(      //执行分支预测
        .clk(clk), 
        .rst(rst),
        .instrD(instrD),
        .immD(immD),
        .pcD(pcD),
        .pcM(pcM),
        .branchM(branchM),
        .actual_takeM(actual_takeM),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );

    //jump
    jump_predict jump_predict(//主要判断jr类指令是否对先前的指令有WAR相关，决定是否在ID阶段跳转
        .instrD(instrD),
        .pc_plus4D(pc_plus4D),
        .rd1D(rd1D),
        .reg_write_enE(reg_write_enE), .reg_write_enM(reg_write_enM),
        .reg_writeE(reg_writeE), .reg_writeM(reg_writeM),

        .jumpD(jumpD),                      
        .jump_conflictD(jump_conflictD),    
        .pc_jumpD(pc_jumpD)                 
    );

    //ID_EX
    id_ex id_ex(
        .clk(clk),
        .rst(rst),
        .stallE(stallE),
        .flushE(flushE),
        .pcD(pcD),
        .rsD(rsD), .rd1D(rd1D), .rd2D(rd2D),
        .rtD(rtD), .rdD(rdD),
        .immD(immD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .branchD(branchD),
        .pred_takeD(pred_takeD),
        .pc_branchD(pc_branchD),
        .jump_conflictD(jump_conflictD),
        .is_in_delayslot_iD(is_in_delayslot_iD),
        .saD(saD),
        .alu_controlD(alu_controlD),
        .jumpD(jumpD),
        .branch_judge_controlD(branch_judge_controlD),
        .l_s_typeD(l_s_typeD),
        
        .pcE(pcE),
        .rsE(rsE), .rd1E(rd1E), .rd2E(rd2E),
        .rtE(rtE), .rdE(rdE),
        .immE(immE),
        .pc_plus4E(pc_plus4E),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),
        .jump_conflictE(jump_conflictE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .saE(saE),
        .alu_controlE(alu_controlE),
        .jumpE(jumpE),
        .branch_judge_controlE(branch_judge_controlE),
        .l_s_typeE(l_s_typeE)
    );

    //EX
    wire [31:0] hi;
    wire hi_wen;   //hi寄存器写使能
    wire [31:0] lo;
    wire lo_wen;   //lo寄存器写使能
    //通过独立控制hi和lo寄存器的读写，就不需要再前推hilo寄存器的值

    alu alu(
        .clk(clk),
        .rst(rst),
        .flushE(flushE),
        .src_aE(src_aE), .src_bE(src_bE),
        .alu_controlE(alu_controlE),
        .sa(saE),
        .stallD(stallD),
        .is_divD(is_divD),
        .is_multD(is_multD),

        .div_stallE(div_stallE),
        .mult_stallE(mult_stallE),
        .alu_outE(alu_outE), //除了访存类指令硬件地址、hilo寄存器结果等其余ALU指令的运算结果
        .hi(hi),
        .hi_wen(hi_wen),
        .lo(lo),
        .lo_wen(lo_wen),
        .overflowE(overflowE)//有符号运算溢出
    );

    assign mem_addrE = src_aE + src_bE;//生成lw和sw等访存指令的地址，绕过ALU内部逻辑，消除关键路径

    //以下mux4都不能集成到datapath中，否则时序不满足

    //mux write reg
    mux4 #(5) mux4_reg_dst(rdE, rtE, 5'd31, 5'b0, reg_dstE, reg_writeE);//目标寄存器的地址，jar等指令写reg[31]，reg[0]始终为0

    //数据前推(bypass)
    mux4 mux4_forward_aE(
        rd1E,                       
        resultM_without_rdata,
        resultW,
        pc_plus4D,                          // 执行jalr，jal指令；写入到$ra寄存器的数据
        {2{jumpE | branchE}} | forward_aE,  // 当exe阶段是jal或jalr指令，或者bxxzal时，jumpE | branchE== 1，此时进行pc+8运算，故选择pc_plus4D
        src_aE
    );
    mux4 mux4_forward_bE(
        rd2E,                               
        resultM_without_rdata,              
        resultW,                            
        immE,                               //立即数，例如pc+8
        {2{alu_imm_selE}} | forward_bE,     //main_decoder产生alu_imm_selE信号，表示alu第二个操作数为立即数
        src_bE
    );
    
    mux4 mux4_rs_valueE(rd1E, resultM_without_rdata, resultW, 32'b0, forward_aE, rs_valueE); //数据前推后的rs寄存器
    mux4 mux4_rt_valueE(rd2E, resultM_without_rdata, resultW, 32'b0, forward_bE, rt_valueE); //数据前推后的rt寄存器

    //计算branch结果
    branch_judge branch_judge(
        .branch_judge_controlE(branch_judge_controlE),
        .src_aE(rs_valueE),
        .src_bE(rt_valueE),
        .actual_takeE(actual_takeE)
    );

    //jump
    assign pc_jumpE = rs_valueE;
    assign flush_jump_confilctE = jump_conflictE;

    //EX_MEM
    ex_mem ex_mem(
        .clk(clk),
        .rst(rst),
        .stallM(stallM),
        .flushM(flushM),
        .pcE(pcE),
        .alu_outE(alu_outE),
        .rt_valueE(rt_valueE),
        .reg_writeE(reg_writeE),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),
        .overflowE(overflowE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .rdE(rdE),
        .actual_takeE(actual_takeE),
        .l_s_typeE(l_s_typeE),
        .mem_addrE(mem_addrE),

        .pcM(pcM),
        .alu_outM(alu_outM),
        .rt_valueM(rt_valueM),
        .reg_writeM(reg_writeM),
        .instrM(instrM),
        .branchM(branchM),
        .pred_takeM(pred_takeM),
        .pc_branchM(pc_branchM),
        .overflowM(overflowM),
        .is_in_delayslot_iM(is_in_delayslot_iM),
        .rdM(rdM),
        .actual_takeM(actual_takeM),
        .l_s_typeM(l_s_typeM),
        .mem_addrM(mem_addrM)
    );
    //MEM
    assign mem_enM = (mem_read_enM | mem_write_enM) & ~flush_exceptionM;//访存有效

    mem_ctrl mem_ctrl(
        .l_s_typeM(l_s_typeM),
	    .addr(alu_outM),

        .data_wdataM(rt_valueM),    //原始的wdata
        .mem_wdataM(mem_wdataM),    //新的wdata
        .mem_wenM(mem_wenM),

        .mem_rdataM(mem_rdataM),    
        .data_rdataM(mem_ctrl_rdataM),

        .addr_error_sw(addrErrorSwM),
        .addr_error_lw(addrErrorLwM)
    );

    hilo_reg hilo(
        .clk(clk),
        .rst(rst),
        .instrM(instrM),    // 用于识别mfhi，mflo，决定输出；
        .we(~flush_exceptionM & ~stallM),//当发送异常或者流水线暂停时，不能写寄存器
        .hi(hi),
        .hi_wen(hi_wen),
        .lo(lo),
        .lo_wen(lo_wen),
        .hilo_o(hilo_oM)   //mflo mfhi指令结果
    );

    assign pcErrorM = |(pcM[1:0]); //pc是否是4的倍数，即后两位是否为0
    //不能写pcM[0] | pcM[1]，时序不满足。。。
    
    exception except(//生成异常
        .rst(rst),
        .ri(riM), .break(breakM), .syscall(syscallM), .overflow(overflowM), .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        .cp0_status(cp0_statusW), .cp0_cause(cp0_causeW), .cp0_epc(cp0_epcW),
        .pcM(pcM),
        .alu_outM(alu_outM),

        .except_type(except_typeM),
        .flush_exception(flush_exceptionM),
        .pc_exception(pc_exceptionM),
        .pc_trap(pc_trapM),
        .badvaddrM(badvaddrM)
    );

    cp0_reg cp0(
        .clk(clk),
        .rst(rst),
        .ext_int(6'b0), //实际上不会产生硬件中断，直接赋值为6'b0
        .stallW(stallW),
        
        .en(flush_exceptionM),

        .we_i(cp0_wenM & ~stallW),
        .waddr_i(rdM),
        .data_i(rt_valueM),
        
        .raddr_i(rdM),
        .data_o(cp0_data_oW),

        .except_type_i(except_typeM),
        .current_inst_addr_i(pcM),
        .is_in_delayslot_i(is_in_delayslot_iM),
        .badvaddr_i(badvaddrM),

        .status_o(cp0_statusW),
        .cause_o(cp0_causeW),
        .epc_o(cp0_epcW)
    );

    wire [1:0] selM;//前推、MEM阶段结果选择信号
    assign selM = {hilo_to_regM | cp0_to_regM, mem_to_regM | cp0_to_regM};
    assign resultM_without_rdata = selM[1] ? selM[0] ? cp0_data_oW : hilo_oM :
                                             selM[0] ? 0 : alu_outM;
    assign resultM               = selM[1] ? selM[0] ? cp0_data_oW : hilo_oM :
                                             selM[0] ? mem_ctrl_rdataM : alu_outM;

    //branch predict result
    assign succM = ~(pred_takeM ^ actual_takeM);//预测结果与实际结果相同，则预测成功
    assign failedM = pred_takeM ^ actual_takeM; //反之预测失败

    //MEM_WB
    mem_wb mem_wb(
        .clk(clk),
        .rst(rst),
        .stallW(stallW),
        .pcM(pcM),
        .reg_writeM(reg_writeM),
        .reg_write_enM(reg_write_enM),
        .resultM(resultM),

        .pcW(pcW),
        .reg_writeW(reg_writeW),
        .reg_write_enW(reg_write_enW),
        .resultW(resultW)
    );
//WB

endmodule