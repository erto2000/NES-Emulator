`timescale 1ns / 1ps

module tb_top;
    
    reg clk = 0;
    wire[7:0] data_out;
    
    top t(clk, data_out);
    
    always #10 clk = ~clk;
    
endmodule