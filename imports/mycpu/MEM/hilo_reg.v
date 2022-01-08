`include "defines.vh"

module hilo_reg(
   input wire        clk,rst,we,
   input wire [31:0] instrM,

   input wire [31:0] hi,
   input wire hi_wen,
   input wire [31:0] lo,
   input wire lo_wen,
   output wire [31:0] hilo_o
);
   reg [63:0] hilo;
   always @(posedge clk) begin
      if(rst)
         hilo <= 0;
      else if(we) begin//当没有发生异常或者stall时，更新hilo
         if(hi_wen)
            hilo[63:32] <= hi;
         else hilo[63:32] <= hilo[63:32];
         if(lo_wen)
            hilo[31:0] <= lo;
         else hilo[31:0] <= hilo[31:0];
      end
      else
         hilo <= hilo;
   end

   // 读cp0逻辑
   wire mfhi;
   wire mflo;
   assign mfhi = ~(|(instrM[31:26] ^ `EXE_R_TYPE)) & ~(|(instrM[5:0] ^ `EXE_MFHI));
   assign mflo = ~(|(instrM[31:26] ^ `EXE_R_TYPE)) & ~(|(instrM[5:0] ^ `EXE_MFLO));

   assign hilo_o = ({32{mfhi}} & hilo[63:32]) | ({32{mflo}} & hilo[31:0]);
endmodule

