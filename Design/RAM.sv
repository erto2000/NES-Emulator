module RAM #(
    parameter DATA_WIDTH = 8,
    parameter ADDRESS_WIDTH = 16,
    parameter INITIALIZE_TYPE = 0, //0-> None, 1-> Initialize with 0, 2-> Initialize with given file
    parameter INITIALIZE_FILE_INDEX = 0 //If initialize type is 2 select one of the file names below with index
)
(
    input clk,
    input WE,
    input CS,
    input[ADDRESS_WIDTH-1:0] address,
    inout[DATA_WIDTH-1:0] data
);   
    localparam file_name_0 = "Color_ROM.dat";
    localparam file_name_1 = "PRG_memory.dat";
    localparam file_name_2 = "CHR_memory.dat";

    reg[DATA_WIDTH-1:0] ram[2**ADDRESS_WIDTH-1:0];
    reg[DATA_WIDTH-1:0] out = 0;
    
    initial begin
        if(INITIALIZE_TYPE == 1)begin
            for (integer i=0; i<2**ADDRESS_WIDTH; i=i+1)
                ram[i] = {DATA_WIDTH{1'b0}};
        end
        else if(INITIALIZE_TYPE == 2)begin
//            if(INITIALIZE_FILE_INDEX == 1)
//                $readmemb(file_name_1, ram);
//            if(INITIALIZE_FILE_INDEX == 2)
//                $readmemb(file_name_2, ram);
//            if(INITIALIZE_FILE_INDEX == 3)
//                $readmemb(file_name_3, ram);
            case (INITIALIZE_FILE_INDEX) 
                0: $readmemb(file_name_0 ,ram);
                1: $readmemb(file_name_1 ,ram);
                2: $readmemb(file_name_2 ,ram);
                default: $readmemb(file_name_0 ,ram);
            endcase    
        end
    end
    
    assign data = (CS && !WE) ? out : {DATA_WIDTH{1'bz}};
    
    always @(posedge clk) begin
        if(CS == 1 && WE == 1) begin
            ram[address] <= data;
        end        
        
        out <= ram[address];
    end 
endmodule


















