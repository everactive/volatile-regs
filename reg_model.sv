//
//------------------------------------------------------------------------------
//   Copyright 2011 Mentor Graphics Corporation
//   Copyright 2011 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//------------------------------------------------------------------------------

`ifndef REG_MODEL_SV
`define REG_MODEL_SV

class reg_SCRATCH extends uvm_reg;

	uvm_reg_field SCRATCH;

	function new(string name = "SCRATCH");
		super.new(name,32,UVM_NO_COVERAGE);
	endfunction

	virtual function void build();
		this.SCRATCH = uvm_reg_field::type_id::create("SCRATCH");

		this.SCRATCH.configure(
			.parent (this),
			.size (32),
			.lsb_pos (0),
			.access ("RW"),
			.volatile (0),
			.reset (32'h0000_0000),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
		);
	endfunction

	`uvm_object_utils(reg_SCRATCH)

endclass : reg_SCRATCH


class reg_FIFO extends uvm_reg;

	uvm_reg_field DATA;

	function new(string name = "FIFO");
		super.new(name,32,UVM_NO_COVERAGE);
	endfunction

	virtual function void build();
		this.DATA = uvm_reg_field::type_id::create("DATA");

		this.DATA.configure(
			.parent (this),
			.size (32),
			.lsb_pos (0),
			.access ("RW"),
			.volatile (1),
			.reset (32'h0000_0000),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
		);
	endfunction

	`uvm_object_utils(reg_FIFO)

endclass : reg_FIFO


class reg_FIFO_STATUS extends uvm_reg;

	uvm_reg_field EMPTY;
	uvm_reg_field FULL;
	uvm_reg_field COUNT;

	function new(string name = "FIFO_STATUS");
		super.new(name,32,UVM_NO_COVERAGE);
	endfunction

	virtual function void build();
		this.EMPTY = uvm_reg_field::type_id::create("EMPTY");
		this.FULL = uvm_reg_field::type_id::create("FULL");
		this.COUNT = uvm_reg_field::type_id::create("COUNT");

		this.EMPTY.configure(
			.parent (this),
			.size (1),
			.lsb_pos (0),
			.access ("RO"),
			.volatile (1),
			.reset (1'b1),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
			);

		this.FULL.configure(
			.parent (this),
			.size (1),
			.lsb_pos (8),
			.access ("RO"),
			.volatile (1),
			.reset (1'b0),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
			);

		this.COUNT.configure(
			.parent (this),
			.size (8),
			.lsb_pos (16),
			.access ("RO"),
			.volatile (1),
			.reset (8'h00),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
		);
	endfunction

	`uvm_object_utils(reg_FIFO_STATUS)

endclass : reg_FIFO_STATUS


class reg_GPIO extends uvm_reg;

	uvm_reg_field VALUE;

	function new(string name = "GPIO");
		super.new(name,32,UVM_NO_COVERAGE);
	endfunction

	virtual function void build();
		this.VALUE = uvm_reg_field::type_id::create("VALUE");

		this.VALUE.configure(
			.parent (this),
			.size (32),
			.lsb_pos (0),
			.access ("RW"),
			.volatile (1),
			.reset (8'h00),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
		);
	endfunction

	`uvm_object_utils(reg_GPIO)

endclass : reg_GPIO


class reg_TIMER extends uvm_reg;
	
	uvm_reg_field TIMER;
	
	function new(string name = "TIMER");
		super.new(name, 32, UVM_NO_COVERAGE);
	endfunction	
	
	virtual function void build();
		this.TIMER = uvm_reg_field::type_id::create("TIMER");
		
		this.TIMER.configure(
			.parent (this),
			.size (16),
			.lsb_pos (0),
			.access ("RW"),
			.volatile (1),
			.reset (16'h0000),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
			);
	endfunction
	
	`uvm_object_utils(reg_TIMER)
	
endclass : reg_TIMER


class reg_INTERRUPT extends uvm_reg;
	
	uvm_reg_field EXPIRED;
	
	function new(string name = "INTERRUPT");
		super.new(name, 32, UVM_NO_COVERAGE);
	endfunction
	
	virtual function void build();
		this.EXPIRED = uvm_reg_field::type_id::create("EXPIRED");
		
		this.EXPIRED.configure(
			.parent (this),
			.size (1),
			.lsb_pos (0),
			.access ("RC"),
			.volatile (1),
			.reset (1'b0),
			.has_reset (1),
			.is_rand (0),
			.individually_accessible (1)
			);
	endfunction
	
	`uvm_object_utils(reg_INTERRUPT)
	
endclass : reg_INTERRUPT


class reg_block_dut extends uvm_reg_block;

	rand reg_SCRATCH SCRATCH;
	rand reg_FIFO FIFO;
	rand reg_FIFO_STATUS FIFO_STATUS;
	rand reg_GPIO GPIO;
	rand reg_TIMER TIMER;
	rand reg_INTERRUPT INTERRUPT;

	function new(string name = "dut");
		super.new(name, UVM_NO_COVERAGE);
	endfunction

	virtual function void build();

		// create
		SCRATCH     = reg_SCRATCH::type_id::create("SCRATCH");
		FIFO        = reg_FIFO::type_id::create("FIFO");
		FIFO_STATUS = reg_FIFO_STATUS::type_id::create("FIFO_STATUS");
		GPIO        = reg_GPIO::type_id::create("GPIO");
		TIMER       = reg_TIMER::type_id::create("TIMER");
		INTERRUPT   = reg_INTERRUPT::type_id::create("INTERRUPT");

		// configure
		SCRATCH.configure(this, null, "");
		SCRATCH.build();
		FIFO.configure(this, null, "");
		FIFO.build();
		FIFO_STATUS.configure(this, null, "");
		FIFO_STATUS.build();
		GPIO.configure(this, null, "");
		GPIO.build();
		TIMER.configure(this, null, "");
		TIMER.build();
		INTERRUPT.configure(this, null, "");
		INTERRUPT.build();

		// define default map
		default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN, 1);
		default_map.add_reg(SCRATCH,     'h00, "RW");
		default_map.add_reg(FIFO,        'h04, "RW");
		default_map.add_reg(FIFO_STATUS, 'h08, "RW");
		default_map.add_reg(GPIO,        'h0c, "RW");
		default_map.add_reg(TIMER,       'h10, "RW");
		default_map.add_reg(INTERRUPT,   'h14, "RW");
	endfunction

	`uvm_object_utils(reg_block_dut)

endclass : reg_block_dut


`endif // REG_MODEL_SV
