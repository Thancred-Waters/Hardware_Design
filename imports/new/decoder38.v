module decoder38 (
    input wire [2 : 0] x,
    output wire [7 : 0] y

);
    assign y[0] = x==3'b000;
    assign y[1] = x==3'b001;
    assign y[2] = x==3'b010;
    assign y[3] = x==3'b011;
    assign y[4] = x==3'b100;
    assign y[5] = x==3'b101;
    assign y[6] = x==3'b110;
    assign y[7] = x==3'b111;
endmodule
