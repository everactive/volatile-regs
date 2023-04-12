
class apb_reg_predictor extends uvm_reg_predictor#(apb_rw);
	gpio_vif gp_vif;

	function new(string name="apb_reg_predictor", uvm_component parent);
		super.new(name, parent);
		
	endfunction : new
	
	`uvm_component_utils(apb_reg_predictor)
	

	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
	endfunction : build_phase


	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		void'(uvm_config_db#(gpio_vif)::get(null, "env.gpio", "vif", gp_vif));
	endfunction : connect_phase


	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
	
		check_map_is_not_null :
		assert (map);
		
		check_adapter_is_not_null :
		assert (adapter);
		
		
	endtask : run_phase
	
	
	virtual function void set_map(uvm_reg_map map);
		this.map = map;
	endfunction : set_map
	
	
	virtual function void set_adapter(uvm_reg_adapter adapter);
		this.adapter = adapter;
	endfunction : set_adapter


	virtual function void pre_predict(uvm_reg_item rw);
		uvm_reg_field fld;
		reg_GPIO reg_gpio;
		
		super.pre_predict(rw);
		
		case (rw.element_kind)
			
			UVM_REG : begin
				
				if ($cast(reg_gpio, rw.element)) begin
					
					case (rw.kind)
						
						UVM_WRITE : begin
							bit [7:0] new_value = ~rw.value[0];
							rw.value[0] = {24'h000000, new_value};
							`uvm_info(get_name(), $sformatf("New rw.value=0x%h", rw.value[0]), UVM_HIGH)
						end
						
						UVM_READ : begin
							;
						end
						
					endcase
					
				end
				
			end	
			
		endcase
		
	endfunction : pre_predict

	
endclass : apb_reg_predictor