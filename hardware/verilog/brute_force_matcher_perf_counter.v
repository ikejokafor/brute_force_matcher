`timescale 1ns/1ps

module brute_force_matcher_perf_counter(
clk,
rst,
enable,
initialize,
stop_count,
count
);

input clk;
input rst ;
input enable ;
input initialize;
input stop_count;

output reg [31:0] count;

reg stop_count_flag;
reg [31:0] count_i;

always @(posedge clk)
begin
  if( rst== 1'b1) begin 
    count_i <= 0;
    count   <= 0;
    stop_count_flag <= 1'b0;
  end else begin 
    if(enable == 1'b1) begin
      if( initialize == 1'b1) begin 
        count_i <=0;
        stop_count_flag <= 1'b0;        
      end else begin 
        if(stop_count_flag == 1'b0) begin
          if( stop_count == 1'b1 ) begin
            count_i <= count_i;
            count   <= count_i;
            stop_count_flag <= 1'b1;
          end else
            count_i <= count_i +1 ;
        end 
      end
    end else 
      count_i <=0;
  end // else rst
end // always

endmodule 
