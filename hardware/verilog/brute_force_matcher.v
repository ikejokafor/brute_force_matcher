`timescale 1ns / 1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//    
// Engineer: Ikenna Okafor  
//
// Create Date:  
// Design Name:  
// Module Name:  
// Project Name: 
// Target Devices:  
// Tool versions:
// Description:     Primary Top Level Module 
//
// Dependencies:
//  
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher (  
    sap_clk                      ,
    sap_rst                      ,

    vendor_id                    ,
    device_id                    ,
    class_code                   ,
    revision_id                  ,

    master_clk                   ,
    master_rst                   ,
    master_request               ,
    master_request_ack           ,
    master_request_complete      ,
    master_request_option        ,
    master_request_error         ,
    master_request_tag           ,
    master_request_type          ,
    master_request_flow          ,
    master_request_local_address ,
    master_request_length        ,

    master_descriptor_src_rdy    ,
    master_descriptor_dst_rdy    ,
    master_descriptor_tag        ,
    master_descriptor            ,

    master_datain_src_rdy        ,
    master_datain_dst_rdy        ,
    master_datain_option         ,
    master_datain_tag            ,
    master_datain                ,

    master_dataout_src_rdy       ,
    master_dataout_dst_rdy       ,
    master_dataout_option        ,
    master_dataout_tag           ,
    master_dataout               ,

    slave_clk                    ,
    slave_rst                    ,
    slave_burst_start            ,
    slave_burst_length           ,
    slave_burst_rnw              ,
    slave_address                ,
    slave_transaction_id         ,
    slave_transaction_option     ,
    slave_address_valid          ,
    slave_address_ack            ,
    slave_wrreq                  ,
    slave_wrack                  ,
    slave_be                     ,
    slave_datain                 ,
    slave_rdreq                  ,
    slave_rdack                  ,
    slave_dataout                ,

    send_msg_request             ,
    send_msg_ack                 ,
    send_msg_complete            ,
    send_msg_error               ,
    send_msg_src_rdy             ,
    send_msg_dst_rdy             ,
    send_msg_payload             ,

    recv_msg_request             ,
    recv_msg_ack                 ,
    recv_msg_src_rdy             ,
    recv_msg_dst_rdy             ,
    recv_msg_payload             
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
    localparam C_DISPATCH_DATAIN_WIDTH = `DATAIN_WIDTH + `DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH;
    localparam C_SEC_DESC_FIFO_DEPTH   =    (`SIMD == 8) ? 16'd32 :  
                                            (`SIMD == 8) ? 16'd16 : 16'd32;
    localparam C_DWC_FIFO_READ_DEPTH   =    (`SIMD == 8 ) ? 16'd16384 :
                                            (`SIMD == 64) ? 16'd4096 : 16'd16384;
    localparam C_MATCH_INFO_WIDTH      = `MATCH_INFO_WIDTH * `NUM_ENGINES;
    localparam C_SEC_DESC_BUF_LOAD_CNT = `NUM_ENGINES * 16;


    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Ouputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input               sap_clk;
    input               sap_rst;

    output      [15:0]  vendor_id;
    output      [15:0]  device_id;
    output      [23:0]  class_code;
    output      [7:0]   revision_id;

    output              master_clk;
    output              master_rst;
    output              master_request;
    input               master_request_ack;
    input               master_request_complete;
    output      [3 :0]  master_request_option;
    input       [6 :0]  master_request_error;
    input       [3  :0] master_request_tag;
    output      [3  :0] master_request_type;
    output      [9  :0] master_request_flow;
    output      [63 :0] master_request_local_address;
    output      [35 :0] master_request_length;
    // SAP Master Descriptor Interface 
    output              master_descriptor_src_rdy;
    input               master_descriptor_dst_rdy;
    input       [3  :0] master_descriptor_tag;
    output      [127:0] master_descriptor;
    // SAP Master Data Interface 
    input               master_datain_src_rdy;
    output              master_datain_dst_rdy;
    input       [3 :0]  master_datain_option;
    input       [3  :0] master_datain_tag;
    input       [127:0] master_datain;

    output              master_dataout_src_rdy;
    input               master_dataout_dst_rdy;
    input       [3 :0]  master_dataout_option;
    input       [3  :0] master_dataout_tag;
    output      [127:0] master_dataout;
    // SAP Slave Interface 
    output              slave_clk;
    output              slave_rst;
    input               slave_burst_start;
    input       [12:0]  slave_burst_length;
    input               slave_burst_rnw;
    input       [63 :0] slave_address;
    input       [3  :0] slave_transaction_id;
    input       [3  :0] slave_transaction_option;
    input               slave_address_valid;
    output              slave_address_ack;
    input       [3  :0] slave_wrreq;
    output              slave_wrack;
    input       [15 :0] slave_be;
    input       [127:0] slave_datain;
    input       [3  :0] slave_rdreq;
    output              slave_rdack;
    output      [127:0] slave_dataout;
    // SAP Message Send Interface (Unused)
    output              send_msg_request;
    input               send_msg_ack;
    input               send_msg_complete;
    input       [1  :0] send_msg_error;
    output              send_msg_src_rdy;
    input               send_msg_dst_rdy;
    output      [127:0] send_msg_payload;
    // SAP Message Recv Interface (Unused)
    input               recv_msg_request;
    output              recv_msg_ack;
    input               recv_msg_src_rdy;
    output              recv_msg_dst_rdy;
    input       [127:0] recv_msg_payload;
    

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------      
    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_request;
    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_request_ack;
    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_request_complete;
    wire [ (`NUM_MAST_INF_CLIENTS * 4 ) - 1:0]      i_master_request_option;
    wire [ (`NUM_MAST_INF_CLIENTS * 7 ) - 1:0]      i_master_request_error;
    wire [ (`NUM_MAST_INF_CLIENTS * 4 ) - 1:0]      i_master_request_tag;
    wire [ (`NUM_MAST_INF_CLIENTS * 4 ) - 1:0]      i_master_request_type;
    wire [ (`NUM_MAST_INF_CLIENTS * 10) - 1:0]      i_master_request_flow;
    wire [ (`NUM_MAST_INF_CLIENTS * 64) - 1:0]      i_master_request_local_address;
    wire [ (`NUM_MAST_INF_CLIENTS * 36) - 1:0]      i_master_request_length;

    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_descriptor_src_rdy;
    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_descriptor_dst_rdy;
    wire [(`NUM_MAST_INF_CLIENTS * 4  ) - 1:0]      i_master_descriptor_tag;
    wire [(`NUM_MAST_INF_CLIENTS * 128) - 1:0]      i_master_descriptor;
    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_datain_src_rdy;
    wire [        `NUM_MAST_INF_CLIENTS - 1:0]      i_master_datain_dst_rdy;
    wire [(`NUM_MAST_INF_CLIENTS * 4  ) - 1:0]      i_master_datain_option;
    wire [(`NUM_MAST_INF_CLIENTS * 4  ) - 1:0]      i_master_datain_tag;
    wire [(`NUM_MAST_INF_CLIENTS * 128) - 1:0]      i_master_datain;

    wire [      `NUM_MAST_INF_CLIENTS   - 1:0]      i_master_dataout_src_rdy;
    wire [      `NUM_MAST_INF_CLIENTS   - 1:0]      i_master_dataout_dst_rdy;
    wire [(`NUM_MAST_INF_CLIENTS * 4  ) - 1:0]      i_master_dataout_option;
    wire [(`NUM_MAST_INF_CLIENTS * 4  ) - 1:0]      i_master_dataout_tag;
    wire [(`NUM_MAST_INF_CLIENTS * 128) - 1:0]      i_master_dataout;

    wire                                            secondary_descriptor_buffer_load_init;
    wire  [                 `NUM_ENGINES - 1:0]     i_secondary_descriptor_buffer_depleted;
    wire  [                 `NUM_ENGINES - 1:0]     i_secondary_descriptor_buffer_space_available;
    wire  [      C_SEC_DESC_BUF_LOAD_CNT - 1:0]     i_secondary_descriptor_buffer_load_count;
    wire                                            controller_init_keypoint_engine;
    wire                                            primary_descriptor_buffer_load_init;

    wire [      C_DISPATCH_DATAIN_WIDTH - 1:0]      dispatch_unit_datain;
    wire                                            dispatch_unit_datain_valid;
    wire                                            dispatch_unit_begin_load_fifo;
    wire [                                1:0]      dispatch_unit_descriptor_buffer_select;
    wire [                               15:0]      dispatch_unit_total_keypoint_load_count;
    wire                                            dispatch_unit_done_buffer_load;

    wire [                 `NUM_ENGINES - 1:0]      i_match_table_ready;
    wire [                 `NUM_ENGINES - 1:0]      i_match_info_valid;
    wire [           C_MATCH_INFO_WIDTH - 1:0]      i_match_info;

    wire                                            match_clk;

    wire [                 `NUM_ENGINES - 1:0]      i_match_table_processing_complete;
    wire [          (64 * `NUM_ENGINES) - 1:0]      i_match_table_info_address;
    wire [          (64 * `NUM_ENGINES) - 1:0]      i_match_table_address;
    wire [          (36 * `NUM_ENGINES) - 1:0]      i_match_table_length;
    wire [                               15:0]      controller_num_model_kp; 
    wire [          (16 * `NUM_ENGINES) - 1:0]      i_controller_num_obsvd_kp; 
    
    reg [                               127:0]      slave_register;
    wire                                            controller_force_rst;
    wire                                            controller_last_cell_kp_batch;
    //wire [31:0]                                   performance_counter_single_frame;
 

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    master_if_arbiter_nway #(
        .C_NUM_CLIENTS       (`NUM_MAST_INF_CLIENTS    )
    )
    i_master_if_arbiter
    (
        .clk                                  ( sap_clk                        ),
        .rst                                  ( sap_rst                        ),

        .master_request                       ( master_request                 ),
        .master_request_ack                   ( master_request_ack             ),
        .master_request_complete              ( master_request_complete        ),
        .master_request_error                 ( master_request_error           ),
        .master_request_tag                   ( master_request_tag             ),
        .master_request_type                  ( master_request_type            ),
        .master_request_option                ( master_request_option          ),
        .master_request_flow                  ( master_request_flow            ),
        .master_request_local_address         ( master_request_local_address   ),
        .master_request_length                ( master_request_length          ),

        .master_descriptor_src_rdy            ( master_descriptor_src_rdy      ),
        .master_descriptor_dst_rdy            ( master_descriptor_dst_rdy      ),
        .master_descriptor_tag                ( master_descriptor_tag          ),
        .master_descriptor                    ( master_descriptor              ),

        .master_datain_src_rdy                ( master_datain_src_rdy          ),
        .master_datain_dst_rdy                ( master_datain_dst_rdy          ),
        .master_datain_tag                    ( master_datain_tag              ),
        .master_datain_option                 ( master_datain_option           ),
        .master_datain                        ( master_datain                  ),

        .master_dataout_src_rdy               ( master_dataout_src_rdy         ),
        .master_dataout_dst_rdy               ( master_dataout_dst_rdy         ),
        .master_dataout_tag                   ( master_dataout_tag             ),
        .master_dataout_option                ( master_dataout_option          ),
        .master_dataout                       ( master_dataout                 ),

        .clientX_master_request               ( i_master_request               ),
        .clientX_master_request_ack           ( i_master_request_ack           ),
        .clientX_master_request_complete      ( i_master_request_complete      ),
        .clientX_master_request_error         ( i_master_request_error         ),
        .clientX_master_request_tag           ( i_master_request_tag           ),
        .clientX_master_request_type          ( i_master_request_type          ),
        .clientX_master_request_option        ( i_master_request_option        ),
        .clientX_master_request_flow          ( i_master_request_flow          ),
        .clientX_master_request_local_address ( i_master_request_local_address ),
        .clientX_master_request_length        ( i_master_request_length        ),

        .clientX_master_descriptor_src_rdy    ( i_master_descriptor_src_rdy    ),
        .clientX_master_descriptor_dst_rdy    ( i_master_descriptor_dst_rdy    ),
        .clientX_master_descriptor_tag        ( i_master_descriptor_tag        ),
        .clientX_master_descriptor            ( i_master_descriptor            ),

        .clientX_master_datain_src_rdy        ( i_master_datain_src_rdy        ),
        .clientX_master_datain_dst_rdy        ( i_master_datain_dst_rdy        ),
        .clientX_master_datain_tag            ( i_master_datain_tag            ),
        .clientX_master_datain_option         ( i_master_datain_option         ),
        .clientX_master_datain                ( i_master_datain                ),

        .clientX_master_dataout_src_rdy       ( i_master_dataout_src_rdy       ),
        .clientX_master_dataout_dst_rdy       ( i_master_dataout_dst_rdy       ),
        .clientX_master_dataout_tag           ( i_master_dataout_tag           ),
        .clientX_master_dataout_option        ( i_master_dataout_option        ),
        .clientX_master_dataout               ( i_master_dataout               )
    );

 
    brute_force_matcher_controller
    i0_brute_force_matcher_controller (
        .clk                                            ( sap_clk                                               ),
        .rst                                            ( sap_rst                                               ),
    
        .model_master_request                           ( i_master_request               [               0]     ),
        .model_master_request_ack                       ( i_master_request_ack           [               0]     ),
        .model_master_request_complete                  ( i_master_request_complete      [               0]     ),
        .model_master_request_error                     ( i_master_request_error         [    (0 * 7) +: 7]     ),
        .model_master_request_tag                       ( i_master_request_tag           [   (0 * 4) +: 4 ]     ),
        .model_master_request_option                    ( i_master_request_option        [   (0 * 4) +: 4 ]     ),
        .model_master_request_type                      ( i_master_request_type          [   (0 * 4) +: 4 ]     ),
        .model_master_request_flow                      ( i_master_request_flow          [  (0 * 10) +: 10]     ),
        .model_master_request_local_address             ( i_master_request_local_address [  (0 * 64) +: 64]     ),
        .model_master_request_length                    ( i_master_request_length        [  (0 * 36) +: 36]     ),

        .model_master_descriptor_src_rdy                ( i_master_descriptor_src_rdy    [               0]     ),
        .model_master_descriptor_dst_rdy                ( i_master_descriptor_dst_rdy    [               0]     ),
        .model_master_descriptor_tag                    ( i_master_descriptor_tag        [    (0 * 4) +: 4]     ),
        .model_master_descriptor                        ( i_master_descriptor            [(0 * 128) +: 128]     ),

        .model_master_datain_src_rdy                    ( i_master_datain_src_rdy        [               0]     ),
        .model_master_datain_dst_rdy                    ( i_master_datain_dst_rdy        [               0]     ),
        .model_master_datain_tag                        ( i_master_datain_tag            [    (0 * 4) +: 4]     ),
        .model_master_datain_option                     ( i_master_datain_option         [    (0 * 4) +: 4]     ),
        .model_master_datain                            ( i_master_datain                [(0 * 128) +: 128]     ),

        .model_master_dataout_src_rdy                   ( i_master_dataout_src_rdy       [               0]     ),
        .model_master_dataout_dst_rdy                   ( i_master_dataout_dst_rdy       [               0]     ),
        .model_master_dataout_tag                       ( i_master_dataout_tag           [    (0 * 4) +: 4]     ),
        .model_master_dataout_option                    ( i_master_dataout_option        [    (0 * 4) +: 4]     ),
        .model_master_dataout                           ( i_master_dataout               [(0 * 128) +: 128]     ),
        
        .cell_master_request                            ( i_master_request               [               1]     ),
        .cell_master_request_ack                        ( i_master_request_ack           [               1]     ),
        .cell_master_request_complete                   ( i_master_request_complete      [               1]     ),
        .cell_master_request_error                      ( i_master_request_error         [    (1 * 7) +: 7]     ),
        .cell_master_request_tag                        ( i_master_request_tag           [   (1 * 4) +: 4 ]     ),
        .cell_master_request_option                     ( i_master_request_option        [   (1 * 4) +: 4 ]     ),
        .cell_master_request_type                       ( i_master_request_type          [   (1 * 4) +: 4 ]     ),
        .cell_master_request_flow                       ( i_master_request_flow          [  (1 * 10) +: 10]     ),
        .cell_master_request_local_address              ( i_master_request_local_address [  (1 * 64) +: 64]     ),
        .cell_master_request_length                     ( i_master_request_length        [  (1 * 36) +: 36]     ),

        .cell_master_descriptor_src_rdy                 ( i_master_descriptor_src_rdy    [               1]     ),
        .cell_master_descriptor_dst_rdy                 ( i_master_descriptor_dst_rdy    [               1]     ),
        .cell_master_descriptor_tag                     ( i_master_descriptor_tag        [    (1 * 4) +: 4]     ),
        .cell_master_descriptor                         ( i_master_descriptor            [(1 * 128) +: 128]     ),

        .cell_master_datain_src_rdy                     ( i_master_datain_src_rdy        [               1]     ),
        .cell_master_datain_dst_rdy                     ( i_master_datain_dst_rdy        [               1]     ),
        .cell_master_datain_tag                         ( i_master_datain_tag            [    (1 * 4) +: 4]     ),
        .cell_master_datain_option                      ( i_master_datain_option         [    (1 * 4) +: 4]     ),
        .cell_master_datain                             ( i_master_datain                [(1 * 128) +: 128]     ),

        .cell_master_dataout_src_rdy                    ( i_master_dataout_src_rdy       [               1]     ),
        .cell_master_dataout_dst_rdy                    ( i_master_dataout_dst_rdy       [               1]     ),
        .cell_master_dataout_tag                        ( i_master_dataout_tag           [    (1 * 4) +: 4]     ),
        .cell_master_dataout_option                     ( i_master_dataout_option        [    (1 * 4) +: 4]     ),
        .cell_master_dataout                            ( i_master_dataout               [(1 * 128) +: 128]     ),
    
        .send_msg_request                               ( send_msg_request                                      ),
        .send_msg_ack                                   ( send_msg_ack                                          ),
        .send_msg_complete                              ( send_msg_complete                                     ),
        .send_msg_error                                 ( send_msg_error                                        ),
        .send_msg_src_rdy                               ( send_msg_src_rdy                                      ),
        .send_msg_dst_rdy                               ( send_msg_dst_rdy                                      ),
        .send_msg_payload                               ( send_msg_payload                                      ),
    
        .recv_msg_request                               ( recv_msg_request                                      ),
        .recv_msg_ack                                   ( recv_msg_ack                                          ),
        .recv_msg_src_rdy                               ( recv_msg_src_rdy                                      ),
        .recv_msg_dst_rdy                               ( recv_msg_dst_rdy                                      ),
        .recv_msg_payload                               ( recv_msg_payload                                      ),
        
        .i_secondary_descriptor_buffer_depleted         ( i_secondary_descriptor_buffer_depleted                ),
        .i_secondary_descriptor_buffer_space_available  ( i_secondary_descriptor_buffer_space_available         ),
        .i_secondary_descriptor_buffer_load_count       ( i_secondary_descriptor_buffer_load_count              ),

        .secondary_descriptor_buffer_load_init          ( secondary_descriptor_buffer_load_init                 ),
        .primary_descriptor_buffer_load_init            ( primary_descriptor_buffer_load_init                   ),

        .init_keypoint_engine                           ( controller_init_keypoint_engine                       ),

        .dispatch_unit_datain_valid                     ( dispatch_unit_datain_valid                            ),
        .dispatch_unit_datain                           ( dispatch_unit_datain                                  ),
        .dispatch_unit_begin_load_fifo                  ( dispatch_unit_begin_load_fifo                         ),
        .dispatch_unit_descriptor_buffer_select         ( dispatch_unit_descriptor_buffer_select                ),
        .dispatch_unit_total_keypoint_load_count        ( dispatch_unit_total_keypoint_load_count               ),
        .dispatch_unit_done_buffer_load                 ( dispatch_unit_done_buffer_load                        ),

        .num_model_kp                                   ( controller_num_model_kp                               ),
        .i_num_obsvd_kp                                 ( i_controller_num_obsvd_kp                             ),

        .i_match_table_processing_complete              ( i_match_table_processing_complete                     ),
        .i_match_table_info_address                     ( i_match_table_info_address                            ),
        .i_match_table_length                           ( i_match_table_length                                  ),
        .i_match_table_address                          ( i_match_table_address                                 ),
        .force_rst                                      ( controller_force_rst                                  ),
        .last_cell_kp_batch                             ( controller_last_cell_kp_batch                         )   
        
        //.performance_counter_single_frame            ( performance_counter_single_frame                  )
 );
 
 
    brute_force_matcher_datapath #(
        .C_DWC_FIFO_READ_DEPTH                       (C_DWC_FIFO_READ_DEPTH                             ),
        .C_PRIM_DESCRIPTOR_TABLE_DEPTH               (`PRIM_DESCRIPTOR_TABLE_DEPTH                      ),
        .C_SEC_DESCRIPTOR_TABLE_DEPTH                (`SEC_DESCRIPTOR_TABLE_DEPTH                       ),
        .C_SEC_DESC_FIFO_DEPTH                       (C_SEC_DESC_FIFO_DEPTH                             )
    )
    i0_brute_force_matcher_datapath (  
        .interface_clk                                      ( sap_clk                                           ),
        .compute_clk                                        ( sap_clk                                           ),
        .rst                                                ( sap_rst                                           ),
        .force_rst                                          ( controller_force_rst                              ),

        .num_model_kp                                       ( controller_num_model_kp                           ),
        .i_secondary_descriptor_buffer_load_count           ( i_secondary_descriptor_buffer_load_count          ),
        .i_secondary_descriptor_buffer_depleted             ( i_secondary_descriptor_buffer_depleted            ),
        .i_secondary_descriptor_buffer_space_available      ( i_secondary_descriptor_buffer_space_available     ),

        .dispatch_unit_datain_valid                         ( dispatch_unit_datain_valid                        ),
        .dispatch_unit_datain                               ( dispatch_unit_datain                              ),
        .dispatch_unit_begin_load_fifo                      ( dispatch_unit_begin_load_fifo                     ),
        .dispatch_unit_descriptor_buffer_select             ( dispatch_unit_descriptor_buffer_select            ),
        .dispatch_unit_total_keypoint_load_count            ( dispatch_unit_total_keypoint_load_count           ),
        .dispatch_unit_done_buffer_load                     ( dispatch_unit_done_buffer_load                    ),

        .secondary_descriptor_buffer_load_init              ( secondary_descriptor_buffer_load_init             ),
        .primary_descriptor_buffer_load_init                ( primary_descriptor_buffer_load_init               ),
        .controller_last_cell_kp_batch                      ( controller_last_cell_kp_batch                     ),

        .i_match_table_ready                                ( i_match_table_ready                               ),
        .i_match_info_valid                                 ( i_match_info_valid                                ),
        .i_match_info                                       ( i_match_info                                      )
    );
 
    genvar i;
    generate
        for(i = 0; i < `NUM_ENGINES; i = i + 1) begin 
            brute_force_matcher_match_table
            i0_brute_force_matcher_match_table (
                .clk                                        ( match_clk                                                                                 ),
                .rst                                        ( sap_rst                                                                                   ),
    
                .matchTable_master_request                      ( i_master_request                       [                               ((i * 2) + 2)]     ),
                .matchTable_master_request_ack                  ( i_master_request_ack                   [                               ((i * 2) + 2)]     ),
                .matchTable_master_request_complete             ( i_master_request_complete              [                               ((i * 2) + 2)]     ),
                .matchTable_master_request_error                ( i_master_request_error                 [                    (((i * 2) + 2) * 7) +: 7]     ),
                .matchTable_master_request_tag                  ( i_master_request_tag                   [                   (((i * 2) + 2) * 4) +: 4 ]     ),
                .matchTable_master_request_option               ( i_master_request_option                [                   (((i * 2) + 2) * 4) +: 4 ]     ),
                .matchTable_master_request_type                 ( i_master_request_type                  [                   (((i * 2) + 2) * 4) +: 4 ]     ),
                .matchTable_master_request_flow                 ( i_master_request_flow                  [                  (((i * 2) + 2) * 10) +: 10]     ),
                .matchTable_master_request_local_address        ( i_master_request_local_address         [                  (((i * 2) + 2) * 64) +: 64]     ),
                .matchTable_master_request_length               ( i_master_request_length                [                  (((i * 2) + 2) * 36) +: 36]     ),

                .matchTable_master_descriptor_src_rdy           ( i_master_descriptor_src_rdy            [                               ((i * 2) + 2)]     ),
                .matchTable_master_descriptor_dst_rdy           ( i_master_descriptor_dst_rdy            [                               ((i * 2) + 2)]     ),
                .matchTable_master_descriptor_tag               ( i_master_descriptor_tag                [                    (((i * 2) + 2) * 4) +: 4]     ),
                .matchTable_master_descriptor                   ( i_master_descriptor                    [                (((i * 2) + 2) * 128) +: 128]     ),

                .matchTable_master_datain_src_rdy               ( i_master_datain_src_rdy                [                               ((i * 2) + 2)]     ),
                .matchTable_master_datain_dst_rdy               ( i_master_datain_dst_rdy                [                               ((i * 2) + 2)]     ),
                .matchTable_master_datain_tag                   ( i_master_datain_tag                    [                    (((i * 2) + 2) * 4) +: 4]     ),
                .matchTable_master_datain_option                ( i_master_datain_option                 [                    (((i * 2) + 2) * 4) +: 4]     ),
                .matchTable_master_datain                       ( i_master_datain                        [                (((i * 2) + 2) * 128) +: 128]     ),

                .matchTable_master_dataout_src_rdy              ( i_master_dataout_src_rdy               [                               ((i * 2) + 2)]     ),
                .matchTable_master_dataout_dst_rdy              ( i_master_dataout_dst_rdy               [                               ((i * 2) + 2)]     ),
                .matchTable_master_dataout_tag                  ( i_master_dataout_tag                   [                    (((i * 2) + 2) * 4) +: 4]     ),
                .matchTable_master_dataout_option               ( i_master_dataout_option                [                    (((i * 2) + 2) * 4) +: 4]     ),
                .matchTable_master_dataout                      ( i_master_dataout                       [                (((i * 2) + 2) * 128) +: 128]     ),

                .matchTableInfo_master_request                  ( i_master_request                       [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_request_ack              ( i_master_request_ack                   [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_request_complete         ( i_master_request_complete              [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_request_error            ( i_master_request_error                 [                    (((i * 2) + 3) * 7) +: 7]     ),
                .matchTableInfo_master_request_tag              ( i_master_request_tag                   [                   (((i * 2) + 3) * 4) +: 4 ]     ),
                .matchTableInfo_master_request_option           ( i_master_request_option                [                   (((i * 2) + 3) * 4) +: 4 ]     ),
                .matchTableInfo_master_request_type             ( i_master_request_type                  [                   (((i * 2) + 3) * 4) +: 4 ]     ),
                .matchTableInfo_master_request_flow             ( i_master_request_flow                  [                  (((i * 2) + 3) * 10) +: 10]     ),
                .matchTableInfo_master_request_local_address    ( i_master_request_local_address         [                  (((i * 2) + 3) * 64) +: 64]     ),
                .matchTableInfo_master_request_length           ( i_master_request_length                [                  (((i * 2) + 3) * 36) +: 36]     ),

                .matchTableInfo_master_descriptor_src_rdy       ( i_master_descriptor_src_rdy            [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_descriptor_dst_rdy       ( i_master_descriptor_dst_rdy            [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_descriptor_tag           ( i_master_descriptor_tag                [                    (((i * 2) + 3) * 4) +: 4]     ),
                .matchTableInfo_master_descriptor               ( i_master_descriptor                    [                (((i * 2) + 3) * 128) +: 128]     ),

                .matchTableInfo_master_datain_src_rdy           ( i_master_datain_src_rdy                [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_datain_dst_rdy           ( i_master_datain_dst_rdy                [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_datain_tag               ( i_master_datain_tag                    [                    (((i * 2) + 3) * 4) +: 4]     ),
                .matchTableInfo_master_datain_option            ( i_master_datain_option                 [                    (((i * 2) + 3) * 4) +: 4]     ),
                .matchTableInfo_master_datain                   ( i_master_datain                        [                (((i * 2) + 3) * 128) +: 128]     ),

                .matchTableInfo_master_dataout_src_rdy          ( i_master_dataout_src_rdy               [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_dataout_dst_rdy          ( i_master_dataout_dst_rdy               [                               ((i * 2) + 3)]     ),
                .matchTableInfo_master_dataout_tag              ( i_master_dataout_tag                   [                    (((i * 2) + 3) * 4) +: 4]     ),
                .matchTableInfo_master_dataout_option           ( i_master_dataout_option                [                    (((i * 2) + 3) * 4) +: 4]     ),
                .matchTableInfo_master_dataout                  ( i_master_dataout                       [                (((i * 2) + 3) * 128) +: 128]     ),

                .match_table_ready                              ( i_match_table_ready                    [                                           i]     ),
                .match_info_valid                               ( i_match_info_valid                     [                                           i]     ),
                .match_info                                     ( i_match_info                           [(i * `MATCH_INFO_WIDTH) +: `MATCH_INFO_WIDTH]     ),

                .init_keypoint_engine                           ( controller_init_keypoint_engine                                                           ),

                .controller_num_model_kp                        ( controller_num_model_kp                                                                   ),
                .controller_num_obsvd_kp                        ( i_controller_num_obsvd_kp              [                              (i * 16) +: 16]     ),

                .processing_complete                            ( i_match_table_processing_complete      [                                           i]     ),
                .match_table_info_address                       ( i_match_table_info_address             [                              (i * 64) +: 64]     ),

                .match_table_address                            ( i_match_table_address                  [                              (i * 64) +: 64]     ),
                .match_table_length                             ( i_match_table_length                   [                              (i * 36) +: 36]     ),
                .write_match_table_info                         ( slave_register                         [                                           i]     )
            );
        end
    endgenerate
 
    //assign slave_dataout       = performance_counter_single_frame;
    //assign slave_rdack         = slave_rdreq[0];
    //assign slave_address_ack   = slave_address_valid;
    //assign slave_wrack         = slave_wrreq[0];
    assign master_clk  = sap_clk;
    assign master_rst  = sap_rst;
    assign match_clk   = sap_clk;
    assign slave_clk   = sap_clk;
    assign slave_rst   = sap_rst;
    assign vendor_id   = 16'hFF00;
    assign device_id   = 16'h000B;
    assign revision_id = 8'h1;
    assign class_code  = 24'h120000;
    
    // BEGIN Slave Logic ----------------------------------------------------------------------------------------------------------------------------
    assign slave_rdack			= slave_rdreq[0];
	assign slave_address_ack	= slave_address_valid;
	assign slave_wrack			= slave_wrreq[0];
    assign slave_dataout        = 128'b0;

    always@(posedge slave_clk) begin
        if(slave_rst) begin
            slave_register <= 128'b0;
        end else begin
            if(slave_address_valid) begin
                slave_register <= slave_datain;      
            end
        end
    end
    // END Slave Logic ------------------------------------------------------------------------------------------------------------------------------
    
endmodule

