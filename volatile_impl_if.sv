`ifndef VOLATILE_IMPL_IF_SV
`define VOLATILE_IMPL_IF_SV

interface class volatile_impl_if;

	pure virtual function uvm_reg_data_t get_volatile_value (input uvm_reg_field fld);
	
	pure virtual function bit update_volatile_mirror(input uvm_reg_field fld);
	
	pure virtual function void handle_volatile_write (
		input uvm_reg_field  fld,
		input uvm_reg_data_t previous,
		input uvm_reg_data_t value, // Cannot be changed
		input uvm_predict_e  kind,
		input uvm_path_e     path,
		input uvm_reg_map    map
	);

	pure virtual function void handle_volatile_read (
		input uvm_reg_field  fld,
		input uvm_reg_data_t previous,
		input uvm_reg_data_t value, // Cannot be changed
		input uvm_predict_e  kind,
		input uvm_path_e     path,
		input uvm_reg_map    map
	);

endclass : volatile_impl_if

`endif // VOLATILE_IMPL_IF_SV

