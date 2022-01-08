module branch_judge (
    input wire [4:0] branch_judge_controlE,
    input wire [31:0] src_aE, src_bE,

    output wire actual_takeE
);
    assign actual_takeE = branch_judge_controlE == `ALU_EQ  ? ~(|(src_aE ^ src_bE))   :
                          branch_judge_controlE == `ALU_NEQ ? |(src_aE ^ src_bE)      :
                          branch_judge_controlE == `ALU_GTZ ? ~src_aE[31] & (|src_aE) :
                          branch_judge_controlE == `ALU_GEZ ? ~src_aE[31]             :
                          branch_judge_controlE == `ALU_LTZ ? src_aE[31]              : 
                          branch_judge_controlE == `ALU_LEZ ? src_aE[31] | ~(|src_aE) :
                          1'b0;
endmodule