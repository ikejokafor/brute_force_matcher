///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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
// Additional Comments:
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

`ifndef __BRUTE_FORCE_MATCHER_DEFINES__
`define __BRUTE_FORCE_MATCHER_DEFINES__

// for(all observed keypoints)
//      for(all model keypoints)
//         get best match

//---------------------------------------------------------------------------------------------------------------------------------------------------   
// MSC definitions 
//---------------------------------------------------------------------------------------------------------------------------------------------------
`define NUM_ENGINES                         16'd4
`define MAX_NUM_KEYPOINTS                   16'd8192
`define MAX_MODEL_KP                        16'd2048
`define DATAIN_WIDTH                        128
`define KEYPOINT_ID_WIDTH                   clog2(`MAX_NUM_KEYPOINTS)
`define DESCRIPTOR_ELEMENT_WIDTH            16'd16
`define DSP_OUTPUT_WIDTH                    16'd48
`define SQRT_OUTPUT_WIDTH                   16'd32
`define FLOATING_NUM_PREC                   32
`define FLOAT_PREC_WIDTH                    32
`define FIXED_INT_WIDTH                     2
`define FIXED_FRAC_WIDTH                    14
`define FIXED_NUM_WIDTH                     (`FIXED_INT_WIDTH + `FIXED_FRAC_WIDTH)
`define SEC_DESCRIPTOR_TABLE_DEPTH          16'd1
`define PRIM_DESCRIPTOR_TABLE_DEPTH         `MAX_MODEL_KP
`define DSP_LATENCY                         16'd4
`define SQRT_LATENCY                        16'd13
`define SIMD                                16'd64
`define NUM_MAST_INF_CLIENTS                (16'd2 + `NUM_ENGINES * 2)
`define MAX_NUM_CELLS                       16'd2048   // based of off 1920x1080 image and 32x32 cell size
`define BITS_PER_BYTE                       16'd8
`define NUM_DESC_PER_BUS                    16'd4
`define BYTE_PER_ELEMENT                    16'd4
`define SEC_BUFFER_SELECT_IDX               1'd1
`define PRIM_BUFFER_SELECT_IDX              1'd0

`ifdef DESCRIPTOR_SIZE_EXTENDED                                 
`define NUM_ELEMENTS_PER_DESCRIPTOR         16'd128
`else                                                    
`define NUM_ELEMENTS_PER_DESCRIPTOR         16'd64
`endif 

//--------------------------------------------------------------------------------------------------------------------------------------------------
// DISPATCH UNIT CELL ID FIELDS
//--------------------------------------------------------------------------------------------------------------------------------------------------
`define DISPATCH_UNIT_DATAIN_CELL_ID_WIDTH         16
`define DISPATCH_UNIT_DATAIN_CELL_ID_LOW           (`NUM_DESC_PER_BUS * 2 * `DESCRIPTOR_ELEMENT_WIDTH)
`define DISPATCH_UNIT_DATAIN_CELL_ID_HIGH          (`DISPATCH_UNIT_DATAIN_CELL_ID_LOW + `DISPATCH_UNIT_DATAIN_CELL_ID_WIDTH - 1)
`define DISPATCH_UNIT_DATAIN_CELL_ID_FIELD         (`DISPATCH_UNIT_DATAIN_CELL_ID_HIGH):(`DISPATCH_UNIT_DATAIN_CELL_ID_LOW)

`define DISPATCH_UNIT_DATAOUT_CELL_ID_WIDTH        16
`define DISPATCH_UNIT_DATAOUT_CELL_ID_LOW          (`NUM_DESC_PER_BUS * `DESCRIPTOR_ELEMENT_WIDTH)
`define DISPATCH_UNIT_DATAOUT_CELL_ID_HIGH         (`DISPATCH_UNIT_DATAOUT_CELL_ID_LOW + `DISPATCH_UNIT_DATAOUT_CELL_ID_WIDTH - 1)
`define DISPATCH_UNIT_DATAOUT_CELL_ID_FIELD        (`DISPATCH_UNIT_DATAOUT_CELL_ID_HIGH):(`DISPATCH_UNIT_DATAOUT_CELL_ID_LOW)


//--------------------------------------------------------------------------------------------------------------------------------------------------
// CONMAND DATA FIELDS
//--------------------------------------------------------------------------------------------------------------------------------------------------
// COMMAND 0
`define CMD_DATA_MODEL_DATA_ADDR_WIDTH                   64
`define CMD_DATA_MODEL_DATA_ADDR_FIELD_LOW               0
`define CMD_DATA_MODEL_DATA_ADDR_FIELD_HIGH              (`CMD_DATA_MODEL_DATA_ADDR_FIELD_LOW + `CMD_DATA_MODEL_DATA_ADDR_WIDTH - 1)
`define CMD_DATA_MODEL_DATA_ADDR_FIELD                   (`CMD_DATA_MODEL_DATA_ADDR_FIELD_HIGH):(`CMD_DATA_MODEL_DATA_ADDR_FIELD_LOW)

`define CMD_DATA_CELL_DATA_ADDR_WIDTH                    64
`define CMD_DATA_CELL_DATA_ADDR_FIELD_LOW                (`CMD_DATA_MODEL_DATA_ADDR_FIELD_HIGH + 1)
`define CMD_DATA_CELL_DATA_ADDR_FIELD_HIGH               (`CMD_DATA_CELL_DATA_ADDR_FIELD_LOW + `CMD_DATA_CELL_DATA_ADDR_WIDTH - 1)
`define CMD_DATA_CELL_DATA_ADDR_FIELD                    (`CMD_DATA_CELL_DATA_ADDR_FIELD_HIGH):(`CMD_DATA_CELL_DATA_ADDR_FIELD_LOW)

// COMMAND 1      
`define CMD_DATA_MATCH_TABLE_INFO_ADDR_WIDTH              64                                 
`define CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD_LOW          0                                 
`define CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD_HIGH         (`CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD_LOW + `CMD_DATA_MATCH_TABLE_INFO_ADDR_WIDTH - 1)                                 
`define CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD              (`CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD_HIGH):(`CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD_LOW)                                 

`define CMD_DATA_CELL_DATA_LENGTH_WIDTH                    32
`define CMD_DATA_CELL_DATA_LENGTH_FIELD_LOW                (`CMD_DATA_MATCH_TABLE_INFO_ADDR_FIELD_HIGH + 1)
`define CMD_DATA_CELL_DATA_LENGTH_FIELD_HIGH               (`CMD_DATA_CELL_DATA_LENGTH_FIELD_LOW + `CMD_DATA_CELL_DATA_LENGTH_WIDTH - 1)
`define CMD_DATA_CELL_DATA_LENGTH_FIELD                    (`CMD_DATA_CELL_DATA_LENGTH_FIELD_HIGH):(`CMD_DATA_CELL_DATA_LENGTH_FIELD_LOW)

`define CMD_DATA_MODEL_DATA_LENGTH_WIDTH                   32
`define CMD_DATA_MODEL_DATA_LENGTH_FIELD_LOW               (`CMD_DATA_CELL_DATA_LENGTH_FIELD_HIGH + 1)
`define CMD_DATA_MODEL_DATA_LENGTH_FIELD_HIGH              (`CMD_DATA_MODEL_DATA_LENGTH_FIELD_LOW + `CMD_DATA_MODEL_DATA_LENGTH_WIDTH - 1)
`define CMD_DATA_MODEL_DATA_LENGTH_FIELD                   (`CMD_DATA_MODEL_DATA_LENGTH_FIELD_HIGH):(`CMD_DATA_MODEL_DATA_LENGTH_FIELD_LOW)

// COMMAND 2     
`define CMD_DATA_NUM_CELLS_WIDTH                           64
`define CMD_DATA_NUM_CELLS_LOW                             0
`define CMD_DATA_NUM_CELLS_HIGH                            (`CMD_DATA_NUM_CELLS_LOW + `CMD_DATA_NUM_CELLS_WIDTH - 1)
`define CMD_DATA_NUM_CELLS_FIELD                           (`CMD_DATA_NUM_CELLS_HIGH):(`CMD_DATA_NUM_CELLS_LOW)

`define CMD_DATA_OBSERVED_KP_COUNT_WIDTH                   16
`define CMD_DATA_OBSERVED_KP_COUNT_FIELD_LOW               (`CMD_DATA_NUM_CELLS_HIGH + 1)
`define CMD_DATA_OBSERVED_KP_COUNT_FIELD_HIGH              (`CMD_DATA_OBSERVED_KP_COUNT_FIELD_LOW + `CMD_DATA_OBSERVED_KP_COUNT_WIDTH - 1)
`define CMD_DATA_OBSERVED_KP_COUNT_FIELD                   (`CMD_DATA_OBSERVED_KP_COUNT_FIELD_HIGH):(`CMD_DATA_OBSERVED_KP_COUNT_FIELD_LOW)

`define CMD_DATA_MODEL_KP_COUNT_WIDTH                      16
`define CMD_DATA_MODEL_KP_COUNT_FIELD_LOW                  (`CMD_DATA_OBSERVED_KP_COUNT_FIELD_HIGH + 1)
`define CMD_DATA_MODEL_KP_COUNT_FIELD_HIGH                 (`CMD_DATA_MODEL_KP_COUNT_FIELD_LOW + `CMD_DATA_MODEL_KP_COUNT_WIDTH - 1)
`define CMD_DATA_MODEL_KP_COUNT_FIELD                      (`CMD_DATA_MODEL_KP_COUNT_FIELD_HIGH):(`CMD_DATA_MODEL_KP_COUNT_FIELD_LOW)

// i_COMMAND    
`define I_CMD_DATA_MATCH_TABLE_ADDR_WIDTH                    64
`define I_CMD_DATA_MATCH_TABLE_ADDR_LOW                      0
`define I_CMD_DATA_MATCH_TABLE_ADDR_HIGH                     (`I_CMD_DATA_MATCH_TABLE_ADDR_LOW + `I_CMD_DATA_MATCH_TABLE_ADDR_WIDTH - 1)
`define I_CMD_DATA_MATCH_TABLE_ADDR_FIELD                    (`I_CMD_DATA_MATCH_TABLE_ADDR_HIGH):(`I_CMD_DATA_MATCH_TABLE_ADDR_LOW)

`define I_CMD_DATA_OBSERVED_KP_COUNT_WIDTH                   32
`define I_CMD_DATA_OBSERVED_KP_COUNT_FIELD_LOW               (`I_CMD_DATA_MATCH_TABLE_ADDR_HIGH + 1)
`define I_CMD_DATA_OBSERVED_KP_COUNT_FIELD_HIGH              (`I_CMD_DATA_OBSERVED_KP_COUNT_FIELD_LOW + `I_CMD_DATA_OBSERVED_KP_COUNT_WIDTH - 1)
`define I_CMD_DATA_OBSERVED_KP_COUNT_FIELD                   (`I_CMD_DATA_OBSERVED_KP_COUNT_FIELD_HIGH):(`I_CMD_DATA_OBSERVED_KP_COUNT_FIELD_LOW)

`define I_CMD_DATA_MATCH_TABLE_LENGTH_WIDTH                   32
`define I_CMD_DATA_MATCH_TABLE_LENGTH_FIELD_LOW               (`I_CMD_DATA_OBSERVED_KP_COUNT_FIELD_HIGH + 1)
`define I_CMD_DATA_MATCH_TABLE_LENGTH_FIELD_HIGH              (`I_CMD_DATA_MATCH_TABLE_LENGTH_FIELD_LOW + `I_CMD_DATA_MATCH_TABLE_LENGTH_WIDTH - 1)
`define I_CMD_DATA_MATCH_TABLE_LENGTH_FIELD                   (`I_CMD_DATA_MATCH_TABLE_LENGTH_FIELD_HIGH):(`I_CMD_DATA_MATCH_TABLE_LENGTH_FIELD_LOW)


//---------------------------------------------------------------------------------------------------------------------------------------------------   
// Descriptor input definitions 
//---------------------------------------------------------------------------------------------------------------------------------------------------
`define DESCRIPTOR_INPUT_HEADER_LAP_WIDTH           32
`define DESCRIPTOR_INPUT_HEADER_LAP_LOW             0
`define DESCRIPTOR_INPUT_HEADER_LAP_HIGH            (`DESCRIPTOR_INPUT_HEADER_LAP_LOW + `DESCRIPTOR_INPUT_HEADER_LAP_WIDTH - 1)
`define DESCRIPTOR_INPUT_HEADER_LAP_FIELD           (`DESCRIPTOR_INPUT_HEADER_LAP_HIGH):(`DESCRIPTOR_INPUT_HEADER_LAP_LOW)

`define DESCRIPTOR_INPUT_HEADER_SCALE_WIDTH         32
`define DESCRIPTOR_INPUT_HEADER_SCALE_LOW           (`DESCRIPTOR_INPUT_HEADER_LAP_HIGH + 1)
`define DESCRIPTOR_INPUT_HEADER_SCALE_HIGH          (`DESCRIPTOR_INPUT_HEADER_SCALE_LOW + `DESCRIPTOR_INPUT_HEADER_SCALE_WIDTH - 1)
`define DESCRIPTOR_INPUT_HEADER_SCALE_FIELD         (`DESCRIPTOR_INPUT_HEADER_SCALE_HIGH):(`DESCRIPTOR_INPUT_HEADER_SCALE_LOW)

`define DESCRIPTOR_INPUT_HEADER_ID_WIDTH            16
`define DESCRIPTOR_INPUT_HEADER_ID_LOW              (`DESCRIPTOR_INPUT_HEADER_SCALE_HIGH + 1)
`define DESCRIPTOR_INPUT_HEADER_ID_HIGH             (`DESCRIPTOR_INPUT_HEADER_ID_LOW + `DESCRIPTOR_INPUT_HEADER_ID_WIDTH - 1)
`define DESCRIPTOR_INPUT_HEADER_ID_FIELD            (`DESCRIPTOR_INPUT_HEADER_ID_HIGH):(`DESCRIPTOR_INPUT_HEADER_ID_LOW)

`define DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH       16
`define DESCRIPTOR_INPUT_HEADER_CELL_ID_LOW         (`DESCRIPTOR_INPUT_HEADER_ID_HIGH + 1)
`define DESCRIPTOR_INPUT_HEADER_CELL_ID_HIGH        (`DESCRIPTOR_INPUT_HEADER_CELL_ID_LOW + `DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH - 1)
`define DESCRIPTOR_INPUT_HEADER_CELL_ID_FIELD       (`DESCRIPTOR_INPUT_HEADER_CELL_ID_HIGH):(`DESCRIPTOR_INPUT_HEADER_CELL_ID_LOW)

`define DESCRIPTOR_INPUT_HEADER_Y_WIDTH             16
`define DESCRIPTOR_INPUT_HEADER_Y_LOW               (`DESCRIPTOR_INPUT_HEADER_CELL_ID_HIGH + 1)
`define DESCRIPTOR_INPUT_HEADER_Y_HIGH              (`DESCRIPTOR_INPUT_HEADER_Y_LOW + `DESCRIPTOR_INPUT_HEADER_Y_WIDTH - 1)
`define DESCRIPTOR_INPUT_HEADER_Y_FIELD             (`DESCRIPTOR_INPUT_HEADER_Y_HIGH):(`DESCRIPTOR_INPUT_HEADER_Y_LOW)

`define DESCRIPTOR_INPUT_HEADER_X_WIDTH             16
`define DESCRIPTOR_INPUT_HEADER_X_LOW               (`DESCRIPTOR_INPUT_HEADER_Y_HIGH + 1)
`define DESCRIPTOR_INPUT_HEADER_X_HIGH              (`DESCRIPTOR_INPUT_HEADER_X_LOW + `DESCRIPTOR_INPUT_HEADER_X_WIDTH - 1)
`define DESCRIPTOR_INPUT_HEADER_X_FIELD             (`DESCRIPTOR_INPUT_HEADER_X_HIGH):(`DESCRIPTOR_INPUT_HEADER_X_LOW)

`define DESCRIPTOR_INPUT_HEADER_WIDTH               ((`DESCRIPTOR_INPUT_HEADER_LAP_WIDTH)     + \
                                                     (`DESCRIPTOR_INPUT_HEADER_SCALE_WIDTH)   + \
                                                     (`DESCRIPTOR_INPUT_HEADER_ID_WIDTH)      + \
                                                     (`DESCRIPTOR_INPUT_HEADER_CELL_ID_WIDTH) + \
                                                     (`DESCRIPTOR_INPUT_HEADER_Y_WIDTH)       + \
                                                     (`DESCRIPTOR_INPUT_HEADER_X_WIDTH))   

//---------------------------------------------------------------------------------------------------------------------------------------------------   
// Match Table info definitions 
//---------------------------------------------------------------------------------------------------------------------------------------------------
`define MATCH_TABLE_INFO_OUTPUT_WIDTH               16'd32
`define MATCH_TABLE_ENTRIES_PER_BUS                 16'd4
`define MATCH_TABLE_INFO_OUTPUT_SIZE                ((`MATCH_TABLE_INFO_OUTPUT_WIDTH / `BITS_PER_BYTE) * `MATCH_TABLE_ENTRIES_PER_BUS)


//---------------------------------------------------------------------------------------------------------------------------------------------------   
// BEGIN Descriptor info definitions 
//---------------------------------------------------------------------------------------------------------------------------------------------------
//
//  -------------------------------------------------------------------------------------------------------
// | DESC_INFO_TYPE | DESC_INFO_KEYPOINT_ID | DESC_INFO_LAST_FLAG | DESC_INFO_FIRST_FLAG | DESC_INFO_INDEX |
//  -------------------------------------------------------------------------------------------------------
// Type : 
//         Designates if the corresponding descriptor is for a QUERY (0) or MODEL (1) keypoint.
// KeypointID :
//         The unique ID to identify the keypoint for which this descriptor element belongs.
// LastFlag :
//         Signifies that the descriptor element is the last of the current keypoint (i.e. index == 63 
//         or index == 127 for non-extended and extended descriptors respectively).
// FirstFlag :
//         Signifies that the descriptor element is the first of the current keypoint (i.e. index == 0)
// Index :
//         The descriptor element index for which the current info is associated. (0-63 and 0-127 for non-extended
//         and extended descriptors respectively).
//---------------------------------------------------------------------------------------------------------------------------------------------------

`define DESCRIPTOR_INFO_TYPE_QUERY                       1'b0
`define DESCRIPTOR_INFO_TYPE_MODEL                       1'b1

`define DESCRIPTOR_INFO_DESCRIPTOR_INDEX_WIDTH           (`max(clog2(`NUM_ELEMENTS_PER_DESCRIPTOR / `SIMD), 1))
`define DESCRIPTOR_INFO_DESCRIPTOR_INDEX_LOW             0
`define DESCRIPTOR_INFO_DESCRIPTOR_INDEX_HIGH            (`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_LOW + `DESCRIPTOR_INFO_DESCRIPTOR_INDEX_WIDTH - 1)
`define DESCRIPTOR_INFO_DESCRIPTOR_INDEX_FIELD           (`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_HIGH):(`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_LOW)

`define DESCRIPTOR_INFO_DESCRIPTOR_FIRST_WIDTH           1
`define DESCRIPTOR_INFO_DESCRIPTOR_FIRST_LOW             (`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_HIGH + 1)
`define DESCRIPTOR_INFO_DESCRIPTOR_FIRST_HIGH            (`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_LOW + `DESCRIPTOR_INFO_DESCRIPTOR_FIRST_WIDTH - 1)
`define DESCRIPTOR_INFO_DESCRIPTOR_FIRST_FLAG            (`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_HIGH):(`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_LOW)

`define DESCRIPTOR_INFO_DESCRIPTOR_LAST_WIDTH            1
`define DESCRIPTOR_INFO_DESCRIPTOR_LAST_LOW              (`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_HIGH + 1)
`define DESCRIPTOR_INFO_DESCRIPTOR_LAST_HIGH             (`DESCRIPTOR_INFO_DESCRIPTOR_LAST_LOW + `DESCRIPTOR_INFO_DESCRIPTOR_LAST_WIDTH - 1)
`define DESCRIPTOR_INFO_DESCRIPTOR_LAST_FLAG             (`DESCRIPTOR_INFO_DESCRIPTOR_LAST_HIGH):(`DESCRIPTOR_INFO_DESCRIPTOR_LAST_LOW)

`define DESCRIPTOR_INFO_KEYPOINT_FIRST_WIDTH             1
`define DESCRIPTOR_INFO_KEYPOINT_FIRST_LOW               (`DESCRIPTOR_INFO_DESCRIPTOR_LAST_HIGH + 1)
`define DESCRIPTOR_INFO_KEYPOINT_FIRST_HIGH              (`DESCRIPTOR_INFO_KEYPOINT_FIRST_LOW + `DESCRIPTOR_INFO_KEYPOINT_FIRST_WIDTH - 1)
`define DESCRIPTOR_INFO_KEYPOINT_FIRST_FLAG              (`DESCRIPTOR_INFO_KEYPOINT_FIRST_HIGH):(`DESCRIPTOR_INFO_KEYPOINT_FIRST_LOW)

`define DESCRIPTOR_INFO_KEYPOINT_LAST_WIDTH              1
`define DESCRIPTOR_INFO_KEYPOINT_LAST_LOW                (`DESCRIPTOR_INFO_KEYPOINT_FIRST_HIGH + 1)
`define DESCRIPTOR_INFO_KEYPOINT_LAST_HIGH               (`DESCRIPTOR_INFO_KEYPOINT_LAST_LOW + `DESCRIPTOR_INFO_KEYPOINT_LAST_WIDTH - 1)
`define DESCRIPTOR_INFO_KEYPOINT_LAST_FLAG               (`DESCRIPTOR_INFO_KEYPOINT_LAST_HIGH):(`DESCRIPTOR_INFO_KEYPOINT_LAST_LOW)

`define DESCRIPTOR_INFO_KEYPOINT_ID_WIDTH                (clog2(`MAX_NUM_KEYPOINTS))
`define DESCRIPTOR_INFO_KEYPOINT_ID_LOW                  (`DESCRIPTOR_INFO_KEYPOINT_LAST_HIGH + 1)
`define DESCRIPTOR_INFO_KEYPOINT_ID_HIGH                 (`DESCRIPTOR_INFO_KEYPOINT_ID_LOW + `DESCRIPTOR_INFO_KEYPOINT_ID_WIDTH - 1)
`define DESCRIPTOR_INFO_KEYPOINT_ID_FIELD                (`DESCRIPTOR_INFO_KEYPOINT_ID_HIGH):(`DESCRIPTOR_INFO_KEYPOINT_ID_LOW)

`define DESCRIPTOR_INFO_TYPE_WIDTH                       1
`define DESCRIPTOR_INFO_TYPE_LOW                         (`DESCRIPTOR_INFO_KEYPOINT_ID_HIGH + 1)
`define DESCRIPTOR_INFO_TYPE_HIGH                        (`DESCRIPTOR_INFO_TYPE_LOW + `DESCRIPTOR_INFO_TYPE_WIDTH - 1)
`define DESCRIPTOR_INFO_TYPE_FIELD                       (`DESCRIPTOR_INFO_TYPE_HIGH):(`DESCRIPTOR_INFO_TYPE_LOW)

`define DESCRIPTOR_INFO_CELL_ID_WIDTH                    16
`define DESCRIPTOR_INFO_CELL_ID_LOW                      (`DESCRIPTOR_INFO_TYPE_HIGH + 1)
`define DESCRIPTOR_INFO_CELL_ID_HIGH                     (`DESCRIPTOR_INFO_CELL_ID_LOW + `DESCRIPTOR_INFO_CELL_ID_WIDTH - 1)
`define DESCRIPTOR_INFO_CELL_ID_FIELD                    (`DESCRIPTOR_INFO_CELL_ID_HIGH):(`DESCRIPTOR_INFO_CELL_ID_LOW)

`define DESCRIPTOR_INFO_WIDTH                           ((`DESCRIPTOR_INFO_DESCRIPTOR_INDEX_WIDTH)  + \
                                                         (`DESCRIPTOR_INFO_DESCRIPTOR_FIRST_WIDTH)  + \
                                                         (`DESCRIPTOR_INFO_DESCRIPTOR_LAST_WIDTH)   + \
                                                         (`DESCRIPTOR_INFO_KEYPOINT_FIRST_WIDTH)    + \
                                                         (`DESCRIPTOR_INFO_KEYPOINT_LAST_WIDTH)     + \
                                                         (`DESCRIPTOR_INFO_KEYPOINT_ID_WIDTH)       + \
                                                         (`DESCRIPTOR_INFO_TYPE_WIDTH)              + \
                                                         (`DESCRIPTOR_INFO_CELL_ID_WIDTH))         
   

`define DESCRIPTOR_INFO_LOW                       0                              
`define DESCRIPTOR_INFO_HIGH                      (`DESCRIPTOR_INFO_LOW + `DESCRIPTOR_INFO_WIDTH - 1)
`define DESCRIPTOR_INFO_FIELD                     (`DESCRIPTOR_INFO_HIGH):(`DESCRIPTOR_INFO_LOW)

`define DESCRIPTOR_SIMD_ELEMENT_WIDTH             (`SIMD * `DESCRIPTOR_ELEMENT_WIDTH)
`define DESCRIPTOR_SIMD_ELEMENT_LOW               (`DESCRIPTOR_INFO_HIGH + 1)
`define DESCRIPTOR_SIMD_ELEMENT_HIGH              (`DESCRIPTOR_SIMD_ELEMENT_LOW + `DESCRIPTOR_SIMD_ELEMENT_WIDTH - 1)
`define DESCRIPTOR_SIMD_ELEMENT_FIELD             (`DESCRIPTOR_SIMD_ELEMENT_HIGH):(`DESCRIPTOR_SIMD_ELEMENT_LOW)


`define DESCRIPTOR_FIELD0                         `DESCRIPTOR_INFO_TYPE_HIGH: 0
// fix so not hardcoded
`define DESCRIPTOR_FIELD1                         164:24
`define DESCRIPTOR_FIELD2                         22:0   
//`define DESCRIPTOR_FIELD1                       `DESCRIPTOR_SIMD_ELEMENT_HIGH:`DESCRIPTOR_INFO_CELL_X_LOW
//`define DESCRIPTOR_FIELD2                       `DESCRIPTOR_INFO_KEYPOINT_ID_HIGH:0

//---------------------------------------------------------------------------------------------------------------------------------------------------
// Match info definitions 
//---------------------------------------------------------------------------------------------------------------------------------------------------
//
//  --------------------------------------------------------------------------------------------------
// | MATCH_INFO_RSVD | MATCH_INFO_SCORE | MATCH_INFO_MODEL_KEYPOINT_ID | MATCH_INFO_QUERY_KEYPOINT_ID |
//  --------------------------------------------------------------------------------------------------
// Score :
//          The distance value measured between the Query Keypoint and Model Keypoint
// ModelKeypointID :
//         The unique ID identifying the model keypoint.
// QueryKeypointID :
//         The unique ID identifying the query keypoint.

`define MATCH_INFO_QUERY_KEYPOINT_ID_WIDTH             `KEYPOINT_ID_WIDTH
`define MATCH_INFO_QUERY_KEYPOINT_ID_LOW               0
`define MATCH_INFO_QUERY_KEYPOINT_ID_HIGH              (`MATCH_INFO_QUERY_KEYPOINT_ID_LOW + `MATCH_INFO_QUERY_KEYPOINT_ID_WIDTH - 1)
`define MATCH_INFO_QUERY_KEYPOINT_ID_FIELD             (`MATCH_INFO_QUERY_KEYPOINT_ID_HIGH):(`MATCH_INFO_QUERY_KEYPOINT_ID_LOW)

`define MATCH_INFO_MODEL_KEYPOINT_ID_WIDTH             `KEYPOINT_ID_WIDTH
`define MATCH_INFO_MODEL_KEYPOINT_ID_LOW               (`MATCH_INFO_QUERY_KEYPOINT_ID_HIGH + 1)
`define MATCH_INFO_MODEL_KEYPOINT_ID_HIGH              (`MATCH_INFO_MODEL_KEYPOINT_ID_LOW + `MATCH_INFO_MODEL_KEYPOINT_ID_WIDTH - 1)
`define MATCH_INFO_MODEL_KEYPOINT_ID_FIELD             (`MATCH_INFO_MODEL_KEYPOINT_ID_HIGH):(`MATCH_INFO_MODEL_KEYPOINT_ID_LOW)

`define MATCH_INFO_SCORE_WIDTH                         `FLOAT_PREC_WIDTH
`define MATCH_INFO_SCORE_LOW                           (`MATCH_INFO_MODEL_KEYPOINT_ID_HIGH + 1)
`define MATCH_INFO_SCORE_HIGH                          (`MATCH_INFO_SCORE_LOW + `MATCH_INFO_SCORE_WIDTH - 1)
`define MATCH_INFO_SCORE_FIELD                         (`MATCH_INFO_SCORE_HIGH):(`MATCH_INFO_SCORE_LOW)

`define MATCH_INFO_CELL_ID_WIDTH                       16
`define MATCH_INFO_CELL_ID_LOW                         (`MATCH_INFO_SCORE_HIGH + 1)
`define MATCH_INFO_CELL_ID_HIGH                        (`MATCH_INFO_CELL_ID_LOW + `MATCH_INFO_CELL_ID_WIDTH - 1)
`define MATCH_INFO_CELL_ID_FIELD                       (`MATCH_INFO_CELL_ID_HIGH):(`MATCH_INFO_CELL_ID_LOW)   


`define MATCH_INFO_WIDTH                               ((`MATCH_INFO_QUERY_KEYPOINT_ID_WIDTH) + \
                                                        (`MATCH_INFO_MODEL_KEYPOINT_ID_WIDTH) + \
                                                        (`MATCH_INFO_SCORE_WIDTH)             + \
                                                        (`MATCH_INFO_CELL_ID_WIDTH))    

// MATCH_INFO_QUERY_KEYPOINT_ID_WIDTH                   13
// MATCH_INFO_MODEL_KEYPOINT_ID_WIDTH                   13                                      
// MATCH_INFO_SCORE_WIDTH                               32                                               
// MATCH_INFO_CELL_ID_WIDTH                             16  = 74                                 


`define MATCH_TABLE_SCORE_WIDTH                         `MATCH_INFO_SCORE_WIDTH

`define MATCH_TABLE_1ST_SCORE_WIDTH                     `MATCH_TABLE_SCORE_WIDTH
`define MATCH_TABLE_1ST_SCORE_LOW                       0
`define MATCH_TABLE_1ST_SCORE_HIGH                      (`MATCH_TABLE_1ST_SCORE_LOW + `MATCH_TABLE_SCORE_WIDTH - 1)
`define MATCH_TABLE_1ST_SCORE_FIELD                     (`MATCH_TABLE_1ST_SCORE_HIGH):(`MATCH_TABLE_1ST_SCORE_LOW)

`define MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH         16 //ceil2(`KEYPOINT_ID_WIDTH) 
`define MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_LOW           (`MATCH_TABLE_1ST_SCORE_HIGH + 1)
`define MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_HIGH          (`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_LOW + `MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH - 1)
`define MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_FIELD         (`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_HIGH):(`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_LOW)

`define MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH         16 //ceil2(`KEYPOINT_ID_WIDTH)
`define MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_LOW           (`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_HIGH + 1)
`define MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_HIGH          (`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_LOW + `MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH - 1)
`define MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_FIELD         (`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_HIGH):(`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_LOW)

`define MATCH_TABLE_2ND_SCORE_WIDTH                     `MATCH_TABLE_SCORE_WIDTH 
`define MATCH_TABLE_2ND_SCORE_LOW                       (`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_HIGH + 1)
`define MATCH_TABLE_2ND_SCORE_HIGH                      (`MATCH_TABLE_2ND_SCORE_LOW + `MATCH_TABLE_2ND_SCORE_WIDTH - 1)
`define MATCH_TABLE_2ND_SCORE_FIELD                     (`MATCH_TABLE_2ND_SCORE_HIGH):(`MATCH_TABLE_2ND_SCORE_LOW)

`define MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH         16 //ceil2(`KEYPOINT_ID_WIDTH)
`define MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_LOW           (`MATCH_TABLE_2ND_SCORE_HIGH + 1)
`define MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_HIGH          (`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_LOW + `MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH - 1)
`define MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_FIELD         (`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_HIGH):(`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_LOW)

`define MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH         16 //ceil2(`KEYPOINT_ID_WIDTH)
`define MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_LOW           (`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_HIGH + 1)
`define MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_HIGH          (`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_LOW + `MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH - 1)
`define MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_FIELD         (`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_HIGH):(`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_LOW)

`define MATCH_TABLE_VALID_FLAG_WIDTH                    8 //ceil2(1)
`define MATCH_TABLE_VALID_FLAG                          (`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_HIGH + 1)

`define MATCH_TABLE_WIDTH                               ((`MATCH_TABLE_1ST_SCORE_WIDTH)                 + \
                                                         (`MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH)     + \
                                                         (`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH)     + \
                                                         (`MATCH_TABLE_2ND_SCORE_WIDTH)                 + \
                                                         (`MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH)     + \
                                                         (`MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH))
                                                         
// MATCH_TABLE_1ST_SCORE_WIDTH                  // 32
// MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH      // 16
// MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH      // 16
// MATCH_TABLE_2ND_SCORE_WIDTH                  // 32
// MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH      // 16
// MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH      // 16 
//  = 128                                                         
                                                   
 `define MATCH_TABLE_CTROL_BITS                         (`MATCH_TABLE_1ST_MODEL_KEYPOINT_ID_WIDTH +\
                                                         `MATCH_TABLE_1ST_QUERY_KEYPOINT_ID_WIDTH +\
                                                         `MATCH_TABLE_2ND_MODEL_KEYPOINT_ID_WIDTH +\
                                                         `MATCH_TABLE_2ND_QUERY_KEYPOINT_ID_WIDTH)

`define MATCH_TABLE_SIZE                                (`MATCH_TABLE_WIDTH / `BITS_PER_BYTE)

`endif

