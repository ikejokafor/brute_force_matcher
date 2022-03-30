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
// Description:     This module receives data from the controller and places it in a dwc (data width
//        conversion) fifo for DSP pipeline.
//
// Dependencies:    brute_force_matcher_dispatch_unit_dwc_fifo.v
//  
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_dispatch_unit #(
    C_DWC_FIFO_READ_DEPTH = 4096
)(
    clk                                         ,
    rst                                         ,

    dispatch_unit_datain_valid                  ,
    dispatch_unit_datain                        ,
    begin_load_fifo                             ,
    descriptor_buffer_select                    ,
    total_keypoint_load_count                   ,
    dispatch_unit_done_buffer_load              ,
    buffer_total_kp_load_cnt                    ,

    descriptor_buffer_load_data                 ,
    descriptor_buffer_load_info                 ,
    descriptor_buffer_load_valid                ,
    sec_buffer_not_loading                     
 );
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
 
 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // LocalParams
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    localparam ST_IDLE              = 2'b01;
    localparam ST_LOAD_BUFFER       = 2'b10;
    
    localparam C_DISPATCH_UNIT_DATAIN_WIDTH = `DATAIN_WIDTH + `DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH;
    localparam C_BUFFER_DATA_WIDTH          = `DESCRIPTOR_ELEMENT_WIDTH * `SIMD;
    localparam C_DWC_DATAIN_W_WIDTH         = `NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH;
    localparam C_DWC_FIFO_DATAIN_WIDTH      = `DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH + (`NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH);
    localparam C_DWC_DATAOUT_WIDTH          = (`SIMD / `NUM_DESC_PER_BUS) * (`DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH + (`NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH));
    localparam C_DWC_FIFO_COUNTER_WIDTH     = clog2(`SIMD / `NUM_DESC_PER_BUS);
    localparam C_DWC_FIFO_COUNTER_END       = `SIMD / `NUM_DESC_PER_BUS;
 

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Ouputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                                               clk;
    input                                               rst;
    
    input       [C_DISPATCH_UNIT_DATAIN_WIDTH - 1 :0]   dispatch_unit_datain;
    input                                               dispatch_unit_datain_valid;
    input                                               begin_load_fifo;
    input       [                                1:0]   descriptor_buffer_select;
    output                                              dispatch_unit_done_buffer_load;
    input       [                               15:0]   total_keypoint_load_count;
    output      [                               15:0]   buffer_total_kp_load_cnt;

    output      [          C_BUFFER_DATA_WIDTH - 1:0]   descriptor_buffer_load_data;
    output      [       `DESCRIPTOR_INFO_WIDTH - 1:0]   descriptor_buffer_load_info;
    output reg  [                                1:0]   descriptor_buffer_load_valid;
    input                                               sec_buffer_not_loading;
    
 
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------      
    reg  [                           1:0]   state;
    reg  [    C_DWC_FIFO_COUNTER_WIDTH:0]   dwc_fifo_counter;
    wire [    C_DWC_DATAIN_W_WIDTH - 1:0]   dwc_fifo_datain_w;
    wire [ C_DWC_FIFO_DATAIN_WIDTH - 1:0]   dwc_fifo_datain;
    reg  [     C_DWC_DATAOUT_WIDTH - 1:0]   dwc_fifo_dataout_r;
    wire [     C_DWC_DATAOUT_WIDTH - 1:0]   dwc_fifo_dataout;
    reg  [                          15:0]   dwc_fifo_rd_data_count;
    reg  [                          15:0]   total_keypoint_load_count_r;
    reg  [                           1:0]   descriptor_buffer_load_valid_r;
    wire                                    dwc_fifo_dataout_valid;
    reg                                     dispatch_unit_done_buffer_load_r;
 

    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Module Instaniations /  Generate Statements
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    genvar i;
    generate
        for(i = 0; i < `NUM_DESC_PER_BUS; i = i + 1) begin
            assign dwc_fifo_datain_w[(i * `DESCRIPTOR_ELEMENT_WIDTH) +: `DESCRIPTOR_ELEMENT_WIDTH] 
                = dispatch_unit_datain[(i * 2 *`DESCRIPTOR_ELEMENT_WIDTH) +: `DESCRIPTOR_ELEMENT_WIDTH];
        end
        for(i = 0; i < (`SIMD / `NUM_DESC_PER_BUS); i = i + 1) begin
            assign descriptor_buffer_load_data[(i * `NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH) +: (`NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH)] 
                = dwc_fifo_dataout_r[(i * (`DESCRIPTOR_INFO_CELL_ID_WIDTH + `NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH)) +: (`NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH)];
        end
    endgenerate
 
 
    // BEGIN Main State transistion logic ----------------------------------------------------------------------------------------------------------------
    assign dwc_fifo_datain                                              = {dispatch_unit_datain[`DISPATCH_UNIT_DATAIN_CELL_ID_FIELD], dwc_fifo_datain_w};
    assign buffer_total_kp_load_cnt                                     = total_keypoint_load_count_r;
    assign descriptor_buffer_load_info[`DESCRIPTOR_INFO_CELL_ID_FIELD]  = (descriptor_buffer_load_valid_r[`SEC_BUFFER_SELECT_IDX]) ? dwc_fifo_dataout[`DISPATCH_UNIT_DATAOUT_CELL_ID_FIELD] : 0;
    assign descriptor_buffer_load_info[`DESCRIPTOR_FIELD0]              = 0; 
    assign dwc_fifo_dataout                                             = dwc_fifo_dataout_r;
    assign dwc_fifo_dataout_valid                                       = (dwc_fifo_counter == C_DWC_FIFO_COUNTER_END);
    assign dispatch_unit_done_buffer_load                               = dispatch_unit_done_buffer_load_r;

    always@(posedge clk) begin
        if(rst) begin
            dwc_fifo_counter    <= 0;
        end else begin
            if(dispatch_unit_datain_valid) begin
                dwc_fifo_counter  <= dwc_fifo_counter + 1;
            end
            if(dwc_fifo_counter == C_DWC_FIFO_COUNTER_END) begin
                dwc_fifo_counter    <= 0;
            end
        end
    end

    always@(posedge clk) begin
        if(rst) begin
            total_keypoint_load_count_r                         <= 0;
            descriptor_buffer_load_valid_r                      <= 0;
            descriptor_buffer_load_valid                        <= 0;
            dwc_fifo_rd_data_count                              <= 0;
            dispatch_unit_done_buffer_load_r                    <= 0;
            state                                               <= ST_IDLE;
        end else begin
            dispatch_unit_done_buffer_load_r                    <= 0;
            descriptor_buffer_load_valid                        <= 0;
            case(state)
                ST_IDLE: begin
                    if(begin_load_fifo) begin
                        total_keypoint_load_count_r                             <= total_keypoint_load_count;
                        dwc_fifo_rd_data_count                                  <= total_keypoint_load_count;
                        descriptor_buffer_load_valid_r                          <= descriptor_buffer_select;
                        state                                                   <= ST_LOAD_BUFFER;
                    end
                end
                ST_LOAD_BUFFER: begin
                    if(dispatch_unit_datain_valid) begin
                        dwc_fifo_dataout_r[dwc_fifo_counter * C_DWC_FIFO_DATAIN_WIDTH +: C_DWC_FIFO_DATAIN_WIDTH]     <= dwc_fifo_datain;
                    end
                    if(dwc_fifo_dataout_valid) begin
                        descriptor_buffer_load_valid    <= descriptor_buffer_load_valid_r;
                        dwc_fifo_rd_data_count          <= dwc_fifo_rd_data_count - 1;
                    end
                    if(dwc_fifo_rd_data_count == 0 && descriptor_buffer_load_valid_r[`SEC_BUFFER_SELECT_IDX] && sec_buffer_not_loading) begin
                        dispatch_unit_done_buffer_load_r    <= 1;
                        state                               <= ST_IDLE;
                    end else if(dwc_fifo_rd_data_count == 0 && descriptor_buffer_load_valid_r[`PRIM_BUFFER_SELECT_IDX]) begin
                        dispatch_unit_done_buffer_load_r    <= 1;
                        state                               <= ST_IDLE;
                    end
                end
                default: begin

                end
            endcase
        end 
    end
    // END Main State transition logic --------------------------------------------------------------------------------------------------------------
 

 `ifdef SIMULATION

    string state_s;
    always@(state) begin 
        case(state) 
            ST_IDLE             : state_s = "ST_IDLE"; 
            ST_LOAD_BUFFER      : state_s = "ST_LOAD_BUFFER";
        endcase
    end
    
    int numObsvdKP;
    always@(posedge clk) begin
        if(rst) begin
            numObsvdKP <= 0;
        end
        if(i0_brute_force_matcher_controller.init_keypoint_engine) begin
            numObsvdKP <= 0;
        end
        if(descriptor_buffer_load_valid && descriptor_buffer_load_valid_r[1]) begin
            numObsvdKP <= numObsvdKP + 1;
        end
    end
 `endif
 
 /*
 `ifdef DEBUG
  (* mark_debug = "true" *) reg  [1:0] state_dr;
  assign state_o = state;

 always@(posedge clk) begin
    state_dr <= state;
 end
 
    ila_128_4096
    i0_ila_128_4096 (
        .clk(clk),
        .probe0({
			128'b0,
            state_dr,
        })
    );
    `endif
 */
 
endmodule

