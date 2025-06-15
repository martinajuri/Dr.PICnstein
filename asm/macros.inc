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