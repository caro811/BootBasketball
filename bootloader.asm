[ORG 0x7c00]

main:
	xor ax,ax
	mov ds,ax	; ds = 0
	mov es,ax	; es = 0
	mov ss,ax	; ss = 0
	mov sp,0x7bff	; ss:sp = 0x00007bff - Direccion del stack

	mov ah,02h	; Funcion para leer sectores
	mov al,11	; Cantidad de sectores
	mov ch,0	; Numero de cilindro
	mov cl,2	; Numero de sector
	mov dh,0	; Numero de head
			; dl ya tiene el numero de drive correcto
	mov bx,0x7e00	; es:bx = 0x00007e00
	int 13h
	jc halt		; Hubo algun error

	jmp 0x00007e00	; Ir a la segunda etapa



halt:
jmp halt


times 510-($-$$) db 0
dw 0xAA55

