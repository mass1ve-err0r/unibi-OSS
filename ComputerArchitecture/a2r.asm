;;
; Name:     Arabic2Roman (a2r) in x86_64
; Author:   Saadat Baig <me@saadat.dev>
;;

;; syscall consts
%define SYS_WRITE 1
%define SYS_EXIT 60
%define SYS_READ 0
;; fd consts
%define STDOUT 1
%define STDIN 0
;; custom consts
%define NoError 0
%define NEWLINE 10

section .data
    infomsg db "Following number has been given for conversion: "
    len_infomsg equ $-infomsg
    infomsg2 db "Wrong amount of args! (only 1 allowed!)", NEWLINE
    len_infomsg2 equ $-infomsg2
    infomsg3 db "Number too high!", NEWLINE
    len_infomsg3 equ $-infomsg3
    charError db "INPUT STRING CONTAINED A NON-NUMBER CHAR", NEWLINE
    charErrorlen equ $-charError    
    NewLine db 0x0A


section .bss
    ; placeholder
    arabicNum resb 4    ; 4 bytes for the number (32bit = 1 integer)
    romanNum resb 30    ; 50 char buf

section .text
    global _start

_start:
    pop rcx         ; pop argc INTO rcx
    add rsp, 8      ; advance the stack ptr to argv1 since argv0 is the path
    ;pop r8
    pop r15         ; pop argv1 into r15 (arg1)
    cmp rcx, 2      ; check if we have exactly 1 arg
    jne _end

    call str2int    ; convert from str/ char[] to integer
    cmp r10, 3999   ; check if the input is valid/ max 3999
    ja _end2        ; Jump if above 3999 (includes 3999!)

    call calcRoman
    ;; we have no business here anymore

;;
; the following code piece has been used after long enough consideration & reading
; https://0xax.github.io/asm_3/
; he has amazing tutorials
;;
str2int:
    xor rax, rax    ; Zero-out the register
    mov rcx,  10    ; fixed-multiplier 10
compLoop:
	cmp [r15], byte 0   ; check if we have found a NULL-termination character
    je retSTR           ; break-out case
	mov bl, [r15]       ; copy the byte out into the bl register
    ;; Additional-logic: to check if its a number (stripped from my convert10to16)
    cmp bl, 0x30        ; compare if char is below the char of 0
    jb _end3
    cmp bl, 0x39        ; check if char is above the char for 9
    ja _end3
    ;; end addittional logic
    sub bl, 48          ; -48 because of the ascii range of the digits 0-9
	mul rcx             ; multiply rcx on rax
	add rax, rbx        ; store it in rbx, positional additon
	inc r15             ; increment by one to get next byte
	jmp compLoop        ; loop
retSTR:
    mov r10, rax        ; store the result in r10
	ret

;; (VAL, ASCII, DEC): (1, I, 73), (5, V, 86), (10, X, 88), (50, L, 76), (100, C, 67), (500, D, 68), (1000, M, 77)
;; EXTRA SCOUT FOR 4(IV->'73'+'86'), 40(XL->'88'+'76'), 400(CD->'67'+'68') & 9(IX->'73'+'88'), 90(XC->'88'+'67'), 900(CM->'67'+'77')
calcRoman:
    ; zero the registers
    xor rax, rax
    xor rdx, rdx
    xor rcx, rcx
    mov r9, 0       ; this is slower than XOR'ing

calcRomanThousands: ; str counter in r9, r11 holds the remainder --FXIED M, 0->3 possible
    mov rdx, 0              ; clear divisor
    mov rax, r10            ; rax holds our dividend
    mov rcx, 1000           ; the divisor
    div rcx                 ; leggo, stores RESULT in rax, REMAINDER in rdx
    mov r11, rdx            ; move the remainder into r11
    cmp rax, 0              ; check if our result is 0
    je extra_900check       ; if yes jump to 900 check for the hundreds
    jmp RaddThousands       ; else at this point we jump forward to Roman_add_Thousands

RaddThousands:      ; loop to add the necessary 1000s place shit -M
    mov byte[romanNum+r9], 77   ; add the char M
    dec rax                     ; decrement our result by 1 (counter for how many needed to add)
    inc r9                      ; inc pos iterator
    cmp rax, 0                  ; cmp Quotient, indicates how many times we need to add the char
    je extra_900check           ; jump to check for 900
    jmp RaddThousands           ; else repeat
 
extra_900check:     ; check for 900, else we'd just add normal bs, recall our num is in r11
    mov rdx, 0              ; set rdx = 0
    mov rax, r11            ; shift r11 into rax, REMEMBER: r11 holds the old r11
    mov rcx, 900            ; set divisor to 900 for the 900 check
    div rcx                 ; divide & store results AGAIN in rax= res, rdx=rem
    mov r11, rdx            ; update the remainder in r11
    cmp rax, 0              ; compare the current RAX
    je calcRomanFivehundred ; move onto 500! because 900 is an extra
    jmp extra_add900        ; else add the necessary roman numerals

extra_add900:   ; we just need to add the char for 900, then we move on
    mov byte[romanNum+r9], 67   ; add char for C
    inc r9                      ; increment r9 to next pos
    mov byte[romanNum+r9], 77   ; add char for M
    inc r9                      ; incr pos-iter
    jmp extra_90check           ; check Tenths now because our hundreds are 900!

calcRomanFivehundred:   ; loop & add the D (500)
    mov rdx, 0              ; set rdx = 0
    mov rax, r11            ; shift r11 into rax, REMEMBER: r11 holds the old r11
    mov rcx, 500            ; set divisor to 500 for the 5-hundreds
    div rcx                 ; divide & store results AGAIN in rax= res, rdx=rem
    mov r11, rdx            ; update the remainder in r11
    cmp rax, 0              ; compare the current RAX
    je extra_400check       ; move onto checking 400
    jmp RaddFivehundred     ; else add the necessary roman numerals

RaddFivehundred:
    mov byte[romanNum+r9], 68   ; add the D
    dec rax
    inc r9
    cmp rax, 0              ; cmp Quotient, indicates how many times we need to add the char
    je calcRomanHundreds    ; And now we escape to covering the range 501->899
    jmp RaddFivehundred     ; else repeat

extra_400check:
    mov rdx, 0              ; set rdx = 0
    mov rax, r11            ; shift r11 into rax, REMEMBER: r11 holds the old r11
    mov rcx, 400            ; set divisor to 400 for the 400 check
    div rcx                 ; divide & store results AGAIN in rax= res, rdx=rem
    mov r11, rdx            ; update the remainder in r11
    cmp rax, 0              ; compare the current RAX
    je calcRomanHundreds    ; move onto 100s! because 400 is extra as well
    jmp extra_add400        ; else add the necessary roman numerals

extra_add400:
    mov byte[romanNum+r9], 67   ; add char for C
    inc r9                      ; increment r9 to next pos
    mov byte[romanNum+r9], 68   ; add char for D
    inc r9                      ; incr pos-iter
    jmp extra_90check           ; check Normal 10s space

calcRomanHundreds:  ; grab r11, update rax & go -adding
    ;call Rprint
    mov rdx, 0              ; set rdx = 0
    mov rax, r11            ; shift r11 into rax, REMEMBER: r11 holds the old r11
    mov rcx, 100            ; set divisor to 100 for the hundreds
    div rcx                 ; divide & store results AGAIN in rax= res, rdx=rem
    mov r11, rdx            ; update the remainder in r11
    cmp rax, 0              ; compare the current RAX
    je extra_90check        ; move onto the tenths' 90
    jmp RaddHundreds        ; else add the necessary roman numerals

RaddHundreds:   ; add 100s
    mov byte[romanNum+r9], 67   ; char C=100
    dec rax
    inc r9
    cmp rax, 0              ; cmp Quotient, indicates how many times we need to add the char
    je extra_90check        ; escape if we gucci to next
    jmp RaddHundreds        ; else repeat

extra_90check:  ; same procedure as above for the hundreds, different divisor
    mov rdx, 0
    mov rax, r11
    mov rcx, 90
    div rcx
    mov r11, rdx
    cmp rax, 0
    je calcRomanFifty
    jmp extra_add90

extra_add90:
    mov byte[romanNum+r9], 88   ; add char for X
    inc r9                      ; increment r9 to next pos
    mov byte[romanNum+r9], 67   ; add char for X
    inc r9                      ; incr pos-iter
    jmp extra_9check            ; onto 1s

calcRomanFifty:
    mov rdx, 0
    mov rax, r11
    mov rcx, 50
    div rcx
    mov r11, rdx
    cmp rax, 0
    je extra_40check
    jmp RaddFifty

RaddFifty:
    mov byte[romanNum+r9], 76   ; char L=76
    dec rax
    inc r9
    cmp rax, 0
    je calcRomanTenths          ; cover range from 51->89
    jmp RaddFifty

extra_40check:
    mov rdx, 0
    mov rax, r11
    mov rcx, 40
    div rcx
    mov r11, rdx
    cmp rax, 0
    je calcRomanTenths
    jmp extra_add40

extra_add40:
    mov byte[romanNum+r9], 88   ; add char for X
    inc r9
    mov byte[romanNum+r9], 76   ; add char for L
    inc r9
    jmp extra_9check

calcRomanTenths:
    mov rdx, 0
    mov rax, r11
    mov rcx, 10
    div rcx
    mov r11, rdx
    cmp rax, 0
    je extra_9check
    jmp RaddTenths

RaddTenths:
    mov byte[romanNum+r9], 88   ; char X=88
    dec rax
    inc r9
    cmp rax, 0
    je extra_9check          ; cover range from 51->89
    jmp RaddTenths

extra_9check:
    mov rdx, 0
    mov rax, r11
    mov rcx, 9
    div rcx
    mov r11, rdx
    cmp rax, 0
    je calcRomanFive
    jmp extra_add9

extra_add9:
    mov byte[romanNum+r9], 73   ; add char for I
    inc r9
    mov byte[romanNum+r9], 88   ; add char for X
    inc r9
    jmp Rprint

calcRomanFive:
    mov rdx, 0
    mov rax, r11
    mov rcx, 5
    div rcx
    mov r11, rdx
    cmp rax, 0
    je extra_4check
    jmp RaddFive

RaddFive:
    mov byte[romanNum+r9], 86   ; char V=86
    dec rax
    inc r9
    cmp rax, 0
    je calcRomanOnes          ; cover range from 5->8
    jmp RaddFive

extra_4check:
    mov rdx, 0
    mov rax, r11
    mov rcx, 4
    div rcx
    mov r11, rdx
    cmp rax, 0
    je calcRomanOnes
    jmp extra_add4

extra_add4:
    mov byte[romanNum+r9], 73   ; add char for I
    inc r9
    mov byte[romanNum+r9], 86   ; add char for V
    inc r9
    jmp Rprint

calcRomanOnes:      ; final loop, no division or etc.
    mov rax, r11                ; store the left over int
    ;dec rax
    jmp RaddOne

RaddOne:
    cmp rax, 0                  ; check if its already 0
    je Rprint
    mov byte[romanNum+r9], 73   ; char I=73
    dec rax
    inc r9
    cmp rax, 0
    je Rprint                  ; cover range from 1->3
    jmp RaddOne

Rprint:
    mov byte[romanNum+50], 0
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, romanNum
    mov rdx, 50
    syscall

    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, NewLine
    mov rdx, 1
    syscall

    jmp _exit

_end:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, infomsg2
    mov rdx, len_infomsg2
    syscall

    jmp _exit

_end2:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, infomsg3
    mov rdx, len_infomsg3
    syscall

    jmp _exit

_end3:
    mov rax, SYS_WRITE
    mov rdi, STDOUT
    mov rsi, charError
    mov rdx, charErrorlen
    syscall

    jmp _exit

_exit:
    mov rax, 60
    mov rdi, 0
    syscall