;;
; Name:		Bubblesort (x86_64)
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
    bufferSORT resb 100     ; buffer for sorted chars

section .text
    global _start

_start:
    pop r15             ; get argc
    add rsp, 8          ; skip exec-path
    cmp r15, 1          ; check if we have args
    je _exitARGC

_argvLoop:
    mov r9, 1
    xor r8, r8          ; null out before we begin
    xor r10, r10        ; strlen for buffer
    cmp r15, 1          ; check if we worked out all args
    je _exit

    pop r14             ; get an argv
    call _str2buf       ; place str in buffer
    xor r8, r8          ; buffer iter 1 / nulled out every round
    call bubblesortLoop ; sort it
    dec r15
    call _print
    call _emptybuf
    jmp _argvLoop

_bubblesort:
    cmp r11, 0      ; check if we have had to swap
    je _ret         ; the actual return

    xor r11, r11    ; null out if we had any
    xor r8, r8
    mov r9, 1
bubblesortLoop:
    cmp [bufferSORT+r8], byte 0    ; check i for null terminator
    je _bubblesort     ; check back
    cmp [bufferSORT+r9], byte 0 ; check i+1 for terminator
    je _bubblesort     ; check back

    mov al, [bufferSORT+r8]
    mov bl, [bufferSORT+r9]
    cmp al, bl          ; if i smaller
    jb bubblesortLow    ; no swap
    cmp al, bl          ; if i+1 smaller
    ja bubblesortHigh  ; swap
    cmp al, bl          ; check for equal
    je bubblesortEqual  ; jump

bubblesortLow:
    inc r8                          ; increment pos_ptr
    inc r9
    inc r14                         ; get next byte / i+1 = new i
    jmp bubblesortLoop              ; jumpback to loop

bubblesortHigh:
    mov byte[bufferSORT+r8], bl     ; add char to list
    mov byte[bufferSORT+r9], al
    inc r8                          ; increment pos_ptr
    inc r9
    inc r14                         ; get next byte / i+1 = new i
    inc r11                         ; increment the counter
    jmp bubblesortLoop              ; jumpback to loop

bubblesortEqual:
    inc r8
    inc r9
    jmp bubblesortLoop

_print:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferSORT
    mov rdx, r10
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, NewLine
    mov rdx, 1
    syscall

    ret

_str2buf:
    cmp [r14], byte 0
    je _ret

    inc r10
    mov bl, [r14]
    mov byte[bufferSORT+r8], bl
    inc r8
    inc r14
    jmp _str2buf

;; Many thanks to the wizards at SO for the guidance/ clue & this x86 guide
; https://x86.puri.sm/html/file_module_x86_id_306.html
; https://stackoverflow.com/a/29004650
_emptybuf:
    lea rdi, [bufferSORT]
    mov rcx, 100
    mov al, 0
    rep stosb
    ret

_ret:
    ret

_exitARGC:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, argcError
    mov rdx, argcErrorlen
    syscall

    jmp _exit

_exit:
    mov rax, 60
    mov rdi, 0
    syscall