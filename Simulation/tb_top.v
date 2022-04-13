`timescale 1ns / 1ps

module tb_top;
    
    reg clk = 0, rdy = 1;
    wire[7:0] data_out, pixel_index;
    wire hsync, vsync, sync;
    
    top t(.clk(clk), .rst(0), .irq(1), .data_out(data_out), .hsync(hsync), .vsync(vsync), .sync(sync), .pixel_index(pixel_index));
    
    always #10 clk = ~clk;

endmodule