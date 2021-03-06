module pc_reg #(parameter WIDTH=32)(
    input wire clk,
    input wire stallF,
    input wire rst,
    input wire [WIDTH-1:0] pc_next,

    output reg [ WIDTH-1:0] pc,
    output reg ce
);
    always @(posedge clk) begin
        if(rst) begin
            ce <= 0;
        end
        else begin
            ce <= 1;
        end
    end

    always @(posedge clk) begin
        if(!ce) begin
            pc <= 32'hbfc00000;//可以考虑将pc的初始值设定为bfbf_ffff，这样pc+4就是第一条pc
        end
        else if(~stallF) begin
            pc <= pc_next;
        end
    end
endmodule