;;
; Name:		FixedPoint in x86_64
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
    argcError db "[E]: Missing input or Wrong amounts of args!", NEWLINE
    argcErrorlen equ $-argcError
    charError db "[E]: Input string contained a non-number char!", NEWLINE
    charErrorlen equ $-charError
    pointError db "[E]: You have entered another point! ", NEWLINE
    pointErrorlen equ $-pointError
    fracError db "[E]: Fractional part missing after the point!", NEWLINE
    fracErrorlen equ $-fracError
    ; messages
    inputMSG db "Type a number: "
    inputMSGlen equ $-inputMSG
    outputMSG db "32Bit fixed-point number: "
    outputMSGlen equ $-outputMSG
    ; consts
    NewLine db 0x0A
    fpLF db 0x62, 0x0A
    uint16_t_invalid db "65535"
    twoXMM dd 2
    oneXMM dd 1

section .bss
    bufferU16 resb 16       ; upper 16bit of the 32bit fp (integral)
    bufferL16 resb 16       ; lower 16bit of the 32bit fp (fractional)
    bufferSTDIN resb 256    ; stdin buf

section .text
    global _start

_start:
    mov r8, 0               ; buffer-iter (upper)
    mov r9, 0               ; buffer-iter (lower)
    mov r11, 0              ; Integral Part (as int)
    mov r12, 0              ; Fractional Part (as int)
    mov r13, 0              ; strlen for the frac! 
    mov r14, 0              ; temporarily used for the buffer as cehck that we have 1 decimal point

    call _getDecMessage
    mov rax, 0                      ; sys_read
    mov rdi, 0                      ; stdin
    mov rsi, bufferSTDIN            ; buf
    mov rdx, 255                    ; length
    syscall                         ; after this, RAX-1 holds the strlen! (figured in GDB!)
    mov byte[bufferSTDIN+rax-1], 0  ; because FUCK OFF, sys_read does NOT create a C-Sytle String lmao

    call _convertToInteger          ; int= r11, frac=r12, freed regosters= r10, r14
    call _calcINT                   ; call conversion of INT part
    cmp r13, 0                      ; thanks to strlen we can check if we have a fraction
    je _print32BitFP_NOFRAC         ; print without fractional bit (zero'd)

    call _calcFRAC                  ; call conversion of FRAC part 
    jmp _print32BitFP              ; print fully qualified 32-FP

    ;jmp _exit

;; this function is recycled from my own code (used in arabic2roman) & adapted
_convertToInteger:
    xor rax, rax            ; Zero-out the register
    mov rcx,  10            ; fixed-multiplier 10
    mov r10, bufferSTDIN    ; move our buffer into r10
    call _testINPUT         ; preliminary test if we have anything AT ALL
convertToIntegerLoop:
    cmp [r10], byte 0       ; check if we have found a NULL-termination character
    je retINT               ; break-out case
	mov bl, [r10]           ; copy the byte out into the bl register
    
    cmp bl, 0x2E            ; check if its a point
    je _checkPOINT          ; add point 6 jump to other loop
    cmp bl, 0x30            ; check if char is below the char of 0
    jb _exitCHAR
    cmp bl, 0x39            ; check if char is above the char for 9
    ja _exitCHAR
    
    sub bl, 48              ; -48 because of the ascii range of the digits 0-9
	mul rcx                 ; multiply rcx on rax
	add rax, rbx            ; store it in rax, positional additon
    inc r10                 ; get next byte
	jmp convertToIntegerLoop
retINT:
    mov r11, rax            ; store the result (INT) in r11
    xor r14, r14            ; free reg!
	ret

_checkPOINT:
    cmp r14, 1                      ; check if we have a point already
    je _exitPOINT                   ; exit, too many points

    inc r14                         ; increment to 1 because we have a point!
    inc r10                         ; get next byte
    mov r11, rax                    ; store Integral part into r11
    jmp _convertToInteger_two        ; jump to other loop to construct frac

_convertToInteger_two:
    xor rax, rax            ; Zero-out the register
    mov rcx,  10            ; fixed-multiplier 10
    cmp [r10], byte 0       ; immediatly check if we have anything after the point, else error
    je _exitFRAC            ; error out
convertToIntegerLoop_two:    
    cmp [r10], byte 0               ; check if we have found a NULL-termination character
    je retINT_two                   ; break-out case
	mov bl, [r10]                   ; copy the byte out into the bl register
    
    cmp bl, 0x2E                    ; check if its a point
    je _checkPOINT                  ; add point 6 jump to other loop
    cmp bl, 0x30                    ; check if char is below the char of 0
    jb _exitCHAR
    cmp bl, 0x39                    ; check if char is above the char for 9
    ja _exitCHAR
    
    sub bl, 48                      ; -48 because of the ascii range of the digits 0-9
	mul rcx                         ; multiply rcx on rax
	add rax, rbx                    ; store it in rax, positional additon
    inc r10
    inc r13                         ; basically also capture strlen for the true frac
	jmp convertToIntegerLoop_two
retINT_two:
    mov r12, rax            ; store the result (FRAC) in r12
	xor r10, r10            ; null out the register r10 (free reg!)
    xor r14, r14            ; free reg!
    ret

_testINPUT:             ; recall: we just shifted shit into r10
    cmp [r10], byte 0   ; check if we have input AT ALL
    je _exit            ; we have nothing inputted

    mov dl, [r10]       ; copy byte out
    cmp dl, 0x30        ; check if char is below the char of 0
    jb _exit            ; we now want to exit the input loop
    cmp bl, 0x39        ; check if char is above the char for 9
    ja _exit

    xor rdx, rdx        ; null the reg
    ret

_calcINT:               ; remember: r11 holds our Integral part
    cmp r11, 65534      ; check if our number is above max
    ja _setMAX

    call _dec2binINT    ; pass r11 -> result in bufferU16 !
    ret                 ; return to main/ _start

_setMAX:
    cmp r8, 16
    je _ret

    mov byte[bufferU16+r8], 0x31
    inc r8
    jmp _setMAX

_dec2binINT:
    mov r8, 15          ; we decrement and add the 1s /0s
    xor rcx, rcx        ; null out the reg
dec2binINTLoop:
    cmp r11, 0              ; check if its not already 0
    je addZeros_dec2binINT

    mov rdx, 0          ; no rest
    mov rax, r11        ; dividend is the value
    mov rcx, 2          ; 2 because Horner-principle to calc the true value
    div rcx             ; rax(quotient): leftover --- rdx(remainder): bin numeral

    call _addDigitToBuffer

    mov r11, rax        ; overwrite r10 with the new number
    jmp dec2binINTLoop

addZeros_dec2binINT:
    cmp r8, -1                      ; check if the pos ptr is -1 (Thanks to GDB!) (Error was that inforeg showed r8 was -1 and then i relaized what todo!)
    je _ret                         ; jump if signed Flag is set
                                    ; another variant would be to check for signed flag (jump if signed- js)
    mov byte[bufferU16+r8], 0x30    ; add the 0 char
    dec r8                          ; decrement!
    jmp addZeros_dec2binINT

_retAddZeros:
    mov byte[bufferU16+r8], 0x30
    jmp _ret

_addDigitToBuffer:              ; it wil ALWAYS only be 1 of 9 cases, no general ret needed
    cmp rdx, 0                  ; 0
    je addDigitToBuffer_zero
    cmp rdx, 1                  ; 1
    je addDigitToBuffer_one
    cmp rdx, 2                  ; 2
    je addDigitToBuffer_two
    cmp rdx, 3                  ; 3
    je addDigitToBuffer_three
    cmp rdx, 4                  ; 4
    je addDigitToBuffer_four
    cmp rdx, 5                  ; 5
    je addDigitToBuffer_five
    cmp rdx, 6                  ; 6
    je addDigitToBuffer_six
    cmp rdx, 7                  ; 7
    je addDigitToBuffer_seven
    cmp rdx, 8                  ; 8
    je addDigitToBuffer_eight
    cmp rdx, 9                  ; 9
    je addDigitToBuffer_nine
addDigitToBuffer_zero:
    mov byte[bufferU16+r8], 0x30    ; char '0'
    dec r8
    ret
addDigitToBuffer_one:
    mov byte[bufferU16+r8], 0x31    ; char '1'
    dec r8
    ret
addDigitToBuffer_two:
    mov byte[bufferU16+r8], 0x32    ; char '2'
    dec r8
    ret
addDigitToBuffer_three:
    mov byte[bufferU16+r8], 0x33    ; char '3'
    dec r8
    ret
addDigitToBuffer_four:
    mov byte[bufferU16+r8], 0x34    ; char '4'
    dec r8
    ret
addDigitToBuffer_five:
    mov byte[bufferU16+r8], 0x35    ; char '5'
    dec r8
    ret
addDigitToBuffer_six:
    mov byte[bufferU16+r8], 0x36    ; char '6'
    dec r8
    ret
addDigitToBuffer_seven:
    mov byte[bufferU16+r8], 0x37    ; char '7'
    dec r8
    ret
addDigitToBuffer_eight:
    mov byte[bufferU16+r8], 0x38    ; char '8'
    dec r8
    ret
addDigitToBuffer_nine:
    mov byte[bufferU16+r8], 0x39    ; char '9'
    dec r8
    ret

;; The following has beena  result of countless hours of research & reeading into SSE
;; since I had 0 knowledge beforehand of the SSE instr. set.
;; The following sources have been used:
;; https://www.felixcloutier.com/x86/index.html / https://www.felixcloutier.com/x86/cvtsi2sd
;; https://en.wikibooks.org/wiki/X86_Assembly/SSE
;; https://software.intel.com/sites/default/files/m/d/4/1/d/8/Introduction_to_x64_Assembly.pdf
_calcFRAC:                  ; remember: XMM regs are 128bit wide (2x qword)
    mov r14, 16             ; our 2nd buf iter (max.16 due to buf size)
    cvtsi2sd xmm0, [twoXMM] ; store (convert, scalar!) our multiplier two in xmm regs
    cvtsi2sd xmm4, [oneXMM] ; store (convert, scalar!) the 1 as double for comparison
    cvtsi2sd xmm1, r12      ; prototype (one of them): xmmreg, rm64 (low 64bit)
    call _pow10             ; get our divisor ready (10^strlen)
    cvtsi2sd xmm2, rcx      ; convert our divisor to a double
    divsd xmm1, xmm2        ; do a scalar division between doubles (lower)
    call _hornerschemaBIN   ; call forth the SSE-powered Hornerschema
    call _addZeros_bufL16   ; thanks to r14 we know how many zero to append
    ret

_hornerschemaBIN:       ; xmm0 = 2, xmm1 = frac, xmm2 = 0, xmm4 = 1
    xorpd xmm2, xmm2    ; null out the reg
hornerschemaBINLoop:
    ;; thanks to this SO-thread for the info on _comisd_, the rest has been done independently
    ;; https://stackoverflow.com/a/37768987
    comisd xmm1, xmm2               ; check if its already 0
    je _ret                         ; jump back to caller
    cmp r14, 0                      ; check if we are running out of buffer space
    je _ret                         ; jumpback
    mulsd xmm1, xmm0                ; muliply with 2
    comisd xmm1, xmm4               ; compare result again 1
    jb hornerschemaBINLoop_addChar0 ; if above 1, strip 1 else loop & add zero to buf

    jmp hornerschemaBINLoop_addChar1; else we auto-assume it's 1.x and we add 1

hornerschemaBINLoop_addChar0:
    mov byte[bufferL16+r9], 0x30    ; add the char '0' to the ouput
    inc r9                          ; pos_ptr+1
    dec r14                         ; decr our available buf space
    jmp hornerschemaBINLoop

hornerschemaBINLoop_addChar1:
    mov byte[bufferL16+r9], 0x31    ; add the char '1' to the ouput
    inc r9                          ; pos_ptr+1
    subsd xmm1, xmm4                ; subtract exactly 1 to return back to fracs
    dec r14                         ; decr buf space
    jmp hornerschemaBINLoop

_addZeros_bufL16:
    cmp r14, 0
    je _ret
    cmp r9, 16
    je _ret

    mov byte[bufferL16+r9], 0x30    ; add the char for '0'
    inc r9                          ; pos_ptr+1
    dec r14                         ; buf space
    jmp _addZeros_bufL16

;; re-purposed code from my own convert16to10
;; Logic: integer (div) 10^strlen = real frac which was inputted
;; we basically pad the input fractional (saved as int without leading 0s) to look back
;; as fractional
_pow10:
    xor rax, rax    ; null out the register for safety
    xor rbx, rbx
    mov rbx, r13    ; copy the power (strlen!)
    mov rax, 1      ; this is the base case
pow10Loop:
    cmp rbx, 0      ; check if its zero
    je pow10NUM    ; if yes, exit
    imul rax, 10    ; rax = rax * 10
    dec rbx         ; decrement iter
    jmp pow10Loop
pow10NUM:
    mov rcx, rax    ; move the result from rax to rcx
    xor rax, rax    ; null out the reg but why though amirite lmao
    ret             ; jump back into the loop

_print32BitFP:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, outputMSG
    mov rdx, outputMSGlen
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferU16
    mov rdx, 16
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferL16
    mov rdx, 16
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, NewLine
    mov rdx, 1
    syscall

    jmp _start

_print32BitFP_NOFRAC:
    mov r14, 16             ; set the buf iter to full 16 to decrement
    call _addZeros_bufL16   ; zero it out

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, outputMSG
    mov rdx, outputMSGlen
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferU16
    mov rdx, 16
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, bufferL16
    mov rdx, 16
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, NewLine
    mov rdx, 1
    syscall

    jmp _start

_getDecMessage:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, inputMSG
    mov rdx, inputMSGlen
    syscall

    ret

_ret:
    ret

_exitFRAC:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, fracError
    mov rdx, fracErrorlen
    syscall

    jmp _exit

_exitPOINT:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, pointError
    mov rdx, pointErrorlen
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