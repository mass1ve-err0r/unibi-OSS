;;
; Name:		convert16to10 (x86_64) in x86_64
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
    charError db "Error: Input string contained a non-number char!", NEWLINE
    charErrorlen equ $-charError
    argcError db "Error: Missing or Wrong amounts of args!", NEWLINE
    argcErrorlen equ $-argcError
    strlenError db "Error: strlen is above 8!", NEWLINE
    strlenErrorlen equ $-strlenError
    ; msgs
    messageDEC db "Output Number DEC: "
    messageDEClen equ $-messageDEC
    messageHEX db "Input  Number HEX: "
    messageHEXlen equ $-messageHEX
    ; consts
    NewLine db 0x0A

section .bss
    bufferDEC resb 10
    bufferHEX resb 10

section .text
    global _start

_start:
    mov r8, 0       ; buffer-iter HEX
    mov r9, 9       ; buffer-iter DEC reverse! (Due to stack saving in reverse order, so we place in buffer in reverse order)
    mov r10, 0      ; positional counter (kinda strlen)
    mov r13, 0      ; iterator for the power
    mov rcx, 0      ; sum storage
    ;; prep args
    pop r11                     ; save argc in r11
    add rsp, 8                  ; skip path in stack
    pop r12                     ; save argv1
    cmp r11, 2                  ; check if we have exactly 1 argv
    jne _exitARGC               ; exit if true
    ;; prep the hex buffer
    call _prepHEX
    ;; parse the number onto stack
    jmp parseSTR
_start2:

_prepHEX:
    mov byte[bufferHEX+r8], 0x30    ; add the '0' char
    inc r8                          ; pos_ptr +1
    mov byte[bufferHEX+r8], 0x78    ; add the 'x' char
    inc r8                          ; at this point we have the string "0x" & ready to work the rest
    ret                             ; this jumps back into start as we havent ret yet

parseSTR:           ; r12 holds the str/ char[]
    xor rax, rax    ; Zero-out the register
parseSTRLoop:
	cmp [r12], byte 0           ; check if we have found a NULL-termination character
    je _parseHEX                ; at this point everything is on the stack!
    cmp r10, 8                  ; compare if strlen is above 8 (because we can just enter 8 shits)
    jnc _exitSTRLEN             ; exit because strlen > 8
	mov bl, [r12]               ; copy the byte out into the bl register
    ;; Additional-logic: check if its a number (stripped from my convert10to16)
    cmp bl, 0x30                ; compare if char is below the char of 0 (extra chars)
    jb _exitCHAR                ; we habe found no number or char
    cmp bl, 0x39                ; check if char is above the char for 9 (potential chars abcdefABCDEF)
    ja _checkHEXChar            ; check if we have a hex char, else throw unknown char error
    mov byte[bufferHEX+r8], bl  ; write char to buffer
    inc r8                      ; increment pos pointer
    sub bl, 48                  ; asciiDigit-48 = number (0 = 0x30 or 48(base10) -> 48-48 = 0)
    push rbx                    ; push digit onot stack but recall its in bl, so lower reg of RBX!
	inc r12                     ; increment by one to get next byte
    inc r10                     ; increment our positional counter (needed for horner-schema later)
	jmp parseSTRLoop            ; loop

_checkHEXChar:      ; reminder: our char is STILL in bl and we need BOTH lower AND upper case
    cmp bl, 0x41    ; l33t haxx0r check for 0x41 (it's the char 'A' lol)
    je _chc_AddA
    cmp bl, 0x61    ; lower case A / char 'a'
    je _chc_AddA
    cmp bl, 0x42    ; char 'B'
    je _chc_AddB
    cmp bl, 0x62    ; char 'b'
    je _chc_AddB
    cmp bl, 0x43    ; char 'C'
    je _chc_AddC
    cmp bl, 0x63    ; char 'c'
    je _chc_AddC
    cmp bl, 0x44    ; char 'D'
    je _chc_AddD
    cmp bl, 0x64    ; char 'd'
    je _chc_AddD
    cmp bl, 0x45    ; char 'E'
    je _chc_AddE
    cmp bl, 0x65    ; char 'e'
    je _chc_AddE
    cmp bl, 0x46    ; char 'F'
    je _chc_AddF
    cmp bl, 0x66    ; char 'f'
    je _chc_AddF
    ;; if we have NO match, jump to char error
    jmp _exitCHAR

_chc_AddA:  ; A=10
    mov byte[bufferHEX+r8], 0x41    ; build the output string alongside (only caps!)
    inc r8                          ; pos_ptr +1
    push 10                         ; push 10 onto stack
    inc r12                         ; next char
    inc r10                         ; pos counter
    jmp parseSTRLoop                ; jump back to loop

_chc_AddB:  ; B=11
    mov byte[bufferHEX+r8], 0x42
    inc r8
    push 11
    inc r12
    inc r10
    jmp parseSTRLoop
_chc_AddC:  ; C=12
    mov byte[bufferHEX+r8], 0x43
    inc r8
    push 12
    inc r12
    inc r10
    jmp parseSTRLoop
_chc_AddD:  ; D=13
    mov byte[bufferHEX+r8], 0x44
    inc r8
    push 13
    inc r12
    inc r10
    jmp parseSTRLoop
_chc_AddE:  ; E=14
    mov byte[bufferHEX+r8], 0x45
    inc r8
    push 14
    inc r12
    inc r10
    jmp parseSTRLoop
_chc_AddF:  ; F=15
    mov byte[bufferHEX+r8], 0x46
    inc r8
    push 15
    inc r12
    inc r10
    jmp parseSTRLoop

_parseHEX:                      ; structure the DEC String now
    cmp r10, 0
    je _int2str
    pop r15                     ; pop into r15 the topmost shit (back to front reading!)
    call _pow16                 ; build our power of 16 in accordance to the pos => result in rcx!
    mov rax, r15                ; shift r15 into rax
    mul rcx                     ; rax = rax * rcx
    add r14, rax                ; build the sum in r14
    inc r13                     ; next power
    dec r10                     ; lower our position counter so we dont loop inifitely
    jmp _parseHEX

_pow16:
    mov rbx, r13    ; copy the power
    mov rax, 1      ; this is the base case
    cmp rbx, 0      ; null check to return 1!
    je _pow16NUMBaseCase
_pow16Loop:
    cmp rbx, 0      ; check if its zero
    je _pow16NUM    ; if yes, exit
    imul rax, 16    ; eax = eax * 16
    dec rbx         ; decrement iter
    jmp _pow16Loop
_pow16NUM:
    mov rcx, rax    ; move the result from rax to rcx
    ret             ; jump back into the loop
_pow16NUMBaseCase:
    mov rcx, 1      ; this is the base case for 16^0 = 1
    ret

;; this method has been inspired by here: https://0xax.github.io/asm_3/
;; However I adapted it to my needs
_int2str:               ; at this point we can use the stack again for our purpose!
    mov rax, r14        ; shift sum back to rax
_int2strLoop:
    xor rdx, rdx                ; zero out rdx for safety
    mov rbx, 10                 ; divide by 10
    div rbx                     ; rax: result, rdx= remainder
    add rdx, 48                 ; remainder +48 gives us the ascii char!
    add rdx, 0x0                ; add the null-terminator to char
    mov byte[bufferDEC+r9], dl  ; add the decimal to the buffer => logically we can adress the loer byte of the register in use!
    dec r9                      ; decrement by 1 to obtain next pos becaus we feed in reverse order
    cmp rax, 0x0                ; compare if its 0
    jne _int2strLoop

    jmp _printHexadecimalInfo   ; else we are officially done!

_printDecimalInfo:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, messageDEC
    mov rdx, messageDEClen
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferDEC
    mov rdx, 10
    syscall 

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, NewLine
    mov rdx, 1
    syscall 

    jmp _exit

_printHexadecimalInfo:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, messageHEX
    mov rdx, messageHEXlen
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferHEX
    mov rdx, 10
    syscall 

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, NewLine
    mov rdx, 1
    syscall 

    jmp _printDecimalInfo

;; jumpback
_ret:
    ret

_exitSTRLEN:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, strlenError
    mov rdx, strlenErrorlen
    syscall

    jmp _exit

_exitCHAR:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, charError
    mov rdx, charErrorlen
    syscall

    jmp _exit

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