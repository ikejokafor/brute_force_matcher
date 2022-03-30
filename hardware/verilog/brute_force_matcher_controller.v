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
// Description:         Top level controller for accelerator. Recieves soc-it messages from host. Controls the 
//                reading of keypoint data from the host memory through soc-it messages and feedback from
//                datapath on descriptor buffer current size. After processing all keypoints, waits until
//                match table module signifies the match table info table is written to host memory. Then 
//                tells host memory processing is done through soc-it interface.
//
// Dependencies:        sap_receive_message_queue.v
//                sap_send_message_queue.v  
//                address_incrementer.v 
//                fifo_fwft.v 
//
// Revision:    
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_controller  (
    clk                                                 ,
    rst                                                 ,

    model_master_request                                ,
    model_master_request_ack                            ,
    model_master_request_complete                       ,
    model_master_request_error                          ,
    model_master_request_tag                            ,
    model_master_request_option                         ,
    model_master_request_type                           ,
    model_master_request_flow                           ,
    model_master_request_local_address                  ,
    model_master_request_length                         ,

    model_master_descriptor_src_rdy                     ,
    model_master_descriptor_dst_rdy                     ,
    model_master_descriptor_tag                         ,
    model_master_descriptor                             ,

    model_master_datain_src_rdy                         ,
    model_master_datain_dst_rdy                         ,
    model_master_datain_tag                             ,
    model_master_datain_option                          ,
    model_master_datain                                 ,

    model_master_dataout_src_rdy                        ,
    model_master_dataout_dst_rdy                        ,
    model_master_dataout_tag                            ,
    model_master_dataout_option                         ,
    model_master_dataout                                ,
    
    cell_master_request                                 ,
    cell_master_request_ack                             ,
    cell_master_request_complete                        ,
    cell_master_request_error                           ,
    cell_master_request_tag                             ,
    cell_master_request_option                          ,
    cell_master_request_type                            ,
    cell_master_request_flow                            ,
    cell_master_request_local_address                   ,
    cell_master_request_length                          ,

    cell_master_descriptor_src_rdy                      ,
    cell_master_descriptor_dst_rdy                      ,
    cell_master_descriptor_tag                          ,
    cell_master_descriptor                              ,

    cell_master_datain_src_rdy                          ,
    cell_master_datain_dst_rdy                          ,
    cell_master_datain_tag                              ,
    cell_master_datain_option                           ,
    cell_master_datain                                  ,

    cell_master_dataout_src_rdy                         ,
    cell_master_dataout_dst_rdy                         ,
    cell_master_dataout_tag                             ,
    cell_master_dataout_option                          ,
    cell_master_dataout                                 ,

    // SOC_IT send msg interface
    send_msg_request                                    ,
    send_msg_ack                                        ,
    send_msg_complete                                   ,
    send_msg_error                                      ,
    send_msg_src_rdy                                    ,
    send_msg_dst_rdy                                    ,
    send_msg_payload                                    ,
    // SOC_IT recv msg interface
    recv_msg_request                                    ,
    recv_msg_ack                                        ,
    recv_msg_src_rdy                                    ,
    recv_msg_dst_rdy                                    ,
    recv_msg_payload                                    ,

    i_secondary_descriptor_buffer_load_count            ,
    i_secondary_descriptor_buffer_depleted              ,
    i_secondary_descriptor_buffer_space_available       ,

    secondary_descriptor_buffer_load_init               ,
    primary_descriptor_buffer_load_init                 ,

    init_keypoint_engine                                ,

    dispatch_unit_datain_valid                          ,
    dispatch_unit_datain                                ,
    dispatch_unit_begin_load_fifo                       ,
    dispatch_unit_descriptor_buffer_select              ,
    dispatch_unit_total_keypoint_load_count             ,
    dispatch_unit_done_buffer_load                      ,

    num_model_kp                                        ,
    i_num_obsvd_kp                                      ,

    i_match_table_address                               ,
    i_match_table_length                                ,
    i_match_table_processing_complete                   ,
    i_match_table_info_address                          ,
    
    force_rst                                           ,
    last_cell_kp_batch                                  
    //performance_counter_single_frame                  
    
`ifdef EXOSTIV
    ,
    // model_master_request_exstv,                                                                        
    // model_master_request_ack_exstv,
    // model_master_request_complete_exstv,
    // model_master_request_error_exstv,
    // model_master_request_tag_exstv,
    // model_master_request_option_exstv,
    // model_master_request_type_exstv,
    // model_master_request_flow_exstv,
    // model_master_descriptor_src_rdy_exstv,
    // model_master_descriptor_dst_rdy_exstv,
    // model_master_descriptor_tag_exstv,
    // model_master_datain_src_rdy_exstv,
    // model_master_datain_dst_rdy_exstv,
    // model_master_datain_tag_exstv,
    // model_master_datain_option_exstv,
    // cell_master_request_exstv,
    // cell_master_request_ack_exstv,
    // cell_master_request_complete_exstv,
    // cell_master_request_error_exstv,
    // cell_master_request_tag_exstv,
    // cell_master_request_option_exstv,
    // cell_master_request_type_exstv,
    // cell_master_request_flow_exstv,
    // cell_master_descriptor_src_rdy_exstv,
    // cell_master_descriptor_dst_rdy_exstv,
    // cell_master_descriptor_tag_exstv,
    // cell_master_datain_src_rdy_exstv,
    // cell_master_datain_dst_rdy_exstv,
    // cell_master_datain_tag_exstv,
    // cell_master_datain_option_exstv,
    // i_secondary_descriptor_buffer_load_count_exstv,
    // i_secondary_descriptor_buffer_depleted_exstv,
    // i_secondary_descriptor_buffer_space_available_exstv,
    // secondary_descriptor_buffer_load_init_exstv,
    // primary_descriptor_buffer_load_init_exstv,
    // init_keypoint_engine_exstv,
    // dispatch_unit_datain_valid_exstv,
    // dispatch_unit_begin_load_fifo_exstv,
    // dispatch_unit_descriptor_buffer_select_exstv,
    // dispatch_unit_total_keypoint_load_count_exstv,
    // dispatch_unit_done_buffer_load_exstv,
    // num_model_kp_exstv,
    // i_num_obsvd_kp_exstv,
    // i_match_table_processing_complete_exstv,
    // force_rst_exstv,
    // last_cell_kp_batch_exstv,
    state_exstv,
    fsm_exstv,
    // modelData_initialize_exstv,   
    // modelData_initialize_request_type_exstv,
    // modelData_initialize_complete_exstv,
    // modelData_transactor_request_exstv,                                   
    // modelData_transactor_enable_exstv,                     
    // modelData_transactor_request_option_exstv,             
    // modelData_transactor_active_exstv, 
    // modelData_transaction_request_complete_exstv,
    // modelData_transactor_request_busy_exstv, 
    // cellData_initialize_exstv,  
    // cellData_initialize_request_type_exstv,    
    // cellData_initialize_complete_exstv,    
    // cellData_transactor_request_exstv,                                   
    // cellData_transactor_enable_exstv,                      
    // cellData_transactor_request_option_exstv,    
    // cellData_transactor_active_exstv, 
    // cellData_transaction_request_complete_exstv,
    // cellData_transactor_param_complete_exstv,
    // cellData_transactor_request_busy_exstv,
    // cell_keypoints_fetch_ready_exstv,                        
    // keypoint_data_load_count_exstv,
    // descriptor_count_exstv,
    // i_num_obsvd_kp_residual_exstv,
    // num_obsvd_kp_residual_exstv,
    // i_secondary_descriptor_buffer_load_count_r_exstv,
    // dispatch_unit_done_buffer_load_r_exstv,
    // dispatch_unit_done_buffer_load_r_model_reset_exstv,
    // dispatch_unit_done_buffer_load_r_obsvd_reset_exstv,
    // dispatch_unit_total_keypoint_load_count_r_exstv,
    // match_table_processing_complete_r_reset_exstv,
    // i_match_table_processing_complete_r_exstv

    
`endif
    
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
    localparam ST_IDLE                        = 14'b00000000000001;    // 0001
    localparam ST_LOAD_MESSAGE                = 14'b00000000000010;    // 0002
    localparam ST_DECODE_MESSAGE              = 14'b00000000000100;    // 0004
    localparam ST_INITIALIZE_DATAPATH         = 14'b00000000001000;    // 0008
    localparam ST_FETCH_MODEL_KEYPOINTS_0     = 14'b00000000010000;    // 0010
    localparam ST_FETCH_MODEL_KEYPOINTS_1     = 14'b00000000100000;    // 0020
    localparam ST_WAIT_MODEL_KEYPOINTS_LOAD   = 14'b00000001000000;    // 0040
    localparam ST_FETCH_CELL_KEYPOINTS_0      = 14'b00000010000000;    // 0080
    localparam ST_FETCH_CELL_KEYPOINTS_1      = 14'b00000100000000;    // 0100
    localparam ST_WAIT_CELL_KEYPOINTS_LOAD_0  = 14'b00001000000000;    // 0200
    localparam ST_WAIT_CELL_KEYPOINTS_LOAD_1  = 14'b00010000000000;    // 0400
    localparam ST_MONITOR_CELL_QUEUE          = 14'b00100000000000;    // 0800
    localparam ST_WAIT_WRITEBEACK             = 14'b01000000000000;    // 1000
    localparam ST_SEND_COMPLETION             = 14'b10000000000000;    // 2000

    localparam ST_WAIT_INIT_LOAD              = 3'b001;
    localparam ST_WAIT_FOR_HEADER             = 3'b010;
    localparam ST_CONSUME_DESC                = 3'b100;

    localparam C_NUM_OBSERVED_KEYPOINTS_INVD_FETCH  = 16'd2;
    localparam C_NUM_OBSERVED_KEYPOINTS_FETCH       = C_NUM_OBSERVED_KEYPOINTS_INVD_FETCH * `NUM_ENGINES;
    localparam C_CELL_KP_CHUNK_SIZE                 = (`DESCRIPTOR_INPUT_HEADER_WIDTH / `BITS_PER_BYTE + `NUM_ELEMENTS_PER_DESCRIPTOR * `BYTE_PER_ELEMENT) * C_NUM_OBSERVED_KEYPOINTS_FETCH;
    localparam C_DISPATCH_UNIT_DATAIN_WIDTH         = `DATAIN_WIDTH + `DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH;
    localparam C_SEC_DESC_BUF_LOAD_CNT              = `NUM_ENGINES * 16;
    
 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Ouputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                       clk;
    input                       rst;
    // SAP Master Command Interface (Unused)
	output                      model_master_request;
	input                       model_master_request_ack;
	input                       model_master_request_complete;
    input       [6 :0]          model_master_request_error;
    input       [3 :0]          model_master_request_tag;
    output      [3  :0]         model_master_request_option;
    output      [3  :0]         model_master_request_type;
    output      [9  :0]         model_master_request_flow;
    output      [63 :0]         model_master_request_local_address;
	output  [35 :0]         model_master_request_length;
    // SAP Master Descriptor Interface (Unused)
    output                      model_master_descriptor_src_rdy;
    input                       model_master_descriptor_dst_rdy;
    input       [3  :0]         model_master_descriptor_tag;
    output      [127:0]         model_master_descriptor;
    // SAP Master Data Interface (Unused
    input                       model_master_datain_src_rdy;
    output     reg              model_master_datain_dst_rdy;
    input      [3 :0]           model_master_datain_tag;
    input      [3  :0]          model_master_datain_option;
    input      [127:0]          model_master_datain;

	output                      model_master_dataout_src_rdy;
	input                       model_master_dataout_dst_rdy;
    input       [3 :0]          model_master_dataout_tag;
    input       [3  :0]         model_master_dataout_option;
    output reg  [127:0]         model_master_dataout;
    
    // SAP Master Command Interface (Unused)
	output                      cell_master_request;
	input                       cell_master_request_ack;
	input                       cell_master_request_complete;
    input       [6 :0]          cell_master_request_error;
    input       [3 :0]          cell_master_request_tag;
    output      [3  :0]         cell_master_request_option;
    output      [3  :0]         cell_master_request_type;
    output      [9  :0]         cell_master_request_flow;
    output      [63 :0]         cell_master_request_local_address;
 	output      [35 :0]         cell_master_request_length;
    // SAP Master Descriptor Interface (Unused)
    output                      cell_master_descriptor_src_rdy;
    input                       cell_master_descriptor_dst_rdy;
    input       [3  :0]         cell_master_descriptor_tag;
    output      [127:0]         cell_master_descriptor;
    // SAP Master Data Interface (Unused
    input                       cell_master_datain_src_rdy;
    output  reg                    cell_master_datain_dst_rdy;
    input      [3 :0]           cell_master_datain_tag;
    input      [3  :0]          cell_master_datain_option;
    input      [127:0]          cell_master_datain;

	output                      cell_master_dataout_src_rdy;
	input                       cell_master_dataout_dst_rdy;
    input       [3 :0]          cell_master_dataout_tag;
    input       [3  :0]         cell_master_dataout_option;
    output reg  [127:0]         cell_master_dataout;

    output                                              send_msg_request;
    input                                               send_msg_ack;
    input                                               send_msg_complete;
    input       [                             1  :0]    send_msg_error;
    output                                              send_msg_src_rdy;
    input                                               send_msg_dst_rdy;
    output      [                             127:0]    send_msg_payload;

    input                                               recv_msg_request;
    output                                              recv_msg_ack;
    input                                               recv_msg_src_rdy;
    output                                              recv_msg_dst_rdy;
    input       [                             127:0]    recv_msg_payload;

    output      [     C_SEC_DESC_BUF_LOAD_CNT - 1:0]    i_secondary_descriptor_buffer_load_count;
    input       [                `NUM_ENGINES - 1:0]    i_secondary_descriptor_buffer_depleted;
    input       [                `NUM_ENGINES - 1:0]    i_secondary_descriptor_buffer_space_available;

    output reg                                          secondary_descriptor_buffer_load_init;
    output reg                                          primary_descriptor_buffer_load_init;

    output reg                                          init_keypoint_engine;

    output                                              dispatch_unit_datain_valid;
    output      [C_DISPATCH_UNIT_DATAIN_WIDTH - 1:0]    dispatch_unit_datain;
    output reg                                          dispatch_unit_begin_load_fifo;
    output reg  [                               1:0]    dispatch_unit_descriptor_buffer_select;
    output reg  [                              15:0]    dispatch_unit_total_keypoint_load_count;
    input                                               dispatch_unit_done_buffer_load;

	output      [                              15:0]    num_model_kp;
    output      [         (16 * `NUM_ENGINES) - 1:0]    i_num_obsvd_kp;
    input       [                `NUM_ENGINES - 1:0]    i_match_table_processing_complete;
    output      [         (64 * `NUM_ENGINES) - 1:0]    i_match_table_info_address;
    output      [         (64 * `NUM_ENGINES) - 1:0]    i_match_table_address;
    output      [         (36 * `NUM_ENGINES) - 1:0]    i_match_table_length;
    output                                              force_rst;
    output                                              last_cell_kp_batch;
   

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    reg  [                                         7:0]     completion_type;
    reg  [                                         9:0]     completion_length;
    reg  [                                        15:0]     completion_target;
    reg  [                                         9:0]     completion_id;
    reg  [                                         6:0]     completion_error;
    wire                                                    completion_valid;
    wire                                                    completion_complete;
    reg  [                                       127:0]     completion_data;
    wire                                                    completion_data_valid;
    wire                                                    completion_data_ready;

	reg  [                                        13:0]     state;
	reg  [                                         2:0]     fsm;

    reg                                                     modelData_initialize;   
    reg [                                         3:0]      modelData_initialize_request_type;
    reg [                                         63:0]     modelData_initialize_address;                    
    reg [                                         35:0]     modelData_initialize_length; 
    reg                                                     modelData_initialize_complete;
    reg                                                     modelData_transactor_request;                                   
    reg                                                     modelData_transactor_enable;                     
    reg [                                          3:0]     modelData_transactor_request_option;             
	wire                                                    modelData_transactor_active; 
	wire                                                    modelData_transaction_request_complete;
	wire                                                    modelData_transactor_request_busy;
  
    reg                                                     cellData_initialize;  
    reg [                                          3:0]     cellData_initialize_request_type;    
    reg [                                         63:0]     cellData_initialize_address;                     
    reg [                                         35:0]     cellData_initialize_length; 
    reg                                                     cellData_initialize_complete;    
    reg                                                     cellData_transactor_request;                                   
    reg                                                     cellData_transactor_enable;                      
    reg [                                          3:0]     cellData_transactor_request_option;    
	wire                                                    cellData_transactor_active; 
	wire                                                    cellData_transaction_request_complete;
    wire                                                    cellData_transactor_param_complete;
	wire                                                    cellData_transactor_request_busy;
    wire                                                    cell_keypoints_fetch_ready;                      
   
    wire [                                         7:0]     command_type;
    wire [                                         9:0]     command_length;
    wire [                                        15:0]     command_initiator;
    wire                                                    command_valid;
    reg                                                     command_data_advance;
    wire [                                         9:0]     command_id;
    wire [                                       127:0]     command_data;
    wire                                                    command_data_valid;
    wire                                                    command_data_ready;

    reg  [                  (`NUM_ENGINES * 128) - 1:0]     command_data_buffer;
    reg  [                                       127:0]     command_data_buffer_2;
    reg  [                                       127:0]     command_data_buffer_1;
    reg  [                                       127:0]     command_data_buffer_0;
    reg  [                                        15:0]     load_message_counter;
    reg  [                                        15:0]     keypoint_data_load_count;
    reg  [       clog2(`NUM_ELEMENTS_PER_DESCRIPTOR):0]     descriptor_count;
    reg  [                   (16 * `NUM_ENGINES) - 1:0]     i_num_obsvd_kp_residual;
    reg  [                                        15:0]     num_obsvd_kp_residual;

    reg  [`DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH - 1:0]     cell_id;
    
    reg  [               C_SEC_DESC_BUF_LOAD_CNT - 1:0]     i_secondary_descriptor_buffer_load_count_r;

    reg                                                     dispatch_unit_done_buffer_load_r;
    reg                                                     dispatch_unit_done_buffer_load_r_model_reset;
    reg                                                     dispatch_unit_done_buffer_load_r_obsvd_reset;
    reg  [                                        15:0]     dispatch_unit_total_keypoint_load_count_r;


    reg                                                     match_table_processing_complete_r_reset;
    reg   [                         `NUM_ENGINES - 1:0]     i_match_table_processing_complete_r;

    integer                                                 idx0;
    integer                                                 idx1;
    integer                                                 idx2;
    integer                                                 idx4;
    integer                                                 idx5;
    
    reg                                                     force_rst_r;
    genvar                                                  i;
    wire [                                         31:0]    num_cells;
    wire [15:0]                                             observed_kp_count;
    wire [63:0]                                             modelData_address; 
    wire [31:0]                                             modelData_length;
    wire [63:0]                                             cellData_address;
    wire [31:0]                                             cellData_length; 
    

    
    //wire                                                    performance_counter_start;
    //wire                                                    performance_counter_stop;
`ifdef EXOSTIV
	// output                      model_master_request_exstv;                                                                        
	// output                       model_master_request_ack_exstv;
	// output                       model_master_request_complete_exstv;
    // output       [6 :0]          model_master_request_error_exstv;
    // output       [3 :0]          model_master_request_tag_exstv;
    // output      [3  :0]         model_master_request_option_exstv;
    // output      [3  :0]         model_master_request_type_exstv;
    // output      [9  :0]         model_master_request_flow_exstv;
    // output                      model_master_descriptor_src_rdy_exstv;
    // output                       model_master_descriptor_dst_rdy_exstv;
    // output       [3  :0]         model_master_descriptor_tag_exstv;
    // output                       model_master_datain_src_rdy_exstv;
    // output                      model_master_datain_dst_rdy_exstv;
    // output      [3 :0]           model_master_datain_tag_exstv;
    // output      [3  :0]          model_master_datain_option_exstv;
	// output                      cell_master_request_exstv;
	// output                       cell_master_request_ack_exstv;
	// output                       cell_master_request_complete_exstv;
    // output       [6 :0]          cell_master_request_error_exstv;
    // output       [3 :0]          cell_master_request_tag_exstv;
    // output      [3  :0]         cell_master_request_option_exstv;
    // output      [3  :0]         cell_master_request_type_exstv;
    // output      [9  :0]         cell_master_request_flow_exstv;
    // output                      cell_master_descriptor_src_rdy_exstv;
    // output                       cell_master_descriptor_dst_rdy_exstv;
    // output       [3  :0]         cell_master_descriptor_tag_exstv;
    // output                       cell_master_datain_src_rdy_exstv;
    // output                    cell_master_datain_dst_rdy_exstv;
    // output      [3 :0]           cell_master_datain_tag_exstv;
    // output      [3  :0]          cell_master_datain_option_exstv;
    // output      [     C_SEC_DESC_BUF_LOAD_CNT - 1:0]    i_secondary_descriptor_buffer_load_count_exstv;
    // output       [                `NUM_ENGINES - 1:0]    i_secondary_descriptor_buffer_depleted_exstv;
    // output       [                `NUM_ENGINES - 1:0]    i_secondary_descriptor_buffer_space_available_exstv;
    // output                                          secondary_descriptor_buffer_load_init_exstv;
    // output                                          primary_descriptor_buffer_load_init_exstv;
    // output                                          init_keypoint_engine_exstv;
    // output                                              dispatch_unit_datain_valid_exstv;
    // output                                          dispatch_unit_begin_load_fifo_exstv;
    // output  [                               1:0]    dispatch_unit_descriptor_buffer_select_exstv;
    // output  [                              15:0]    dispatch_unit_total_keypoint_load_count_exstv;
    // output                                               dispatch_unit_done_buffer_load_exstv;
	// output      [                              15:0]    num_model_kp_exstv;
    // output      [         (16 * `NUM_ENGINES) - 1:0]    i_num_obsvd_kp_exstv;
    // output       [                `NUM_ENGINES - 1:0]    i_match_table_processing_complete_exstv;
    // output                                              force_rst_exstv;
    // output                                              last_cell_kp_batch_exstv;
	output  [                                        13:0]     state_exstv;
	output  [                                         2:0]     fsm_exstv;
    // output                                                     modelData_initialize_exstv;   
    // output [                                         3:0]      modelData_initialize_request_type_exstv;
    // output                                                     modelData_initialize_complete_exstv;
    // output                                                     modelData_transactor_request_exstv;                                   
    // output                                                     modelData_transactor_enable_exstv;                     
    // output [                                          3:0]     modelData_transactor_request_option_exstv;             
	// output                                                    modelData_transactor_active_exstv; 
	// output                                                    modelData_transaction_request_complete_exstv;
	// output                                                    modelData_transactor_request_busy_exstv; 
    // output                                                     cellData_initialize_exstv;  
    // output [                                          3:0]     cellData_initialize_request_type_exstv;    
    // output                                                     cellData_initialize_complete_exstv;    
    // output                                                     cellData_transactor_request_exstv;                                   
    // output                                                     cellData_transactor_enable_exstv;                      
    // output [                                          3:0]     cellData_transactor_request_option_exstv;    
	// output                                                    cellData_transactor_active_exstv; 
	// output                                                    cellData_transaction_request_complete_exstv;
    // output                                                    cellData_transactor_param_complete_exstv;
	// output                                                    cellData_transactor_request_busy_exstv;
    // output                                                    cell_keypoints_fetch_ready_exstv;                        
    // output  [                                        15:0]     keypoint_data_load_count_exstv;
    // output  [       clog2(`NUM_ELEMENTS_PER_DESCRIPTOR):0]     descriptor_count_exstv;
    // output  [                   (16 * `NUM_ENGINES) - 1:0]     i_num_obsvd_kp_residual_exstv;
    // output  [                                        15:0]     num_obsvd_kp_residual_exstv;
    // output  [               C_SEC_DESC_BUF_LOAD_CNT - 1:0]     i_secondary_descriptor_buffer_load_count_r_exstv;
    // output                                                     dispatch_unit_done_buffer_load_r_exstv;
    // output                                                     dispatch_unit_done_buffer_load_r_model_reset_exstv;
    // output                                                     dispatch_unit_done_buffer_load_r_obsvd_reset_exstv;
    // output  [                                        15:0]     dispatch_unit_total_keypoint_load_count_r_exstv;
    // output                                                     match_table_processing_complete_r_reset_exstv;
    // output   [                         `NUM_ENGINES - 1:0]     i_match_table_processing_complete_r_exstv;
    
assign model_master_request_exstv =                               model_master_request;                                               
assign model_master_request_ack_exstv =                           model_master_request_ack;
assign model_master_request_complete_exstv =                      model_master_request_complete;
assign model_master_request_error_exstv =                         model_master_request_error;
assign model_master_request_tag_exstv =                           model_master_request_tag;
assign model_master_request_option_exstv =                        model_master_request_option;
assign model_master_request_type_exstv =                          model_master_request_type;
assign model_master_request_flow_exstv =                          model_master_request_flow;
assign model_master_descriptor_src_rdy_exstv =                    model_master_descriptor_src_rdy;
assign model_master_descriptor_dst_rdy_exstv =                    model_master_descriptor_dst_rdy;
assign model_master_descriptor_tag_exstv =                        model_master_descriptor_tag;
assign model_master_datain_src_rdy_exstv =                        model_master_datain_src_rdy;
assign model_master_datain_dst_rdy_exstv =                        model_master_datain_dst_rdy;
assign model_master_datain_tag_exstv =                            model_master_datain_tag;
assign model_master_datain_option_exstv =                         model_master_datain_option;
assign cell_master_request_exstv =                                cell_master_request;
assign cell_master_request_ack_exstv =                            cell_master_request_ack;
assign cell_master_request_complete_exstv =                       cell_master_request_complete;
assign cell_master_request_error_exstv =                          cell_master_request_error;
assign cell_master_request_tag_exstv =                            cell_master_request_tag;
assign cell_master_request_option_exstv =                         cell_master_request_option;
assign cell_master_request_type_exstv =                           cell_master_request_type;
assign cell_master_request_flow_exstv =                           cell_master_request_flow;
assign cell_master_descriptor_src_rdy_exstv =                     cell_master_descriptor_src_rdy;
assign cell_master_descriptor_dst_rdy_exstv =                     cell_master_descriptor_dst_rdy;
assign cell_master_descriptor_tag_exstv =                         cell_master_descriptor_tag;
assign cell_master_datain_src_rdy_exstv =                         cell_master_datain_src_rdy;
assign cell_master_datain_dst_rdy_exstv =                         cell_master_datain_dst_rdy;
assign cell_master_datain_tag_exstv =                             cell_master_datain_tag;
assign cell_master_datain_option_exstv =                          cell_master_datain_option;
assign i_secondary_descriptor_buffer_load_count_exstv =           i_secondary_descriptor_buffer_load_count;
assign i_secondary_descriptor_buffer_depleted_exstv =             i_secondary_descriptor_buffer_depleted;
assign i_secondary_descriptor_buffer_space_available_exstv =      i_secondary_descriptor_buffer_space_available;
assign secondary_descriptor_buffer_load_init_exstv =              secondary_descriptor_buffer_load_init;
assign primary_descriptor_buffer_load_init_exstv =                primary_descriptor_buffer_load_init;
assign init_keypoint_engine_exstv =                               init_keypoint_engine;
assign dispatch_unit_datain_valid_exstv =                         dispatch_unit_datain_valid;
assign dispatch_unit_begin_load_fifo_exstv =                      dispatch_unit_begin_load_fifo;
assign dispatch_unit_descriptor_buffer_select_exstv =             dispatch_unit_descriptor_buffer_select;
assign dispatch_unit_total_keypoint_load_count_exstv =            dispatch_unit_total_keypoint_load_count;
assign dispatch_unit_done_buffer_load_exstv =                     dispatch_unit_done_buffer_load;
assign num_model_kp_exstv =                                       num_model_kp;
assign i_num_obsvd_kp_exstv =                                     i_num_obsvd_kp;
assign i_match_table_processing_complete_exstv =                  i_match_table_processing_complete;
assign force_rst_exstv =                                          force_rst;
assign last_cell_kp_batch_exstv =                                 last_cell_kp_batch;
assign state_exstv =                                              state;
assign fsm_exstv =                                                fsm;
assign modelData_initialize_exstv =                               modelData_initialize;   
assign modelData_initialize_request_type_exstv =                  modelData_initialize_request_type;
assign modelData_initialize_complete_exstv =                      modelData_initialize_complete;
assign modelData_transactor_request_exstv =                       modelData_transactor_request;                               
assign modelData_transactor_enable_exstv =                        modelData_transactor_enable;                    
assign modelData_transactor_request_option_exstv =                modelData_transactor_request_option;            
assign modelData_transactor_active_exstv =                        modelData_transactor_active; 
assign modelData_transaction_request_complete_exstv =             modelData_transaction_request_complete;
assign modelData_transactor_request_busy_exstv =                  modelData_transactor_request_busy; 
assign cellData_initialize_exstv =                                cellData_initialize;  
assign cellData_initialize_request_type_exstv =                   cellData_initialize_request_type;    
assign cellData_initialize_complete_exstv =                       cellData_initialize_complete;    
assign cellData_transactor_request_exstv =                        cellData_transactor_request;                               
assign cellData_transactor_enable_exstv =                         cellData_transactor_enable;                     
assign cellData_transactor_request_option_exstv =                 cellData_transactor_request_option;    
assign cellData_transactor_active_exstv =                         cellData_transactor_active; 
assign cellData_transaction_request_complete_exstv =              cellData_transaction_request_complete;
assign cellData_transactor_param_complete_exstv =                 cellData_transactor_param_complete;
assign cellData_transactor_request_busy_exstv =                   cellData_transactor_request_busy;
assign cell_keypoints_fetch_ready_exstv =                         cell_keypoints_fetch_ready;                     
assign keypoint_data_load_count_exstv =                           keypoint_data_load_count;
assign descriptor_count_exstv =                                   descriptor_count;
assign i_num_obsvd_kp_residual_exstv =                            i_num_obsvd_kp_residual;
assign num_obsvd_kp_residual_exstv =                              num_obsvd_kp_residual;
assign i_secondary_descriptor_buffer_load_count_r_exstv =         i_secondary_descriptor_buffer_load_count_r;
assign dispatch_unit_done_buffer_load_r_exstv =                   dispatch_unit_done_buffer_load_r;
assign dispatch_unit_done_buffer_load_r_model_reset_exstv =       dispatch_unit_done_buffer_load_r_model_reset;
assign dispatch_unit_done_buffer_load_r_obsvd_reset_exstv =       dispatch_unit_done_buffer_load_r_obsvd_reset;
assign dispatch_unit_total_keypoint_load_count_r_exstv =          dispatch_unit_total_keypoint_load_count_r;
assign match_table_processing_complete_r_reset_exstv =            match_table_processing_complete_r_reset;
assign i_match_table_processing_complete_r_exstv =                i_match_table_processing_complete_r;

    
`endif   
    
    

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instantiations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------  
    sap_receive_message_queue
    i0_receive_message_queue (
        .clk                ( clk                  ) ,
        .rst                ( rst                  ) ,

        .recv_msg_request   ( recv_msg_request     ) ,
        .recv_msg_ack       ( recv_msg_ack         ) ,
        .recv_msg_complete  (                      ) ,
        .recv_msg_error     (                      ) ,
        .recv_msg_src_rdy   ( recv_msg_src_rdy     ) ,
        .recv_msg_dst_rdy   ( recv_msg_dst_rdy     ) ,
        .recv_msg_payload   ( recv_msg_payload     ) ,

        .request_type       ( command_type         ) ,
        .request_length     ( command_length       ) ,
        .request_initiator  ( command_initiator    ) ,
        .request_valid      ( command_valid        ) ,
        .request_advance    ( command_data_advance ) ,
        .request_id         ( command_id           ) ,
        .request_data       ( command_data         ) ,
        .request_data_valid ( command_data_valid   ) ,
        .request_data_ready ( command_data_ready   )
    );


    sap_send_message_queue
    i0_send_message_queue (
        .clk                ( clk                   ) ,
        .rst                ( rst                   ) ,

        .send_msg_request   ( send_msg_request      ) ,
        .send_msg_ack       ( send_msg_ack          ) ,
        .send_msg_complete  ( send_msg_complete     ) ,
        .send_msg_error     ( send_msg_error        ) ,
        .send_msg_src_rdy   ( send_msg_src_rdy      ) ,
        .send_msg_dst_rdy   ( send_msg_dst_rdy      ) ,
        .send_msg_payload   ( send_msg_payload      ) ,

        .request_type       ( completion_type       ) ,
        .request_length     ( completion_length     ) ,
        .request_target     ( completion_target     ) ,
        .request_valid      ( completion_valid      ) ,
        .request_complete   ( completion_complete   ) ,
        .request_id         ( completion_id         ) ,
        .request_error      ( completion_error      ) ,
        .request_data       ( completion_data       ) ,
        .request_data_valid ( completion_data_valid ) ,
        .request_data_ready ( completion_data_ready )
    );

    
    master_transactor
    i0_model_data_master_transactor (
        .master_clk                        ( clk                                          ),
        .master_rst                        ( rst                                          ),
        .master_request                    ( model_master_request                         ),
        .master_request_ack                ( model_master_request_ack                     ),
        .master_request_complete           ( model_master_request_complete                ),
        .master_request_option             ( model_master_request_option                  ),
        .master_request_error              ( model_master_request_error                   ),
        .master_request_tag                ( model_master_request_tag                     ),
        .master_request_type               ( model_master_request_type                    ),
        .master_request_flow               ( model_master_request_flow                    ),
        .master_request_local_address      ( model_master_request_local_address           ),
        .master_request_length             ( model_master_request_length                  ),
        .master_descriptor_src_rdy         ( model_master_descriptor_src_rdy              ),
        .master_descriptor_dst_rdy         ( model_master_descriptor_dst_rdy              ),
        .master_descriptor_tag             ( model_master_descriptor_tag                  ),
        .master_descriptor                 ( model_master_descriptor                      ),
        .master_datain_src_rdy             ( model_master_datain_src_rdy                  ),
        .master_datain_dst_rdy             ( model_master_datain_dst_rdy                  ),
        .master_datain_tag                 ( model_master_datain_tag                      ),
        .master_dataout_src_rdy            ( model_master_dataout_src_rdy                 ),
        .master_dataout_dst_rdy            ( model_master_dataout_dst_rdy                 ),
        .master_dataout_tag                ( model_master_dataout_tag                     ),
        .initialize                        ( modelData_initialize                         ),
        .intiialize_request_type           ( modelData_initialize_request_type            ),
        .initialize_address                ( modelData_initialize_address                 ),
        .initialize_length                 ( modelData_initialize_length                  ),
        .initialize_complete               ( modelData_initialize_complete                ),
        .transactor_request                ( modelData_transactor_request                 ),  
        .transactor_enable                 ( modelData_transactor_enable                  ),  
        .transactor_request_option         ( modelData_transactor_request_option          ),
        .transactor_request_busy           ( modelData_transactor_request_busy            ),
        .transactor_active                 ( modelData_transactor_active                  ),
        .transaction_request_complete      ( modelData_transaction_request_complete       ),
        .transactor_param_complete         (                                              ),
        .transactor_reset                  ( 1'b0                                         ),
        .use_provided_param                ( 1'b0                                         ), 
        .provided_parameters_length        (                                              ),
        .provided_request_option           (                                              ),
        .provided_request_type_r           (                                              ),
        .provided_parameters_address       (                                              )
    );
    
    
    master_transactor #(
        .C_BURST_MODE_ENABLED   (                    1 ), 
        .C_BURST_SIZE_BYTES     ( C_CELL_KP_CHUNK_SIZE )
    ) i0_cell_data_master_transactor (
        .master_clk                        ( clk                                        ),
        .master_rst                        ( rst                                        ),
        .master_request                    ( cell_master_request                        ),
        .master_request_ack                ( cell_master_request_ack                    ),
        .master_request_complete           ( cell_master_request_complete               ),
        .master_request_option             ( cell_master_request_option                 ),
        .master_request_error              ( cell_master_request_error                  ),
        .master_request_tag                ( cell_master_request_tag                    ),
        .master_request_type               ( cell_master_request_type                   ),
        .master_request_flow               ( cell_master_request_flow                   ),
        .master_request_local_address      ( cell_master_request_local_address          ),
        .master_request_length             ( cell_master_request_length                 ),
        .master_descriptor_src_rdy         ( cell_master_descriptor_src_rdy             ),
        .master_descriptor_dst_rdy         ( cell_master_descriptor_dst_rdy             ),
        .master_descriptor_tag             ( cell_master_descriptor_tag                 ),
        .master_descriptor                 ( cell_master_descriptor                     ),
        .master_datain_src_rdy             ( cell_master_datain_src_rdy                 ),
        .master_datain_dst_rdy             ( cell_master_datain_dst_rdy                 ),
        .master_datain_tag                 ( cell_master_datain_tag                     ),
        .master_dataout_src_rdy            ( cell_master_dataout_src_rdy                ),
        .master_dataout_dst_rdy            ( cell_master_dataout_dst_rdy                ),
        .master_dataout_tag                ( cell_master_dataout_tag                    ),
        .initialize                        ( cellData_initialize                        ),
        .intiialize_request_type           ( cellData_initialize_request_type           ),
        .initialize_address                ( cellData_initialize_address                ),
        .initialize_length                 ( cellData_initialize_length                 ),
        .initialize_complete               ( cellData_initialize_complete               ),
        .transactor_request                ( cellData_transactor_request                ), 
        .transactor_enable                 ( cellData_transactor_enable                 ),  
        .transactor_request_option         ( cellData_transactor_request_option         ),
        .transactor_request_busy           ( cellData_transactor_request_busy           ),
        .transactor_active                 ( cellData_transactor_active                 ),
        .transaction_request_complete      ( cellData_transaction_request_complete      ),
        .transactor_param_complete         ( cellData_transactor_param_complete         ),
        .transactor_reset                  ( 1'b0                                       ),
        .use_provided_param                ( 1'b0                                       ), 
        .provided_parameters_length        (                                            ),
        .provided_request_option           (                                            ),
        .provided_request_type_r           (                                            ),
        .provided_parameters_address       (                                            )
    );


    // BEGIN Get Command Data logic -----------------------------------------------------------------------------------------------------------------
    always@(posedge clk) begin
        if(rst) begin
            command_data_buffer_0 <= {`DATAIN_WIDTH{1'b0}};
            command_data_buffer_1 <= {`DATAIN_WIDTH{1'b0}};
            command_data_buffer_2 <= {`DATAIN_WIDTH{1'b0}};
            for(idx0 = 0; idx0 < `NUM_ENGINES; idx0 = idx0 + 1) begin
                command_data_buffer[(idx0 * 128) +: 128] <= {`DATAIN_WIDTH{1'b0}};
            end
            load_message_counter  <= 16'b0;     
        end else begin
            if(state == ST_LOAD_MESSAGE) begin
                load_message_counter      <= load_message_counter + 1;      
                if(load_message_counter == 1) begin
                    command_data_buffer_0   <= command_data;        
                end else if(load_message_counter == 2) begin
                    command_data_buffer_1   <= command_data;        
                end else if(load_message_counter == 3) begin
                    command_data_buffer_2   <= command_data;
                end
                if(load_message_counter == 4 && `NUM_ENGINES == 1) begin
                    load_message_counter <= 0;
                    command_data_buffer  <= command_data;
                end else  begin
                    for(idx1 = 0; idx1 < `NUM_ENGINES; idx1 = idx1 + 1) begin
                        if((load_message_counter - 4) == idx1) begin
                            command_data_buffer[(idx1 * 128) +: 128] <= command_data;
                        end
                    end
                    if(load_message_counter == (3 + `NUM_ENGINES)) begin
                        load_message_counter <= 0;
                    end
                end
            end
        end
    end
    
    generate 
        for(i = 0; i < `NUM_ENGINES; i = i + 1) begin
            assign i_match_table_address[(i * 64) +: 64]        = command_data_buffer[(i * 128) +: `I_CMD_DATA_MATCH_TABLE_ADDR_WIDTH];
            assign i_num_obsvd_kp[(i * 16) +: 16]               = command_data_buffer[((i * 128) + `I_CMD_DATA_MATCH_TABLE_ADDR_WIDTH) +: `I_CMD_DATA_OBSERVED_KP_COUNT_WIDTH];
            assign i_match_table_length[(i * 36) +: 36]         = {4'b0, command_data_buffer[((i * 128) + `I_CMD_DATA_MATCH_TABLE_ADDR_WIDTH + `I_CMD_DATA_OBSERVED_KP_COUNT_WIDTH) +: `I_CMD_DATA_MATCH_TABLE_LENGTH_WIDTH]};
            if(i > 0) begin
                assign i_match_table_info_address[(i * 64) +: 64]   = 64'b0;
            end
        end
    endgenerate
    // END Get Command Data logic -------------------------------------------------------------------------------------------------------------------

    
    // BEGIN Dispatch Unit logic ------------------------------------------------------------------------------------------------------------------ 
    assign dispatch_unit_datain         = (cell_master_datain_dst_rdy && cell_master_datain_src_rdy) ? {cell_id, cell_master_datain} : {16'hFFFF, model_master_datain};
    assign dispatch_unit_datain_valid   = ((model_master_datain_dst_rdy && model_master_datain_src_rdy) || (cell_master_datain_dst_rdy && cell_master_datain_src_rdy)) && (fsm == ST_CONSUME_DESC);
    
    always@(posedge clk) begin
        if(rst) begin
            descriptor_count            <= 0;
            keypoint_data_load_count    <= 0;
            fsm                         <= ST_WAIT_INIT_LOAD;
            cell_id                     <= 0;
        end else begin
            case(fsm)
                ST_WAIT_INIT_LOAD: begin
                    if(dispatch_unit_begin_load_fifo) begin
                        fsm                         <= ST_WAIT_FOR_HEADER;
                        descriptor_count            <= `NUM_ELEMENTS_PER_DESCRIPTOR;
                        keypoint_data_load_count    <= dispatch_unit_total_keypoint_load_count;
                    end
                end
                ST_WAIT_FOR_HEADER: begin
                    if((model_master_datain_dst_rdy && model_master_datain_src_rdy) || (cell_master_datain_dst_rdy && cell_master_datain_src_rdy)) begin
                        fsm         <= ST_CONSUME_DESC;
                        cell_id     <= cell_master_datain[`DESCRIPTOR_INPUT_HEADER_CELL_ID_FIELD];
                    end
                end
                ST_CONSUME_DESC: begin
                    if((model_master_datain_dst_rdy && model_master_datain_src_rdy) || (cell_master_datain_dst_rdy && cell_master_datain_src_rdy)) begin
                        descriptor_count <= descriptor_count - `NUM_DESC_PER_BUS;
                        if(descriptor_count == `NUM_DESC_PER_BUS) begin
                            keypoint_data_load_count <= keypoint_data_load_count - 1;
                            if(keypoint_data_load_count == 1) begin
                                fsm                 <= ST_WAIT_INIT_LOAD;
                            end else begin
                                descriptor_count    <= `NUM_ELEMENTS_PER_DESCRIPTOR;
                                fsm                 <= ST_WAIT_FOR_HEADER;
                            end
                        end
                    end
                end
                default: begin
                
                end
            endcase 
        end
    end
 
    always@(posedge clk) begin
        if(rst) begin
            dispatch_unit_done_buffer_load_r <= 0;
        end else begin
            if(dispatch_unit_done_buffer_load) begin
                dispatch_unit_done_buffer_load_r <= 1;
            end
            if(dispatch_unit_done_buffer_load_r_obsvd_reset || dispatch_unit_done_buffer_load_r_model_reset) begin
                dispatch_unit_done_buffer_load_r <= 0;
            end
        end
    end
    // END Keypoint header logic --------------------------------------------------------------------------------------------------------------------
 
 
    // BEGIN Keypoint counter logic -----------------------------------------------------------------------------------------------------------------
    always@(posedge clk) begin
        if(rst) begin
            num_obsvd_kp_residual <= 16'b0;
        end else begin
            if(state == ST_INITIALIZE_DATAPATH) begin
                num_obsvd_kp_residual <= command_data_buffer_2[`CMD_DATA_OBSERVED_KP_COUNT_FIELD];
            end
            if(dispatch_unit_done_buffer_load_r_obsvd_reset) begin
                num_obsvd_kp_residual <= num_obsvd_kp_residual - dispatch_unit_total_keypoint_load_count_r;
            end
        end
    end
    
    generate
        for(i = 0; i < `NUM_ENGINES; i = i + 1) begin
            assign i_secondary_descriptor_buffer_load_count[(i * 16) +: 16] = i_secondary_descriptor_buffer_load_count_r[(i * 16) +: 16];
        end
    endgenerate
    
    always@(posedge clk) begin
        if(rst) begin
            i_secondary_descriptor_buffer_load_count_r <= 0;
        end else begin
            if(state == ST_INITIALIZE_DATAPATH) begin
                for(idx5 = 0; idx5 < `NUM_ENGINES; idx5 = idx5 + 1) begin
                    i_num_obsvd_kp_residual[(idx5 * 16) +: 16] <= command_data_buffer[((idx5 * 128) + `I_CMD_DATA_MATCH_TABLE_ADDR_WIDTH) +: `I_CMD_DATA_OBSERVED_KP_COUNT_WIDTH];
                end
            end     
            for(idx4 = 0; idx4 < `NUM_ENGINES; idx4 = idx4 + 1) begin
                if(dispatch_unit_begin_load_fifo && dispatch_unit_descriptor_buffer_select[`SEC_BUFFER_SELECT_IDX]) begin
                    i_secondary_descriptor_buffer_load_count_r[(idx4 * 16) +: 16] <= (i_num_obsvd_kp_residual[(idx4 * 16) +: 16] > C_NUM_OBSERVED_KEYPOINTS_INVD_FETCH) ?  C_NUM_OBSERVED_KEYPOINTS_INVD_FETCH : i_num_obsvd_kp_residual[(idx4 * 16) +: 16];
                end
                if(dispatch_unit_done_buffer_load_r_obsvd_reset) begin
                    i_num_obsvd_kp_residual[(idx4 * 16) +: 16] <= i_num_obsvd_kp_residual[(idx4 * 16) +: 16] - i_secondary_descriptor_buffer_load_count_r[(idx4 * 16) +: 16];
                end
            end
        end
    end
    // END Keypoint counter logic --------------------------------------------------------------------------------------------------------------------

    
    // BEGIN Main State Machine State Logic ----------------------------------------------------------------------------------------------  
    assign command_data_ready                           = (state == ST_IDLE) && command_valid;  
    assign i_match_table_info_address[(0 * 64) +: 64]   = command_data_buffer_1[`CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD];
    assign cell_keypoints_fetch_ready                   = ~cellData_transactor_param_complete && &i_secondary_descriptor_buffer_space_available && !cellData_transactor_request_busy;
    assign num_model_kp                                 = command_data_buffer_2[`CMD_DATA_MODEL_KP_COUNT_FIELD];
    assign completion_valid                             = (state == ST_SEND_COMPLETION) ? 1 : 0;
    assign completion_data_valid                        = (state == ST_SEND_COMPLETION) ? 1 : 0; 
    assign force_rst                                    = force_rst_r;
    assign last_cell_kp_batch                           = (state == ST_WAIT_WRITEBEACK) && cellData_transactor_param_complete;
    assign model_master_dataout_src_rdy                 = 0;
    assign cell_master_dataout_src_rdy                  = 0;
    assign num_cells                                    = command_data_buffer_2[`CMD_DATA_NUM_CELLS_FIELD];
    assign observed_kp_count                            = command_data_buffer_2[`CMD_DATA_OBSERVED_KP_COUNT_FIELD];
    assign modelData_address                            = command_data_buffer_0[`CMD_DATA_MODEL_DATA_ADDR_FIELD];
    assign modelData_length                             = command_data_buffer_1[`CMD_DATA_MODEL_DATA_LENGTH_FIELD];
    assign cellData_address                             = command_data_buffer_0[`CMD_DATA_CELL_DATA_ADDR_FIELD];  
    assign cellData_length                              = command_data_buffer_1[`CMD_DATA_CELL_DATA_LENGTH_FIELD]; 

    always@(posedge clk) begin
        if(rst) begin
            i_match_table_processing_complete_r <= 0;
        end else begin
            for(idx2 = 0; idx2 < `NUM_ENGINES; idx2 = idx2 + 1) begin
                if(i_match_table_processing_complete[(idx2 * 1) +: 1]) begin
                    i_match_table_processing_complete_r[(idx2 * 1) +: 1] <= 1;
                end
            end   
            if(match_table_processing_complete_r_reset) begin
                i_match_table_processing_complete_r <= 0;
            end
        end   
    end
    
    always@(posedge clk) begin
        if(rst) begin       
            command_data_advance                            <= 0;
            secondary_descriptor_buffer_load_init           <= 0;
            primary_descriptor_buffer_load_init             <= 0;
            dispatch_unit_begin_load_fifo                   <= 0;   
            dispatch_unit_done_buffer_load_r_model_reset    <= 0;
            dispatch_unit_done_buffer_load_r_obsvd_reset    <= 0;
            match_table_processing_complete_r_reset         <= 0;
            model_master_dataout                            <= 0;
            model_master_datain_dst_rdy                     <= 0;
            cell_master_dataout                             <= 0;
            cell_master_datain_dst_rdy                      <= 0;
            modelData_initialize                            <= 0;     
            modelData_initialize_request_type               <= 0;
            modelData_initialize_address                    <= 64'b0;                    
            modelData_initialize_length                     <= 36'b0;  
            modelData_initialize_complete                   <= 0;
            modelData_transactor_request                    <= 0;                                
            modelData_transactor_enable                     <= 0;                  
            modelData_transactor_request_option             <= 0;           
            cellData_initialize                             <= 0;
            cellData_initialize_request_type                <= 0;
            cellData_initialize_address                     <= 64'b0;                    
            cellData_initialize_length                      <= 36'b0;                    
            cellData_transactor_request                     <= 0;                                
            cellData_transactor_enable                      <= 0;                  
            cellData_transactor_request_option              <= 0;  
            cellData_initialize_complete                    <= 0;
            dispatch_unit_descriptor_buffer_select          <= 0;
            dispatch_unit_total_keypoint_load_count         <= 0;
            completion_type                                 <= `SAP_MSG_TYPE_EXECUTE_COMPLETE;
            completion_length                               <= 32;
            completion_target                               <= 16'h0;
            completion_id                                   <= 0;
            completion_data                                 <= 128'h0;
            dispatch_unit_total_keypoint_load_count_r       <= 0;
            force_rst_r                                     <= 0;
            state                                           <= ST_IDLE;           
        end else begin        
            command_data_advance                            <= 0;
            secondary_descriptor_buffer_load_init           <= 0;
            dispatch_unit_begin_load_fifo                   <= 0;
            primary_descriptor_buffer_load_init             <= 0;
            init_keypoint_engine                            <= 0;
            dispatch_unit_done_buffer_load_r_model_reset    <= 0;
            dispatch_unit_done_buffer_load_r_obsvd_reset    <= 0;
            match_table_processing_complete_r_reset         <= 0;
            model_master_dataout                            <= 0;
            model_master_datain_dst_rdy                     <= 0;
            cell_master_dataout                             <= 0;
            cell_master_datain_dst_rdy                      <= 0;
            modelData_initialize                            <= 0;                                               
            modelData_initialize_address                    <= 64'b0;                    
            modelData_initialize_length                     <= 36'b0;                    
            modelData_transactor_request                    <= 0;                                
            modelData_transactor_enable                     <= 1;                  
            modelData_transactor_request_option             <= 0;           
            cellData_initialize                             <= 0;                                               
            cellData_initialize_address                     <= 64'b0;                    
            cellData_initialize_length                      <= 36'b0;                    
            cellData_transactor_request                     <= 0;                                
            cellData_transactor_enable                      <= 1;                  
            cellData_transactor_request_option              <= 0; 
            dispatch_unit_descriptor_buffer_select          <= 2'b0;
            dispatch_unit_total_keypoint_load_count         <= 64'd0;
            completion_type                                 <= `SAP_MSG_TYPE_EXECUTE_COMPLETE;
            completion_length                               <= 32;
            completion_target                               <= command_initiator;
            completion_id                                   <= command_id;
            force_rst_r                                     <= 0;
            case (state)
                ST_IDLE: begin          
                    if(command_data_valid) begin
                        if(command_type == `SAP_MSG_TYPE_EXECUTE_REQUEST) begin
                            command_data_advance     <= 1'b1;
                            state                    <= ST_LOAD_MESSAGE;
                        end else begin
                            completion_error         <= `NIF_ERRCODE_UNSUPPORTED_CMD;
                            completion_data          <= 128'h1;
                            state                    <= ST_SEND_COMPLETION;
                        end
                    end
                end
                ST_LOAD_MESSAGE: begin  
                    if(load_message_counter != (3 + `NUM_ENGINES)) begin
                        command_data_advance      <= 1'b1;
                        state             <= ST_LOAD_MESSAGE;
                    end else begin
                        state             <= ST_DECODE_MESSAGE;
                    end
                end
                ST_DECODE_MESSAGE: begin  
                    if(observed_kp_count != 0 && num_model_kp != 0 && num_cells <= `MAX_NUM_CELLS) begin
                        state               <= ST_INITIALIZE_DATAPATH;
                    end else begin
                        completion_error    <= `NIF_ERRCODE_UNSUPPORTED_CMD;
                        completion_data     <= 128'h2;
                        state               <= ST_SEND_COMPLETION;
                    end
                end
                ST_INITIALIZE_DATAPATH: begin
                    secondary_descriptor_buffer_load_init                               <= 1'b1;
                    primary_descriptor_buffer_load_init                                 <= 1'b1;
                    dispatch_unit_begin_load_fifo                                       <= 1'b1;
                    init_keypoint_engine                                                <= 1'b1;
                    modelData_initialize                                                <= 1;
                    modelData_initialize_request_type                                   <= `NIF_MASTER_CMD_RDREQ;
                    modelData_initialize_address                                        <= modelData_address;                    
                    modelData_initialize_length                                         <= modelData_length;                   
                    modelData_initialize_complete                                       <= 0;
                    cellData_initialize                                                 <= 1;  
                    cellData_initialize_request_type                                    <= `NIF_MASTER_CMD_RDREQ;
                    cellData_initialize_address                                         <= command_data_buffer_0[`CMD_DATA_CELL_DATA_ADDR_FIELD];                   
                    cellData_initialize_length                                          <= command_data_buffer_1[`CMD_DATA_CELL_DATA_LENGTH_FIELD];  
                    cellData_initialize_address                                         <= cellData_address;                     
                    cellData_initialize_length                                          <= cellData_length;      
                    cellData_initialize_complete                                        <= 0;
                    dispatch_unit_total_keypoint_load_count                             <= command_data_buffer_2[`CMD_DATA_MODEL_KP_COUNT_FIELD];
                    dispatch_unit_descriptor_buffer_select[`PRIM_BUFFER_SELECT_IDX]     <= 1;
                    state                                                               <= ST_FETCH_MODEL_KEYPOINTS_0;
                end
                ST_FETCH_MODEL_KEYPOINTS_0: begin
                    if(modelData_transactor_active) begin 
                        model_master_datain_dst_rdy         <= 1;
                        modelData_transactor_request        <= 1;
                        state                               <= ST_FETCH_MODEL_KEYPOINTS_1;
                    end
                end                
                ST_FETCH_MODEL_KEYPOINTS_1: begin
                    model_master_datain_dst_rdy             <= 1;
                    if(modelData_transaction_request_complete) begin
                        state                               <= ST_WAIT_MODEL_KEYPOINTS_LOAD;
                    end
                end
                ST_WAIT_MODEL_KEYPOINTS_LOAD: begin
                    if(dispatch_unit_done_buffer_load_r)begin
                        dispatch_unit_begin_load_fifo                                   <= 1'b1;
                        dispatch_unit_done_buffer_load_r_model_reset                    <= 1;
                        dispatch_unit_total_keypoint_load_count                         <= (num_obsvd_kp_residual > C_NUM_OBSERVED_KEYPOINTS_FETCH) ?  C_NUM_OBSERVED_KEYPOINTS_FETCH : num_obsvd_kp_residual;
                        dispatch_unit_total_keypoint_load_count_r                       <= (num_obsvd_kp_residual > C_NUM_OBSERVED_KEYPOINTS_FETCH) ?  C_NUM_OBSERVED_KEYPOINTS_FETCH : num_obsvd_kp_residual;
                        dispatch_unit_descriptor_buffer_select[`SEC_BUFFER_SELECT_IDX]  <= 1;   
                        state                                                           <= ST_FETCH_CELL_KEYPOINTS_0;
                    end
                end
                ST_FETCH_CELL_KEYPOINTS_0: begin
                    if(cellData_transactor_active) begin
                        cell_master_datain_dst_rdy      <= 1;
                        cellData_transactor_request     <= 1;
                        state                           <= ST_FETCH_CELL_KEYPOINTS_1;
                    end
                end               
                ST_FETCH_CELL_KEYPOINTS_1: begin
                    cell_master_datain_dst_rdy        <= 1;
                    if(cellData_transaction_request_complete) begin
                        state                           <= ST_WAIT_CELL_KEYPOINTS_LOAD_0;
                    end
                end
                ST_WAIT_CELL_KEYPOINTS_LOAD_0: begin
                    if(dispatch_unit_done_buffer_load_r) begin    
                        dispatch_unit_done_buffer_load_r_obsvd_reset    <= 1;
                        state                                           <= ST_WAIT_CELL_KEYPOINTS_LOAD_1;
                    end
                end              
                ST_WAIT_CELL_KEYPOINTS_LOAD_1: begin    // wait until correct num_obsvd_kp_residual is correct value after add
                    state                                               <= ST_MONITOR_CELL_QUEUE;
                end
                ST_MONITOR_CELL_QUEUE: begin
                    if(cell_keypoints_fetch_ready) begin
                        dispatch_unit_total_keypoint_load_count                             <= (num_obsvd_kp_residual > C_NUM_OBSERVED_KEYPOINTS_FETCH) ?  C_NUM_OBSERVED_KEYPOINTS_FETCH : num_obsvd_kp_residual;
                        dispatch_unit_total_keypoint_load_count_r                           <= (num_obsvd_kp_residual > C_NUM_OBSERVED_KEYPOINTS_FETCH) ?  C_NUM_OBSERVED_KEYPOINTS_FETCH : num_obsvd_kp_residual;
                        dispatch_unit_descriptor_buffer_select[`SEC_BUFFER_SELECT_IDX]      <= 1; 
                        dispatch_unit_begin_load_fifo                                       <= 1'b1;
                        state                                                               <= ST_FETCH_CELL_KEYPOINTS_0;
                    end else if(cellData_transactor_param_complete)begin
                        state                           <= ST_WAIT_WRITEBEACK;
                    end
                end
                ST_WAIT_WRITEBEACK: begin
                    if(&i_match_table_processing_complete_r && &i_secondary_descriptor_buffer_depleted) begin
                        match_table_processing_complete_r_reset     <= 1;
                        force_rst_r                                 <= 1;
                        completion_error                            <= `NIF_ERRCODE_NO_ERROR;
                        completion_data                             <= 128'h0;
                        state                                       <= ST_SEND_COMPLETION;
                    end
                end
                ST_SEND_COMPLETION: begin         
                    if(completion_complete) begin
                        state           <= ST_IDLE;
                    end
                end
                default: begin

                end
            endcase
        end
    end
 
 
 `ifdef SIMULATION
    // always@(posedge clk) begin
    //     if((state == ST_FETCH_CELL_KEYPOINTS_0 || state == ST_FETCH_CELL_KEYPOINTS_1) && !i_secondary_descriptor_buffer_space_available) begin
    //         $stop;
    //     end
    // end
    
  string state_s;
  string fsm_s;
  always@(state) begin 
    case(state) 
        ST_IDLE                        : state_s = "ST_IDLE";
        ST_LOAD_MESSAGE                : state_s = "ST_LOAD_MESSAGE";
        ST_DECODE_MESSAGE              : state_s = "ST_DECODE_MESSAGE";
        ST_INITIALIZE_DATAPATH         : state_s = "ST_INITIALIZE_DATAPATH";
        ST_FETCH_MODEL_KEYPOINTS_0     : state_s = "ST_FETCH_MODEL_KEYPOINTS_0";
        ST_FETCH_MODEL_KEYPOINTS_1     : state_s = "ST_FETCH_MODEL_KEYPOINTS_1";
        ST_WAIT_MODEL_KEYPOINTS_LOAD   : state_s = "ST_WAIT_MODEL_KEYPOINTS_LOAD";
        ST_FETCH_CELL_KEYPOINTS_0      : state_s = "ST_FETCH_CELL_KEYPOINTS_0";
        ST_FETCH_CELL_KEYPOINTS_1      : state_s = "ST_FETCH_CELL_KEYPOINTS_1";
        ST_WAIT_CELL_KEYPOINTS_LOAD_0  : state_s = "ST_WAIT_CELL_KEYPOINTS_LOAD_0";
        ST_WAIT_CELL_KEYPOINTS_LOAD_1  : state_s = "ST_WAIT_CELL_KEYPOINTS_LOAD_1";
        ST_MONITOR_CELL_QUEUE          : state_s = "ST_MONITOR_CELL_QUEUE";
        ST_WAIT_WRITEBEACK             : state_s = "ST_WAIT_WRITEBEACK";
        ST_SEND_COMPLETION             : state_s = "ST_SEND_COMPLETION";
    endcase
   end
   always@(fsm) begin 
    case(fsm) 
      ST_WAIT_INIT_LOAD  : fsm_s = "ST_WAIT_INIT_LOAD";
      ST_WAIT_FOR_HEADER : fsm_s = "ST_WAIT_FOR_HEADER";
      ST_CONSUME_DESC    : fsm_s = "ST_CONSUME_DESC";
    endcase
   end
   
   //integer fd;
   //initial begin
   // fd    = $fopen("debug_input.txt","w");
   //end
   //always@(posedge clk) begin
   // if(master_datain_dst_rdy && master_datain_src_rdy && state == ST_FETCH_CELL_KEYPOINTS_0)begin
   //     $fwrite(fd, "%H\n", dispatch_unit_datain[127:0]);
   //     $fflush(fd);
   // end
   //end
   
 `endif

`ifdef DEBUG

(* mark_debug = "true" *) reg [13:0] state_dr;
(* mark_debug = "true" *) reg [2:0]  fsm_dr;
(* mark_debug = "true" *) reg cellData_transactor_request_busy_dr;
(* mark_debug = "true" *) reg modelData_transactor_request_busy_dr;
(* mark_debug = "true" *) reg cellData_transactor_param_complete_dr;             
(* mark_debug = "true" *) reg i_secondary_descriptor_buffer_space_available_dr;  


always@(posedge clk) begin
    state_dr                                        <= state;
    fsm_dr                                          <= fsm;
    cellData_transactor_request_busy_dr             <= cellData_transactor_request_busy;
    modelData_transactor_request_busy_dr            <= modelData_transactor_request_busy;
    cellData_transactor_param_complete_dr               <= cellData_transactor_param_complete;         
    i_secondary_descriptor_buffer_space_available_dr   <= i_secondary_descriptor_buffer_space_available;
end
   
ila_128_1024
i0_ila_128_1024 (
    .clk(clk),
    .probe0({                                  
		106'b0								                ,
        state_dr                                            ,   // 15
        fsm_dr                                              ,   // 3
        cellData_transactor_param_complete_dr               ,   // 1
        i_secondary_descriptor_buffer_space_available_dr    ,   // 1
        cellData_transactor_request_busy_dr                 ,   // 1
        modelData_transactor_request_busy_dr                    // 1
    })
);

`endif


	
	/*
  brute_force_matcher_perf_counter
  i_performance_counter_ip_detector_0
  (
      .clk        (clk),
      .rst        (rst),
      .enable     (1'b1),
      .initialize (performance_counter_start),
      .stop_count (performance_counter_stop),
      .count      (performance_counter_single_frame)
  );

  assign  performance_counter_start = command_valid & (command_type == `SAP_MSG_TYPE_EXECUTE_REQUEST);
  assign  performance_counter_stop  = (state == ST_SEND_COMPLETION) & (completion_type == `SAP_MSG_TYPE_EXECUTE_COMPLETE); 
  */
endmodule
