; Macros de manejo de Bancos y conversor A/D

BANK0       macro 
    BCF STATUS,RP1
    BCF STATUS,RP0
            endm

BANK1       macro
    BCF STATUS,RP1
    BSF STATUS,RP0
            endm

BANK2       macro
    BSF STATUS,RP1
    BCF STATUS,RP0
            endm

BANK3       macro
    BSF STATUS,RP1
    BSF STATUS,RP0
            endm

TURNON      macro
    BCF     PORTC, 2
    BCF     PORTC, 4
            endm
            
TURNOFF     macro
    BSF     PORTC, 2
    BSF     PORTC, 4
            endm