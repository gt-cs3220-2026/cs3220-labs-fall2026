# HW0 Floating-Point Units

**Objective:** Implement IEEE-style floating-point add, multiply, and divide in Verilog for four formats used in modern accelerators.

**Description:** Each question is a self-contained FPU. `i_inst` selects the operation. Data width matches the format (unused high bits must stay 0 if you internally use a wider datapath). Inputs and results will not be NaN, Inf, or denormal, and divide-by-zero is not tested.

1. **Included modules:** a. FP32; b. BF16; c. FP16; d. FP8 E4M3
2. **Specification about each module:**
   1. [FP32 (4%)](./FP32/FP32.md)
   2. [BF16 (4%)](./BF16/BF16.md)
   3. [FP16 (4%)](./FP16/FP16.md)
   4. [FP8 E4M3 (4%)](./FP8E4M3/FP8E4M3.md)
3. Check [this](./ICE_environment_setup.pdf) for ICE environment setup.

**Submission Format:**

1. We use Gradescope for the code submission and grading.
2. Please submit **all four** files together to the **HW0** assignment: `fp32.v`, `bf16.v`, `fp16.v`, `fp8e4m3.v` (no need to zip—just upload the `*.v` files). DO NOT CHANGE THE FILENAME AND MODULENAME!

**Due:** Friday, Sep. 11, at 11:59 PM (2-hour grace period)

**Grading Policy**:

1. If you pass the test cases.
   1. Note: All test cases are generated for add, mul, and div (10 each, 30 total per module).
   2. Each module is out of **4.0**. HW0 total is **16.0**. Partial credit is awarded per passing vector. The take-home portion of HW0 will be rescaled from 16 points to [9 points](https://sites.google.com/view/gt-cs3220-fall26/course-policies?authuser=0).

**FAQ:**

[Q] How to debug the code?

[A] The gradescope will provide the input and output for both your code and the golden code if the test failed. You can compare the output to debug your code. Additionally, writing testbench is an important skill in processor design, you can also design your own testbench and install iverilog on your computer to debug the code.

[Q] Any online tutorials to watch?

[A] [link1](https://www.youtube.com/watch?v=lLg1AgA2Xoo&list=PLEBQazB0HUyT1WmMONxRZn9NmQ_9CIKhb&index=1): Focus on the concept and programing as we will use different devices

[link2](https://www.youtube.com/watch?v=9mpRF6bAY1g): modelsim (similar to vivado xsim)

[link3](https://www.youtube.com/watch?v=YodFKbKxElo&list=PLfGJEQLQIDBN0VsXQ68_FEYyqcym8CTDN), [link4](https://www.youtube.com/watch?v=S26TPZm4zzM&list=PL3Soy1ohxlP1TLpcbYXYcVWItRy_XrUk8): more comprehensive digital design and RTL programing tutorial videos