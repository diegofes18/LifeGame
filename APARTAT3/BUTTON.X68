; =============================================================================
; TITLE    : BUTTON MANAGEMENT
; AUTHOR   : ANTONI BURGUERA
; HISTORY  : 05-JULY-2021 - CREATION
; COMMENTS : * A BUTTON IS DEFINED BY A STATIC DATA BLOCK (SDB), WHICH DOES NOT
;              CHANGE OVER TIME, AND A VARIABLE DATA BLOCK (VDB), THAT CAN
;              CHANGE OVER TIME. CHANGES IN THE VDB ARE PRODUCED WHEN CALLING
;              SUBROUTINE BTNUPD.
;
;            * THE BUTTON SDB (CAN BE IN ROM) HAS THE FOLLOWING FIELDS. THE
;              NUMBER DENOTES THE OFFSET WITH RESPECT TO THE SDB START:
;
;                +0  - WORD - YTOP COORDINATE (PIXELS)
;                +2  - WORD - XLEFT COORDINATE (PIXELS)
;                +4  - WORD - HEIGHT (PIXELS)
;                +6  - WORD - WIDTH (PIXELS)
;                +8  - LONG - CALLBACK POINTER
;                +12 - BYTE STRING - ZERO TERMINATED STRING. TEXT TO SHOW.
;
;            * THE BUTTON VDB (MUST BE IN RAM) IS:
;
;                +0 - LONG - POINTER TO THE STATIC DATABLOCK
;                +4 - BYTE - STATUS WITH FORMAT XXXXXCPI WHERE:
;                            - I (BIT 0) - 1=MOUSE INSIDE, 0=MOUSE OUTSIDE
;                            - P (BIT 1) - 1=MOUSE PRESSED INSIDE
;                                          0=MOUSE NOT PRESSED INSIDE
;                            - C (BIT 2) - 1=MOUSE CLICKED INSIDE
;                                          0=MOUSE NOT CLICKED INSIDE
;                            NOTE THAT IF I=0 THEN P=C=0, IF I=1 AND P=0
;                            THEN C=0.
; =============================================================================

; -----------------------------------------------------------------------------
BTNINIT
; INITIALIZES THE BUTTON BY:
;  * COPYING THE SDB POINTER INTO THE VDB.
;  * CLEARING THE STATUS BYTE.
; INPUT    : A0 - POINTER TO THE VARIABLE DATABLOCK
;            A1 - POINTER TO THE STATIC DATABLOCK
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE  

            ;Copiamos SDB (A1) en el contenido de VDB ((A0))         
            MOVE.L A1,(A0)
            
            ;Limpiamos el B status
            CLR.B 4(A0) 
           
            RTS
; -----------------------------------------------------------------------------
BTNUPD
; UPDATES THE BUTTON VDB AND EXECUTES THE CALLBACK IF REQUIRED
; INPUT    : A0 - POINTER TO THE VARIABLE DATABLOCK
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE
    
            ;Guardamos registros     
            MOVEM.L A0-A3/D0-D4, -(A7)

            ;Movemos el contenido de VDB en A1
            MOVE.L (A0),A2

            ;Sumamos 4 a A0 para acceder a los bits I,P,C 
            ADDQ.L #4,A0

            ;Ponemos I,P,C de A0 en 0
            ANDI.B #%11111000,(A0)

            ;Movemos las coordenadas MOUY en D2,
            ;y YTOP en D1
            MOVE.W (MOUY),D1
            MOVE.W (A2),D2

            ;Movemos la altura del botón en D3
            MOVE.W 4(A2),D3

            ;Restamos la posición Y del ratón con la coordenada
            ;Y superior, y comprobamos que sea menor que su altura
            SUB.W D2,D1
            CMP.W D1,D3
            
            ;Saltamos si MOUY es mayor
            BGE MAYORY
            
            ;Saltamos si MOUY es menor
            JMP FINAL
            

MAYORY:
            ;Comprobamos que la coordenada del botón sea >0
            CMP #0,D1
            
            ;Saltamos en DENTROY si MOUY es mayor
            BGE DENTROY
            
            JMP FINAL


DENTROY:

            ;Si entramos aqui es porqué el ratón se encuentra
            ;dentro de las coordenadas Y del botón
            ;Ahora miraremos que esté dentro de X
    
            ;Movemos MOUX a D1, y XLEFT a D2
            MOVE.W (MOUX),D1
            MOVE.W 2(A2),D2

            ;El proceso que usaremos es el mismo que para la Y
            MOVE.W 6(A2),D3

            ;XLEFT - MOUX, y comprobar que sea mayor a la anchura
            SUB.W D2,D1
            CMP.W D1,D3
    
            BGE  MAYORX 
        
            JMP FINAL


MAYORX:
            ;Comprobamos que la coordenada del botón sea >0
            CMP #0,D1
            
            BGE I
            
            JMP FINAL


I:
            ;Si entramos en aquí significa que el ratón se encontraba
            ;dentro de un botón
            
            ;Ponemos el bit I de A0 en 1
            ORI.B #%00000001,(A0)

            MOVE.B (MOUVAL),D4
            
            ;Comparamos si el ratón se está pulsando(P=1)
            BTST.L #0,D4
            
            ;Saltamos si el bit P estaba en 1
            BNE P

            JMP FINAL


P: 
            ;Ponemos el bit P en 1 porque el click derecho se ha pulsado
            ORI.B #%0000010,(A0)
            
            ;Miramos mediante el bit menos significativo de MOUEDGE 
            ;si el ratón ha sido pulsado
            MOVE.B (MOUEDGE),D4
            BTST.L #0,D4

            ;Saltamos si C=1
            BNE C

            JMP FINAL


C:
            ;Ponemos C en 1
            ORI.B #%00000100,(A0)
            MOVE.L 8(A2),A3

            ;Realizamos el callback para el sonido
            JSR  (A3)


FINAL:

            MOVEM.L (A7)+,A0-A3/D0-D4
            RTS







; -----------------------------------------------------------------------------
BTNPLOT
; PLOTS THE BUTTON. A RECTANGLE IS DRAWN WITH THICKNESS BTNPENWD. THE CONTOUR
; COLOR IS BTNPENCL. THE FILL COLOR IS BLACK IF THE MOUSE IS NOT INSIDE,
; BTNSELCL IF THE MOUSE IS INSIDE BUT THE MOUSE BUTTON IS NOT PRESSED AND
; BTNPRSCL IF THE MOUSE BUTTON IS PRESSED INSIDE.
; INPUT    : A0 - POINTER TO THE VARIABLE DATABLOCK
; OUTPUT   : NONE
; MODIFIES : NONE
; -----------------------------------------------------------------------------

; TODO : PLACE YOUR CODE HERE

            ;Guardamos registros
            MOVEM.L D0-D7/A0-A1,-(A7)
        
            ;Usamos el trap #15 para la anchura del contorno
            MOVE.B #93,D0
            MOVE.B #BTNPENWD,D1
            TRAP #15
        
            ;Usamos el trap #15 para el color del contorno
            MOVE.B #80,D0
            MOVE.L #BTNPENCL,D1
            TRAP #15
        
            ;Miramos si el ratón está dentro del botón, mediante el bit 
            ;menos significativo de VDB
            MOVE.B 4(A0),D3
            BTST.L #0,D3
            
            ;Si el bit vale 1 significa que está dentro
            BNE DENTRO
        
            JMP FUERA


DENTRO: 
            ;Miramos si el ratón se está pulsando dentro de un botón
            ;mediante el bit P
            BTST.L #1,D3
            
            ;Saltamos si está pulsado
            BNE PULSADO
            
            ;Si no està pulsado usamos la tarea 81 del trap #15 para
            ;asignarle color correspondiente 
            MOVE.B #81,D0
            MOVE.L #BTNSELCL,D1
            TRAP #15
        
            JMP FINAL1
            

PULSADO:    
            ;Usamos la tarea 81 del trap #15 para asignarle el color 
            ;correspondiente al botón, para cuando se pulsa
            MOVE.B #81,D0
            MOVE.L #BTNPRSCL,D1
            TRAP #15
         
            JMP FINAL1
         
FUERA:      
            ;Usamos la tarea 81 del trap #15 para asignarle el color 
            ;correspondiente al botón, para cuando el ratón se encuentra
            ;fuera del botón 
            MOVE.B #81,D0
            MOVE.L #0,D1
            TRAP #15


FINAL1:     
            MOVE.L (A0),A1
         
            ;Usamos la tarea 87 del trap #15 para dibujar el rectangulo
            ;con sus coordenadas correspondientes
            MOVE.B #87,D0
            MOVE.W 2(A1),D1
            MOVE.W (A1),D2
            MOVE.W D1,D3
            ADD.W 6(A1),D3
            MOVE.W D2,D4
            ADD.W 4(A1),D4
            TRAP #15
         
            ;Usamos la tarea 95 del trap #15 para escribir el texto 
            ;correcto en el rectangulo
            MOVE.B #95,D0
            MOVE.W 2(A1),D1
            ADD.W #40,D1
         
            MOVE.W (A1),D2
            ADD.W #15,D2
         
            ADD.W #12,A1
         
            TRAP #15
         
            MOVEM.L (A7)+,D0-D7/A0-A1
            RTS

        
























*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
