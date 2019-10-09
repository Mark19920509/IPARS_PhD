C  READ3.FOR - FREEFORM KEYWORD INPUT PACKAGE
C
C  ROUTINES IN THIS MODULE:
C
C  SUBROUTINE GETVAL2 (VNAM,VAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,NERR)
C      ENTRY GETVALS2 (VNAM,SVAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,NERR)

C HISTORY:

C GURPREET SINGH 2011-2014

C*********************************************************************
      SUBROUTINE GETVAL2 (VNAM,VAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,
     & NERR)
C*********************************************************************
C  EXTRACTS DATA FROM THE INPUT SUPER ARRAY.  DO NOT USE THIS ROUTINE
C  TO DIRECTLY READ MEMORY MANAGED ARRAYS

C  VNAM   = VARIABLE NAME AND OPTIONAL UNITS (INPUT, CHARACTER*60).
C           THE NAME MUST BE TERMINATED WITH A BLANK OR THE LEFT
C           BRACKET OF A UNITS SPECFICATION.  THE NAME CAN NOT INCLUDE
C           EMBEDDED BLANKS.  UNITS, IF ANY, MUST BE ENCLOSED IN
C           BRACKETS [] AND IMMEDIATELY FOLLOW THE NAME.  BLANKS MAY BE
C           INCLUDED BETWEEN THE BRACKETS.  EXAMPLES:
C           'NX '   'P[psi]'   'HC[Btu/lb F]'

C  VAL()  = VALUE RETURNED (OUTPUT).  MAY BE DIMENSIONED OR NOT.
C   OR      TYPE IS DETERMINED BY VTYP.  IF VNAM IS NOT FOUND THEN
C  SVAL()   VAL IS NOT CHANGED.  USE ENTRY GETVALS() TO READ CHARACTER
C           STRINGS AND BLOCK TEXT.

C  VTYP   = VARIABLE TYPE (INPUT, CHARACTER*2).
C         = I2 ==> INTEGER
C         = I4 ==> INTEGER
C         = R4 ==> REAL*4
C         = R8 ==> REAL*8
C         = L2 ==> LOGICAL
C         = L4 ==> LOGICAL
C         = CS ==> CHARACTER STRING (MAX LENGTH GIVEN BY DIM4)
C         = FG ==> FLAG VARIABLE, LOGICAL
C         = BT ==> BLOCK TEXT (MAX LENGTH GIVEN BY DIM4)

C  NDIM1  = DIMENSIONS OF VAL (INPUT, INTEGER).
C  NDIM2    UNUSED DIMENSIONS ARE INDICATED BY 0
C  NDIM3    FOR CHARACTER AND BLOCK VARIABLES, NDIM4 = MAX CHARACTERS.
C  NDIM4    CHARACTER VARIABLES ARE LIMITED TO 3 SUBSCRIPTS.
C           BLOCK VARIABLES MAY NOT BE SUBSCRIPTED IF GETVAL IS CALLED
C           DIRECTLY (CALL INDIRECTLY VIA GETBLK)
C           IF THE FILL OPTION FOR ARRAYS IS NOT TO BE USED THEN SET
C           NDIM1 EQUAL TO THE NEGATIVE OF THE FIRST DIMENSION.

C  NUMRET = NUMBER OF VALUES RETURNED IN VAL() (OUTPUT, INTEGER)

C  NERR   = ERROR NUMBER STEPPED BY 1 FOR EACH DATA ERROR INCOUNTERED
C           (INPUT AND OUTPUT, INTEGER)

C*********************************************************************
      USE scrat1mod

      PARAMETER (MAXCHR=100000000)

      LOGICAL LQ,ENDAT,LV,SKIPIT,WLOGIC
      INTEGER NN(3,4),MUL(4),NGLT(3),L1REP(5),L2REP(5),NREP(5)
      REAL*8 R8,VAL(*)
      CHARACTER*1 BLANK,QUOTE,COMMA,LEFT,RIGHT,EQUAL,COLON,ASTR,VNAM(*),
     & TOS(2),STP(4),TRU(4),FAL(5),III,JJJ,KKK,LLL,LBRAC,RBRAC,RECEND
     & ,SVAL(*)
      CHARACTER*2 TYP(9),VTYP
      CHARACTER*50 E
      CHARACTER*60 UNTSTDS

      INTEGER LI,LJ,LK
      LOGICAL ELEIN

      INCLUDE 'control.h'
      INCLUDE 'readdat.h'
!      INCLUDE 'scrat1.h'
      INCLUDE 'layout.h'

      EQUIVALENCE (UNTSTD(1),UNTSTDS)

      DATA BLANK/' '/,QUOTE/'"'/,COMMA/','/,LEFT/'('/,RIGHT/')'/,
     & EQUAL/'='/,COLON/':'/,ASTR/'*'/,TOS/'T','O'/,LBRAC/'['/,
     & STP/'S','T','E','P'/,III/'I'/,JJJ/'J'/,KKK/'K'/,LLL/'L'/,
     & RBRAC/']'/,TYP/'I2','I4','R4','R8','L2','L4','CS','FG','BT'/,
     & TRU/'T','R','U','E'/,FAL/'F','A','L','S','E'/

      ENTRY GETVALS2 (VNAM,SVAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,
     & NERR)

      NUMRET=0
      ISUNT=.FALSE.
      NOTINDX=.TRUE.
      UNTSTDS=' '
      LBLK=1

C  GET LENGTH OF VARIABLE NAME AND STANDARD UNITS, IF ANY

      DO 1 I=1,60
      IF (VNAM(I).EQ.BLANK) GO TO 2
      IF (VNAM(I).EQ.LBRAC) THEN
         DO 42 J=1,60
         UNTSTD(J)=VNAM(I+J)
         IF (UNTSTD(J).EQ.RBRAC) GO TO 2
 42      CONTINUE
         GO TO 2
      ENDIF
    1 NAML=I
    2 L1=1

C  FIND VARIABLE NAME

   97 LQ=.TRUE.
      LL=LAST-NAML+1
      DO 3 I=L1,LL
      IF (A(I).EQ.QUOTE) LQ=.NOT.LQ
      IF ((A(I).EQ.COLON).AND.LQ) THEN
         DO 4 J=1,NAML
         IF (A(I+J).NE.VNAM(J)) GO TO 3
    4    CONTINUE
         J=I+NAML+1
         IF (A(J).EQ.BLANK.OR.A(J).EQ.EQUAL.OR.A(J).EQ.LEFT.OR.
     &      A(J).EQ.COLON) THEN
            LV1=I
            L=I+NAML+1
            GO TO 5
         ENDIF
      ENDIF
    3 CONTINUE

C  EXIT IF VARIABLE NAME NOT FOUND

      ISUNTD=.FALSE.
      RETURN

C  SET VARIABLE TYPE CODE

    5 DO 6 I=1,9
      IF (VTYP.EQ.TYP(I)) THEN
         KVAR=I
         GO TO 7
      ENDIF
    6 CONTINUE
      LEVERR=2
      IF (LEVELC) WRITE(NFOUT,36) VTYP,(VNAM(I),I=1,NAML)
   36 FORMAT(' ERROR 121, PROGRAM ERROR: TYPE ',A2,' FOR VARIABLE ',
     & 20A1)
      NERR=NERR+1
      L=LV1+1
      GO TO 95

C  SET DEFAULT INDEX RANGES

    7 DO 40 I=1,4
      NN(1,I)=1
   40 NN(3,I)=1
      ND1A=MAX(IABS(NDIM1),1)
      ND2A=MAX(NDIM2,1)
      ND3A=MAX(NDIM3,1)
      ND4A=MAX(NDIM4,1)
      IF (KVAR.EQ.9) ND4A=1
      NN(2,1)=ND1A
      NN(2,2)=ND2A
      NN(2,3)=ND3A
      NN(2,4)=ND4A
      IF (KVAR.EQ.7) NN(2,4)=1
      I1=1
      I2=2
      I3=3
      I4=4
      MUL(1)=1
      IF (NBLKG.GT.0) THEN
         NGLT(1)=IGLT+1
         NGLT(2)=JGLT+1
         NGLT(3)=KGLT+1

         MUL(2)=IDIML
         MUL(3)=IDIML*JDIML
         MUL(4)=IDIML*JDIML*KDIML
      ELSE
         MUL(2)=ND1A
         MUL(3)=ND1A*ND2A
         MUL(4)=ND1A*ND2A*ND3A
      ENDIF

C  TEST FOR SCALAR VARIABLE

      IF (NDIM1.EQ.0.AND.NDIM2.EQ.0.AND.NDIM3.EQ.0.AND.
     & NN(2,4).EQ.1) THEN
         IF (A(L).EQ.LEFT.OR.A(L+1).EQ.LEFT) THEN
            E='SUBSCRIPT ON A SCALAR VARIABLE'
            NER=118
            GO TO 90
         ENDIF
         GO TO 15
      ENDIF

C  PARSE ARRAY INDEXES

C  GET (
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).NE.LEFT) GO TO 13
      L=L+1
C  LOOK FOR INDEX SEQUENCE CHARACTERS
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).LT.III.OR.A(L).GT.LLL) GO TO 50
      IF (A(L).EQ.JJJ) I1=2
      IF (A(L).EQ.KKK) I1=3
      IF (A(L).EQ.LLL) I1=4
      L=L+1
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).LT.III.OR.A(L).GT.LLL) GO TO 50
      IF (A(L).EQ.III) I2=1
      IF (A(L).EQ.KKK) I2=3
      IF (A(L).EQ.LLL) I2=4
      L=L+1
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).LT.III.OR.A(L).GT.LLL) GO TO 50
      IF (A(L).EQ.III) I3=1
      IF (A(L).EQ.JJJ) I3=2
      IF (A(L).EQ.LLL) I3=4
      L=L+1
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).LT.III.OR.A(L).GT.LLL) GO TO 50
      IF (A(L).EQ.III) I4=1
      IF (A(L).EQ.JJJ) I4=2
      IF (A(L).EQ.KKK) I4=3
      L=L+1
   50 IF (I1.EQ.I2.OR.I1.EQ.I3.OR.I1.EQ.I4.OR.I2.EQ.I3.OR.I2.EQ.I4
     & .OR.I3.EQ.I4) THEN
         E='INVALID INDEX SEQUENCE'
         NER=117
         GO TO 90
      ENDIF

C  LOOP OVER THE INDEXES
      NDMAX=4
      IF (KVAR.EQ.7) NDMAX=3
      IF (KVAR.EQ.9) NDMAX=1
      DO 16 I=1,NDMAX
      IDUM=NN(2,I)
C  GET LOWER INDEX
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.COMMA) GO TO 16
      NOTINDX=.FALSE.
      CALL GETNUM(R8,KEY,L,LL)
      NOTINDX=.TRUE.
      IF (KEY.EQ.0) THEN
         L=LL
         NN(1,I)=R8+1.0D-2
         IF (NN(1,I).LT.1.OR.NN(1,I).GT.IDUM) GO TO 41
         NN(2,I)=R8+1.0D-2
      ENDIF
C  CHECK FOR , OR )
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.COMMA) GO TO 16
      IF (A(L).EQ.RIGHT) GO TO 14
C  GET TO
      IF (A(L).NE.TOS(1).OR.A(L+1).NE.TOS(2)) GO TO 13
      L=L+2
C  GET UPPER INDEX
      NN(2,I)=IDUM
      NOTINDX=.FALSE.
      CALL GETNUM(R8,KEY,L,LL)
      NOTINDX=.TRUE.
      IF (KEY.EQ.0) THEN
         L=LL
         NN(2,I)=R8+1.0D-2
         IF (NN(2,I).LT.1.OR.NN(2,I).GT.IDUM) GO TO 41
      ENDIF
C  CHECK FOR , OR )
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.COMMA) GO TO 16
      IF (A(L).EQ.RIGHT) GO TO 14
C  GET STEP
      IF (A(L).NE.STP(1).OR.A(L+1).NE.STP(2).OR.A(L+2).NE.STP(3).OR.
     &   A(L+3).NE.STP(4)) GO TO 13
      L=L+4
C  GET STEP SIZE
      NOTINDX=.FALSE.
      CALL GETNUM(R8,KEY,L,LL)
      NOTINDX=.TRUE.
      IF (KEY.EQ.0) THEN
         L=LL-1
         NN(3,I)=R8+1.0D-2
      ELSE
         GO TO 13
      ENDIF
C  END OF INDEX LOOP
   16 L=L+1
C  GET )
      IF (A(L).EQ.BLANK) L=L+1
   14 IF (A(L).EQ.RIGHT) THEN
        L=L+1
        GO TO 11
      ENDIF
   13 E='INVALID ARRAY SYNTAX'
      NER=103
      GO TO 90
C  CHECK VALID INDEX RANGE(S)
   11 DO 35 I=1,NDMAX
      IF (NN(3,I)*(NN(2,I)-NN(1,I)).LT.0) GO TO 41
   35 CONTINUE
      GO TO 15
   41 E='INVALID SUBSCRIPT RANGE'
      NER=112
      GO TO 90

C  GET BLANK AND/OR = AFTER VARIABLE NAME AND SUBSCRIPTS

   15 IF (A(L).NE.BLANK.AND.A(L).NE.EQUAL) THEN
         IF (KVAR.NE.8) THEN
            E='BLANK OR EQUAL DOES NOT FOLLOW VARIABLE NAME'
            NER=104
            GO TO 90
         ENDIF
      ELSE
         L=L+1
      ENDIF
      IF (A(L).EQ.EQUAL) L=L+1
      IF (A(L).EQ.BLANK) L=L+1

C  START DATA LOOP, global corners

      NUMREP=0
      ENDAT=.FALSE.
      LFILL=0
      NETPRN=0
      NRETR=0
      NBLK=0

      DO 20 ND4=NN(1,I4),NN(2,I4),NN(3,I4)
      DO 20 ND3=NN(1,I3),NN(2,I3),NN(3,I3)
      DO 20 ND2=NN(1,I2),NN(2,I2),NN(3,I2)
      DO 20 ND1=NN(1,I1),NN(2,I1),NN(3,I1)
      SKIPIT=.FALSE.
      IF (NBLKG.GT.0) THEN
         IF (I2.EQ.2) THEN
            MAPA=ND2
         ELSE
            IF (I1.EQ.2) THEN
               MAPA=ND1
            ELSE
               IF (I3.EQ.2) THEN
                  MAPA=ND3
               ELSE
                  MAPA=ND4
               ENDIF
            ENDIF
         ENDIF
         IF (I3.EQ.3) THEN
            MAPA=MAPA+N0MAP(NBLKG)+ND3*NYMAP(NBLKG)
         ELSE
            IF (I1.EQ.3) THEN
               MAPA=MAPA+N0MAP(NBLKG)+ND1*NYMAP(NBLKG)
            ELSE
               IF (I2.EQ.3) THEN
                  MAPA=MAPA+N0MAP(NBLKG)+ND2*NYMAP(NBLKG)
               ELSE
                  MAPA=MAPA+N0MAP(NBLKG)+ND4*NYMAP(NBLKG)
               ENDIF
            ENDIF
         ENDIF

C CORNER POINT DATA
C  I1=1 I2=2 I3=3 I4=4 FOR MOST CASES WITH ONE GHOST LAYER
C       MAPA = ND2 + N0MAP(NBLKG)+ND3*NYMAP(NBLKG)
C       NGLT(I1)=NGLT(I2)=NGLT(I3)=NGLT(I4)=0
C

c processor maps of surrounding four elements w.r.t. corner
c GLOBAL CORNER INDEX:  ND1,ND2,ND3

        MAPA1 = ND2-1 + N0MAP(NBLKG) + (ND3-1)*NYMAP(NBLKG)
        MAPA2 = ND2   + N0MAP(NBLKG) + (ND3-1)*NYMAP(NBLKG)
        MAPA3 = ND2-1 + N0MAP(NBLKG) + ND3*NYMAP(NBLKG)
        MAPA4 = ND2   + N0MAP(NBLKG) + ND3*NYMAP(NBLKG)

        WLOGIC = .FALSE.

c        IF ((ND2.GT.1).AND.(ND3.GT.1)) THEN
c          IF (PRCMAP(MAPA1).EQ.MYPRC) WLOGIC = .TRUE.
c        ENDIF
c        IF ((ND2.LT.NDIM2).AND.(ND3.GT.1)) THEN
c          IF (PRCMAP(MAPA2).EQ.MYPRC) WLOGIC = .TRUE.
c        ENDIF
c        IF ((ND2.GT.1).AND.(ND3.LT.NDIM3)) THEN
c          IF (PRCMAP(MAPA3).EQ.MYPRC) WLOGIC = .TRUE.
c        ENDIF
c        IF ((ND2.LT.NDIM2).AND.(ND3.LT.NDIM3)) THEN
c          IF (PRCMAP(MAPA4).EQ.MYPRC) WLOGIC = .TRUE.
c        ENDIF

c increase xc dimension
c nx,ny,nz:    global numer of element in each direction
c              (without including ghost layer)
c nd1 nd2 nd3: global corner index in each direction
c              (without including ghost layer)
c              1:nx+1 1:ny+1 1:nz+1
c nd1-1 nd2-1 nd3-1 :
c     --------        -surrounding 8 elements to
c     --------         corner (nd1,nd2,nd3)
c     --------        -indexing 0: nx + 1
c     --------        -zero and nx+1 are gohast layer
c     --------         parts
c nd1   nd2   nd3   :
c LI LJ LK : Local element index 1:idim 1:jdim 1:kdim
c LI = GI - IOFF
c LJ = GJ - JOFF
c LK = GK - KOFF
C
C X- Y- Z- ELEMENT
C
        LI = nd1-1 - IGLT
        LJ = nd2-1 - JGLT
        LK = nd3-1 - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X+ Y- Z- ELEMENT
C
        LI = nd1   - IGLT
        LJ = nd2-1 - JGLT
        LK = nd3-1 - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X- Y+ Z- ELEMENT
C
        LI = nd1-1-IGLT
        LJ = nd2  -JGLT
        LK = nd3-1-KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X+ Y+ Z- ELEMENT
C
        LI = nd1   - IGLT
        LJ = nd2   - JGLT
        LK = nd3-1 - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X- Y- Z+ ELEMENT
C
        LI = nd1-1 - IGLT
        LJ = nd2-1 - JGLT
        LK = nd3   - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X+ Y- Z+ ELEMENT
C
        LI = nd1   - IGLT
        LJ = nd2-1 - JGLT
        LK = nd3   - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X- Y+ Z+ ELEMENT
C
        LI = nd1-1 - IGLT
        LJ = nd2   - JGLT
        LK = nd3   - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.
C
C X+ Y+ Z+ ELEMENT
C
        LI = nd1   - IGLT
        LJ = nd2   - JGLT
        LK = nd3   - KGLT
        IF(ELEIN(LI,LJ,LK,IDIML-1,JDIML-1,KDIML-1)) WLOGIC=.TRUE.



        IF (WLOGIC) THEN
           LOC=MUL(I1)*(ND1-NGLT(I1))+MUL(I2)*(ND2-NGLT(I2))
     &        +MUL(I3)*(ND3-NGLT(I3))+MUL(I4)*(ND4-1)+1
        ELSE
           SKIPIT=.TRUE.
        ENDIF
C CORNER POINT DATA
      ELSE
         LOC=MUL(I1)*(ND1-1)+MUL(I2)*(ND2-1)+MUL(I3)*(ND3-1)
     &      +MUL(I4)*(ND4-1)+1
      ENDIF

C XC1 is R8.  KVAR = 4

C  PROCESS FLAG VARIABLES

      IF (KVAR.EQ.8) THEN
         CALL PUTL4(.TRUE.,LOC,VAL)
         GO TO 20
      ENDIF

C  PROCESS BLOCK TEXT INPUT

      IF (KVAR.EQ.9) THEN
         IF (NBLK.EQ.0) THEN
            L=L+6
            CALL PUTBT(A(L),SVAL,NDIM4,LBLK,NUMRET9,KERR)
            NBLK=1
            LBLKO=LBLK
            LBLK=LBLK+NUMRET9
            IF (KERR.NE.0) THEN
               E='MAX TEXT BLOCK LENGTH EXCEEDED'
               NER=120
               GO TO 90
            ENDIF
            L=L+NUMRET9
         ENDIF
         LENBLK(ND1)=NUMRET9
         LOCBLK(ND1)=LBLKO
         GO TO 20
      ENDIF

C  CHECK FOR END OF A REPEAT SEQUENCE

   23 IF (NUMREP.GT.0) THEN
         IF (L.GE.L2REP(NUMREP)) THEN
            IF (NUMRET.EQ.NRETR) THEN
               E='NO DATA FOR REPEAT FACTOR'
               NER=115
               GO TO 90
            ENDIF
            IF (NREP(NUMREP).GT.1) THEN
               NREP(NUMREP)=NREP(NUMREP)-1
               L=L1REP(NUMREP)
               IF (A(L).EQ.LEFT) THEN
                  L=L+1
                  NETPRN=NETPRN+1
               ENDIF
            ELSE
               NUMREP=NUMREP-1
               IF (A(L).EQ.RIGHT) THEN
                  IF (NETPRN.LE.0) THEN
                     E='RIGHT PARENTHESIS NOT EXPECTED'
                     NER=108
                     GO TO 90
                  ENDIF
                  L=L+1
                  NETPRN=NETPRN-1
               ENDIF
               GO TO 23
            ENDIF
         ENDIF
      ENDIF

C  LOOK FOR A NUMBER

      CALL GETNUM(R8,KEY,L,LL)
      IF (KEY.EQ.0) GO TO 21

C  NUMBER NOT FOUND.  MAY BE END OF VARIABLE DATA, CHARACTER VARIABLE,
C  LOGICAL VARIABLE, OR ERROR

      IF (KEY.NE.1) GO TO 98
   45 IF (A(L).EQ.BLANK.OR.A(L).EQ.COMMA) THEN
         L=L+1
         GO TO 45
      ENDIF
      IF (A(L).EQ.COLON) GO TO 22
      IF (A(L).EQ.QUOTE) THEN
         IF (KVAR.EQ.7) GO TO 24
         E='QUOTE ENCOUNTERED, NUMBER EXPECTED'
         NER=107
         GO TO 90
      ENDIF
      IF (KVAR.EQ.5.OR.KVAR.EQ.6) THEN
         IF (NUMREP.EQ.0) LFILL=L
         DO 31 I=1,4
         IF (A(L+I-1).NE.TRU(I)) GO TO 32
   31    CONTINUE
         LV=.TRUE.
         L=L+4
         GO TO 27
   32    DO 33 I=1,5
         IF (A(L+I-1).NE.FAL(I)) GO TO 34
   33    CONTINUE
         LV=.FALSE.
         L=L+5
         GO TO 27
      ENDIF
   34 E='DATA SYNTAX ERROR'
      NER=109
      GO TO 90

C  NUMBER FOUND, MAY BE REPEAT FACTOR, DATA, OR ERROR

   21 IF (NUMREP.EQ.0) LFILL=L
      L=LL
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.ASTR) GO TO 26
      IF (KVAR.LT.5) GO TO 28
      E='UNEXPECTED NUMBER ENCOUNTERED'
      NER=110
      GO TO 90

C  END OF VARIABLE DATA FOUND

   22 IF (LFILL.EQ.0) THEN
         E='EXPECTED DATA NOT FOUND'
         NER=111
         GO TO 90
      ENDIF
      IF (NDIM1.LT.0) GO TO 95
      L=LFILL
      GO TO 23

C  QUOTE FOUND AND EXPECTED

   24 IF (NUMREP.EQ.0) LFILL=L
      LOC=(LOC-1)*ND4A+1
      CALL PUTCS(A,L,ND4A,SVAL,LOC,L,NER)
      L=L+1
      IF (NER.EQ.0) GO TO 20
      E='CHARACTER STRING IS TOO LONG'
      NER=113
      GO TO 90

C  REPEAT FACTOR FOUND

   26 IF (NUMREP.GT.4) THEN
         E='MORE THAN 5 REPEAT FACTORS NESTED'
         NER=112
         GO TO 90
      ENDIF
      NRETR=NUMRET
      NUMREP=NUMREP+1
      NREP(NUMREP)=R8+1.0D-2
      L=L+1
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.LEFT) THEN
         L1REP(NUMREP)=L
         NETPRN=NETPRN+1
         L=L+1
         LQ=.TRUE.
         NET=1
         DO 29 I=L,LAST
         IF (A(I).EQ.QUOTE) LQ=.NOT.LQ
         IF (LQ) THEN
            IF (A(I).EQ.RIGHT) THEN
               NET=NET-1
               IF (NET.EQ.0) THEN
                  L2REP(NUMREP)=I
                  GO TO 23
               ENDIF
            ENDIF
            IF (A(I).EQ.LEFT) NET=NET+1
            IF (A(I).EQ.COLON) GO TO 30
         ENDIF
   29    CONTINUE
   30    E='RIGHT PARENTHESES FOR REPEAT FACTOR NOT FOUND'
         NER=105
         GO TO 90
      ENDIF
      IF (A(L).EQ.COLON) THEN
         E='NO DATA AFTER REPEAT FACTOR'
         NER=114
         GO TO 90
      ENDIF
      L1REP(NUMREP)=L
      L2REP(NUMREP)=L+1
      GO TO 23

C  LOGICAL VARIABLE FOUND AND EXPECTED

   27 IF (SKIPIT) GO TO 20
      IF (KVAR.EQ.5) THEN
         CALL PUTL2(LV,LOC,VAL)
      ELSE
         CALL PUTL4(LV,LOC,VAL)
      ENDIF
      GO TO 20

C  NUMERIC DATA FOUND AND EXPECTED

   28 IF (SKIPIT) GO TO 20
      IF (KVAR.EQ.1) CALL PUTI2(R8,LOC,VAL)
      IF (KVAR.EQ.2) CALL PUTI4(R8,LOC,VAL)
      IF (KVAR.EQ.3) CALL PUTR4(R8,LOC,VAL)

      IF (KVAR.EQ.4) VAL(LOC)=R8

C  END OF DATA LOOP

   20 NUMRET=NUMRET+1


C  SET CORRECT SIZE FOR A SINGLE BLOCK READ BY GETVAL

      IF (KVAR.EQ.9) NUMRET=NUMRET9

C  CHECK FOR EXCESS DATA

   38 IF (A(L).EQ.BLANK.OR.A(L).EQ.COMMA.OR.A(L).EQ.RIGHT) THEN
         L=L+1
         GO TO 38
      ENDIF
      IF (A(L).EQ.COLON.OR.NUMREP.GT.0) GO TO 95
      E='EXCESS DATA ENCOUNTERED'
      NER=106

C  OUTPUT ERROR MESSAGE

   90 IF (L-LV1.GT.65) THEN
         NS=L-65
      ELSE
         NS=LV1+1
      ENDIF
      K=NS+75
      IF (K.GT.LAST) K=LAST
      M=L-NS
      RECEND=CHAR(30)
      DO 91 I=L,K
      IF (A(I).EQ.COLON.OR.A(I).EQ.RECEND) GO TO 92
   91 M=M+1
   92 CALL PUTERR(NER,E,A(NS),M,L-NS+1)
   98 NERR=NERR+1

C  ERASE ENTRY AND GO BACK TO LOOK FOR ANOTHER ENTRY

   95 LQ=.TRUE.
      L1=L
      LV1=LV1+1
      IF (.NOT.NOERASE) THEN        ! bag8
      DO 96 I=LV1,LAST
      IF (A(I).EQ.QUOTE) LQ=.NOT.LQ
      IF ((A(I).EQ.COLON).AND.LQ) GO TO 97
      A(I)=BLANK
   96 CONTINUE
      ENDIF
      ISUNTD=.FALSE.
      RETURN
      END
