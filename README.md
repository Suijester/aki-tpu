# TPU-Style Matrix Multiplication Accelerator

**Achieved 181 MHz clock speed on 8x8 array (23.2 GFLOPS), 176 MHz clock speed on 16x16 array (90.6 GFLOPS) in simulation. Expended power of 0.285 W on-chip, with 26.3 Junction Temp.**

Synthesizable MatMul TPU-style accelerator implemented as a parameterizable systolic array, utilizing SystemVerilog. Features BRAM-inferrable double buffering to conceal I/O write latency, ReLu activation mux to enable full neural network layer execution, and scalable data sizes for different workloads. Minimally expensive on power, and timing constraints decrease minimally with array size scaling -- allowing high clock speeds regardless of matrix size.

## Operation
![TPU_1](https://github.com/user-attachments/assets/130be6fb-6c3b-4694-abdc-2de35c2f5459)
The MatMul Accelerator uses a systolic array structure for rapid multiplication, where inputs stream from a BRAM-inferrable memory bank into each Multiply-and-Accumulate Unit. Each 'MAC' unit keeps an internal register of the current matrix multiplication value. When two new inputs come in, they are multiplied and added to the internal register. These internal registers are combinationally passed to the register of output values.

## Benchmarking

For simulation and synthesis, LUT arrays were used for input matrix arrays to minimize critical timing path from BRAM fetch. Real FPGA deployment may want BRAM usage, dependent on the size of matrices being stored. _Buffers are designed to be BRAM-inferrable; this is suggested for larger workloads._ Additionally, for synthesis, DSP slices were used for multiplication, and caused the primary clock speed bottleneck, which could be improved through gate-level primitive implementation and breaking up the multiplicative workload.

### Resource and Utilization


### Timing & Power

