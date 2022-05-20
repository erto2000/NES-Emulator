`timescale 1ns / 1ps

module VGA(
    input clk,
    input rst,
    output reg [19:0] index,
	output reg[3:0] R,
	output reg[3:0] G,
	output reg[3:0] B,
	output reg vga_hsync,
	output reg vga_vsync,
	input [11:0] data_vga
    );
    
      parameter hRez   = 640;
      parameter hStartSync   = 640+16;
      parameter hEndSync     = 640+16+96;
      parameter hMaxCount    = 800;
    
      parameter vRez         = 480;
      parameter vStartSync   = 480+10;
      parameter vEndSync     = 480+10+2;
      parameter vMaxCount    = 480+10+2+33;
    
		parameter hsync_active   =0;
		parameter vsync_active  = 0;
		reg[9:0] hCounter;
		reg[9:0] vCounter;    
		reg[16:0] address;  
		reg blank;
		initial   hCounter = 10'b0;
		initial   vCounter = 10'b0;  
		initial   address = 17'b0;   
		initial   blank = 1'b1;    
		assign frame_addr = address;
		
		always@(posedge clk)
    	begin
		if( hCounter == hMaxCount-1 )
			begin
			hCounter <=  10'b0;
			if (vCounter == vMaxCount-1 )
				vCounter <=  10'b0;
			else
				vCounter <= vCounter+1;
			end
		else
			hCounter <= hCounter+1;

		if (blank ==0)
			begin
		        R   <= data_vga[11:8];
                G <= data_vga[7:4];
                B  <= data_vga[3:0];                      
			end
		else 
			begin
			R   <= 4'b0;
			G <= 4'b0;
			B  <= 4'b0;
			end

		if(  vCounter  >= 360 || vCounter  < 120) 
			begin
			index <= 20'b0; 
			blank <= 1;
			end
		else
			begin
			if ( hCounter  < 416 && hCounter  >= 160) 
				begin
				blank <= 0;
				index <= index+1;
				end
			else
				blank <= 1;
			end

		if( hCounter > hStartSync && hCounter <= hEndSync)
			vga_hsync <= hsync_active;
		else
			vga_hsync <= ~ hsync_active;

		if( vCounter >= vStartSync && vCounter < vEndSync )
			vga_vsync <= vsync_active;
		else
			vga_vsync <= ~ vsync_active;
	end 
endmodule







//`timescale 1ns / 1ps

//module VGA(
//    input clk,
//    input rst,
//    output reg [19:0] index,
//	output reg[3:0] R,
//	output reg[3:0] G,
//	output reg[3:0] B,
//	output reg vga_hsync,
//	output reg vga_vsync,
//	input [11:0] data_vga
//    );
    
//      parameter hRez   = 640;
//      parameter hStartSync   = 640+16;
//      parameter hEndSync     = 640+16+96;
//      parameter hMaxCount    = 800;
    
//      parameter vRez         = 400;
//      parameter vStartSync   = 400+12;
//      parameter vEndSync     = 400+12+2;
//      parameter vMaxCount    = 400+12+2+35; //449
    
//		parameter hsync_active   =0;
//		parameter vsync_active  = 0;
//		reg[9:0] hCounter;
//		reg[9:0] vCounter;    
//		reg[16:0] address;  
//		reg blank;
//		initial   hCounter = 10'b0;
//		initial   vCounter = 10'b0;  
//		initial   address = 17'b0;   
//		initial   blank = 1'b1;    
//		assign frame_addr = address;
		
//		always@(posedge clk)
//		begin
//		if( hCounter == hMaxCount-1 )
//			begin
//			hCounter <=  10'b0;
//            index <= index + 1;
//			if (vCounter == vMaxCount-1 ) begin
//				vCounter <=  10'b0;
//				index <= 20'b0;
//		    end
//			else
//			    index <= index + 1;
//				vCounter <= vCounter+1;
//			end
//		else begin
//			hCounter <= hCounter+1;
//			index <= index + 1;
//        end

//		 R   <= data_vga[11:8];
//         G   <= data_vga[7:4];
//         B   <= data_vga[3:0]; 
          
////		if (blank ==0)
////			begin
////		        R   <= data_vga[11:8];
////                G <= data_vga[7:4];
////                B  <= data_vga[3:0];                      
////			end
////		else 
////			begin
////			R   <= 4'b0;
////			G <= 4'b0;
////			B  <= 4'b0;
////			end

////		if(  vCounter  >= 360 || vCounter  < 120) 
////			begin
////			address <= 17'b0; 
////			blank <= 1;
////			end
////		else
////			begin
////			if ( hCounter  < 480 && hCounter  >= 160) 
////				begin
////				blank <= 0;
////				address <= address+1;
////				end
////			else
////				blank <= 1;
////			end

//		if( hCounter > hStartSync && hCounter <= hEndSync)
//			vga_hsync <= hsync_active;
//		else
//			vga_hsync <= ~ hsync_active;

//		if( vCounter >= vStartSync && vCounter < vEndSync )
//			vga_vsync <= vsync_active;
//		else
//			vga_vsync <= ~ vsync_active;
//		end 
//endmodule