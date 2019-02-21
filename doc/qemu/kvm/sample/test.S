# A test code for kvmsample

.globl _start
    .code32
_start:
    xorl %eax, %eax
    
loop1:
    out %eax, $0x10
    inc %eax
    jmp loop1
