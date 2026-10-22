#=============================================================================
# Pipeline Hazard & Forwarding Verification Suite
# Tests:
# 1. EX-to-EX Forwarding (distance 1 RAW hazard)
# 2. MEM-to-EX Forwarding (distance 2 RAW hazard)
# 3. Load-Use Hazard Detection & Hardware Stall (1 bubble insertion)
# 4. Store Data Forwarding (WB-to-MEM)
#=============================================================================
    # 1. Back-to-back RAW Forwarding
    addi x1, x0, 10        # x1 = 10
    addi x2, x1, 5         # x2 = 10 + 5 = 15 (EX-to-EX forwarding from x1)
    add  x3, x2, x1        # x3 = 15 + 10 = 25 (EX-to-EX from x2, MEM-to-EX from x1)

    # 2. Memory Store and Load
    sw   x3, 0(x0)         # Mem[0] = 25
    lw   x4, 0(x0)         # x4 = Mem[0] = 25

    # 3. CRITICAL: Load-Use Hazard Stalling
    # The very next instruction uses x4. The hazard unit MUST stall IF & ID and flush EX for 1 cycle.
    addi x5, x4, 10        # x5 = 25 + 10 = 35

    # 4. Another Load-Use with R-type
    sw   x5, 4(x0)         # Mem[4] = 35
    lw   x6, 4(x0)         # x6 = 35
    add  x7, x6, x1        # x7 = 35 + 10 = 45 (Immediate load-use with R-type)

    # 5. Store forwarding test
    addi x8, x0, 100       # x8 = 100
    sw   x8, 8(x0)         # store x8 immediately (WB/MEM forwarding)
    lw   x9, 8(x0)         # x9 = 100

end:
    beq  x0, x0, end
