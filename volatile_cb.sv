`ifndef VOLATILE_CB_SV
`define VOLATILE_CB_SV

typedef interface class volatile_impl_if;

class volatile_cb extends uvm_reg_cbs;
	volatile_impl_if impl;
	bit auto_set_volatile_value;
	bit auto_set_compare;

	`uvm_object_utils_begin(volatile_cb)
		`uvm_field_int(auto_set_compare, UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "volatile_cb");
		super.new(name);
		this.impl = null;
		this.auto_set_volatile_value = 1'b1;
		this.auto_set_compare = 1'b0;
	endfunction : new


	virtual function void post_predict(input uvm_reg_field fld, input uvm_reg_data_t previous, inout uvm_reg_data_t value, input uvm_predict_e kind, input uvm_path_e path, input uvm_reg_map map);
		uvm_reg_data_t original_value = value;

		super.post_predict(fld, previous, value, kind, path, map);
		
		if (impl) begin

			case (kind)
				UVM_PREDICT_WRITE : begin
					impl.handle_volatile_write(fld, previous, value, kind, path, map);
				end

				UVM_PREDICT_READ : begin
					impl.handle_volatile_read(fld, previous, value, kind, path, map);
				end
			endcase

			if (auto_set_volatile_value) begin
				value =  impl.get_volatile_value(fld);
			end

		end

		if (auto_set_compare) begin
			fld.set_compare(UVM_CHECK);
		end

		`uvm_info(get_name(), $sformatf("post_predict callback set %s mirror from 0x%h to volatile value 0x%h",
				fld.get_full_name(), original_value, value), UVM_HIGH)

	endfunction : post_predict


	virtual function uvm_reg_data_t get_volatile_value();
		`uvm_info(get_name(), "get_volatile_value", UVM_HIGH)
	endfunction : get_volatile_value


	// Get impl
	function volatile_impl_if get_impl();
		return this.impl;
	endfunction : get_impl


	// Set impl
	function void set_impl(volatile_impl_if impl);
		this.impl = impl;
	endfunction : set_impl
	
	
	function void set_auto_set_volatile_value(bit auto_set_volatile_value);
		this.auto_set_volatile_value = auto_set_volatile_value;
	endfunction : set_auto_set_volatile_value
	

	function bit get_auto_set_volatile_value(bit auto_set_volatile_value);
		return this.auto_set_volatile_value;
	endfunction : get_auto_set_volatile_value
	
	
	function void set_auto_set_compare(bit auto_set_compare);
		this.auto_set_compare = auto_set_compare;
	endfunction : set_auto_set_compare
	

	function bit get_auto_set_compare(bit auto_set_compare);
		return this.auto_set_compare;
	endfunction : get_auto_set_compare
	
	
	// Configure impl and knobs
	function void configure(volatile_impl_if impl = null, bit auto_set_volatile_value = 1'b1, bit auto_set_compare = 1'b0);
		this.set_impl(impl);
		this.set_auto_set_volatile_value(auto_set_volatile_value);
		this.set_auto_set_compare(auto_set_compare);
	endfunction : configure

endclass : volatile_cb

`endif // VOLATILE_CB_SV

