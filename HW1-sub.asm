section .text

global start 	
%define stack_pointer rsp

%define reading_syscall_number 0 ;0x2000003 
%define writing_syscall_number 1 ;0x2000004 
%define exit_syscall_number 60 ;0x2000001 

start:
	sub stack_pointer, 2 * 128 * 8		
	lea rdi, [stack_pointer + 128 * 8]		
	mov rcx, 128 
	call read_long 
	mov rdi, stack_pointer 
	call read_long 
	lea rsi, [stack_pointer + 128 * 8]		
	
	call swap ; swap(first, second)

	call sub_long_long		

	cmp r14, 0

	call write_long 

	mov al, 0x0a 
	call write_char 

	jmp exit

swap:
	mov rax, rdi
	mov rdi, rsi
	mov rsi, rax
	ret


; adds two long number
;    rdi -- address of summand #1 (long number)
;    rsi -- address of summand #2 (long number)
;    rcx -- length of long numbers in qwords (qword означает 8-битное число)
; result:
;    sum is written to rdi
sub_long_long:
	push rdi 
	push rsi
	push rcx

	clc 	
	.loop:  
		mov rax, [rsi] 
		lea rsi, [rsi + 8]		
		sbb [rdi], rax 
		lea rdi, [rdi + 8]		
		dec rcx 
		jnz .loop		

	pop rcx 
	pop rsi
	pop rdi
	ret



; adds 64-bit number to long number
;    rdi -- address of summand #1 (long number)
;    rax -- summand #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    sum is written to rdi
add_long_short: ; 
	push rdi ;
	push rcx ;
	push rdx ;

	xor rdx,rdx ;
	.loop: ;
		add [rdi], rax ;
		adc rdx, 0 ;
		mov rax, rdx ;
		xor rdx, rdx ;
		add rdi, 8 ;
		dec rcx ;
		jnz .loop ;

	pop rdx ;
	pop rcx ;
	pop rdi ;
	ret

; multiplies long number by a short
;    rdi -- address of multiplier #1 (long number)
;    rbx -- multiplier #2 (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    product is written to rdi
mul_long_short: ;
	push rax ;
	push rdi ;
	push rcx ;

	xor rsi, rsi ;
	.loop: ;
		mov rax, [rdi] ;
		mul rbx ;
		add rax, rsi ;
		adc rdx, 0 ;
		mov [rdi], rax ;
		add rdi, 8 ;
		mov rsi, rdx ;
		dec rcx ;
		jnz .loop ;

	pop rcx ;
	pop rdi ;
	pop rax ;
	ret

; divides long number by a short
;    rdi -- address of dividend (long number)
;    rbx -- divisor (64-bit unsigned)
;    rcx -- length of long number in qwords
; result:
;    quotient is written to rdi
;    rdx -- remainder
div_long_short: ;
push rdi ;
push rax ;
push rcx ;

lea rdi, [rdi + 8 * rcx - 8] ;
xor rdx, rdx ;

.loop: ;
mov rax, [rdi] ;
div rbx ;
mov [rdi], rax ;
sub rdi, 8 ;
dec rcx ;
jnz .loop ;

pop rcx ;
pop rax ;
pop rdi ;
ret

; assigns a zero to long number
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
set_zero: ;
push rax ;
push rdi ;
push rcx ;

xor rax, rax ;
rep stosq ;

pop rcx ;
pop rdi ;
pop rax ;
ret

; checks if a long number is a zero
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
; result:
;    ZF=1 if zero
is_zero: ;
push rax ;
push rdi ;
push rcx ;

xor rax, rax ;
rep scasq ;

pop rcx ;
pop rdi ;
pop rax ;
ret

; read long number from stdin
;    rdi -- location for output (long number)
;    rcx -- length of long number in qwords
read_long: ;
push rcx ;
push rdi ;

call set_zero ;
.loop: ;
call read_char ;
or  rax, rax ;
js  exit ;
cmp rax, 0x0a ;
je  .done ;
cmp rax, '0' ;
jb  .invalid_char ;
cmp rax, '9' ;
ja  .invalid_char ;

sub rax, '0' ;
mov rbx, 10 ;
call mul_long_short ;
call add_long_short ;
jmp .loop ;

.done: ;
pop rdi ;
pop rcx ;
ret

.invalid_char: ;
mov rsi, invalid_char_msg ;
mov rdx, invalid_char_msg_size ;
call print_string ;
call write_char ;
mov al, 0x0a ;
call write_char ;

.skip_loop: ;
call read_char ;
or  rax, rax ;
js  exit ;
cmp rax, 0x0a ;
je  exit ;
jmp .skip_loop ;

; write long number to stdout
;    rdi -- argument (long number)
;    rcx -- length of long number in qwords
write_long: ;
push rax ;
push rcx ;

mov rax, 20 ;
mul rcx ;
mov rbp, stack_pointer ;
sub stack_pointer, rax ;

mov rsi, rbp ;

.loop: ;
mov rbx, 10 ;
call div_long_short ;
add rdx, '0' ;
dec rsi ;
mov [rsi], dl ;
call is_zero ;
jnz .loop ;

mov rdx, rbp ;
sub rdx, rsi ;
call print_string ;

mov stack_pointer, rbp ;
pop rcx ;
pop rax ;
ret

; read one char from stdin
; result:
;    rax == -1 if error occurs
;    rax \in [0; 255] if OK
read_char: ;
push rcx ;
push rdi ;

sub stack_pointer, 1 ;
mov rax, reading_syscall_number ;
xor rdi, rdi ;
mov rsi, stack_pointer ;
mov rdx, 1 ;
syscall ;

cmp rax, 1 ;
jne .error ;
xor rax, rax ;
mov al, [stack_pointer] ;
add stack_pointer, 1 ;

pop rdi ;
pop rcx ;
ret
.error: ;
mov rax, -1 ;
add stack_pointer, 1 ;
pop rdi ;
pop rcx ;
ret

; write one char to stdout, errors are ignored
;    al -- char
write_char: ;
	push rax
	push rdi
	push rsi
	push rdx

	sub stack_pointer, 1 ;
	mov [stack_pointer], al ;

	mov rax, writing_syscall_number ;
	mov rdi, 1 ;
	mov rsi, stack_pointer ;
	mov rdx, 1 ;
	syscall ;
	add stack_pointer, 1 ;


	pop rdx
	pop rsi
	pop rdi
	pop rax
	ret

exit: ;
	mov rax, exit_syscall_number ;
	xor rdi, rdi ;
	syscall ;

; print string to stdout
;    rsi -- string
;    rdx -- size
print_string: ;
push rax ;

mov rax, writing_syscall_number ;
mov rdi, 1 ;
syscall ;

pop rax ;
ret


section .data ;
invalid_char_msg: ;
db  "Invalid character: " ;
invalid_char_msg_size: equ $ - invalid_char_msg ;
