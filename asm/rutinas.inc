

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
    CALL    RETARDO             ; Retardo para multiplexado
    MOVLW   b'00000111'
    MOVWF   PORTE          ; Desactivar RA5, RA6, RA7
    RETURN
    
DISPLAY_DECENAS:
    MOVF    decenas, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    BSF	    PORTD, 7
    ; Activar RA6 (decenas)
    MOVLW   b'00000101'
    MOVWF   PORTE
    CALL    RETARDO             ; Retardo para multiplexado
    MOVLW   b'00000111'
    MOVWF   PORTE          ; Desactivar RA5, RA6, RA7
    RETURN

DISPLAY_UNIDADES:
    MOVF    unidades, W
    CALL    TABLA_7SEG
    MOVWF   PORTD
    ; Activar RA7 (unidades)
    MOVLW   b'00000011'
    MOVWF   PORTE
    CALL    RETARDO             ; Retardo para multiplexado
    MOVLW   b'00000111'
    MOVWF   PORTE          ; Desactivar RA5, RA6, RA7
    RETURN
; --- Rutina de retardo visible para multiplexado ---
RETARDO:
    BANK0
    CLRF TMR0          ; Limpiar TMR0
    BCF INTCON,TMR0IF ; Limpia el flag de interrupciÃ³n TMR0
LOOP_RETARDO:
    BTFSS INTCON, TMR0IF ; Espera a que TMR0 se desborde
    GOTO LOOP_RETARDO   ; Si no se desbordÃ³, espera
    RETURN

; --- Rutina de ADC ---
ADC:
    BANK0
    BCF     PORTC, 4        ; Apagar LED RC1 (fin del ciclo)
    ; Actualiza centenas, decenas y unidades
    ;CALL    SEPARAR_3DIGITOS
    MOVF    ADRESH, W
    CALL    TABLA_7SEG
    MOVF    PORTD
    CLRF    PORTE
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    CALL RETARDO
    ; Iniciar nueva conversiÃ³n ADC
    BSF     ADCON0, GO
    BSF     PORTC, 4        ; Prender LED RC1 (inicio ADC)
    RETURN


; --- Tabla de conversiÃ³n a 7 segmentos (anodo comÃºn) ---
; 0-9: 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
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
