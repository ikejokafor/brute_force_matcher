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
// Description:   This module handles processing matches from DSP Cascade. Keeps up with best match
//                for current observed keypoint in secondary desc buffer against model keypoints
//                in primary desc buffer. Handles writing match table back to memory as well
//                match table info.
//
// Dependencies:  address_incrementer.v  
//                fifo_fwft_prog_full.v  
//                fifo_fwft_prog_full_count.v  
//                brute_force_matcher_match_table_info_fifo.v
//   
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_match_table (
    clk                                            ,            
    rst                                            ,

    matchTable_master_request                      ,
    matchTable_master_request_ack                  ,
    matchTable_master_request_complete             ,
    matchTable_master_request_error                ,
    matchTable_master_request_tag                  ,
    matchTable_master_request_option               ,
    matchTable_master_request_type                 ,
    matchTable_master_request_flow                 ,
    matchTable_master_request_local_address        ,
    matchTable_master_request_length               ,

    matchTable_master_descriptor_src_rdy           ,
    matchTable_master_descriptor_dst_rdy           ,
    matchTable_master_descriptor_tag               ,
    matchTable_master_descriptor                   ,

    matchTable_master_datain_src_rdy               ,
    matchTable_master_datain_dst_rdy               ,
    matchTable_master_datain_tag                   ,
    matchTable_master_datain_option                ,
    matchTable_master_datain                       ,

    matchTable_master_dataout_src_rdy              ,
    matchTable_master_dataout_dst_rdy              ,
    matchTable_master_dataout_tag                  ,
    matchTable_master_dataout_option               ,
    matchTable_master_dataout                      ,

    matchTableInfo_master_request                  ,
    matchTableInfo_master_request_ack              ,
    matchTableInfo_master_request_complete         ,
    matchTableInfo_master_request_error            ,
    matchTableInfo_master_request_tag              ,
    matchTableInfo_master_request_option           ,
    matchTableInfo_master_request_type             ,
    matchTableInfo_master_request_flow             ,
    matchTableInfo_master_request_local_address    ,
    matchTableInfo_master_request_length           ,

    matchTableInfo_master_descriptor_src_rdy       ,
    matchTableInfo_master_descriptor_dst_rdy       ,
    matchTableInfo_master_descriptor_tag           ,
    matchTableInfo_master_descriptor               ,

    matchTableInfo_master_datain_src_rdy           ,
    matchTableInfo_master_datain_dst_rdy           ,
    matchTableInfo_master_datain_tag               ,
    matchTableInfo_master_datain_option            ,
    matchTableInfo_master_datain                   ,

    matchTableInfo_master_dataout_src_rdy          ,
    matchTableInfo_master_dataout_dst_rdy          ,
    matchTableInfo_master_dataout_tag              ,
    matchTableInfo_master_dataout_option           ,
    matchTableInfo_master_dataout                  ,

    match_table_ready                              ,
    match_info_valid                               ,
    match_info                                     ,

    init_keypoint_engine                           ,

    controller_num_model_kp                        ,
    controller_num_obsvd_kp                        ,

    processing_complete                            ,

    match_table_info_address                       ,
    match_table_length                             ,
    match_table_address                            ,

    write_match_table_info
);
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    // ----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"

  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local parameters
    //-----------------------------------------------------------------------------------------------------------------------------------------------  
    localparam ST_IDLE_0                   = 8'b00000001;   // 01
    localparam ST_INIT                     = 8'b00000010;   // 02
    localparam ST_WAIT_FOR_MATCHES         = 8'b00000100;   // 04
    localparam ST_PROCESS_MATCH            = 8'b00001000;   // 08
    localparam ST_LOAD_MATCH_BUFFER        = 8'b00010000;   // 10
    localparam ST_RESET_TABLE              = 8'b00100000;   // 20
    localparam ST_WRITE_OUTPUT_BUFFER_0    = 8'b01000000;   // 40
    localparam ST_WRITE_OUTPUT_BUFFER_1    = 8'b10000000;   // 80

    localparam ST_IDLE_1                        = 7'b0000001; // 01
    localparam ST_BUSY                          = 7'b0000010; // 02
    localparam ST_RETIRE_MATCHES_0              = 7'b0000100; // 04
    localparam ST_RETIRE_MATCHES_1              = 7'b0001000; // 08
    localparam ST_RETIRE_MATCHE_TABLE_INFO_0    = 7'b0010000; // 10
    localparam ST_RETIRE_MATCHE_TABLE_INFO_1    = 7'b0100000; // 20
    localparam ST_RETIRE_MATCHE_TABLE_INFO_2    = 7'b1000000; // 40

    localparam C_MATCH_TABLE_CHUNK_SZ      = 128 * `MATCH_TABLE_SIZE;
 
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Ouputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                                 clk;
    input                                 rst;
    // SAP Master Command Interface (Unused)
	output                                  matchTable_master_request;
	input                                   matchTable_master_request_ack;
	input                                   matchTable_master_request_complete;
	input       [6 :0]                      matchTable_master_request_error;
    input       [3 :0]                      matchTable_master_request_tag;
    output      [3  :0]                     matchTable_master_request_option;
    output      [3  :0]                     matchTable_master_request_type;
    output      [9  :0]                     matchTable_master_request_flow;
    output      [63 :0]                     matchTable_master_request_local_address;
	output  [35 :0]                         matchTable_master_request_length;
    // SAP Master Descriptor Interface (Unused)
    output                                  matchTable_master_descriptor_src_rdy;
    input                                   matchTable_master_descriptor_dst_rdy;
    input       [3  :0]                     matchTable_master_descriptor_tag;
    output      [127:0]                     matchTable_master_descriptor;
    // SAP Master Data Interface (Unused
    input                                   matchTable_master_datain_src_rdy;
    output                                  matchTable_master_datain_dst_rdy;
    input      [3 :0]                       matchTable_master_datain_tag;
    input      [3  :0]                      matchTable_master_datain_option;
    input      [127:0]                      matchTable_master_datain;

	output                                  matchTable_master_dataout_src_rdy;
	input                                   matchTable_master_dataout_dst_rdy;
    input       [3 :0]                      matchTable_master_dataout_tag;
    input       [3  :0]                     matchTable_master_dataout_option;
    output reg  [127:0]                     matchTable_master_dataout;
    
	output                                  matchTableInfo_master_request;
	input                                   matchTableInfo_master_request_ack;
 	input                                   matchTableInfo_master_request_complete;
    input       [6 :0]                      matchTableInfo_master_request_error;
    input       [3 :0]                      matchTableInfo_master_request_tag;
    output      [3  :0]                     matchTableInfo_master_request_option;
    output      [3  :0]                     matchTableInfo_master_request_type;
    output      [9  :0]                     matchTableInfo_master_request_flow;
    output      [63 :0]                     matchTableInfo_master_request_local_address;
	output    [35 :0]                       matchTableInfo_master_request_length;
    // SAP Master Descriptor Interface (Unused)
    output                                  matchTableInfo_master_descriptor_src_rdy;
    input                                   matchTableInfo_master_descriptor_dst_rdy;
    input       [3  :0]                     matchTableInfo_master_descriptor_tag;
    output      [127:0]                     matchTableInfo_master_descriptor;
    // SAP Master Data Interface (Unused
    input                                   matchTableInfo_master_datain_src_rdy;
    output                                  matchTableInfo_master_datain_dst_rdy;
    input      [3 :0]                       matchTableInfo_master_datain_tag;
    input      [3  :0]                      matchTableInfo_master_datain_option;
    input      [127:0]                      matchTableInfo_master_datain;

	output                                  matchTableInfo_master_dataout_src_rdy;
	input                                   matchTableInfo_master_dataout_dst_rdy;
    input       [3 :0]                      matchTableInfo_master_dataout_tag;
    input       [3  :0]                     matchTableInfo_master_dataout_option;
    output reg  [127:0]                     matchTableInfo_master_dataout;

	output                                  match_table_ready;
    input                                   match_info_valid;
    input       [`MATCH_INFO_WIDTH - 1:0]   match_info;

    input                                   init_keypoint_engine;

    input       [15:0]                      controller_num_model_kp;
    input       [15:0]                      controller_num_obsvd_kp;

    output                                  processing_complete;
	input       [63:0]                      match_table_info_address;
    input       [35:0]                      match_table_length;
	input       [63:0]                      match_table_address;
    
    input                                   write_match_table_info;

  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    reg  [          `MATCH_TABLE_WIDTH  - 1:0]      match_table;
	reg  [                                7:0]      state_0;
	reg  [                                6:0]      state_1;

    reg                                             matchTable_initialize;   
    reg [                                3:0]       matchTable_initialize_request_type;
    reg [                               63:0]       matchTable_initialize_address;                    
    reg                                             matchTable_initialize_complete;
    reg [35:0  ]                                    matchTable_initialize_length;
    reg                                             matchTable_transactor_request;                                   
    reg [                                3:0]       matchTable_transactor_request_option;             
	wire                                            matchTable_transactor_active; 
	wire                                            matchTable_transactor_request_busy;
	wire                                            matchTable_transaction_request_complete;
    reg                                             matchTable_transactor_reset;
    
    reg                                             matchTableInfo_initialize;   
    reg                                             matchTableInfo_transactor_request;                                   
    reg [                                3:0]       matchTableInfo_transactor_request_option;             
	wire                                            matchTableInfo_transactor_active; 
	wire                                            matchTableInfo_transactor_request_busy;
	wire                                            matchTableInfo_transaction_request_complete;
    reg                                             matchTableInfo_use_provided_param;
    reg                                             matchTableInfo_transactor_reset;
    reg        [ 35:0]                              matchTableInfo_provided_parameters_length;
    reg        [  3:0]                              matchTableInfo_provided_request_option;
    reg        [  3:0]                              matchTableInfo_provided_request_type_r;
    reg        [ 63:0]                              matchTableInfo_provided_parameters_address;
    
    
	reg     [                             15:0]     match_table_counter;
	reg     [                 clog2(256) - 1:0]     match_table_wr_addr;
	reg     [                 clog2(256) - 1:0]     match_table_rd_addr;
    
	reg     [                clog2(2048) - 1:0]     match_table_info_wr_addr;
	reg     [                 clog2(512) - 1:0]     match_table_info_rd_addr;
    
    wire                                            match_buffer_empty;
    wire [             `MATCH_INFO_WIDTH - 1:0]     match_buffer_dataout;
    wire                                            match_buffer_rden;

	reg  [                                15:0]     model_kp_count;
	reg  [                                15:0]     obsvd_kp_count;

    reg                                             processing_complete_r0;
    reg                                             processing_complete_r1;
    reg                                             pipeline_retire_matches;
    reg                                             pipeline_retire_matches_reset;
	reg                                             retire_matches;

    wire                                            match_table_output_fifo_rden;
    wire [            `MATCH_TABLE_WIDTH - 1:0]     match_table_output_fifo_dataout;
    wire                                            match_table_output_fifo_prog_full;
    wire [                        clog2(256):0]     match_table_output_fifo_count;
    wire                                            match_table_output_fifo_full;
    wire                                            match_table_match_buffer_prog_full;

    
    reg                                             fxd_to_flt_din_valid;
    wire [            `MATCH_TABLE_WIDTH - 1:0]     fxd_to_flt_din;
    wire [            `MATCH_TABLE_WIDTH - 1:0]     fxd_to_flt_dataout;
    wire                                            fxd_to_flt_data_valid;

    reg                                             match_table_info_output_fifo_wren;
    wire                                            match_table_info_output_fifo_rden;
    wire [`MATCH_TABLE_INFO_OUTPUT_WIDTH - 1:0]     match_table_info_output_fifo_datain;
    reg  [`MATCH_TABLE_INFO_OUTPUT_WIDTH - 1:0]     match_table_info_output_fifo_datain_r;
    wire [`DATAIN_WIDTH                  - 1:0]     match_table_info_output_fifo_dataout;
    reg  [                                 9:0]     match_table_info_output_fifo_count;

    reg  [                                15:0]     cell_count;
    reg                                             last_batch;
	reg                                             last_batch_r;
    reg                                             last_batch_r_reset;
    reg  [                                15:0]     current_cell_match_count;
    reg  [                                15:0]     cell_id;
    reg                                             matchTable_master_dataout_src_rdy_r;
    reg                                             matchTableInfo_master_dataout_src_rdy_r0;
    reg                                             matchTableInfo_master_dataout_src_rdy_r1;
    reg  [                                15:0]     master_dataout_count;
    
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations / Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    master_transactor #(        
        .C_BURST_MODE_ENABLED   ( 1                         ), 
        .C_BURST_SIZE_BYTES     ( C_MATCH_TABLE_CHUNK_SZ    )
    )
    i0_matchTable_transactor (                                                     
        .master_clk                    ( clk                                       ),
        .master_rst                    ( rst                                       ),
        .master_request                ( matchTable_master_request                 ),
        .master_request_ack            ( matchTable_master_request_ack             ),
        .master_request_complete       ( matchTable_master_request_complete        ),
        .master_request_option         ( matchTable_master_request_option          ),
        .master_request_error          ( matchTable_master_request_error           ),
        .master_request_tag            ( matchTable_master_request_tag             ),
        .master_request_type           ( matchTable_master_request_type            ),
        .master_request_flow           ( matchTable_master_request_flow            ),
        .master_request_local_address  ( matchTable_master_request_local_address   ),
        .master_request_length         ( matchTable_master_request_length          ),
        .master_descriptor_src_rdy     ( matchTable_master_descriptor_src_rdy      ),
        .master_descriptor_dst_rdy     ( matchTable_master_descriptor_dst_rdy      ),
        .master_descriptor_tag         ( matchTable_master_descriptor_tag          ),
        .master_descriptor             ( matchTable_master_descriptor              ),
        .master_datain_src_rdy         ( matchTable_master_datain_src_rdy          ),
        .master_datain_dst_rdy         ( matchTable_master_datain_dst_rdy          ),
        .master_datain_tag             ( matchTable_master_datain_tag              ),
        .master_dataout_src_rdy        ( matchTable_master_dataout_src_rdy         ),
        .master_dataout_dst_rdy        ( matchTable_master_dataout_dst_rdy         ),
        .master_dataout_tag            ( matchTable_master_dataout_tag             ),
        .initialize                    ( matchTable_initialize                     ),
        .intiialize_request_type       ( matchTable_initialize_request_type        ),
        .initialize_address            ( matchTable_initialize_address             ),
        .initialize_length             ( matchTable_initialize_length              ),
        .initialize_complete           ( matchTable_initialize_complete            ),
        .transactor_request            ( matchTable_transactor_request             ),
        .transactor_enable             ( 1'b1                                      ),      
        .transactor_request_option     ( 4'b0                                      ),
        .transactor_request_busy       ( matchTable_transactor_request_busy        ),
        .transactor_active             ( matchTable_transactor_active              ),
        .transaction_request_complete  ( matchTable_transaction_request_complete   ),
        .transactor_param_complete     (                                           ),
        .transactor_reset              ( matchTable_transactor_reset               ),
        .use_provided_param            ( 1'b0                                      ), 
        .provided_parameters_length    (                                           ),
        .provided_request_option       (                                           ),
        .provided_request_type_r       (                                           ),
        .provided_parameters_address   (                                           )
    );
    
    
    master_transactor
    i0_matchTableInfo_transactor (
        .master_clk                    ( clk                                            ),
        .master_rst                    ( rst                                            ),
        .master_request                ( matchTableInfo_master_request                  ),
        .master_request_ack            ( matchTableInfo_master_request_ack              ),
        .master_request_complete       ( matchTableInfo_master_request_complete         ),
        .master_request_option         ( matchTableInfo_master_request_option           ),
        .master_request_error          ( matchTableInfo_master_request_error            ),
        .master_request_tag            ( matchTableInfo_master_request_tag              ),
        .master_request_type           ( matchTableInfo_master_request_type             ),
        .master_request_flow           ( matchTableInfo_master_request_flow             ),
        .master_request_local_address  ( matchTableInfo_master_request_local_address    ),
        .master_request_length         ( matchTableInfo_master_request_length           ),
        .master_descriptor_src_rdy     ( matchTableInfo_master_descriptor_src_rdy       ),
        .master_descriptor_dst_rdy     ( matchTableInfo_master_descriptor_dst_rdy       ),
        .master_descriptor_tag         ( matchTableInfo_master_descriptor_tag           ),
        .master_descriptor             ( matchTableInfo_master_descriptor               ),
        .master_datain_src_rdy         ( matchTableInfo_master_datain_src_rdy           ),
        .master_datain_dst_rdy         ( matchTableInfo_master_datain_dst_rdy           ),
        .master_datain_tag             ( matchTableInfo_master_datain_tag               ),
        .master_dataout_src_rdy        ( matchTableInfo_master_dataout_src_rdy          ),
        .master_dataout_dst_rdy        ( matchTableInfo_master_dataout_dst_rdy          ),
        .master_dataout_tag            ( matchTableInfo_master_dataout_tag              ),
        .initialize                    ( matchTableInfo_initialize                      ),
        .intiialize_request_type       (                                                ),
        .initialize_address            (                                                ),
        .initialize_length             (                                                ),
        .initialize_complete           (                                                ),
        .transactor_request            ( matchTableInfo_transactor_request              ),
        .transactor_enable             ( 1'b1                                           ),
        .transactor_request_option     ( 4'b0                                           ),
        .transactor_request_busy       ( matchTableInfo_transactor_request_busy         ),
        .transactor_active             ( matchTableInfo_transactor_active               ),
        .transaction_request_complete  ( matchTableInfo_transaction_request_complete    ),
        .transactor_param_complete     (                                                ),
        .transactor_reset              ( matchTableInfo_transactor_reset                ),
        .use_provided_param            ( matchTableInfo_use_provided_param              ),
        .provided_parameters_length    ( matchTableInfo_provided_parameters_length      ),
        .provided_request_option       ( matchTableInfo_provided_request_option         ),
        .provided_request_type_r       ( matchTableInfo_provided_request_type_r         ),
        .provided_parameters_address   ( matchTableInfo_provided_parameters_address     )
    );

  
    // fifo_fwft_prog_full  #(
    //     .C_DATA_WIDTH          ( `MATCH_INFO_WIDTH  ),
    //     .C_FIFO_DEPTH          ( 256                ),   // there is a way to compute how much you
    //     .C_PROG_FULL_THRESHOLD ( 128                )    // need based on how fast matches are being produced
    // )
    // match_buffer (
    //     .clk       ( clk                                    ),
    //     .rst       ( rst                                    ),
    //     .wren      ( match_info_valid                       ),
    //     .rden      ( match_buffer_rden                      ),
    //     .datain    ( match_info                             ),
    //     .dataout   ( match_buffer_dataout                   ),
    //     .empty     ( match_buffer_empty                     ),
    //     .full      (                                        ),
    //     .prog_full ( match_table_match_buffer_prog_full     )
    // );
// `ifdef SIMULATION    
//     wire [17:0] match_buffer_count;
// `endif
    fifo_fwft_prog_full_count  #(
        .C_DATA_WIDTH          ( `MATCH_INFO_WIDTH  ),
        .C_FIFO_DEPTH          ( 256                ),   // there is a way to compute how much you
        .C_PROG_FULL_THRESHOLD ( 128                )    // need based on how fast matches are being produced
    )
    match_buffer (
        .clk       ( clk                                    ),
        .rst       ( rst                                    ),
        .wren      ( match_info_valid                       ),
        .rden      ( match_buffer_rden                      ),
        .datain    ( match_info                             ),
        .dataout   ( match_buffer_dataout                   ),
        .empty     ( match_buffer_empty                     ),
        .full      (                                        ),
        .prog_full ( match_table_match_buffer_prog_full     ),
        .count     ( /*match_buffer_count*/                 )
    );
    
 
    brute_force_matcher_format_conv
    i0_brute_force_matcher_format_conv (
        .clk                  ( clk                   ), 
        .rst                  ( rst                   ),
        .s_axis_tvalid        ( fxd_to_flt_din_valid  ),
        .s_axis_tdata         ( fxd_to_flt_din        ),
        .m_axis_result_tvalid ( fxd_to_flt_data_valid ),
        .m_axis_result_tdata  ( fxd_to_flt_dataout    ) 
    );
    
    
    xilinx_simple_dual_port_1_clock_ram #(
        .RAM_WIDTH       (`MATCH_TABLE_WIDTH    ),
        .RAM_DEPTH       ( 256                  )
    )
    match_table_fifo (
        .addra   ( match_table_wr_addr             ),
        .addrb   ( match_table_rd_addr             ),
        .dina    ( fxd_to_flt_dataout              ),
        .clka    ( clk                             ),
        .wren    ( fxd_to_flt_data_valid           ),
        .rden    ( match_table_output_fifo_rden    ),
        .rstb    ( rst                             ),
        .doutb   ( match_table_output_fifo_dataout ),
        .count   ( match_table_output_fifo_count   ),
        .full    ( match_table_output_fifo_full    )
    );
    

    //fifo_fwft_prog_full_count  #(
    //    .C_DATA_WIDTH          ( `MATCH_TABLE_WIDTH ),
    //    .C_FIFO_DEPTH          ( 256                ),
    //    .C_PROG_FULL_THRESHOLD ( 128                ) // reture every 128 matches
    //)
    //match_table_fifo (
    //    .clk       ( clk                               ),
    //    .rst       ( rst                               ),
    //    .wren      ( fxd_to_flt_data_valid             ),
    //    .datain    ( fxd_to_flt_dataout                ),
    //    .rden      ( match_table_output_fifo_rden      ),
    //    .dataout   ( match_table_output_fifo_dataout   ),
    //    .empty     (                                   ),
    //    .full      (                                   ),
    //    .prog_full ( match_table_output_fifo_prog_full ),
    //    .count     ( match_table_output_fifo_count     )
    //);
    
    
    // Match Table Fifo Specs for 8 DSP Slices, 4 desc elements per datain bus, and 16 bits per desc element
    // Write Width: 32 bits
    // Write Depth: 2048 (for 2048 max cells)
    // Read Width:  128 bits
    // Read Depth:  512  
    brute_force_matcher_match_table_info_bram
    match_table_info_bram (
        .clka       ( clk                                    ),            
        .wea        ( match_table_info_output_fifo_wren      ),
        .addra      ( match_table_info_wr_addr               ),
        .dina       ( match_table_info_output_fifo_datain    ),
        .clkb       ( clk                                    ),
        .enb        ( match_table_info_output_fifo_rden      ),
        .addrb      ( match_table_info_rd_addr               ),
        .doutb      ( match_table_info_output_fifo_dataout   )
    );
    

    // Match Table Fifo Specs for 8 DSP Slices, 4 desc elements per datain bus, and 16 bits per desc element
    // Write Width: 32 bits
    // Write Depth: 2048 (for 2048 max cells)
    // Read Width:  128 bits
    // Read Depth:  512  
    //brute_force_matcher_match_table_info_fifo
    //i0_brute_force_matcher_match_table_info_fifo (
    //    .clk           ( clk                                  ),
    //    .srst          ( rst                                  ),
    //    .din           ( match_table_info_output_fifo_datain  ),
    //    .wr_en         ( match_table_info_output_fifo_wren    ),
    //    .rd_en         ( match_table_info_output_fifo_rden    ),
    //    .dout          ( match_table_info_output_fifo_dataout ),
    //    .full          (                                      ),
    //    .empty         (                                      ),
    //    .valid         (                                      ),
    //    .rd_data_count ( match_table_info_output_fifo_count   ) 
    //);
    
    
    

    // BEGIN Match table State machine transition logic ---------------------------------------------------------------------------------------------
`ifdef VERIFICATION
    reg debug;
    always@(posedge clk) begin
        if(rst) begin
            debug <= 1;
        end else begin
            debug <= $urandom_range(0, 1);
        end
    end
    assign match_table_ready                        = !match_table_match_buffer_prog_full && debug; 
`else
    assign match_table_ready                        = !match_table_match_buffer_prog_full; 
`endif
    assign fxd_to_flt_din                           = match_table;
    assign match_table_info_output_fifo_datain      = (state_0 != ST_WRITE_OUTPUT_BUFFER_1) ? match_table_info_output_fifo_datain_r : 32'hFFFFFFFF;
    assign processing_complete                      = processing_complete_r0 || processing_complete_r1;
    assign match_buffer_rden                        = (!match_buffer_empty && state_0 == ST_PROCESS_MATCH);
    
    always@(posedge clk) begin
        if(rst) begin
            retire_matches  <= 0;
            last_batch_r    <= 0;
        end else begin
            if(pipeline_retire_matches) begin
                retire_matches      <= 1;
            end else if(pipeline_retire_matches_reset) begin
                retire_matches      <= 0;
            end
            if(last_batch) begin
                last_batch_r        <= 1;
            end else if(last_batch_r_reset) begin
                last_batch_r        <= 0;
            end
        end
    end
    
    always@(posedge clk) begin
        if(rst) begin
            match_table_wr_addr                 <= 0;
            match_table_info_wr_addr            <= 0;
            match_table_counter                 <= 0;
            match_table_info_output_fifo_count  <= 0;
        end else begin
            if(fxd_to_flt_data_valid) begin
                match_table_wr_addr <= match_table_wr_addr + 1;
                match_table_counter <= match_table_counter + 1;
            end
            if(processing_complete) begin
                match_table_counter <= 0;
            end
            if(match_table_info_output_fifo_wren) begin
                match_table_info_wr_addr            <= match_table_info_wr_addr + 1;
                match_table_info_output_fifo_count  <= match_table_info_output_fifo_count + 1;
            end
            if(match_table_info_output_fifo_rden) begin
                match_table_info_output_fifo_count  <= match_table_info_output_fifo_count - 4;
            end           
        end
    end
    
    always@(posedge clk) begin
        if(rst) begin
            model_kp_count                      <= 0;
            obsvd_kp_count                      <= 0;
            pipeline_retire_matches             <= 0;
            last_batch                          <= 0;
            match_table_info_output_fifo_wren   <= 0;
            current_cell_match_count            <= 0;
            cell_id                             <= 0;
            cell_count                          <= 1;
            processing_complete_r1              <= 0;
            match_table                         <=  {              
                                                      {`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH{1'b0}},  // 2nd Model ID
                                                      {`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH{1'b0}},  // 2nd Query ID
                                                      1'b0, {(`MATCH_TABLE_2ND_SCORE_WIDTH - 1){1'b1}},  // 2nd Score
                                                      {`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH{1'b0}},  // 1st Model ID
                                                      {`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH{1'b0}},  // 1st Query ID
                                                      1'b0, {(`MATCH_TABLE_1ST_SCORE_WIDTH - 1){1'b1}}   // 1st Score
                                                    };  
            state_0                             <= ST_IDLE_0;
        end else begin
            pipeline_retire_matches             <= 0;
            fxd_to_flt_din_valid                <= 0;
            match_table_info_output_fifo_wren   <= 0;
            processing_complete_r1              <= 0;
            last_batch                          <= 0;
            case(state_0)
                ST_IDLE_0: begin
                    if(init_keypoint_engine) begin
                        if(controller_num_model_kp != 0 && controller_num_obsvd_kp != 0) begin
                            current_cell_match_count <= 0;
                            obsvd_kp_count           <= 0;
                            model_kp_count           <= 0;
                            state_0                  <= ST_WAIT_FOR_MATCHES;
                        end else begin
                            processing_complete_r1  <= 1;
                        end
                    end 
                end
                ST_WAIT_FOR_MATCHES: begin    
                    if(model_kp_count == controller_num_model_kp) begin // 
                        model_kp_count <= 0;                            // dont think this logic is needed here anymore
                        state_0        <= ST_LOAD_MATCH_BUFFER;         // 
                    end else if(!match_buffer_empty) begin
                        state_0           <= ST_PROCESS_MATCH;
                    end
                end
                ST_PROCESS_MATCH: begin  
                    if(model_kp_count == controller_num_model_kp) begin
                        model_kp_count <= 0;
                        state_0        <= ST_LOAD_MATCH_BUFFER;
                    end else if(!match_buffer_empty) begin
                        model_kp_count        <= model_kp_count + 1;
                        if((match_buffer_dataout[`MATCH_INFO_SCORE_FIELD]) < (match_table[`MATCH_TABLE_1ST_SCORE_FIELD])) begin // if this feature matches better than current best         
                            // update 2nd best match with best match
                            match_table[`MATCH_TABLE_2ND_SCORE_FIELD]             <= match_table[`MATCH_TABLE_1ST_SCORE_FIELD];
                            match_table[`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD] <= match_table[`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD];
                            match_table[`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD] <= match_table[`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD];
                            // update best with new match
                            match_table[`MATCH_TABLE_1ST_SCORE_FIELD]             <= match_buffer_dataout[`MATCH_INFO_SCORE_FIELD];
                            match_table[`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD] <= {3'b0, match_buffer_dataout[`MATCH_INFO_MODEL_KEYPOINT_ID_FIELD]};
                            match_table[`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD] <= {3'b0, match_buffer_dataout[`MATCH_INFO_QUERY_KEYPOINT_ID_FIELD]};          
                        end else if((match_buffer_dataout[`MATCH_INFO_SCORE_FIELD]) < (match_table[`MATCH_TABLE_2ND_SCORE_FIELD])) begin // this feature matches better than second best          
                            match_table[`MATCH_TABLE_2ND_SCORE_FIELD]             <= match_buffer_dataout[`MATCH_INFO_SCORE_FIELD];
                            match_table[`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD] <= {3'b0, match_buffer_dataout[`MATCH_INFO_MODEL_KEYPOINT_ID_FIELD]};
                            match_table[`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD] <= {3'b0, match_buffer_dataout[`MATCH_INFO_QUERY_KEYPOINT_ID_FIELD]};          
                        end      
                        if(cell_id != match_buffer_dataout[`MATCH_INFO_CELL_ID_FIELD]) begin
                            cell_id                               <= match_buffer_dataout[`MATCH_INFO_CELL_ID_FIELD];
                            cell_count                            <= cell_count + 1;
                            current_cell_match_count              <= 0;
                            match_table_info_output_fifo_datain_r <= {current_cell_match_count, cell_id};
                            match_table_info_output_fifo_wren     <= 1;
                        end
                    end else begin
                        state_0             <= ST_WAIT_FOR_MATCHES;
                    end
                end
                ST_LOAD_MATCH_BUFFER: begin
                    fxd_to_flt_din_valid        <= 1;
                    obsvd_kp_count              <= obsvd_kp_count + 1;
                    current_cell_match_count    <= current_cell_match_count + 1;
                    state_0                     <= ST_RESET_TABLE;
                end
                ST_RESET_TABLE: begin
                    match_table  <=     {              
                                            {`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH{1'b0}},  // 2nd Model ID
                                            {`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH{1'b0}},  // 2nd Query ID
                                            1'b0, {(`MATCH_TABLE_2ND_SCORE_WIDTH - 1){1'b1}},  // 2nd Score
                                            {`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH{1'b0}},  // 1st Model ID
                                            {`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH{1'b0}},  // 1st Query ID
                                            1'b0, {(`MATCH_TABLE_1ST_SCORE_WIDTH - 1){1'b1}}   // 1st Score
                                        }; 		
                    if(obsvd_kp_count != controller_num_obsvd_kp) begin
                        state_0   <= ST_WAIT_FOR_MATCHES;
                    end else if(obsvd_kp_count == controller_num_obsvd_kp && fxd_to_flt_data_valid) begin
                        match_table_info_output_fifo_datain_r <= {current_cell_match_count, cell_id};
                        match_table_info_output_fifo_wren     <= 1;      // done with current and last cell so need an extra write
                        state_0                               <= ST_WRITE_OUTPUT_BUFFER_0;
                    end
                end
                ST_WRITE_OUTPUT_BUFFER_0: begin  // wait for last write to occur from previous state bc of 1 cycle write latency from vivado fifo ip
                    state_0    <= ST_WRITE_OUTPUT_BUFFER_1;
                end
                // in case number of matches doesnt fill a whole 128 bit slot, need to add 0's
                // to the rest of entries
                ST_WRITE_OUTPUT_BUFFER_1: begin
                    // extra wren signal, but xilinx fifo's will not overwrite value
                    if(cell_count[1:0] != 0) begin  // since 4 entries per slot, number of total matches has to be multiple of 4
                        state_0                             <= ST_WRITE_OUTPUT_BUFFER_1;
                        match_table_info_output_fifo_wren   <= 1;
                        cell_count                          <= cell_count + 1;
                    end else begin
                        pipeline_retire_matches     <= 1;
                        last_batch                  <= 1;
                        cell_id                     <= 0;
                        cell_count                  <= 1;
                        state_0                     <= ST_IDLE_0;
                    end
                end
                default: begin

                end
            endcase    
        end
    end
    // END Match table state machine transition logic -----------------------------------------------------------------------------------------------
  
    
    // BEGIN Match table Retire State machine transition logic --------------------------------------------------------------------------------------
    assign matchTable_master_datain_dst_rdy         = 0;
    assign matchTable_master_dataout_option         = 0;  
    assign matchTableInfo_master_datain_dst_rdy     = 0;
    assign matchTableInfo_master_dataout_option     = 0;
    
    // NIF_DMA_DESCRIPTOR_LENGTH_FIELD      35:0  
    // NIF_DMA_DESCRIPTOR_DEVICE_FIELD      51:36
    // NIF_DMA_DESCRIPTOR_FLOW_FIELD        61:52
    // NIF_DMA_DESCRIPTOR_LAST_TARGET_FLAG  63  
    // NIF_DMA_DESCRIPTOR_ADDRESS_FIELD     127:64  
    always@(posedge clk) begin
        if(rst) begin
            processing_complete_r0                          <= 0;
            last_batch_r_reset                              <= 0;
            matchTable_master_dataout                       <= 0;
            matchTableInfo_master_dataout                   <= 0;
            matchTable_initialize                           <= 0;  
            matchTable_initialize_request_type              <= 0;
            matchTable_initialize_address                   <= 0;
            matchTable_initialize_length                    <= 0;                               
            matchTable_initialize_complete                  <= 0;
            matchTable_transactor_request                   <= 0;                                   
            matchTable_transactor_request_option            <= 0;
            matchTable_transactor_reset                     <= 0;
            matchTableInfo_initialize                       <= 0;
            matchTableInfo_transactor_request               <= 0;                                   
            matchTableInfo_transactor_request_option        <= 0;
            matchTableInfo_use_provided_param               <= 0;
            matchTableInfo_provided_parameters_length       <= 0;
            matchTableInfo_provided_request_option          <= 0;
            matchTableInfo_provided_request_type_r          <= 0;
            matchTableInfo_provided_parameters_address      <= 0;
            matchTableInfo_transactor_reset                 <= 0;
            pipeline_retire_matches_reset                   <= 0;
            state_1                                         <= ST_IDLE_1;      
        end else begin
            last_batch_r_reset                             <= 0;
            processing_complete_r0                         <= 0;
            matchTable_initialize                          <= 0;
            matchTable_initialize                          <= 0;
            matchTable_initialize_request_type             <= 0;
            matchTable_initialize_address                  <= 0;  
            matchTable_initialize_length                   <= 0;                   
            matchTable_initialize_complete                 <= 0;
            matchTable_transactor_request                  <= 0;                                 
            matchTable_transactor_request_option           <= 0;
            matchTable_transactor_reset                    <= 0;
            matchTableInfo_initialize                      <= 0;
            matchTableInfo_transactor_request              <= 0;                                  
            matchTableInfo_transactor_request_option       <= 0;
            matchTableInfo_use_provided_param              <= 0;
            matchTableInfo_provided_parameters_length      <= 0;
            matchTableInfo_provided_request_option         <= 0;
            matchTableInfo_provided_request_type_r         <= 0;
            matchTableInfo_provided_parameters_address     <= 0;
            matchTableInfo_transactor_reset                <= 0;
            matchTable_master_dataout                      <= 0;
            matchTableInfo_master_dataout                  <= 0;
            pipeline_retire_matches_reset                  <= 0;
            case(state_1)    
                ST_IDLE_1: begin
                    if(init_keypoint_engine && controller_num_model_kp != 0 && controller_num_obsvd_kp != 0) begin                    
                        matchTable_initialize                   <= 1;
                        matchTable_initialize_request_type      <= `NIF_MASTER_CMD_WRREQ;
                        matchTable_initialize_address           <= match_table_address; 
                        matchTable_initialize_length            <= match_table_length;
                        matchTable_initialize_complete          <= 0; 
                        matchTableInfo_initialize               <= 1;                        
                        state_1                                 <= ST_BUSY;
                    end 
                end
                ST_BUSY: begin
                    if(match_table_output_fifo_count > 0 && ((match_table_counter[6:0] == 0 || retire_matches) && match_table_counter > 0)) begin    // match_table_counter[6:0] => retire every 128 matches
                        if(retire_matches) begin
                            pipeline_retire_matches_reset   <= 1;
                        end
                        state_1                             <= ST_RETIRE_MATCHES_0;
                    end
                    if(last_batch_r && (match_table_output_fifo_count == 0)) begin
                        if(write_match_table_info && (state_0 != ST_WRITE_OUTPUT_BUFFER_0 || state_0 != ST_WRITE_OUTPUT_BUFFER_1)) begin
                            last_batch_r_reset              <= 1;
                            state_1                         <= ST_RETIRE_MATCHE_TABLE_INFO_0;             
                        end else begin
                            if(!matchTable_transactor_request_busy) begin
                                processing_complete_r0              <= 1;
                                last_batch_r_reset                  <= 1;
                                matchTable_transactor_reset         <= 1;
                                matchTableInfo_transactor_reset     <= 1;
                                pipeline_retire_matches_reset       <= 1;
                                state_1                             <= ST_IDLE_1;
                            end
                        end
                    end
                end
                //ST_BUSY: begin
                //    if(match_table_output_fifo_prog_full || (retire_matches && match_table_output_fifo_count > 0)) begin
                //        if(retire_matches) begin
                //            pipeline_retire_matches_reset   <= 1;
                //        end
                //        state_1                             <= ST_RETIRE_MATCHES_0;
                //    end
                //    if(last_batch_r && (match_table_output_fifo_count == 0)) begin
                //        if(write_match_table_info && (state_0 != ST_WRITE_OUTPUT_BUFFER_0 || state_0 != ST_WRITE_OUTPUT_BUFFER_1)) begin
                //            last_batch_r_reset              <= 1;
                //            state_1                         <= ST_RETIRE_MATCHE_TABLE_INFO_0;             
                //        end else begin
                //            if(!matchTable_transactor_request_busy) begin
                //                processing_complete_r0              <= 1;
                //                last_batch_r_reset                  <= 1;
                //                matchTable_transactor_reset         <= 1;
                //                matchTableInfo_transactor_reset     <= 1;
                //                pipeline_retire_matches_reset       <= 1;
                //                state_1                             <= ST_IDLE_1;
                //            end
                //        end
                //    end
                //end
                ST_RETIRE_MATCHES_0: begin              
                    if(matchTable_transactor_active && !matchTable_transactor_request_busy) begin
                        matchTable_transactor_request       <= 1;
                        state_1                             <= ST_RETIRE_MATCHES_1;               
                    end
                end  
                ST_RETIRE_MATCHES_1: begin
                    matchTable_master_dataout <= match_table_output_fifo_dataout;                    
                    if(matchTable_transaction_request_complete) begin
                        state_1                              <= ST_BUSY;
                    end                    
                end
                ST_RETIRE_MATCHE_TABLE_INFO_0: begin
                    matchTableInfo_use_provided_param               <= 1;
                    matchTableInfo_provided_parameters_length       <= {36'b0, match_table_info_output_fifo_count[9:2] << clog2(`MATCH_TABLE_INFO_OUTPUT_SIZE)};
                    matchTableInfo_provided_request_type_r          <= `NIF_MASTER_CMD_WRREQ;
                    matchTableInfo_provided_parameters_address      <= match_table_info_address;
                    if(matchTableInfo_transactor_active) begin 
                        matchTableInfo_transactor_request           <= 1;
                        state_1                                     <= ST_RETIRE_MATCHE_TABLE_INFO_1;
                    end
                end
                ST_RETIRE_MATCHE_TABLE_INFO_1: begin
                    if(matchTableInfo_transaction_request_complete) begin
                        state_1                   <= ST_RETIRE_MATCHE_TABLE_INFO_2;
                    end
                    matchTableInfo_master_dataout <= match_table_info_output_fifo_dataout;
                                                        //{
                                                        //    match_table_info_output_fifo_dataout[31:0],
                                                        //    match_table_info_output_fifo_dataout[63:32],
                                                        //    match_table_info_output_fifo_dataout[95:64],
                                                        //    match_table_info_output_fifo_dataout[127:96]
                                                        //};
                end
                ST_RETIRE_MATCHE_TABLE_INFO_2: begin
                    if(!matchTable_transactor_request_busy && !matchTableInfo_transactor_request_busy) begin
                        processing_complete_r0              <= 1;
                        matchTableInfo_transactor_reset     <= 1;
                        matchTable_transactor_reset         <= 1;
                        pipeline_retire_matches_reset       <= 1;
                        state_1                             <= ST_IDLE_1;
                    end
                end
                default: begin

                end
            endcase      
        end
    end
    // END Match table Retire State machine transition logic ----------------------------------------------------------------------------------------
  
  
    // BEGIN Match table Retire State machine transition logic --------------------------------------------------------------------------------------  
    assign matchTable_master_dataout_src_rdy         = matchTable_master_dataout_src_rdy_r;
    assign matchTableInfo_master_dataout_src_rdy     = matchTableInfo_master_dataout_src_rdy_r1;
    assign match_table_info_output_fifo_rden         = (state_1 == ST_RETIRE_MATCHE_TABLE_INFO_1    && matchTableInfo_master_dataout_dst_rdy   && master_dataout_count > 0);
    assign match_table_output_fifo_rden              = (state_1 == ST_RETIRE_MATCHES_1              && matchTable_master_dataout_dst_rdy       && master_dataout_count > 0);
    
    always@(posedge clk) begin
        if(rst) begin
            matchTable_master_dataout_src_rdy_r         <= 0;
            matchTableInfo_master_dataout_src_rdy_r0    <= 0;
            matchTableInfo_master_dataout_src_rdy_r1    <= 0;
            master_dataout_count                        <= 0;
            match_table_rd_addr                         <= 0;
            match_table_info_rd_addr                    <= 0;
        end else begin
            matchTable_master_dataout_src_rdy_r         <= 0;
            matchTableInfo_master_dataout_src_rdy_r0    <= 0;
            matchTableInfo_master_dataout_src_rdy_r1    <= 0;
            if(matchTable_master_request_ack) begin
                master_dataout_count    <= matchTable_master_request_length >> 4;
            end
            if(matchTableInfo_master_request_ack) begin
                master_dataout_count    <= matchTableInfo_master_request_length >> 4;
            end
            if(matchTable_master_dataout_dst_rdy) begin
                matchTable_master_dataout_src_rdy_r <= 1;
            end
            if(matchTableInfo_master_dataout_dst_rdy) begin
                matchTableInfo_master_dataout_src_rdy_r0 <= 1;
                matchTableInfo_master_dataout_src_rdy_r1 <= matchTableInfo_master_dataout_src_rdy_r0;
            end
            if(match_table_output_fifo_rden) begin
                match_table_rd_addr             <= match_table_rd_addr + 1;
                master_dataout_count            <= master_dataout_count - 1;
            end
            if(match_table_info_output_fifo_rden) begin
                match_table_info_rd_addr        <= match_table_info_rd_addr + 1;
                master_dataout_count            <= master_dataout_count - 1;
            end
        end
    end
    // END Match table Retire State machine transition logic ----------------------------------------------------------------------------------------
  

`ifdef SIMULATION
  //integer     f_match_soln;
  //integer     f_match_info;
  //integer     f_floatout;
  //wire [31:0] z1;
  //wire [10:0] exp1;
  //wire [63:0] double_prec1;
  //wire [31:0] z2;
  //wire [10:0] exp2;
  //wire [63:0] double_prec2;
  //
  //assign z1           = fxd_to_flt_dataout[`MATCH_TABLE_1ST_SCORE_FIELD];
  //assign exp1         = z1[30:23] + 11'd896;
  //assign double_prec1 = {z1[31], exp1, z1[22:0], {29{1'b0}}};
  //
  //assign z2           = fxd_to_flt_dataout[`MATCH_TABLE_2ND_SCORE_FIELD];
  //assign exp2         = z2[30:23] + 11'd896;
  //assign double_prec2 = {z2[31], exp2, z2[22:0], {29{1'b0}}};
  //
  //initial begin
  //   f_match_soln    = $fopen("hw_match_data_fixed.txt","w");
  //   f_match_info    = $fopen("hw_match_info.txt","w");
  //   f_floatout      = $fopen("hw_match_data_float.txt","w");
  //
  //   wait (processing_complete==1);
  //   $fclose(f_match_soln);
  //   $fclose(f_match_info);
  //   $fclose(f_floatout);
  //end
  //
  //always@(posedge clk) begin
  //   if(fxd_to_flt_din_valid) begin
  //     $fwrite(f_match_soln, "%d, (%d, %d) ; %d, (%d, %d)\n", 
  //         fxd_to_flt_din[`MATCH_TABLE_1ST_SCORE_FIELD]             ,
  //         fxd_to_flt_din[`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD] ,
  //         fxd_to_flt_din[`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD] ,
  //         fxd_to_flt_din[`MATCH_TABLE_2ND_SCORE_FIELD]             ,
  //         fxd_to_flt_din[`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD] ,
  //         fxd_to_flt_din[`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD]);
  //   end
  //   if(match_table_info_output_fifo_wren)
  //     $fwrite(f_match_info, "%x.000000\n", match_table_info_output_fifo_datain);
  //   if(fxd_to_flt_data_valid ) begin
  //     $fwrite(f_floatout, "%f, (%d, %d) ; %f, (%d, %d)\n", 
  //         $bitstoreal(double_prec1),
  //         fxd_to_flt_dataout[`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD] ,
  //         fxd_to_flt_dataout[`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD] ,
  //         $bitstoreal(double_prec2),
  //         fxd_to_flt_dataout[`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD] ,
  //         fxd_to_flt_dataout[`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD]);
  //   end
  //
  //end
`endif




`ifdef SIMULATION
    string state_0_s;
    string state_1_s;
    // int numMatches;
    // int numReadEnables;
    
    always@(state_0) begin 
        case(state_0) 
            ST_IDLE_0                : state_0_s = "ST_IDLE_0";
            ST_INIT                  : state_0_s = "ST_INIT";
            ST_WAIT_FOR_MATCHES      : state_0_s = "ST_WAIT_FOR_MATCHES";
            ST_PROCESS_MATCH         : state_0_s = "ST_PROCESS_MATCH";
            ST_LOAD_MATCH_BUFFER     : state_0_s = "ST_LOAD_MATCH_BUFFER";
            ST_RESET_TABLE           : state_0_s = "ST_RESET_TABLE";
            ST_WRITE_OUTPUT_BUFFER_0 : state_0_s = "ST_WRITE_OUTPUT_BUFFER_0";
            ST_WRITE_OUTPUT_BUFFER_1 : state_0_s = "ST_WRITE_OUTPUT_BUFFER_1";
        endcase
    end
    always@(state_1) begin 
        case(state_1) 
            ST_IDLE_1                     : state_1_s = "ST_IDLE_1";
            ST_BUSY                       : state_1_s = "ST_BUSY";
            ST_RETIRE_MATCHES_0           : state_1_s = "ST_RETIRE_MATCHES_0";
            ST_RETIRE_MATCHES_1           : state_1_s = "ST_RETIRE_MATCHES_1";
            ST_RETIRE_MATCHE_TABLE_INFO_0 : state_1_s = "ST_RETIRE_MATCHE_TABLE_INFO_0";
            ST_RETIRE_MATCHE_TABLE_INFO_1 : state_1_s = "ST_RETIRE_MATCHE_TABLE_INFO_1";
            ST_RETIRE_MATCHE_TABLE_INFO_2 : state_1_s = "ST_RETIRE_MATCHE_TABLE_INFO_2";
        endcase
    end

    // always@(posedge clk) begin
    //     if(rst) begin
    //         numMatches <= 0;
    //     end else begin
    //         if(init_keypoint_engine) begin
    //             numMatches <= 0;
    //         end
    //         if(match_info_valid) begin
    //             numMatches <= numMatches + 1;
    //         end
    //         if(init_keypoint_engine) begin
    //             numReadEnables <= 0;
    //         end
    //         if(match_buffer_rden) begin
    //             numReadEnables <= numReadEnables + 1;
    //         end
    //     end
    // end    
`endif
  
//`ifdef DEBUG
//        (* mark_debug = "true" *)     reg                                                                   master_request_dr;             
//    (* mark_debug = "true" *)     reg                                                                   master_request_ack_dr;         
//    (* mark_debug = "true" *)     reg                                                                   master_request_complete_dr;    
//    (* mark_debug = "true" *)     reg  [6  :0]                                                          master_request_error_dr;       
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_request_tag_dr;         
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_request_option_dr;      
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_request_type_dr;        
//    (* mark_debug = "true" *)     reg  [9  :0]                                                          master_request_flow_dr;        
//    (* mark_debug = "true" *)     reg  [63 :0]                                                          master_request_local_address_dr;
//    (* mark_debug = "true" *)     reg  [35 :0]                                                          master_request_length_dr;      
//    (* mark_debug = "true" *)     reg                                                                   master_descriptor_src_rdy_dr;  
//    (* mark_debug = "true" *)     reg                                                                   master_descriptor_dst_rdy_dr;  
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_descriptor_tag_dr;      
//    (* mark_debug = "true" *)     reg                                                                   master_datain_src_rdy_dr;      
//    (* mark_debug = "true" *)     reg                                                                   master_datain_dst_rdy_dr;      
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_datain_tag_dr;          
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_datain_option_dr;       
//    (* mark_debug = "true" *)     reg                                                                   master_dataout_src_rdy_dr;     
//    (* mark_debug = "true" *)     reg                                                                   master_dataout_dst_rdy_dr;     
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_dataout_tag_dr;         
//    (* mark_debug = "true" *)     reg  [3  :0]                                                          master_dataout_option_dr; 
//     (* mark_debug = "true" *)     reg [36:0]               master_descriptor_DESCRIPTOR_LENGTH_FIELD_dr;         
//     (* mark_debug = "true" *)     reg [15:0]               master_descriptor_DESCRIPTOR_DEVICE_FIELD_dr;          
//     (* mark_debug = "true" *)     reg [9:0]               master_descriptor_DESCRIPTOR_FLOW_FIELD_dr;             
//     (* mark_debug = "true" *)     reg                 master_descriptor_DESCRIPTOR_LAST_TARGET_FLAG_dr;       
//     (* mark_debug = "true" *)     reg [63:0]               master_descriptor_DESCRIPTOR_ADDRESS_FIELD_dr;          
//    
//    (* mark_debug = "true" *)  reg                              match_table_ready_dr;
//    (* mark_debug = "true" *)  reg                              match_table_match_buffer_prog_full_dr;
//    (* mark_debug = "true" *)  reg     [15:0]                  controller_num_model_kp_dr;
//    (* mark_debug = "true" *)  reg     [15:0]                  controller_num_obsvd_kp_dr;
//    (* mark_debug = "true" *)  reg  [7:0]                      state_0_dr;
//    (* mark_debug = "true" *)  reg  [4:0]                      state_1_dr;
//    (* mark_debug = "true" *)  reg                             match_buffer_empty_dr;
//    (* mark_debug = "true" *)  reg  [15:0]                     model_kp_count_dr;
//    (* mark_debug = "true" *)  reg  [15:0]                     obsvd_kp_count_dr;
//    (* mark_debug = "true" *)  reg                             last_batch_dr;
//    (* mark_debug = "true" *)  reg                             retire_matches_dr;
//    (* mark_debug = "true" *)  reg                              match_table_address_parameters_valid_dr;
//    (* mark_debug = "true" *)  reg                              processing_complete_dr;
//
//    always@(posedge clk) begin
//    
//                     master_request_dr                                       <=   master_request;                                  
//             master_request_ack_dr                                   <=   master_request_ack;                               
//             master_request_complete_dr                              <=   master_request_complete;                          
//             master_request_error_dr                                 <=   master_request_error;                             
//             master_request_tag_dr                                   <=   master_request_tag;                               
//             master_request_option_dr                                <=   master_request_option;                            
//             master_request_type_dr                                  <=   master_request_type;                              
//             master_request_flow_dr                                  <=   master_request_flow;                              
//             master_request_local_address_dr                         <=   master_request_local_address;                    
//             master_request_length_dr                                <=   master_request_length;                            
//             master_descriptor_src_rdy_dr                            <=   master_descriptor_src_rdy;                        
//             master_descriptor_dst_rdy_dr                            <=   master_descriptor_dst_rdy;                        
//             master_descriptor_tag_dr                                <=   master_descriptor_tag;                                
//             master_datain_src_rdy_dr                                <=   master_datain_src_rdy;                            
//             master_datain_dst_rdy_dr                                <=   master_datain_dst_rdy;                            
//             master_datain_tag_dr                                    <=   master_datain_tag;                                
//             master_datain_option_dr                                 <=   master_datain_option;                             
//             master_dataout_src_rdy_dr                               <=   master_dataout_src_rdy;                           
//             master_dataout_dst_rdy_dr                               <=   master_dataout_dst_rdy;                           
//             master_dataout_tag_dr                                   <=   master_dataout_tag;                               
//             master_dataout_option_dr                                <=   master_dataout_option; 
//             master_descriptor_DESCRIPTOR_LENGTH_FIELD_dr            <=   master_descriptor[`NIF_DMA_DESCRIPTOR_LENGTH_FIELD];       
//             master_descriptor_DESCRIPTOR_DEVICE_FIELD_dr            <=   master_descriptor[`NIF_DMA_DESCRIPTOR_DEVICE_FIELD];       
//             master_descriptor_DESCRIPTOR_FLOW_FIELD_dr              <=   master_descriptor[`NIF_DMA_DESCRIPTOR_FLOW_FIELD];         
//             master_descriptor_DESCRIPTOR_LAST_TARGET_FLAG_dr        <=   master_descriptor[`NIF_DMA_DESCRIPTOR_LAST_TARGET_FLAG];   
//             master_descriptor_DESCRIPTOR_ADDRESS_FIELD_dr           <=   master_descriptor[`NIF_DMA_DESCRIPTOR_ADDRESS_FIELD];   
//
//             
//         match_table_ready_dr                      <=   match_table_ready;                     
//         match_table_match_buffer_prog_full_dr    <=   match_table_match_buffer_prog_full;   
//        controller_num_model_kp_dr                <=  controller_num_model_kp;               
//        controller_num_obsvd_kp_dr                <=  controller_num_obsvd_kp;               
//        state_0_dr                                <=  state_0;                               
//        state_1_dr                                <=  state_1;                               
//        match_buffer_empty_dr                    <=  match_buffer_empty;                    
//        model_kp_count_dr                         <=  model_kp_count;                        
//        obsvd_kp_count_dr                         <=  obsvd_kp_count;                        
//        last_batch_dr                            <=  last_batch_r;                            
//        retire_matches_dr                         <=  retire_matches; 
//        match_table_address_parameters_valid_dr     <=    match_table_address_parameters_valid         ;
//        processing_complete_dr                      <= processing_complete;
//    end

 
//    ila_128_4096
//    i0_ila_128_4096 (
//        .clk(clk),
//        .probe0({
//			 128'b0		                                            ,          
//            matchTable_match_table_address_parameters_valid_dr                ,   // 1
//            matchTable_master_request_dr                                       ,   // 1
//            matchTable_master_request_ack_dr                                   ,   // 1
//            matchTable_master_request_complete_dr                              ,   // 1
//            matchTable_master_request_error_dr                                 ,   // 7
//            matchTable_master_request_tag_dr                                   ,   // 3
//           // master_request_option_dr                                ,   //
//           // master_request_type_dr                                  ,
//           // master_request_flow_dr                                  ,
//            //master_request_local_address_dr                         ,
//            matchTable_master_request_length_dr                                ,   // 36
//           // master_descriptor_src_rdy_dr                            ,
//           // master_descriptor_dst_rdy_dr                            ,
//            matchTable_master_descriptor_tag_dr                                ,
//           //master_descriptor_DESCRIPTOR_LENGTH_FIELD_dr            ,
//           //master_descriptor_DESCRIPTOR_DEVICE_FIELD_dr            ,
//           //master_descriptor_DESCRIPTOR_FLOW_FIELD_dr              ,
//           //master_descriptor_DESCRIPTOR_LAST_TARGET_FLAG_dr        ,
//           matchTable_master_descriptor_DESCRIPTOR_ADDRESS_FIELD_dr[3:0]                  ,    // 4
//            matchTable_master_datain_src_rdy_dr                                ,   // 1
//            matchTable_master_datain_dst_rdy_dr                                ,   // 1
//          //  master_datain_tag_dr                                    ,   
//        //    master_datain_option_dr                                 ,
//            matchTable_master_dataout_src_rdy_dr                               ,   // 1
//            matchTable_master_dataout_dst_rdy_dr                               ,   // 1
//         //   master_dataout_tag_dr                                   ,
//         //   master_dataout_option_dr                                ,   // 1
//            match_table_ready_dr                                     ,  // 1
//           // controller_num_model_kp_dr                              ,   // 
//           // controller_num_obsvd_kp_dr                              ,   // 
//            state_0_dr                                              ,   // 8
//            state_1_dr                                              ,   // 5
//            match_buffer_empty_dr                                   ,   // 1
//            model_kp_count_dr                                       ,   // 16
//            obsvd_kp_count_dr                                       ,   // 16
//            last_batch_dr                                           ,   // 1
//            retire_matches_dr,                                          // 1
//            processing_complete_dr                                      // 1
//        })
//    );
//    
//    ila_128_4096
//    i0_ila_128_4096 (
//        .clk(clk),
//        .probe0({
//			 128'b0		                                            ,          
//            match_table_address_parameters_valid_dr                ,   // 1
//            master_request_dr                                       ,   // 1
//            master_request_ack_dr                                   ,   // 1
//            master_request_complete_dr                              ,   // 1
//            master_request_error_dr                                 ,   // 7
//            master_request_tag_dr                                   ,   // 3
//           // master_request_option_dr                                ,   //
//           // master_request_type_dr                                  ,
//           // master_request_flow_dr                                  ,
//            //master_request_local_address_dr                         ,
//            master_request_length_dr                                ,   // 36
//           // master_descriptor_src_rdy_dr                            ,
//           // master_descriptor_dst_rdy_dr                            ,
//            master_descriptor_tag_dr                                ,
//           //master_descriptor_DESCRIPTOR_LENGTH_FIELD_dr            ,
//           //master_descriptor_DESCRIPTOR_DEVICE_FIELD_dr            ,
//           //master_descriptor_DESCRIPTOR_FLOW_FIELD_dr              ,
//           //master_descriptor_DESCRIPTOR_LAST_TARGET_FLAG_dr        ,
//           master_descriptor_DESCRIPTOR_ADDRESS_FIELD_dr[3:0]                  ,    // 4
//            master_datain_src_rdy_dr                                ,   // 1
//            master_datain_dst_rdy_dr                                ,   // 1
//          //  master_datain_tag_dr                                    ,   
//        //    master_datain_option_dr                                 ,
//            master_dataout_src_rdy_dr                               ,   // 1
//            master_dataout_dst_rdy_dr                               ,   // 1
//         //   master_dataout_tag_dr                                   ,
//         //   master_dataout_option_dr                                ,   // 1
//            match_table_ready_dr                                      // 1
//           // controller_num_model_kp_dr                              ,   // 
//           // controller_num_obsvd_kp_dr                              ,   // 
//        })
//    );
//    
//`endif

endmodule

