`ifndef FIFO_VOLATILE_IMPL_SV
`define FIFO_VOLATILE_IMPL_SV

typedef class tb_env;
typedef class reg_block_dut;
typedef class fifo_data_volatile_impl;
typedef class fifo_status_volatile_impl;


class fifo_model extends uvm_component;

	bit[31:0] shadow_fifo[$:16];

	tb_env env;
	reg_block_dut reg_model;
	volatile_cb fifo_data_cb;
	volatile_cb fifo_status_cb;
	fifo_data_volatile_impl fifo_data_impl;
	fifo_status_volatile_impl fifo_status_impl;

	`uvm_component_utils(fifo_model)

	function new(string name = "fifo_model", uvm_component parent);
		super.new(name, parent);
		shadow_fifo.delete();
	endfunction : new


	virtual function void build_phase(uvm_phase phase);

		fifo_data_cb = volatile_cb::type_id::create("fifo_cb", this);
		fifo_status_cb = volatile_cb::type_id::create("fifo_status_cb", this);
		fifo_data_impl = fifo_data_volatile_impl::type_id::create("fifo_data_impl", this);
		fifo_status_impl = fifo_status_volatile_impl::type_id::create("fifo_status_impl", this);
	endfunction : build_phase


	virtual function void connect_phase(uvm_phase phase);
		uvm_component comp;
		bit ok;

		fifo_data_impl.set_fifo_mdl(this);
		fifo_status_impl.set_fifo_mdl(this);
		comp = lookup(".env");
		ok  = $cast(env, comp);
		check_env_is_correct_type : assert (ok);
		check_env_is_not_null : assert (env);
		reg_model = env.model;
		check_reg_model_is_not_null : assert (reg_model);

		fifo_data_cb.configure(fifo_data_impl);
		uvm_reg_field_cb::add(reg_model.FIFO.DATA, fifo_data_cb);

		fifo_status_cb.configure(fifo_status_impl);
		uvm_reg_field_cb::add(reg_model.FIFO_STATUS.EMPTY, fifo_status_cb);
		uvm_reg_field_cb::add(reg_model.FIFO_STATUS.FULL, fifo_status_cb);
		uvm_reg_field_cb::add(reg_model.FIFO_STATUS.COUNT, fifo_status_cb);
	endfunction : connect_phase


	virtual function void push_data_in(bit[31:0] data);
		shadow_fifo.push_back(data);
	endfunction : push_data_in


	virtual function bit[31:0] pop_data_out();
		bit[31:0] data;
		data = shadow_fifo.pop_front();
		return data;
	endfunction : pop_data_out


	virtual function bit[31:0] peek_next_data_out();
		bit[31:0] data;
		data = shadow_fifo[0];
		return data;
	endfunction : peek_next_data_out


	virtual function bit get_empty();
		bit result;
		result = shadow_fifo.size() == 0;
		return result;
	endfunction : get_empty


	virtual function bit get_full();
		bit result;
		result = shadow_fifo.size() == 16;
		return result;
	endfunction : get_full


	virtual function bit[7:0] get_count();
		bit[7:0] result;
		result = shadow_fifo.size();
		return result;
	endfunction : get_count

endclass : fifo_model


virtual class fifo_volatile_field_impl extends uvm_object implements volatile_impl_if;
	fifo_model fifo_mdl;

	function new(string name = "");
		super.new(name);
	endfunction : new

	virtual function uvm_reg_data_t get_volatile_value(input uvm_reg_field fld);
		uvm_reg_data_t result = 0;
		return result;
	endfunction : get_volatile_value


	virtual function bit update_volatile_mirror(input uvm_reg_field fld);
		uvm_reg_data_t volatile_value;
		bit ok;

		check_fld_is_not_null : assert (fld);

		volatile_value = get_volatile_value(fld);

		ok = fld.predict(volatile_value);
		check_predict_is_successful : assert (ok)
			`uvm_info(get_name(), $sformatf("update_volatile_mirror set %s mirror to volatile value 0x%h", fld.get_full_name(), volatile_value), UVM_HIGH)

	endfunction : update_volatile_mirror


	virtual function void handle_volatile_write (
			input uvm_reg_field  fld,
			input uvm_reg_data_t previous,
			input uvm_reg_data_t value,
			input uvm_predict_e  kind,
			input uvm_path_e     path,
			input uvm_reg_map    map
		);
		`uvm_info(get_name(), "Default handle_volatile_write() implementation", UVM_FULL)
	endfunction : handle_volatile_write


	virtual function void handle_volatile_read (
			input uvm_reg_field  fld,
			input uvm_reg_data_t previous,
			input uvm_reg_data_t value,
			input uvm_predict_e  kind,
			input uvm_path_e     path,
			input uvm_reg_map    map
		);
		`uvm_info(get_name(), "Default handle_volatile_read() implementation", UVM_FULL)
	endfunction : handle_volatile_read


	virtual function void set_fifo_mdl(fifo_model fifo_mdl);
		this.fifo_mdl = fifo_mdl;
	endfunction : set_fifo_mdl

endclass : fifo_volatile_field_impl


class fifo_data_volatile_impl extends fifo_volatile_field_impl;

	uvm_reg_data_t tmp_data;

	`uvm_object_utils(fifo_data_volatile_impl)

	function new(string name = "fifo_data_volatile_impl");
		super.new(name);
	endfunction : new


	virtual function uvm_reg_data_t get_volatile_value(input uvm_reg_field fld);
		uvm_reg_data_t result;

		check_fld_is_not_null : assert (fld);

		result = fifo_mdl.peek_next_data_out();
		return result;
	endfunction : get_volatile_value


	virtual function void handle_volatile_write (
			input uvm_reg_field  fld,
			input uvm_reg_data_t previous,
			input uvm_reg_data_t value,
			input uvm_predict_e  kind,
			input uvm_path_e     path,
			input uvm_reg_map    map
		);
		bit[31:0] wr_data;
		bit ok;

		wr_data = value[31:0];
		fifo_mdl.push_data_in(wr_data);
		// Writing this field has side-effects on the FIFO_STATUS fields so
		// we need them to re-sample their new volatile values.
		// These three are RO volatile fields so to update them we use a trick:
		// we do a fake UVM_PREDICT_READ.
		// Their own volatile callback handlers will update them with the correct new values.
		ok = fifo_mdl.reg_model.FIFO_STATUS.EMPTY.predict(0, .kind (UVM_PREDICT_READ));
		assert (ok);
		ok = fifo_mdl.reg_model.FIFO_STATUS.FULL.predict(0, .kind (UVM_PREDICT_READ));
		assert (ok);
		ok = fifo_mdl.reg_model.FIFO_STATUS.COUNT.predict(0, .kind (UVM_PREDICT_READ));
		assert (ok);
		`uvm_info(get_name(), $sformatf("handled volatile write by pushing data 0x%h into FIFO and updating status", wr_data), UVM_HIGH)
	endfunction : handle_volatile_write


	virtual function void handle_volatile_read (
			input uvm_reg_field  fld,
			input uvm_reg_data_t previous,
			input uvm_reg_data_t value,
			input uvm_predict_e  kind,
			input uvm_path_e     path,
			input uvm_reg_map    map
		);
		bit[31:0] rd_data;
		bit ok;

		rd_data = fifo_mdl.pop_data_out();
		// Reading this field has side-effects on the FIFO_STATUS fields so
		// we need them to re-sample their new volatile values.
		// These three are RO volatile fields so to update them we use a trick:
		// we do a fake UVM_PREDICT_READ.
		// Their own volatile callback handlers will update them with the correct new values.
		ok = fifo_mdl.reg_model.FIFO_STATUS.EMPTY.predict(0, .kind (UVM_PREDICT_READ));
		assert (ok);
		ok = fifo_mdl.reg_model.FIFO_STATUS.FULL.predict(0, .kind (UVM_PREDICT_READ));
		assert (ok);
		ok = fifo_mdl.reg_model.FIFO_STATUS.COUNT.predict(0, .kind (UVM_PREDICT_READ));
		assert (ok);
		`uvm_info(get_name(), $sformatf("handled volatile read by popping data 0x%h out of FIFO and updating status", rd_data), UVM_HIGH)
	endfunction : handle_volatile_read

endclass : fifo_data_volatile_impl


class fifo_status_volatile_impl extends fifo_volatile_field_impl;

	`uvm_object_utils(fifo_status_volatile_impl)

	function new(string name = "fifo_status_volatile_impl");
		super.new(name);
	endfunction : new


	virtual function uvm_reg_data_t get_volatile_value(input uvm_reg_field fld);
		uvm_reg_data_t result;
		bit ok;

		check_fld_is_not_null : assert (fld);

		case (fld.get_name())
			"EMPTY" : result = fifo_mdl.get_empty();
			"FULL" : result = fifo_mdl.get_full();
			"COUNT" : result = fifo_mdl.get_count();
			default : `uvm_warning(get_name(), {"Unexpected field: ", fld.get_name()})
		endcase
		return result;
	endfunction : get_volatile_value

endclass : fifo_status_volatile_impl


`endif // FIFO_VOLATILE_IMPL_SV
