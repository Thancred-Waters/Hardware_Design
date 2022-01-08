module hazard (
    input wire clk,rst,
    input wire i_cache_stall,
    input wire d_cache_stall,
    input wire mem_read_enM,
    input wire mem_write_enM,
    input wire div_stallE,
    input wire mult_stallE,
    input wire [7:0] l_s_typeE,

    input wire flush_jump_confilctE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsE, rsD,
    input wire [4:0] rtE, rtD,
    input wire reg_write_enE,
    input wire reg_write_enM,
    input wire reg_write_enW,
    input wire [4:0] reg_writeM, reg_writeE,
    input wire [4:0] reg_writeW, 
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,
    output wire [1:0] forward_aE, forward_bE //00-> NONE, 01-> MEM, 10-> WB (LW instr)
);
    assign forward_aE = rsE != 0 && reg_write_enM && (rsE == reg_writeM) ? 2'b01 :
                        rsE != 0 && reg_write_enW && (rsE == reg_writeW) ? 2'b10 :
                        2'b00;
    assign forward_bE = rtE != 0 && reg_write_enM && (rtE == reg_writeM) ? 2'b01 :
                        rtE != 0 && reg_write_enW && (rtE == reg_writeW) ? 2'b10 :
                        2'b00;
    wire stall_ltypeE;
    assign stall_ltypeE = |(l_s_typeE[7:3]) & ((rsD != 0 && reg_write_enE && (rsD == reg_writeE)) || (rtD != 0 && reg_write_enE && (rtD == reg_writeE)));
    
    wire pipeline_stall;
    
    assign pipeline_stall = i_cache_stall | d_cache_stall | div_stallE | mult_stallE;
    //一旦发生flush，流水线无需stall
    assign stallF = ~flush_exceptionM & (pipeline_stall | (stall_ltypeE & ~flush_pred_failedM));
    assign stallD = ~flush_exceptionM & (stall_ltypeE | pipeline_stall);
    assign stallE = ~flush_exceptionM & pipeline_stall;
    assign stallM = ~flush_exceptionM & pipeline_stall;
    assign stallW = pipeline_stall;

    assign flushF = 1'b0;//取值阶段通过pc选择决定正确的地址    
    assign flushD = flush_exceptionM | (flush_pred_failedM & ~pipeline_stall) | (flush_jump_confilctE & ~pipeline_stall & ~stall_ltypeE);       
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~pipeline_stall) | (stall_ltypeE & ~pipeline_stall);     
    assign flushM = flush_exceptionM;
    assign flushW = 1'b0;//WB阶段永远不需要刷新
endmodule