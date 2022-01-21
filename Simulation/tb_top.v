`timescale 1ns / 1ps

module tb_top(
    );
    
    reg clk;
    wire data_out;
    
    top uut(clk,data_out);
    
    initial begin
    clk = 0;
    end
    
    always #20 clk = ~clk;
    
endmodule