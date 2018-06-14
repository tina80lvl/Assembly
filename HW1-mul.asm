section         .text
global          _start

%define First rdi
%define Second rsi
%define size rcx
%define short rbx
%define stack_pointer rsp
%define Result rdx
%define FirstCopy rbp

%define reading_syscall_number 0
%define writing_syscall_number 1
%define exit_syscall_number 60

_start:
	sub stack_pointer, 4 * 128 * 8

	lea First, [stack_pointer + 128 * 8]
	mov size, 128
	call read_long ;read "Second"

	mov First, stack_pointer
	call read_long ;read "First"

	lea  Second, [stack_pointer + 128 * 8]
	lea FirstCopy, [Second +  128 * 8]
	lea Result, [FirstCopy + 128 * 8]
	call mul_long_long
	mov First, Result
	call write_long
	
	call write_endl		

	jmp  exit

mul_long_long:
	push Second						
	push size
	push First 
	push Result	
	push FirstCopy
	push rax
	push rdx

	mov rax, First
	mov First, Result
	call set_zero
	mov First, rax ; result = 0

	clc 
	.loop:			
			
		call array_copy ; array(FirstCopy) := array(First)

		mov  short, [Second] ; c = [Second]
		call mul_long_short ; First *= c
		mov rax, Second ; rax = Second
		mov Second, First ; Second = First
		mov First, Result ; First = Result
		call add_long_long    	; array(First) += array(Second) (i.e. Result += old_First * c * (2^64)^i)
		mov First, Second ; First = Second
		mov Second, rax ; Second = rax
		lea  Second, [Second + 8]						; Second = Second.next

		mov rax, First
		mov First, FirstCopy
		mov FirstCopy, rax ; swap(First, FirstCopy)
		call array_copy ; array(FirstCopy) := array(First) <=> copy back
		mov rax, First
		mov First, FirstCopy
		mov FirstCopy, rax ; swap(First, FirstCopy)

		call mul_long_2_64 ; array(First) *= 2^64

		dec  size ; --size      (++i)
		jnz  .loop ; if (size != 0) continue

	pop rdx
	pop rax
	pop FirstCopy
	pop Result
	pop First
	pop  size			
	pop  Second
	ret

array_copy: ;copies array(FIRST) to array(FirstCopy)
	push First
	push FirstCopy
	push size
	push rax

	mov size, 128
	.loop:
		mov rax, [First]
		mov [FirstCopy], rax
		lea First, [First + 8]
		lea FirstCopy, [FirstCopy + 8]
		dec size
		jnz .loop

	pop rax
	pop size
	pop FirstCopy
	pop First
	ret


mul_long_2_64:							; First *= 2^64
	push First
	push size
	push rax
	push rbx

	mov size, 127
	lea First, [First + 127 * 8] ; last_element

	.loop:
		mov rax, First
		sub First, 8
		mov rbx, [First]
		mov [rax], rbx
		dec size
		jnz .loop


	xor rax, rax
	mov [First], rax

	pop rbx
	pop rax
	pop size
	pop First
	ret

write_long_in_2_64:     ; writes long in 2^64-notation, was used for output-debugging
	push size
	push First
	push rax

	.loop:
		push size
		mov size, 1
		call write_long
		pop size
		lea First, [First + 8]
		dec size
		jnz .loop

	call write_endl

	pop rax
	pop First
	pop size
	ret



add_long_long:					;First += Second
	push First			
	push Second
	push size
	push rax

	mov size, 128
	clc				
	.loop:						
		mov  rax, [Second]			
		lea  Second, [Second + 8]		
		adc  [First], rax			
		lea  First, [First + 8]		
		dec  rcx			
		jnz  .loop			

	pop rax
	pop size
	pop  Second
	pop  First
	ret

; adds 64-bit number to long number
;    rdi -- address of summand #1 (long number)
;    rax -- summand #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    sum is written to rdi
add_long_short:				; 
	push rdi			;
	push rcx			;
	push rdx			;

	clc
	xor  rdx, rdx			;
	.loop:			;
		add  [rdi], rax			;
		adc  rdx, 0			;
		mov  rax, rdx			;
		xor  rdx, rdx			;
		add  rdi, 8			;
		dec  rcx			;
		jnz  .loop			;

	pop  rdx			;
	pop  rcx			;
	pop  rdi			;
	ret

; multiplies long number by a short
;    rdi -- address of multiplier #1 (long number)
;    rbx -- multiplier #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    product is written to rdi
%define i rdi
mul_long_short:			;
	push rax			;
	push i			;
	push size			;
	push rsi
	push short
	push rdx

	clc
	mov size, 128
	xor  rsi, rsi				;
	.loop:			;
		mov  rax, [i]			;
		mul  short				; rax *= short, result in rdx : rax
		add  rax, rsi			; rax += rsi
		adc  rdx, 0				; rdx += carry, carry.update()
		mov  [i], rax			; First[i] = rax
		add  i, 8				; ++i
		mov  rsi, rdx			; rsi = rdx
		dec  size				;
		jnz  .loop				;

	pop rdx
	pop short
	pop rsi
	pop  size			;
	pop  i			;
	pop  rax			;
	ret

; divides long number by a short
;    rdi -- address of dividend (long number)
;    rbx -- divisor (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    quotient is written to rdi
;    rdx -- remainder
div_long_short:			;
	push rdi			;
	push rax			;
	push rcx			;
	push rbx

	clc
	lea  rdi, [rdi + 8 * rcx - 8]			;
	xor  rdx, rdx			;

	.loop:			;
		mov  rax, [rdi]			;
		div  rbx			;
		mov  [rdi], rax			;
		sub  rdi, 8			;
		dec  rcx			;
		jnz  .loop			;

	pop rbx
	pop  rcx			;
	pop  rax			;
	pop  rdi			;
	ret

; assigns a zero to long number
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
set_zero:			;
	push rax			;
	push rdi			;
	push rcx			;
	push  rax

	xor  rax, rax			;
	rep stosq			;

	pop rax
	pop  rcx			;
	pop  rdi			;
	pop  rax			;
	ret

; checks if a long number is a zero
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
; result:
;    ZF=1 if zero
is_zero:			;
	push rax			;
	push rdi			;
	push rcx			;
	push rax

	xor  rax, rax			;
	rep scasq			;

	pop rax
	pop  rcx			;
	pop  rdi			;
	pop  rax			;
	ret

; read long number from stdin
;    rdi -- location for output (long number)
;    rcx -- length of long number in qwords
read_long:			;
	push rcx			;
	push rdi			;
	push rax

	call set_zero			;
	.loop:			;
	call read_char			;
	or   rax, rax			;
	js   exit			;
	cmp  rax, 0x0a			;
	je   .done			;
	cmp  rax, '0'			;
	jb   .invalid_char			;
	cmp  rax, '9'			;
	ja   .invalid_char			;

	sub  rax, '0'			;
	mov  rbx, 10			;
	call mul_long_short			;
	call add_long_short			;
	jmp  .loop			;

.done:			;
	pop rax
	pop  rdi			;
	pop  rcx			;
	ret

.invalid_char:			;
	mov  rsi, invalid_char_msg			;
	mov  rdx, invalid_char_msg_size			;
	call print_string			;
	call write_char			;
	mov  al, 0x0a			;
	call write_char			;

.skip_loop:			;
	call read_char			;
	or   rax, rax			;
	js   exit			;
	cmp  rax, 0x0a			;
	je   exit			;
	jmp  .skip_loop			;

; write long number to stdout
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
write_long:			;
	push rax			;
	push rcx			;
	push rbp
	push rsi
	push rbx
	push rdx
	push stack_pointer

	;mov rcx, 128

	mov  rax, 20			;
	mul  rcx			;
	mov  rbp, stack_pointer			;
	sub  stack_pointer, rax			;

	mov  rsi, rbp			;

	.loop:			;
		mov  rbx, 10			;
		call div_long_short			;
		add  rdx, '0'			;
		dec  rsi			;
		mov  [rsi], dl			;
		call is_zero			;
		jnz  .loop			;

	mov  rdx, rbp			;
	sub  rdx, rsi			;
	call print_string			;

	mov  stack_pointer, rbp			;

	pop stack_pointer
	pop rdx
	pop rbx
	pop rsi
	pop rbp
	pop  rcx			;
	pop  rax			;
	ret

; read one char from stdin
; result:
;    rax == -1 if error occurs
;    rax \in [0; 255] if OK
read_char:			;
	push rcx			;
	push rdi			;
	push rsi

	sub  stack_pointer, 1			;
	mov  rax, reading_syscall_number			;
	xor  rdi, rdi			;
	mov  rsi, stack_pointer			;
	mov  rdx, 1			;
	syscall			;

	cmp  rax, 1			;
	jne  .error			;
	xor  rax, rax			;
	mov  al, [stack_pointer]			;
	add  stack_pointer, 1			;

	pop rsi
	pop  rdi			;
	pop  rcx			;
	ret

.error:			;
	mov  rax, -1			;
	add  stack_pointer, 1			;
	pop  rdi			;
	pop  rcx			;
	ret

write_endl:
	push rax

	mov rax, 0x0a
	call write_char

	pop rax
	ret

; write one char to stdout, errors are ignored
;    al -- char
write_char:			;
	push rax
	push rdi
	push rsi
	push rdx

	sub  stack_pointer, 1			;
	mov  [stack_pointer], al			;

	mov  rax, writing_syscall_number				;
	mov  rdi, 1						;
	mov  rsi, stack_pointer			;
	mov  rdx, 1						;
	syscall			;
	add  stack_pointer, 1			;

	pop rdx
	pop rsi
	pop rdi	
	pop rax
	ret

exit:			;
	mov  rax, exit_syscall_number			;
	xor  rdi, rdi			;
	syscall			;

; print string to stdout
;    rsi -- string
;    rdx -- size
print_string:			;
	push rax			;
	push rdi
	push rcx
	mov rcx, 128

	mov  rax, writing_syscall_number			;
	mov  rdi, 1			;
	syscall			;
	pop rcx
	pop rdi
	pop  rax			;
	ret


section         .data			;
invalid_char_msg:			;
db   "Invalid character: "			;
invalid_char_msg_size: equ  $ - invalid_char_msg