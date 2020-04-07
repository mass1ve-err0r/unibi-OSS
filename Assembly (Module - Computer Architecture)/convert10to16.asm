;;
; Name:		Convert DEC to HEX (convert10to16) in x86_64
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
    charError db "INPUT STRING CONTAINED A NON-NUMBER CHAR", NEWLINE
    charErrorlen equ $-charError
    uintmaxError db "INPUT NUMBER IS BEYOND UINT_MAX! (4294967295)", NEWLINE
    uintmaxErrorlen equ $-uintmaxError
    ; infos
    infoDEC db "Input  Number DEC: "
    infoDEClen equ $-infoDEC
    infoHEX db "Output Number HEX: "
    infoHEXlen equ $-infoHEX
    ; consts
    NewLine db 0x0A                 ; I still need to figure out why this works & %def doesnt

section .bss
    bufferHEX resb 10
    bufferDEC resb 10              ; max buf of 255 for input (if crazy enough)

section .text
    global _start

_start:
    ;; prepare the buffer
    mov r8, 0                   ; buffer-iter
    mov r13, 0                  ; bufferDEC iter
    mov r12, 0                  ; failsafe iter
    call _bufferprep

    ;; prep args
    pop r9                      ; save argc in r9
    add rsp, 8                  ; skip path in stack
    pop r10                     ; save argv1
    mov r11, r10                ; temp copyc -DEBUG FURTHER
    cmp r9, 2                   ; check if we have exactly 1 argv
    jne _exit                   ; exit if true

    ;; convert & print & actually convert then
    call convertToInteger       ; convert to int -> stores result in r10 as updated value
    call _printNUMBER

    ;; check if we break uint_max
    mov rcx, 0xFFFFFFFF         ; store UINT_MAX
    cmp r10, rcx                ; compare input to it
    ja _endNOW2                 ; exit if above


    ;; null out required registers before conversion
    xor rax, rax
    xor rdx, rdx
    xor rcx, rcx

    jmp convertToHEXLoop


_bufferprep:    ; add "0x" to the front & set 0-counter to 0
    mov byte[bufferHEX+r8], 0x30     ; add 0 to front
    inc r8
    mov byte[bufferHEX+r8], 0x78     ; add x to front
    inc r8                           ; ptr to next pos
    mov r15, 0                       ; the pre-0 iter
    ret

;; this function is recycled from my own code (used in arabic2roman)
convertToInteger:
    xor rax, rax    ; Zero-out the register
    mov rcx,  10    ; fixed-multiplier 10
convertToIntegerLoop:
	cmp [r10], byte 0   ; check if we have found a NULL-termination character
    je retINT           ; break-out case
	mov bl, [r10]       ; copy the byte out into the bl register
    
    ;; Additional-logic: to check if its a number:
    cmp bl, 0x30        ; compare if char is below the char of 0
    jb _endNOW
    cmp bl, 0x39        ; check if char is above the char for 9
    ja _endNOW
    
    sub bl, 48          ; -48 because of the ascii range of the digits 0-9
	mul rcx             ; multiply rcx on rax
	add rax, rbx        ; store it in rbx, positional additon
	inc r10             ; increment by one to get next byte
	jmp convertToIntegerLoop        ; loop
retINT:
    xor r10, r10          ; null out the register since argv1 no longer needed
    mov r10, rax          ; store the result/ update in r10
	ret

convertToHEXLoop:       ; recall: integer is in r10
    cmp r10, 0          ; check if its not already 0
    je createHEXString  ; return, r10 should be 0 & the number on the stack
    mov rdx, 0          ; no rest
    mov rax, r10        ; dividend is the value
    mov rcx, 16         ; 16 because Horner-principle to calc the true value
    div rcx             ; rax(quotient): leftover --- rdx(remainder): hex numeral
    push rdx            ; store the digit! (from back to front)
    mov r10, rax        ; overwrite r10 with the new number
    inc r15             ; increase our null counter
    jmp convertToHEXLoop

createHEXString:
    xor r10, 10     ; set our iter
    mov r14, 8      ; 8 here because we have 8 effective spaces
    sub r14, r15    ; 8-r15 = amounts of zeros needed
    mov r15, r14    ; move back into r15
    xor r14, r14    ; null it
    jmp addZerosLoop

addZerosLoop:                       ; thanks to our 0-counter r15 we can now add 0s
    cmp r15, 0                      ; check if its 0
    je createHEXStringLoop          ; now we can add the nums
    
    mov byte[bufferHEX+r8], 0x30    ; 0x30 = '0'
    dec r15                         ; decrement iter by 1
    inc r8                          ; inc buffer pos
    jmp addZerosLoop

createHEXStringLoop:
    ; add bound check
    cmp r8, 10
    jae _printHEX                 ; jump away if iter is maxxed

    pop r10                     ; pop from last to first char into r10 !-> its an integer
    cmp r10, 0                  ; 0
    je _chsl_zero
    cmp r10, 1                  ; 1
    je _chsl_one
    cmp r10, 2                  ; 2
    je _chsl_two
    cmp r10, 3                  ; 3
    je _chsl_three
    cmp r10, 4                  ; 4
    je _chsl_four
    cmp r10, 5                  ; 5
    je _chsl_five
    cmp r10, 6                  ; 6
    je _chsl_six
    cmp r10, 7                  ; 7
    je _chsl_seven
    cmp r10, 8                  ; 8
    je _chsl_eight
    cmp r10, 9                  ; 9
    je _chsl_nine
    cmp r10, 10                 ; A
    je _chsl_ten
    cmp r10, 11                 ; B
    je _chsl_eleven
    cmp r10, 12                 ; C
    je _chsl_twelve
    cmp r10, 13                 ; D
    je _chsl_thirteen
    cmp r10, 14                 ; E
    je _chsl_forteen
    cmp r10, 15                 ; F
    je _chsl_fifteen

    cmp r8, 10                  ; max 10 due to buf
    jae createHEXStringLoop

    jmp _printHEX                 ; print out the dex number

_chsl_zero:
    mov byte[bufferHEX+r8], 0x30    ; char '0'
    inc r8
    jmp createHEXStringLoop
_chsl_one:
    mov byte[bufferHEX+r8], 0x31    ; char '1'
    inc r8
    jmp createHEXStringLoop
_chsl_two:
    mov byte[bufferHEX+r8], 0x32    ; char '2'
    inc r8
    jmp createHEXStringLoop
_chsl_three:
    mov byte[bufferHEX+r8], 0x33    ; char '3'
    inc r8
    jmp createHEXStringLoop
_chsl_four:
    mov byte[bufferHEX+r8], 0x34    ; char '4'
    inc r8
    jmp createHEXStringLoop
_chsl_five:
    mov byte[bufferHEX+r8], 0x35    ; char '5'
    inc r8
    jmp createHEXStringLoop
_chsl_six:
    mov byte[bufferHEX+r8], 0x36    ; char '6'
    inc r8
    jmp createHEXStringLoop
_chsl_seven:
    mov byte[bufferHEX+r8], 0x37    ; char '7'
    inc r8
    jmp createHEXStringLoop
_chsl_eight:
    mov byte[bufferHEX+r8], 0x38    ; char '8'
    inc r8
    jmp createHEXStringLoop
_chsl_nine:
    mov byte[bufferHEX+r8], 0x39    ; char '9'
    inc r8
    jmp createHEXStringLoop
_chsl_ten:
    mov byte[bufferHEX+r8], 0x41    ; char 'A'
    inc r8
    jmp createHEXStringLoop
_chsl_eleven:
    mov byte[bufferHEX+r8], 0x42    ; char 'B'
    inc r8
    jmp createHEXStringLoop
_chsl_twelve:
    mov byte[bufferHEX+r8], 0x43    ; char 'C'
    inc r8
    jmp createHEXStringLoop
_chsl_thirteen:
    mov byte[bufferHEX+r8], 0x44    ; char 'D'
    inc r8
    jmp createHEXStringLoop
_chsl_forteen:
    mov byte[bufferHEX+r8], 0x45    ; char 'E'
    inc r8
    jmp createHEXStringLoop
_chsl_fifteen:
    mov byte[bufferHEX+r8], 0x46    ; char 'F'
    inc r8
    jmp createHEXStringLoop

;; print the hex number out
_printHEX:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, infoHEX
    mov rdx, infoHEXlen
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

    call _exit

;; STR -> STR
_identifyNumberSTR:       ; our number is in r11, finished numebr in bufferDEC
    cmp [r11], byte 0   ; check if we have found a NULL-termination character
    je _ret             ; break-out case
	mov bl, [r11]       ; copy the byte out into the bl register
    
    ;; Additional-logic: to check if its a number:
    cmp bl, 0x30        ; compare if char is below the char of 0
    jb _endNOW
    cmp bl, 0x39        ; check if char is above the char for 9
    ja _endNOW
    
    mov byte[bufferDEC+r13], bl ; move the char into buffer
    inc r13                     ; incr pos ptr
	inc r11                     ; increment by one to get next byte
	jmp _identifyNumberSTR      ; loop

;; decimal info
_printNUMBER:
    call _identifyNumberSTR
    xor bl, bl

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, infoDEC
    mov rdx, infoDEClen
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

    ret

;; scanned char was NOT a number!
_endNOW:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, charError
    mov rdx, charErrorlen
    syscall

    jmp _exit

;; we habe too big numba
_endNOW2:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, uintmaxError
    mov rdx, uintmaxErrorlen
    syscall

    jmp _exit

;; general return
_ret:
    ret

;; just exit
_exit:
    mov rax, 60
    mov rdi, 0
    syscall