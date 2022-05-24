`timescale 1ns / 1ps

module tb_NES;
    
    reg clk = 0, rdy = 1, ppu_clk;
    reg[3:0] R,G,B;
    wire vga_hsync, vga_vsync;
    
    NES UUT(.clk(clk), .rst(0), .R(R), .G(G), .B(B), .vga_hsync(vga_hsync),. vga_vsync(vga_vsync));
    
    always #10 clk = ~clk;

    
//    reg state = 0;
//    always@(posedge clk) begin
//        if(v == 1)
//            state <= 1;
//    end
    
//    always
    
//    integer file;
//    initial begin
//        file = $fopen("frame_pixels.txt", "w");

//        @(posedge v)#1;
//        while(1)begin
//            $fwriteh(file, pixel_color);
//            cycle_counter = cycle_counter + 1;
//            if(cycle_counter == 256) begin
//                cycle_counter = 0;
//                line_counter = line_counter + 1;
//                if(line_counter == 240) begin
//                    $fdisplay(file);$fdisplay(file);
//                    line_counter = 0;
//                    @(posedge v)#1;
//                end else begin
//                    $fdisplay(file);
//                    @(posedge h)#1;
//                end
//            end else begin
//                #80;
//            end
//        end


endmodule