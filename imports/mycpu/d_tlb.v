module d_tlb (
    input wire [31:0] inst_va,
    input wire [31:0] inst_va2,
    input wire [31:0] data_va,
    input wire [31:0] data_va2,

    output wire [31:0] data_pa,
    output wire [31:0] data_pa2,
    output wire [31:0] inst_pa,
    output wire [31:0] inst_pa2,

    output wire no_cache_d,
    output wire no_cache_i
);
    // kseg0 + kseg1

    assign inst_pa = inst_va[31] & ~inst_va[30] ? {3'b0, inst_va[28:0]} : inst_va;

    assign inst_pa2 = inst_va2[31] & ~inst_va2[30] ? {3'b0, inst_va2[28:0]} : inst_va2;

    assign data_pa = data_va[31] & ~data_va[30] ?  {3'b0, data_va[28:0]} : data_va;

    assign data_pa2 = data_va2[31] & ~data_va2[30] ? {3'b0, data_va2[28:0]} : data_va2;
    
    assign no_cache_d = (data_va[31:29] == 3'b101) | //kseg1
                        (data_va[31] & ~(|data_va[30:22]) & (|data_va[21:20]));
    
    assign no_cache_i = 1'b0;//提高访存速度

    
endmodule