#  FPGA-based Sensor Interfacing System (HC-SR04 & DHT11)

##  Project Overview
This project implements a **complete RTL hardware architecture for interfacing external sensors** on a **Xilinx Basys 3 FPGA**. Instead of relying on an MCU and pre-written libraries, the timing diagrams and communication protocols of the **HC-SR04 ultrasonic sensor (Pulse-Width)** and the **DHT11 temperature & humidity sensor (Single-Wire)** were translated directly into **Finite State Machines (FSMs)** using **Verilog HDL**. The measured distance, temperature, and humidity are displayed in real time on the board's 4-digit 7-segment display.

##  Key Features
* **Microsecond Timebase:** Generated a 1MHz tick (HC-SR04) and a 100kHz tick (DHT11) from the 100MHz system clock to measure pulse widths in hardware without software-induced delays.
* **HC-SR04 Distance Controller:** Designed an FSM that generates the trigger pulse, measures the echo high time in 1us units, and converts it to centimeters (`Distance (cm) = Pulse Width (us) / 58`).
* **DHT11 Single-Wire Controller:** Controlled a bidirectional `inout` line with a tri-state buffer, decoded 40 bits of data based on pulse width, and verified the checksum in hardware.
* **Deadlock Prevention (Timeout):** Calculated the maximum valid duration of each step and added counter-based timeouts, so the FSM automatically returns to `IDLE` instead of hanging when a sensor stops responding.
* **FPGA Validation:** Synthesized and tested on a Digilent Basys 3 FPGA with real HC-SR04 and DHT11 sensors, displaying the results on the 7-segment display.

---

##  System Architecture

### 1. HC-SR04 Ultrasonic Distance Controller (`sr04_ctrl`)
Measures distance from the time-of-flight of the ultrasonic pulse. A new measurement starts automatically every **100ms**, satisfying the datasheet recommendation of a measurement cycle over 60ms.
* **FSM (4 states):** `IDLE` -> `TRIG` -> `WAIT` -> `CALC`. `WAIT` waits for the echo to rise, and `CALC` counts the echo high time.
* **Trigger Pulse:** Drives a trigger pulse of about **12us**, satisfying the sensor's minimum of 10us.
* **Timeout:** The longest valid echo is about 23.2ms (4m × 58us/cm). The FSM returns to `IDLE` if the echo does not rise within **30ms** (`WAIT`) or stays high longer than **25ms** (`CALC`).

### 2. DHT11 Temperature & Humidity Controller (`dht11_controller`)
Manages the sensor's bidirectional Single-Wire protocol.
* **FSM (8 states):** `IDLE` -> `START` -> `WAIT` -> `SYNC_L` -> `SYNC_H` -> `DATA_SYNC` -> `DATA_C` -> `STOP`.
* **Start Signal:** Drives the line LOW for **19ms** (datasheet minimum: 18ms), releases it, and switches to input mode after about 30us.
* **Bit Decoding:** A high time of **50us or more** is decoded as `1`, otherwise `0`.
* **Checksum Verification:** Compares the 8-bit sum of the four data bytes with the checksum byte, and asserts `dht11_valid` only when they match.
* **Timeout:** If a transaction does not finish within **1 second** (100,000 × 10us), the FSM releases the line and returns to `IDLE`.
* **Trigger:** A measurement starts on a button press, or automatically when the idle counter expires.

### 3. Display & Input
* **FND Controller:** Converts the binary values to BCD and multiplexes them onto the 4-digit 7-segment display.
* **Button Debounce:** Debounces the push buttons and generates a single-cycle pulse with an edge detector.

---

##  Timing Parameters

| Parameter | Value | Reason |
| :--- | :--- | :--- |
| HC-SR04 trigger pulse | ~12us | Datasheet minimum 10us |
| HC-SR04 measurement period | 100ms | Datasheet recommends over 60ms |
| HC-SR04 echo timeout (`CALC`) | 25ms | Max valid echo ≈ 23.2ms (4m × 58us/cm) |
| HC-SR04 response timeout (`WAIT`) | 30ms | No echo → return to `IDLE` |
| DHT11 start signal | 19ms LOW | Datasheet minimum 18ms |
| DHT11 bit threshold | 50us | `0`: ~26–28us, `1`: ~70us high time |
| DHT11 transaction timeout | 1s | Recover when the sensor stops mid-transmission |

---

##  Engineering Challenges & Solutions
* **FSM Hang on Sensor Failure:** The FSM froze when the DHT11 was disconnected mid-transmission (e.g., stuck at bit 31 in the `DATA_SYNC` state) or the HC-SR04 echo was lost. Added counter-based timeouts calculated from the maximum valid duration of each step, so the system recovers on the next cycle without a manual reset.
* **Button Bouncing:** Mechanical bouncing caused multiple unintended inputs. Added a debounce circuit and an edge detector so that each press produces exactly one pulse.

---

##  Limitations & Future Work
1. **Input Synchronization:** In the files in `source/`, the asynchronous `echo` and `dhtio` inputs are sampled directly by the FSMs. The final version shown in `Sensor_project.pdf` adds **2-stage synchronizers and edge detectors** to these inputs (verified in a testbench with an asynchronous input), and `source/` will be updated to that version.
2. **Division Logic:** The current `/ 58` operator synthesizes a combinational divider. The final version replaces it with **subtraction-based sequential division** in a 5-state FSM (`CALC_1`, `CALC_2`) to avoid timing slack issues.

> **Note:** The final design presented in [`Sensor_project.pdf`](Sensor_project.pdf) uses a 5-state HC-SR04 FSM (`IDLE → TRIG → WAIT → CALC_1 → CALC_2`), 25ms timeouts for both `WAIT` and `CALC_1`, 2-stage input synchronizers, and subtraction-based division. The files in `source/` are an earlier version (4-state FSM, 30ms `WAIT` timeout).
---

##  Development Environment
* **Target Hardware:** Xilinx Basys 3 (Artix-7)
* **Peripherals:** HC-SR04 Ultrasonic Sensor, DHT11 Temperature & Humidity Sensor
* **Language:** Verilog HDL
* **EDA Tool:** Xilinx Vivado (Synthesis, Implementation, Bitstream Generation, Simulation)
