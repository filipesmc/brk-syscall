.globl alloca, dealloca

.section .data

MEMORY_START: .8byte 0
MEMORY_END: .8byte 0

.section .text

.equ BRK_SYSCALL, 12
.equ HEADER_SIZE, 16
.equ OFFSET_HEADER_IN_USE, 0
.equ OFFSET_HEADER_SIZE, 8

init:

    movq $0, %rdi
    movq $BRK_SYSCALL, %rax
    syscall
    
    # %rax contém o retorno da chamada à brk
    movq %rax, MEMORY_START
    movq %rax, MEMORY_END
    jmp allocate

move_break_pointer:

    # %rcx contém o ponteiro anterior do break, salva ele em %r8
    movq %rcx, %r8
    
    # calcula e diz pra onde o break deve apontar
    # ou seja (antigo valor + tamanho)
    movq %rcx, %rdi
    addq %rdx, %rdi
    movq %rdi, MEMORY_END

    # seta o novo break
    movq $BRK_SYSCALL, %rax
    syscall
    
    movq $1, OFFSET_HEADER_IN_USE(%r8)
    movq %rdx, OFFSET_HEADER_SIZE(%r8) 

    # valor de retorno esta alem do nosso header
    addq $HEADER_SIZE, %r8
    movq %r8, %rax
    ret

alloc:

    # salva o tamanho que foi requisitado
    movq %rdi, %rdx
    addq $HEADER_SIZE, %rdx

    # verifica se ja inicializamos
    cmpq $0, MEMORY_START
    je init

allocate:

    movq MEMORY_START, %rsi
    movq MEMORY_END, %rcx

alloc_loop:

    # Se não tiver mais memória, aloca mais movendo o break pointer
    cmpq %rsi, %rcx
    je move_break_pointer

    # checa se o próximo bloco está disponível
    cmpq $0, OFFSET_HEADER_IN_USE(%rsi)
    jne next_block

    # checa se o próximo bloco tem o chunk livre suficiente
    cmpq %rdx, OFFSET_HEADER_SIZE(%rsi)
    jb next_block

    # caso o chunk for livre e tem espaço suficiente...
    movq $1, OFFSET_HEADER_IN_USE(%rsi)
    
    # move além do header
    addq $HEADER_SIZE, %rsi
    
    # retorna
    movq %rsi, %rax
    ret

next_block:

    addq OFFSET_HEADER_SIZE(%rsi), %rsi
    jmp alloc_loop

dealloc:

    movq $0, OFFSET_HEADER_IN_USE - HEADER_SIZE(%rdi)
    ret





