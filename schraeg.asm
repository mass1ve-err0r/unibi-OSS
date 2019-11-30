;;
; Name:		Print Diagonally (schraeg) in x86_64
; Author:	Saadat M. Baig, <me@saadat.dev>
;;

; system_consts (x86_64)
%define SYS_WRITE 1
%define SYS_READ 0
; fd consts
%define STDIN 0
%define STDOUT 1
; custom consts
%define NoError 0
%define NEWLINE 10

section .data
    ; errors
    argcError db "Error: Missing or Wrong amounts of args!", NEWLINE
    argcErrorlen equ $-argcError
    ; consts
    NewLine db 0x0A

section .bss
    bufferSTR resb 255  ; reserve 255 bytes for our buffer

section .text
    global _start

_start:
    mov r8, 0       ; buffer-iter for our diagonal strings
    mov r9, 0       ; kinda strlen
    mov r12, 0      ; whitespace iterator

    pop r10         ; copy argc into r10
    add rsp, 8      ; increment by 8 so rsp points to first arg
    cmp r10, 1      ; check if we even have args
    je _exitARGC
_argvLoop:
    xor r9, r9              ; null strlen each round
    xor r8, r8              ; also null the ptr to re-use the buffer!
    cmp r10, 1              ; check if we processed all args
    je _exit                ; if yes, exit

    dec r10                 ; decrement argc counter by 1
    pop r11                 ; copy arg into r11
    call _parseDiagonally   ; parse the char[] with spaces & shit
    call _printAgent        ; print out the buffer so far
    jmp _argvLoop           ; loop, null the necessary ptr & go again

_parseDiagonally:                   ; strip byte by byte & print it | arg is in r11!
    cmp [r11], byte 0               ; check if zero terminator exists
    je _ret
    
    call _addWhitespaces            ; whitespaces loop
    inc r9                          ; strlen += 1
    xor r12, r12                    ; zero-out the whitepsace counter so loop can begin over again
    mov al, [r11]                   ; move out a byte
    mov byte[bufferSTR+r8], al      ; write char to buffer with whitespaces prefixing it
    inc r8
    mov byte[bufferSTR+r8], 0x0A    ; write the newline char at the end!
    inc r8
    inc r11                         ; point to next byte
    jmp _parseDiagonally

_addWhitespaces:                    ; compare against strlen & add as many whitespaces as strlen/ strlen = position in string => needed whitespaces before char
    cmp r12, r9                     ; check if whitespace counter matches strlen, because it determines how many whitespaces per char
    je _ret

    mov byte[bufferSTR+r8], 0x20    ; whitespace char
    inc r8                          ; inrecement buffer pos_ptr
    inc r12                         ; increment because we added 1 whitespace
    jmp _addWhitespaces

_printAgent:            ; print our buffer
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferSTR  ; buffer
    mov rdx, r8         ; buffer_pos_ptr indicates size+1 so we can use it!
    syscall

    ret                 ; jumpback to wherever we got called

;; jumpback
_ret:
    ret

;; exit because argc is non-matching to our cond
_exitARGC:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, argcError
    mov rdx, argcErrorlen
    syscall

    jmp _exit

;; exit bruh
_exit:
    mov rax, 60
    mov rdi, 0
    syscall