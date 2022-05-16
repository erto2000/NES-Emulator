`timescale 1ns / 1ps

module tb_NES;
    
    reg clk = 0, rdy = 1, ppu_clk;
    reg[1:0] clk_counter = 0;
    reg[8:0] cycle_counter = 0;
    reg[8:0] line_counter = 0;
    reg[8:0] counter = 0;
    reg[7:0] controller;
    wire[23:0] pixel_color;
    wire h, v;
    
    NES UUT(.clk(clk), .rst(0), .controller(controller), .pixel_color(pixel_color), .h(h), .v(v));
    
    always #10 clk = ~clk;
    
    initial controller = 0;
    assign #50_000_000 controller = 8'b00001000;
    assign #70_000_000 controller = 8'b00000000;
    
    
//    reg state = 0;
//    always@(posedge clk) begin
//        if(v == 1)
//            state <= 1;
//    end
    
//    always
    
    integer file;
    initial begin
        file = $fopen("frame_pixels.txt", "w");

        @(posedge v)#1;
        while(1)begin
            $fwriteh(file, pixel_color);
            cycle_counter = cycle_counter + 1;
            if(cycle_counter == 256) begin
                cycle_counter = 0;
                line_counter = line_counter + 1;
                if(line_counter == 240) begin
                    $fdisplay(file);$fdisplay(file);
                    line_counter = 0;
                    @(posedge v)#1;
                end else begin
                    $fdisplay(file);
                    @(posedge h)#1;
                end
            end else begin
                #80;
            end
        end

        
    end;

endmodule
























