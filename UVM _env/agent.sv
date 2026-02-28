class agent extends uvm_agent;
  `uvm_component_utils(agent)

  // Allow reuse: ACTIVE = has driver/sequencer, PASSIVE = monitor-only
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  sequencer UART_sequencer;
  driver    UART_driver;
  monitor   UART_monitor;

  function new(string name = "agent", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Priority: config_db -> plusargs -> default
    void'(uvm_config_db#(uvm_active_passive_enum)::get(this, "", "is_active", is_active));
    if ($test$plusargs("AGENT_PASSIVE")) is_active = UVM_PASSIVE;
    if ($test$plusargs("AGENT_ACTIVE"))  is_active = UVM_ACTIVE;

    UART_monitor = monitor::type_id::create("UART_monitor", this);

    if (is_active == UVM_ACTIVE) begin
      UART_sequencer = sequencer::type_id::create("UART_sequencer", this);
      UART_driver    = driver   ::type_id::create("UART_driver",    this);
    end
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (is_active == UVM_ACTIVE) begin
      UART_driver.seq_item_port.connect(UART_sequencer.seq_item_export);
    end
  endfunction

endclass
