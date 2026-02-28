class test extends uvm_test;
  `uvm_component_utils(test)

  env UART_env;

  // Optional: let the same test run in PASSIVE mode (monitor-only)
  uvm_active_passive_enum is_active = UVM_ACTIVE;

  function new(string name = "test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Optional passive mode (no new cfg file needed)
    if ($test$plusargs("AGENT_PASSIVE")) is_active = UVM_PASSIVE;
    if ($test$plusargs("AGENT_ACTIVE"))  is_active = UVM_ACTIVE;

    uvm_config_db#(uvm_active_passive_enum)::set(this, "UART_env.UART_agent", "is_active", is_active);

    UART_env = env::type_id::create("UART_env", this);
  endfunction

  // Giảm spam log: chỉ giữ ERROR của scoreboard, không in MATCH lặp lại
  //function void start_of_simulation_phase(uvm_phase phase);
  //  super.start_of_simulation_phase(phase);
  //
  //  // Với log của mày đang hiện "[scoreboard]" -> report_id thường là "scoreboard"
  //  uvm_root::get().set_report_id_verbosity_hier("scoreboard", UVM_ERROR);
  //endfunction

  task run_phase(uvm_phase phase);
    // ---- sequence handles (khai báo trước statements để tránh lỗi parser) ----
    reset_sequence         rst;
    all_zero_sequence      s0;
    all_one_sequence       s1;
    pat_aa_sequence        saa;
    pat_55_sequence        s55;
    fill_tx_full_sequence  fill;
    random_mix_sequence    rseq;
    rx_bad_parity_sequence badpar;

    // ---- knobs ----
    int unsigned fill_depth;
    int unsigned ext_nframes;
    int unsigned passive_cycles;

    phase.raise_objection(this);

    // PASSIVE mode: no stimulus, only observe
    passive_cycles = 2000;
    void'($value$plusargs("PASSIVE_CYCLES=%d", passive_cycles));
    if (is_active == UVM_PASSIVE) begin
      `uvm_info(get_type_name(),
        $sformatf("AGENT_PASSIVE enabled: no stimulus. Waiting %0d cycles then ending test.", passive_cycles),
        UVM_LOW)
      repeat (passive_cycles) @(UART_env.UART_agent.UART_monitor.intf.mon_cb);
      phase.drop_objection(this);
      return;
    end

    // Defaults
    fill_depth  = 32;
    ext_nframes = 10;

    // Overrides from plusargs
    void'($value$plusargs("FILL_DEPTH=%d", fill_depth));
    void'($value$plusargs("EXT_NFRAMES=%d", ext_nframes));

    // 0) Reset luôn chạy đầu tiên
    rst = reset_sequence::type_id::create("rst");
    rst.start(UART_env.UART_agent.UART_sequencer);

    // Nếu chỉ muốn chạy external RX inject để hit incorrect_send rồi thoát
    if ($test$plusargs("EXT_RX_ONLY")) begin
      badpar = rx_bad_parity_sequence::type_id::create("badpar");
      badpar.n_frames = ext_nframes;
      badpar.start(UART_env.UART_agent.UART_sequencer);

      phase.drop_objection(this);
      return;
    end

    // =========================================================
    // PHASE 1: Directed / Coverage-driven (giữ coverage 100%)
    // =========================================================
    if (!$test$plusargs("NO_DIRECTED")) begin
      // Hit bins data patterns
      s0  = all_zero_sequence::type_id::create("s0");
      s0.start(UART_env.UART_agent.UART_sequencer);

      s1  = all_one_sequence::type_id::create("s1");
      s1.start(UART_env.UART_agent.UART_sequencer);

      saa = pat_aa_sequence::type_id::create("saa");
      saa.start(UART_env.UART_agent.UART_sequencer);

      s55 = pat_55_sequence::type_id::create("s55");
      s55.start(UART_env.UART_agent.UART_sequencer);

      // fill TX (hit tx_full bins + boundary)
      fill = fill_tx_full_sequence::type_id::create("fill_00");
      fill.fill_byte = 8'h00;
      fill.depth     = fill_depth;
      fill.start(UART_env.UART_agent.UART_sequencer);

      fill = fill_tx_full_sequence::type_id::create("fill_FF");
      fill.fill_byte = 8'hFF;
      fill.depth     = fill_depth;
      fill.start(UART_env.UART_agent.UART_sequencer);

      fill = fill_tx_full_sequence::type_id::create("fill_AA");
      fill.fill_byte = 8'hAA;
      fill.depth     = fill_depth;
      fill.start(UART_env.UART_agent.UART_sequencer);

      fill = fill_tx_full_sequence::type_id::create("fill_55");
      fill.fill_byte = 8'h55;
      fill.depth     = fill_depth;
      fill.start(UART_env.UART_agent.UART_sequencer);
    end

    // Optional: chạy inject error RX (nếu mày muốn test incorrect_send trong cùng run)
    if ($test$plusargs("EXT_RX")) begin
      badpar = rx_bad_parity_sequence::type_id::create("badpar");
      badpar.n_frames = ext_nframes;
      badpar.start(UART_env.UART_agent.UART_sequencer);
    end

    // =========================================================
    // PHASE 2: Random / Stress (system-like)
    // =========================================================
    if (!$test$plusargs("NO_RANDOM")) begin
      rseq = random_mix_sequence::type_id::create("rseq");
      // random_mix_sequence tự đọc plusargs (RAND_TXN, RAND_MAX_BURST...)
      rseq.start(UART_env.UART_agent.UART_sequencer);
    end

    phase.drop_objection(this);
  endtask

endclass
