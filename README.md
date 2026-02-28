# UART_Verification_using_UVM
•	Performed verification with multiple test scenarios such as write/read operations, fill full FIFO, bad parity injection, baud rate configuration in directed and random tests on QuestaSim.
## 🚀 Features

- **Testbench Environment**: Built using UVM to verify UART functionality, including edge cases.
- **Coverage**: Functional coverage to ensure all possible UART states and transitions are exercised.
- **Simulation**: Run on QuestaSim with detailed logs and waveform analysis.

---

## 📡 UART Frame Structure (8N1 with Optional Parity)

A UART frame consists of:

- **Start Bit** – Always `0` (low), indicating the beginning of a frame  
- **8 Data Bits** – Transmitted LSB (least significant bit) first  
- **Optional Parity Bit** – May be included for error checking  
- **Stop Bit** – Always `1` (high), indicating the end of a frame  

---

## 🧩 UART Frame Illustration

```text
Clock Signal -->
clk:   _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_

Bit Periods -->
+---+----+----+----+----+----+----+----+----+--------+---+
| 0 | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | Parity | 1 |
+---+----+----+----+----+----+----+----+----+--------+---+
  ^    ^    ^    ^    ^    ^    ^    ^    ^      ^      ^
 Start  D0   D1   D2   D3   D4   D5   D6   D7   Parity  Stop
 Bit                                                Bit
