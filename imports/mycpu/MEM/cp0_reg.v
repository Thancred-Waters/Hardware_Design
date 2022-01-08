`timescale 1ns / 1ps

`include "defines.vh"

//cp0 status
`define IE_BIT 0
`define EXL_BIT 1
`define BEV_BIT 22
`define IM7_IM0_BITS  15:8
//cp0 cause
`define BD_BIT 31                //延迟槽
`define TI_BIT 30                //计时器中断指令
`define IP1_IP0_BITS 9:8         //软件中断令
`define IP7_IP2_BITS 15:10       //软件中断令
`define EXC_CODE_BITS 6:2        //异常编码

module cp0_reg(
      input wire clk,rst,
      input wire [5:0] ext_int,          //硬件中断，直接设置为0
      input wire stallW,                  
      
      input wire en,                      //异常

      input wire we_i,                    //mtc0
      input wire [4:0] waddr_i,           //写cp0地址
      input wire [31:0] data_i,           //写cp0数据

      input wire [4:0] raddr_i,           //读cp0地址
      output wire [31:0] data_o,          //读cp0数据

      input [31:0] except_type_i,         //异常类型
      input [31:0] current_inst_addr_i,   //异常指令的pc
      input        is_in_delayslot_i,     //
      input [31:0] badvaddr_i,            //最近一次导致发生地址错例外的虚地址(load/store, pc未对齐地址)
      
      output reg [31:0] status_o,
      output reg [31:0] cause_o,
      output reg [31:0] epc_o
   );
   //cp0寄存器
   reg [31:0] config_o;
   reg [31:0] prid_o;
   reg [31:0] badvaddr_o;
   reg [31:0] compare_o;
   reg        timer_int_o;

   reg [32:0] count_inner;                //每个时钟+1
   wire [31:0] count_o;
   assign count_o = count_inner[32:1];    //右移1位，相当于每两个时钟+1

   always @(posedge clk) begin
      if(rst) begin
         count_inner <= 33'b0;
         compare_o   <= `ZeroWord;
         status_o    <= 32'b000000000_1_000000_00000000_000000_0_0;  //BEV置为1
         cause_o     <= 32'b0_0_000000000000000_00000000_0_00000_00;
         epc_o       <= `ZeroWord;
         config_o    <= 32'h0000_8000;
         prid_o      <= 32'h004c_0102;
         timer_int_o <= `InterruptNotAssert;
      end
      else begin
         //计时器加1
         count_inner <= count_inner + 1;
         if(compare_o != 32'b0 && count_o == compare_o) begin
            timer_int_o <= `InterruptAssert;
         end

         //遇到异常
         if(en) begin
            case (except_type_i)
               `EXC_TYPE_INT: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_INT;
               end
               `EXC_TYPE_ADEL: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_ADEL;
                  badvaddr_o <= badvaddr_i;
               end
               `EXC_TYPE_RI: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_RI;
               end
               `EXC_TYPE_SYS: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_SYS;
               end
               `EXC_TYPE_BP: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_BP;
               end
               `EXC_TYPE_ADES: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_ADES;
                  badvaddr_o <= badvaddr_i;
               end
               `EXC_TYPE_OV: begin
                  if(is_in_delayslot_i) begin
                     epc_o <= current_inst_addr_i - 4;
                     cause_o[`BD_BIT] <= 1'b1;
                  end else begin 
                     epc_o <= current_inst_addr_i;
                     cause_o[`BD_BIT] <= 1'b0;
                  end
                  status_o[`EXL_BIT] <= 1'b1;
                  cause_o[`EXC_CODE_BITS] <= `EXC_CODE_OV;
               end
               `EXC_TYPE_ERET: begin
                  status_o[`EXL_BIT] <= 1'b0 ;
               end
            endcase
         end
         // mtc0
         else if(we_i) begin
            case (waddr_i)
               `CP0_REG_COUNT:begin 
                  count_inner <= data_i;
               end
               `CP0_REG_COMPARE:begin 
                  compare_o <= data_i;
                  timer_int_o <= `InterruptNotAssert;
               end
               `CP0_REG_STATUS:begin 
                  status_o[`IE_BIT] <= data_i[`IE_BIT];
                  status_o[`EXL_BIT] <= data_i[`EXL_BIT];
                  status_o[`IM7_IM0_BITS] <= data_i[`IM7_IM0_BITS];
               end
               `CP0_REG_CAUSE:begin 
                  cause_o[`IP1_IP0_BITS] <= data_i[`IP1_IP0_BITS];
               end
               `CP0_REG_EPC:begin 
                  epc_o <= data_i;
               end
            endcase
         end
      end
   end

   //read
   assign data_o = ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_COUNT    ))}} & count_o)//去除rst信号后会增大组合逻辑延迟
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_COMPARE  ))}} & compare_o)
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_STATUS   ))}} & status_o)
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_CAUSE    ))}} & cause_o)
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_EPC      ))}} & epc_o)
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_PRID     ))}} & prid_o)
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_CONFIG   ))}} & config_o)
                 | ( {32{~rst & ~(|( raddr_i ^ `CP0_REG_BADVADDR ))}} & badvaddr_o);
endmodule
