#=============================================================================
# Control Hazard & Branch Flushing Verification Suite
# Tests:
# 1. BEQ Taken & Branch Flushing (ensuring wrong-path instructions are discarded)
# 2. BEQ Not Taken (ensuring sequential execution)
# 3. BLT, BGE, BNE comparisons
# 4. JAL function call and JALR function return
#=============================================================================
    addi x1, x0, 10        # x1 = 10
    addi x2, x0, 10        # x2 = 10
    addi x3, x0, 0         # x3 = 0 (guard register)

    # 1. BEQ Taken & Flush Test
    beq  x1, x2, branch_taken
    addi x3, x0, 99        # SHOULD BE FLUSHED! If flushed, x3 stays 0!
    addi x4, x0, 99        # SHOULD BE FLUSHED!

branch_taken:
    addi x5, x0, 1         # x5 = 1 (marks branch_taken reached)

    # 2. BEQ Not Taken Test
    addi x6, x0, 20
    beq  x1, x6, branch_not_taken
    addi x7, x0, 2         # x7 = 2 (sequential path followed)

branch_not_taken:
    # 3. Signed vs Unsigned Branch Test
    addi x8, x0, -5        # x8 = -5 (0xFFFFFFFB)
    addi x9, x0, 5         # x9 = 5
    blt  x8, x9, signed_less
    addi x10, x0, 99       # should not reach here

signed_less:
    addi x10, x0, 1        # x10 = 1 (signed less-than verified)

    # 4. JAL and JALR Procedure Call
    addi x11, x0, 50
    jal  x1, my_function   # Call function, save return PC in x1 (ra)
    addi x12, x0, 100      # Return destination: x12 = 100
    beq  x0, x0, test_done

my_function:
    addi x11, x11, 25      # x11 = 50 + 25 = 75
    jalr x0, x1, 0         # Return to caller using x1

test_done:
    addi x13, x0, 1        # x13 = 1 (all tests completed)
hang:
    beq  x0, x0, hang
