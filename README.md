# TPU-Style Matrix Multiplication Accelerator

**Achieved 182 MHz clock speed on 8x8 array (23.2 GFLOPS), 177 MHz clock speed on 16x16 array (90.6 GFLOPS) in simulation. Expended power of 0.285 W on-chip, with 26.3 Junction Temp.**

Synthesizable MatMul TPU-style accelerator implemented as a parameterizable systolic array, utilizing SystemVerilog. Features BRAM-inferrable double buffering to conceal I/O write latency, ReLu activation mux to enable full neural network layer execution, and scalable data sizes for different workloads. Minimally expensive on power, and timing constraints decrease minimally with array size scaling -- allowing high clock speeds regardless of matrix size. Implemented testbench to simplify testing streaming inputs for users.

## Architecture
<img src="https://github.com/user-attachments/assets/130be6fb-6c3b-4694-abdc-2de35c2f5459" height="800">


The MatMul Accelerator uses a systolic array structure for rapid multiplication, where inputs stream from a BRAM-inferrable memory bank into each Multiply-and-Accumulate Unit. Each 'MAC' unit keeps an internal register of the current matrix multiplication value. When two new inputs come in, they are multiplied and added to the internal register. These internal registers are combinationally passed to the register of output values. Multiplication is synthesized to classical DSP multipliers.

Furthermore, the matrix supports double buffering to hide I/O latency - pass additional matrices before the start of computation to fill the secondary buffer, simultaneously as matmul executes.

## Benchmarking

For simulation and synthesis, LUT arrays were used for input matrix arrays to minimize critical timing path from BRAM fetch. Real FPGA deployment may want BRAM usage, dependent on the size of matrices being stored. _Buffers are designed to be BRAM-inferrable; this is suggested for larger workloads._ Additionally, for synthesis, DSP slices were used for multiplication, and caused the primary clock speed bottleneck, which could be improved through gate-level primitive implementation and breaking up the multiplicative workload.

### Resource and Utilization
The top module attempted to preserve all logic during synthesis using anti-pruning methods. The performance numbers reported account for this, though some pruning may still have occurred.

#### 8x8 Systolic Array
| Resource | Utilization |
| :--- | :--- |
| LUT | 972 |
| LUTRAM | 360 |
| FF | 2256 |
| DSP | 64 |
| IO | 9 |
| BUFG | 1 |

#### 16x16 Systolic Array
| Resource | Utilization |
| :--- | :--- |
| LUT | 4425 |
| LUTRAM | 248 |
| FF | 4424 |
| DSP | 256 |
| IO | 9 |
| BUFG | 1 |

### Timing & Power
Measured in Vivado simulation, simulated device was an Artix-7 family FPGA.
| Matrix Size | Clock Speed | GFLOPS | Power Consumption |
| :--- | :--- | :--- | :--- |
| 8x8 | 182 MHZ | 23.296 | 0.235W |
| 16x16 | 177 MHZ | 90.624 | 0.285W |

## Running Simulation
- Create a new project in Vivado targeting an Artix-7 FPGA, or in another synthesis tool of your choice.
- Add all the `.sv` files (apart from `topModule_tb.sv`) as design sources.
- Add `topModule_tb.sv` as a simulation source, and mark it as the top module.
- Use the testbench for simulation to test larger size matrix multiplication, or to verify correctness.
- All files are synthesizable (tested on Vivado), so implement a top module if necessary and it should run well!

## Challenges During Implementation
I didn't implement every module elastically, leading to tricky problems dealing with timing - notably in the control unit, where the accelerator determined whether to read from the buffer, and if so, where. Calculating the timing when each MAC unit would complete was tricky. Additionally, there was an edge case when attempting to make the buffers BRAM-inferrable - registering reads caused desync with the control unit. Fixing this was difficult, but I resolved it by requesting reads one cycle ahead of the cycle counter artificially. 

Additionally, another problem during implementation was breaking up the long critical path between reading from both buffers, deciding which read vector to use (as there are two buffers), passing the selected input to the MACs, and then performing multiplication. To break up this critical path, I registered the inputs into the MACs, which caused an extra cycle of latency, but improved throughput. The critical path then became the DSP multiplier, which forced completion in one cycle, therefore becoming the new max delay.

If I were to solve this in the future, I'd likely implement some type of pipelined multiplier, whether it be implemented at a gate-level or higher level, preventing it from mapping directly to DSP. By pipelining the multiplication, the critical path would be broken up, enabling the accelerator to reach an upwards of 200-225 MHz before being throttled by something else.
