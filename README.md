# UART_Verification_using_UVM
•	Performed verification with multiple test scenarios such as write/read operations, fill full FIFO, bad parity injection, baud rate configuration in directed and random tests on QuestaSim.
## Features

- **Testbench Environment**: Built using UVM to verify UART functionality, including some edge cases.
- **Coverage**: Functional coverage to ensure all possible UART states and transitions are exercised.
- **Simulation**: Run on QuestaSim with detailed logs and waveform analysis.


## UART Frame Structure (8N1 with Optional Parity)

A UART frame consists of:

- **Start Bit** – Always `0` (low), indicating the beginning of a frame  
- **8 Data Bits** – Transmitted LSB (least significant bit) first  
- **Optional Parity Bit** – May be included for error checking  
- **Stop Bit** – Always `1` (high), indicating the end of a frame  


# UART Frame Illustration
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


# Table. UART IP Interface Signal Description
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


