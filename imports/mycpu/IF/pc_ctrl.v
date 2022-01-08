module pc_ctrl(
    input wire branchD,
    input wire branchM,
    input wire succM,
    input wire actual_takeM,
    input wire pred_takeD,

    input wire pc_trapM,
    input wire jumpD,
    input wire jump_conflictD,
    input wire jump_conflictE,

    output wire [2:0] pc_sel
);  
    assign pc_sel = pc_trapM                ? 3'b110 ://流水线异常
                    branchM & ~succM        ? {2'b10, ~actual_takeM} ://分支预测结果出错，根据实际是否跳转采取不同选项
                    jump_conflictE          ? 3'b011 ://jr类指令在d阶段冲突，在e阶段通过前推获得地址
                    jumpD & ~jump_conflictD ? 3'b010 ://普通j型指令，或者jr指令未冲突
                    {2'b00, branchD & ~branchM & pred_takeD | branchD & branchM & succM & pred_takeD};//分支预测
endmodule