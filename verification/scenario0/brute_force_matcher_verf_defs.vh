`ifndef	__BRUTE_FORCE_MATCHER_VERF_DEFS__
`define	__BRUTE_FORCE_MATCHER_VERF_DEFS__
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
//
// Dependencies:     
//    
// Revision:
//
// Additional Comments:     Corner Cases - 1,1;  2,2;  3,3;  4,4;  5,5;  6,6;  2048,2048; 1024,1024
//                      
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------------------------------------------------------------------------


`define KEYPOINT_SIZE               272
`define MAX_VERF_OBSVD_KEYPOINTS    2048
`define MAX_VERF_MATCHES            `MAX_VERF_OBSVD_KEYPOINTS
`define FX_PT_SCALE                 16384.0
`define MAX_DESC_VALUE              16384


typedef bit [63:0] mem_queue_64_t[$];


typedef struct {
	shortreal first_score;
	bit[15:0] first_model_id;
	bit[15:0] first_query_id;
	shortreal second_score;
	bit[15:0] second_model_id;
	bit[15:0] second_query_id;
} matchTable_t;

`endif