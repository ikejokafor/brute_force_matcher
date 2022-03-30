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
module testbench;


    //-----------------------------------------------------------------------------------------------------------------------------------------------
    // Wire / Regs
    //-----------------------------------------------------------------------------------------------------------------------------------------------
	reg						sap_clk								;
    wire                    sap_rst                             ;

	wire		[15:0]		vendor_id							;
	wire		[15:0]		device_id							;
	wire		[23:0]		class_code							;
	wire		[7:0]		revision_id							;

	wire					master_clk							;
	wire					master_rst							;
	wire 					master_request						;
	wire					master_request_ack					;
	wire					master_request_complete				;
	wire		[3	:0]		master_request_option				;	
	wire		[6	:0]		master_request_error				;
	wire		[3  :0]		master_request_tag					;
	wire		[3  :0]		master_request_type					;
	wire		[9  :0]		master_request_flow					;
	wire		[63 :0]		master_request_local_address		;
	wire		[35 :0]		master_request_length				;
	// SAP Master Descriptor Interface 
	wire					master_descriptor_src_rdy			;
	wire					master_descriptor_dst_rdy			;
	wire		[3  :0]		master_descriptor_tag				;
	wire		[127:0]		master_descriptor					;
	// SAP Master Data Interface 
	wire	   				master_datain_src_rdy				;
	wire					master_datain_dst_rdy				;
	wire		[3	:0]		master_datain_option				;
	wire		[3  :0]		master_datain_tag					;
	wire		[127:0]		master_datain						;
	
	wire					master_dataout_src_rdy				;
	wire					master_dataout_dst_rdy				;
	wire		[3	:0]		master_dataout_option				;
	wire		[3  :0]		master_dataout_tag					;
	wire		[127:0]		master_dataout						;
	// SAP Slave Interface 
	wire					slave_clk							;
	wire					slave_rst							;
	wire					slave_burst_start					;
	wire	[12:0]			slave_burst_length					;
	wire					slave_burst_rnw						;
	wire	[63 :0]			slave_address						;
	wire	[3  :0]			slave_transaction_id				;
	wire	[3  :0]			slave_transaction_option			;
	wire					slave_address_valid					;
	wire					slave_address_ack					;
	wire	[3  :0]			slave_wrreq							;
	wire					slave_wrack							;
	wire	[15 :0] 		slave_be							;
	wire	[127:0]			slave_datain						;
	wire	[3  :0]  		slave_rdreq							;
	wire		      		slave_rdack							;
	wire	[127:0]			slave_dataout						;
	// SAP Message Send Interface (Unused)
	wire					send_msg_request 					;
	wire					send_msg_ack						;
	wire					send_msg_complete					;
	wire	[1  :0]			send_msg_error						;
	wire					send_msg_src_rdy 					;
	wire					send_msg_dst_rdy					;
	wire	[127:0]			send_msg_payload 					;
	// SAP Message Recv Interface (Unused)	
	wire					recv_msg_request					;
	wire					recv_msg_ack 						;
	wire					recv_msg_src_rdy					;
	wire					recv_msg_dst_rdy					;
	wire	[127:0]			recv_msg_payload					;	
    
    
	//-----------------------------------------------------------------------------------------------------------------------------------------------
	// Module Instantiations
	//-----------------------------------------------------------------------------------------------------------------------------------------------
    clock_gen #(
        .C_PERIOD_BY_2(10)
    )
    i0_clock_gen(
        .clk_out(sap_clk)
    );
    
    
	soc_it_master_request_ports
	i0_soc_it_master_request_ports (
		.clk							( master_clk					),
		.rst							( master_rst					),
		.master_request					( master_request				),
		.master_request_ack				( master_request_ack			),
		.master_request_complete		( master_request_complete		),
		.master_request_error			( master_request_error			),
		.master_request_tag				( master_request_tag			),
		.master_request_type			( master_request_type			),
		.master_request_flow			( master_request_flow			),
		.master_request_local_address	( master_request_local_address	),
		.master_request_length			( master_request_length			)
	);
	

	soc_it_master_descriptor_ports
	i0_soc_it_master_descriptor_ports (
		.clk							( master_clk					),
		.rst							( master_rst					),
		.master_descriptor_src_rdy		( master_descriptor_src_rdy		),
		.master_descriptor_dst_rdy		( master_descriptor_dst_rdy		),
		.master_descriptor_tag			( master_descriptor_tag			),
		.master_descriptor				( master_descriptor				)
	);

	
	soc_it_master_data_ports
	i0_soc_it_master_data_ports (
		.clk							( master_clk					),
		.rst							( master_rst					),
		.master_datain_src_rdy			( master_datain_src_rdy			),
		.master_datain_dst_rdy			( master_datain_dst_rdy			),
		.master_datain_tag				( master_datain_tag				),
		.master_datain					( master_datain					),
		.master_dataout_src_rdy			( master_dataout_src_rdy		),
		.master_dataout_dst_rdy			( master_dataout_dst_rdy		),
		.master_dataout_tag				( master_dataout_tag			),
		.master_dataout					( master_dataout				)
	);

	
	soc_it_slave_ports
	i0_soc_it_slave_ports (
		.clk							( master_clk					),
		.rst							( master_rst					),
		.slave_address					( slave_address					),
		.slave_transaction_id			( slave_transaction_id			),
		.slave_address_valid			( slave_address_valid			),
		.slave_address_ack				( slave_address_ack				),
		.slave_wrreq					( slave_wrreq					),
		.slave_wrack					( slave_wrack					),
		.slave_be						( slave_be						),
		.slave_datain					( slave_datain					),
		.slave_rdreq					( slave_rdreq					),
		.slave_rdack					( slave_rdack					),
		.slave_dataout					( slave_dataout					)
	);

	
	soc_it_message_send_ports
	i0_soc_it_message_send_ports (
		.clk							( master_clk					),
		.rst							( master_rst					),
		.send_msg_request				( send_msg_request				),
		.send_msg_ack					( send_msg_ack					),
		.send_msg_complete				( send_msg_complete				),
		.send_msg_error					( send_msg_error				),
		.send_msg_src_rdy				( send_msg_src_rdy				),
		.send_msg_dst_rdy				( send_msg_dst_rdy				),
		.send_msg_payload				( send_msg_payload				)
	);

	
	soc_it_message_recv_ports
	i0_soc_it_message_recv_ports (
		.clk					    ( master_clk					),
		.rst					    ( master_rst					),
		.recv_msg_request		    ( recv_msg_request				),
		.recv_msg_ack			    ( recv_msg_ack					),
		.recv_msg_src_rdy		    ( recv_msg_src_rdy				),
		.recv_msg_dst_rdy		    ( recv_msg_dst_rdy				),
		.recv_msg_payload		    ( recv_msg_payload				)
	);
	
	
	main
	i0_main	(
		.master_request_ports		( i0_soc_it_master_request_ports		),
		.master_descriptor_ports	( i0_soc_it_master_descriptor_ports	    ),
		.master_data_ports			( i0_soc_it_master_data_ports		    ),
		.slave_ports				( i0_soc_it_slave_ports				    ),
		.message_send_ports			( i0_soc_it_message_send_ports		    ),
		.message_recv_ports			( i0_soc_it_message_recv_ports		    ),
        .rst                        ( sap_rst                               )
	);
    

	brute_force_matcher
	i0_brute_force_matcher (
		.sap_clk								( sap_clk							),		
		.sap_rst							    ( sap_rst							),

		.vendor_id								( vendor_id							),
		.device_id							    ( device_id							),
		.class_code							    ( class_code						),
		.revision_id							( revision_id						),

		.master_clk								( master_clk						),
		.master_rst							    ( master_rst						),
		.master_request						    ( master_request					),
		.master_request_ack					    ( master_request_ack				),
		.master_request_complete			    ( master_request_complete			),
		.master_request_option				    ( master_request_option				),
		.master_request_error				    ( master_request_error				),
		.master_request_tag					    ( master_request_tag				),
		.master_request_type				    ( master_request_type				),
		.master_request_flow				    ( master_request_flow				),
		.master_request_local_address		    ( master_request_local_address		),
		.master_request_length				    ( master_request_length				),

		.master_descriptor_src_rdy				( master_descriptor_src_rdy			),
		.master_descriptor_dst_rdy			    ( master_descriptor_dst_rdy			),
		.master_descriptor_tag				    ( master_descriptor_tag				),
		.master_descriptor					    ( master_descriptor					),

		.master_datain_src_rdy					( master_datain_src_rdy				),
		.master_datain_dst_rdy				    ( master_datain_dst_rdy				),
		.master_datain_option				    ( master_datain_option				),
		.master_datain_tag					    ( master_datain_tag					),
		.master_datain							( master_datain						),

		.master_dataout_src_rdy					( master_dataout_src_rdy			),
		.master_dataout_dst_rdy				    ( master_dataout_dst_rdy			),
		.master_dataout_option				    ( master_dataout_option				),
		.master_dataout_tag					    ( master_dataout_tag				),
		.master_dataout						    ( master_dataout					),

		.slave_clk								( slave_clk							),
		.slave_rst							    ( slave_rst							),
		.slave_burst_start					    ( slave_burst_start					),
		.slave_burst_length					    ( slave_burst_length				),
		.slave_burst_rnw					    ( slave_burst_rnw					),
		.slave_address						    ( slave_address						),
		.slave_transaction_id				    ( slave_transaction_id				),
		.slave_transaction_option			    ( slave_transaction_option			),
		.slave_address_valid				    ( slave_address_valid				),
		.slave_address_ack					    ( slave_address_ack					),
		.slave_wrreq						    ( slave_wrreq						),
		.slave_wrack						    ( slave_wrack						),
		.slave_be							    ( slave_be							),
		.slave_datain						    ( slave_datain						),
		.slave_rdreq						    ( slave_rdreq						),
		.slave_rdack						    ( slave_rdack						),
		.slave_dataout						    ( slave_dataout						),

		.send_msg_request 						( send_msg_request 					),
		.send_msg_ack						    ( send_msg_ack						),
		.send_msg_complete					    ( send_msg_complete					),
		.send_msg_error						    ( send_msg_error				    ),
		.send_msg_src_rdy 					    ( send_msg_src_rdy 					),
		.send_msg_dst_rdy					    ( send_msg_dst_rdy					),
		.send_msg_payload 					    ( send_msg_payload 					),

		.recv_msg_request						( recv_msg_request					),
		.recv_msg_ack 						    ( recv_msg_ack 						),
		.recv_msg_src_rdy					    ( recv_msg_src_rdy					),
		.recv_msg_dst_rdy					    ( recv_msg_dst_rdy					),
		.recv_msg_payload					    ( recv_msg_payload					)
	);    
    
endmodule
