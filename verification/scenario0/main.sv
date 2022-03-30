`timescale 1ns / 1ns
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: Copyright 2016 SiliconScapes, LLC. All Rights Reserved.			
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
`include "soc_it_driver.sv"
`include "soc_it_bfm_defs.vh"
`include "MatcherAccelMSG.sv"
`include "Keypoint.sv"
`include "brute_force_matcher_verf_defs.vh"


function automatic void get_query(int numMatches, bit[63:0] mainMemory[bit[63:0]], int address[`NUM_ENGINES], ref matchTable_t matchTable_qry[`MAX_VERF_MATCHES]);
    int i;
    
    i = 0;
    for(int j = address[0]; j < (address[0] + numMatches * `MATCH_TABLE_SIZE); j = j + `MATCH_TABLE_SIZE) begin
        matchTable_qry[i].first_score = $bitstoshortreal(mainMemory[j][31:0]);
        matchTable_qry[i].first_model_id = mainMemory[j][47:32];
        matchTable_qry[i].first_query_id = mainMemory[j][63:48];
        matchTable_qry[i].second_score = $bitstoshortreal(mainMemory[j + 8][31:0]);
        matchTable_qry[i].second_model_id = mainMemory[j + 8][47:32];
        matchTable_qry[i].second_query_id = mainMemory[j + 8][63:48];
        i = i + 1;
    end
endfunction: get_query


function automatic void get_solution(int numModelKP, Keypoint modelKeypoint[`MAX_MODEL_KP], int numObsvdKP, Keypoint obsvdKeypoint[`MAX_VERF_OBSVD_KEYPOINTS], ref matchTable_t matchTable_sol[`MAX_VERF_MATCHES]);
    shortreal d1;
	shortreal d2;
	shortreal distance;  

	for(int i = 0; i < numObsvdKP; i = i + 1) begin
		d1 = $bitstoshortreal(32'h7f7fffff);
		d2 = $bitstoshortreal(32'h7f7fffff);   
		for(int j = 0; j < numModelKP; j = j + 1) begin
			distance = 0.0;             
			for(int k = 0; k < 64; k = k + 1) begin
                distance = distance + ((obsvdKeypoint[i].m_descriptors[k] - modelKeypoint[j].m_descriptors[k]) * (obsvdKeypoint[i].m_descriptors[k] - modelKeypoint[j].m_descriptors[k]));
			end	
			distance = $sqrt(distance);
			if (distance < d1) begin
				d2 = d1;
				matchTable_sol[i].second_model_id = matchTable_sol[i].first_model_id;
				matchTable_sol[i].second_query_id = matchTable_sol[i].first_query_id;
				matchTable_sol[i].second_score = d2;
				d1 = distance;
				matchTable_sol[i].first_model_id = j;
				matchTable_sol[i].first_query_id = i;
				matchTable_sol[i].first_score = d1;
			end else if(distance < d2) begin
				d2 = distance;
				matchTable_sol[i].second_model_id = j;
				matchTable_sol[i].second_query_id = i;
				matchTable_sol[i].second_score = d2;
			end
		end
	end
endfunction: get_solution


function int check_qry_against_sol(int numMatches, matchTable_t matchTable_qry[`MAX_VERF_MATCHES], matchTable_t matchTable_sol[`MAX_VERF_MATCHES], int numModelKP);
    matchTable_t match;
    integer fd;
    
    fd = $fopen("matchSol.txt", "w");
	for(int i = 0; i < numMatches; i = i + 1) begin
		$fwrite(fd,
			"Observed ID %d: Best Model: %d Observed ID %d: 2nd Best Model: %d\n",
			matchTable_sol[i].first_query_id,
			matchTable_sol[i].first_model_id,
			matchTable_sol[i].second_query_id,
			matchTable_sol[i].second_model_id);
	end
	$fclose(fd);
    
	fd = $fopen("matchOut.txt", "w");
	for(int i = 0; i < numMatches; i = i + 1) begin
		$fwrite(fd,
			"Observed ID %d: Best Model: %d Observed ID %d: 2nd Best Model: %d\n",
			matchTable_qry[i].first_query_id,
			matchTable_qry[i].first_model_id,
			matchTable_qry[i].second_query_id,
			matchTable_qry[i].second_model_id);
	end
	$fclose(fd);
    
    for(int i = 0; i < numMatches; i = i + 1) begin
        for(int j = 0; j < numMatches; j = j + 1) begin
            if( /*matchTable_sol[i].first_score == matchTable_qry[j].first_score
                &&*/ matchTable_sol[i].first_model_id == matchTable_qry[j].first_model_id               
                && matchTable_sol[i].first_query_id == matchTable_qry[j].first_query_id              
                /*&& matchTable_sol[i].second_score == matchTable_qry[j].second_score*/               
                && matchTable_sol[i].second_model_id == matchTable_qry[j].second_model_id               
                && matchTable_sol[i].second_query_id == matchTable_qry[j].second_query_id                
            ) begin 
                break;
            end else if(/*matchTable_sol[i].first_score == matchTable_qry[j].first_score
                        &&*/ matchTable_sol[i].first_model_id == matchTable_qry[j].first_model_id               
                        && matchTable_sol[i].first_query_id == matchTable_qry[j].first_query_id              
                        && numModelKP == 1
            ) begin
                break;
            end else if(j == (numMatches - 1)) begin
                return 0;
            end
        end        
    end
   
    return 1;
endfunction: check_qry_against_sol


function automatic void initMemory(ref bit [63:0] mainMemory[bit[63:0]], int numModelKP, ref bit[63:0] modelDataAddr, ref Keypoint modelKeypoint[`MAX_MODEL_KP], int numObsvdKP, ref bit[63:0] obsvdDataAddr, ref Keypoint obsvdKeypoint[`MAX_VERF_OBSVD_KEYPOINTS]);    
    bit[63:0] address;
    int modelKPSize;
    int obsvdKPSize;
    Keypoint keypoint;
    mem_queue_64_t mem_queue;

    
    address = 0;   
    modelDataAddr = address;
 
 
	for(int i = 0; i < numModelKP; i = i + 1) begin
        keypoint = new();
        if(!keypoint.randomize()) begin
            $display("Model Keypoint randomization failed");
            $stop;
        end
        keypoint.post_randomize();
        mem_queue = keypoint.get_bits();
        while(mem_queue.size() > 0) begin
            mainMemory[address] = mem_queue.pop_front();
            address = address + 8;
        end
        modelKeypoint[i] = keypoint;
	end  
    
    obsvdDataAddr = address;
    for(int i = 0; i < numObsvdKP; i = i + 1) begin
        keypoint = new();
        if(!keypoint.randomize()) begin
            $display("Obsvd Keypoint randomization failed");
            $stop;
        end
        keypoint.post_randomize();
        mem_queue = keypoint.get_bits();
        while(mem_queue.size() > 0) begin
            mainMemory[address] = mem_queue.pop_front();
            address = address + 8;
        end
        obsvdKeypoint[i] = keypoint;
	end
endfunction: initMemory


program main (
	soc_it_master_request_ports		master_request_ports		,
	soc_it_master_descriptor_ports	master_descriptor_ports		,
	soc_it_master_data_ports		master_data_ports			,
	soc_it_slave_ports				slave_ports					,
	soc_it_message_send_ports		message_send_ports			,
	soc_it_message_recv_ports		message_recv_ports			,
    output reg                      rst
);

	//-----------------------------------------------------------------------------------------------------------------------------------------------
	// Variables
	//-----------------------------------------------------------------------------------------------------------------------------------------------
    Keypoint modelKeypoint[`MAX_MODEL_KP];     
    Keypoint obsvdKeypoint[`MAX_VERF_OBSVD_KEYPOINTS];
    int numTests = 0;
    int numCells = 1;
    bit[63:0] modelDataAddr;
    bit[63:0] obsvdDataAddr;
    bit[63:0] matchTableStartAddr;
    bit[63:0] matchTableInfoAddr;
    soc_it_driver driver;
	int i;
    int j;
    MatcherAccelMSG msgQueue[$];
    MatcherAccelMSG msg;
    mem_queue_128_t msgBits;
    int msgLength;
    bit [63:0] mainMemory[bit[63:0]];
    matchTable_t matchTable_sol[`MAX_VERF_MATCHES];
    matchTable_t matchTable_qry[`MAX_VERF_MATCHES];
    integer fd;
    int numMatches;
    int maxNumModelKP; 
	int maxNumObsvdKP;
    
    
    // BEGIN Logic ----------------------------------------------------------------------------------------------------------------------------------       
	initial begin
        // BEGIN Logic ------------------------------------------------------------------------------------------------------------------------------
        maxNumModelKP = `MAX_MODEL_KP;
        maxNumObsvdKP = `MAX_VERF_OBSVD_KEYPOINTS;
        initMemory(mainMemory, maxNumModelKP, modelDataAddr, modelKeypoint, maxNumObsvdKP, obsvdDataAddr, obsvdKeypoint);
        matchTableStartAddr = `MAX_MODEL_KP * `KEYPOINT_SIZE + `MAX_VERF_OBSVD_KEYPOINTS * `KEYPOINT_SIZE;
        matchTableInfoAddr = matchTableStartAddr + (`MATCH_TABLE_SIZE * `MAX_VERF_MATCHES);
        rst = 1;
		#20 rst = 0;
		driver = new 	(	
							master_request_ports		,
							master_descriptor_ports		,
							master_data_ports			,
							slave_ports					,
							message_send_ports			,
							message_recv_ports			,
                            mainMemory                  
						);
		fork
			driver.do_service();
            driver.sendMsg();
		join_none
        // END Logic --------------------------------------------------------------------------------------------------------------------------------


  
        // BEGIN Logic ------------------------------------------------------------------------------------------------------------------------------
        // for(i = 1; i <= 128; i = i + 1) begin
        //     for(j = 1; j <= 128; j = j + 1) begin
        //         msg = new(modelDataAddr, obsvdDataAddr, matchTableStartAddr, matchTableInfoAddr, numCells);
        //         msg.m_modelKPcount = i;
        //         msg.m_obsvdKPcount = j;
        //         msg.createMsg();
        //         msgQueue.push_back(msg);
        //         numTests++;
        //     end
        // end

        // msg = new(modelDataAddr, obsvdDataAddr, matchTableStartAddr, matchTableInfoAddr, numCells); 
        // msg.m_modelKPcount = `MAX_MODEL_KP;
        // msg.m_obsvdKPcount = `MAX_VERF_OBSVD_KEYPOINTS;
        // msg.createMsg();
        // msgQueue.push_back(msg);
        // numTests++;      

        msg = new(modelDataAddr, obsvdDataAddr, matchTableStartAddr, matchTableInfoAddr, numCells); 
        msg.m_modelKPcount = 2;
        msg.m_obsvdKPcount = 2;
        msg.createMsg();
        msgQueue.push_back(msg);
        numTests++;        

        // for(i = 0; i < 1000; i = i + 1) begin
        //     msg = new(modelDataAddr, obsvdDataAddr, matchTableStartAddr, matchTableInfoAddr, numCells);
        //     if(!msg.randomize()) begin
        //         $display("Msg randomization failed");
        //         $stop;
        //     end
        //     msg.createMsg();
        //     msgQueue.push_back(msg);
        //     numTests++;
        // end
        
        $display("NumTests %d", numTests);
        fd = $fopen("results.txt", "w");
        for(i = 0; i < numTests; i = i + 1) begin
            msg = msgQueue.pop_front();
            numMatches = msg.m_obsvdKPcount;
            $display("//--------------------------------------------");
            $display("Transaction %d", i);
            $display("Obsvd Keypoint Count %d", msg.m_obsvdKPcount);
            $display("Model Keypoint Count %d", msg.m_modelKPcount);
            $display("//--------------------------------------------");
            msgBits = msg.get_bits(msgLength);
            driver.sendMsgTransaction(msgBits, msgLength);          
            wait(message_send_ports.send_msg_complete);
            $display("//--------------------------------------------");
            $display("Done transaction %d", i);
            $display("//--------------------------------------------");
            get_query(numMatches, driver.m_mainMemory, msg.m_I_matchTableAddr, matchTable_qry);
            get_solution(msg.m_modelKPcount, modelKeypoint, msg.m_obsvdKPcount, obsvdKeypoint, matchTable_sol);
            if(!check_qry_against_sol(numMatches, matchTable_qry, matchTable_sol, msg.m_modelKPcount)) begin
                $display("//--------------------------------------------");
                $display("Transaction failed");
                $display("//--------------------------------------------");
                $fwrite(fd, "Transaction %d failed\n", i);
                $fwrite(fd, "\t\tObsvd Keypoint Count %d\n", msg.m_obsvdKPcount);
                $fwrite(fd, "\t\tModel Keypoint Count %d\n", msg.m_modelKPcount);
            end else begin
                $display("//--------------------------------------------");
                $display("Transaction passed");
                $display("//--------------------------------------------");
                $fwrite(fd, "Transaction %d passed\n", i);
            end
        end
        $display("//--------------------------------------------");
        $display("Finished all Tests");
        $display("//--------------------------------------------");
        $fclose(fd);
        $stop;
	end
    // END Logic ------------------------------------------------------------------------------------------------------------------------------------
    // END Logic ------------------------------------------------------------------------------------------------------------------------------------
endprogram

