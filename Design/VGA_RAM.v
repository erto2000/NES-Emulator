`timescale 1ns / 1ps

module VGA_RAM#(
    parameter DATA_WIDTH = 12,
    parameter ADDRESS_WIDTH = 61440,
    parameter h_size = 256,
    parameter v_size = 240
    
)
(
    input clk,
    input clk_2,
    input rst,
	input [23:0]pixel_color,
	input vsync,
	input hsync,
	input [19:0] index,
	output reg [DATA_WIDTH-1 : 0] data_vga
);

    reg[DATA_WIDTH-1:0] ram[ADDRESS_WIDTH-1:0];
    reg[19:0] counter_h = 0;
    reg[19:0] counter_v = 0;
    reg[19:0] counter_r = 0;
    reg h_hold = 0;
    reg v_hold = 0;
    
    integer i;
    initial begin
      for (i=0;i<ADDRESS_WIDTH;i=i+1) begin
        ram[i] = 12'b111100000000;
      end
    end
    
    always @(posedge clk) begin
        if(vsync == 1) begin
            v_hold <= 1;
        end
        
        if(hsync == 1)begin
            h_hold <= 1;
        end
        
        if(v_hold == 1)begin
            if(counter_h == h_size) begin
                v_hold <= 0;
                counter_h <= 0;
                counter_v <= counter_v + 1;
            end
            else begin
                ram[counter_r] <= {pixel_color[23:20],pixel_color[15:12],pixel_color[7:4]};    
                counter_r <= counter_r + 1;
                counter_h <= counter_h + 1;
            end 
        end
        
        if(h_hold == 1) begin
            if(counter_h == h_size) begin
                counter_h <= 0;
                h_hold <= 0;
                counter_v <= counter_v + 1;
                if(counter_v == v_size-1) begin
                    counter_v <= 0;
                    counter_r <= 0;
                end
            end
            else begin
                ram[counter_r] <= {pixel_color[23:20],pixel_color[15:12],pixel_color[7:4]};    
                counter_r <= counter_r + 1;
                counter_h <= counter_h + 1;
            end                  
        end
        
    end 
    
    always @(posedge clk_2) begin
        data_vga = ram[index]; 
    end 
    
endmodule
