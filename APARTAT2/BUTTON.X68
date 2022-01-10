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
         
*            MOVEM.L D0-D7/A0-A2,-(A7)
*         
*            MOVE.L (A0),A2
*         
*            ;Máscara para dejar a 0 los 3 últimos bits del status
*            ANDI.B #%11111000,4(A0)  
*         
*            MOVE.W (MOUX),D0
*            MOVE.W 2(A2),D1
*            SUB.W D1,D0
*            
*            MOVE.W 6(A2),D2
*            ADD.W D2,D1
*            CMP.W D0,D1
*         
*            BGE MAYOR_X
*            JMP FINAL
*            
*MAYOR_X:    CMP.W #0,D0
**           BLE FINAL
*            MOVE.W (MOUX),D3
*            CMP.W D3,D1
*            BGE IN_X 
*            JMP FINAL
*
*IN_X:       MOVE.W (MOUY),D0
*            MOVE.W (A2),D1
*            SUB.W D1,D0
*            
*            MOVE.W 4(A2),D2
*            ADD.W D2,D1
*            CMP D0,D1
*            BGE MAYOR_Y
*            JMP FINAL
*            
*MAYOR_Y:    CMP.W #0,D0
*            BLE  FINAL
**          MOVE.W (MOUY),D3
*            CMP.W D3,D1
*            BGE BIT_I
*            JMP FINALL
*         
*BIT_I:      ORI.B #%00000001,4(A0)
*            MOVE.B (MOUVAL),D1
*            BTST.L #0,D1
*            BNE BIT_P
*            JMP FINAL
*            
*BIT_P:      ORI.B #%00000010,4(A0)
*            MOVE.B (MOUEDGE),D1
*            BTST.L #0,D1
*            BNE BIT_C
*            JMP FINAL
*            
*BIT_C:      ORI.B #%00000100,4(A0)
*            MOVE.L 8(A1),A2
*            JSR (A2)
*
*         
*FINAL:      MOVEM.L (A7)+,D0-D7/A0-A2
*            RTS
*

    MOVEM.L A0-A3/D0-D3, -(A7)

    ;A1-SDB +0
    MOVE.L (A0),A1

    ADDQ.L #4,A0

    ;A0 APUNTA A VBD +4 STATTUS I POSAM ELS BITS CPI A 0
    ANDI.B #%11111000,(A0)

    ;MIRAR SI Y ES MAJOR QUE LA
    ;COORDENADA Y DEL BOTO


    ;TEMPORAL
    ;YTOP COORDINATES
    ;D1 - YTOP
    MOVE.W (A1),D1
    MOVE.W (MOUY),D2

    ;A1-HEIGHT

    MOVE.W 4(A1),D3



    ;COMPARAM COORDENADES Y DEL RATOLI
    ;AMB ELS PIXELS Y DEL BOTO
    SUB.W D1,D2



    ;MIRAM SI LA ANTERIOR DIFERENCIA ES MENOR QUE LA ALTURA
    CMP.W D2,D3
    BGE  .MAJOR_0_Y


    JMP .FINAL



 
;SABEMO QUE MOUY HA ESTAT MAJOR QUE LA
;COORDENADA Y DEL BOTO


.DINS_Y:

    ;TEMPORAL
    ;YTOP COORDINATES
    ;D1 - YTOP

    ;A1-XLEFT
    MOVE.W 2(A1),D1

    MOVE.W (MOUX),D2


    ;A1-WIDTH
    MOVE.W 6(A1),D3

    ;COMPARAM COORDENADES x DEL RATOLI
    ;AMB ELS PIXELS x DEL BOTO
    SUB.W D1,D2

    ;MIRAM SI LA ANTERIOR DIFERENCIA ES MENOR QUE LA
    ;AMPLADA
    CMP.W D2,D3
    BGE  .MAJOR_0_X 
    JMP .FINAL


.MAJOR_0_X:
    CMP #0,D2
    BGE .BITI
    JMP .FINAL

.MAJOR_0_Y:
    CMP #0,D2
    BGE .DINS_Y
    JMP .FINAL




.BITI:
    ;ACTIVAM BIT I
    ORI.B #%00000001,(A0)

    ;MOUSE STATUS A D1

    MOVE.B (MOUVAL),D1
    ;MIRAM BIT 0 PER VEURE SI EL CLICK ESQUERRE
    ;SE HA APRETAT PRESSED
    BTST.L #0,D1
    ;SI HA ESTAT 1 BITP
    BNE .BITP


    JMP .FINAL


.BITP: 
    ;ACTIVAM EL BIT P
    ORI.B #%0000010,(A0)
    ;MIRAM BIT 0 PER VEURE SI EL BOTO ESQUERRE
    ;SE HA APRETAT PRESSED
    MOVE.B (MOUEDGE),D1
    BTST.L #0,D1

    ;SI HA ESTAT 1 A BITC
    BNE .BITC


    JMP .FINAL



.BITC:

     ORI.B #%00000100,(A0)
     MOVE.L 8(A1),A2

     ;EXECUTES CALLBACK
     JSR  (A2)




.FINAL:

     MOVEM.L (A7)+,A0-A3/D0-D3 
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

        MOVEM.L D0-D7/A0-A1,-(A7)
        MOVE.B #93,D0
        MOVE.B #BTNPENWD,D1
        TRAP #15
        
        MOVE.B #80,D0
        MOVE.L #BTNPENCL,D1
        TRAP #15
        
        MOVE.B 4(A0),D3
        BTST.L #0,D3
        BNE INSIDE
        
        JMP OUT

INSIDE: BTST.L #1,D3
        BNE PRESSED
        MOVE.B #81,D0
        MOVE.L #BTNSELCL,D1
        TRAP #15
        
        JMP FINAL1

PRESSED: MOVE.B #81,D0
         MOVE.L #BTNPRSCL,D1
         TRAP #15
         
         JMP FINAL1
         
OUT:     MOVE.B #81,D0
         MOVE.L #0,D1
         TRAP #15


FINAL1:  MOVE.L (A0),A1
         
         MOVE.B #87,D0
         MOVE.W 2(A1),D1
         MOVE.W (A1),D2
         MOVE.W D1,D3
         ADD.W 6(A1),D3
         MOVE.W D2,D4
         ADD.W 4(A1),D4
         TRAP #15
         
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
