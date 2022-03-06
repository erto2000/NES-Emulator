module RAM #(
    parameter DATA_WIDTH = 8,
    parameter ADDRESS_WIDTH = 16
)
(
    input clk,
    input WE,
    input CS,
    input[ADDRESS_WIDTH-1:0] address,
    inout[DATA_WIDTH-1:0] data
);   
    const enum {NONE, ZERO, FILE} INITIALIZE_TYPE = FILE; //NONE->not initialized, ZERO-> initialized with zero, FILE->give data in file
    
    reg[DATA_WIDTH-1:0] ram[2**ADDRESS_WIDTH-1:0];
    reg[DATA_WIDTH-1:0] out = 0;
    
    initial begin
        if(INITIALIZE_TYPE == NONE || INITIALIZE_TYPE == ZERO)begin
            for (integer i=0; i<2**ADDRESS_WIDTH; i=i+1)
                ram[i] = INITIALIZE_TYPE == NONE ? {DATA_WIDTH{1'bz}} : {DATA_WIDTH{1'b0}};
        end
        else if(INITIALIZE_TYPE == FILE)begin
            $readmemb("ram.dat", ram);    
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


















