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
// Description:   Controls the writing of the secondary descriptor buffer  as well as signifies
//                if data is currently present within the buffer.
//
// Dependencies:     
//    
// Revision:
//
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module brute_force_matcher_secondary_buffer_control #(
    parameter C_SEC_DESC_FIFO_DEPTH     = 32
) (
    clk                   ,
    rst                   ,
    queue_depleted        ,
    queue_space_available ,
    fifo_count            ,

    keypoint_advance      ,
    descriptor_valid      ,
    buffer_load_init      ,
    buffer_load_valid     ,
    buffer_load_enable     
);                          
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Includes
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    `include "math.vh"
    `include "brute_force_matcher_defines.vh"
    `include "soc_it_defs.vh"
  
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Local Params
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    localparam ST_UNOCCUPIED             = 4'b0001;
    localparam ST_OCCUPIED               = 4'b0010;
    localparam ST_INIT_BUFFER            = 4'b0100;
    localparam ST_LOAD_FROM_FIFO         = 4'b1000;

    localparam C_NUM_ELEMENTS_PER_KP        =   (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD);
    localparam C_NUM_ELEMENTS_PER_KP_CHUNK  =   (2 * (`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD));
  
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Inputs / Outputs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    input                       clk;
    input                       rst;
    output                      queue_depleted;
    output                      queue_space_available;
    input   [17:0  ]            fifo_count;
    input                       keypoint_advance;
    output                      descriptor_valid;
    output                      buffer_load_init;
    input                       buffer_load_valid;
    output                      buffer_load_enable;
  
  
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wires / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
    reg [3:0]                                   state;
    reg [clog2(C_SEC_DESC_FIFO_DEPTH) - 1:0]    load_count;
  
    // BEGIN Buffer control logic -------------------------------------------------------------------------------------------------------------------
    assign descriptor_valid     = (state == ST_OCCUPIED);
    assign queue_depleted       = (state == ST_UNOCCUPIED);
    assign queue_space_available = (C_SEC_DESC_FIFO_DEPTH - fifo_count) >= C_NUM_ELEMENTS_PER_KP_CHUNK;
    assign buffer_load_init      = (state == ST_INIT_BUFFER);
    assign buffer_load_enable    = (state == ST_LOAD_FROM_FIFO);
  
  
    always@(posedge clk) begin
        if(state == ST_INIT_BUFFER || rst) begin
            load_count  <= {clog2(C_SEC_DESC_FIFO_DEPTH){1'b0}};
        end else if(state == ST_LOAD_FROM_FIFO && buffer_load_valid) begin
            load_count  <= load_count + 1'b1;
        end
    end
  
    always@(posedge clk) begin
        if(rst) begin
            state                 <= ST_UNOCCUPIED;          
        end else begin
            case(state)
                ST_UNOCCUPIED: begin
                    if(fifo_count >= C_NUM_ELEMENTS_PER_KP) begin  // have atleast 1 whole keypoint in sync fifo
                        state <= ST_INIT_BUFFER;
                    end
                end
                ST_INIT_BUFFER: begin
                    state <= ST_LOAD_FROM_FIFO;
                end
                ST_LOAD_FROM_FIFO: begin
                    if(load_count == (C_NUM_ELEMENTS_PER_KP - 1)) begin  // loaded 1 keypoint
                        state                 <= ST_OCCUPIED;
                    end
                end
                ST_OCCUPIED: begin
                    if(keypoint_advance && (fifo_count < C_NUM_ELEMENTS_PER_KP)) begin  // next keypoint and atleast less than 1 keypoint is present
                        state <= ST_UNOCCUPIED;
                    end else if(keypoint_advance && (fifo_count >= C_NUM_ELEMENTS_PER_KP)) begin  // next keypoint and atleast 1 keypoint is present 
                        state <= ST_INIT_BUFFER;
                    end
                end
                default: begin
    
                end
            endcase
        end
    end
    // END Buffer control logic ---------------------------------------------------------------------------------------------------------------------
  
  
  `ifdef SIMULATION
    int obsvd_kp_count;
    always@(posedge clk) begin
        if(rst || i0_brute_force_matcher_controller.force_rst) begin
            obsvd_kp_count <= 0;
        end else begin
            if(state == ST_INIT_BUFFER) begin
                obsvd_kp_count <= obsvd_kp_count + 1;
            end
        end
    end
  
    string state_s;
    always@(state) begin 
      case(state) 
        ST_UNOCCUPIED     : state_s = "ST_UNOCCUPIED";
        ST_INIT_BUFFER    : state_s = "ST_INIT_BUFFER";
        ST_LOAD_FROM_FIFO : state_s = "ST_LOAD_FROM_FIFO";
        ST_OCCUPIED       : state_s = "ST_OCCUPIED";
      endcase
     end
  `endif

  /*
  `ifdef DEBUG
  (* mark_debug = "true" *) reg [3:0] state_dr;
  
  always@(posedge clk) begin
    state_dr <= state;
  end
  
  ila_128_4096
  i0_ila_128_4096 (
    .clk(clk),
    .probe0  ({
		128'b0,
        state_dr
        })
  );
  `endif
*/  
  
endmodule
