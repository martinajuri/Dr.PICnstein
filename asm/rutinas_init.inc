; ========================================================================
; =========== Rutinas de inicializaciÃ³n para el PIC16F887 ================
; ========================================================================

; ==========================================================
; ========== ConfiguraciÃ³n de puertos y ADC ================
; ==========================================================
CONFIGURAR:
    ; ANSEL RA5 digital (banco 3) (11)
    BANK3
    MOVLW   b'00011111'     ; RA2 como analÃ³gico (AN2) y el resto digitales
    MOVWF   ANSEL
    CLRF    ANSELH          ; Setear puerto B como digital  

    ; TRISA y TRISD (banco 1) (01)
    BANK1
    MOVLW   b'00011111'
    MOVWF   TRISA           ;  RA0-RA2 entrada
    CLRF    TRISC           ; PORTC como salida para LEDs
    CLRF    TRISD           ; PORTD como salida (segmentos)
    CLRF    TRISE           ; PORTD como salida RE0, RE1, RE2 como salida (multiplex)
    MOVLW   0x0F            ; RB7-RB4 Salidas (fil), RB3-RB0 Entradas (col)
    MOVWF   TRISB

    ; ConfiguraciÃ³n de OPTION_REG
    MOVLW   B'10000111'     ; Deshabilitar pull-ups, prescaler 1:16
    MOVWF   OPTION_REG
    
    ; Configuracion de OSCCON
    MOVLW   B'01100001'  
    MOVWF    OSCCON

    ; ConfiguraciÃ³n ADC ADCON1: (banco 1) (01)
    MOVLW   b'10000000'     ; vref+ = AN3, vref- = Vss (porque es el puerto AN2 donde esta el sensor)
    MOVWF   ADCON1

    ; Configuracion de IOCB
    MOVLW   B'00000001'     ; Habilitar interrupciones por cambio en RB0
    MOVWF   IOCB

    ; ConfiguraciÃ³n de UART (banco 1) (01)
    MOVLW   0x19          ; 9600 baud @ 4MHz -> SPBRG = 25
    MOVWF   SPBRG

    BSF     TXSTA, BRGH   ; Alta velocidad
    BSF     TXSTA, TXEN   ; Habilitar TX
    BSF     RCSTA, SPEN   ; Habilitar puerto serial (TX/ RX)

    ; ADCON0: canal 2 (AN2), ADC ON (banco 0) (00)
    BANK0
    MOVLW   b'01000101'     ; ADCS=10(Fosc/32) CHS=0010 (AN2), ADON=1, GO=0
    MOVWF   ADCON0

    ; ConfiguraciÃ³n de interrupciones
    MOVLW   b'10001000' ; Habilitar interrupciones globales y por cambio Puerto B
    MOVWF   INTCON

    RETURN        

; ==========================================================
; ========== InicializaciÃ³n de variables y puertos =========
; ==========================================================
INICIALIZAR:
    ; InicializaciÃ³n de puertos (banco 0) (00)
    BANK0
    CLRF    PORTA
    CLRF    PORTD
    CLRF    PORTE
    MOVLW   b'00111111'     ; Inicializar PORTC con LEDs apagados
    MOVWF   PORTC
    MOVLW   0xF0            ; Inicializar PORTB con filas en alto
    MOVWF   PORTB

    ; Inicializo la temperatura de corte en 80 grados
    MOVLW   B'00000011'
    MOVWF   TCH
    MOVLW   B'00100000'
    MOVWF   TCL

    ; Iniciar conversiÃ³n ADC
    BSF     ADCON0, GO
    
    RETURN