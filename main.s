#Githup : AWM-ENG

intel_syntax noprefix
.text

.global _start
_start:
    mov r8, [rsp + 16]
    lea r12, [rsp + 24]
    test r8, r8
    je exit
    mov rdi, 1      
    mov rdx, 1    

loop:
    movzx rax, byte ptr [r8]
    test al, al
    je exit

    cmp al, 0x5c       
    je handle_backslash
    cmp al, 0x25
    je handle_percent
    mov rsi, r8
    mov rax, 1
    syscall
    inc r8
    jmp loop

exit:
    mov rax, 60
    xor rdi, rdi
    syscall

        #backslash sign printing
handle_backslash:
    movzx rax, byte ptr [r8 + 1]
    cmp al, 0x6e
    je handle_print_newline
    cmp al, 0x5c
    je handle_print_backslash
    cmp al,0x78
    je handle_print_hex
    inc r8
    jmp loop


    handle_print_newline:
        mov byte ptr [rsp - 8], 0x0A
        lea rsi, [rsp - 8]
        mov rax, 1
        syscall
        add r8, 2
        jmp loop

    handle_print_backslash:
        mov byte ptr [rsp - 8], 0x5c
        lea rsi, [rsp - 8]
        mov rax, 1
        syscall
        add r8, 2
        jmp loop

    handle_percent:
        movzx rax, byte ptr [r8 + 1]
        cmp al, 0x25
        je handle_print_percent
        cmp al, 0x64
        je handle_print_integer
        cmp al, 0x73
        je handle_print_string
        inc r8
        jmp loop

        #percent sign printing
handle_print_percent:
        mov byte ptr [rsp - 8], 0x25
        lea rsi, [rsp - 8]
        mov rax, 1
        syscall
        add r8, 2
        jmp loop

handle_print_integer:               
    mov rdi, [r12]       
    sub rsp, 32              
    call atoi              
   
    mov rdi, rax              
    lea rsi, [rsp]            
    call itoa                 

    mov rdx, rax              
    lea rsi, [rsp]            
    mov rdi, 1                
    mov rax, 1                
    syscall

    add rsp, 32                                
    add r8, 2       
    add r12, 8
    mov rdx, 1         
    jmp loop

    handle_print_string:
        mov rsi, [r12]
        sub rsp, 32
        xor rdx, rdx

    repeat:
        movzx rax, byte ptr [rsi + rdx]
        test al, al
        je print_string
        inc rdx
        jmp repeat

    print_string:
        mov rdi, 1
        mov rax, 1
        syscall
        add rsp, 32
        add r8, 2
        add r12, 8
        mov rdx, 1
        jmp loop


handle_print_hex:

        xor rcx, rcx
        sub rsp, 32
        mov rsi, rsp
    hex_loop:
        cmp rcx, 2
        je handle_print_hex_end
        cmp byte ptr [r8 + rcx + 2], 0x61
        jge handle_print_hex_lower
        cmp byte ptr [r8 + rcx + 2], 0x41
        jge handle_print_hex_upper
        cmp byte ptr [r8 + rcx + 2], 0x30
        jge handle_print_hex_integer
        jmp handle_print_hex_fail


    handle_print_hex_lower: 
        mov al, byte ptr [r8 + rcx + 2]
        sub al, 0x61
        add al, 0x0A
        jmp store_nibble


    handle_print_hex_upper:
        mov al, byte ptr [r8 + rcx + 2]
        sub al, 0x41
        add al, 0x0A
        jmp store_nibble

    handle_print_hex_integer:
        mov al, byte ptr [r8 + rcx + 2]
        sub al, 0x30
        jmp store_nibble

    store_nibble:
        mov byte ptr [rsi + rcx], al
        inc rcx
        jmp hex_loop

    handle_print_hex_end:
        mov al, byte ptr [rsi]
        shl al, 4
        or al, byte ptr [rsi + 1]
        mov byte ptr [rsi], al
        mov rdi, 1
        mov rax, 1
        syscall
        add rsp, 32
        add r8, 4
        jmp loop

        handle_print_hex_fail:
        add rsp, 32
        add r8, 4
        jmp loop










#-------------------------------------------------------------------------------------#
        #shared functions

        #convert a single digit character to its integer value
atoi_digit:
    movzx rax, byte ptr [rdi]
    sub rax, 0x30
    ret

        #convert a string to an integer
.global atoi
atoi:
    xor r11, r11
    xor rcx, rcx
    cmp byte ptr [rdi], 0x2d
    je atoi_neg
    mov rsi, rdi

atoi_loop:
    mov rdi, rsi 
    call atoi_digit
    cmp rax, 9
    ja atoi_end
    imul r11, 10
    add r11, rax
    inc rsi
    jmp atoi_loop

        #handle negative numbers
atoi_neg:
    mov rcx, 1
    inc rdi 
    mov rsi, rdi
    jmp atoi_loop

atoi_end:
    mov rax, r11
    cmp rcx, 1
    jne atoi_end1
    neg rax
    ret
          
atoi_end1:
    ret


        #convert a single digit integer to its character representation
.global itoa_digit 
itoa_digit:
    mov rax, rdi
    add rax, 0x30
    ret
        
        #convert an integer to a string
.global itoa 
itoa:
    xor rcx, rcx
    xor r10, r10
    test rdi, rdi
    jz itoa_end1
    cmp rdi, 0
    jl itoa_neg

itoa_back:
    xor r11, r11
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

itoa_end1:
    mov rax, 1
    mov byte ptr [rsi], 0x30
    ret

itoa_neg:
    mov byte ptr [rsi], 0x2d
    neg rdi
    mov r10, 1
    add rsi, 1
    jmp itoa_back
