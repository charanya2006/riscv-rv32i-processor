#!/usr/bin/env python3
"""
Simple, Robust RV32I Assembler
Encodes standard RV32I assembly instructions into 32-bit machine code hex.
Supports labels, pseudo-instructions (NOP, LI, MV, J, JR, RET), and data sections.
"""

import sys
import re

REGISTERS = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
    't0': 5, 't1': 6, 't2': 7, 's0': 8, 'fp': 8, 's1': 9,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
    's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23, 's8': 24, 's9': 25,
    's10': 26, 's11': 27, 't3': 28, 't4': 29, 't5': 30, 't6': 31
}
for i in range(32):
    REGISTERS[f'x{i}'] = i

def parse_reg(s):
    s = s.strip().lower()
    if s in REGISTERS:
        return REGISTERS[s]
    raise ValueError(f"Unknown register: {s}")

def parse_imm(s, labels=None, current_pc=0):
    s = s.strip()
    if labels and s in labels:
        return labels[s] - current_pc
    return int(s, 0)

def encode_r(opcode, funct3, funct7, rd, rs1, rs2):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i(opcode, funct3, rd, rs1, imm):
    imm = imm & 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s(opcode, funct3, rs1, rs2, imm):
    imm = imm & 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0 = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def encode_b(opcode, funct3, rs1, rs2, imm):
    imm = imm & 0x1FFE
    b12 = (imm >> 12) & 1
    b11 = (imm >> 11) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

def encode_u(opcode, rd, imm):
    imm = (imm >> 12) & 0xFFFFF
    return (imm << 12) | (rd << 7) | opcode

def encode_j(opcode, rd, imm):
    imm = imm & 0x1FFFFE
    j20 = (imm >> 20) & 1
    j10_1 = (imm >> 1) & 0x3FF
    j11 = (imm >> 11) & 1
    j19_12 = (imm >> 12) & 0xFF
    return (j20 << 31) | (j19_12 << 12) | (j11 << 20) | (j10_1 << 21) | (rd << 7) | opcode

def parse_mem_operand(op_str):
    # e.g. "4(x5)" or "0(sp)"
    m = re.match(r'([-\w\d]+)\s*\(([\w\d]+)\)', op_str.strip())
    if not m:
        raise ValueError(f"Invalid memory operand: {op_str}")
    imm_str, reg_str = m.groups()
    return int(imm_str, 0), parse_reg(reg_str)

def assemble(source_lines):
    # Pass 1: find labels and instructions
    instructions = []
    labels = {}
    pc = 0

    for raw_line in source_lines:
        line = raw_line.split('#')[0].split('//')[0].strip()
        if not line:
            continue
        if ':' in line:
            parts = line.split(':', 1)
            lbl = parts[0].strip()
            labels[lbl] = pc
            line = parts[1].strip()
            if not line:
                continue

        # Check pseudo-instructions expanding to 1 or 2 instructions
        tokens = [t.strip() for t in re.split(r'[,\s]+', line) if t.strip()]
        inst = tokens[0].lower()
        args = tokens[1:]

        if inst == 'nop':
            instructions.append((pc, 'addi', ['zero', 'zero', '0']))
            pc += 4
        elif inst == 'mv':
            instructions.append((pc, 'addi', [args[0], args[1], '0']))
            pc += 4
        elif inst == 'not':
            instructions.append((pc, 'xori', [args[0], args[1], '-1']))
            pc += 4
        elif inst == 'neg':
            instructions.append((pc, 'sub', [args[0], 'zero', args[1]]))
            pc += 4
        elif inst == 'j':
            instructions.append((pc, 'jal', ['zero', args[0]]))
            pc += 4
        elif inst == 'jr':
            instructions.append((pc, 'jalr', ['zero', args[0], '0']))
            pc += 4
        elif inst == 'ret':
            instructions.append((pc, 'jalr', ['zero', 'ra', '0']))
            pc += 4
        elif inst == 'li':
            val = int(args[1], 0)
            if -2048 <= val < 2048:
                instructions.append((pc, 'addi', [args[0], 'zero', str(val)]))
                pc += 4
            else:
                upper = (val + 0x800) >> 12
                lower = val - (upper << 12)
                instructions.append((pc, 'lui', [args[0], str(upper << 12)]))
                pc += 4
                instructions.append((pc, 'addi', [args[0], args[0], str(lower)]))
                pc += 4
        else:
            instructions.append((pc, inst, args))
            pc += 4

    # Pass 2: encode instructions
    hex_words = []
    for pc, inst, args in instructions:
        word = 0
        if inst == 'add':
            word = encode_r(0x33, 0x0, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'sub':
            word = encode_r(0x33, 0x0, 0x20, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'sll':
            word = encode_r(0x33, 0x1, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'slt':
            word = encode_r(0x33, 0x2, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'sltu':
            word = encode_r(0x33, 0x3, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'xor':
            word = encode_r(0x33, 0x4, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'srl':
            word = encode_r(0x33, 0x5, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'sra':
            word = encode_r(0x33, 0x5, 0x20, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'or':
            word = encode_r(0x33, 0x6, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))
        elif inst == 'and':
            word = encode_r(0x33, 0x7, 0x00, parse_reg(args[0]), parse_reg(args[1]), parse_reg(args[2]))

        # I-type ALU
        elif inst == 'addi':
            imm = parse_imm(args[2], labels, pc)
            word = encode_i(0x13, 0x0, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'slli':
            imm = int(args[2], 0) & 0x1F
            word = encode_i(0x13, 0x1, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'slti':
            imm = parse_imm(args[2], labels, pc)
            word = encode_i(0x13, 0x2, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'sltiu':
            imm = parse_imm(args[2], labels, pc)
            word = encode_i(0x13, 0x3, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'xori':
            imm = parse_imm(args[2], labels, pc)
            word = encode_i(0x13, 0x4, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'srli':
            imm = int(args[2], 0) & 0x1F
            word = encode_i(0x13, 0x5, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'srai':
            imm = (int(args[2], 0) & 0x1F) | 0x400
            word = encode_i(0x13, 0x5, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'ori':
            imm = parse_imm(args[2], labels, pc)
            word = encode_i(0x13, 0x6, parse_reg(args[0]), parse_reg(args[1]), imm)
        elif inst == 'andi':
            imm = parse_imm(args[2], labels, pc)
            word = encode_i(0x13, 0x7, parse_reg(args[0]), parse_reg(args[1]), imm)

        # Loads
        elif inst in ('lb', 'lh', 'lw', 'lbu', 'lhu'):
            imm, rs1 = parse_mem_operand(args[1])
            f3_map = {'lb': 0, 'lh': 1, 'lw': 2, 'lbu': 4, 'lhu': 5}
            word = encode_i(0x03, f3_map[inst], parse_reg(args[0]), rs1, imm)

        # Stores
        elif inst in ('sb', 'sh', 'sw'):
            imm, rs1 = parse_mem_operand(args[1])
            f3_map = {'sb': 0, 'sh': 1, 'sw': 2}
            word = encode_s(0x23, f3_map[inst], rs1, parse_reg(args[0]), imm)

        # Branches
        elif inst in ('beq', 'bne', 'blt', 'bge', 'bltu', 'bgeu'):
            imm = parse_imm(args[2], labels, pc)
            f3_map = {'beq': 0, 'bne': 1, 'blt': 4, 'bge': 5, 'bltu': 6, 'bgeu': 7}
            word = encode_b(0x63, f3_map[inst], parse_reg(args[0]), parse_reg(args[1]), imm)

        # Jumps & Upper
        elif inst == 'jal':
            if len(args) == 1:
                rd = 1 # ra
                imm = parse_imm(args[0], labels, pc)
            else:
                rd = parse_reg(args[0])
                imm = parse_imm(args[1], labels, pc)
            word = encode_j(0x6F, rd, imm)
        elif inst == 'jalr':
            if len(args) == 2:
                rd = parse_reg(args[0])
                imm, rs1 = parse_mem_operand(args[1])
            elif len(args) == 3:
                rd = parse_reg(args[0])
                rs1 = parse_reg(args[1])
                imm = int(args[2], 0)
            else:
                imm, rs1 = parse_mem_operand(args[0])
                rd = 1
            word = encode_i(0x67, 0x0, rd, rs1, imm)
        elif inst == 'lui':
            imm = int(args[1], 0)
            word = encode_u(0x37, parse_reg(args[0]), imm)
        elif inst == 'auipc':
            imm = int(args[1], 0)
            word = encode_u(0x17, parse_reg(args[0]), imm)
        else:
            raise ValueError(f"Unsupported instruction: {inst}")

        hex_words.append(f"{word:08x}")

    return hex_words

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python3 assembler.py <input.s> <output.hex>")
        sys.exit(1)

    with open(sys.argv[1], 'r') as f:
        lines = f.readlines()

    words = assemble(lines)
    with open(sys.argv[2], 'w') as f:
        for w in words:
            f.write(w + '\n')
    print(f"Assembled {len(words)} instructions from {sys.argv[1]} -> {sys.argv[2]}")
