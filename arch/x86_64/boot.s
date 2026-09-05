bits 32

; Multiboot 1 Header
MB_MAGIC    equ 0x1BADB002
MB_FLAGS    equ 0x00000003 ; align modules + provide memory map
MB_CHECKSUM equ -(MB_MAGIC + MB_FLAGS)

section .multiboot
align 4
    dd MB_MAGIC
    dd MB_FLAGS
    dd MB_CHECKSUM

section .bss
align 4096
pml4_table:
    resb 4096
pdpt_table:
    resb 4096
pd_table:
    resb 4096
stack_bottom:
    resb 16384 ; 16 KB stack
stack_top:

section .text
global _start
_start:
    mov esp, stack_top

    ; 1. Set up page tables (Identity map first 2MB using a 2MB huge page)
    mov eax, pdpt_table
    or eax, 0b11 ; present + writable
    mov [pml4_table], eax

    mov eax, pd_table
    or eax, 0b11 ; present + writable
    mov [pdpt_table], eax

    ; Map PD entry 0 to 0x0 with 2MB huge page bit set (bit 7)
    mov dword [pd_table], 0x00000083 ; present + writable + 2MB page (PS)

    ; 2. Pass PML4 address to CR3
    mov eax, pml4_table
    mov cr3, eax

    ; 3. Enable PAE in CR4
    mov eax, cr4
    or eax, 1 << 5 ; PAE bit
    mov cr4, eax

    ; 4. Set Long Mode bit in EFER MSR (0xC0000080)
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8 ; LME bit
    wrmsr

    ; 5. Enable Paging in CR0
    mov eax, cr0
    or eax, 1 << 31 | 1 << 0 ; PG and PE bits
    mov cr0, eax

    ; 6. Load 64-bit GDT and jump
    lgdt [gdt64.pointer]
    jmp gdt64.code_segment:long_mode_start

bits 64
long_mode_start:
    ; Reset segment registers
    mov ax, gdt64.data_segment
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Call 64-bit C kernel
    extern _Cmain.Main
    call _Cmain.Main

    cli
.halt:
    hlt
    jmp .halt

section .rodata
gdt64:
    dq 0 ; Null descriptor
.code_segment: equ $ - gdt64
    dq 0x00AF9A0000000000 ; 64-bit Code segment (Present, Executable, Ring 0, Long mode flag)
.data_segment: equ $ - gdt64
    dq 0x00CF920000000000 ; 64-bit Data segment (Present, Writable, Ring 0)
.pointer:
    dw $ - gdt64 - 1
    dq gdt64
