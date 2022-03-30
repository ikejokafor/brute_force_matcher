`timescale 1ns / 1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:			
//				
// Engineer:		
//
// Create Date:		
// Design Name:		
// Module Name:		
// Project Name:	
// Target Devices:  
// Tool versions:
// Description:		
//
// Dependencies:
//	 
// 	 
//
// Revision:
//
//
//
//
// Additional Comments: Xilinx Simple Dual Port Single Clock RAM
//                      This code implements a parameterizable SDP single clock memory.
//                      If a reset or enable is not necessary, it may be tied off or removed from the code.
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module xilinx_simple_dual_port_1_clock_ram #(
    parameter RAM_WIDTH       = 64,                       // Specify RAM data width
    parameter RAM_DEPTH       = 512                       // Specify RAM depth (number of entries)
) (
    addra,      // Write address bus, width determined from RAM_DEPTH
    addrb,      // Read address bus, width determined from RAM_DEPTH
    dina,       // RAM input data
    clka,       // Clock
    wren,       // Write enable
    rden,       // Read Enable, for additional power savings, disable when not in use
    rstb,       // Output reset (does not affect memory contents)
    doutb,      // RAM output data
    count,
    full
);	
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
  
    
	//-----------------------------------------------------------------------------------------------------------------------------------------------
	//	Inputs / Output Ports
	//-----------------------------------------------------------------------------------------------------------------------------------------------
    input       [clog2(RAM_DEPTH) - 1:0]    addra;
    input       [clog2(RAM_DEPTH) - 1:0]    addrb;
    input       [       RAM_WIDTH - 1:0]    dina; 
    input                                   clka;
    input                                   wren;  
    input                                   rden;  
    input                                   rstb; 
    output reg  [        RAM_WIDTH - 1:0]   doutb;
    output reg  [     clog2(RAM_DEPTH):0]   count;
    output                                  full;
	

	//-----------------------------------------------------------------------------------------------------------------------------------------------
	// Regs
	//-----------------------------------------------------------------------------------------------------------------------------------------------
    reg     [       RAM_WIDTH - 1:0]    BRAM[RAM_DEPTH - 1:0];
	reg     [clog2(RAM_DEPTH) - 1:0]    addrb_plus_one;
    wire    [clog2(RAM_DEPTH) - 1:0]    address;

	
	// BEGIN BRAM Write logic -----------------------------------------------------------------------------------------------------------------------   
    always@(posedge clka) begin
        if(wren) begin
            BRAM[addra] <= dina;
        end 
    end
    // END BRAM Write logic -------------------------------------------------------------------------------------------------------------------------

    
    // BEGIN BRAM Count logic -----------------------------------------------------------------------------------------------------------------------
    assign full = (count == RAM_DEPTH);
    
    always@(posedge clka) begin
        if(rstb) begin
            count <= 0;
        end else begin
            if(wren && rden) begin
                count <= count;
            end else if(wren && count <= RAM_DEPTH) begin
                count <= count + 1;
            end else if(rden && count >= 0) begin
                count <= count - 1;
            end
        end
    end
    // END BRAM Count logic -------------------------------------------------------------------------------------------------------------------------

    
    
    // BEGIN BRAM Read logic ------------------------------------------------------------------------------------------------------------------------
    assign address = (rden) ? addrb_plus_one : addrb;

    always @(posedge clka) begin
        addrb_plus_one     <= addrb + 1;
        if(rden) begin
            addrb_plus_one <= addrb_plus_one + 1;
        end
    end

    always @(posedge clka) begin
        doutb <= BRAM[address];
    end
  // END BRAM logic ---------------------------------------------------------------------------------------------------------------------------------

endmodule
