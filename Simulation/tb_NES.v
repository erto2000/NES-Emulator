`timescale 1ns / 1ps

module tb_NES;
    
    reg clk = 0, rdy = 1, ppu_clk;
    reg[1:0] clk_counter = 0;
    reg[8:0] cycle_counter = 0;
    reg[8:0] line_counter = 0;
    reg[8:0] counter = 0;
    reg[7:0] controller;
    wire[7:0] pixel_index;
    wire h, v;
    
    NES UUT(.clk(clk), .rst(0), .controller(controller), .pixel_out(pixel_index), .h(h), .v(v));
    
    always #10 clk = ~clk;
    always @(posedge clk) clk_counter = clk_counter + 1;
    assign ppu_clk = (clk_counter == 0) ? 1 : 0;
    
    initial controller = 0;
    assign #50_000_000 controller = 8'b00001000;
    assign #70_000_000 controller = 8'b00000000;
    
    integer file;
    initial begin
        file = $fopen("frame_pixels.txt", "w");
                
        @(posedge v);
        #1;
        $fwrite(file, pixel_index);
        @(posedge ppu_clk);
        cycle_counter = cycle_counter + 1;
        
        while(1) begin
            #1;
            $fwrite(file, pixel_index);
            @(posedge ppu_clk);
            cycle_counter = cycle_counter + 1;
            if(v == 1)
                $fdisplay(file);
            if(cycle_counter == 256)begin
                @(posedge h);
                cycle_counter = 0;
                line_counter = line_counter + 1;
                $fdisplay(file);
            end
            
        end;  
    end;
endmodule
























