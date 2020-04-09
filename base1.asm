IDEAL
MODEL small
STACK 100h
DATASEG
; --------------------------

	trash4 dd 1234abcdh,0abcdefh,1a2b3c4dh,1e2f3a4ch,12a23bffh,92ce2h,1763ah,4def36adh,5436adh
	trash3 dd 123456a8h,665b65c7h,5abc34fh,912f98h,10ff76h,0a42156h,3ab146h,92ce2h,1763ah,4def36adh
	trash2 dd 12345678h,66546547,5abcdefh,912998h,103376h,432156h,323146h,92212h,1763ah,5436adh
	trash dd 123456a8h,665b65c7h,5abc34fh,912f98h,10ff76h,0a42156h,3ab146h,92ce2h,1763ah,4def36adh
	trash1 dd 12345678h,66546547,5abcdefh,912998h,103376h,432156h,323146h,92212h,1763ah,5436adh
	tens db ?
	ten db 10
	units db ?
	tendiv db 10
	;print1 db ?
	;print2 db ?
	openingMsg db "welcome to the pig game!$"
	instructions db 10,13,10,13,"The rules are Simple:",10,13,10,13
		db  "Your goal is to reach 100 Points!",10,13,10,13
		db "type SPACE to roll the dice",10,13,10,13
		db "and ENTER to save your points to ",10,13,10,13,10,13
		db "the total amount and your turn will end",10,13,10,13
		db "be careful because if you get 1 ",10,13,10,13
		db "your current points will be earsed",10,13,10,13
		db " and your turn will end!",10,13,10,13,10,13
		db "       to continue type SPACE",'$'
	
	totalSquare db '   ',201,205,205,205,205,205,205,205,187, '              ',201,205,205,205,205,205,205,205,187  ,10,13
		db '   ',186,' ',84,79,84,65,76,' ',186,'              ',186,' ',84,79,84,65,76,' ',186,10,13
		db '   ',186,'       ',186,'              ',186,'       ',186,10,13
		db '   ',186,'       ',186,'              ',186,'       ',186,10,13
		db '   ',186,'       ',186,'              ',186,'       ',186,10,13
		db '   ',200,205,205,205,205,205,205,205,188,'              ',200,205,205,205,205,205,205,205,188,'$' 

	currentSquare 	db '   ',201,205,205,205,205,205,205,205,187,'              ',201,205,205,205,205,205,205,205,187,10,13
		db '   ',186,67,85,82,82,69,78,84,186,'              ',186,67,85,82,82,69,78,84,186,10,13
		db '   ',186,'       ',186,'              ',186,'       ',186,10,13
		db '   ',186,'       ',186,'              ',186,'       ',186,10,13
		db '   ',186,'       ',186,'              ',186,'       ',186,10,13
		db '   ',200,205,205,205,205,205,205,205,188,'              ',200,205,205,205,205,205,205,205,188,10,13,'$'
	
	mainDice db ?
	dice1 db ?
	dice2 db ?
	;currentMain db 0
	current1 db 0
	current2 db 0
	total1 db 0
	total2 db 0
	color dw 3
	x_coordinate dw ?
	y_coordinate dw ?
	x1_coordinate dw 26
	y1_coordinate dw 20
	x2_coordinate dw 210
	y2_coordinate dw 20
	temp_x dw ?
	temp_y dw ?
	len_col dw 69
	len_row dw 5
	temp_col dw ?
	temp_row dw ?
	;returnaddres dw ?
	;returnaddres1 dw ?
	tempNum db ?
	number db ?
	note dw 1715
	fail_note dw 8609 
	countSound db 3
	time db ?
	victorynote1 dw 1140
	victorynote2 dw 1207
	victorynote3 dw 1355
	help db 0
	
	filename db 'img.bmp',0
	filename1 db 'pig.bmp',0
	filehandle dw ?
	Header db 54 dup (0)
	Palette db 256*4 dup (0)
	ScrLine db 320 dup (0)
	ErrorMsg db 'Error', 13, 10 ,'$'
	winner_msg1 db 'Player 1 is the Winner!$'
	winner_msg2 db 'Player 2 is the Winner!$'

; --------------------------

CODESEG
;opening picture procs
proc OpenFile
; Open file
mov ah, 3Dh
xor al, al
mov dx, offset filename
int 21h
jc openerror
mov [filehandle], ax
ret
openerror :
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
ret
endp OpenFile

proc OpenFile1
; Open file
mov ah, 3Dh
xor al, al
mov dx, offset filename1
int 21h
jc openerror1
mov [filehandle], ax
ret
openerror1 :
mov dx, offset ErrorMsg
mov ah, 9h
int 21h
ret
endp OpenFile1
proc ReadHeader
; Read BMP file header, 54 bytes
mov ah,3fh
mov bx, [filehandle]
mov cx,54
mov dx,offset Header
int 21h
ret
endp ReadHeader
proc ReadPalette
; Read BMP file color palette, 256 colors * 4 bytes (400h)
mov ah,3fh
mov cx,400h
mov dx,offset Palette
int 21h
ret
endp ReadPalette

proc CopyPal
; Copy the colors palette to the video memory
; The number of the first color should be sent to port 3C8h
; The palette is sent to port 3C9h
mov si,offset Palette
mov cx,256
mov dx,3C8h
mov al,0
; Copy starting color to port 3C8h
out dx,al
; Copy palette itself to port 3C9h
inc dx
PalLoop:
; Note: Colors in a BMP file are saved as BGR values rather than RGB .
mov al,[si+2] ; Get red value .
shr al,2 ; Max. is 255, but video palette maximal
; value is 63. Therefore dividing by 4.
out dx,al ; Send it .
mov al,[si+1] ; Get green value .
shr al,2
out dx,al ; Send it .
mov al,[si] ; Get blue value .
shr al,2
out dx,al ; Send it .
add si,4 ; Point to next color .
; (There is a null chr. after every color.)
loop PalLoop
ret
endp CopyPal

proc CopyBitmap
; BMP graphics are saved upside-down .
; Read the graphic line by line (200 lines in VGA format),
; displaying the lines from bottom to top.
mov ax, 0A000h
mov es, ax
mov cx,200
PrintBMPLoop :
push cx
; di = cx*320, point to the correct screen line
mov di,cx
shl cx,6
shl di,8
add di,cx
; Read one line
mov ah,3fh
mov cx,320
mov dx,offset ScrLine
int 21h
; Copy one line into video memory
cld ; Clear direction flag, for movsb
mov cx,320
mov si,offset ScrLine
rep movsb ; Copy line to the screen
 ;rep movsb is same as the following code :
 ;mov es:di, ds:si
 ;inc si
 ;inc di
 ;dec cx
 ;loop until cx=0
pop cx
loop PrintBMPLoop
ret
endp CopyBitmap
proc openPic
push ax
	call OpenFile
call ReadHeader
call ReadPalette
call CopyPal
call CopyBitmap
; Wait for key press

mov ah,0
int 16h
; Back to text mode
;mov ah, 0
;mov al, 2
;int 10h

pop dx
ret
endp openPic
proc openPig
push ax
	mov ax, 13h
	int 10h
	call OpenFile1
	call ReadHeader
	call ReadPalette
	call CopyPal
	call CopyBitmap
; Wait for key press
	mov ah,1
	int 21h
; Back to text mode
	mov ah, 0
	mov al, 2
	int 10h
	mov ax, 13h
	int 10h
pop ax
ret
endp openPig
;end opening picture procs
proc makeSound; צליל שלוחצים על המקלדת
	push ax
	
	check_oneSecond:
	in al, 61h
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h
	out 43h, al
	
	mov ah, 2ch 
	int 21h
	mov [time], dl
	
	mov ax, [note]
	out 42h, al
	mov al, ah
	out 42h,al

	mov ah, 2ch 
	int 21h
	cmp [time], dl
	je check_oneSecond
	in al, 61h
	and al, 11111100b
	out 61h, al
	
	
	pop ax
	ret
	endp makeSound
proc failSound ; sound when you roll the dice and get 1
	push ax
	mov [countSound],3
	start_failSound:
	failS_check_oneSecond:
	in al, 61h
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h
	out 43h, al
	
	mov ah, 2ch 
	int 21h
	mov [time], dl
	
	mov ax, [fail_note]
	out 42h, al
	mov al, ah
	out 42h,al

	mov ah, 2ch 
	int 21h
	cmp [time], dl
	je failS_check_oneSecond
	in al, 61h
	and al, 11111100b
	out 61h, al
	dec [countSound]
	cmp [countSound],0
	jne start_failSound
	
	
	
	pop ax
	ret

endp failSound
 proc victoryA
 push ax
	
	VAcheck_oneSecond:
	in al, 61h
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h
	out 43h, al
	
	mov ah, 2ch 
	int 21h
	mov [time], dl
	
	mov ax, [victorynote1]
	out 42h, al
	mov al, ah
	out 42h,al

	mov ah, 2ch 
	int 21h
	cmp [time], dl
	je VAcheck_oneSecond
	in al, 61h
	and al, 11111100b
	out 61h, al
	
	
	pop ax
 ret
 endp victoryA
 proc victoryB
 push ax
	
	VBcheck_oneSecond:
	in al, 61h
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h
	out 43h, al
	
	mov ah, 2ch 
	int 21h
	mov [time], dl
	
	mov ax, [victorynote2]
	out 42h, al
	mov al, ah
	out 42h,al

	mov ah, 2ch 
	int 21h
	cmp [time], dl
	je VBcheck_oneSecond
	in al, 61h
	and al, 11111100b
	out 61h, al
	
	
	pop ax
 ret
 endp victoryB
 proc victoryC
 push ax
	
	VCcheck_oneSecond:
	in al, 61h
	or al, 00000011b
	out 61h, al
	
	mov al, 0B6h
	out 43h, al
	
	mov ah, 2ch 
	int 21h
	mov [time], dl
	
	mov ax, [victorynote3]
	out 42h, al
	mov al, ah
	out 42h,al

	mov ah, 2ch 
	int 21h
	cmp [time], dl
	je VCcheck_oneSecond
	in al, 61h
	and al, 11111100b
	out 61h, al
	
	
	pop ax
 ret
 endp victoryC
 proc victorySound
 call victoryA
 call victoryB
 call victoryC
 call makeSound
 call makeSound
 call victoryB
 call victoryA
 call makeSound
 call victoryC
 call victoryC
 ret
 endp victorySound
proc Print
	push dx
	push ax
	mov bh, 0 ; page number
	mov ah, 2
	int 10h
	
	mov al, [number]
	mov ah, 0
	div [ten]
	
	add ah, '0'
	add al, '0'
	
	mov dx, ax
	mov ah, 2h
	int 21h
	
	mov dl, dh
	mov ah, 2h
	int 21h
	
	
	pop ax
	pop dx
	ret
endp Print

proc Enterline
	push cx
	enters:
	MOV dl, 0ah
	MOV ah, 02h
	INT 21h
	loop enters
	pop cx
ret
endp Enterline
;which player's turn
proc player1Turn_sign
push bx
mov [color], 3
mov bx, [x1_coordinate]
mov [x_coordinate],bx
mov bx, [y1_coordinate]
mov [y_coordinate],bx
call drawSqure
pop bx
ret
endp player1Turn_sign
proc player2Turn_sign
push bx
mov [color],3
mov bx, [x2_coordinate]
mov [x_coordinate],bx
mov bx, [y2_coordinate]
mov [y_coordinate],bx
call drawSqure
pop bx
ret
endp player2Turn_sign
proc drawSqure
	push ax
	push bx
	push cx
	push dx
	;trasfer to temp
	mov bx, [x_coordinate]
	mov [temp_x], bx
	mov bx, [y_coordinate]
	mov [temp_y], bx
	mov bx, [len_col]
	mov [temp_col],bx
	mov bx, [len_row]
	mov [temp_row],bx
	;end transfer
	squre:
	;restart the len_col so it will create a new line
	mov bx, [len_col]
	mov [temp_col],bx
	call drawLine
	;new line
	dec [temp_y]
	;back to the start of the row
	mov bx, [x_coordinate]
	mov [temp_x], bx
	;the amount of rows
	dec [len_row]
	cmp [len_row],0
	jne squre
	pop dx
	pop cx
	pop bx
	pop ax
	

	ret
endp drawSqure
proc drawLine
push bx
push ax
push cx
push dx
Line:	
	xor bh, bh
	mov cx, [temp_x]
	mov dx, [temp_y]
	mov ax, [color]
	mov ah, 0ch
	int 10h
	inc [temp_x]
	dec [temp_col]
	cmp [temp_col], 0
	jne Line
	pop dx
	pop cx
	pop ax
	pop bx
ret
endp drawLine





 ;which player's turn end
 ;throw dice
proc throwDice
	push ax
	push bx
random:
	
	mov ah, 2ch 
	int 21h
	mov ax, 40h
	mov es, ax
	mov ax, [es:6Ch]
	xor ax, [si]
	inc si
	shr ax, 13
	cmp ax,7
	je random
	cmp ax,0
	je random
	mov [word ptr mainDice], ax
	call printDice
	pop bx
	pop ax
	ret
endp throwDice
;throw dice end
;print dice
proc printDice
	push ax
	push bx
	push dx
	
	mov dl,18
	mov dh,4
	mov  bh, 0    ;Display page		
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov al,[mainDice]
	mov ah, 0
	div  [ten]	
	add  ax, '00'		
	mov dx, ax
	mov ah, 2h
	int 21h 
	mov dl, dh
	int 21h
	
	pop dx
	pop bx
	pop ax
	ret
endp printDice
proc printCurrent1
	push bx
	push ax
	push dx
	mov bx,[word ptr mainDice]
	mov [word ptr dice1],bx
	mov ax,[word ptr dice1]
	add [word ptr current1],ax
	mov bx, [word ptr current1]
	mov [word ptr number], bx
	mov dh,13
	mov dl,7
	call print
	pop dx
	pop ax
	pop bx
ret
endp printCurrent1
proc printCurrent2
	push bx
	push ax
	push dx
	mov bx,[word ptr mainDice]
	mov [word ptr dice2],bx
	mov ax,[word ptr dice2]
	add [word ptr current2],ax
	mov bx, [word ptr current2]
	mov [word ptr number], bx
	mov dh,13
	mov dl,30
	call Print
	pop dx
	pop ax
	pop bx
ret
endp printCurrent2
proc restartCurrent1
	push bx 
	push dx
	mov [current1],0
	mov bx, [word ptr current1]
	mov [word ptr number], bx
	mov dh,13
	mov dl,7
	call print
	pop dx
	pop bx
ret
endp restartCurrent1
proc restartCurrent2
	push bx
	push dx
	mov [current2],0
	mov bx, [word ptr current2]
	mov [word ptr number], bx
	mov dh,13
	mov dl,30
	call print
	pop dx
	pop bx
ret
endp restartCurrent2
proc savePlayer1
	push ax
	push bx
	push dx
	
	mov ax,[word ptr current1]
	add [word ptr total1],ax
	mov bx, [word ptr total1]
	mov [word ptr number], bx
	mov dh,7
	mov dl,7
	call print
	mov [current1],0
	mov bx, [word ptr current1]
	mov [word ptr number], bx
	mov dh,13
	mov dl,7
	call print
	pop dx
	pop bx
	pop ax

	ret 
endp savePlayer1
proc savePlayer2
	push ax
	push bx
	push dx
	mov ax,[word ptr current2]
	add [word ptr total2],ax
	mov bx, [word ptr total2]
	mov [word ptr number], bx
	mov dh,7
	mov dl,30
	call Print
	mov [current2],0
	mov bx, [word ptr current2]
	mov [word ptr number], bx
	mov dh,13
	mov dl,30
	call print
	pop dx
	pop bx
	pop ax
ret
endp savePlayer2
proc winner
	push ax
	push bx
	push dx
	
	mov al, 2
	int 10h
	mov ax, 13h
	int 10h
	call victorySound
	;clearing the screen
	cmp [total1],100
	jge player1Win
	mov dl,7
	mov dh,3
	mov  bh, 0    ;Display page		
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov dx, offset winner_msg2
	mov  ah, 9h
	int  21h
	jmp finishAnnouncement
	player1Win:
	mov dl,7
	mov dh,3
	mov  bh, 0    ;Display page		
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov dx, offset winner_msg1
	mov  ah, 9h
	int  21h
	finishAnnouncement:
	mov ah,1
	int 21h
	call openPic
	pop dx
	pop bx
	pop cx;In order to not lose al
	
ret
endp winner
proc manageGame
	push ax
	push bx
	push cx
	push dx
	mov dl,7
	mov dh,3
	mov  bh, 0    ;Display page		
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	;print messages
	mov dx, offset openingMsg
	mov  ah, 9h
	int  21h
	mov cx,2
	call Enterline
	mov dx, offset instructions
	mov  ah, 9h
	int  21h
	;end print messages
	;check if type space
	check:
	mov ah, 0h
	int 16h
	cmp al, 32
	jne check
	;earse everything
	mov ax,2
	int 10h
	mov ax, 13h
	int 10h
	;print BG
	mov  dh, 4 ; שורה
	mov  dl, 0 ; טור
	mov  bh, 0    ;Display page		
	mov  ah, 02h  ;SetCursorPosition
	int  10h
	mov dx, offset totalSquare
	mov ah,9h
	int 21h
	;total
	mov dl,0
	mov dh,10
	mov  bh, 0    ;Display page		
	mov  ah, 02h  ;SetCursorPosition
	int  10h	
	mov dx, offset currentSquare
	mov ah,9h
	int 21h
	;print the basic ones
	mov [current1],0
	mov [current2],0
	mov [total1],0
	mov [total2],0
	mov dh,13
	mov dl,7
	mov bx,[word ptr current1]
	mov [word ptr number], bx
	call print
	mov dh,13
	mov dl,30
	mov bx,[word ptr current2]
	mov [word ptr number], bx
	call print
	mov dh,7
	mov dl,7
	mov bx,[word ptr total1]
	mov [word ptr number], bx
	call print
	mov dh,7
	mov dl,30
	mov bx,[word ptr total2]
	mov [word ptr number], bx
	call print
	
	pop dx
	pop cx
	pop bx
	pop ax
	
ret
endp manageGame

start:
	mov ax, @data
	mov ds, ax
; --------------------------
startGame:
	;mov ax, 13h
	;int 10h
	call openPig
	mov [help],0
	xor si,si
	;instructions and print base BG
	call manageGame
	
	player1_Turn:
	;call player1Turn_sign
	call restartCurrent2
	checkRoll1:
	mov ah, 0h
	int 16h
	call makeSound
	cmp al,13
	jne notSave
	call savePlayer1
	jmp EndTurn1
	;save current to total + end turn
	notSave:
	cmp al, 32
	jne checkRoll1
	call throwDice
	
	cmp [mainDice],1
	jne sameTurn1
	call failSound
	jmp player2_Turn
	sameTurn1:
	cmp [help],6
	je start
	call printCurrent1
	EndTurn1:
	cmp [total1],100
	jge ending
	;if player1 wins 
	;else- player2 turn
	cmp [current1],0
	jne player1_Turn
	jmp player2_Turn
	
	player2_Turn:
	;call player2Turn_sign
	call restartCurrent1
	checkRoll2:
	mov ah, 0h
	int 16h
	call makeSound
	cmp al,13
	jne notSave1
	call savePlayer2
	jmp EndTurn2
	notSave1:
	cmp al, 32
	jne checkRoll2
	call throwDice
	cmp [mainDice],1
	jne sameTurn2
	call failSound
	jmp player1_Turn
	sameTurn2:
	call printCurrent2
	
	EndTurn2:
	cmp [total2],100
	jge ending
	cmp [current2],0
	jne player2_Turn
	je player1_Turn
	
	
	ending:
	call winner
	call makeSound
	cmp al, 114
	jne theEnd
	mov [help],6
	jmp sameTurn1
	theEnd:
; --------------------------

exit:
	mov ax, 4c00h
	int 21h
END start


