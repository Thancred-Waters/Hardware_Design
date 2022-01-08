//module:       div
//description:  radix-2 divider
//version:      1.2

/*
log:
1.1: 增加了存储输入的逻辑 (不暂停M,W阶段, 数据前推导致输入发生变化)
1.2: 增加了flush逻辑，用于发生异常时停止计算除法
*/

module div_radix2(
    input               clk,
    input               rst,
    input               flush,
    input [31:0]        a,  //divident
    input [31:0]        b,  //divisor
    input               valid,
    input               sign,   //1:signed

    output reg          ready,
    output [63:0]       result
    );
    /*
    1. 先取绝对值，计算出余数和商�?�再根据被除数�?�除数符号对结果调整
    2. 计算过程中，由于保证了remainer为正，因此最高位�?0，可以用32位存储�?��?�除数需�?33�?
    */
    reg [31:0] a_save, b_save;
    reg [63:0] SR; //shift register
    reg [32 :0] NEG_DIVISOR;  //divisor 2's complement
    wire [31:0] REMAINER, QUOTIENT;
    assign REMAINER = SR[63:32];
    assign QUOTIENT = SR[31: 0];

    wire [31:0] divident_abs;
    wire [32:0] divisor_abs;
    wire [31:0] remainer, quotient;

    assign divident_abs = (sign & a[31]) ? ~a + 1'b1 : a;
    //余数符号与被除数相同
    assign remainer = (sign & a_save[31]) ? ~REMAINER + 1'b1 : REMAINER;
    assign quotient = sign & (a_save[31] ^ b_save[31]) ? ~QUOTIENT + 1'b1 : QUOTIENT;
    assign result = {remainer,quotient};

    wire CO;
    wire [32:0] sub_result;
    wire [32:0] mux_result;
    //sub
    assign {CO,sub_result} = {1'b0,REMAINER} + NEG_DIVISOR;
    //mux
    assign mux_result = CO ? sub_result : {1'b0,REMAINER};

    //state machine
    reg [5:0] cnt;
    reg start_cnt;
    always @(posedge clk) begin
        if(rst | flush) begin
            cnt <= 0;
            start_cnt <= 0;
            ready <= 0;
        end
        else if(!start_cnt & valid) begin
            cnt <= 1;
            start_cnt <= 1;
            //save a,b
            a_save <= a;
            b_save <= b;

            //Register init
            SR[63:0] <= {31'b0,divident_abs,1'b0}; //left shift one bit initially
            NEG_DIVISOR <= (sign & b[31]) ? {1'b1,b} : ~{1'b0,b} + 1'b1; //divisor_abs的补�?
        end
        else if(start_cnt) begin
            if(cnt==32) begin
                cnt <= 0;
                start_cnt <= 0;
                
                //Output result
                SR[63:32] <= mux_result[31:0];
                SR[0] <= CO;

                //ready
                ready <= 1'b1;
            end
            else begin
                cnt <= cnt + 1;

                SR[63:0] <= {mux_result[30:0],SR[31:1],CO,1'b0}; //wsl: write and shift left
            end
        end
        else begin
            ready <= 1'b0;
        end
    end


    
    assign div_stall = |cnt; //只有当cnt=0时不暂停
endmodule