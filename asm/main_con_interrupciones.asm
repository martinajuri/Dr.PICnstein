LIST    P=16F887
#include <P16F887.inc>
#include <macros.inc>
    __CONFIG    _CONFIG1, _WDT_OFF

ORG 0x00
    GOTO INICIO
ORG 0x04
    GOTO ISR
    
; --- Variables ---
CBLOCK 0x20
    temp16H
    temp16L
    decenas
    unidades
    decimas
    factor
    factore10
    TCH
    TCL
ENDC

; --- KEYPAD ---
;RB0-RB3: Columnas (entrada)
;RB0 = Columna 4
;RB1 = Columna 3    
;RB2 = Columna 2
;RB3 = Columna 1
;RB4-RB7: Filas (salida)
;RB4 = Fila 4
;RB5 = Fila 3
;RB6 = Fila 2
;RB7 = Fila 1
; --- Variables para el keypad ---
CBLOCK 0x30
    ROW             ; Fila seleccionada
    ROWMASK         ; Mascara de filas
    INDICE          ; Indice de la tecla presionada
    COL             ; Columna seleccionada
    COLMASK         ; Mascara de columnas
    TECLA           ; Tecla presionada
ENDC

; --- Variables para UART ---
CBLOCK 0x40
    decenascorte
    unidadescorte
    decimascorte
ENDC

INCLUDE "3digitos.inc"
INCLUDE "rutinas.inc"
INCLUDE "rutinas_init.inc"
    
; --- Programa principal ---
INICIO:
    CALL    CONFIGURAR
    CALL    INICIALIZAR

MAIN_LOOP:
    CALL    MOSTRAR_DISPLAY     ; Mostrar los digitos en el display
    BTFSS   ADCON0, GO          ; Verificar si la conversiÃ³n ADC estÃ¡ en curso
    CALL    ADC                 ; Si no estÃ¡ en curso, llamar a la rutina de ADC
    BTFSC   PORTC, 2            ; Verifico si esta calentando
    CALL    CONTROL             ; Controlo no superar la temperatura de corte
    ;CALL    TX_TEXTO            ; Transmitir texto por UART
    GOTO    MAIN_LOOP

; --- Interrupciones ---
ISR:
    BTFSC   INTCON, RBIF ; Verificar si es interrupciÃ³n por cambio en PORTB
    GOTO    ISR_RBIF

    RETFIE              ; Si no es interrupciÃ³n por cambio, retornar de la interrupciÃ³n


ISR_RBIF:
    BCF     INTCON, RBIF ; Limpiar bandera de interrupciÃ³n por cambio en PORTB
    ; Antirebote
	MOVLW   0xF0	                ; Pongo 1 todas las filas
	MOVWF   PORTB	    
    CALL    RETARDO   
	MOVF    PORTB, 0	            ; Testeo la columna
    ANDLW   0x0F                    ; Enmascarar columnas
    BTFSC   STATUS, Z
	RETFIE	                        ; No hay teclas presionadas -> salgo de la interrupcion

    
    ; Selecciono la primer Fila:
    MOVLW   B'10000000'           
    MOVWF   PORTB
    BTFSC   PORTB, 0	            ; fila 1 en alto?
    GOTO    ISR_OPTIONS	            ; Entro a la rutina de OPTIONS
    
    ; Selecciono la segunda Fila:
    MOVLW   B'01000000'         
    MOVWF   PORTB
	BTFSC   PORTB, 0	            ; fila 2 en alto?
    GOTO    ISR_ONOFF	            ; Entro a la rutina de INICIAR/PARAR

    ; Si no es las filas utilizadas salgo de la interrupcion
    RETFIE


; Rutina de OPTIONS
ISR_OPTIONS:
    BCF     PORTC, 5                        ; Prendo un LED que me indica que estoy en OPTIONS
    BCF     PORTC, 2                        ; Apago la pava
    CALL    RETARDO_200ms
    ; Guardo la temperatura de corte en variable temporales para separarla en digitos
    BANK0
    MOVF    TCH, W
    MOVWF   temp16H
    MOVF    TCL, W
    MOVWF   temp16L
    CALL    SEPARAR_3DIGITOS                ; Separo los digitos de la temperatura de corte actual para mostrala en los display

; Display decenas
T1:
    CALL    LOOP_KEYPAD             ; Escaneo el teclado
    BTFSC   TECLA, 4
    GOTO    SET_TEMP                ; Si se apreto options seteo la temperatura
    BTFSC   TECLA, 5
    GOTO    T1                      ; Si se apreto cualquier tecla sin utilidad escaneo denuevo
    MOVF    TECLA,W
    MOVWF   decenas                ; Guardo el valor de la tecla escaneada en decenas
T1F:
    CALL    LOOP_KEYPAD             
    BTFSC   TECLA, 4           
    GOTO    SET_TEMP                ; Si se apreto options seteo la temperatura
    BTFSC   TECLA, 6
    GOTO    T2
    GOTO    T1F
    
    
; Display unidades
T2:
    CALL    LOOP_KEYPAD             ; Repito para unidades
    BTFSC   TECLA, 4
    GOTO    SET_TEMP
    BTFSC   TECLA, 5
    GOTO    T2
    MOVF    TECLA,W
    MOVWF   unidades

T2F:
    CALL    LOOP_KEYPAD             
    BTFSC   TECLA, 4           
    GOTO    SET_TEMP                ; Si se apreto options seteo la temperatura
    BTFSC   TECLA, 6
    GOTO    T3
    GOTO    T2F
    
; Display decimas         
T3:
    CALL    LOOP_KEYPAD             ; Repito para decimas
    BTFSC   TECLA, 4
    GOTO    SET_TEMP
    BTFSC   TECLA, 5
    GOTO    T3
    MOVF    TECLA,W
    MOVWF   decimas

T3F:
    CALL    LOOP_KEYPAD             
    BTFSC   TECLA, 4           
    GOTO    SET_TEMP                ; Si se apreto options seteo la temperatura
    BTFSC   TECLA, 6
    GOTO    T1
    GOTO    T3F
    
SET_TEMP:                           ; Guardo el valor de la temperatura de corte y salgo de la Interrupcion
    CALL    COMBINAR_3DIGITOS
    BSF     PORTC, 5                ; Apago el LED que me indica que estoy en OPTIONS
    RETFIE

; Rutina de INICIAR/PARAR
ISR_ONOFF:
    CALL    RETARDO_200ms
    BTFSC   PORTC, 2                ; Me fijo si esta prendida, si es asi skipeo
    GOTO    TURNON_I
    GOTO    TURNOFF_I

TURNON_I:
    TURNON
    RETFIE
TURNOFF_I:
    TURNOFF
    RETFIE

END