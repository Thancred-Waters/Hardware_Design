`include "aludefines.vh"

module alu (
    input wire clk, rst,
    input wire flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [4:0] alu_controlE,
    input wire [4:0] sa,
    input wire stallD,
    input wire is_divD,
    input wire is_multD,

    output reg div_stallE,
    output wire mult_stallE,
    output wire [31:0] alu_outE,
    output wire [31:0] hi,
    output wire [31:0] lo,
    output wire hi_wen,
    output wire lo_wen,
    output wire overflowE
);
    wire [63:0] alu_out_div, alu_out_mult;
    wire mult_sign;
    wire mult_valid;
    wire div_sign;
	wire div_valid;

    wire [63:0] alu_out_signed_mult, alu_out_unsigned_mult;
    wire signed_mult_ce, unsigned_mult_ce;
    reg [2:0] cnt;
    
    wire [63:0] alu64_out;
    assign alu64_out = {64{mult_valid}} & alu_out_mult |
                        {64{div_valid}}  & alu_out_div;
    assign hi = div_valid | mult_valid ? alu64_out[63:32] : src_aE;
    assign hi_wen = alu_controlE == `ALU_MTHI | div_valid | mult_valid;
    assign lo = div_valid | mult_valid ? alu64_out[31:0] : src_aE;
    assign lo_wen = alu_controlE == `ALU_MTLO | div_valid | mult_valid;

    wire And,Or,Nor,Xor,Add,Addu,Sub,Subu,Slt,Sltu,Sll,Sll_sa,Srl,Sra,Srl_sa,Sra_sa,Lui,Donothing;

    assign And       = alu_controlE == `ALU_AND      ;
    assign Or        = alu_controlE == `ALU_OR       ;
    assign Nor       = alu_controlE == `ALU_NOR      ;
    assign Xor       = alu_controlE == `ALU_XOR      ;
    assign Add       = alu_controlE == `ALU_ADD      ;
    assign Addu      = alu_controlE == `ALU_ADDU     ;
    assign Sub       = alu_controlE == `ALU_SUB      ;
    assign Subu      = alu_controlE == `ALU_SUBU     ;
    assign Slt       = alu_controlE == `ALU_SLT      ;
    assign Sltu      = alu_controlE == `ALU_SLTU     ;
    assign Sll       = alu_controlE == `ALU_SLL      ;
    assign Sll_sa    = alu_controlE == `ALU_SLL_SA   ;
    assign Srl       = alu_controlE == `ALU_SRL      ;
    assign Sra       = alu_controlE == `ALU_SRA      ;
    assign Srl_sa    = alu_controlE == `ALU_SRL_SA   ;
    assign Sra_sa    = alu_controlE == `ALU_SRA_SA   ;
    assign Lui       = alu_controlE == `ALU_LUI      ;
    assign Donothing = alu_controlE == `ALU_DONOTHING;

    wire [31:0] and_out          ;
    wire [31:0] or_out           ;
    wire [31:0] nor_out          ;
    wire [31:0] xor_out          ;
    wire [31:0] slt_out          ;
    wire [31:0] sltu_out         ;
    wire [31:0] sll_out          ;
    wire [31:0] sll_sa_out       ;
    wire [31:0] lui_out          ;

    wire add_cry;
    wire [31:0] add_out;
    wire [31:0] sr_sa_out, sr_out;

    assign {add_cry,add_out} = Sub ? {src_aE[31],src_aE} - {src_bE[31],src_bE} : 
                               Add ? {src_aE[31],src_aE} + {src_bE[31],src_bE} :
                               Addu ? src_aE + src_bE : src_aE - src_bE; 

    assign overflowE = (Add | Sub) & (add_cry ^ add_out[31]);

    assign and_out    = src_aE & src_bE;
    assign or_out     = src_aE | src_bE;
    assign nor_out    = ~(src_aE | src_bE);
    assign xor_out    = src_aE ^ src_bE;
    assign lui_out    = {src_bE[15:0],  16'd0};

    assign slt_out = $signed(src_aE) < $signed(src_bE);
    assign sltu_out = src_aE < src_bE;

    assign sll_out  = src_bE << src_aE[4:0];                                     // sll
    assign sll_sa_out = src_bE << sa;                                            // sll_sa
    
    assign sr_out = {{32{Sra & src_bE[31]}},src_bE[31:0]} >> src_aE[4:0]; // sra srl                                      
    assign sr_sa_out = {{32{Sra_sa & src_bE[31]}},src_bE[31:0]} >> sa;       // sra_sa srl_sa

    assign alu_outE =   ({32{And        }} & and_out)            
                    |   ({32{Nor        }} & nor_out)            
                    |   ({32{Or         }} & or_out)             
                    |   ({32{Xor        }} & xor_out)  
                    |   ({32{Add | Addu | Sub | Subu}} & add_out) 
                    |   ({32{Slt        }} & slt_out)            
                    |   ({32{Sltu       }} & sltu_out)           
                    |   ({32{Sll        }} & sll_out)       
                    |   ({32{Sll_sa     }} & sll_sa_out)       
                    |   ({32{Sra    | Srl    }} & sr_out)
                    |   ({32{Sra_sa | Srl_sa }} & sr_sa_out)
                    |   ({32{Lui        }} & lui_out)
                    |   ({32{Donothing}} & src_aE);


    //divide
	assign div_sign = alu_controlE == `ALU_SIGNED_DIV;
	assign div_valid = alu_controlE == `ALU_SIGNED_DIV || alu_controlE == `ALU_UNSIGNED_DIV;

    reg vaild;
    wire ready;
    always @(posedge clk) begin
        div_stallE <= rst  ? 1'b0 :
                      is_divD & ~stallD & ~flushE ? 1'b1 :
                      ready | flushE ? 1'b0 : div_stallE;
        vaild <= rst ? 1'b0 :
                     is_divD & ~stallD & ~flushE ? 1'b1 : 1'b0;
    end
    
	div_radix2 DIV(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.a(src_aE),  //divident
		.b(src_bE),  //divisor
		.valid(vaild ),
		.sign(div_sign),   //1 signed

		.ready(ready),
		.result(alu_out_div)
	);

    //multiply
	assign mult_sign = (alu_controlE == `ALU_SIGNED_MULT);
    assign mult_valid = (alu_controlE == `ALU_SIGNED_MULT) | (alu_controlE == `ALU_UNSIGNED_MULT);

    assign alu_out_mult = mult_sign ? alu_out_signed_mult : alu_out_unsigned_mult;

    wire mult_ready;
    assign mult_ready = !(cnt ^ 3'b101);

    always@(posedge clk) begin
        cnt <= rst | (is_multD & ~stallD & ~flushE) | flushE ? 0 :
                mult_ready ? cnt :
                cnt + 1;
    end

    assign unsigned_mult_ce = mult_valid & ~mult_ready;
    assign signed_mult_ce =  mult_valid & ~mult_ready;
    assign mult_stallE = mult_valid & (unsigned_mult_ce | signed_mult_ce);

    signed_mult signed_mult (
        .CLK(clk),  // input wire CLK
        .A(src_aE),      // input wire [31 : 0] A
        .B(src_bE),      // input wire [31 : 0] B
        .CE(signed_mult_ce),    // input wire CE
        .P(alu_out_signed_mult)      // output wire [63 : 0] P
    );

    unsigned_mult unsigned_mult (
        .CLK(clk),  // input wire CLK
        .A(src_aE),      // input wire [31 : 0] A
        .B(src_bE),      // input wire [31 : 0] B
        .CE(unsigned_mult_ce),    // input wire CE
        .P(alu_out_unsigned_mult)      // output wire [63 : 0] P
    );

endmodule