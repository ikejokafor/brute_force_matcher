`ifndef	__KEYPOINT__
`define	__KEYPOINT__
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
// Additional Comments:
//                      
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//-----------------------------------------------------------------------------------------------------------------------------------------------
// Includes
//-----------------------------------------------------------------------------------------------------------------------------------------------
`include "brute_force_matcher_verf_defs.vh"
`include "brute_force_matcher_defines.vh"


class Keypoint;
    
    extern function new();
    extern function mem_queue_64_t get_bits();
    extern function void post_randomize();

	int m_laplacian;
	int m_scale;
	int m_id;
	int m_cell_id;
	int m_y;
	int m_x;
	shortreal m_descriptors[63:0];
    rand int unsigned m_multipliers[63:0];
    
endclass: Keypoint


function Keypoint::new();
    m_laplacian = 0;
    m_scale = 0;
    m_id = 0;
    m_cell_id = 0;
    m_y = 0;
    m_x = 0;
endfunction: new


function void Keypoint::post_randomize();
    int i;
    
    for(i = 0; i < 64; i = i + 1) begin
        m_descriptors[i] = -1.0 + (1.0 - -1.0) * (shortreal'(m_multipliers[i]) / 32'hFFFFFFFF);
    end
endfunction


function mem_queue_64_t Keypoint::get_bits();
    bit [63:0] mem_piece;
    int i;
    mem_queue_64_t mem_queue;
    
    // order doesnt matter for matcher
    mem_piece[31:0] = m_laplacian;
	mem_piece[31:0] = m_scale;   
    mem_queue.push_back(mem_piece);
	mem_piece[15:0] = m_id;
	mem_piece[15:0] = m_cell_id;
	mem_piece[15:0] = m_y;
	mem_piece[15:0] = m_x;
    mem_queue.push_back(mem_piece);
    

    for(i = 0; i < 64; i = i + 2) begin
        mem_piece[31:0] = $floor(m_descriptors[i] * `FX_PT_SCALE);
        mem_piece[63:32] = $floor(m_descriptors[i + 1] * `FX_PT_SCALE);
        mem_queue.push_back(mem_piece);
    end

    
    return mem_queue;   
endfunction: get_bits


`endif
