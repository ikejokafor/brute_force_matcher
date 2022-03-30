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
// Description:          Teritary top level module which holds secondary descriptor buffer and logic which 
//                controls writing to the buffer. Contains an async buffer which can operate at two
//                different clock frequencies. Synch buffer is attached to output of async buffer
//                for more accurate count. This count value is used in the buffer control. The buffers
//                Are there because the brute_force_matcher_circular_descriptor_buffer cannot handle
//                reading and writing at the same.
//
// Dependencies:        brute_force_matcher_secondary_buffer_fifo.v
//                fifo_fwft_prog_full_count.v  
//                brute_force_matcher_buffer_control.v
//                brute_force_matcher_circular_descriptor_buffer.v  
// 
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module brute_force_matcher_secondary_descriptor_buffer #(
    parameter C_SEC_DESCRIPTOR_TABLE_DEPTH  = 1,
    parameter C_SEC_DESC_FIFO_DEPTH         = 32
) (
    rst                                     ,
    force_rst                               ,

    queue_write_clk                         ,
    queue_depleted                          ,
    queue_space_available                   ,
    queue_wren                              ,
    queue_datain                            ,
    secondary_descriptor_buffer_load_init   ,
    buffer_empty                            ,

    queue_read_clk                          ,
    buffer_control_descriptor_valid         ,
    descriptor_advance                      ,
    keypoint_advance                        ,
    descriptor_dataout                      ,
    descriptor_dataout_valid                ,
    dispatch_unit_total_keypoint_load_count ,
    sec_buffer_wren
);                          
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------------------------------------------------------------------------   
    localparam C_DESCRIPTOR_FIFO_DATA_WIDTH         = `DESCRIPTOR_INFO_WIDTH + (`DESCRIPTOR_ELEMENT_WIDTH * `SIMD);
    localparam C_BUFFER_DATA_WIDTH                  = `DESCRIPTOR_ELEMENT_WIDTH * `SIMD;
    localparam C_NUM_DESC_ELEM_DIV_SIMD_MINUS_TWO   = (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD) - 16'd2;
 
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                                       rst;
    input                                       force_rst;

    input                                       queue_write_clk;
    input                                       queue_wren;
    input  [C_DESCRIPTOR_FIFO_DATA_WIDTH - 1:0] queue_datain;
    output                                      queue_depleted;
    output                                      queue_space_available;
    input                                       secondary_descriptor_buffer_load_init;
    output                                      buffer_empty;

    input                                       queue_read_clk;
    output                                      buffer_control_descriptor_valid;
    input                                       descriptor_advance;
    input                                       keypoint_advance;
    output [C_DESCRIPTOR_FIFO_DATA_WIDTH - 1:0] descriptor_dataout;
    output                                      descriptor_dataout_valid;
    input  [15:0]                               dispatch_unit_total_keypoint_load_count;
    output                                      sec_buffer_wren;
 
 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------    
    wire                                                    buffer_load_valid;
            
    wire                                                    buffer_control_queue_depleted;
    wire                                                    buffer_control_queue_space_available;
    wire                                                    buffer_control_keypoint_advance;
    wire                                                    buffer_control_buffer_load_init;
    wire                                                    buffer_control_buffer_load_valid;
    wire                                                    buffer_control_buffer_load_enable;
    wire                                                    buffer_control_descriptor_valid_w;
            
    wire                                                    async_fifo_wren;
    wire                                                    async_fifo_rden;
    wire [C_DESCRIPTOR_FIFO_DATA_WIDTH  - 1:0]              async_fifo_datain;
    wire [C_DESCRIPTOR_FIFO_DATA_WIDTH  - 1:0]              async_fifo_dataout;
    wire                                                    async_fifo_empty;
    wire                                                    async_fifo_empty0;
    wire                                                    async_fifo_empty1;
    wire                                                    async_fifo_valid;
    wire                                                    async_fifo_valid0;
    wire                                                    async_fifo_valid1;
            
    wire [C_DESCRIPTOR_FIFO_DATA_WIDTH  - 1:0]              sync_fifo_datain;
    wire                                                    sync_fifo_wren;
    wire                                                    sync_fifo_rden;
    wire [C_DESCRIPTOR_FIFO_DATA_WIDTH  - 1:0]              sync_fifo_dataout;
    wire [17:0]                                             sync_fifo_count;
    wire                                                    sync_fifo_empty;
            
    reg  [`DESCRIPTOR_INFO_WIDTH - 1:0]                     secondary_descriptor_buffer_load_info_r;
    wire [`DESCRIPTOR_INFO_WIDTH - 1:0]                     secondary_descriptor_buffer_load_info;
    wire [C_BUFFER_DATA_WIDTH - 1:0]                        secondary_descriptor_buffer_load_data;
    reg  [C_BUFFER_DATA_WIDTH - 1:0]                        secondary_descriptor_buffer_load_data_r;
    wire                                                    secondary_descriptor_buffer_load_valid;
    wire [15:0]                                             secondary_descriptor_buffer_load_count;
    wire                                                    secondary_descriptor_buffer_read_init;
    wire [`DESCRIPTOR_INFO_WIDTH - 1:0]                     secondary_descriptor_buffer_read_info;
    wire                                                    secondary_descriptor_buffer_read_advance;
    wire [C_BUFFER_DATA_WIDTH - 1:0]                        secondary_descriptor_buffer_read_data;
    wire                                                    secondary_descriptor_buffer_empty;
    wire [`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_WIDTH - 1:0]    secondary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD;
    
    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    generate
    // Secondary Fifo Specs for 8 DSP Slices, 4 desc elements per datain bus, and 16 bits per desc element
    // Write Width: 165 bits
    // Write Depth: 32
    // Read Width:  165 bits
    // Read Depth:  32
        if(`SIMD == 8) begin
            brute_force_matcher_secondary_buffer_fifo  
            i0_brute_force_matcher_secondary_buffer_fifo (    
                .rst    ( rst                   ),
                .wr_clk ( queue_write_clk       ),
                .rd_clk ( queue_write_clk       ),
                .din    ( async_fifo_datain     ),
                .wr_en  ( async_fifo_wren       ),
                .rd_en  ( async_fifo_rden       ),
                .dout   ( async_fifo_dataout    ),
                .full   (                       ),
                .empty  ( async_fifo_empty      ),
                .valid  ( async_fifo_valid      )
            );
        end else if(`SIMD == 64) begin
            brute_force_matcher_secondary_buffer_fifo_64dsp0  
            i0_brute_force_matcher_secondary_buffer_fifo_64dsp0 (    
                .rst    ( rst                           ),
                .wr_clk ( queue_write_clk               ),
                .rd_clk ( queue_write_clk               ),
                .din    ( async_fifo_datain[1023:0]     ),  // fix so not hardcoded
                .wr_en  ( async_fifo_wren               ),
                .rd_en  ( async_fifo_rden               ),
                .dout   ( async_fifo_dataout[1023:0]    ),  // fix so not hardcoded
                .full   (                               ),
                .empty  ( async_fifo_empty0             ),
                .valid  ( async_fifo_valid0             )
            );
            
            brute_force_matcher_secondary_buffer_fifo_64dsp1  
            i0_brute_force_matcher_secondary_buffer_fifo_64dsp1 (    
                .rst    ( rst                           ),
                .wr_clk ( queue_write_clk               ),
                .rd_clk ( queue_write_clk               ),
                .din    ( async_fifo_datain[1058:1024]  ), // fix so not hardcoded
                .wr_en  ( async_fifo_wren               ),
                .rd_en  ( async_fifo_rden               ),
                .dout   ( async_fifo_dataout[1058:1024] ), // fix so not hardcoded
                .full   (                               ),
                .empty  ( async_fifo_empty1             ),
                .valid  ( async_fifo_valid1             )
            );
            
            always@(posedge queue_write_clk) begin // must delay input by 1 clock cycle
                if(rst) begin                
                    secondary_descriptor_buffer_load_data_r     <= {C_BUFFER_DATA_WIDTH{1'b0}};
                    secondary_descriptor_buffer_load_info_r     <= {`DESCRIPTOR_INFO_WIDTH{1'b0}};
                end else begin
                    secondary_descriptor_buffer_load_data_r     <= secondary_descriptor_buffer_load_data;    
                    secondary_descriptor_buffer_load_info_r     <= secondary_descriptor_buffer_load_info;                
                end
            end
        end
        if(`SIMD != 64) begin
            always@(*) begin 
                secondary_descriptor_buffer_load_data_r     <= secondary_descriptor_buffer_load_data;    
                secondary_descriptor_buffer_load_info_r     <= secondary_descriptor_buffer_load_info;              
            end
        end
    endgenerate
    
    
    fifo_fwft_prog_full_count #(
        .C_DATA_WIDTH           (C_DESCRIPTOR_FIFO_DATA_WIDTH  ),
        .C_FIFO_DEPTH           (C_SEC_DESC_FIFO_DEPTH         ),
        .C_PROG_FULL_THRESHOLD  (16                            )
    )
    i0_fifo_fwft_prog_full_count (
        .clk       ( queue_read_clk    ),
        .rst       ( rst               ),
        .wren      ( sync_fifo_wren    ),
        .rden      ( sync_fifo_rden    ),
        .datain    ( sync_fifo_datain  ),
        .dataout   ( sync_fifo_dataout ),
        .empty     ( sync_fifo_empty   ),
        .full      (                   ),
        .prog_full (                   ),
        .count     ( sync_fifo_count   )
    );
  
  
    brute_force_matcher_secondary_buffer_control #(
        .C_SEC_DESC_FIFO_DEPTH    (C_SEC_DESC_FIFO_DEPTH          )  
    )
    i0_brute_force_matcher_secondary_buffer_control (
        .clk                   ( queue_read_clk                       ),
        .rst                   ( rst                                  ),
        .queue_depleted        ( buffer_control_queue_depleted        ),
        .queue_space_available ( buffer_control_queue_space_available ),
        .fifo_count            ( sync_fifo_count                      ),

        .keypoint_advance      ( buffer_control_keypoint_advance      ),
        .descriptor_valid      ( buffer_control_descriptor_valid_w    ),
        .buffer_load_init      ( buffer_control_buffer_load_init      ),
        .buffer_load_valid     ( buffer_control_buffer_load_valid     ),
        .buffer_load_enable    ( buffer_control_buffer_load_enable    )
    );
  
  
    brute_force_matcher_circular_descriptor_buffer #(
        .C_DESCRIPTOR_TABLE_DEPTH    (C_SEC_DESCRIPTOR_TABLE_DEPTH      ),
        .C_DESCRIPTOR_INFO_TYPE      (`DESCRIPTOR_INFO_TYPE_QUERY       ),
        .C_PRIM_BUFFER               ( 0                                )
    ) 
    i0_brute_force_matcher_secondary_descriptor_buffer (
        .rst                 ( rst                                      ),
        .force_rst           ( force_rst                                ),
        
        .num_model_kp        (                                          ),

        .buffer_load_clk     ( queue_read_clk                           ),
        .buffer_load_init    ( buffer_control_buffer_load_init          ),
        .buffer_load_info    ( secondary_descriptor_buffer_load_info_r  ),
        .buffer_load_data    ( secondary_descriptor_buffer_load_data_r  ),
        .buffer_load_count   ( secondary_descriptor_buffer_load_count   ),
        .buffer_load_valid   ( secondary_descriptor_buffer_load_valid   ),

        .buffer_read_clk     ( queue_read_clk                           ),
        .buffer_read_init    ( secondary_descriptor_buffer_read_init    ),
        .buffer_read_info    ( secondary_descriptor_buffer_read_info    ),
        .buffer_read_data    ( secondary_descriptor_buffer_read_data    ),
        .buffer_read_valid   ( descriptor_dataout_valid                 ),
        .buffer_read_advance ( secondary_descriptor_buffer_read_advance ),

        .buffer_empty        ( secondary_descriptor_buffer_empty        )
    );
   
  
    // BEGIN Secondary Buffer logic -----------------------------------------------------------------------------------------------------------------
    assign secondary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD = secondary_descriptor_buffer_read_info[`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD];
    assign secondary_descriptor_buffer_load_count       = 1;                                          
    assign buffer_load_valid                            = !sync_fifo_empty && buffer_control_buffer_load_enable;  
    assign queue_depleted                               = buffer_control_queue_depleted;
    assign queue_space_available                        =   (`SIMD == 64) ? buffer_control_queue_space_available && async_fifo_empty0 && async_fifo_empty1 :
                                                            (`SIMD == 8 ) ? buffer_control_queue_space_available && async_fifo_empty : buffer_control_queue_space_available && async_fifo_empty;
    
    assign buffer_control_keypoint_advance              = keypoint_advance;
    assign buffer_control_buffer_load_valid             = buffer_load_valid;   
    assign async_fifo_wren                              = queue_wren;
    assign async_fifo_datain                            = queue_datain;
    assign async_fifo_rden                              = (`SIMD == 64) ? ((!async_fifo_empty0 && !async_fifo_empty1)  && (async_fifo_valid0 && async_fifo_valid1))   
                                                                            : (!async_fifo_empty  && async_fifo_valid);
    assign sync_fifo_wren                               = (`SIMD == 64) ? ((!async_fifo_empty0 && !async_fifo_empty1)  && (async_fifo_valid0  && async_fifo_valid1))    
                                                                            : (!async_fifo_empty  && async_fifo_valid);  
    assign sync_fifo_datain                             = async_fifo_dataout;
    assign sync_fifo_rden                               = buffer_load_valid;
    assign secondary_descriptor_buffer_load_valid       = buffer_load_valid;
    assign secondary_descriptor_buffer_load_info        = sync_fifo_dataout[`DESCRIPTOR_INFO_FIELD];
    assign secondary_descriptor_buffer_load_data        = sync_fifo_dataout[`DESCRIPTOR_SIMD_ELEMENT_FIELD];
    assign secondary_descriptor_buffer_read_init        = (secondary_descriptor_buffer_empty) ? 0 :
                                                           (secondary_descriptor_buffer_read_info_DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD == C_NUM_DESC_ELEM_DIV_SIMD_MINUS_TWO);
                                                                                                                
    assign secondary_descriptor_buffer_read_advance     = descriptor_advance;
    assign descriptor_dataout                           = {secondary_descriptor_buffer_read_data, secondary_descriptor_buffer_read_info};
    assign buffer_empty                                 = secondary_descriptor_buffer_empty;
    assign buffer_control_descriptor_valid              = buffer_control_descriptor_valid_w && !secondary_descriptor_buffer_empty;
    assign sec_buffer_wren                              = sync_fifo_wren;
    // END Secondary Buffer logic -------------------------------------------------------------------------------------------------------------------
   

`ifdef SIMULATION
    int numOverFlow;
    
    always@(posedge queue_write_clk) begin
        if(rst || force_rst) begin
            numOverFlow <= 0;
        end else begin
            if(sync_fifo_count == C_SEC_DESC_FIFO_DEPTH && sync_fifo_wren) begin
                numOverFlow <= numOverFlow + 1;
                $stop;
            end
        end
    end

    int numObsvdKP;
    always@(posedge queue_write_clk) begin
        if(rst) begin
            numObsvdKP <= 0;
        end else begin
            if(i0_brute_force_matcher_controller.init_keypoint_engine) begin
                numObsvdKP <= 0;
            end
            if(buffer_control_keypoint_advance) begin
                numObsvdKP <= numObsvdKP + 1;
            end
        end
    end
`endif
    
endmodule
