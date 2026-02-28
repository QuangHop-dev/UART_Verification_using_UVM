# UART_Verification_using_UVM
•	Performed verification with multiple test scenarios such as write/read operations, fill full FIFO, bad parity injection, baud rate configuration in directed and random tests on QuestaSim.
## Features

- **Testbench Environment**: Built using UVM to verify UART functionality, including some edge cases.
- **Coverage**: Functional coverage to ensure all possible UART states and transitions are exercised.
- **Simulation**: Run on QuestaSim with detailed logs and waveform analysis.


## UART Frame Structure

### UART frame consists of:

- **Start Bit** – Always `0` (low), indicating the beginning of a frame  
- **8 Data Bits** – Transmitted LSB (least significant bit) first  
- **Optional Parity Bit** – May be included for error checking  
- **Stop Bit** – Always `1` (high), indicating the end of a frame  


### UART Frame Illustration
<p align="center">
  <img width="880" height="128" alt="UART frame format" src="https://github.com/user-attachments/assets/5c713b74-d1e5-4601-a40b-5e95de6dd5b5" />
</p>

## UART DESIGN

### Design Overview

The UART IP consists of four main functional blocks: `UART_TX`, `UART_RX`, `FIFO_TX`, `FIFO_RX`, and a `Baud_Gen` module.  
The FIFO blocks are used to buffer transmit and receive data, while the baud rate generator provides timing control for both transmission and reception.

The overall data flow is as follows:

- Write operation → `FIFO_TX` → `UART_TX` → Serial output (`tx`)
- Serial input (`rx`) → `UART_RX` → `FIFO_RX` → Read operation

Below is the block diagram of the UART IP:
<p align="center">
  <img width="885" height="491" alt="Block diagram of the IP UART design" src="https://github.com/user-attachments/assets/1f944b52-62f1-4e1f-96be-ff030aeb9e16" />
</p>


### Table. UART IP Interface Signal Description
<div align="center">
  
  | Signal         | Direction | Description |
  |:-------------:|:---------:|:----------:|
  | clk           | Input     | System clock for the entire UART IP |
  | reset         | Input     | Reset signal that initializes the system to its default state |
  | wr_uart       | Input     | Write enable signal for FIFO_TX (request to transmit data) |
  | w_data[7:0]   | Input     | 8-bit data input to FIFO_TX for transmission |
  | divsr[9:0]    | Input     | Baud rate divisor used to generate transmit/receive timing |
  | rd_uart       | Input     | Read enable signal for FIFO_RX (read received data) |
  | rx            | Input     | Serial input signal |
  | tx            | Output    | Serial output signal |
  | tx_done       | Output    | Indicates completion of one frame/byte transmission |
  | tx_full       | Output    | Indicates FIFO_TX is full (cannot accept more data) |
  | r_data[7:0]   | Output    | 8-bit data output from FIFO_RX |
  | rx_empty      | Output    | Indicates FIFO_RX is empty (no data available) |
  | rx_done       | Output    | Indicates completion of one frame/byte reception |
  | incorrect_send| Output    | Indicates an invalid or corrupted received frame |
  
</div>

## UVM Testbench
### UVM environment structure
<p align="center">
  <img width="872" height="416" alt="Block diagram of UVM environment construction for UART design testing" src="https://github.com/user-attachments/assets/7ba78d0b-8882-4c8b-8c95-e24adb34b6fb" />
</p>

### UVM Testbench Topology & Factory Registrations
<p align="center">
  <img width="433" height="319" alt="UVM topology of the UART test environment" src="https://github.com/user-attachments/assets/6bb5f864-3a72-4aa5-a3d3-2824d55ca59e" />
</p>

### Data Transmitting and receiving

- w_data signal is the write data at the TX and the r_data signal is the read data at the RX.

<p align="center">
  <img width="1262" height="715" alt="Simulation results of the UART transmission and reception function" src="https://github.com/user-attachments/assets/9ee4d5d8-7b6e-4fdf-87fc-e85184afb170" />
</p>

### FSM Of TX and RX & FIFO Behavior

- TX/n_reg is the current state of the TX and RX/n_reg is the same for RX and FSM starts when start bit 0 arrives.
- States are {start , Data Transfer/Receiving , Parity , End}.
- Also FIFO_RX is the fifo of the RX and the w_data is the data that received by the RX (when the receiver receives a bit the shift register will add it).
- In FIFO_RX/r_data is the read data in FIFO and it will extract the data from the fifo when a read signal arrives.

<p align="center">
  <img width="1231" height="734" alt="Simulation results of FSM for TXRX and data pushread mechanism via FIFO_RX" src="https://github.com/user-attachments/assets/5425d35c-a1d6-4e7a-955c-b0e200448e87" />
</p>

### Data Flow
- rx_data_out signal also represents a shift register to the received data (look how the data flow in the register).

<p align="center">
  <img width="1214" height="710" alt="data_flow simulation results" src="https://github.com/user-attachments/assets/9d19d984-28e1-48ee-8c9c-c83f963233f8" />
</p>

## Results of the testbench
- Match is counting the success receiving and mismatch is the opposite.

<p align="center">
  <img width="1230" height="785" alt="Simulation results (log)" src="https://github.com/user-attachments/assets/de542816-8693-4b0d-9084-eee787747c55" />
</p>

### Report Summary
<p align="center">
  <img width="627" height="211" alt="UVM report summary results" src="https://github.com/user-attachments/assets/2e09b7db-51bb-4c15-b939-48716e797366" />
</p>

## Coverage Result
<p align="center">
  <img width="627" height="230" alt="Summary of coverage report results for verify plan" src="https://github.com/user-attachments/assets/1c701ca8-3148-4b84-a237-7e8df2560206" />
</p>



