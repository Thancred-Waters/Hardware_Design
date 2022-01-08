module mux4 #(parameter WIDTH=32) (
    input wire [WIDTH-1:0] a, b, c, d,
    input wire [1:0] sel,

    output wire [WIDTH-1:0] y
);
    assign y = sel[1] ? (sel[0] ? d : c):
                        (sel[0] ? b : a);
    
endmodule