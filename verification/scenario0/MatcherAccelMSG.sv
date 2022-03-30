`ifndef	__MATCHER_ACCEL_MSG__
`define	__MATCHER_ACCEL_MSG__
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
`include "soc_it_bfm_defs.vh"
`include "soc_it_defs.vh"
`include "soc_it_transaction.sv"
`include "brute_force_matcher_verf_defs.vh"
`include "brute_force_matcher_defines.vh"


class MatcherAccelMSG extends soc_it_transaction;
    
    extern function new(bit[63:0] modelDataAddr, bit[63:0] obsvdDataAddr, bit[63:0] matchTableStartAddr, bit[63:0] matchTableInfoAddr, bit[63:0] numCells);
    extern function mem_queue_128_t get_bits(ref int msgLength);
    extern function void createMsg();
    
    int m_modelDataAddr;
    int m_obsvdDataAddr;
    int m_matchTableStartAddr;
    int m_matchTableInfoAddr;
    int m_obsvdDataLength;
    int m_modelDataLength;
    int m_numCells;
    rand int m_obsvdKPcount;
    rand int m_modelKPcount;
    int m_I_matchTableAddr[`NUM_ENGINES];
    int m_I_obsvdKPcount[`NUM_ENGINES];
    int m_I_matchTableLength[`NUM_ENGINES];
    int m_keypointSize;
    bit[127:0] m_msgHeader;
    int m_msgLength;
    
    constraint c1 { 
        m_modelKPcount >= 0;
        m_modelKPcount <= `MAX_MODEL_KP;
    }
    
    constraint c2 { 
        m_obsvdKPcount >= 0;
        m_obsvdKPcount <= `MAX_VERF_OBSVD_KEYPOINTS;
    }
    
endclass: MatcherAccelMSG


function MatcherAccelMSG::new(bit[63:0] modelDataAddr, bit[63:0] obsvdDataAddr, bit[63:0] matchTableStartAddr, bit[63:0] matchTableInfoAddr, bit[63:0] numCells);
    m_modelDataAddr = modelDataAddr;
    m_obsvdDataAddr = obsvdDataAddr;
    m_matchTableStartAddr = matchTableStartAddr;
    m_numCells = numCells;
    m_matchTableInfoAddr = matchTableInfoAddr;
    m_msgHeader = 128'h00000000000000010004500708000022;
endfunction: new


function void MatcherAccelMSG::createMsg();
    int matchTableStartAddr;
    int num_obsvd_kp_process_residual;
    int i;
    
    m_obsvdDataLength = `KEYPOINT_SIZE * m_obsvdKPcount;
    m_modelDataLength = `KEYPOINT_SIZE * m_modelKPcount;
    
    for(i = 0; i < `NUM_ENGINES; i = i + 1) begin
        m_I_obsvdKPcount[i] = m_obsvdKPcount / int'(`NUM_ENGINES);
    end
    
    num_obsvd_kp_process_residual = m_obsvdKPcount - (m_obsvdKPcount / `NUM_ENGINES) * `NUM_ENGINES;
    for(i = 0; num_obsvd_kp_process_residual > 0; i = (i + 1) % `NUM_ENGINES) begin
        m_I_obsvdKPcount[i] = m_I_obsvdKPcount[i] + 1;
        num_obsvd_kp_process_residual = num_obsvd_kp_process_residual - 1;
    end
    
    m_I_matchTableLength[0] = m_I_obsvdKPcount[0] * int'(`MATCH_TABLE_SIZE);
    m_I_matchTableAddr[0] = m_matchTableStartAddr;
    for(i = 1; i < (`NUM_ENGINES - 1); i = i + 1) begin
        m_I_matchTableLength[i] = m_I_obsvdKPcount[i] * int'(`MATCH_TABLE_SIZE);
        m_I_matchTableAddr[i] = m_I_matchTableAddr[i - 1] + m_I_matchTableLength[i - 1];
    end

    m_msgLength = 4 + int'(`NUM_ENGINES);
    m_msgHeader[`NIF_MSG_LENGTH_FIELD] = m_msgLength << 4;
endfunction: createMsg


function mem_queue_128_t MatcherAccelMSG::get_bits(ref int msgLength);
    bit[127:0] flit;
    int i;
    mem_queue_128_t mem_queue;
    
    msgLength = m_msgLength;
    
    mem_queue.push_back(m_msgHeader);

    flit[63:0]      = m_modelDataAddr;
    flit[127:64]    = m_obsvdDataAddr;
    mem_queue.push_back(flit); 
    
    flit[63:0]      = m_matchTableInfoAddr;
    flit[95:64]     = m_obsvdDataLength;
    flit[127:96]    = m_modelDataLength;
    mem_queue.push_back(flit); 
    
    flit[63:0]      = m_numCells;
    flit[79:64]     = m_obsvdKPcount;
    flit[95:80]     = m_modelKPcount;
    mem_queue.push_back(flit); 
    
    for(i = 0; i < `NUM_ENGINES; i = i + 1) begin
        flit[63:0]      = m_I_matchTableAddr[i];
        flit[95:64]     = m_I_obsvdKPcount[i];
        flit[127:96]    = m_I_matchTableLength[i];
        mem_queue.push_back(flit);
    end
    
    return mem_queue;
endfunction: get_bits


`endif
