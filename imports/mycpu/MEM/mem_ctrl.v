`include "defines.vh"

module mem_ctrl(
    input wire [7:0] l_s_typeM,
    input wire [3:0] addr,

    input wire [31:0] data_wdataM,
    output wire [31:0] mem_wdataM,
    output wire [3:0] mem_wenM,

    input wire [31:0] mem_rdataM,
    output wire [31:0] data_rdataM,

    output wire addr_error_sw, addr_error_lw
);
    wire instr_lw, instr_lh, instr_lhu, instr_lb, instr_lbu, instr_sw, instr_sh, instr_sb;
    wire addr_W0, addr_B2, addr_B1, addr_B3;
    
	assign {instr_lw, instr_lh, instr_lhu, instr_lb, instr_lbu, instr_sw, instr_sh, instr_sb} = l_s_typeM;

    assign addr_error_sw = (instr_sw & ~addr_W0)
                        | (  instr_sh & ~(addr_W0 | addr_B2));
    assign addr_error_lw = (instr_lw & ~addr_W0)
                        | (( instr_lh | instr_lhu ) & ~(addr_W0 | addr_B2));
//字节偏移
    assign addr_W0 = ~(|(addr[1:0]));
    assign addr_B2 = ~(|(addr[1:0] ^ 2'b10));
    assign addr_B1 = ~(|(addr[1:0] ^ 2'b01));
    assign addr_B3 = ~(|(addr[1:0] ^ 2'b11));

// wdata  and  byte_wen
    assign mem_wenM =   {4{ instr_sw & addr_W0}          }//4'b1111
                        | {2'b00, {2{instr_sh & addr_W0}}}//4'b0011
                        | {{2{instr_sh & addr_B2}},2'b00 }//4'b1100
                        | {3'b000, instr_sb & addr_W0    }//4'b0001
                        | {2'b00, instr_sb & addr_B1,1'b0}//4'b0010
                        | {1'b0, instr_sb & addr_B2,2'b0 }//4'b0100
                        | {instr_sb & addr_B3,3'b000     };//4'b1000
// rdata
// data ram 按字寻址
    assign mem_wdataM =   ({ 32{instr_sw}} & data_wdataM)
                        | ( {32{instr_sh}}  & {2{data_wdataM[15:0]} })
                        | ( {32{instr_sb}}  & {4{data_wdataM[7:0]}  });  
    assign data_rdataM =  ( {32{instr_lw}}   & mem_rdataM)
                        | ( {32{ instr_lh   & addr_W0}}  & { {16{mem_rdataM[15]}},  mem_rdataM[15:0]    })
                        | ( {32{ instr_lh   & addr_B2}}  & { {16{mem_rdataM[31]}},  mem_rdataM[31:16]   })
                        | ( {32{ instr_lhu  & addr_W0}}  & {  16'b0,                mem_rdataM[15:0]    })
                        | ( {32{ instr_lhu  & addr_B2}}  & {  16'b0,                mem_rdataM[31:16]   })
                        | ( {32{ instr_lb   & addr_W0}}  & { {24{mem_rdataM[7]}},   mem_rdataM[7:0]     })
                        | ( {32{ instr_lb   & addr_B1}}  & { {24{mem_rdataM[15]}},  mem_rdataM[15:8]    })
                        | ( {32{ instr_lb   & addr_B2}}  & { {24{mem_rdataM[23]}},  mem_rdataM[23:16]   })
                        | ( {32{ instr_lb   & addr_B3}}  & { {24{mem_rdataM[31]}},  mem_rdataM[31:24]   })
                        | ( {32{ instr_lbu  & addr_W0}}  & {  24'b0 ,               mem_rdataM[7:0]     })
                        | ( {32{ instr_lbu  & addr_B1}}  & {  24'b0 ,               mem_rdataM[15:8]    })
                        | ( {32{ instr_lbu  & addr_B2}}  & {  24'b0 ,               mem_rdataM[23:16]   })
                        | ( {32{ instr_lbu  & addr_B3}}  & {  24'b0 ,               mem_rdataM[31:24]   });
endmodule