//
// -------------------------------------------------------------
//    Copyright 2004-2011 Synopsys, Inc.
//    Copyright 2010 Mentor Graphics Corporation
//    Copyright 2010 Cadence Design Systems, Inc.
//    All Rights Reserved Worldwide
//
//    Licensed under the Apache License, Version 2.0 (the
//    "License"); you may not use this file except in
//    compliance with the License.  You may obtain a copy of
//    the License at
//
//        http://www.apache.org/licenses/LICENSE-2.0
//
//    Unless required by applicable law or agreed to in
//    writing, software distributed under the License is
//    distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//    CONDITIONS OF ANY KIND, either express or implied.  See
//    the License for the specific language governing
//    permissions and limitations under the License.
// -------------------------------------------------------------
//

`timescale 1ns/1ns

module dut(
		apb_if    apb,
		input bit rst,
		input bit[7:0] GPI,
		output bit[7:0] GPO
	);

	parameter FIFO_DEPTH = 16;
	parameter FIFO_POINTER_WIDTH = 4;

	reg [31:0] pr_data;
	assign apb.prdata = (apb.psel && apb.penable && !apb.pwrite) ? pr_data : 'z;

	reg[31:0] scratch_word;
	reg[31:0] fifo[FIFO_DEPTH];
	reg[7:0] fifo_count;
	logic fifo_empty;
	logic fifo_full;
	reg[FIFO_POINTER_WIDTH-1 : 0] fifo_wr_pointer;
	reg[FIFO_POINTER_WIDTH-1 : 0] fifo_rd_pointer;
	
	reg[15:0] timer;
	reg expired;
	reg running;
	
	logic[7:0] gpi;
	reg[7:0] gpo;

	assign gpi = GPI;
	assign GPO = gpo;
	
	always_comb
		begin
			fifo_empty <= fifo_count == 8'd0;
			fifo_full <= fifo_count == FIFO_DEPTH;
		end

	always @ (posedge apb.pclk)
	begin
		if (rst) begin
			scratch_word  <= 32'h0000_0000;
			foreach (fifo[i]) begin
				fifo[i] <= 32'h0000_0000;
			end
			fifo_wr_pointer <= 'd0;
			fifo_rd_pointer <= 'd0;
			fifo_count <= 8'd0;
			gpo <= 8'h00;
			pr_data <= 32'h0;
			timer <= 16'h0000;
			expired <= 1'b0;
			running <= 1'b0;
		end
		else begin
			
			if (timer != 16'h0000) begin
				timer <= timer - 1;
			end
			
			if (running && timer == 16'h0000) begin
				expired <= 1'b1;
				running <= 1'b0;
			end

			if (apb.psel == 1'b1 && apb.penable == apb.pwrite) begin
				pr_data <= 32'h0;
				if (apb.pwrite) begin
					casez (apb.paddr)
						16'h0000 : begin : write_SCRATCH
							scratch_word <= apb.pwdata[31:0];
						end
						
						16'h0004 : begin : write_FIFO
							fifo[fifo_wr_pointer] <= apb.pwdata[31:0];
							fifo_wr_pointer++; // Rolls over
							if (fifo_count < FIFO_DEPTH) fifo_count++;
						end

						16'h000c : begin : write_GPIO
							gpo <= apb.pwdata[7:0];
						end
						
						16'h0010 : begin : write_TIMER
							timer <= apb.pwdata[15:0];
							running <= 1'b1;
						end
					endcase
				end
				else begin
					casez (apb.paddr)
						16'h0000 : begin : read_SCRATCH
							pr_data <= scratch_word;
						end
						
						16'h0004 : begin : read_FIFO
							pr_data <= fifo[fifo_rd_pointer];
							fifo_rd_pointer <= fifo_rd_pointer + 1; // Rolls over
							if (fifo_count > 0) fifo_count <= fifo_count - 1;
						end
						
						16'h0008 : begin : read_FIFO_STATUS
							pr_data <= {8'h00, fifo_count[7:0], {7'h00, fifo_full}, {7'h00, fifo_empty}};
						end

						16'h000c : begin : read_GPIO
							pr_data <= {24'h00, gpi[7:0]};
						end
						
						16'h0010 : begin : read_TIMER
							pr_data <= {16'h00, timer[15:0]};
						end
						
						16'h0014 : begin : read_INTERRUPT
							pr_data <= {31'h0000, expired};
							expired <= 1'b0;
						end
					endcase
				end
			end
		end
	end

endmodule : dut

