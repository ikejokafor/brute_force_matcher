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
// Description:   Secondary top level module. Also contains combinational logic which tells the secondary and
//                primary buffer when to wrap around to the beginning and the logic which tells the pipeline
//                to advance or not.
//
// Dependencies:  brute_force_matcher_keypoint_dispatch_unit
//                brute_force_matcher_circular_descriptor_buffer
//                brute_force_matcher_secondary_descriptor_buffer   
//                brute_force_matcher_descriptor_compute_pipeline
//    
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_datapath #(
    parameter C_DWC_FIFO_READ_DEPTH         = 4096,
    parameter C_PRIM_DESCRIPTOR_TABLE_DEPTH = 16,
    parameter C_SEC_DESCRIPTOR_TABLE_DEPTH  = 1,
    parameter C_SEC_DESC_FIFO_DEPTH         = 32
) (
    interface_clk                                   ,
    compute_clk                                     ,
    rst                                             ,
    force_rst                                       ,

    num_model_kp                                    ,
    i_secondary_descriptor_buffer_depleted            ,
    i_secondary_descriptor_buffer_space_available     ,
    i_secondary_descriptor_buffer_load_count        ,

    dispatch_unit_datain_valid                      ,
    dispatch_unit_datain                            ,
    dispatch_unit_begin_load_fifo                   ,
    dispatch_unit_descriptor_buffer_select          ,
    dispatch_unit_total_keypoint_load_count         ,
    dispatch_unit_done_buffer_load                  ,

    secondary_descriptor_buffer_load_init           ,
    primary_descriptor_buffer_load_init             ,
    controller_last_cell_kp_batch                   ,

    i_match_table_ready                              ,
    i_match_info_valid                              ,
    i_match_info                                    
);
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"

    
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Parameters
    //-----------------------------------------------------------------------------------------------------------------------------------------------   
    localparam ST_IDLE                              = 2'b01;
    localparam ST_SEC_BUF_LOADING                   = 2'b10;
    
    localparam C_BUFFER_DATA_WIDTH                  = `SIMD * `DESCRIPTOR_ELEMENT_WIDTH;
    localparam C_BUFFER_DATA_WIDTH_1                = `SIMD * `DESCRIPTOR_ELEMENT_WIDTH * `NUM_ENGINES;
    localparam C_DISPATCH_UNIT_DATAIN_WIDTH         = `DATAIN_WIDTH + `DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH;
    localparam C_NUM_DESC_ELEM_DIV_SIMD_MINUS_TWO   = (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD) - 16'd2;
    localparam C_MATCH_INFO_WIDTH                   = `MATCH_INFO_WIDTH * `NUM_ENGINES;
    localparam C_DESCRIPTOR_INFO_WIDTH              = `DESCRIPTOR_INFO_WIDTH * `NUM_ENGINES;
    localparam C_IDX                                = `max(1, clog2(`NUM_ENGINES));
    localparam C_SEC_DESC_BUF_LOAD_CNT              = `NUM_ENGINES * 16;
  
  
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    input                                           interface_clk;
    input                                           compute_clk;
    input                                           rst;
    input                                           force_rst;

    input  [                              15:0]     num_model_kp;
    input                                           dispatch_unit_datain_valid;
    input  [                               1:0]     dispatch_unit_descriptor_buffer_select;
    input  [C_DISPATCH_UNIT_DATAIN_WIDTH - 1:0]     dispatch_unit_datain;       
    input                                           dispatch_unit_begin_load_fifo;
    input  [                              15:0]     dispatch_unit_total_keypoint_load_count;
    output                                          dispatch_unit_done_buffer_load;

    input                                           secondary_descriptor_buffer_load_init;
    input                                           primary_descriptor_buffer_load_init;
    input                                           controller_last_cell_kp_batch;
    
    output  [                  `NUM_ENGINES - 1:0]  i_secondary_descriptor_buffer_depleted;
    output  [                  `NUM_ENGINES - 1:0]  i_secondary_descriptor_buffer_space_available;
    input   [       C_SEC_DESC_BUF_LOAD_CNT - 1:0]  i_secondary_descriptor_buffer_load_count;

    input  [                `NUM_ENGINES - 1:0]     i_match_table_ready;
    output [                `NUM_ENGINES - 1:0]     i_match_info_valid;
    output [          C_MATCH_INFO_WIDTH - 1:0]     i_match_info;

   
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    reg   [                                 1:0]    state;
    reg   [                                15:0]    load_count;
    
    
    wire                                            primary_descriptor_buffer_load_valid;
    wire  [           C_BUFFER_DATA_WIDTH - 1:0]    primary_descriptor_buffer_load_data;
    reg   [           C_BUFFER_DATA_WIDTH - 1:0]    primary_descriptor_buffer_load_data_r;
    wire  [        `DESCRIPTOR_INFO_WIDTH - 1:0]    primary_descriptor_buffer_load_info;
    reg   [        `DESCRIPTOR_INFO_WIDTH - 1:0]    primary_descriptor_buffer_load_info_r;
    wire  [                                15:0]    primary_descriptor_buffer_load_count;

    wire  [        `DESCRIPTOR_INFO_WIDTH - 1:0]    primary_descriptor_buffer_read_info;
    wire  [           C_BUFFER_DATA_WIDTH - 1:0]    primary_descriptor_buffer_read_data;
    wire                                            primary_descriptor_buffer_read_valid;
    wire                                            primary_descriptor_buffer_read_init;
    wire  [                  `NUM_ENGINES - 1:0]    i_primary_descriptor_buffer_read_init;
    wire                                            primary_descriptor_buffer_empty;
   
    reg   [         C_BUFFER_DATA_WIDTH_1 - 1:0]    i_secondary_descriptor_buffer_load_data;
    reg   [                  `NUM_ENGINES - 1:0]    i_secondary_descriptor_buffer_load_valid;
    reg   [       C_DESCRIPTOR_INFO_WIDTH - 1:0]    i_secondary_descriptor_buffer_load_info;
    wire                                            all_sec_desc_engine_desc_valid;
    wire  [                  `NUM_ENGINES - 1:0]    i_sec_desc_engine_desc_valid;
    

    wire  [                                 1:0]    dispatch_unit_descriptor_buffer_load_valid;
    integer                                         idx0;
    reg   [                         C_IDX - 1:0]    last_engine_loaded;
    integer                                         idx1;
    
    wire  [           C_BUFFER_DATA_WIDTH - 1:0]    dispatch_unit_descriptor_buffer_load_data;
    wire  [        `DESCRIPTOR_INFO_WIDTH - 1:0]    dispatch_unit_descriptor_buffer_load_info; 
    wire  [                                15:0]    disp_buffer_total_kp_load_cnt;
    
    wire                                            advance;
    wire  [                  `NUM_ENGINES - 1:0]    i_advance;
    wire                                            sec_buffer_not_loading;
    wire  [                  `NUM_ENGINES - 1:0]    i_sec_buffer_wren;
    wire                                            sec_buffer_wren;


    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    generate
        if(`SIMD == 64) begin
            always@(posedge interface_clk) begin // must delay input by 1 clock cycle
                if(rst) begin
                    primary_descriptor_buffer_load_data_r       <= {C_BUFFER_DATA_WIDTH{1'b0}};
                    primary_descriptor_buffer_load_info_r       <= {`DESCRIPTOR_INFO_WIDTH{1'b0}};                    
                end else begin
                    primary_descriptor_buffer_load_data_r       <= primary_descriptor_buffer_load_data;      
                    primary_descriptor_buffer_load_info_r       <= primary_descriptor_buffer_load_info;                 
                end
            end
        end else begin
            always@(*) begin 
                primary_descriptor_buffer_load_data_r       <= primary_descriptor_buffer_load_data;      
                primary_descriptor_buffer_load_info_r       <= primary_descriptor_buffer_load_info;              
            end
        end
    endgenerate
    
    brute_force_matcher_dispatch_unit #(
        .C_DWC_FIFO_READ_DEPTH                  (C_DWC_FIFO_READ_DEPTH                         )
    ) 
    i0_brute_force_matcher_dispatch_unit (
        .clk                                        ( interface_clk                                 ),
        .rst                                        ( rst                                           ),

        .dispatch_unit_datain_valid                 ( dispatch_unit_datain_valid                    ),
        .dispatch_unit_datain                       ( dispatch_unit_datain                          ),
        .begin_load_fifo                            ( dispatch_unit_begin_load_fifo                 ),
        .descriptor_buffer_select                   ( dispatch_unit_descriptor_buffer_select        ),
        .total_keypoint_load_count                  ( dispatch_unit_total_keypoint_load_count       ),
        .dispatch_unit_done_buffer_load             ( dispatch_unit_done_buffer_load                ),
        .buffer_total_kp_load_cnt                   ( disp_buffer_total_kp_load_cnt                 ),
        
        .descriptor_buffer_load_data                ( dispatch_unit_descriptor_buffer_load_data     ),
        .descriptor_buffer_load_info                ( dispatch_unit_descriptor_buffer_load_info     ),
        .descriptor_buffer_load_valid               ( dispatch_unit_descriptor_buffer_load_valid    ),
        .sec_buffer_not_loading                     ( sec_buffer_not_loading                        )
    );
  
  
    brute_force_matcher_circular_descriptor_buffer #(
        .C_DESCRIPTOR_TABLE_DEPTH   ( C_PRIM_DESCRIPTOR_TABLE_DEPTH   ),
        .C_DESCRIPTOR_INFO_TYPE     ( `DESCRIPTOR_INFO_TYPE_MODEL     ),
        .C_PRIM_BUFFER              ( 1                               )
    ) 
    i0_brute_force_matcher_primary_descriptor_buffer (
        .rst                        ( rst                                       ),
        .force_rst                  ( force_rst                                 ),

        .num_model_kp               ( num_model_kp                              ),
        .buffer_load_clk            ( interface_clk                             ),
        .buffer_load_init           ( primary_descriptor_buffer_load_init       ),
        .buffer_load_info           ( primary_descriptor_buffer_load_info_r     ),
        .buffer_load_data           ( primary_descriptor_buffer_load_data_r     ),
        .buffer_load_count          ( primary_descriptor_buffer_load_count      ),
        .buffer_load_valid          ( primary_descriptor_buffer_load_valid      ),

        .buffer_read_clk            ( compute_clk                               ),
        .buffer_read_init           ( primary_descriptor_buffer_read_init       ),
        .buffer_read_info           ( primary_descriptor_buffer_read_info       ),
        .buffer_read_data           ( primary_descriptor_buffer_read_data       ),
        .buffer_read_valid          ( primary_descriptor_buffer_read_valid      ),
        .buffer_read_advance        ( advance                                   ),

        .buffer_empty               ( primary_descriptor_buffer_empty           )
    );    

    genvar i;
    generate
        for(i = 0; i < `NUM_ENGINES; i = i + 1) begin
            brute_force_matcher_engine #(
                .C_SEC_DESCRIPTOR_TABLE_DEPTH  (C_SEC_DESCRIPTOR_TABLE_DEPTH ),
                .C_SEC_DESC_FIFO_DEPTH         (C_SEC_DESC_FIFO_DEPTH        )
            ) 
            i0_brute_force_matcher_engine (                                                                                                                                   
                .compute_clk                                     ( compute_clk                                                                                                  ),
                .interface_clk                                   ( interface_clk                                                                                                ),
                .rst                                             ( rst                                                                                                          ),
                .force_rst                                       ( force_rst                                                                                                    ),

                .primary_descriptor_buffer_read_info             ( primary_descriptor_buffer_read_info                                                                          ),
                .primary_descriptor_buffer_read_data             ( primary_descriptor_buffer_read_data                                                                          ),
                .primary_descriptor_buffer_read_valid            ( primary_descriptor_buffer_read_valid                                                                         ),
                .primary_descriptor_buffer_read_init             ( i_primary_descriptor_buffer_read_init            [i]                                                         ),
                .primary_descriptor_buffer_empty                 ( primary_descriptor_buffer_empty                                                                              ),
                
                .secondary_descriptor_buffer_space_available     ( i_secondary_descriptor_buffer_space_available    [(i * 1) +: 1]                                              ),
                .secondary_descriptor_buffer_depleted            ( i_secondary_descriptor_buffer_depleted           [(i * 1) +: 1]                                              ),
                .secondary_descriptor_buffer_load_init           ( secondary_descriptor_buffer_load_init                                                                        ),
                .secondary_descriptor_buffer_load_data           ( i_secondary_descriptor_buffer_load_data          [(i * C_BUFFER_DATA_WIDTH) +: C_BUFFER_DATA_WIDTH]          ),
                .secondary_descriptor_buffer_load_valid          ( i_secondary_descriptor_buffer_load_valid         [(i * 1) +: 1]                                              ),
                .secondary_descriptor_buffer_load_info           ( i_secondary_descriptor_buffer_load_info          [(i * `DESCRIPTOR_INFO_WIDTH) +: `DESCRIPTOR_INFO_WIDTH]    ),
                .secondary_descriptor_buffer_load_count          ( i_secondary_descriptor_buffer_load_count         [(i * 16) +: 16]                                            ),
                .sec_desc_engine_desc_valid                      ( i_sec_desc_engine_desc_valid                     [i]                                                         ),
                .all_sec_desc_engine_desc_valid                  ( all_sec_desc_engine_desc_valid                                                                               ),

                .match_table_ready                               ( i_match_table_ready                              [(i * 1) +: 1]                                              ),
                .match_info_valid                                ( i_match_info_valid                               [(i * 1) +: 1]                                              ),
                .match_info                                      ( i_match_info                                     [(i * `MATCH_INFO_WIDTH) +: `MATCH_INFO_WIDTH]              ),

                .advance                                         ( i_advance                                        [(i * 1) +: 1]                                              ),
                .sec_buffer_wren                                 ( i_sec_buffer_wren                                [(i * 1) +: 1]                                              )
            );           
        end
        
        assign all_sec_desc_engine_desc_valid                 = (controller_last_cell_kp_batch) ? i_sec_desc_engine_desc_valid[(last_engine_loaded * 1) +: 1] : &i_sec_desc_engine_desc_valid;
        assign primary_descriptor_buffer_read_init            = i_primary_descriptor_buffer_read_init[0];
        assign advance                                        = i_advance[0];

    endgenerate
 
 
    // BEGIN Cluser Descriptor Engine logic ---------------------------------------------------------------------------------------------------------
    assign primary_descriptor_buffer_load_count         = disp_buffer_total_kp_load_cnt;
    assign primary_descriptor_buffer_load_valid         = dispatch_unit_descriptor_buffer_load_valid[`PRIM_BUFFER_SELECT_IDX];
    assign primary_descriptor_buffer_load_data          = dispatch_unit_descriptor_buffer_load_data;
    assign primary_descriptor_buffer_load_info          = dispatch_unit_descriptor_buffer_load_info;
    assign sec_buffer_not_loading                       = !(state == ST_SEC_BUF_LOADING);
    assign sec_buffer_wren                              = |i_sec_buffer_wren;
    
    always@(*) begin
        for(idx1 = 0; idx1 < `NUM_ENGINES; idx1 = idx1 + 1) begin
            if(idx1 == idx0 && dispatch_unit_descriptor_buffer_load_valid[`SEC_BUFFER_SELECT_IDX]) begin
                i_secondary_descriptor_buffer_load_valid[(idx1 * 1) +: 1]                                           = 1;
                i_secondary_descriptor_buffer_load_data[(idx1 * C_BUFFER_DATA_WIDTH) +: C_BUFFER_DATA_WIDTH]        = dispatch_unit_descriptor_buffer_load_data;
                i_secondary_descriptor_buffer_load_info[(idx1 * `DESCRIPTOR_INFO_WIDTH) +: `DESCRIPTOR_INFO_WIDTH]  = dispatch_unit_descriptor_buffer_load_info;
            end else begin
                i_secondary_descriptor_buffer_load_valid[(idx1 * 1) +: 1]                                           = 0;
                i_secondary_descriptor_buffer_load_data[(idx1 * C_BUFFER_DATA_WIDTH) +: C_BUFFER_DATA_WIDTH]        = 0;
                i_secondary_descriptor_buffer_load_info[(idx1 * `DESCRIPTOR_INFO_WIDTH) +: `DESCRIPTOR_INFO_WIDTH]  = 0;
            end
        end
    end
    
    always@(posedge interface_clk) begin
        if(rst || force_rst) begin
            idx0                    <= 0;
            last_engine_loaded      <= 0;
        end else begin
            if(`NUM_ENGINES > 1) begin
                if(dispatch_unit_descriptor_buffer_load_valid[`SEC_BUFFER_SELECT_IDX]) begin
                    last_engine_loaded  <= idx0;
                    if(idx0 == (`NUM_ENGINES - 1)) begin
                        idx0    <= 0;
                    end else begin
                        idx0    <= idx0 + 1;
                    end                   
                end
            end
        end
    end
    
    always@(posedge interface_clk) begin
        if(rst) begin
            load_count  <= 0;
            state       <= ST_IDLE;
        end else begin
            case(state)
                ST_IDLE: begin
                    if(dispatch_unit_begin_load_fifo && dispatch_unit_descriptor_buffer_select[`SEC_BUFFER_SELECT_IDX]) begin
                        load_count  <= dispatch_unit_total_keypoint_load_count;
                        state       <= ST_SEC_BUF_LOADING;
                    end
                end                
                ST_SEC_BUF_LOADING: begin
                    if(load_count == 0) begin
                        state <= ST_IDLE;
                    end else if(sec_buffer_wren) begin
                        load_count <= load_count - 1;
                    end
                end
                default: begin
                
                end            
            endcase
        end
    end
    // END Cluster Descriptor Engine logic ----------------------------------------------------------------------------------------------------------

    
`ifdef SIMULATION    
    string state_s;
    always@(state) begin 
        case(state) 
            ST_IDLE                 : state_s = "ST_IDLE";
            ST_SEC_BUF_LOADING      : state_s = "ST_SEC_BUF_LOADING";
        endcase
    end
`endif
  
endmodule
