#make_bin#

#LOAD_SEGMENT=FFFFh#
#LOAD_OFFSET=0000h#

#CS=0000h#
#IP=0000h#

#DS=0000h#
#ES=0000h#

#SS=0000h#
#SP=FFFEh#

#AX=0000h#
#BX=0000h#
#CX=0000h#
#DX=0000h#
#SI=0000h#
#DI=0000h#
#BP=0000h#

; add your code here
    jmp st1
		nop
		db 512 dup(0)

;IVT entry for 80H

		dw clock_int0
        dw 0000h 
		
		dw int_1
		dw 0000h
		 
		dw int_2
		dw 0000h
		 
        db 504 dup(0)
		
;main program
st1:          
	cli 
; intialize ds, es,ss to start of RAM (2000h to 2fffh)
	
	mov ax,0200h
    mov ds,ax
	mov es,ax
	mov ss,ax
	mov sp,0FFFEH
	mov cl,00h
	mov si,0000
;intialise portb as input   porta  & portc as output	
	
	mov al,8ah			;10001010b ->I/O mode, port A mode 0,port A output,C up input, B mode 0, B input, C low output
	out 06h,al
	mov al,11011111b
	out 00h,al
	
	
;timer - generation of one hour clock [8253]
	;12h creg
	
	mov al,00110110b    ;counter0 mode 3,binary
	out 12h,al
	mov al,01110110b    ;counter1 mode 3,binary
	out 12h,al
	mov al,10110110b    ;counter2 mode 3,binary
	out 12h,al
	
	mov ax,25000d		;cnt1=25000d
	out 0ch,al
	mov al,ah
	out 0ch,al 

	mov ax,100d			;cnt2=100d
	out 0eh,al
	mov al,ah
	out 0eh,al
	
	mov ax,3600d		;cnt3=3600d
	out 10h,al
	mov ah,al
	out 10h,al
	
;8259 initialize - vector number 80h, edge triggered

	mov al,13h			;ICW1
	out 08h,al
	mov al,80h			;ICW2
	out 0ah,al
	mov al,03h			;ICW4
	out 0ah,al
	mov al,0f8h			;OCW1
	out 0ah,al
	sti
	
	push ax
	push bx
	push cx
	mov al,cl
	mov ah,00
	mov cl,10
	div cl
	mov dh,al
	mov dl,ah
	mov cl,4
	shl dl,cl
	add dl,dh
	shl dl,2
	mov al,dl
	out 00h,al
	pop cx
	pop bx
	pop ax

AB: nop
	jmp AB			;infinite loop

clock_int0:				;whenever clock gives intrupt increament hour count and check for different levels
 	inc cl				;cl current hour
check:		
	cmp cl,24
	jne y1
	mov cl,00
	mov bh,001b
	jmp x1

y1: 
	cmp cl,5			;min -- if less 
	jl y2
	cmp cl,6			;med -- if less
	jl y3
	cmp cl,10			;max -- if less
	jl y4
	cmp cl,17			;med -- if less
	jl y3
	cmp cl,19			;max -- if less
	jl y4
	cmp cl,24			;med -- if less
	jl y3
	jmp check
						;bh contains the level it should be at
y2: 			
	mov bh,001b			;min
	jmp x1

y3:	
	mov bh,011b			;med
	jmp x1

y4:	
	mov bh,111b			;max
	jmp x1				;all go to x1:

x1:	
	cmp bl,bh			;not sure but bl is where it currently is
	jb x3
	ja x2
	iret				;if no changes required then iret here
	
;pc1 on pc2 off
;if empty the tank
x2:	
	shr bh,1			;bh-1
	mov al,02h
	out 06h,al
	mov al,05h
	out 06h,al
	iret				;turn on empty motor and iret

;pc1 off pc2 on
;fill the tank
x3:			
	mov al,03h
	out 06h,al
	mov al,04h
	out 06h,al
	iret				;turn on fill motor and iret
	
int_1:	
	in al,02h			;input from port b
	mov bl,al
	cmp bl,bh
	jne Z1				;motor should be on
	jmp Z2				;turn off motor

Z1:	cmp bl,bh
	jl Z4				;fill
	jmp Z3				;empty

Z2:	mov al,02h			;off 
	out 06h,al
	mov al,04h
	out 06h,al
	iret

Z3:	mov al,05h			;keep pc2 on empty
	out 06h,al
	mov al,02h			;pc1 off 
	out 06h,al
	iret

Z4:	mov al,03h			;keep pc1 on fill 
	out 06h,al
	mov al,04h			;pc2 off
	out 06h,al
	iret
	
int_2: 	

	in al,02h			;input from port b
	mov bl,al
	cmp bl,bh
	jne w1				;motor should be on
	jmp w2				;turn off motor

w1:	cmp bl,bh
	jl w4				;fill
	jmp w3				;empty

w2:	mov al,02h			;off 
	out 06h,al
	mov al,04h
	out 06h,al
	iret

w3:	mov al,05h			;keep pc2 on empty
	out 06h,al
	mov al,02h			;pc1 off 
	out 06h,al
	iret

w4:	mov al,03h			;keep pc1 on fill 
	out 06h,al
	mov al,04h			;pc2 off
	out 06h,al
	iret