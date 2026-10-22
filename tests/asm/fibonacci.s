#=============================================================================
# Fibonacci Sequence Generator (Real-World Benchmark Program)
# Computes the first 10 Fibonacci numbers and writes them to data memory.
# Demonstrates looping, memory store/load, register hazards, and branches.
#=============================================================================
    addi x1, x0, 0         # F(0) = 0
    addi x2, x0, 1         # F(1) = 1
    addi x3, x0, 10        # Loop counter N = 10
    addi x4, x0, 0         # Loop index i = 0
    addi x5, x0, 0         # Memory byte pointer = 0

    # Store F(0) and F(1)
    sw   x1, 0(x5)         # Mem[0] = 0
    addi x5, x5, 4         # Mem pointer = 4
    sw   x2, 0(x5)         # Mem[4] = 1

fib_loop:
    beq  x4, x3, fib_done  # If i == 10, exit loop
    add  x6, x1, x2        # F(n) = F(n-1) + F(n-2)
    addi x5, x5, 4         # Advance memory pointer
    sw   x6, 0(x5)         # Store F(n) into memory
    addi x1, x2, 0         # F(n-2) = F(n-1)
    addi x2, x6, 0         # F(n-1) = F(n)
    addi x4, x4, 1         # i = i + 1
    beq  x0, x0, fib_loop  # Jump back to loop start

fib_done:
    # Final 10th Fibonacci value is in x6:
    # 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89 -> 89 = 0x59
    addi x10, x6, 0        # x10 holds final result
done_loop:
    beq  x0, x0, done_loop
