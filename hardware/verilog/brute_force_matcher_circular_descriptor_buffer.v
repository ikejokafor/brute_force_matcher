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
// Description:   Circular buffer for descriptor values. Each entry in the buffer contains the descriptor data
//                and metadata about the descriptor data defined in "brute_force_matcher_defines.vh"
//                The number of descriptor values per entry is (NUM_DESC_ELEMENTS) / (SIMD). Primary Buffer is large 
//                enough to hold 512 keypoints. Secondary buffer holds 1 keypoint.            
//
// Dependencies:
//    
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_circular_descriptor_buffer #(
    parameter C_DESCRIPTOR_TABLE_DEPTH = 16,  // this should be changed to keypoint depth or something for semantics
    parameter C_DESCRIPTOR_INFO_TYPE   = 1,
    parameter C_PRIM_BUFFER = 0
) (
    rst                 ,
    force_rst           ,
    
    num_model_kp        ,

    buffer_load_clk     ,
    buffer_load_init    ,
    buffer_load_info    ,
    buffer_load_data    ,
    buffer_load_count   ,
    buffer_load_valid   ,

    buffer_read_clk     ,
    buffer_read_init    ,
    buffer_read_info    ,
    buffer_read_data    ,
    buffer_read_valid   ,
    buffer_read_advance ,

    buffer_empty
);
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"
 
 

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    localparam C_ACTUAL_DESCRIPTOR_TABLE_DEPTH = `max(2, (C_DESCRIPTOR_TABLE_DEPTH * (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD)));
    localparam C_DESCRIPTOR_TABLE_INDEX_WIDTH  = clog2(C_ACTUAL_DESCRIPTOR_TABLE_DEPTH);
    localparam C_DESCRIPTOR_TABLE_DATA_WIDTH   = `DESCRIPTOR_INFO_WIDTH + (`DESCRIPTOR_ELEMENT_WIDTH * `SIMD);
    localparam C_NUM_DESCRIPTOR_SLOTS          = `max(2, (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD));
    localparam C_BUFFER_DATA_LENGTH            = `DESCRIPTOR_ELEMENT_WIDTH * `SIMD;
 
 
    //----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    //----------------------------------------------------------------------------------------------------------------------------------------------
    input                                   rst;
    input                                   force_rst;
    input  [                         15:0]  num_model_kp;
    input                                   buffer_load_clk;
    input                                   buffer_load_init;
    input  [`DESCRIPTOR_INFO_WIDTH  - 1:0]  buffer_load_info;
    input  [                         15:0]  buffer_load_count;
    input                                   buffer_load_valid;
    input  [   C_BUFFER_DATA_LENGTH - 1:0]  buffer_load_data;
    output [   C_BUFFER_DATA_LENGTH - 1:0]  buffer_read_data;
    input                                   buffer_read_clk;
    input                                   buffer_read_init;
    output [`DESCRIPTOR_INFO_WIDTH  - 1:0]  buffer_read_info;
    output                                  buffer_read_valid;
    input                                   buffer_read_advance;
    output                                  buffer_empty;

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    reg                                                     buffer_load_valid_r;
    reg                                                     buffer_empty_r;
    reg                                                     keypoint_load_index_last_r;
    wire                                                    keypoint_load_index_last_w;
    reg                                                     keypoint_load_index_first;
    reg     [    `DESCRIPTOR_INFO_KEYPOINT_ID_WIDTH - 1:0]  keypoint_id;
    reg     [clog2(C_ACTUAL_DESCRIPTOR_TABLE_DEPTH) - 1:0]  keypoint_load_index;
    reg     [clog2(C_ACTUAL_DESCRIPTOR_TABLE_DEPTH) - 1:0]  keypoint_read_index;
    reg     [                                        15:0]  total_keypoint_count_in_buf;
    reg                                                     descriptor_load_index_last;
    reg                                                     descriptor_load_index_first;
    reg                                                     descriptor_read_index_last;
    reg     [        clog2(C_NUM_DESCRIPTOR_SLOTS)  - 1:0]  descriptor_load_index;
    reg     [        clog2(C_NUM_DESCRIPTOR_SLOTS)  - 1:0]  descriptor_read_index;
    wire    [        `DESCRIPTOR_INFO_CELL_ID_WIDTH - 1:0]  descriptor_load_cell_id;
    wire    [        C_DESCRIPTOR_TABLE_INDEX_WIDTH - 1:0]  descriptor_buffer_load_address;
    wire    [        C_DESCRIPTOR_TABLE_INDEX_WIDTH - 1:0]  descriptor_buffer_read_address;
    wire    [        C_DESCRIPTOR_TABLE_DATA_WIDTH  - 1:0]  descriptor_buffer_datain;
    reg     [        C_DESCRIPTOR_TABLE_DATA_WIDTH  - 1:0]  descriptor_buffer_dataout;
    wire    [        C_DESCRIPTOR_TABLE_DATA_WIDTH  - 1:0]  descriptor_buffer_dataout_w;
    reg     [        C_DESCRIPTOR_TABLE_DATA_WIDTH  - 1:0]  descriptor_buffer[C_ACTUAL_DESCRIPTOR_TABLE_DEPTH - 1:0];
    reg     [    clog2(C_ACTUAL_DESCRIPTOR_TABLE_DEPTH):0]  buffer_count;
    reg                                                     buffer_read_advance_r;

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    generate
        // BEGIN Descriptor Load / Read Logic -------------------------------------------------------------------------------------------------------       
        if(`SIMD == 64) begin
            assign descriptor_buffer_read_address  = keypoint_read_index;
            assign descriptor_buffer_load_address  = keypoint_load_index;
        
            always@(posedge buffer_load_clk) begin
                if(rst) begin
                    buffer_load_valid_r <= 0;
                end else begin
                    if(buffer_load_valid) begin
                        buffer_load_valid_r <= buffer_load_valid;
                    end else begin
                        buffer_load_valid_r <= 0;
                    end
                end
            end
        end else begin
            assign descriptor_buffer_read_address  = {keypoint_read_index, descriptor_read_index};
            assign descriptor_buffer_load_address  = {keypoint_load_index, descriptor_load_index};
            
            always@(*) begin
                buffer_load_valid_r <= buffer_load_valid;
            end       
        end        
        // END Descriptor Load / Read Logic ---------------------------------------------------------------------------------------------------------
    endgenerate
    
    
    // BEGIN Descriptor Load Interface --------------------------------------------------------------------------------------------------------------
    assign descriptor_load_cell_id = buffer_load_info[`DESCRIPTOR_INFO_CELL_ID_FIELD];
    assign buffer_empty = buffer_empty_r; 

    always@(posedge buffer_load_clk) begin
        if(rst || buffer_load_init || force_rst) begin
            descriptor_load_index       <= 0;
            descriptor_load_index_last  <= 1'b0;
            descriptor_load_index_first <= 1'b1;
            total_keypoint_count_in_buf <= 16'd0; 
        end else begin
            if(`SIMD == 64) begin 
                descriptor_load_index_last  <= 1'b1;
            end else begin
                if(buffer_load_valid_r) begin
                    descriptor_load_index         <= descriptor_load_index + 1;
                     if(descriptor_load_index == {{(clog2(C_NUM_DESCRIPTOR_SLOTS) - 1){1'b1}}, 1'b0}) begin
                         descriptor_load_index_last  <= 1'b1;
                     end else begin
                         descriptor_load_index_last  <= 1'b0;
                     end  
                     if(descriptor_load_index == {clog2(C_NUM_DESCRIPTOR_SLOTS){1'b1}}) begin
                         descriptor_load_index_first  <= 1'b1;
                     end else begin
                         descriptor_load_index_first  <= 1'b0;
                    end
                    // Sample the total keypoint count - added by sxv49 - temp fix
                    total_keypoint_count_in_buf <= total_keypoint_count_in_buf + 1; 
                end
            end
        end
    end
 
    always@(posedge buffer_load_clk) begin
        if(rst || buffer_load_init || force_rst) begin
            keypoint_load_index       <= 0;
            keypoint_load_index_last_r  <= 1'b0;
            keypoint_load_index_first <= 1'b1;
        end else begin
            if(buffer_load_valid_r && descriptor_load_index_last) begin
                keypoint_load_index       <= keypoint_load_index + 1;
                if(buffer_load_count == 1) begin
                    keypoint_load_index_last_r        <= 1;
                end else begin
                    if(keypoint_load_index == (buffer_load_count - 2)) begin
                        keypoint_load_index_last_r    <= 1'b1;
                    end else begin
                        keypoint_load_index_last_r    <= 1'b0;
                    end
                    if(keypoint_load_index == buffer_load_count) begin
                        keypoint_load_index_first   <= 1'b1;
                    end else begin
                        keypoint_load_index_first   <= 1'b0;
                    end
                end
            end
        end
    end
    

    always@(posedge buffer_load_clk) begin
        if(rst || force_rst) begin
            keypoint_id    <= {`DESCRIPTOR_INFO_KEYPOINT_ID_WIDTH{1'b0}};
        end else if(buffer_load_valid_r && descriptor_load_index_last) begin
            keypoint_id    <= keypoint_id + 1;
        end
    end
 
    always@(posedge buffer_load_clk) begin
        if(rst || buffer_load_init || force_rst) begin
            buffer_count    <= 0;
            buffer_empty_r  <= 1;
        end else begin
            if(buffer_load_valid_r) begin
                buffer_count  <= buffer_count + 1;
            end 
            if(buffer_count == 0 || (descriptor_buffer_read_address > (buffer_count - 1))) begin
                buffer_empty_r <= 1;
            end else if(buffer_count > 0 && (descriptor_buffer_read_address <= (buffer_count - 1))) begin
                buffer_empty_r <= 0;
            end  
        end
    end 
    // END Descriptor Load Interface ----------------------------------------------------------------------------------------------------------------      
 
    // BEGIN Descriptor Buffer ----------------------------------------------------------------------------------------------------------------------  
    assign keypoint_load_index_last_w = (C_PRIM_BUFFER && num_model_kp == 1) ? 1 : keypoint_load_index_last_r;
    
    assign descriptor_buffer_datain =   {  
                                            buffer_load_data,  
                                            descriptor_load_cell_id,
                                            {`DESCRIPTOR_INFO_TYPE_WIDTH{1'b0}},
                                            keypoint_id,
                                            keypoint_load_index_last_w,
                                            keypoint_load_index_first,
                                            descriptor_load_index_last,
                                            descriptor_load_index_first,
                                            descriptor_load_index                  
                                        };

    always@(posedge buffer_load_clk) begin
        if(buffer_load_valid_r) begin
            descriptor_buffer[descriptor_buffer_load_address] <= descriptor_buffer_datain;
        end
    end

    always@(posedge buffer_read_clk) begin
        descriptor_buffer_dataout <= descriptor_buffer[descriptor_buffer_read_address];    
    end  

    assign buffer_read_valid = !buffer_empty_r && buffer_read_advance_r;
    // END Descriptor Buffer ------------------------------------------------------------------------------------------------------------------------

    
    // BEGIN Descriptor Read Interface --------------------------------------------------------------------------------------------------------------
    assign {buffer_read_data, buffer_read_info} = descriptor_buffer_dataout;

    always@(posedge buffer_read_clk) begin
        if(rst || buffer_read_init || force_rst) begin
            descriptor_read_index         <= 0;
            descriptor_read_index_last    <= 0;
        end else begin

            if(buffer_read_advance) begin
                descriptor_read_index        <= descriptor_read_index + 1;
                if(`SIMD == 64) begin 
                    descriptor_read_index_last   <= 1;
                end else begin
                    if(descriptor_read_index == {{(clog2(C_NUM_DESCRIPTOR_SLOTS) - 1){1'b1}}, 1'b0}) begin
                        descriptor_read_index_last   <= 1;
                    end else begin
                        descriptor_read_index_last   <= 0;
                    end
                end
            end
        end
    end
 
    always@(posedge buffer_read_clk) begin
        if(rst || force_rst) begin
            buffer_read_advance_r         <= 0;
        end else begin
            buffer_read_advance_r                <= buffer_read_advance;
        end
    end

 
    generate
        if(`SIMD == 8) begin
             always@(posedge buffer_read_clk) begin
                if(rst || buffer_read_init || force_rst) begin
                    keypoint_read_index <= 0;
                end else if((keypoint_read_index == (total_keypoint_count_in_buf - 1'b1)) && buffer_read_advance && descriptor_read_index_last)begin
                    keypoint_read_index <= 0;
                end else if(buffer_read_advance && descriptor_read_index_last && buffer_count > 1) begin
                    keypoint_read_index <= keypoint_read_index + 1;
                end
            end
        end else if(`SIMD == 64) begin
            always@(posedge buffer_read_clk) begin
                if(rst || buffer_read_init || force_rst) begin
                    keypoint_read_index <= 0;                  
                end else begin
                    if((keypoint_read_index == (total_keypoint_count_in_buf - 1'b1)) && buffer_read_advance)begin
                        keypoint_read_index <= 0;
                    end else if(buffer_read_advance && buffer_count > 1) begin
                        keypoint_read_index <= keypoint_read_index + 1;
                    end
                end
            end
        end
    endgenerate
    // END Descriptor Read Interface ----------------------------------------------------------------------------------------------------------------
 
endmodule
