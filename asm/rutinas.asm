;--- Rutinas para el proyecto ---

; --- Rutina para multiplexar los displays ---
MOSTRAR_DISPLAY:
    CALL    DISPLAY_CENTENAS
    CALL    DISPLAY_DECENAS
    CALL    DISPLAY_UNIDADES   
    RETURN
DISPLAY_CENTENAS:
    MOVF    centenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD

    ; Activar RA5 (centenas)
    MOVLW   b'00000110'
    MOVWF   PORTE
    CALL    RETARDO            
    MOVLW   b'00000111'
    MOVWF   PORTE          
    RETURN
    
DISPLAY_DECENAS:
    MOVF    decenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    BSF	    PORTD, 7            ; Punto decimal

    ; Activar RA6 (decenas)
    MOVLW   b'00000101'
    MOVWF   PORTE
    CALL    RETARDO            
    MOVLW   b'00000111'
    MOVWF   PORTE          
    RETURN

DISPLAY_UNIDADES:
    MOVF    unidades, W
    CALL    TABLA_7SEG
    MOVWF   PORTD

    ; Activar RA7 (unidades)
    MOVLW   b'00000011'
    MOVWF   PORTE
    CALL    RETARDO            
    MOVLW   b'00000111'
    MOVWF   PORTE          
    RETURN

; --- Rutina de retardo visible para multiplexado (16ms) ---
RETARDO:
    BANK0
    CLRF TMR0               ; Limpiar TMR0
    BCF INTCON,TMR0IF       ; Limpia el flag de interrupción TMR0
LOOP_RETARDO:
    BTFSS INTCON, TMR0IF    ; Espera a que TMR0 se desborde
    GOTO LOOP_RETARDO       ; Si no se desbordó, espera
    RETURN
    
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
    RETURN
    
; --- Rutina de ADC ---
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

    ; Actualiza centenas, decenas y unidades
    CALL    SEPARAR_3DIGITOS

    ; Iniciar nueva conversión ADC
    BSF     ADCON0, GO

    RETURN


; --- Tabla de conversión a 7 segmentos (anodo común) ---
TABLA_7SEG
    ADDWF   PCL, F
    RETLW   0xC0    ; 0
    RETLW   0xF9    ; 1
    RETLW   0xA4    ; 2
    RETLW   0xB0    ; 3
    RETLW   0x99    ; 4
    RETLW   0x92    ; 5
    RETLW   0x82    ; 6
    RETLW   0xF8    ; 7
    RETLW   0x80    ; 8
    RETLW   0x90    ; 9

; --- Tabla de teclas ---
TECLAS:
    ADDWF PCL, f
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
    RETLW 0x20     ; 11
    RETLW 0x20     ; 12
    RETLW D'0'     ; 13
    RETLW 0x20     ; 14
    RETLW 0x20     ; 15


    
; -----------------------------------
; en algun init llamen a INIT_UART
; y que en las variables definen las necesarias acá
; decenas, unidades y decimas
; spdecenas, spunidades y spdecimas



INIT_UART:
    BSF     STATUS, RP0
    MOVLW   0x19          ; 9600 baud @ 4MHz -> SPBRG = 25
    MOVWF   SPBRG
    BCF     STATUS, RP0

    BSF     TXSTA, BRGH   ; High speed
    BSF     TXSTA, TXEN   ; Enable TX
    BSF     RCSTA, SPEN   ; Enable serial port (TX/ RX)
    RETURN

; =============================
; === TX mensaje ===
; =============================

TX_TEXTO:
    ; Envía: Temp: xx.x°C, Set Point: xx.x°C\r\n
    ; Envía caracteres con CALL TX_BYTE
    ; Armarlo como:
    ; "Temp: ", número, ", Set Point: ", número, "\r\n"
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

    ; Parte entera
    ; si tienen algo como decenas, unidades y decimas
    MOVF    decenas, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVF    unidades, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   '.'
    CALL    TX_BYTE

    MOVF    decimas, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   223           ; ° (grados)
    CALL    TX_BYTE
    MOVLW   'C'
    CALL    TX_BYTE
    MOVLW   ','
    CALL    TX_BYTE
    MOVLW   ' '
    CALL    TX_BYTE

    ; "Set Point: "
    MOVLW   'S'
    CALL    TX_BYTE
    MOVLW   'e'
    CALL    TX_BYTE
    MOVLW   't'
    CALL    TX_BYTE
    MOVLW   ' '
    CALL    TX_BYTE
    MOVLW   'P'
    CALL    TX_BYTE
    MOVLW   'o'
    CALL    TX_BYTE
    MOVLW   'i'
    CALL    TX_BYTE
    MOVLW   'n'
    CALL    TX_BYTE
    MOVLW   't'
    CALL    TX_BYTE
    MOVLW   ':'
    CALL    TX_BYTE
    MOVLW   ' '
    CALL    TX_BYTE

    ; Set point
    ; si tienen algo como spdecenas, spunidades y spdecimas
    MOVF    spdecenas, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVF    spunidades, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   '.'
    CALL    TX_BYTE

    MOVF    spdecimas, W
    CALL    TX_ASCII       ; Enviar 1 caracter

    MOVLW   223
    CALL    TX_BYTE
    MOVLW   'C'
    CALL    TX_BYTE
    MOVLW   0x0D ; '\r'
    CALL    TX_BYTE
    MOVLW   0x0A ; '\n'
    CALL    TX_BYTE
    RETURN

; =============================
; === TX byte por UART ===
; =============================
TX_BYTE:
    BTFSS   PIR1, TXIF  ; espera si está aún transmitiendo
    GOTO    $-1          
    MOVWF   TXREG
    RETURN

; =============================
; === Enviar 1 dígito (ascii ===
; 0 --> "0", 1 --> "1" ... 9-->"9"
; =============================
TX_ASCII:
    ADDLW   '0'
    CALL    TX_BYTE
    RETURN