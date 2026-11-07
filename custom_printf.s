#AWM-ENG

.intel_syntax noprefix
.global custom_printf
.text

custom_printf:
    push rbp
    mov rbp, rsp
    sub rsp, 80           

    # Save callee-saved registers we will use
    push rbx
    push r12
    push r13
    push r14

    # Save argument registers to a local array on the stack (Index mapping)
    mov [rbp - 8],  rsi    # Arg 2
    mov [rbp - 16], rdx    # Arg 3
    mov [rbp - 24], rcx    # Arg 4
    mov [rbp - 32], r8     # Arg 5
    mov [rbp - 40], r9     # Arg 6

    mov rbx, rdi         
    mov rdx, 1
    xor r12, r12           

format_loop:
    movzx rax, byte ptr [rbx]
    test al, al
    je custom_printf_end
            
    cmp al, 0x5c           
    je handle_backslash
    cmp al, 0x25          
    je handle_percent

    
    mov byte ptr [rbp - 48], al
    mov rdi, 1             
    lea rsi, [rbp - 48]               
    mov rax, 1            
    syscall

    inc rbx
    jmp format_loop

# --- Helper to get the Next Argument from Register or Stack ---
get_next_arg:
    cmp r12, 5
    jl get_from_register
    
    mov rax, r12
    sub rax, 5
    imul rax, rax, 8
    add rax, 16
    add rax, rbp
    mov rax, [rax]
    inc r12
    ret

get_from_register:
    mov rax, r12
    imul rax, rax, 8
    neg rax
    lea rcx, [rbp]
    add rcx, rax
    sub rcx, 8
    mov rax, [rcx]
    inc r12
    ret

# --- Backslash Handling ---
handle_backslash:
    movzx rax, byte ptr [rbx + 1]
    cmp al, 0x6e           
    je handle_print_newline
    cmp al, 0x5c           
    je handle_print_backslash
    inc rbx
    jmp format_loop

handle_print_newline:
    mov byte ptr [rbp - 48], 0x0A
    mov rdi, 1
    lea rsi, [rbp - 48]
    mov rax, 1
    syscall
    add rbx, 2
    jmp format_loop

handle_print_backslash:
    mov byte ptr [rbp - 48], 0x5c
    mov rdi, 1
    lea rsi, [rbp - 48]
    mov rax, 1
    syscall
    add rbx, 2
    jmp format_loop

# --- Percent Specifier Handling ---
handle_percent:
    movzx rax, byte ptr [rbx + 1]
    cmp al, 0x25           
    je handle_print_percent
    cmp al, 0x64          
    je handle_print_integer
    cmp al, 0x73           
    je handle_print_string
    inc rbx
    jmp format_loop

handle_print_percent:
    mov byte ptr [rbp - 48], 0x25
    mov rdi, 1
    lea rsi, [rbp - 48]
    mov rax, 1
    syscall
    add rbx, 2
    jmp format_loop

handle_print_integer:
    call get_next_arg      
    
    mov rdi, rax           
    sub rsp, 32           
    lea rsi, [rsp]        
    call itoa             

    mov rdx, rax           
    lea rsi, [rsp]        
    mov rdi, 1             
    mov rax, 1             
    syscall

    mov rdx, 1
    add rsp, 32
    add rbx, 2
    jmp format_loop


handle_print_string:
    call get_next_arg      
    mov r13, rax           
    
    # Calculate string length
    xor rdx, rdx
string_len_loop:
    movzx rax, byte ptr [r13 + rdx]
    test al, al
    je print_string_exec
    inc rdx
    jmp string_len_loop

print_string_exec:
    test rdx, rdx
    jz string_done
    mov rdi, 1
    mov rsi, r13
    mov rax, 1
    syscall
    mov rdx, 1

string_done:
    add rbx, 2
    jmp format_loop

# --- Exit  ---
custom_printf_end:
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret


# =====================================================================================
# Shared Utility Functions (itoa implementation)
# =====================================================================================

.global itoa
itoa:
    xor rcx, rcx
    xor r10, r10
    test rdi, rdi
    jz itoa_zero
    cmp rdi, 0
    jl itoa_neg

itoa_back:
    mov r9, 10
    mov rax, rdi

itoa_loop:
    xor rdx, rdx
    cmp rax, 0
    je itoa_loop2
    div r9
    push rdx
    inc rcx
    jmp itoa_loop

itoa_loop2:
    cmp r11, rcx
    je itoa_end
    pop rdx
    add rdx, 0x30
    mov byte ptr [rsi + r11], dl
    inc r11
    jmp itoa_loop2

itoa_end:
    add rcx, r10
    mov rax, rcx
    ret

itoa_zero:
    mov rax, 1
    mov byte ptr [rsi], 0x30
    ret

itoa_neg:
    mov byte ptr [rsi], 0x2d
    neg rdi
    mov r10, 1
    add rsi, 1
    jmp itoa_back
