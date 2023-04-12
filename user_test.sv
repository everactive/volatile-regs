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

class directed_fifo_seq extends uvm_reg_sequence;

	function new(string name="directed_fifo_seq");
		super.new(name);
	endfunction : new

	rand bit   [31:0] addr;
	rand logic [31:0] data;

	`uvm_object_utils(directed_fifo_seq)

	virtual task body();
		reg_block_dut model;
		uvm_reg_data_t tmp_data;
		bit[31:0] shadow_fifo[$:16];
		bit[31:0] wr_data;
		bit[31:0] act_data;
		bit[31:0] exp_data;
		uvm_status_e status;

		`uvm_info(get_name(), "Running", UVM_LOW)

		$cast(model, this.model);
		shadow_fifo.delete();

		begin : write_then_read_each_entry
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			repeat (16) begin
				wr_data = $urandom;
				tmp_data = wr_data;
				write_reg(model.FIFO, status, tmp_data);
				assert (status == UVM_IS_OK);
				`uvm_info(get_name(), $sformatf("Wrote data (0x%h)", wr_data), UVM_MEDIUM)
				shadow_fifo.push_back(wr_data);

				model.FIFO.read(status, tmp_data);
				act_data = tmp_data;
				assert (status == UVM_IS_OK);
				exp_data = shadow_fifo.pop_front();

				check_exp_eq_act : assert (exp_data === act_data)
					`uvm_info(get_name(), $sformatf("OK: Expected data (0x%h) matches actual data (0x%h)", exp_data, act_data), UVM_MEDIUM)
				else
					`uvm_error(get_name(), $sformatf("Expected data (0x%h) != actual data (0x%h)", exp_data, act_data))
			end
		end


		begin : write_all_entries_then_read_all_entries
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			repeat (16) begin : write_all_entries
				wr_data = $urandom;
				tmp_data = wr_data;
				write_reg(model.FIFO, status, tmp_data);
				assert (status == UVM_IS_OK);
				`uvm_info(get_name(), $sformatf("Wrote data (0x%h)", wr_data), UVM_MEDIUM)
				shadow_fifo.push_back(wr_data);
			end

			repeat (16) begin : read_and_check_all_entries
				read_reg(model.FIFO, status, tmp_data);
				act_data = tmp_data;
				assert (status == UVM_IS_OK);
				exp_data = shadow_fifo.pop_front();

				check_exp_eq_act : assert (exp_data === act_data)
					`uvm_info(get_name(), $sformatf("OK: Expected data (0x%h) matches actual data (0x%h)", exp_data, act_data), UVM_MEDIUM)
				else
					`uvm_error(get_name(), $sformatf("Expected data (0x%h) != actual data (0x%h)", exp_data, act_data))
			end
		end


		begin : write_then_mirror_each_entry
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			repeat (16) begin
				wr_data = $urandom;
				tmp_data = wr_data;
				write_reg(model.FIFO, status, tmp_data);
				assert (status == UVM_IS_OK);
				`uvm_info(get_name(), $sformatf("Wrote data (0x%h)", wr_data), UVM_MEDIUM)

				mirror_reg(model.FIFO, status, UVM_CHECK);
				assert (status == UVM_IS_OK);
			end
		end


		begin : write_all_entries_then_mirror_all_entries
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			repeat (16) begin : write_all_entries
				wr_data = $urandom;
				tmp_data = wr_data;
				write_reg(model.FIFO, status, tmp_data);
				assert (status == UVM_IS_OK);
				`uvm_info(get_name(), $sformatf("Wrote data (0x%h)", wr_data), UVM_MEDIUM)
			end

			repeat (16) begin : mirror_and_check_all_entries
				mirror_reg(model.FIFO, status, UVM_CHECK);
				assert (status == UVM_IS_OK);
			end
		end


		begin : check_fifo_status_fields
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			`uvm_info(get_name(),
				//
				"Check status before filling FIFO",
				//
				UVM_MEDIUM)
			read_reg(model.FIFO_STATUS, status, tmp_data);
			check_empty : assert (model.FIFO_STATUS.EMPTY.get() == 1);
			check_not_full : assert (model.FIFO_STATUS.FULL.get() == 0);
			check_count_eq_0 : assert (model.FIFO_STATUS.COUNT.get() == 0);

			`uvm_info(get_name(),
				//
				"Write all entries, check status after every write",
				//
				UVM_MEDIUM)
			repeat (16) begin : write_all_entries_check_status_after_every_write
				wr_data = $urandom;
				tmp_data = wr_data;

				write_reg(model.FIFO, status, tmp_data);
				assert (status == UVM_IS_OK);

				mirror_reg(model.FIFO_STATUS, status, UVM_CHECK);
				assert (status == UVM_IS_OK);

				`uvm_info(get_name(), $sformatf("Wrote data (0x%h) and checked status", wr_data), UVM_MEDIUM)
			end

			`uvm_info(get_name(),
				//
				"Check status while FIFO is full",
				//
				UVM_MEDIUM)
			read_reg(model.FIFO_STATUS, status, tmp_data);
			check_not_empty : assert (model.FIFO_STATUS.EMPTY.get() == 0);
			check_full : assert (model.FIFO_STATUS.FULL.get() == 1);
			check_count_eq_16 : assert (model.FIFO_STATUS.COUNT.get() == 16);

			`uvm_info(get_name(),
				//
				"Read all entries, check status after every read",
				//
				UVM_MEDIUM)
			repeat (16) begin : mirror_and_check_all_entries_check_status_after_every_read
				mirror_reg(model.FIFO, status, UVM_CHECK);
				assert (status == UVM_IS_OK);

				mirror_reg(model.FIFO_STATUS, status, UVM_CHECK);
				assert (status == UVM_IS_OK);

				`uvm_info(get_name(), "Read FIFO data and checked status", UVM_MEDIUM)
			end

			`uvm_info(get_name(),
				//
				"Check status after emptying FIFO",
				//
				UVM_MEDIUM)
			read_reg(model.FIFO_STATUS, status, tmp_data);
			check_empty_again : assert (model.FIFO_STATUS.EMPTY.get() == 1);
			check_not_full_again : assert (model.FIFO_STATUS.FULL.get() == 0);
			check_count_eq_0_again : assert (model.FIFO_STATUS.COUNT.get() == 0);
		end

	endtask : body

endclass : directed_fifo_seq


class random_fifo_seq extends uvm_reg_sequence;

	rand int unsigned iterations;
	rand uvm_reg_data_t tmp_data;

	function new(string name="random_fifo_seq");
		super.new(name);
	endfunction : new

	`uvm_object_utils_begin(random_fifo_seq)
		`uvm_field_int(iterations, UVM_ALL_ON)
	`uvm_object_utils_end

	constraint c_iterations {
		iterations < 10000;
		iterations > 0;
		soft iterations == 1000;
	}

	virtual task body();
		reg_block_dut model;
		uvm_status_e status;
		int ok;

		`uvm_info(get_name(), "Running", UVM_LOW)

		$cast(model, this.model);

		ok = randomize(iterations);
		assert (ok);
		
		`uvm_info(get_name(), {"\n", sprint()}, UVM_MEDIUM)

		repeat (iterations) begin

			randcase
				100 : begin : write_FIFO_reg
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					if (!model.FIFO_STATUS.FULL.get()) begin
						ok = randomize(tmp_data) with {tmp_data < 64'h1_0000_0000;};
						assert (ok);
						write_reg(model.FIFO, status, tmp_data);
						assert (status == UVM_IS_OK);
					end
				end

				100 : begin : write_FIFO_DATA_field
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					if (!model.FIFO_STATUS.FULL.get()) begin
						ok = randomize(tmp_data) with {tmp_data < 64'h1_0000_0000;};
						assert (ok);
						model.FIFO.DATA.write(status, tmp_data, .parent(this));
						assert (status == UVM_IS_OK);
					end
				end

				10 : begin : write_FIFO_reg_until_full
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					while (!model.FIFO_STATUS.FULL.get()) begin
						ok = randomize(tmp_data) with {tmp_data < 64'h1_0000_0000;};
						assert (ok);
						write_reg(model.FIFO, status, tmp_data);
						assert (status == UVM_IS_OK);
					end
				end

				100 : begin : read_and_check_FIFO_reg
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					if (!model.FIFO_STATUS.EMPTY.get()) begin
						mirror_reg(model.FIFO, status, UVM_CHECK);
						assert (status == UVM_IS_OK);
					end
				end

				100 : begin : read_and_check_FIFO_DATA_field
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					if (!model.FIFO_STATUS.EMPTY.get()) begin
						model.FIFO.DATA.mirror(status, UVM_CHECK, .parent(this));
						assert (status == UVM_IS_OK);
					end
				end

				10 : begin : read_and_check_FIFO_reg_until_empty
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					while (!model.FIFO_STATUS.EMPTY.get()) begin
						mirror_reg(model.FIFO, status, UVM_CHECK);
						assert (status == UVM_IS_OK);
					end
				end

				10 : begin : read_and_check_FIFO_STATUS_reg
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					mirror_reg(model.FIFO_STATUS, status, UVM_CHECK);
					assert (status == UVM_IS_OK);
				end

				10 : begin : read_and_check_FIFO_STATUS_EMPTY_field
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					model.FIFO_STATUS.EMPTY.mirror(status, UVM_CHECK, .parent(this));
					assert (status == UVM_IS_OK);
				end

				10 : begin : read_and_check_FIFO_STATUS_FULL_field
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					model.FIFO_STATUS.FULL.mirror(status, UVM_CHECK, .parent(this));
					assert (status == UVM_IS_OK);
				end

				10 : begin : read_and_check_FIFO_STATUS_COUNT_field
					`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)
					model.FIFO_STATUS.COUNT.mirror(status, UVM_CHECK, .parent(this));
					assert (status == UVM_IS_OK);
				end

			endcase
		end

	endtask : body
endclass : random_fifo_seq


class execute_program_seq extends uvm_reg_sequence;

	rand uvm_reg_data_t tmp_data;

	function new(string name="execute_program_seq");
		super.new(name);
	endfunction : new

	`uvm_object_utils(execute_program_seq)

	virtual task body();
		reg_block_dut model;
		uvm_status_e status;
		int ok;

		`uvm_info(get_name(), "Running", UVM_LOW)
		`uvm_info(get_name(), {"\n", sprint()}, UVM_MEDIUM)

		$cast(model, this.model);
		
		`uvm_info("DEBUG", $sformatf("auto_predict=%0b", model.get_map_by_name("default_map").get_auto_predict()), UVM_NONE)

		`uvm_info(get_name(),
			//
			"Execute embedded APB program",
			//
			UVM_LOW)

		// Write magic value to SCRATCH register
		tmp_data = 32'h1111_1111;
		write_reg(model.SCRATCH, status, tmp_data);
		assert (status == UVM_IS_OK);

		#100ns;

		mirror_reg(model.FIFO_STATUS, status, UVM_CHECK);
		assert (status == UVM_IS_OK);

		while (!model.FIFO_STATUS.EMPTY.get()) begin
			mirror_reg(model.FIFO, status, UVM_CHECK);
			assert (status == UVM_IS_OK);
		end

		#100ns;
	endtask : body
endclass : execute_program_seq


class directed_timer_seq extends uvm_reg_sequence;
	localparam real CLOCK_PERIOD_S = 20.0e-9;
	
	rand uvm_reg_data_t tmp_data;
	rand bit[15:0] timer_start_value;
	
	function new(string name="directed_timer_seq");
		super.new(name);
	endfunction : new
	
	`uvm_object_utils_begin(directed_timer_seq)
	`uvm_object_utils_end
	
	virtual task body();
		reg_block_dut model;
		uvm_status_e status;
		bit ok;
		int success;
		int act_timer;
		int exp_timer;
		int margin;
		int delta;

		`uvm_info(get_name(), "Running", UVM_LOW)
		`uvm_info(get_name(), {"\n", sprint()}, UVM_MEDIUM)

		$cast(model, this.model);

		begin : check_initial_interrupt_value
			model.INTERRUPT.read(status, tmp_data);
			check_initial_interrupt : assert (tmp_data[0] == 1'b0) else
				`uvm_error(get_name(), $sformatf("expected EXPIRED=%0b; actual EXPIRED=%0b", 1'b0, tmp_data[0]))
		end

		begin : start_timer
			timer_start_value = 1000;
			tmp_data = timer_start_value;
			write_reg(model.TIMER, status, tmp_data);
			assert (status == UVM_IS_OK);
		end

		wait_until_midpoint :
		#((real'(timer_start_value) / 2.0) * CLOCK_PERIOD_S * 1.0s);


		begin : check_timer_at_midpoint
			model.TIMER.read(status, tmp_data);
			assert (status == UVM_IS_OK);
			act_timer = tmp_data[15:0];
			margin = 10;
			exp_timer = timer_start_value - (timer_start_value / 2);
			delta = act_timer - exp_timer;
			if (delta < 0) delta = -delta;
			check_timer : assert (delta <= margin) else
				`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
						exp_timer, act_timer, delta, margin))
		end

		begin : check_interrupt_at_midpoint
			model.INTERRUPT.read(status, tmp_data);
			check_cleared_interrupt : assert (tmp_data[0] == 1'b0) else
				`uvm_error(get_name(), $sformatf("expected EXPIRED=%0b; actual EXPIRED=%0b", 1'b0, tmp_data[0]))
		end

		wait_until_end :
		#((real'(timer_start_value) / 2.0) * CLOCK_PERIOD_S * 1.0s);


		begin : check_timer_at_end
			model.TIMER.read(status, tmp_data);
			assert (status == UVM_IS_OK);
			act_timer = tmp_data[15:0];
			margin = 10;
			exp_timer = 0;
			delta = act_timer - exp_timer;
			if (delta < 0) delta = -delta;
			check_timer : assert (delta <= margin) else
				`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
						exp_timer, act_timer, delta, margin))
		end

		begin : check_final_interrupt_value
			model.INTERRUPT.read(status, tmp_data);
			assert (status == UVM_IS_OK);
			check_final_interrupt : assert (tmp_data[0] == 1'b1) else
				`uvm_error(get_name(), $sformatf("expected EXPIRED=%0b; actual EXPIRED=%0b", 1'b1, tmp_data[0]))
		end

		begin : check_interrupt_was_cleared_on_read
			model.INTERRUPT.read(status, tmp_data);
			assert (status == UVM_IS_OK);
			check_cleared_interrupt : assert (tmp_data[0] == 1'b0) else
				`uvm_error(get_name(), $sformatf("expected EXPIRED=%0b; actual EXPIRED=%0b", 1'b0, tmp_data[0]))
		end

	endtask : body
	
	
endclass : directed_timer_seq


class directed_timer_w_mirror_seq extends uvm_reg_sequence;
	localparam real CLOCK_PERIOD_S = 20.0e-9;
	
	rand uvm_reg_data_t tmp_data;
	rand bit[15:0] timer_start_value;
	
	function new(string name="directed_timer_w_mirror_seq");
		super.new(name);
	endfunction : new
	
	`uvm_object_utils_begin(directed_timer_w_mirror_seq)
	`uvm_object_utils_end
	
	virtual task body();
		reg_block_dut model;
		uvm_status_e status;
		bit ok;
		int success;
		int act_timer;
		int exp_timer;
		int margin;
		int delta;

		`uvm_info(get_name(), "Running", UVM_LOW)
		`uvm_info(get_name(), {"\n", sprint()}, UVM_MEDIUM)

		$cast(model, this.model);

		begin : check_initial_interrupt_value
			mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
			assert (status == UVM_IS_OK);
		end

		begin : start_timer
			timer_start_value = 1000;
			tmp_data = timer_start_value;
			write_reg(model.TIMER, status, tmp_data);
			assert (status == UVM_IS_OK);
		end

		wait_until_midpoint :
		#((real'(timer_start_value) / 2.0) * CLOCK_PERIOD_S * 1.0s);

		begin : check_timer_at_midpoint
			mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
			assert (status == UVM_IS_OK);
			tmp_data = model.TIMER.get();
			act_timer = tmp_data[15:0];
			margin = 10;
			exp_timer = timer_start_value - (timer_start_value / 2);
			delta = act_timer - exp_timer;
			if (delta < 0) delta = -delta;
			check_timer : assert (delta <= margin) else
				`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
						exp_timer, act_timer, delta, margin))
		end

		begin : check_interrupt_at_midpoint
			mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
			assert (status == UVM_IS_OK);
		end

		wait_until_end :
		#((real'(timer_start_value) / 2.0) * CLOCK_PERIOD_S * 1.0s);


		begin : check_timer_at_end
			mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
			assert (status == UVM_IS_OK);
			tmp_data = model.TIMER.get();
			act_timer = tmp_data[15:0];
			margin = 10;
			exp_timer = 0;
			delta = act_timer - exp_timer;
			if (delta < 0) delta = -delta;
			check_timer : assert (delta <= margin) else
				`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
						exp_timer, act_timer, delta, margin))
		end

		begin : check_final_interrupt_value
			mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
		end

		begin : check_interrupt_was_cleared_on_read
			mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
			assert (status == UVM_IS_OK);
		end

	endtask : body
	
	
endclass : directed_timer_w_mirror_seq


class directed_timer_busy_seq extends uvm_reg_sequence;
	localparam real CLOCK_PERIOD_S = 20.0e-9;

	rand uvm_reg_data_t tmp_data;
	rand bit[15:0] timer_start_value;

	function new(string name="directed_timer_busy_seq");
		super.new(name);
	endfunction : new

	`uvm_object_utils_begin(directed_timer_busy_seq)
	`uvm_object_utils_end

	virtual task body();
		reg_block_dut model;
		uvm_status_e status;
		bit ok;
		int success;
		int act_timer;
		int exp_timer;
		int margin;
		int delta;

		`uvm_info(get_name(), "Running", UVM_LOW)
		`uvm_info(get_name(), {"\n", sprint()}, UVM_MEDIUM)

		$cast(model, this.model);
		
		begin : let_timer_expire_while_reg_is_busy_with_reads
			`uvm_info(get_name(), $sformatf("# %m"), UVM_LOW)

			begin : start_timer
				timer_start_value = 1000;
				tmp_data = timer_start_value;
				write_reg(model.TIMER, status, tmp_data);
				assert (status == UVM_IS_OK);
			end

			wait_until_80percent :
			#((real'(timer_start_value) * 0.8) * CLOCK_PERIOD_S * 1.0s);

			begin : poll_timer_until_expired_to_keep_reg_busy
				bit done = 1'b0;
				bit hung = 1'b0;
				`uvm_info(get_name(), $sformatf("## %m"), UVM_LOW)
				fork
					#((real'(timer_start_value) * 0.4) * CLOCK_PERIOD_S * 1.0s) hung = 1'b1;

					while (!done && !hung) begin
						mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
						assert (status == UVM_IS_OK);
						tmp_data = model.TIMER.get();
						act_timer = tmp_data[15:0];
						done = act_timer == 16'h0000;
					end
				join_any

				assert_done_not_hung : assert (done && !hung) else
					`uvm_error(get_name(), "Timed out waiting for timer to expire")
			end

			begin : check_final_interrupt_value
				mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
			end

			begin : check_interrupt_was_cleared_on_read
				mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
				assert (status == UVM_IS_OK);
			end
			
			begin : read_timer_while_it_is_predictable_to_set_UVM_CHECK_flag
				`uvm_info(get_name(), $sformatf("## %m"), UVM_LOW)
				mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
				assert (status == UVM_IS_OK);
				tmp_data = model.TIMER.get();
				act_timer = tmp_data[15:0];
				margin = 10;
				exp_timer = 0;
				delta = act_timer - exp_timer;
				if (delta < 0) delta = -delta;
				check_timer : assert (delta <= margin) else
					`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
							exp_timer, act_timer, delta, margin))
			end

		end
		
		#100ns;
		
		begin : let_timer_expire_while_reg_is_not_busy
			`uvm_info(get_name(), $sformatf("# %m"), UVM_LOW)

			begin : start_timer
				timer_start_value = 500;
				tmp_data = timer_start_value;
				write_reg(model.TIMER, status, tmp_data);
				assert (status == UVM_IS_OK);
			end

			wait_until_80percent :
			#((real'(timer_start_value) * 0.8) * CLOCK_PERIOD_S * 1.0s);

			begin : check_timer_at_80percent
				`uvm_info(get_name(), $sformatf("## %m"), UVM_LOW)
				mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
				assert (status == UVM_IS_OK);
				tmp_data = model.TIMER.get();
				act_timer = tmp_data[15:0];
				margin = 10;
				exp_timer = timer_start_value - (timer_start_value * 0.8);
				delta = act_timer - exp_timer;
				if (delta < 0) delta = -delta;
				check_timer : assert (delta <= margin) else
					`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
							exp_timer, act_timer, delta, margin))
			end

			wait_until_end :
			#((real'(timer_start_value) * 0.2) * CLOCK_PERIOD_S * 1.0s);

			begin : check_timer_at_end
				`uvm_info(get_name(), $sformatf("## %m"), UVM_LOW)
				mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
				assert (status == UVM_IS_OK);
				tmp_data = model.TIMER.get();
				act_timer = tmp_data[15:0];
				margin = 10;
				exp_timer = 0;
				delta = act_timer - exp_timer;
				if (delta < 0) delta = -delta;
				check_timer : assert (delta <= margin) else
					`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
							exp_timer, act_timer, delta, margin))
			end

			begin : check_final_interrupt_value
				mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
			end

			begin : check_interrupt_was_cleared_on_read
				mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
				assert (status == UVM_IS_OK);
			end

		end
		
		#100ns;
		
		begin : restart_timer
			`uvm_info(get_name(), $sformatf("# %m"), UVM_LOW)

			begin : start_timer
				timer_start_value = 1000;
				tmp_data = timer_start_value;
				write_reg(model.TIMER, status, tmp_data);
				assert (status == UVM_IS_OK);
			end

			wait_until_50percent :
			#((real'(timer_start_value) * 0.5) * CLOCK_PERIOD_S * 1.0s);

			begin : restart_timer
				timer_start_value = 250;
				tmp_data = timer_start_value;
				write_reg(model.TIMER, status, tmp_data);
				assert (status == UVM_IS_OK);
			end

			wait_until_end :
			#((real'(timer_start_value) * 1.0) * CLOCK_PERIOD_S * 1.0s);

			begin : check_timer_at_end
				`uvm_info(get_name(), $sformatf("## %m"), UVM_LOW)
				mirror_reg(model.TIMER, status, model.TIMER.TIMER.get_compare());
				assert (status == UVM_IS_OK);
				tmp_data = model.TIMER.get();
				act_timer = tmp_data[15:0];
				margin = 10;
				exp_timer = 0;
				delta = act_timer - exp_timer;
				if (delta < 0) delta = -delta;
				check_timer : assert (delta <= margin) else
					`uvm_error(get_name(), $sformatf("expected timer=%0d; actual timer=%0d delta %0d is outside allowed margin %0d",
							exp_timer, act_timer, delta, margin))
			end

			begin : check_final_interrupt_value
				mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
			end

			begin : check_interrupt_was_cleared_on_read
				mirror_reg(model.INTERRUPT, status, model.INTERRUPT.EXPIRED.get_compare());
				assert (status == UVM_IS_OK);
			end

		end

	endtask : body


endclass : directed_timer_busy_seq

class directed_gpio_seq extends uvm_reg_sequence;

	function new(string name="directed_gpio_seq");
		super.new(name);
	endfunction : new

	rand bit   [31:0] addr;
	rand logic [31:0] data;

	`uvm_object_utils(directed_gpio_seq)

	virtual task body();
		reg_block_dut model;
		uvm_reg_data_t tmp_data;
		bit[7:0] wr_data;
		bit[7:0] act_data;
		bit[7:0] exp_data;
		uvm_status_e status;

		`uvm_info(get_name(), "Running", UVM_LOW)

		$cast(model, this.model);

		begin : test_1
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			for (int i = 0; i < 8; i++) begin
				wr_data = 8'h01 << i;
				tmp_data = wr_data;
				write_reg(model.GPIO, status, tmp_data);
				assert (status == UVM_IS_OK);
				`uvm_info(get_name(), $sformatf("Wrote data (0x%h)", wr_data), UVM_MEDIUM)

				model.GPIO.read(status, tmp_data);
				act_data = tmp_data;
				assert (status == UVM_IS_OK);
				exp_data = ~wr_data;

				check_exp_eq_act : assert (exp_data === act_data)
					`uvm_info(get_name(), $sformatf("OK: Expected data (0x%h) matches actual data (0x%h)", exp_data, act_data), UVM_MEDIUM)
				else
					`uvm_error(get_name(), $sformatf("Expected data (0x%h) != actual data (0x%h)", exp_data, act_data))
			end
		end
		
		begin : test_2
			`uvm_info(get_name(), $sformatf("%m"), UVM_LOW)

			for (int i = 0; i < 8; i++) begin
				wr_data = 8'h01 << i;
				tmp_data = wr_data;
				write_reg(model.GPIO, status, tmp_data);
				assert (status == UVM_IS_OK);
				`uvm_info(get_name(), $sformatf("Wrote data (0x%h)", wr_data), UVM_MEDIUM)
				#20;
				`uvm_info(get_name(), $sformatf("mirror=0x%h", model.GPIO.get_mirrored_value()), UVM_MEDIUM)

				mirror_reg(model.GPIO, status, UVM_CHECK);
				act_data = model.GPIO.get();
				assert (status == UVM_IS_OK);
				exp_data = ~wr_data;

				check_exp_eq_act : assert (exp_data === act_data)
					`uvm_info(get_name(), $sformatf("OK: Expected data (0x%h) matches actual data (0x%h)", exp_data, act_data), UVM_MEDIUM)
				else
					`uvm_error(get_name(), $sformatf("Expected data (0x%h) != actual data (0x%h)", exp_data, act_data))
			end			
		end

	endtask : body

endclass : directed_gpio_seq

