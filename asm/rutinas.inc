; ==========================
; === Tablas 7 segmentos ===
; ====== Anodo ComÃºn =======
; ==========================
TABLA_7SEG:
    ADDWF   PCL, F
    RETLW   0xC0    ; 0
    RETLW   0xF9    ; 1
    RETLW   0xA4    ; 2
    RETLW   0xB0    ; 3
    RETLW   0x99    ; 4 10011001
    RETLW   0x92    ; 5
    RETLW   0x82    ; 6
    RETLW   0xF8    ; 7
    RETLW   0x80    ; 8
    RETLW   0x90    ; 9

; ==========================
; = Tabla de teclas Keypad =
; ==========================
TECLAS:
    ADDWF PCL, F
    RETLW D'7'     ; 7
    RETLW D'8'     ; 8
    RETLW D'9'     ; 9
    RETLW 0x10     ; OPTIONS
    RETLW D'4'     ; 4
    RETLW D'5'     ; 5
    RETLW D'6'     ; 6
    RETLW 0x20     ; ONNOFF
    RETLW D'1'     ; 1
    RETLW D'2'     ; 2
    RETLW D'3'     ; 3
    RETLW 0x40     ; SIGDIGITO
    RETLW 0x20     ; 12
    RETLW D'0'     ; 13
    RETLW 0x20     ; 14
    RETLW 0x20     ; 15
;--- Rutinas para el proyecto ---

; ============================
; == Rutina de multiplexado ==
; ============================
MOSTRAR_DISPLAY:
    CALL    DISPLAY_DECENAS
    CALL    DISPLAY_UNIDADES
    CALL    DISPLAY_DECIMAS
    RETURN
DISPLAY_DECENAS:
    MOVF    decenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD

    ; Activar RA5 (decenas)
    MOVLW   b'00000110'
    MOVWF   PORTE
    CALL    RETARDO            
    MOVLW   b'00000111'
    MOVWF   PORTE          
    RETURN
    
DISPLAY_UNIDADES:
    MOVF    unidades, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    BSF	    PORTD, 7            ; Punto decimal

    ; Activar RA6 (unidades)
    MOVLW   b'00000101'
    MOVWF   PORTE
    CALL    RETARDO            
    MOVLW   b'00000111'
    MOVWF   PORTE          
    RETURN

DISPLAY_DECIMAS:
    MOVF    decimas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD

    ; Activar RA7 (decimas)
    MOVLW   b'00000011'
    MOVWF   PORTE
    CALL    RETARDO            
    MOVLW   b'00000111'
    MOVWF   PORTE          
    RETURN

; =============================
; == Rutina de retardo 16 ms ==
; =============================
RETARDO:
    BANK0
    CLRF TMR0               ; Limpiar TMR0
    BCF INTCON,TMR0IF       ; Limpia el flag de interrupción TMR0
LOOP_RETARDO:
    BTFSS INTCON, TMR0IF    ; Espera a que TMR0 se desborde
    GOTO LOOP_RETARDO       ; Si no se desbordó, espera
    RETURN

; ============================
; = Rutina de retardo 200 ms =
; ============================
RETARDO_200ms:
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    RETURN
    
; ============================
; =========== ADC ============
; ============================
ADC:
    BANK0

    ; Prueba de conversión ADC
    MOVLW   b'00000000'
    MOVWF   ADRESH
    BANK1
    MOVLW   b'00000000'
    MOVWF   ADRESL
    
    ; Leer ADRESH (banco 0)
    BANK0
    MOVF    ADRESH, W
    MOVWF   temp16H

    ; Leer ADRESL (banco 1)
    BANK1
    MOVF    ADRESL, W
    BANK0
    MOVWF   temp16L

    ; Actualiza decenas, unidades y decimas
    CALL    SEPARAR_3DIGITOS

    ; Iniciar nueva conversión ADC
    BSF     ADCON0, GO

    RETURN

; ==============================
; === Control de temperatura ===
; ==============================
CONTROL:
; Testeo la parte Alta
    BANK0
    MOVF    TCH, W
    SUBWF   ADRESH, 0
    BTFSC   STATUS, Z           ; Si dio 0, chequeo la parte baja
    GOTO    CONTROLB
    BTFSS   STATUS, C           ; Si me pase de temperatura, apago la pava
    TURNOFF 
    RETURN

; Testeo la parte Baja
CONTROLB:                       
    MOVF    TCL, W
    SUBWF   ADRESL, 0
    BTFSC   STATUS, Z           ; Si dio 0, apago la pava
    TURNOFF  
    BTFSS   STATUS, C           ; Si me pase de temperatura, apago la pava
    TURNOFF  
    RETURN

; ============================
; === Escaneo de teclado ===
; ============================
LOOP_KEYPAD:                        ; hay alguna tecla presionada?
    CALL    MOSTRAR_DISPLAY         ; Mostrar los digitos en el display
    CALL    RETARDO_200ms

	MOVLW   0xF0	                ; Pongo 1 todas las filas
	MOVWF   PORTB	    
	MOVF    PORTB, W	            ; Testeo columnas
    ANDLW   0x0F                    ; Enmascarar columnas
    BTFSC   STATUS, Z
	GOTO    LOOP_KEYPAD	            ; No hay teclas presionadas -> vuelvo al loop
	; Si -> Antirebote
	CALL    RETARDO
	MOVF    PORTB, W	     
    ANDLW   0x0F                    ; Enmascarar columnas
    BTFSC   STATUS, Z
	GOTO    LOOP_KEYPAD	            ; No hay teclas presionadas -> vuelvo al loop
	; Si -> Escanear las teclas
	CALL    ESCANEAR_TECLAS
    RETURN

ESCANEAR_TECLAS:
	CLRF    ROW
	MOVLW   B'10000000'             ; Pongo fila 1 en alto
	MOVWF   ROWMASK

ESCANEAR_COL:		                ; Detectar columna
	CLRF    INDICE
	MOVF    ROWMASK, W
	MOVWF   PORTB
    CALL    RETARDO

    BTFSC   PORTB, 3	            ; Columna 1 (RB3) en alto?
    GOTO    OFFSET_ROW	            ; si -> offset = 0
	INCF    INDICE, 1	                ; no -> Indice += 4, y sigo
    
	BTFSC   PORTB, 2	            ; Columna 2 (RB2) en alto?
    GOTO    OFFSET_ROW	            ; si -> offset = 4
	INCF    INDICE, 1	                ; no -> Indice += 4, y sigo

    BTFSC   PORTB, 1	            ; Columna 3 (RB1) en alto?
    GOTO    OFFSET_ROW	            ; Guardar tecla presionada
	INCF    INDICE, 1	            ; no -> Indice += 4, y sigo

	BTFSC   PORTB, 0	            ; Columna 4 (RB0) en alto?
	GOTO    OFFSET_ROW	            ; si -> offset = 4
    BCF     STATUS, C
	RRF     ROWMASK	                ; no -> siguiente fila
    
	CALL    SUMO_4	                ; Incrementar el indice de row en 4        
	MOVLW   0x0F
	SUBWF   ROW, 0
	BTFSS   STATUS, Z	            ; Se revisaron todas las filas?
    GOTO    ESCANEAR_COL            ; no -> seguimos escaneando columnas
	MOVLW   0xFF	                ; si -> volvemos
	MOVF    INDICE, 1	            ; con el indice en 0xFF
	RETURN

OFFSET_ROW:
	MOVF    ROW, W
	ADDWF   INDICE, 0
    CALL    TECLAS	                ; Obtener tecla presionada
    MOVWF   TECLA	                ; Guardar tecla presionada
	RETURN		    

SUMO_4:
	MOVLW   0x04	                ; Sumo 4
    ADDWF   ROW, 1	                ; al indice
    RETURN

; =============================
; ========= TX mensaje ========
; =============================
TX_TEXTO:
    ; Envía: Temp: xx.x C, Corte: xx.x C\r\n
    ; Envía caracteres con CALL TX_BYTE

    MOVLW   'T'  ; ejemplo
    CALL    TX_BYTE
    MOVLW   'e'
    CALL    TX_BYTE
    MOVLW   'm'
    CALL    TX_BYTE
    MOVLW   'p'
    CALL    TX_BYTE
    MOVLW   ':'
    CALL    TX_BYTE
    MOVLW   ' '
    CALL    TX_BYTE

    ; Temperatura
    MOVF    decenas, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVF    unidades, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   '.'
    CALL    TX_BYTE

    MOVF    decimas, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   ' '
    CALL    TX_BYTE
    MOVLW   'C'
    CALL    TX_BYTE
    MOVLW   ','
    CALL    TX_BYTE
    MOVLW   ' '
    CALL    TX_BYTE

    ; "Corte: "
    MOVLW   'C'
    CALL    TX_BYTE
    MOVLW   'o'
    CALL    TX_BYTE
    MOVLW   'r'
    CALL    TX_BYTE
    MOVLW   't'
    CALL    TX_BYTE
    MOVLW   'e'
    CALL    TX_BYTE
    MOVLW   ':'
    CALL    TX_BYTE
    MOVLW   ' '
    CALL    TX_BYTE

    ; Temperatura de corte
    MOVF    decenascorte, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVF    unidadescorte, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   '.'
    CALL    TX_BYTE

    MOVF    decimascorte, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   ' '
    CALL    TX_BYTE
    MOVLW   'C'
    CALL    TX_BYTE
    MOVLW   0x0D ; '\r'
    CALL    TX_BYTE
    MOVLW   0x0A ; '\n'
    CALL    TX_BYTE
    RETURN

; TX byte por UART 
TX_BYTE:
    BTFSS   PIR1, TXIF      ; Espera si está aún transmitiendo
    GOTO    $-1          
    MOVWF   TXREG
    RETURN

TX_ASCII:
    ADDLW   '0'
    CALL    TX_BYTE
    RETURN