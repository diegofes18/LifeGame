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
            MOVE.W A1,(A0)
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
         
         MOVEM.L D0-D1/A0-A2,-(A7)
         
         MOVE.L (A0),A2
         AND.B #%11111000,4(A0)
         MOVE.W (MOUX),D0
         MOVE.W 2(A2),D1
         SUB.W D1,D0
         ADD.W 6(A2),D1
         CMP.W D1,D0
         BLE IN_X
         JMP FINAL

IN_X:    MOVE.W (MOUY),D0
         MOVE.W (A2),D1
         SUB.W D1,D0
         ADD.W 4(A2),D1
         CMP.W D1,D0
         BLE IN_ALL
         JMP FINAL

IN_ALL:  OR.B #%00000001, 4(A0)
         MOVE.B (MOUVAL),D0
         BTST.L #0,D0
         BEQ FINAL
         OR.B #%00000010,4(A0)
         MOVE.B (MOUEDGE),D0
         BTST.L #0,D0
         BEQ FINAL
         OR.B #%00000100,4(A0)
         MOVE.L 8(A0),A1
         JSR (A1)
         
FINAL:   MOVEM.L (A7)+,D0-D1/A0-A2
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

        MOVE.B #93,D0
        MOVE.B #BTNPENWD,D1
        TRAP #15
        
        MOVE.B #80,D0
        MOVE.L #BTNPENCL,D1
        TRAP #15
      
        BTST #0,4(A0)
        BNE INSIDE
        
        JMP OUT

INSIDE: MOVE.B #81,D0
        MOVE.L #BTNSELCL,D1
        TRAP #15
       
        BTST #1,4(A0)
        BNE PRESSED
        
        JMP FINAL1

PRESSED: MOVE.B #81,D0
         MOVE.L #BTNPRSCL,D1
         TRAP #15
         JMP FINAL1
         
OUT:     MOVE.B #81,D0
         MOVE.L #0,D1
         TRAP #15
         JMP FINAL1

FINAL1:   MOVE.L (A0),A1
         
         MOVE.B #87,D0
         MOVE.W 2(A1),D1
         MOVE.W (A1),D2
         MOVE.W D1,D3
         ADD.W 6(A1),D3
         MOVE.W D2,D4
         ADD.W 4(A1),D4
         TRAP #15
         RTS











*~Font name~Courier New~
*~Font size~11~
*~Tab type~1~
*~Tab size~4~
