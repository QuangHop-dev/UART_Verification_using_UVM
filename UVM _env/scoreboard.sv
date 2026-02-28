class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_analysis_imp #(UART_sequence_item, scoreboard) scoreboard_imp;

  int unsigned match_total;
  int unsigned mismatch_total;

  // Expected queue (push on WR, pop on RD)
  byte exp_q[$];

  // Optional strictness at end of test (off by default)
  bit strict_end_check = 1'b0;

  // Match-group compression (run-length encoding)
  bit          grp_valid;
  logic [7:0]  grp_val;
  time         grp_t_first;
  time         grp_t_last;
  int unsigned grp_count;

  function new(string name = "scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scoreboard_imp = new("scoreboard_imp", this);

    match_total    = 0;
    mismatch_total = 0;

    grp_valid   = 0;
    grp_val     = '0;
    grp_t_first = 0;
    grp_t_last  = 0;
    grp_count   = 0;

    exp_q.delete();

    // Enable strict end check with +STRICT_SB
    if ($test$plusargs("STRICT_SB")) strict_end_check = 1'b1;
  endfunction

  // Flush current group to console (1 line per run)
  function void flush_group();
    if (!grp_valid) return;

    `uvm_info("scoreboard",
      $sformatf("MATCH x%0d value=0x%02h time=%0t -> %0t (match_total=%0d)",
                grp_count, grp_val, grp_t_first, grp_t_last, match_total),
      UVM_LOW)

    grp_valid = 0;
    grp_count = 0;
  endfunction

  function void write(UART_sequence_item t);
    UART_sequence_item item;
    byte exp;

    item = UART_sequence_item::type_id::create("item");
    $cast(item, t);

    // Reset breaks the stream: clear expected queue + flush log group
    if (item.kind == UART_sequence_item::TR_RESET) begin
      flush_group();
      exp_q.delete();
      return;
    end

    // Track expected bytes on accepted writes
    if (item.kind == UART_sequence_item::TR_WRITE) begin
      exp_q.push_back(item.w_data);
      return;
    end

    // Only compare on READ
    if (item.kind != UART_sequence_item::TR_READ) return;

    // If we have no expected data (e.g., external RX injection), just ignore compare
    if (exp_q.size() == 0) begin
      flush_group();
      `uvm_info("scoreboard",
        $sformatf("READ observed with empty expected queue: got=0x%02h @%0t (likely external RX)", item.r_data, $time),
        UVM_LOW)
      return;
    end

    exp = exp_q.pop_front();

    if (exp === item.r_data) begin
      match_total++;

      // Run-length encode repeated matches of same value
      if (grp_valid && (grp_val === exp)) begin
        grp_count++;
        grp_t_last = $time;
      end else begin
        flush_group();
        grp_valid   = 1;
        grp_val     = exp;
        grp_count   = 1;
        grp_t_first = $time;
        grp_t_last  = $time;
      end

    end else begin
      // mismatch: flush group first so logs don't mix
      flush_group();

      mismatch_total++;
      `uvm_error("scoreboard",
        $sformatf("MISMATCH exp=0x%02h got=0x%02h @%0t (mismatch_total=%0d)",
                  exp, item.r_data, $time, mismatch_total))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    // Flush last group
    flush_group();

    if (exp_q.size() != 0) begin
      if (strict_end_check) begin
        `uvm_warning("scoreboard",
          $sformatf("Expected queue not empty at end of test: remaining=%0d", exp_q.size()))
      end else begin
        `uvm_info("scoreboard",
          $sformatf("Expected queue remaining at end of test (OK for TX-full directed tests): remaining=%0d", exp_q.size()),
          UVM_LOW)
      end
    end

    `uvm_info("scoreboard",
      $sformatf("SCOREBOARD SUMMARY: match=%0d mismatch=%0d",
                match_total, mismatch_total),
      UVM_NONE)
  endfunction

endclass
