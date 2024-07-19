[ORG 0x7e00]

xor ax,ax
mov ds,ax	; ds = 0
mov ss,ax	; ss = 0
mov sp,0xa000	; ss:sp = 0x00007a0000 - Direccion del stack
		; El archivo termina en 0x9400, entonces el stack es
		; de 3072 bytes, mas que suficiente para este programa.

jmp main



%define BLACK	0x0
%define BLUE	0x1
%define GREEN	0x2
%define CYAN	0x3
%define RED	0x4
%define MAGENTA	0x5
%define BROWN	0x6
%define LGRAY	0x7
%define DGRAY	0x8
%define LBLUE	0x9
%define LGREEN	0xa
%define LCYAN	0xb
%define LRED	0xc
%define LMAG	0xd
%define YELLOW	0xe
%define WHITE	0xf


;----------------------------------------------------------------------------------------------------
;	pset
; Pinta el pixel (cx,dx) del color al, si es que este esta dentro de la pantalla.
; Asume ah = 0ch (funcion para pintar pixel).
pset:
	cmp cx,0
	jl pset.fin
	cmp dx,0
	jl pset.fin
	cmp cx,319
	jg pset.fin
	cmp dx,199
	jg pset.fin

	int 10h

	.fin:
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	line(x0,y0,x1,y1,color)
; Dibuja una linea, del color 'color', con extremos (x0,y0) y (x1,y1)
; (no hay restricciones acerca de estas coordenadas)
line:
	push bp
	mov bp,sp


	mov ah,0ch	; Funcion para pintar pixel

	mov al,[bp+4]	; al = color

	mov cx,[bp+12]	; cx = x0
	mov bx,[bp+8]	; bx = x1

	cmp cx,bx	; x0 < x1 ?
	jl line.caso_1
	cmp cx,bx	; x0 > x1 ?
	jg line.caso_2
	jmp line.caso_3	; x0 == x1

	.caso_1:
	; x0 < x1
		mov bx,[bp+6]	; bx = y1
		sub bx,[bp+10]	; bx = y1 - y0
		imul bx,[bp+12]	; bx = x0*(y1-y0)
		push bx
		mov bx,[bp+8]	; bx = x1
		sub bx,[bp+12]	; bx = x1 - x0
		push bx
		call intdiv
		add sp,4
		mov bx,dx	; bx = x0*(y1-y0)/(x1-x0)
		mov cx,[bp+10]	; cx = y0
		sub cx,bx	; cx = h = y0 - x0*(y1-y0)/(x1-x0)
		push cx		; Dejamos h en el stack [bp-2]

		mov cx,[bp+6]	; cx = y1
		sub cx,[bp+10]	; cx = y1 - y0
		cmp cx,0	; y1 - y0 >= 0?
		jge line.caso_1_no_cambia_signo
		mov cx,[bp+10]	; cx = y0
		sub cx,[bp+6]	; cx = y0 - y1
		; cx = abs(y1-y0)
		.caso_1_no_cambia_signo:
		mov bx,[bp+8]	; bx = x1
		sub bx,[bp+12]	; bx = x1 - x0
		cmp bx,cx	; x1 - x0 > abs(y1-y0) ?
		jg line.caso_1_1

		.caso_1_2:
			mov dx,[bp+10]	; dx = y0
			cmp dx,[bp+6]	; y0 < y1 ?
			jl line.caso_1_2_aumentar

			.caso_1_2_decrecer:
				mov bx,[bp-2]	; bx = h
				sub bx,dx	; bx = h - yi
				mov cx,[bp+8]	; cx = x1
				sub cx,[bp+12]	; cx = x1 - x0
				imul bx,cx	; bx = (h - yi)*(x1 - x0)
				push bx
				mov bx,[bp+10]	; bx = y0
				sub bx,[bp+6]	; bx = y0 - y1
				push bx
				mov bx,dx
				call intdiv
				add sp,4
				mov cx,dx	; cx = xi = (h-yi)*(x1-x0)/(y0-y1)
				mov dx,bx
				call pset
				dec dx
				cmp dx,[bp+6]
				jge line.caso_1_2_decrecer
			add sp,2
			jmp line.fin
			.caso_1_2_aumentar:
				mov bx,dx	; bx = yi
				sub bx,[bp-2]	; bx = yi - h
				mov cx,[bp+8]	; cx = x1
				sub cx,[bp+12]	; cx = x1 - x0
				imul bx,cx	; bx = (yi - h)*(x1 - x0)
				push bx
				mov bx,[bp+6]	; bx = y1
				sub bx,[bp+10]	; bx = y1 - y0
				push bx
				mov bx,dx
				call intdiv
				add sp,4
				mov cx,dx	; cx = xi = (yi-h)*(x1-x0)/(y1-y0)
				mov dx,bx
				call pset
				inc dx
				cmp dx,[bp+6]
				jle line.caso_1_2_aumentar
		add sp,2
		jmp line.fin
		.caso_1_1:
			mov cx,[bp+12]	; cx = x0

			.caso_1_1_aumentar:
				mov bx,[bp+6]	; bx = y1
				sub bx,[bp+10]	; bx = y1 - y0
				imul bx,cx	; bx = xi*(y1 - y0)
				push bx
				mov bx,[bp+8]	; bx = x1
				sub bx,[bp+12]	; bx = x1 - x0
				push bx
				call intdiv
				add sp,4
				add dx,[bp-2]	; dx = yi = xi*(y1-y0)/(x1-x0) + h
				call pset
				inc cx
				cmp cx,[bp+8]
				jle line.caso_1_1_aumentar
	add sp,2
	jmp line.fin
	.caso_2:
	; x0 > x1
		mov cx,[bp+12]	; cx = x0
		sub cx,[bp+8]	; cx = x0 - x1
		mov bx,[bp+10]	; bx = y0
		sub bx,[bp+6]	; bx = y0 - y1
		imul bx,[bp+12]	; bx = x0*(y0-y1)
		push bx
		push cx
		call intdiv
		add sp,4
		mov bx,dx	; bx = x0*(y0-y1)/(x0-x1)
		mov cx,[bp+10]	; cx = y0
		sub cx,bx	; cx = h = y0 - x0*(y0-y1)/(x0-x1)
		push cx		; Dejamos h en el stack [bp-2]

		mov cx,[bp+6]
		sub cx,[bp+10]
		cmp cx,0	; y1-y0 >= 0?
		jge line.caso_2_no_cambia_signo
		imul cx,-1	; cambiar signo
		; cx = abs(y1-y0)
		.caso_2_no_cambia_signo:
		mov bx,[bp+12]	; bx = x0
		sub bx,[bp+8]	; bx = x0-x1
		cmp bx,cx	; x0-x1 > abs(y1-y0) ?
		jg line.caso_2_1

		.caso_2_2:
			mov dx,[bp+10]	; dx = y0
			cmp dx,[bp+6]	; y0 < y1 ?
			jl line.caso_2_2_aumentar

			.caso_2_2_decrecer:
				mov bx,[bp-2]	; bx = h
				sub bx,dx	; bx = h - yi
				mov cx,[bp+8]	; cx = x1
				sub cx,[bp+12]	; cx = x1 - x0
				imul bx,cx	; bx = (h - yi)*(x1 - x0)
				push bx
				mov bx,[bp+10]	; bx = y0
				sub bx,[bp+6]	; bx = y0 - y1
				push bx
				mov bx,dx
				call intdiv
				add sp,4
				mov cx,dx	; cx = xi = (h-yi)*(x1-x0)/(y0-y1)
				mov dx,bx
				call pset
				dec dx
				cmp dx,[bp+6]
				jge line.caso_2_2_decrecer
			add sp,2
			jmp line.fin
			.caso_2_2_aumentar:
				mov bx,dx	; bx = yi
				sub bx,[bp-2]	; bx = yi - h
				mov cx,[bp+8]	; cx = x1
				sub cx,[bp+12]	; cx = x1 - x0
				imul bx,cx	; bx = (yi - h)*(x1 - x0)
				push bx
				mov bx,[bp+6]	; bx = y1
				sub bx,[bp+10]	; bx = y1 - y0
				push bx
				mov bx,dx
				call intdiv
				add sp,4
				mov cx,dx	; cx = xi = (yi-h)*(x1-x0)/(y1-y0)
				mov dx,bx
				call pset
				inc dx
				cmp dx,[bp+6]
				jle line.caso_2_2_aumentar
		add sp,2
		jmp line.fin
		.caso_2_1:
			mov cx,[bp+12]	; cx = x0

			.caso_2_1_decrecer:
				mov bx,[bp+10]	; bx = y0
				sub bx,[bp+6]	; bx = y0 - y1
				imul bx,cx	; bx = xi*(y0 - y1)
				push bx
				mov bx,[bp+12]	; bx = x0
				sub bx,[bp+8]	; bx = x0 - x1
				push bx
				call intdiv
				add sp,4
				add dx,[bp-2]	; dx = yi = xi*(y0-y1)/(x0-x1) + h
				call pset
				dec cx
				cmp cx,[bp+8]
				jge line.caso_2_1_decrecer
	add sp,2
	jmp line.fin
	.caso_3:
	; x0 == x1
		mov cx,[bp+8]	; cx = x1
		mov dx,[bp+10]	; dx = y0
		cmp dx,[bp+6]	; y0 < y1 ?
		jl line.caso_3_aumentar

		.caso_3_decrecer:
			call pset
			dec dx
			cmp dx,[bp+6]
			jg line.caso_3_decrecer
		jmp line.fin
		.caso_3_aumentar:
			call pset
			inc dx
			cmp dx,[bp+6]
			jl line.caso_3_aumentar

	.fin:
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	rectangle(x1,y1,x2,y2,color)
; Dibuja el rectangulo (relleno), del color 'color', donde (x1,y1)
; y (x2,y2) son las coordenadas de las esquinas.
rectangle:
	push bp
	mov bp,sp

	; Primero cambio el orden de las cosas para que en realidad reciba las coordenadas de
	; las esquinas superior izquierda e inferior derecha.

	; .compare_x:
	mov dx,[bp+12]	; dx = x1
	mov bx,[bp+8]	; bx = x2
	cmp dx,bx	; x1 <= x2 ?
	jle rectangle.compare_y	; No hay cambios
	; Intercambio
	mov [bp+12],bx
	mov [bp+8],dx

	.compare_y:
	mov dx,[bp+10]	; dx = y1
	mov bx,[bp+6]	; bx = y2
	cmp dx,bx	; y1 <= y2 ?
	jle rectangle.dibujo	; No hay cambios
	; Intercambio
	mov [bp+10],bx
	mov [bp+6],dx



	; Ahora si, el dibujo:
	.dibujo:

	mov ah,0ch	; Funcion para pintar pixel

	mov al,[bp+4]	; al = color
	mov cx,[bp+12]	; cx = x1

	.horizontal:
		mov dx,[bp+10]	; dx = y1

		.vertical:
			call pset

			inc dx		; dx++
			cmp dx,[bp+6]	; dx <= y2 ?
		jle rectangle.vertical

		inc cx		; cx++
		cmp cx,[bp+8]	; cx <= x2 ?
	jle rectangle.horizontal

	.fin:
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	circle(x,y,radius,color)
; Dibuja el circulo (relleno), del color 'color', con centro (x,y) y radio 'radius'.
circle:
	push bp
	mov bp,sp


	mov ah,0ch	; Funcion para pintar pixel

	mov al,[bp+4]	; al = color
	
	mov cx,[bp+10]	; cx = x
	add cx,[bp+6]	; cx = x + r
	push cx		; [bp-2] = x + r
	mov cx,[bp+8]	; cx = y
	add cx,[bp+6]	; cx = y + r
	push cx		; [bp-4] = y + r


	mov bx,[bp+6]	; bx = r
	imul bx,bx	; bx = r^2
	push bx		; [bp-6] = r^2
	mov bx,[bp+6]	; bx = r
	inc bx		; bx = r + 1
	imul bx,bx	; bx = (r + 1)^2
	sub bx,[bp-6]	; bx = (r + 1)^2 - r^2
	add sp,2
	shr bx,2	; bx = ((r + 1)^2 - r^2)/4
	push bx		; [bp-6] = ((r + 1)^2 - r^2)/4
	mov bx,[bp+6]	; bx = r
	imul bx,bx	; bx = r^2
	add bx,[bp-6]	; bx = r^2 + ((r + 1)^2 - r^2)/4
	add sp,2
	push bx		; [bp-6] = r^2+((r+1)^2-r^2)/4


	mov cx,[bp+10]	; cx = x
	sub cx,[bp+6]	; cx = x - r

	; for xi = x-r to x+r
	.for_x_i:
		mov dx,[bp+8]	; dx = y
		sub dx,[bp+6]	; dx = y_i = y-radius

		; for yi = y-r to y+r
		.for_y_i:
			mov bx,cx	; bx = xi
			sub bx,[bp+10]	; bx = xi - x
			imul bx,bx	; bx = (xi - x)^2
			push bx		; [bp-8] = (xi - x)^2
			mov bx,dx	; bx = yi
			sub bx,[bp+8]	; bx = yi - y
			imul bx,bx	; bx = (yi - y)^2
			add bx,[bp-8]	; bx = l = (xi - x)^2 + (yi - y)^2
			add sp,2
			cmp bx,[bp-6]	; l >= r^2+((r+1)^2-r^2)/4 ?
			jge circle.no_pixel
			call pset	; pset (xi,yi,circ_color)
			.no_pixel:
			inc dx		; yi++
			cmp dx,[bp-4]	; yi <= y + radius ?
		jle circle.for_y_i

		inc cx		; xi++
		cmp cx,[bp-2]	; xi <= x + radius ?
	jle circle.for_x_i

	add sp,6

	.fin:
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	circumference(x,y,radius,color)
; Dibuja la circunferencia (o algo aproximado), del color 'color', con
; centro (x,y) y radio 'radius'.
circumference:
	push bp
	mov bp,sp


	mov ah,0ch	; Funcion para pintar pixel

	mov al,[bp+4]	; al = color

	
	mov cx,[bp+10]	; cx = x
	add cx,[bp+6]	; cx = x + r
	push cx		; [bp-2] = x + r
	mov cx,[bp+8]	; cx = y
	add cx,[bp+6]	; cx = y + r
	push cx		; [bp-4] = y + r


	mov bx,[bp+6]	; bx = r
	imul bx,bx	; bx = r^2
	push bx		; [bp-6] = r^2
	mov bx,[bp+6]	; bx = r
	inc bx		; bx = r+1
	imul bx,bx	; bx = (r+1)^2
	sub bx,[bp-6]	; bx = (r+1)^2 - r^2
	add sp,2
	shr bx,2	; bx = ((r+1)^2 - r^2)/4
	push bx		; [bp-6] = ((r+1)^2 - r^2)/4
	mov bx,[bp+6]	; bx = r
	imul bx,bx	; bx = r^2
	add bx,[bp-6]	; bx = r^2 + ((r+1)^2 - r^2)/4
	add sp,2
	push bx		; [bp-6] = r^2+((r+1)^2-r^2)/4

	mov bx,[bp+6]	; bx = r
	dec bx		; bx = r-1
	imul bx,bx	; bx = (r-1)^2
	push bx		; [bp-8] = (r-1)^2
	mov bx,[bp+6]	; bx = r
	imul bx,bx	; bx = r^2
	sub bx,[bp-8]	; bx = r^2 - (r-1)^2
	add sp,2
	shr bx,2	; bx = (r^2 - (r-1)^2)/4
	push bx		; [bp-8] = (r^2 - (r-1)^2)/4
	mov bx,[bp+6]	; bx = r
	dec bx		; bx = r-1
	imul bx,bx	; bx = (r-1)^2
	sub bx,[bp-8]	; bx = (r-1)^2 - (r^2 - (r-1)^2)/4
	add sp,2
	push bx		; [bp-8] = (r-1)^2-(r^2-(r-1)^2)/4

	mov cx,[bp+10]	; cx = x
	sub cx,[bp+6]	; cx = x - r

	; for xi = x-r to x+r
	.for_x_i:
		mov dx,[bp+8]	; dx = y
		sub dx,[bp+6]	; dx = y_i = y - r

		; for yi = y-r to y+r
		.for_y_i:
			mov bx,cx	; bx = xi
			sub bx,[bp+10]	; bx = xi - x
			imul bx,bx	; bx = (xi - x)^2
			push bx		; [bp-10] = (xi - x)^2
			mov bx,dx	; bx = yi
			sub bx,[bp+8]	; yi - y
			imul bx,bx	; bx = (yi - y)^2
			add bx,[bp-10]	; bx = l = (xi - x)^2 + (yi - y)^2
			add sp,2
			cmp bx,[bp-6]	; l >= r^2+((r+1)^2-r^2)/4 ?
			jge circumference.no_pixel
			cmp bx,[bp-8]	; l < (r-1)^2+(r^2-(r-1)^2)/4 ?
			jl circumference.no_pixel
			call pset	; pset (xi,yi,circ_color)
			.no_pixel:
			inc dx		; yi++
			cmp dx,[bp-4]	; yi <= y + radius ?
		jle circumference.for_y_i

		inc cx		; xi++
		cmp cx,[bp-2]	; xi <= x + radius ?
	jle circumference.for_x_i

	add sp,8

	.fin:
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	print_basket()
; Imprime la canasta
print_basket:
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	inc dx
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	push 319
	mov dx,[basket_web_top_y]
	dec dx
	push dx
	push WHITE
	call rectangle	; rectangle(basket_center_x+basket_radius+1,basket_circle_top_y,
			; 319,basket_web_top_y-1,WHITE)
	add sp,10

	push 310
	mov dx,[basket_web_top_y]
	push dx
	push 319
	mov dx,[floor_level]
	dec dx
	push dx
	push WHITE
	call rectangle	; rectangle(310,basket_web_top_y,319,floor_level,WHITE)
	add sp,10

	mov dx,[basket_center_x]
	add dx,[basket_radius]
	inc dx
	push dx
	mov dx,[basket_circle_top_y]
	dec dx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	add dx,3
	push dx
	mov dx,[basket_circle_top_y]
	sub dx,[basket_length]
	push dx
	push WHITE
	call rectangle	; rectangle(basket_center_x+basket_radius+1,basket_circle_top_y-1,
			; basket_center_x+basket_radius+3,basket_circle_top_y-basket_length,WHITE)
	add sp,10



	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_web_top_y,
			; basket_center_x-basket_radius,basket_web_top_y+basket_length,
			; basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	sub dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	sub dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius/2,basket_web_top_y,
			; basket_center_x-basket_radius/2,basket_web_top_y+basket_length,
			; basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x,basket_web_top_y,
			; basket_center_x,basket_web_top_y+basket_length,basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x+basket_radius/2,basket_web_top_y,
			; basket_center_x+basket_radius/2,basket_web_top_y+basket_length,
			; basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x+basket_radius,basket_web_top_y,
			; basket_center_x+basket_radius,basket_web_top_y+basket_length,
			; basket_web_color)
	add sp,10


	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,2
	add dx,bx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,2
	add dx,bx
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_web_top_y+basket_length/4,
			; basket_center_x+basket_radius,basket_web_top_y+basket_length/4,
			; basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_web_top_y+basket_length/2,
			; basket_center_x+basket_radius,basket_web_top_y+basket_length/2,
			; basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	mov bx,[basket_length]
	shr bx,2
	sub dx,bx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	mov bx,[basket_length]
	shr bx,2
	sub dx,bx
	push dx
	mov dx,[basket_web_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,
			; basket_web_top_y+basket_length*3/4,basket_center_x+basket_radius,
			; basket_web_top_y+basket_length*3/4,basket_web_color)
	add sp,10

	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_web_top_y]
	dec dx
	push dx
	mov dx,[basket_circle_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_circle_top_y,
			; basket_center_x+basket_radius,basket_web_top_y-1,basket_circle_color)
	add sp,10

	ret
;----------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------
;	erase_basket()
; Imprime la canasta
erase_basket:
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	inc dx
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	push 319
	mov dx,[basket_web_top_y]
	dec dx
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x+basket_radius+1,basket_circle_top_y,
			; 319,basket_web_top_y-1,wall_color)
	add sp,10

	push 310
	mov dx,[basket_web_top_y]
	push dx
	push 319
	mov dx,[floor_level]
	dec dx
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(310,basket_web_top_y,319,floor_level,wall_color)
	add sp,10

	mov dx,[basket_center_x]
	add dx,[basket_radius]
	inc dx
	push dx
	mov dx,[basket_circle_top_y]
	dec dx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	add dx,3
	push dx
	mov dx,[basket_circle_top_y]
	sub dx,[basket_length]
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x+basket_radius+1,basket_circle_top_y-1,
			; basket_center_x+basket_radius+3,basket_circle_top_y-basket_length,wall_color)
	add sp,10



	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_web_top_y,
			; basket_center_x-basket_radius,basket_web_top_y+basket_length,
			; wall_color)
	add sp,10

	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	sub dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	sub dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius/2,basket_web_top_y,
			; basket_center_x-basket_radius/2,basket_web_top_y+basket_length,
			; wall_color)
	add sp,10

	mov dx,[basket_center_x]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x,basket_web_top_y,
			; basket_center_x,basket_web_top_y+basket_length,wall_color)
	add sp,10

	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	mov bx,[basket_radius]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x+basket_radius/2,basket_web_top_y,
			; basket_center_x+basket_radius/2,basket_web_top_y+basket_length,
			; wall_color)
	add sp,10

	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x+basket_radius,basket_web_top_y,
			; basket_center_x+basket_radius,basket_web_top_y+basket_length,
			; wall_color)
	add sp,10


	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,2
	add dx,bx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,2
	add dx,bx
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_web_top_y+basket_length/4,
			; basket_center_x+basket_radius,basket_web_top_y+basket_length/4,
			; wall_color)
	add sp,10

	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	mov bx,[basket_length]
	shr bx,1
	add dx,bx
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_web_top_y+basket_length/2,
			; basket_center_x+basket_radius,basket_web_top_y+basket_length/2,
			; wall_color)
	add sp,10

	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	mov bx,[basket_length]
	shr bx,2
	sub dx,bx
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	add dx,[basket_length]
	mov bx,[basket_length]
	shr bx,2
	sub dx,bx
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,
			; basket_web_top_y+basket_length*3/4,basket_center_x+basket_radius,
			; basket_web_top_y+basket_length*3/4,wall_color)
	add sp,10

	mov dx,[basket_center_x]
	sub dx,[basket_radius]
	push dx
	mov dx,[basket_circle_top_y]
	push dx
	mov dx,[basket_center_x]
	add dx,[basket_radius]
	push dx
	mov dx,[basket_web_top_y]
	dec dx
	push dx
	mov dx,[wall_color]
	push dx
	call rectangle	; rectangle(basket_center_x-basket_radius,basket_circle_top_y,
			; basket_center_x+basket_radius,basket_web_top_y-1,wall_color)
	add sp,10

	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	draw_arrow(a,b,x,y,length,color)
; Dibuja una flecha de (a,b) a (x,y), de longitud 'length' y color 'color'
draw_arrow:
	push bp
	mov bp,sp

	mov bx,[bp+14]	; a
	push bx
	mov bx,[bp+12]	; b
	push bx
	mov bx,[bp+10]	; x
	push bx
	mov bx,[bp+8]	; y
	push bx
	mov bx,[bp+4]	; color
	push bx
	call line	; line(a,b,x,y,color)
	add sp,10

	mov cx,[bp+10]
	sub cx,[bp+14]	; cx = x-a
	imul cx,cx	; cx = (x-a)^2
	mov dx,[bp+6]	; dx = length
	imul dx,dx	; dx = length^2
	sub dx,cx	; dx = length^2 - (x-a)^2
	push dx
	call isqrt	; dx = s = isqrt(length^2 - (x-a)^2)
	add sp,2
	push dx		; [bp-2] = s

	mov cx,[bp+10]	; cx = x
	sub cx,[bp+14]	; cx = x - a
	add cx,[bp-2]	; cx = s + (x-a)
	mov dx,[bp+10]	; dx = x
	imul dx,11	; dx = 11x
	sub dx,cx	; dx = 11x - (s + (x-a))
	push dx
	mov cx,11
	push cx
	call intdiv	; dx = (11x - (s + (x-a)))/11
	add sp,4
	mov bx,dx	; bx = x - (s + (x - a))/11

	mov cx,[bp+10]	; cx = x
	sub cx,[bp+14]	; cx = x - a
	mov dx,[bp-2]	; dx = s
	sub dx,cx	; dx = s - (x-a)
	mov cx,[bp+8]	; cx = y
	imul cx,11	; cx = 11x
	add dx,cx	; dx = 11y + (s - (x-a))
	push dx
	mov cx,11
	push cx
	call intdiv	; dx = (11y + (s - (x-a)))/11
	add sp,4
	mov cx,dx	; cx = y + (s - (x-a))/11


	mov dx,[bp+10]	; x
	push dx
	mov dx,[bp+8]	; y
	push dx
	push bx		; x - (s + (x - a))/11
	push cx		; y + (s - (x-a))/11
	mov dx,[bp+4]	; color
	push dx
	call line	; line(x,y,x - (s + (x - a))/11,y + (s - (x-a))/11,color)
	add sp,10


	mov cx,[bp+10]	; cx = x
	sub cx,[bp+14]	; cx = x - a
	add cx,[bp-2]	; cx = s + (x-a)
	mov dx,[bp+8]	; dx = y
	imul dx,11	; dx = 11y
	add dx,cx	; dx = 11y + (s + (x-a))
	push dx
	mov cx,11
	push cx
	call intdiv	; dx = (11y + (s + (x-a)))/11
	add sp,4
	mov bx,dx	; bx = y + (s + (x - a))/11

	mov cx,[bp+10]	; cx = x
	sub cx,[bp+14]	; cx = x - a
	mov dx,[bp-2]	; dx = s
	sub dx,cx	; dx = s - (x-a)
	mov cx,[bp+10]	; cx = x
	imul cx,11	; cx = 11x
	add dx,cx	; dx = 11x + (s - (x-a))
	push dx
	mov cx,11
	push cx
	call intdiv	; dx = (11x + (s - (x-a)))/11
	add sp,4
	mov cx,dx	; cx = x + (s - (x - a))/11


	mov dx,[bp+10]	; x
	push dx
	mov dx,[bp+8]	; y
	push dx
	push cx		; x + (s - (x - a))/11
	push bx		; y + (s + (x - a))/11
	mov dx,[bp+4]	; color
	push dx
	call line	; line(x,y,x + (s - (x - a))/11,y + (s + (x - a))/11,color)
	add sp,10

	add sp,2
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	print_arrow
; Dibuja la flecha de (origin_x,origin_y) a (vx,vy)
print_arrow:
	mov bx,[origin_x]
	push bx
	mov bx,[origin_y]
	push bx
	mov bx,[vx]
	push bx
	mov bx,[vy]
	push bx
	mov bx,[arrow_length]
	push bx
	mov bx,[arrow_color]
	push bx
	call draw_arrow
	add sp,12

	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	erase_arrow
; Borra la flecha de (origin_x,origin_y) a (vx,vy)
erase_arrow:
	mov bx,[origin_x]
	push bx
	mov bx,[origin_y]
	push bx
	mov bx,[vx]
	push bx
	mov bx,[vy]
	push bx
	mov bx,[arrow_length]
	push bx
	mov bx,[wall_color]
	push bx
	call draw_arrow
	add sp,12

	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	print_ball(x,y)
; Dibuja la pelota con centro en (x,y)
print_ball:
	push bp
	mov bp,sp

	mov dx,[bp+6]
	push dx
	mov bx,[bp+4]
	push bx
	mov cx,[ball_radius]
	push cx
	mov cx,[ball_color]
	push cx
	call circle
	add sp,8		; circle(x,y,ball_radius,ball_color)

	mov cx,[bp+6]		; cx = x
	sub cx,[ball_radius]	; cx = x - ball_radius
	mov dx,[bp+6]		; dx = x
	add dx,[ball_radius]	; dx = x + ball_radius
	push cx
	mov bx,[bp+4]
	push bx
	push dx
	push bx
	push BLACK
	call line		; line(x-ball_radius,y,x+ball_radius,y,0)
	add sp,10

	mov cx,[ball_radius]	; cx = ball_radius
	shr cx,1		; cx = ball_radius/2
	mov dx,[bp+6]
	push dx
	mov bx,[bp+4]
	push bx
	push cx
	push BLACK
	call circumference
	add sp,8		; circumference(x,y,ball_radius/2,0)

	mov cx,[ball_radius]
	mov dx,[bp+6]
	push dx
	mov bx,[bp+4]
	push bx
	push cx
	push BLACK
	call circumference
	add sp,8		; circumference(x,y,ball_radius,0)

	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	erase_ball(x,y)
; Borra la pelota con centro en (x,y)
erase_ball:
	push bp
	mov bp,sp

	mov dx,[bp+6]	; dx = x
	push dx
	mov bx,[bp+4]	; bx = y
	push bx
	mov cx,[ball_radius]
	push cx
	mov cx,[wall_color]
	push cx
	call circle
	add sp,8		; circle(x,y,ball_radius,wall_color)

	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	print_background()
; Dibuja el fondo
print_background:
	xor dx,dx
	push dx
	push dx
	push 319
	mov bx,[floor_level]
	dec bx
	push bx
	mov bx,[wall_color]
	push bx
	call rectangle		; rectangle(0,0,319,floor_level-1,wall_color)
	add sp,10

	xor dx,dx
	push dx
	mov bx,[floor_level]
	push bx
	push 319
	push 199
	mov bx,[floor_color]
	push bx
	call rectangle		; rectangle(0,floor_level,319,199,floor_color)
	add sp,10

	call print_arrow	; print_arrow

	mov dx,[origin_x]
	push dx
	mov dx,[origin_y]
	push dx
	call print_ball
	add sp,4		; print_ball(origin_x,origin_y)

	call print_basket	; print_basket()

	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	check_score(x,y)
; Se fija si la posicion (x,y) de la pelota es ganadora.
; Guarda en dx el resultado. 0 si no es ganadora, 1 si lo es.
check_score:
	push bp
	mov bp,sp


	mov cx,[basket_center_x]	; cx = basket_center_x
	add cx,[basket_radius]		; cx = basket_center_x + basket_radius
	mov dx,[bp+6]			; dx = x
	add dx,[ball_radius]		; dx = x + ball_radius
	cmp dx,cx			; x + ball_radius > basket_center_x + basket_radius ?
	jg check_score.no_score

	sub dx,[ball_radius]		; dx = x
	sub dx,[ball_radius]		; dx = x - ball_radius
	sub cx,[basket_radius]		; cx = basket_center_x
	sub cx,[basket_radius]		; cx = basket_center_x - basket_radius
	cmp dx,cx			; x - ball_radius < basket_center_x - basket_radius ?
	jl check_score.no_score


	mov cx,[basket_circle_top_y]	; cx = basket_circle_top_y
	mov dx,[bp+4]			; dx = y
	sub dx,[ball_radius]		; dx = y - ball_radius
	cmp dx,cx			; y-ball_radius > basket_circle_top_y ?
	jg check_score.no_score

	add dx,[ball_radius]		; dx = y
	add dx,[ball_radius]		; dx = y + ball_radius
	cmp dx,cx			; y + ball_radius < basket_circle_top_y ?
	jl check_score.no_score


	; WIN
	xor dx,dx	; dx = 0
	inc dx		; dx = 1
	pop bp
	ret

	.no_score:
	xor dx,dx	; dx = 0
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	check_bounce(x,y)
; Se fija si la posicion (x,y) de la pelota genera rebote.
; Guarda en dx el resultado. 0 si no rebota, 1 y 3 si rebota en el aro, 2 si rebota en la placa.
; (considero dos rebotes distintos  contra el aro)
check_bounce:
	push bp
	mov bp,sp

	mov dx,[bp+6]			; dx = x
	add dx,[ball_radius]		; dx = x + ball_radius
	mov cx,[basket_center_x]	; cx = basket_center_x
	sub cx,[basket_radius]		; cx = basket_center_x - basket_radius
	cmp dx,cx			; x + ball_radius < basket_center_x - basket_radius ?
	jl check_bounce.no_case_1

	mov dx,[bp+6]			; dx = x
	sub dx,[ball_radius]		; dx = x - ball_radius
	mov cx,[basket_center_x]	; cx = basket_center_x
	sub cx,[basket_radius]		; cx = basket_center_x - basket_radius
	cmp dx,cx			; x - ball_radius >= basket_center_x - basket_radius ?
	jge check_bounce.no_case_1

	mov dx,[bp+4]			; dx = y
	add dx,[ball_radius]		; dx = y + ball_radius
	mov cx,[basket_circle_top_y]	; cx = basket_circle_top_y
	cmp dx,cx			; y + ball_radius < basket_circle_top_y ?
	jl check_bounce.no_case_1

	mov dx,[bp+4]			; dx = y
	sub dx,[ball_radius]		; dx = y - ball_radius
	mov cx,[basket_web_top_y]	; cx = basket_web_top_y
	dec cx				; cx = basket_web_top_y - 1
	cmp dx,cx			; y - ball_radius > basket_web_top_y - 1 ?
	jg check_bounce.no_case_1

	.case_1:
		mov dx,[bp+6]			; dx = x
		mov cx,[basket_center_x]	; cx = basket_center_x
		sub cx,[basket_radius]		; cx = basket_center_x - basket_radius
		cmp dx,cx			; x <= basket_center_x - basket_radius ?
		jle check_bounce.no_case_3
		.case_3:
			mov dx,3
			pop bp
			ret
		.no_case_3:
			xor dx,dx
			inc dx
			pop bp
			ret

	.no_case_1:


	mov dx,[bp+6]			; dx = x
	add dx,[ball_radius]		; dx = x + ball_radius
	mov cx,[basket_center_x]	; cx = basket_center_x
	add cx,[basket_radius]		; cx = basket_center_x + basket_radius
	inc cx				; cx = basket_center_x + basket_radius + 1
	cmp dx,cx			; x + ball_radius <= basket_center_x + basket_radius + 1 ?
	jle check_bounce.no_case_2

	mov dx,[bp+6]			; dx = x
	mov cx,[basket_center_x]	; cx = basket_center_x
	add cx,[basket_radius]		; cx = basket_center_x + basket_radius
	inc cx 				; cx = basket_center_x + basket_radius + 1
	cmp dx,cx			; x >= basket_center_x + basket_radius + 1 ?
	jge check_bounce.no_case_2

	mov dx,[bp+4]			; dx = y
	add dx,[ball_radius]		; dx = y + ball_radius
	mov cx,[basket_circle_top_y]	; cx = basket_circle_top_y
	sub cx,[basket_length]		; cx = basket_circle_top_y - basket_length
	cmp dx,cx			; y + ball_radius < basket_circle_top_y - basket_length ?
	jl check_bounce.no_case_2

	mov dx,[bp+4]			; dx = y
	sub dx,[ball_radius]		; dx = y - ball_radius
	mov cx,[basket_web_top_y]	; cx = basket_web_top_y
	cmp dx,cx			; y - ball_radius > basket_circle_top_y ?
	jg check_bounce.no_case_2

	.case_2:
		mov dx,2
		pop bp
		ret

	.no_case_2:

	; No rebota
	xor dx,dx	; dx = 0
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	throw_ball(x,y)
; Ejecuta el tiro de la pelota desde la posicion (x,y).
; Devuelve en dx 1 si el tiro fue exitoso (se gano el juego), 0 en caso contrario.
throw_ball:
	push bp
	mov bp,sp

	call erase_arrow	; erase_arrow

	mov bx,[origin_x]
	push bx
	mov bx,[origin_y]
	push bx
	call print_ball		; print_ball(origin_x,origin_y)
	add sp,4


	xor bx,bx
	push bx			; [bp-2] = t = 0

	mov bx,[bp+6]		; bx = x
	sub bx,[origin_x]	; bx = x - origin_x
	push bx			; [bp-4] = v0x = x - origin_x
	mov bx,[origin_y]	; bx = origin_y
	sub bx,[bp+4]		; bx = origin_y - y
	push bx			; [bp-6] = v0y = origin_y - y

	mov bx,[origin_x]
	push bx			; [bp-8] = x0 = origin_x
	mov bx,[origin_y]
	push bx			; [bp-10] = y0 = origin_y

	mov bx,[bp-8]
	push bx			; [bp-12] = xi = x0
	mov bx,[bp-10]
	push bx			; [bp-14] = yi = y0

	; Ahora en el stack tenemos:
	;	+--------+
	;	|    x   | 6
	;	+--------+
	;	|    y   | 4
	;	+--------+
	;	| ****** | 2
	;	+--------+
	;	|   bp   | 0
	;	+--------+
	;	|    t   | -2
	;	+--------+
	;	|   v0x  | -4
	;	+--------+
	;	|   v0y  | -6
	;	+--------+
	;	|   x0   | -8
	;	+--------+
	;	|   y0   | -10
	;	+--------+
	;	|   xi   | -12
	;	+--------+
	;	|   yi   | -14
	;	+--------+
	; El hecho de que xi,yi esten al final del stack hace que no tengamos que pushearlos
	; de nuevo cuando queremos llamar a una funcion que los tome como parametros.

	.loop:
		call erase_ball ; erase_ball(xi,yi)

		inc word [bp-2]	; t = t+1. Incremento t de a 1, y cuando la uso divido por 8

		mov cx,[bp-4]	; cx = v0x
		imul cx,[bp-2]	; cx = v0x*t
		xor bx,bx
		inc bx	; bx = 1
		cmp cx,0
		jge throw_ball.v0xnoneg
		imul cx,-1
		imul bx,-1
		.v0xnoneg:
		shr cx,3	; cx = v0x*t/8
		imul cx,bx
		add cx,[bp-8]	; cx = x0 + v0x*t/8
		mov [bp-12],cx	; xi = x0 + v0x*t/8

		mov dx,[bp-10]	; dx = y0
		mov bx,[bp-6]	; bx = v0y
		imul bx,[bp-2]	; bx = v0y*t
		xor cx,cx
		inc cx	; cx = 1
		cmp bx,0
		jge throw_ball.v0ynoneg
		imul bx,-1
		imul cx,-1
		.v0ynoneg:
		shr bx,3	; bx = v0y*t/8
		imul bx,cx
		sub dx,bx	; dx = y0 - v0y*t/8
		mov bx,[bp-2]	; bx = t
		imul bx,bx	; bx = t*t
		shr bx,4	; bx = t*t*4/64
		add dx,bx	; dx = y0 - v0y*t/4 + t*t*4/64
		mov [bp-14],dx	; yi = y0 - v0y*t/4 + t*t*4/64

		call check_bounce ; check_bounce(xi,yi)
		; En dx esta el resultado de check_bounce
		cmp dx,0
		je throw_ball.no_bounce	; Caso dx == 0, no hay rebote.

		; Rebote
		xor bx,bx	; bx = 0
		sub bx,[bp-4]	; bx = -v0x
		mov [bp-4],bx	; v0x = -v0x
		mov bx,[bp-2]	; bx = t
				; bx = t*8/8
		mov cx,[bp-6]	; cx = v0y
		sub cx,bx	; bx = v0y - t*8/8
		mov [bp-6],cx	; v0y = v0y - t*8/8

		cmp dx,2
		je throw_ball.rebote_2	; Caso dx == 2, rebote contra la placa

		cmp dx,1
		je throw_ball.rebote_1	; Caso dx == 1, rebote contra el aro (1)

		.rebote_3:		; Caso dx == 3, rebote contra el aro (2)
			mov bx,[basket_center_x] ; bx = basket_center_x
			sub bx,[basket_radius]	 ; bx = basket_center_x - basket_radius
			add bx,[ball_radius] ; bx = basket_center_x - basket_radius + ball_radius
			inc bx		; bx = basket_center_x - basket_radius + ball_radius + 1
			mov [bp-8],bx	; x0 = basket_center_x - basket_radius + ball_radius + 1

			jmp throw_ball.rebote_salida

		.rebote_1:
			mov bx,[basket_center_x] ; bx = basket_center_x
			sub bx,[basket_radius]	 ; bx = basket_center_x - basket_radius
			sub bx,[ball_radius] ; bx = basket_center_x - basket_radius - ball_radius
			dec bx		; bx = basket_center_x - basket_radius - ball_radius - 1
			mov [bp-8],bx	; x0 = basket_center_x - basket_radius - ball_radius - 1

			jmp throw_ball.rebote_salida

		.rebote_2:
			mov bx,[basket_center_x] ; bx = basket_center_x
			add bx,[basket_radius]	 ; bx = basket_center_x + basket_radius
			sub bx,[ball_radius] ; bx = basket_center_x + basket_radius - ball_radius
			dec bx		; bx = basket_center_x + basket_radius - ball_radius - 1
			mov [bp-8],bx	; x0 = basket_center_x + basket_radius - ball_radius - 1

		.rebote_salida:
			mov cx,[bp-8]	; cx = x0
			mov [bp-12],cx	; xi = x0
			mov cx,[bp-14]	; cx = yi
			mov [bp-10],cx	; y0 = yi
			xor cx,cx	; cx = 0
			mov [bp-2],cx	; t = 0

		.no_bounce:
		call print_ball		; print_ball(xi,yi)
        	call print_basket	; print_basket()

		xor cx,cx	;mov cx,0x0000
		mov dx,0xf424
		mov ah,86h
		int 15h			; wait 1/16 s


	; loop until (	(yi > origin_y) or		- Pelota que toca el piso
	;		(check_score(xi,yi)>0) or	- Gana el juego
	;		(xi<0) or (xi>319)	)	- Pelota que no puede volver
		mov dx,[bp-14]		; dx = yi
		cmp dx,[origin_y]	; yi > origin_y?
		jg throw_ball.end_loop	; loop until yi > origin_y

		call check_score	; En dx el resultado
		cmp dx,0		; dx > 0?
		jg throw_ball.end_loop	; loop until check_score(xi,yi)>0

		mov cx,[bp-12]		; cx = xi
		cmp cx,0		; xi < 0?
		jl throw_ball.end_loop	; loop until xi<0
		cmp cx,319		; xi > 319?
		jg throw_ball.end_loop	; loop until xi>319

		jmp throw_ball.loop


	.end_loop:
	call check_score
	cmp dx,0
	jne throw_ball.win	; dx != 0 --> Gano el juego

	call lose		; dx == 0 --> Perdio el juego
	xor dx,dx
	add sp,14
	pop bp
	ret

	.win:
	call win
	xor dx,dx
	inc dx
	add sp,14
	pop bp
	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	lose()
; Muestra mensaje perdedor
lose:
	mov ah,13h
	mov al,00h
	xor bx,bx
	mov es,bx
	mov bl,LRED
	mov bp,lost_ms
	mov cx,11
	mov dh,10
	mov dl,15
	int 10h

	mov cx,0x000b
	mov dx,0x71b0
	mov ah,86h
	int 15h		; wait 3/4s

	ret
;----------------------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------------------
;	win()
; Muestra mensaje ganador
win:
	mov ah,13h
	mov al,00h
	xor bx,bx
	mov es,bx
	mov bl,LRED
	mov bp,won_ms
	mov cx,10
	mov dh,10
	mov dl,15
	int 10h

	mov cx,0x000b
	mov dx,0x71b0
	mov ah,86h
	int 15h		; wait 3/4s

	ret
;----------------------------------------------------------------------------------------------------



;----------------------------------------------------------------------------------------
;	intdiv(n,d)
; dx = n/d
intdiv:			; |  n | bp+6
	push bp		; |  d | bp+4
	mov bp,sp	; | ret| bp+2
			; | bp | bp
	push ax		; | ax | bp-2
	push bx		; | bx | bp-4
	push cx		; | cx | bp-6
	; Registros que uso en la funcion y no quiero modificar.

	xor bx,bx
	inc bx		; (bx = 1) bx guarda el signo de la operacion.

	mov cx,[bp+4]	; cx = d
	cmp cx,0
	jge intdiv.d_no_negativo
	imul cx,-1
	imul bx,-1
	.d_no_negativo:
	; cx = abs(d)

	xor dx,dx	; dx = 0
	mov ax,[bp+6]	; ax = n
	cmp ax,0
	jge intdiv.n_no_negativo
	imul ax,-1
	imul bx,-1
	.n_no_negativo:
	; dx:ax = abs(n)

	div cx
	; dx = resto
	; ax = cociente


	shr cx,1	; cx /= 2
	cmp dx,cx
	jle intdiv.fin	; resto <= d/2 ?
			; Si lo es, devolvemos ax (o sea, piso[n/d])
	inc ax		; Si no, le sumamos 1 a ax (o sea, techo[n/d])


	.fin:

	imul ax,bx	; le cambia el signo si es necesario

	mov dx,ax
	mov ax,[bp-2]
	mov bx,[bp-4]
	mov cx,[bp-6]
	add sp,6
	pop bp
	ret
;----------------------------------------------------------------------------------------

;----------------------------------------------------------------------------------------
;	isqrt(n)
; Calcula la parte entera de la raiz cuadrada del entero n, y guarda el resultado en dx
isqrt:
	push bp
	mov bp,sp

	push ax	; despues lo recuperamos


	mov cx,[bp+4]	; cx = n

	xor dx,dx	; dx = res = 0

	xor bx,bx
	inc bx
	shl bx,14	; bx = bit = 1 << 14

	cmp bx,cx
	jle isqrt.no_loop1
	.loop1:	; while(bit > n)
		shr bx,2	; bit >>= 2
		cmp bx,cx
		jg isqrt.loop1
	.no_loop1:
	cmp bx,0
	je isqrt.fin

	;n >= res + bit
	sub cx,dx
	sub cx,bx	; n -= res + bit
	mov dx,bx	; res = bit
	shr bx,2	; bit >>= 2

	.loop2:	; while(bit != 0)
		cmp bx,0
		je isqrt.fin

		mov ax,bx
		add ax,dx
		cmp cx,ax	; n >= res+bit ?
		jge isqrt.case_1

		shr dx,1	; res >>= 1
		shr bx,2	; bit >>= 2
		jmp isqrt.loop2

		.case_1:
			sub cx,dx
			sub cx,bx	; n -= res + bit
			shr dx,1	; res >>= 1
			add dx,bx	; res += bit
			shr bx,2	; bit >>= 2
			jmp isqrt.loop2

	.fin:
	mov ax,[bp-2]
	add sp,2
	pop bp
	ret
;----------------------------------------------------------------------------------------







main:
	xor ax,ax
	mov al,13h
	int 10h


	mov ah,13h
	mov al,00h
	xor bx,bx
	mov es,bx


	mov bl,LRED

	mov bp,titulo
	mov cx,10
	mov dh,1
	mov dl,15
	int 10h

	mov bp,autor
	mov cx,27
	mov dh,3
	mov dl,7
	int 10h


	mov bl,WHITE

	mov bp,inst_l1
	mov cx,14
	mov dh,8
	mov dl,0
	int 10h

	mov bp,inst_l2
	mov cx,35
	mov dh,10
	mov dl,1
	int 10h

	mov bp,inst_l3
	mov dh,12
	int 10h

	mov bp,inst_l4
	mov cx,31
	mov dh,15
	int 10h

	mov bp,inst_li
	mov cx,13
	mov dh,13
	mov dl,3
	int 10h

	push 0
	push 50
	push 319
	push 52
	push WHITE
	call rectangle
	add sp,10
	push 0
	push 140
	push 319
	push 142
	push WHITE
	call rectangle
	add sp,10


	push 20
	push 20
	call print_ball
	add sp,4
	push 300
	push 20
	call print_ball
	add sp,4


	.main_loop:
		mov ah,13h
		mov al,00h
		xor bx,bx
		mov es,bx
		mov bl,RED
		mov bp,inst_c
		mov cx,26
		mov dh,21
		mov dl,7
		int 10h

		push 50
		push 160
		push 270
		push 162
		push RED
		call rectangle
		add sp,10
		push 50
		push 180
		push 270
		push 182
		push RED
		call rectangle
		add sp,10
		push 50
		push 162
		push 52
		push 180
		push RED
		call rectangle
		add sp,10
		push 268
		push 162
		push 270
		push 180
		push RED
		call rectangle
		add sp,10

		mov cx,0x000b
		mov dx,0x71b0
		mov ah,86h
		int 15h		; wait 3/4s

		mov ah,13h
		mov al,00h
		xor bx,bx
		mov es,bx
		mov bl,BLACK
		mov bp,inst_c
		mov cx,26
		mov dh,21
		mov dl,7
		int 10h

		push 50
		push 160
		push 270
		push 162
		push BLACK
		call rectangle
		add sp,10
		push 50
		push 180
		push 270
		push 182
		push BLACK
		call rectangle
		add sp,10
		push 50
		push 162
		push 52
		push 180
		push BLACK
		call rectangle
		add sp,10
		push 268
		push 162
		push 270
		push 180
		push BLACK
		call rectangle
		add sp,10

		mov cx,0x0005
		mov dx,0xb8d8
		mov ah,86h
		int 15h		; wait 3/8s

		mov ah, 01h
		int 16h			; Toma el estado del buffer del teclado
		jz main.main_loop	; Si no se presiona ninguna tecla, volver a fijarse
					; Si se presiono alguna:
		xor ax,ax
		int 16h			; Esto nos dice que tecla fue presionada

		cmp al,'c'		; 'c' para comenzar
		jne main.main_loop




nivel1:
	


	call print_background


	.main_loop:
		mov ah, 01h
		int 16h			; Toma el estado del buffer del teclado
		jz nivel1.main_loop	; Si no se presiona ninguna tecla, volver a fijarse
					; Si se presiono alguna:
		xor ax,ax
		int 16h			; Esto nos dice que tecla fue presionada

		cmp al,'a'		; 'a' para aumentar el angulo
		je nivel1.a
		cmp al,'d'		; 'd' para achicar el angulo
		je nivel1.d
		cmp al,'-'		; '-' para disminuir el modulo
		je nivel1.menos
		cmp al,'m'		; 'm' para disminuir el modulo
		je nivel1.menos
		cmp al,'+'		; '+' para aumentar el modulo
		je nivel1.mas
		cmp al,'p'		; 'p' para aumentar el modulo
		je nivel1.mas
		cmp al,' '		; ' ' para efectuar el tiro
		je nivel1.esp

		jmp nivel1.main_loop ; Si no fue ninguna de las anteriores, volver a leer una tecla

	.a:
		mov bx,[origin_x]
		add bx,[x_inc]
		cmp bx,[vx]		; origin_x + x_inc > vx ?
		jg nivel1.main_loop

		call erase_arrow

		mov bx,[vx]
		sub bx,[x_inc]		; bx = x - x_inc
		mov [vx],bx		; x = x - x_inc

		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = isqrt(cx)
		mov bx,[origin_y]
		sub bx,dx		; bx = origin_y - isqrt(cx)
		mov [vy],bx		; y = origin_y - sqrt(arrow_length^2 - (x - origin_x)^2)

		call print_arrow
		mov bx,[origin_x]
		push bx
		mov bx,[origin_y]
		push bx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel1.main_loop

	.d:
		mov bx,[vy]
		cmp bx,[origin_y]	; vy < origin_y ?
		jge nivel1.main_loop

		call erase_arrow

		mov bx,[vx]
		add bx,[x_inc]
		mov [vx],bx		; x = x + x_inc

		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = sqrt(cx)
		mov bx,[origin_y]
		sub bx,dx
		mov [vy],bx		; y = origin_y - sqrt(arrow_length^2 - (x - origin_x)^2)

		call print_arrow
		mov bx,[origin_x]
		push bx
		mov bx,[origin_y]
		push bx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel1.main_loop

	.mas:
		mov bx,[arrow_length]
		add bx,[arrow_inc]
		cmp bx,[arrow_max]
		jg nivel1.main_loop

		call erase_arrow

		; x = x + (x-origin_x)*arrow_inc/arrow_length
		mov bx,[vx]		; bx = x
		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,[arrow_inc]	; bx = (x - origin_x)*arrow_inc
		push bx
		mov bx,[arrow_length]
		push bx
		call intdiv
		add sp,4
		mov bx,dx		; bx = (x - origin_x)*arrow_inc/arrow_length
		add bx,[vx]		; bx = x + (x - origin_x)*arrow_inc/arrow_length
		mov [vx],bx

		mov bx,[arrow_length]
		add bx,[arrow_inc]
		mov [arrow_length],bx	; arrow_length = arrow_length + arrow_inc

		mov bx,[vx]		; bx = x
		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = sqrt(cx)
		mov bx,[origin_y]
		sub bx,dx		; bx = origin_y - sqrt(cx)
		mov [vy],bx

		call print_arrow
		mov bx,[origin_x]
		push bx
		mov bx,[origin_y]
		push bx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel1.main_loop

	.menos:
		mov bx,[arrow_length]
		sub bx,[arrow_inc]
		cmp bx,[arrow_min]
		jl nivel1.main_loop

		call erase_arrow

		; x = x - (x-origin_x)*arrow_inc/arrow_length
		mov bx,[vx]
		sub bx,[origin_x]
		imul bx,[arrow_inc]
		push bx
		mov bx,[arrow_length]
		push bx
		call intdiv
		add sp,4
		mov bx,dx
		imul bx,-1
		add bx,[vx]
		mov [vx],bx

		mov bx,[arrow_length]
		sub bx,[arrow_inc]
		mov [arrow_length],bx	; arrow_length = arrow_length - arrow_inc

		mov bx,[vx]		; bx = x
		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = sqrt(cx)
		mov bx,[origin_y]
		sub bx,dx		; bx = origin_y - sqrt(cx)
		mov [vy],bx


		call print_arrow
		mov dx,[origin_x]
		push dx
		mov dx,[origin_y]
		push dx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel1.main_loop


	.esp:
		mov cx,[vx]
		push cx
		mov cx,[vy]
		push cx
		call throw_ball
		add sp,4

		cmp dx,0
		je nivel1


mov [vx], word 75
mov [vy], word 150
mov [arrow_length], word 50

nivel2:
	call print_background


	.main_loop:
		call erase_basket
		mov bx,[nivel2_i]
		add bx,[nivel2_s]
		mov [nivel2_i],bx		; i = i + s
		mov cx,[basket_center_x_original]
		sub cx,bx
		mov [basket_center_x],cx	; basket_center_x = basket_center_x_original - i
		cmp bx,0
		jg nivel2.i_not_0
		mov bx,[nivel2_s]
		imul bx,-1
		mov [nivel2_s],bx
		jmp nivel2.out_basket_moving
		.i_not_0:
		cmp bx,100
		jl nivel2.out_basket_moving
		mov bx,[nivel2_s]
		imul bx,-1
		mov [nivel2_s],bx

		.out_basket_moving:
		call print_basket
		mov cx,0x0001
		mov dx,0xe848
		mov ah,86h
		int 15h		; wait 1/8s

		mov ah, 01h
		int 16h			; Toma el estado del buffer del teclado
		jz nivel2.main_loop	; Si no se presiona ninguna tecla, volver a fijarse
					; Si se presiono alguna:
		xor ax,ax
		int 16h			; Esto nos dice que tecla fue presionada

		cmp al,'a'		; 'a' para aumentar el angulo
		je nivel2.a
		cmp al,'d'		; 'd' para achicar el angulo
		je nivel2.d
		cmp al,'-'		; '-' para disminuir el modulo
		je nivel2.menos
		cmp al,'m'		; 'm' para disminuir el modulo
		je nivel2.menos
		cmp al,'+'		; '+' para aumentar el modulo
		je nivel2.mas
		cmp al,'p'		; 'p' para aumentar el modulo
		je nivel2.mas
		cmp al,' '		; ' ' para efectuar el tiro
		je nivel2.esp

		jmp nivel2.main_loop ; Si no fue ninguna de las anteriores, volver a leer una tecla

	.a:
		mov bx,[origin_x]
		add bx,[x_inc]
		cmp bx,[vx]		; origin_x + x_inc > vx ?
		jg nivel2.main_loop

		call erase_arrow

		mov bx,[vx]
		sub bx,[x_inc]		; bx = x - x_inc
		mov [vx],bx		; x = x - x_inc

		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = isqrt(cx)
		mov bx,[origin_y]
		sub bx,dx		; bx = origin_y - isqrt(cx)
		mov [vy],bx		; y = origin_y - sqrt(arrow_length^2 - (x - origin_x)^2)

		call print_arrow
		mov bx,[origin_x]
		push bx
		mov bx,[origin_y]
		push bx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel2.main_loop

	.d:
		mov bx,[vy]
		cmp bx,[origin_y]	; vy < origin_y ?
		jge nivel2.main_loop

		call erase_arrow

		mov bx,[vx]
		add bx,[x_inc]
		mov [vx],bx		; x = x + x_inc

		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = sqrt(cx)
		mov bx,[origin_y]
		sub bx,dx
		mov [vy],bx		; y = origin_y - sqrt(arrow_length^2 - (x - origin_x)^2)

		call print_arrow
		mov bx,[origin_x]
		push bx
		mov bx,[origin_y]
		push bx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel2.main_loop

	.mas:
		mov bx,[arrow_length]
		add bx,[arrow_inc]
		cmp bx,[arrow_max]
		jg nivel2.main_loop

		call erase_arrow

		; x = x + (x-origin_x)*arrow_inc/arrow_length
		mov bx,[vx]		; bx = x
		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,[arrow_inc]	; bx = (x - origin_x)*arrow_inc
		push bx
		mov bx,[arrow_length]
		push bx
		call intdiv
		add sp,4
		mov bx,dx		; bx = (x - origin_x)*arrow_inc/arrow_length
		add bx,[vx]		; bx = x + (x - origin_x)*arrow_inc/arrow_length
		mov [vx],bx

		mov bx,[arrow_length]
		add bx,[arrow_inc]
		mov [arrow_length],bx	; arrow_length = arrow_length + arrow_inc

		mov bx,[vx]		; bx = x
		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = sqrt(cx)
		mov bx,[origin_y]
		sub bx,dx		; bx = origin_y - sqrt(cx)
		mov [vy],bx

		call print_arrow
		mov bx,[origin_x]
		push bx
		mov bx,[origin_y]
		push bx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel2.main_loop

	.menos:
		mov bx,[arrow_length]
		sub bx,[arrow_inc]
		cmp bx,[arrow_min]
		jl nivel2.main_loop

		call erase_arrow

		; x = x - (x-origin_x)*arrow_inc/arrow_length
		mov bx,[vx]
		sub bx,[origin_x]
		imul bx,[arrow_inc]
		push bx
		mov bx,[arrow_length]
		push bx
		call intdiv
		add sp,4
		mov bx,dx
		imul bx,-1
		add bx,[vx]
		mov [vx],bx

		mov bx,[arrow_length]
		sub bx,[arrow_inc]
		mov [arrow_length],bx	; arrow_length = arrow_length - arrow_inc

		mov bx,[vx]		; bx = x
		sub bx,[origin_x]	; bx = x - origin_x
		imul bx,bx		; bx = (x - origin_x)^2
		mov cx,[arrow_length]
		imul cx,cx		; cx = arrow_length^2
		sub cx,bx		; cx = arrow_length^2 - (x - origin_x)^2
		push cx
		call isqrt
		add sp,2		; dx = sqrt(cx)
		mov bx,[origin_y]
		sub bx,dx		; bx = origin_y - sqrt(cx)
		mov [vy],bx


		call print_arrow
		mov dx,[origin_x]
		push dx
		mov dx,[origin_y]
		push dx
		call print_ball
		add sp,4		; print_ball(origin_x,origin_y)

		jmp nivel2.main_loop


	.esp:
		mov cx,[vx]
		push cx
		mov cx,[vy]
		push cx
		call throw_ball
		add sp,4

		cmp dx,0
		je nivel2


despedida:
	push 0
	push 0
	push 319
	push 199
	push BLACK
	call rectangle
	add sp,10

	mov ah,13h
	mov al,00h
	xor bx,bx
	mov es,bx
	mov bl,WHITE
	mov bp,chau_l1
	mov cx,13
	mov dh,10
	mov dl,13
	int 10h


	push 159
	push 120
	call print_ball
	add sp,4

	mov cx,0x001e
	mov dx,0x8480
	mov ah,86h
	int 15h		; wait 2s

; Apagar sistema
mov ax,5307h
mov cx,0003h
xor bx,bx
inc bx	; bx = 0001h
int 15h

; Si por alguna razon no se apago:

mov ah,13h
mov al,00h
xor bx,bx
mov es,bx
mov bl,WHITE
mov bp,chau_l2
mov cx,31
mov dh,1
mov dl,5
int 10h

halt:
jmp halt




							; Longitud:
titulo	db "Basketball"					; 10
autor	db "por Carolina Lucia Gonzalez"		; 27
inst_l1	db "Instrucciones:"				; 14
inst_l2	db "*  'a' y 'd' para ajustar el angulo"	; 35
inst_l3	db "*  '+' y '-' para ajustar el modulo"	; 35
inst_li	db "(o 'p' y 'm')"				; 13
inst_l4	db "*  barra espaciadora para tirar"		; 31
inst_c	db "Presione 'c' para comenzar"			; 26
won_ms	db "GANASTE :)"					; 10
lost_ms	db "PERDISTE :("				; 11
chau_l1	db "Fin del juego"				; 13
chau_l2	db "(Apague manualmente la maquina)"		; 31


vx dw 75
vy dw 150

x_inc dw 1

inicio dw 20

wall_color db BLUE
floor_color db GREEN

origin_x dw 25
origin_y dw 150

ball_radius dw 10
ball_color db LRED

floor_level dw 161

arrow_color db WHITE
arrow_length_original dw 50
arrow_length dw 50
arrow_inc dw 2
arrow_max dw 65
arrow_min dw 50

basket_center_x_original dw 250
basket_center_x dw 250
basket_circle_top_y dw 50
basket_web_top_y dw 53
basket_radius dw 20
basket_length dw 40
basket_circle_color db RED
basket_web_color db WHITE

nivel2_i dw 0
nivel2_s dw 1


times 5632-($-$$) db 0

