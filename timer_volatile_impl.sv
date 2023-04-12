`ifndef TIMER_VOLATILE_IMPL_SV
`define TIMER_VOLATILE_IMPL_SV

typedef class tb_env;
typedef class reg_block_dut;
typedef interface class timer_state_if;
typedef class timer_state_IDLE;
typedef class timer_state_RUNNING;
typedef class timer_state_EXPIRED;
typedef class timer_state_RESTART;


class timer_model extends uvm_component;

	uvm_analysis_imp#(apb_rw, timer_model) apb_ap;

	tb_env env;
	reg_block_dut reg_model;
	volatile_cb timer_timer_cb;
	volatile_cb interrupt_expired_cb;
	timer_state_if state;
	timer_state_IDLE state_IDLE;
	timer_state_RUNNING state_RUNNING;
	timer_state_EXPIRED state_EXPIRED;
	timer_state_RESTART state_RESTART;
	mailbox state_mbox;
	bit[15:0] timer_data;
	realtime timer_start_time;
	real timer_duration_s;
	realtime timer_end_time;

	`uvm_component_utils(timer_model)

	function new(string name = "timer_model", uvm_component parent);
		super.new(name, parent);
		apb_ap = new("apb_ab", this);
		state_IDLE = new("state_IDLE", this);
		state_RUNNING = new("state_RUNNING", this);
		state_EXPIRED = new("state_EXPIRED", this);
		state_RESTART = new("state_RESTART", this);
		state = state_IDLE;
		state_mbox = new();
		timer_data = 16'h0000;
		timer_start_time = 0.0s;
		timer_duration_s = 0.0;
		timer_end_time = 0.0s;
	endfunction : new


	virtual function void build_phase(uvm_phase phase);
		timer_timer_cb = volatile_cb::type_id::create("timer_timer_cb", this);
		interrupt_expired_cb = volatile_cb::type_id::create("interrupt_expired_cb", this);
	endfunction : build_phase


	virtual function void connect_phase(uvm_phase phase);
		uvm_component comp;
		bit ok;

		comp = lookup(".env");
		ok  = $cast(env, comp);
		assert_env_is_correct_type : assert (ok);
		assert_env_is_not_null : assert (env);
		reg_model = env.model;
		assert_reg_model_is_not_null : assert (reg_model);
		
		timer_timer_cb.configure(.auto_set_volatile_value(1'b0), .auto_set_compare(1'b0));
		interrupt_expired_cb.configure(.auto_set_volatile_value(1'b0), .auto_set_compare(1'b1));
	endfunction : connect_phase
	

	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		fork
			state_machine();
		join_none
	endtask : run_phase


	function void write (input apb_rw t);
		fork
			#0 state.handle_apb(t);
		join_none
	endfunction : write
	
	
	task state_machine();
		timer_state_if current_state = state;
		forever begin
			current_state.body();
			state_mbox.get(current_state);
		end
	endtask : state_machine
	
	
	function void change_state(timer_state_if new_state);
		int success;
		state = new_state;
		success = state_mbox.try_put(new_state);
		assert_state_mbox_is_not_full : assert (success > 0);
	endfunction : change_state

endclass : timer_model


interface class timer_state_if;
	pure virtual task body();
	pure virtual function void set_name(string name);
	pure virtual function string get_name();
	pure virtual function void handle_apb(input apb_rw apb_transfer);
	pure virtual function void set_model(timer_model model);
	pure virtual function timer_model get_model();
endclass : timer_state_if


virtual class timer_state_base implements timer_state_if;

	string name;
	timer_model model;

	function new(string name, timer_model model);
		this.name = name;
		this.model = model;
	endfunction : new
	
	
	virtual task body();
		; // Default implementation
	endtask : body
	
	
	virtual function void handle_apb(input apb_rw apb_transfer);
		; // Default implementation
	endfunction : handle_apb
	
	
	// Get name
	virtual function string get_name();
		return name;
	endfunction : get_name


	// Set name
	virtual function void set_name(string name);
		this.name = name;
	endfunction : set_name
	
	
	// Get model
	virtual function timer_model get_model();
		return model;
	endfunction : get_model


	// Set model
	virtual function void set_model(timer_model model);
		this.model = model;
	endfunction : set_model
	
	
	virtual function void change_state(timer_state_if next_state);
		`uvm_info(get_name(), {"Changing state to ", next_state.get_name()}, UVM_HIGH)
		model.change_state(next_state);
	endfunction : change_state

endclass : timer_state_base


class timer_state_IDLE extends timer_state_base;
	timer_state_if next_state;
	typedef enum {NONE, WRITE_TIMER, READ_TIMER} event_kind_t;
	typedef struct {event_kind_t kind; bit[15:0] timer_data;} event_t;
	mailbox event_mbox;

	function new(string name, timer_model model);
		super.new(name, model);
		event_mbox = new(1);
	endfunction : new
	
	
	virtual task body();
		event_t idle_event;

		`uvm_info(get_name(), $sformatf("(%m) Starting"), UVM_HIGH)

		forever begin
			event_mbox.get(idle_event);
			
			case (idle_event.kind)

				WRITE_TIMER : begin
					model.timer_data = idle_event.timer_data;
					model.timer_start_time = $realtime;
					model.timer_duration_s = model.timer_data * 20.0e-9;
					model.timer_end_time = model.timer_start_time + model.timer_duration_s * 1.0s;
					next_state = model.state_RUNNING;
					break;
				end
				
				READ_TIMER : begin
					// In `IDLE` state, `TIMER` has a known, predicted value after a successful read so mark it checkable.
					model.reg_model.TIMER.TIMER.set_compare(UVM_CHECK);
					// Stay in the `IDLE` state. This is not an exit event.
				end

			endcase
		end
		
		change_state(next_state);
	endtask : body
	
	
	virtual function void handle_apb(input apb_rw apb_transfer);
		uvm_reg rg;
		event_t apb_event;
		int success;

		`uvm_info(get_name(), $sformatf("(%m) Transfer received %s", apb_transfer.convert2string()), UVM_HIGH)

		apb_event.kind = NONE;

		rg = model.reg_model.default_map.get_reg_by_offset(apb_transfer.addr);
		assert_rg_is_not_null : assert (rg);

		case (rg.get_name())
			"TIMER" : begin
				case (apb_transfer.kind)
					apb_rw::WRITE : begin
						apb_event.kind = WRITE_TIMER;
						apb_event.timer_data = apb_transfer.data[15:0];
					end

					apb_rw::READ : begin
						apb_event.kind = READ_TIMER;
					end
				endcase
			end

			"INTERRUPT" : ;

		endcase

		if (apb_event.kind != NONE) begin
			success = event_mbox.try_put(apb_event);
			assert_event_mbox_is_not_full : assert (success);
		end
	endfunction : handle_apb
endclass : timer_state_IDLE


class timer_state_RUNNING extends timer_state_base;
	timer_state_if next_state;
	typedef enum {NONE, TIMER_EXPIRED, WRITE_TIMER} event_kind_t;
	typedef struct {event_kind_t kind; bit[15:0] timer_data;} event_t;
	mailbox event_mbox;

	function new(string name, timer_model model);
		super.new(name, model);
		event_mbox = new(1);
	endfunction : new


	virtual task body();
		event_t exit_event;

		`uvm_info(get_name(), $sformatf("(%m) Timer starting"), UVM_MEDIUM)
		`uvm_info_begin(get_name(), "Timer parameters", UVM_HIGH)
		`uvm_message_add_tag("timer", $sformatf("%0d", model.timer_data))
		`uvm_message_add_tag("start time", $sformatf("%0t", model.timer_start_time))
		`uvm_message_add_tag("duration", $sformatf("%0gs", model.timer_duration_s))
		`uvm_message_add_tag("end time", $sformatf("%0t", model.timer_end_time))
		`uvm_info_end

		model.reg_model.TIMER.TIMER.set_compare(UVM_NO_CHECK);

		exit_event.kind = NONE;

		fork
			#(model.timer_duration_s * 1.0s) exit_event.kind = TIMER_EXPIRED;
			event_mbox.get(exit_event);
		join_any
		disable fork;

		case (exit_event.kind)
			TIMER_EXPIRED : begin
				`uvm_info(get_name(), "Timer expired", UVM_MEDIUM)
				next_state = model.state_EXPIRED;
			end

			WRITE_TIMER : begin
				model.timer_data = exit_event.timer_data;
				model.timer_start_time = $realtime;
				model.timer_duration_s = model.timer_data * 20.0e-9;
				model.timer_end_time = model.timer_start_time + model.timer_duration_s * 1.0s;
				next_state = model.state_RESTART;
			end

			default : begin
				`uvm_error(get_name(), {"Unexpected event kind: ", exit_event.kind.name()})
			end

		endcase

		change_state(next_state);

	endtask : body
	
	
	virtual function void handle_apb(input apb_rw apb_transfer);
		uvm_reg rg;
		event_t apb_event;
		int success;
		
		`uvm_info(get_name(), $sformatf("(%m) Transfer received %s", apb_transfer.convert2string()), UVM_HIGH)
		
		apb_event.kind = NONE;

		rg = model.reg_model.default_map.get_reg_by_offset(apb_transfer.addr);
		assert_rg_is_not_null : assert (rg);

		case (rg.get_name())
			"TIMER" : begin
				case (apb_transfer.kind)
					apb_rw::WRITE : begin
						apb_event.kind = WRITE_TIMER;
						apb_event.timer_data = apb_transfer.data[15:0];
						success = event_mbox.try_put(apb_event);
						assert_event_mbox_is_not_full : assert (success);
					end

					apb_rw::READ : begin
					end
				endcase
			end

			"INTERRUPT" : ;

		endcase
	endfunction : handle_apb
endclass : timer_state_RUNNING


class timer_state_EXPIRED extends timer_state_base;

	function new(string name, timer_model model);
		super.new(name, model);
	endfunction : new
	

	virtual task body();
		bit ok;

		`uvm_info(get_name(), $sformatf("(%m) Starting"), UVM_HIGH)
		
		ok = model.reg_model.TIMER.TIMER.predict(16'h0000, .kind (UVM_PREDICT_DIRECT));
		if (ok) begin
			model.reg_model.TIMER.TIMER.set_compare(UVM_CHECK);
		end
		else begin
			`uvm_warning(get_name(), "TIMER.TIMER direct prediction failed. Setting compare flag to UVM_NO_CHECK.");
			model.reg_model.TIMER.TIMER.set_compare(UVM_NO_CHECK);
		end

		ok = model.reg_model.INTERRUPT.EXPIRED.predict('b1, .kind (UVM_PREDICT_DIRECT));
		if (ok) begin
			model.reg_model.INTERRUPT.EXPIRED.set_compare(UVM_CHECK);
		end
		else begin
			`uvm_warning(get_name(), "INTERRUPT.EXPIRED direct prediction failed. Setting compare flag to UVM_NO_CHECK.");
			model.reg_model.INTERRUPT.EXPIRED.set_compare(UVM_NO_CHECK);
		end

		change_state(model.state_IDLE);
	endtask : body


	virtual function void handle_apb(input apb_rw apb_transfer);
		;
	endfunction : handle_apb
endclass : timer_state_EXPIRED


class timer_state_RESTART extends timer_state_base;
	bit[15:0] timer_data;

	function new(string name, timer_model model);
		super.new(name, model);
	endfunction : new
	

	virtual task body();
		
		`uvm_info(get_name(), $sformatf("(%m) Starting"), UVM_HIGH)

		change_state(model.state_RUNNING);
	endtask : body


	virtual function void handle_apb(input apb_rw apb_transfer);
		;
	endfunction : handle_apb
endclass : timer_state_RESTART


`endif // TIMER_VOLATILE_IMPL_SV

