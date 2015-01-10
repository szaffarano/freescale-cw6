;** ===================================================================
;**     Programa        : main.asm
;**
;**     Descripcion     : punto de entrada invocado en _Startup
;** ===================================================================

            INCLUDE 'derivative.inc'
;
; export symbols
;
            XDEF _Startup
            ABSENTRY _Startup

;
; Constantes
;
PUSH1_PORT  EQU   PTAD
PUSH1_MASK  EQU   (1<<PTAD_PTAD1)

PUSH2_PORT  EQU   PTAD
PUSH2_MASK  EQU   (1<<PTAD_PTAD2)

LED_PORT    EQU   PTBD
LED_MASK    EQU   (1<<PTBD_PTBD4)

BUZ_PORT    EQU   PTBD
BUZ_MASK    EQU   (1<<PTBD_PTBD3)

; offsets de los parámetros que se pasan por stack
PORT        EQU   0
MASK        EQU   1
STATE       EQU   2

; estados de la máquina de estados
WAITING     EQU   0
BOUNCE1     EQU   1
PUSHED      EQU   2
BOUNCE2     EQU   3

DELAY       EQU   20

; Variables en ZRAM
;
            ORG   Z_RAMStart
;
; Cada pulsador se describe con 3 bytes.
; La rutina que maneja el teclado recibe como parámetro en el stack una variable de este tipo, la
; cual modifica en base al estado del pulsador.  Ver SMKBD
KEY1       RMB   3
KEY2       RMB   3

;
; Variables en RAM
;
            ORG    RAMStart

; Codigo
;
            ORG    ROMStart

; Se incluye codigo generado por Device Initializacion
            
            INCLUDE 'MCUInit.inc'

;
; Entry point cargado en el vector de interrupciones
; (ver MCUinit.inc)
_Startup:
            LDHX   #RAMEnd+1        ; initialize the stack pointer
            TXS
            ; Se invoca MCU_init, definido en MCUinit.inc, generado
            ; por Device Initialization
            JSR    MCU_init

; Codigo main
MAIN        BSR   INISYS

; Bucle infinito
LOOP:       
            LDA   KEY1+STATE
            AND   #%00000001
            CMP   #1
            BNE   KEY1OFF
            BSR   LEDON                   ; Tecla 1 presionada
            BRA   NEXT
KEY1OFF     BSR   LEDOFF

NEXT        LDA   KEY2+STATE
            AND   #%00000001
            CMP   #1
            BNE   KEY2OFF
            BSR   BUZON                   ; Tecla 2 presionada
            BRA   NEXT1
KEY2OFF     BSR   BUZOFF
            
NEXT1       BRA   LOOP                     
            
LEDON       LDA   LED_PORT
            ORA   #LED_MASK
            STA   LED_PORT
            RTS

LEDOFF      LDA   #LED_MASK
            COMA
            AND   LED_PORT
            STA   LED_PORT
            RTS

BUZON       LDA   BUZ_PORT
            ORA   #BUZ_MASK
            STA   BUZ_PORT
            RTS

BUZOFF      LDA   #BUZ_MASK
            COMA
            AND   BUZ_PORT
            STA   BUZ_PORT
            RTS
                        
;** ===================================================================
;** Se invoca cada 1 ms
;** ===================================================================
TICK_1MS
            LDHX  #KEY1       ; Pongo el parámetro (KEY1) en el stack
            PSHX
            PSHH
            
            BSR   SMKBD       ; Invoco función de debounce para KEY1
            AIS   #2          ; Reseteo el stack para desechar parámetro

            LDHX  #KEY2       ; Pongo el parámetro (KEY2) en el stack
            PSHX
            PSHH
            BSR   SMKBD       ; Invoco función de debounce para KEY2
            AIS   #2          ; reseteo el stack para desechar parámetro

END_TICK    RTS

;** ===================================================================
; Inicializaición del sistema.
;** ===================================================================
INISYS      CLI             ; habilito interrupciones

            ; Inicializo KEY1 con los valores del pulsador1
            MOV   #PUSH1_PORT,KEY1+PORT
            MOV   #PUSH1_MASK,KEY1+MASK
            MOV   #(WAITING<<1), KEY1+STATE

            ; Inicializo KEY2 con los valores del pulsador2
            MOV   #PUSH2_PORT,KEY2+PORT
            MOV   #PUSH2_MASK,KEY2+MASK
            MOV   #(WAITING<<1), KEY2+STATE
            
            RTS

;** ================================================================================== **
;** SMKBD         :     Máquina de estados que maneja un pulsador.  Recibe en el       **
;**                     stack un puntero a una variable de 3 bytes que contiene        **
;**                     el puerto del pulsador, la máscara en ese puerto, y actualiza  **
;**                     el estad que tiene el pulstador.                               **
;**                                                                                    **
;** PORT          :     Puerto del pulsador.                                           **
;** PIN_MASK      :     Máscara del pin del pulsador.                                  **
;** STATE[0]      :     Bit que indica si el pulsador está presionado o liberado.      **
;** STATE[1:2]    :     Estado de la maquina de estados, de uso interno de la rutina.  **
;** STATE[3:7]    :     Esta parte del byte se usa para el contador del debounce_delay **
;**                     se puede contar hasta 2^5 = 32.  De uso interno de la rutina.  **
;** ================================================================================== **
SMKBD       PSHX                    ; resguardo registros
            PSHA
            PSHH

KEY         EQU   (2+3+1)           ; offset del parámetro: 
                                    ;     2 bytes de la dirección de retorno
                                    ;     3 bytes de los registros resguardados
                                    ;     1 byte pues el SP punta al próximo slot libre


            LDHX  KEY,SP            ; Pongo en H:X la dirección del parámetro
            LDA   STATE,X           ; desreferencio el estado y lo guardo en A
            AND   #%00000110        ; elimino todos los bits menos los del estado
            
            LSRA                    ; Corro hacia la derecha una posición ya que el
                                    ; estado está en los bits 1 y 2 del byte STATE
            
            CMP   #WAITING          ; Si estado == WAITING
            BEQ   S_WAITING
            
            CMP   #BOUNCE1          ; Si estado == BOUNCE1
            BEQ   S_BOUNCE1
            
            CMP   #PUSHED           ; Si estado == PUSHED
            BEQ   S_PUSHED
            
            CMP   #BOUNCE2          ; Si estado == BOUNCE2
            BEQ   S_BOUNCE2

            BRA   END_TMP           ; default: estado inválido.  No debería pasar.

; Estado Waiting
S_WAITING
            LDHX  KEY,SP            ; Pongo en H:X la dirección del parámetro
            LDX   PORT,X            ; Desreferencio el puerto y lo guardo en A
            LDA   ,X
            
            LDHX  KEY,SP            ; Vuelvo a poner en H:X el parámetro
            AND   MASK,X            ; Leo el valor de la máscara y hago AND
            CMP  #0                 ; Si el AND da cero, está presionada la key
            BNE   END_TMP           ; Si no está presionada la key, termino
            
            LDHX  KEY,SP            ; Paso el estado a BOUNCE1
            LDA   #(BOUNCE1<<1)
            ORA   #(DELAY<<3)       ; pongo el contador en #DELAY
            STA   STATE,X            
            
END_TMP     BRA   END_TMP2          ; Salto intermedio para llegar a final, por dirección > 127

; Estado Bounce1: sospecha de que se presionó la key
S_BOUNCE1
            LDHX  KEY,SP            ; Leo el estado.
            LDA   STATE,X
            AND   #%11111000        ; Dejo solo los bits del contador (7:3) con máscara AND
            LSRA                    ; Shift right 3 veces para dejar solo los 5 bits del contador
            LSRA
            LSRA
            DBNZA END_BNC1          ; Si es cero termino el tiempo de espera, confirmo si hay pulsacion,
                                    ; pero si aún no es cero tengo que guardar el contador y salir

            LDX   PORT,X            ; desreferencio el puerto y lo guardo en A
            LDA   ,X
            
            LDHX  KEY,SP            ; Vuelvo a poner en H:X el parámetro
            AND   MASK,X            ; Leo la máscara y hago AND
            CMP  #0                 ; Si el AND da cero, está presionada la key
            BEQ   TO_PUSHED
            
            LDA   #WAITING          ; Si no está presionada, falsa alarma, se vuelve a waiting
            LSLA                    ; Shift left una posición pues el estado esta en STATE[1:2]
            STA   STATE,X           ; Guardo estado en memoria
            
END_TMP2    BRA   END_SMKBD         ; Fin de esta parte del switch
            
TO_PUSHED   LDA   #PUSHED           ; Paso el estado a PUSHED
            LSLA                    ; Shift left una posición pues el estado esta en STATE[1:2]
            
            ORA   #1                ; Pongo en 1 el flag de presionado, STATE[0]
            STA   STATE,X           ; Guardo estado en memoria
            BRA   END_SMKBD         ; Finalizo esta parte del switch

END_BNC1                            ; Guardo el contador a memoria para la próxima llamada
            LSLA                    ; Vuelvo a ubicar los bits del contador en posicion 7:3 en STATE
            LSLA
            LSLA
            PSHA                    ; Backup del contador en SP
            LDA   STATE,X           ; Traigo de memoria todo el STATE y
            AND   #%00000111        ; pongo en cero el contador para pisar el valor con el decrementado
            ORA   1,SP              ; Incorporo el contador backupeado en SP con máscara OR
            STA   STATE,X           ; Almaceno el estado en memoria.
            AIS   #1                ; Saco del stack el contador almacenado.
            BRA   END_SMKBD

; Estado pushed
S_PUSHED
            LDHX  KEY,SP            ; Pongo en H:X la dirección del parámetro
            LDX   PORT,X            ; desreferencio el puerto y lo guardo en A
            LDA   ,X
            
            LDHX  KEY,SP            ; Vuelvo a poner en H:X el parámetro
            AND   MASK,X            ; desreferencio la máscara y hago AND
            CMP  #0                 ; Si el AND da cero, está presionada la key
            BEQ   ENDPSH

            LDHX  KEY,SP            ; paso el estado a BOUNCE2
            LDA   #(BOUNCE2<<1)
            ORA   #(DELAY<<3)       ; pongo el contador en #DELAY
            STA   STATE,X          

ENDPSH      BRA   END_SMKBD

S_BOUNCE2
            LDHX  KEY,SP            ; Leo el estado y dejo solo el contador
            LDA   STATE,X
            AND   #%11111000        ; Dejo solo los bits del contador (7:3)
            LSRA                    ; corro a la derecha para dejar solo los 5 bits del contador
            LSRA
            LSRA
            DBNZA END_BNC2          ; Si es cero termino el tiempo de espera, confirmo que ya no esta presionado,
                                    ; pero si aún no es cero tengo que guardar el contador y salir

            LDX   PORT,X            ; desreferencio el puerto y lo guardo en A
            LDA   ,X
            
            LDHX  KEY,SP            ; Vuelvo a poner en H:X el parámetro
            AND   MASK,X            ; desreferencio la máscara y hago AND
            CMP  #0                 ; Si el AND no da cero, confirmo que liberaron la key
            BNE   TO_WAITING
            
            LDA   #(PUSHED<<1)      ; Si está presionada, falsa alarma, vuelvo a PUSHED
            ORA   #1                ; Además del estado en pushed hay que poner el flag de presionado
            STA   STATE,X
            BRA   END_SMKBD
            
TO_WAITING  LDA   #(WAITING<<1)     ; Paso el estado a WAITING
            STA   STATE,X           ; Guardo estado en memoria.
            BRA   END_SMKBD         ; Finalizo esta parte del switch

END_BNC2    
            LSLA                    ; Vuelvo a ubicar los bits del contador en posicion 7:3 en STATE
            LSLA
            LSLA
            PSHA                    ; Backup del contador en SP
            LDA   STATE,X           ; Traigo de memoria todo el state
            AND   #%00000111        ; Reseteo el contador
            ORA   1,SP              ; Incorporo el contador backupeado en SP            
            STA   STATE,X
            AIS   #1
            BRA   END_SMKBD

END_SMKBD            
            
            PULH                    ; Dejo los registros como estaban
            PULA
            PULX
            
            RTS