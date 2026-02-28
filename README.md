# UART_Verification_using_UVM
•	Performed verification with multiple test scenarios such as write/read operations, fill full FIFO, bad parity injection, baud rate configuration in directed and random tests on QuestaSim.
## Features

- **Testbench Environment**: Built using UVM to verify UART functionality, including edge cases.
- **Coverage**: Functional coverage to ensure all possible UART states and transitions are exercised.
- **Simulation**: Run on QuestaSim with detailed logs and waveform analysis.


## UART Frame Structure (8N1 with Optional Parity)

A UART frame consists of:

- **Start Bit** – Always `0` (low), indicating the beginning of a frame  
- **8 Data Bits** – Transmitted LSB (least significant bit) first  
- **Optional Parity Bit** – May be included for error checking  
- **Stop Bit** – Always `1` (high), indicating the end of a frame  


## 🧩 UART Frame Illustration

<img width="880" height="128" alt="UART frame format" src="https://github.com/user-attachments/assets/5c713b74-d1e5-4601-a40b-5e95de6dd5b5" />

