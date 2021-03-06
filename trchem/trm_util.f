C ---------------------------------------------------------------------
C FILE: TM_UTIL.F
C -------------------- 
C SUBROUTINES:
C
C SUBROUTINE TRGETBC(NERR) 
C SUBROUTINE TRGETBC_IN(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
C     &     KEYOUT,NBLK,BC_PRESX,BC_PRESY,BC_PRESZ,PRES)
C  
C CODE HISTORY:
C
C SUNIL G. THOMAS 01/15/07  REACTIVE-TRANSPORT MULTI-BLOCK INTERFACE BC 
C                           ROUTINE BASED ON TGETBC.
C --------------------------------------------------------------------  
      SUBROUTINE TRGETBC(NALPHA,NERR)
C
C INTERFACE TO A  WORK ROUTINE THAT COPIES VALUES OF THE
C IPARS PRIMARY VARIABLES FOR THE PHYSICAL MODEL TO BC_VARIABLES
C
C IT COPIES PRES -> BC_PRES                                      
C ==============================================================
      IMPLICIT NONE
      INTEGER NERR
C
      INCLUDE 'blkary.h'
      INCLUDE 'trarydat.h'
      INCLUDE 'mbvars.h'
C
      INTEGER NALPHA,IGETBC(8)
      DATA IGETBC /8*0/
      EXTERNAL TRGETBC_IN
C
      IGETBC(1) = 7
      IGETBC(2) = N_BC_PRIM(1,$NBCVARS)
      IGETBC(3) = N_BC_PRIM(2,$NBCVARS)
      IGETBC(4) = N_BC_PRIM(3,$NBCVARS)
      IGETBC(5) = N_CONCARR(NALPHA)
      IGETBC(6) = N_BC_TYPE(1)
      IGETBC(7) = N_BC_TYPE(2)
      IGETBC(8) = N_BC_TYPE(3)
C
      CALL CALLWORK(TRGETBC_IN,IGETBC)
C
      RETURN
      END

C --------------------------------------------------------------------  
      SUBROUTINE TRGETBC_IN(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &     KL1,KL2,KEYOUT,NBLK,BC_CONCX,BC_CONCY,BC_CONCZ,CONC,
     &     BC_TYPEX,BC_TYPEY,BC_TYPEZ)
C
C THIS IS A WORK ROUTINE : COPIES IPARS PRIMARIES -> IPARS BC_PRIMARIES
C ================================================================
      IMPLICIT NONE
C
      INCLUDE 'layout.h'
C
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),KL1,KL2
      INTEGER KEYOUT(IDIM,JDIM,KDIM),NBLK
      INTEGER BC_TYPEX(JDIM-2*JLAY,KDIM-2*KLAY,2)
      INTEGER BC_TYPEY(IDIM-2*ILAY,KDIM-2*KLAY,2)
      INTEGER BC_TYPEZ(IDIM-2*ILAY,JDIM-2*JLAY,2) 
      REAL*8 BC_CONCX(JDIM-2*JLAY,KDIM-2*KLAY,2)
      REAL*8 BC_CONCY(IDIM-2*ILAY,KDIM-2*KLAY,2) 
      REAL*8 BC_CONCZ(IDIM-2*ILAY,JDIM-2*JLAY,2) 
      REAL*8 CONC(IDIM,JDIM,KDIM)
      INTEGER I,J,K
C -----------------------------------------------------------------

      I=ILAY+1
 10   IF ((I.EQ.ILAY+1.AND.BC_MORTAR(1,NBLK).EQ.1).OR.(I.EQ.IDIM-ILAY
     &     .AND.BC_MORTAR(2,NBLK).EQ.1)) THEN
      DO K=KLAY+1,KDIM-KLAY
      DO J=JLAY+1,JDIM-JLAY

         IF (I.EQ.ILAY+1.AND.KEYOUT(I,J,K).EQ.1.
     &       AND.BC_TYPEX(J-JLAY,K-KLAY,1).EQ.1) THEN 
            BC_CONCX(J-JLAY,K-KLAY,1)=CONC(I,J,K)
         ELSE IF (I.EQ.ILAY+1) THEN
            BC_CONCX(J-JLAY,K-KLAY,1)=0.D0
         ENDIF   
         IF(I.EQ.IDIM-ILAY.AND.KEYOUT(I,J,K).EQ.1
     &      .AND.BC_TYPEX(J-JLAY,K-KLAY,2).EQ.1) THEN     
            BC_CONCX(J-JLAY,K-KLAY,2)=CONC(I,J,K)
         ELSE IF (I.EQ.IDIM-ILAY) THEN 
            BC_CONCX(J-JLAY,K-KLAY,2)=0.D0
         ENDIF
      ENDDO
      ENDDO
      ENDIF
      IF(I.EQ.IDIM-ILAY) GOTO 11
      I=IDIM-ILAY
      GOTO 10
 11   CONTINUE

      J=JLAY+1
 20   IF ((J.EQ.JLAY+1.AND.BC_MORTAR(3,NBLK).EQ.1).OR.(J.EQ.JDIM-JLAY
     &     .AND.BC_MORTAR(4,NBLK).EQ.1)) THEN
      DO K=KLAY+1,KDIM-KLAY
      DO I=ILAY+1,IDIM-ILAY

         IF (J.EQ.JLAY+1.AND.KEYOUT(I,J,K).EQ.1
     &       .AND.BC_TYPEY(I-ILAY,K-KLAY,1).EQ.1) THEN     
            BC_CONCY(I-ILAY,K-KLAY,1)=CONC(I,J,K)
         ELSE IF (J.EQ.JLAY+1) THEN
            BC_CONCY(I-ILAY,K-KLAY,1)=0.D0
         ENDIF   
         IF(J.EQ.JDIM-JLAY.AND.KEYOUT(I,J,K).EQ.1
     &      .AND.BC_TYPEY(I-ILAY,K-KLAY,2).EQ.1) THEN     
            BC_CONCY(I-ILAY,K-KLAY,2)=CONC(I,J,K)
         ELSE IF (J.EQ.JDIM-JLAY) THEN
            BC_CONCY(I-ILAY,K-KLAY,2)=0.D0
         ENDIF
      ENDDO
      ENDDO
      ENDIF
      IF(J.EQ.JDIM-JLAY) GOTO 21
      J=JDIM-JLAY
      GOTO 20
 21   CONTINUE

      K=KLAY+1
 30   IF ((K.EQ.KLAY+1.AND.BC_MORTAR(5,NBLK).EQ.1).OR.(K.EQ.KDIM-KLAY
     &     .AND.BC_MORTAR(6,NBLK).EQ.1)) THEN
      DO J=JLAY+1,JDIM-JLAY
      DO I=ILAY+1,IDIM-ILAY

         IF(K.EQ.KLAY+1.AND.KEYOUT(I,J,K).EQ.1
     &      .AND.BC_TYPEZ(I-ILAY,J-JLAY,1).EQ.1) THEN     
            BC_CONCZ(I-ILAY,J-JLAY,1)=CONC(I,J,K)
         ELSE IF (K.EQ.KLAY+1) THEN
            BC_CONCZ(I-ILAY,J-JLAY,1)=0.D0
         ENDIF   
         IF(K.EQ.KDIM-KLAY.AND.KEYOUT(I,J,K).EQ.1
     &      .AND.BC_TYPEZ(I-ILAY,J-JLAY,2).EQ.1) THEN
            BC_CONCZ(I-ILAY,J-JLAY,2)=CONC(I,J,K)
         ELSE IF (K.EQ.KDIM-KLAY) THEN  
            BC_CONCZ(I-ILAY,J-JLAY,2)=0.D0
         ENDIF
      ENDDO
      ENDDO
      ENDIF
      IF(K.EQ.KDIM-KLAY) GOTO 31
      K=KDIM-KLAY
      GOTO 30
 31   CONTINUE

      RETURN
      END

