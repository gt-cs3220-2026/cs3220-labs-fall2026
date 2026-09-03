### Prior knowledge

### Always clocked block: always @(*)

Since digital circuits are composed of logic gates connected with wires, any circuit can be expressed as some combination of modules and assign statements. However, sometimes this is not the most convenient way to describe the circuit. *Procedures* (of which always blocks are one example) provide an alternative syntax for describing circuits.

For synthesizing hardware, two types of always blocks are relevant:

- Combinational:
    
    always @(*)
    
- Clocked:
    
    always @(posedge clk)
    

Combinational always blocks are equivalent to assign statements, thus there is always a way to express a combinational circuit both ways. The choice between which to use is mainly an issue of which syntax is more convenient. **The syntax for code inside a procedural block is different from code that is outside.** Procedural blocks have a richer set of statements (e.g., if-then, case), cannot contain continuous assignments*, but also introduces many new non-intuitive ways of making errors. (**Procedural continuous assignments* do exist, but are somewhat different from *continuous assignments*, and are not synthesizable.)

For example, the assign and combinational always block describe the same circuit. Both create the same blob of combinational logic. Both will recompute the output whenever any of the inputs (right side) changes value. **`assign** out1 = a & b | c ^ d;
**always @(*)** out2 = a & b | c ^ d;`

![Untitled](https://hdlbits.01xz.net/mw/images/2/2b/Alwayscomb.png)

For combinational always blocks, always use a sensitivity list of (*). Explicitly listing out the signals is error-prone (if you miss one), and is ignored for hardware synthesis. If you explicitly specify the sensitivity list and miss a signal, the synthesized hardware will still behave as though (*) was specified, but the simulation will not match the hardware's behaviour. (In SystemVerilog, use always_comb.)

A note on wire vs. reg: The left-hand-side of an assign statement must be a *net* type (e.g., wire), while the left-hand-side of a procedural assignment (in an always block) must be a *variable* type (e.g., reg). These types (wire vs. reg) have nothing to do with what hardware is synthesized, and is just syntax left over from Verilog's use as a hardware *simulation* language.

### Always clocked block: always @(posedge clk); Sequential logic

Clocked always blocks create a blob of combinational logic just like combinational always blocks, but also creates a set of flip-flops (or "registers") at the output of the blob of combinational logic. Instead of the outputs of the blob of logic being visible immediately, the outputs are visible only immediately after the next (posedge clk).

### **Blocking vs. Non-Blocking Assignment**

There are three types of assignments in Verilog:

- **Continuous** assignments (). Can only be used when **not** inside a procedure ("always block").
    
    assign x = y;
    
- Procedural **blocking** assignment: (). Can only be used inside a procedure.
    
    x = y;
    
- Procedural **non-blocking** assignment: (). Can only be used inside a procedure.
    
    x <= y;
    

In a **combinational** always block, use **blocking** assignments. In a **clocked** always block, use **non-blocking** assignments. A full understanding of why is not particularly useful for hardware design and requires a good understanding of how Verilog simulators keep track of events. Not following this rule results in extremely hard to find errors that are both non-deterministic and differ between simulation and synthesized hardware.

### Practice:

A D flip-flop is a circuit that stores a bit and is updated periodically, at the (usually) positive edge of a clock signal.

![Untitled](https://hdlbits.01xz.net/mw/images/6/6c/Dff.png)

D flip-flops are created by the logic synthesizer when a clocked always block is used. A D flip-flop is the simplest form of "blob of combinational logic followed by a flip-flop" where the combinational logic portion is just a wire.

Create a single D flip-flop.