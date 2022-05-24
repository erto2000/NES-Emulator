`timescale 1ns / 1ps

module VGA(
    input clk,
    input rst,
    output reg [19:0] index,
	output reg[3:0] R,
	output reg[3:0] G,
	output reg[3:0] B,
	output reg VGA_H,
	output reg VGA_V,
	input [11:0] data_vga
    );
    
      parameter h_start   = 640+16;
      parameter h_end     = 640+16+96;
      parameter h_max     = 640+16+96+48;
    
      parameter v_start   = 480+10;
      parameter v_end     = 480+10+2;
      parameter v_max     = 480+10+2+33;
    
	  parameter h_active   = 0;
	  parameter v_active   = 0;
	  reg[9:0] h_coun;
	  reg[9:0] v_coun;    
	  reg black_screen;

	  initial   black_screen = 1'b1;    
	  initial   h_coun       = 10'b0;
	  initial   v_coun       = 10'b0;    
		
      always@(posedge clk)
      begin
        if(h_coun == h_max-1)
        begin
        	h_coun <=  10'b0;
        	if (v_coun == v_max-1 )
        		v_coun <=  10'b0;
        	else
        		v_coun <= v_coun+1;
        end
        else
        	h_coun <= h_coun+1;
        
        if (black_screen ==0)
        	begin
                R   <= data_vga[11:8];
                G   <= data_vga[7:4];
                B   <= data_vga[3:0];                      
        	end
        else 
        	begin
        	R   <= 4'b0;
        	G   <= 4'b0;
        	B   <= 4'b0;
        	end
        
        if(v_coun >= 360 || v_coun < 120) 
        	begin
        	index <= 20'b0; 
        	black_screen <= 1;
        	end
        else
        	begin
        	if (h_coun < 416 && h_coun >= 160) 
        		begin
        		black_screen <= 0;
        		index <= index+1;
        		end
        	else
        		black_screen <= 1;
        	end
        
        if(h_coun > h_start && h_coun <= h_end)
        	VGA_H <= h_active;
        else
        	VGA_H <= ~ h_active;
        
        if(v_coun >= v_start && v_coun < v_end )
          VGA_V <= v_active;
        else
        	VGA_V <= ~ v_active;
	end 
endmodule



