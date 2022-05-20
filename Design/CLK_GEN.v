`timescale 1ns / 1ps

module CLK_GEN(
    input clk,
    input rst,
    output clk50,
    output clk25,
    output clk12_5,
    output clk6_75
    );
    reg clk50 = 0;
    reg clk25 = 0;
    reg clk12_5 = 0;
    reg clk6_75 = 0;
	   always@(posedge clk)
		begin
            if (rst == 1) begin
                clk50 <= 1'b0;
            end
            else 
                clk50 <= !clk50;
		end
		
		always@(posedge clk50)
		begin
            if (rst == 1) begin
                clk25 <= 1'b0;
            end
            else
                clk25 <= !clk25;
        end
                
        always@(posedge clk25)
		begin
            if (rst == 1) begin
                clk12_5 <= 1'b0;
            end
            else
                clk12_5 <= !clk12_5;
		end
		
	    always@(posedge clk12_5)
		begin
            if (rst == 1) begin
                clk6_75 <= 1'b0;
            end
            else
                clk6_75 <= !clk6_75;
		end
		
endmodule