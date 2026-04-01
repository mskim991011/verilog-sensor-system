# FPGA-based Advanced Sensor Interfacing System (HC-SR04 & DHT11)

## Project Overview
This project showcases a complete **Register-Transfer Level (RTL) hardware architecture** designed to interface with external environmental sensors using a Xilinx Basys 3 FPGA. 

Unlike conventional MCU-based (Arduino/Raspberry Pi) projects that rely on sequential software instructions and pre-built libraries, this system is engineered entirely from scratch using **Verilog HDL**. It demonstrates the ability to directly control hardware peripherals by translating complex timing diagrams and communication protocols (Pulse-Width and Single-Wire) into robust digital logic circuits and Finite State Machines (FSMs). The real-time sensor data is processed and displayed continuously on a 4-digit 7-segment display.

---

## System Architecture & Data Flow
The architecture is strictly modularized to separate timing generation, signal synchronization, protocol control, and data display.

1. **Microsecond Timing Generator (`tick_gen_1us`):** - Generates a precise 1MHz clock enable tick from the Basys 3's 100MHz system clock. This serves as the fundamental timebase for all sensor protocol measurements, ensuring highly accurate pulse width calculations without software-induced delays.

2. **Asynchronous Signal Synchronization:**
   - External signals (`echo` from HC-SR04, `dhtio` from DHT11) are inherently asynchronous to the FPGA's system clock. To prevent **Metastability** and system failures, robust 2-stage Synchronizers and Edge Detectors (using D-Flip-Flops) are implemented on all incoming sensor signals.

3. **Sensor Control FSMs & Data Processing:**
   - Independent FSMs handle the unique protocols of the HC-SR04 and DHT11. They process the synchronized signals, extract the raw data, perform arithmetic calculations (like division for distance and addition for checksum), and output the final validated digital values.

4. **Display Controller (`fnd_controller`):**
   - Receives the 16-bit binary values from the sensor controllers, converts them using a hardware BCD (Binary-Coded Decimal) logic, and multiplexes them onto the 7-segment display at a high refresh rate.

---

## Detailed Module Specifications

### 1. HC-SR04 Ultrasonic Distance Controller
This module measures physical distance by analyzing the time-of-flight of ultrasonic pulses.
* **Precise Trigger Generation:** Outputs a strict **10us TTL trigger pulse** to initiate the sensor burst.
* **5-State FSM Design:** Operates through a structured state machine (`IDLE` -> `TRIG` -> `WAIT` -> `CAL_1` -> `CAL_2`) to meticulously track the rising and falling edges of the echo signal.
* **Hardware Arithmetic Calculation:** Converts the echo pulse width (in microseconds) directly into centimeters using the standard formula: `Distance (cm) = Pulse Width (uS) / 58`. Subtraction-based sequential division logic is utilized to meet tight timing constraints and prevent slack issues.
* **Deadlock Prevention (Timeout):** Incorporates a critical **25ms Timeout Exception Handling**. If the echo signal is lost or the object is out of the 4m range, the FSM automatically resets to `IDLE`. This guarantees that the hardware never enters an infinite wait state (System Hang).

### 2. DHT11 Temperature & Humidity Controller
This module manages a proprietary bidirectional Single-Wire (One-Wire) protocol.
* **Tri-state Buffer Management:** Safely controls a single `inout` port for the DHT11 data line. It actively drives the line LOW for **19ms** (Start Signal) and then releases it (High-Z) to listen for the sensor's 80us response and subsequent data stream.
* **40-bit Continuous Data Parsing:** Captures a continuous stream of 40 bits containing Integral/Decimal Relative Humidity, Integral/Decimal Temperature, and a Checksum.
* **Timing-based Bit Decoding:** Specifically designed logic evaluates the duration of each high-voltage pulse. Pulses shorter than 50us are decoded as logic `0`, and pulses longer than 50us are decoded as logic `1`.
* **Data Integrity (Checksum Verification):** Hardware-level parity checking is performed on the fly. The lower 8 bits (Checksum) are compared against the sum of the upper 32 bits. The module asserts a `Valid` signal only if the transmission is 100% error-free.
* **Auto-Reset & Polling:** Implemented an internal counter that automatically requests new data from the sensor at stable 1-second intervals after a system reset.

---

## Engineering Challenges & Solutions

* **Challenge:** Unstable state transitions caused by bouncing or asynchronous external signals from the sensors.
* **Solution:** Implemented structural edge detectors combined with 2-stage synchronizers. This forced the asynchronous sensor inputs to align with the FPGA's internal clock domains, completely resolving unpredictable FSM behavior.

* **Challenge:** FSM freezing when the DHT11 sensor was disconnected mid-transmission or the HC-SR04 pulse was lost.
* **Solution:** Developed a robust counter-based timeout mechanism. By calculating the maximum possible duration for a valid transaction, the system forces a state reset if the threshold is exceeded, ensuring continuous and stable operation.

---

## Development Environment
* **Target Hardware:** Xilinx Basys 3 Artix-7 FPGA board.
* **External Peripherals:** HC-SR04 Ultrasonic Sensor, DHT11 Temperature & Humidity Sensor.
* **Language:** Verilog HDL.
* **EDA Tool:** Xilinx Vivado ML Edition (RTL Synthesis, Implementation, Bitstream Generation, and Timing Simulation).
* **Key Focus Areas:** RTL Design, FSM, Timing Constraints, Asynchronous Signal Handling, Hardware Arithmetic.
