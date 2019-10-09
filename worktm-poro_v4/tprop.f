C  TPROP.F - auxiliary file for TSTEP.f

C  ROUTINES IN THIS MODULE:

C  SUBROUTINE TPROP (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
C                       KEYOUT,NBLK,FLDEN,PRES,FLDENN,PRESN,COF,RESID,
C                       PV,PVN,CR)
C  SUBROUTINE TTRAN (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C          KL2,KEYOUT,NBLK,KEYOUTCR,VOLPROP,VOLDIM,FACEPROP,FACEDIM,
C          PERMINV,XC,YC,ZC,FLDEN,PRES,AINVF,TRAN,AINV,COF,RESID)
C  SUBROUTINE TUPPRES   (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
C                       KEYOUT,NBLK,DUNK,PRES)
C  SUBROUTINE TMAXRESID (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2
C                       KEYOUT,NBLK,RESID)
C  SUBROUTINE TBUGOUT   (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
C                       KEYOUT,NBLK,POR,PRES,FLDEN,COF,RESID,TCOFX,TCOFY,TCOFZ)
C  SUBROUTINE TVEL_EX(INP)
C
C  SUBROUTINE TVELCOMP (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C                      KL2,KEYOUT,NBLK,TRAN,AINVF,PRES,VOLPROP,FACEPROP,
C                      VOLDIM,FACEDIM,KEYOUTCR,VEL)

C  CODE HISTORY:

C  Bahareh Momken  3/16/99  code written for single phase flow, Hydrology
C                           (IMPES) gprop.df is used as template.
C  JOHN WHEELER   04/03/99  IMPLICIT SINGLE PHASE MODEL
C
C  GURPREET SINGH 04/04/15  IMPLICIT SINGLE PHASE MFMFE MODEL

C*********************************************************************
      SUBROUTINE TPROP (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &     KL2,KEYOUT,NBLK,FLDEN,PRES,FLDENN,PRESN,COF,RESID,
     &     PV,PVN,CR,POR,PORTRUE,PRESN3,VSTRAIN,
     &     VSTRAINN,BIOTA,MODUL,POISS,EVOL,PVN3)
C*********************************************************************

C  FORM ACCUMULATION TERMS

C  FLDEN(I,J,K) = FLUID DENSITY AT TIME N+1, LB/CU-FT (OUTPUT, REAL*8)

C  PRES(I,J,K) = FLUID PRESSURE AT TIME N+1, PSIA (INPUT, REAL*8)

C  FLDENN(I,J,K) = FLUID DENSITY AT TIME N, LB/CU-FT (OUTPUT, REAL*8)

C  PRESN(I,J,K) = FLUID PRESSURE AT TIME N, PSIA (OUTPUT, REAL*8)

C  COF(I,J,K,27)= MATRIX COEFFICIENTS (REAL*8)

C  RESID(I,J,K) = RESIDUALS (OUTPUT, REAL*8)
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'layout.h'
      INCLUDE 'control.h'
      INCLUDE 'tfluidsc.h'
      INCLUDE 'tbaldat.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM)
     &        ,KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK

      REAL*8  FLDEN(IDIM,JDIM,KDIM),   FLDENN(IDIM,JDIM,KDIM)
      REAL*8  PRES(IDIM,JDIM,KDIM),    PRESN(IDIM,JDIM,KDIM)
      REAL*8  RESID(IDIM,JDIM,KDIM)
      REAL*8  COF(IDIM,JDIM,KDIM,-13:13)
      REAL*8  CR(IDIM,JDIM,KDIM), POR(IDIM,JDIM,KDIM),
     &        PV(IDIM,JDIM,KDIM), PVN(IDIM,JDIM,KDIM),
! saumik
     &        PORTRUE(IDIM,JDIM,KDIM),PRESN3(IDIM,JDIM,KDIM),
     &        VSTRAIN(IDIM,JDIM,KDIM),VSTRAINN(IDIM,JDIM,KDIM),
     &        BIOTA(IDIM,JDIM,KDIM),MODUL(IDIM,JDIM,KDIM),
     &        POISS(IDIM,JDIM,KDIM),EVOL(IDIM,JDIM,KDIM),
     &        PVN3(IDIM,JDIM,KDIM)
! saumik
      INTEGER MAPPING,I,J,K

      REAL*8 WAT

      LOGICAL :: DBG = .FALSE.

      REAL*8 CURRTIME,PREVTIME
      DATA PREVTIME/0.D0/
!---------------------------------------------------------------
! bag8 : Linearization type for TPROP
!          0 = Usual linearization with exponential density
!          1 = Linearization for Mandel problem
!---------------------------------------------------------------
      INTEGER :: TLINTYPE = 1
!---------------------------------------------------------------

      COF = 0.D0

      CURRTIME=TIM+DELTIM

      DO K = KL1,KL2
         DO J = JL1V(K),JL2V(K)
            DO I = IL1,IL2
            IF (KEYOUT(I,J,K).NE.1) CYCLE
! BAG8 - NEWT IS RESET TO 1 DURING FIXED STRESS WITH MULTIRATE LOGIC
            IF (MBPOROE.AND.NEWT==1) THEN
! SAUMIK - RESERVOIR PORE VOLUME AT THE START OF CURRENT COUPLING ITERATION
               PORTRUE(I,J,K) = PV(I,J,K)
! SAUMIK - PORE PRESSURE AT THE START OF CURRENT COUPLING ITERATION
               PRESN3(I,J,K) = PRES(I,J,K)
! SAUMIK - VOL. STRAIN AT THE START OF CURRENT COUPLING ITERATION
               PVN3(I,J,K) = VSTRAIN(I,J,K)
            ENDIF

            IF ((CURRTIME.GT.PREVTIME).OR.(NSTEP < 1)) THEN
               PRESN(I,J,K) = PRES(I,J,K)
               FLDENN(I,J,K) = FLDEN(I,J,K)
               PVN(I,J,K) = PV(I,J,K)
            ENDIF
            IF (TMODEL.EQ.0) THEN
              FLDEN(I,J,K) = STFLDEN*EXP(FLCMP*PRES(I,J,K))
              WAT = FLDEN(I,J,K)*PV(I,J,K)
              COF(I,J,K,MAPPING(0)) = FLCMP*WAT+CR(I,J,K)*FLDEN(I,J,K)
              RESID(I,J,K) = PVN(I,J,K)*FLDENN(I,J,K)-WAT
            ELSEIF (TMODEL.EQ.1) THEN
              FLDEN(I,J,K) = STFLDEN
              WAT = STFLDEN*(PV(I,J,K)+FLCMP*POR(I,J,K)*PRES(I,J,K))
              COF(I,J,K,MAPPING(0))=STFLDEN*(FLCMP*POR(I,J,K)+CR(I,J,K))
              RESID(I,J,K) = (PVN(I,J,K)+FLCMP*PRESN(I,J,K)*POR(I,J,K))
     &                       *STFLDEN-WAT
            ELSE
              STOP 'Bad LINTYPE in TPROP'
            ENDIF
            CURRENT = CURRENT+WAT

            ENDDO
         ENDDO
      ENDDO

      PREVTIME = CURRTIME

      END
C*********************************************************************
      SUBROUTINE TTRAN (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &     KL2,KEYOUT,NBLK,KEYOUTCR,VOLPROP,VOLDIM,FACEPROP,FACEDIM,
     &     PERMINV,XC,YC,ZC,FLDEN,PRES,AINVF,TRAN,AINV,COF,RESID,
     &     UPMOBPROD)
C*********************************************************************

C  DEPTH(I,J,K) = ELEMENT CENTER DEPTH, FT (INPUT, REAL*8)

C  FLDEN(I,J,K) = FLUID DENSITY, LB/CU-FT (INPUT, REAL*8)

C  PRES(I,J,K) = FLUID PRESSURE, PSIA (INPUT, REAL*8)

C  COF(I,J,K,27)= MATRIX COEFFICIENTS (INPUT AND OUTPUT, REAL*8)

C  RESID(I,J,K)= RESIDUALS (INPUT AND OUTPUT, REAL*8)
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'tfluidsc.h'
      INCLUDE 'mpfaary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK,
     &        KEYOUTCR(IDIM+1,JDIM+1,KDIM+1),
     &        VOLPROP(IDIM+1,JDIM+1,KDIM+1,8),
     &        VOLDIM(IDIM+1,JDIM+1,KDIM+1),
     &        FACEPROP(IDIM+1,JDIM+1,KDIM+1,12),
     &        FACEDIM(IDIM+1,JDIM+1,KDIM+1)
      REAL*8  PERMINV(3,3,8,IDIM,JDIM,KDIM),
     &        XC(IDIM+1,JDIM+1,KDIM+1),YC(IDIM+1,JDIM+1,KDIM+1),
     &        ZC(IDIM+1,JDIM+1,KDIM+1),FLDEN(IDIM,JDIM,KDIM),
     &        PRES(IDIM,JDIM,KDIM),AINVF(12,IDIM+1,JDIM+1,KDIM+1),
     &        TRAN(12,8,IDIM+1,JDIM+1,KDIM+1),
     &        AINV(12,12,IDIM+1,JDIM+1,KDIM+1),
     &        COF(IDIM,JDIM,KDIM,-13:13),
     &        RESID(IDIM,JDIM,KDIM)

      INTEGER VPROP(8),FPROP(12)
      REAL*8  RHON(8),PN(8),PINV(3,3,8),X(3,8,8)
      INTEGER I,J,K,M,KR

      REAL*8  UPMOBPROD(IDIM,JDIM,KDIM,3),PCN(8)
      INTEGER NC,NPH,NCINPH,ICINPH(12+1,3)

cgp dbg
      LOGICAL DBG
      DATA DBG /.FALSE./

! bag8
C      IF (DO_INTF) STOP 'Multiblock hexahedra not implemented yet'

! bag8 - initialize TRAN and AINVF1
C      IF (.NOT.DO_INTF) THEN
C        CALL INITARYR8(TRAN,(IDIM+1)*(JDIM+1)*(KDIM+1)*8*12,0.0D0)
C        CALL INITARYR8(AINVF,(IDIM+1)*(JDIM+1)*(KDIM+1)*12,0.0D0)
C        CALL INITARYR8(AINV,(IDIM+1)*(JDIM+1)*(KDIM+1)*12*12,0.0D0)
C      ENDIF

      NC = 1
      NPH = 1
      NCINPH = 1
      ICINPH(:,:) = 1
      PCN = 0.D0

C bag8 - note: UPMOBPROD for Dirichlet boundaries set in TBDPROP;
C              It is set for internal faces below.

      DO K = 1,KDIM
      DO J = 1,JDIM
      DO I = 1,IDIM
      IF ((KEYOUT(I,J,K).EQ.1).OR.(KEYOUT(I,J,K).EQ.-1)) THEN
        IF (I.GT.1) THEN
          IF ((KEYOUT(I-1,J,K).EQ.1).OR.(KEYOUT(I-1,J,K).EQ.-1)) THEN
           UPMOBPROD(I,J,K,1) = 0.5D0*(FLDEN(I,J,K)+FLDEN(I-1,J,K))
     &                          /FLVIS
          ENDIF
        ENDIF
        IF (J.GT.1) THEN
          IF ((KEYOUT(I,J-1,K).EQ.1).OR.(KEYOUT(I,J-1,K).EQ.-1)) THEN
           UPMOBPROD(I,J,K,2) = 0.5D0*(FLDEN(I,J,K)+FLDEN(I,J-1,K))
     &                          /FLVIS
          ENDIF
        ENDIF
        IF (K.GT.1) THEN
          IF ((KEYOUT(I,J,K-1).EQ.1).OR.(KEYOUT(I,J,K-1).EQ.-1)) THEN
           UPMOBPROD(I,J,K,3) = 0.5D0*(FLDEN(I,J,K)+FLDEN(I,J,K-1))
     &                          /FLVIS
          ENDIF
        ENDIF
      ENDIF
      ENDDO
      ENDDO
      ENDDO
C
C LOOP OVER ALL VERTICES (I,J,K)
C
      DO 200 K = KL1,KL2+1
      DO 200 J = 1, JDIM+1
      DO 200 I = IL1,IL2+1
      KR = KEYOUTCR(I,J,K)

      IF ((KR.EQ.1).OR.(KR.EQ.2)) THEN
      IF ((VOLDIM(I,J,K).GT.0).AND.(FACEDIM(I,J,K).GT.0)) THEN

         VPROP(:) = VOLPROP(I,J,K,:)
         FPROP(:) = FACEPROP(I,J,K,:)
         CALL GETCORNERLOCAL(PN,I,J,K,PRES,IDIM,JDIM,KDIM,VPROP)
         CALL GETCORNERLOCAL(RHON,I,J,K,FLDEN,IDIM,JDIM,KDIM,VPROP)

! bag8
         CALL GETCORNERPINV(PINV,I,J,K,PERMINV,IDIM,JDIM,KDIM,VPROP)
         CALL GETCORNERHEX(X,I,J,K,XC,YC,ZC,IDIM,JDIM,KDIM,VPROP)

! bag8: todo - remove i,j,k from getmatrhs and pass pinv, x instead

         CALL GETMATRHS(COF,RESID,TRAN(1,1,I,J,K),
     &                AINV(1,1,I,J,K),AINVF(1,I,J,K),
     &                I,J,K,PN,PCN,RHON,PERMINV,VOLDIM(I,J,K),
     &                VPROP,FACEDIM(I,J,K),FPROP,IDIM,JDIM,
     &                KDIM,XC,YC,ZC,NBLK,UPMOBPROD,NC,NPH,NCINPH,
     &                ICINPH)

      ENDIF
      ENDIF

 200  CONTINUE

cgp dbg
      IF (DBG) THEN
        WRITE(0,*)
        WRITE(0,'(2(A,I2),A)')'------------- NSTEP ',NSTEP,' NEWT',NEWT,
     &                        ': TTRAN -------------'
c        PAUSE
        DO K = KL1,KL2
        DO J = JL1V(K),JL2V(K)
        DO I = IL1,IL2
           IF (KEYOUT(I,J,K)==0) CYCLE
           WRITE(0,'(A,3I3,3X,E23.15)')'I,J,K,RESID',I,J,K,RESID(I,J,K)
           WRITE(0,*)'COF',COF(I,J,K,-13:13)
c           PAUSE
        ENDDO
        ENDDO
        ENDDO
        PAUSE
      ENDIF
cgp dbg

      RETURN

      END
C*********************************************************************
      SUBROUTINE TUPPRES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &              KL1,KL2,KEYOUT,NBLK,DUNK,PRES)
C*********************************************************************

C  Single phse flow model: update pressure

C  DUNK(I,J,K) = LINEAR SOLUTION (INPUT, REAL*8)

C  PRES(I,J,K) = FLUID PRESSURE, PSI (INPUT AND OUTPUT, REAL*8)
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'layout.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK

      REAL*8 PRES(IDIM,JDIM,KDIM)
      REAL*8 DUNK(IDIM,JDIM,KDIM,1)
      INTEGER I,J,K

cgp dbg
      INCLUDE 'control.h'
      LOGICAL DBG
      DATA DBG /.FALSE./

! bag8 debug
!      I=40+ILAY
!      J=20+JLAY
!      K=1+KLAY
!      WRITE(*,*)'In TUPPRES, I,J,K=',I,J,K
!      WRITE(*,*)'PRES (old) = ',PRES(I,J,K)
!      WRITE(*,*)'DUNK       = ',DUNK(I,J,K,1)
!      WRITE(*,*)'PRES (new) = ',PRES(I,J,K)+DUNK(I,J,K,1)

      IF (DBG) THEN
        WRITE(0,*)
        WRITE(0,'(2(A,I2),A)')'------------- NSTEP ',NSTEP,' NEWT',NEWT,
     &                        ': TUPPRES -------------'
c         PAUSE
      ENDIF
cgp dbg

      DO K = KL1,KL2
       DO J = JL1V(K),JL2V(K)
        DO I = IL1,IL2
         IF(KEYOUT(I,J,K).EQ.1) THEN
cgp dbg
            IF (DBG) THEN
               WRITE(0,'(A,3I3,3(3X,A,E23.15))')'I,J,K',I,J,K,
     &                 'PRES',PRES(I,J,K),'DUNK',DUNK(I,J,K,1),
     &                 'PRES+',PRES(I,J,K)+DUNK(I,J,K,1)
            ENDIF
cgp dbg
            PRES(I,J,K) = PRES(I,J,K) + DUNK(I,J,K,1)
         ENDIF
        ENDDO
       ENDDO
      ENDDO
      IF (DBG) PAUSE

      END
C***********************************************************************
      SUBROUTINE TMAXRESID (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                 KL2,KEYOUT,NBLK,RESID)
C*********************************************************************

C  ROUTINE PICKS OUT LOCAL MAXIMUM RESIDUALS AND TOTALS RESIDUALS.
C  THIS IS A WORK ROUTINE.

C  RESID(I,J,K)= RESIDUALS (INPUT, REAL*8)

C  NOTE:  RESULTS ARE PUT IN COMMON /TBALDAT/
C***********************************************************************
      IMPLICIT NONE

      INCLUDE 'tbaldat.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK

      REAL*8 RESID(IDIM,JDIM,KDIM),R

      INTEGER I,J,K,JL1,JL2

      DO 1 K=KL1,KL2
      JL1=JL1V(K)
      JL2=JL2V(K)
      DO 1 J=JL1,JL2
      DO 1 I=IL1,IL2
      IF (KEYOUT(I,J,K).EQ.1) THEN
         R=RESID(I,J,K)
         RESIDT=RESIDT+R
         IF (ABS(R).GT.RESIDM) THEN
            IRM1=I
            JRM1=J
            KRM1=K
            RMA1=R
            RESIDM=ABS(R)
         ENDIF
      ENDIF
    1 CONTINUE

      END
C*******************************************************************
      SUBROUTINE TBUGOUT (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
     &           KEYOUT,NBLK,POR,PRES,FLDEN,COF,RESID)
C*********************************************************************

C  ROUTINE OUTPUT DEBUG DATA.  THIS IS A WORK ROUTINE.

C  POR(I,J,K)   = PORE VOLUME (INPUT, REAL*8)
C  PRES(I,J,K)  = FLUID PRESSURE, PSI (INPUT, REAL*8)
C  FLDEN(I,J,K) = FLUID DENSITY, LB/CU-FT (INPUT, REAL*8)
C  COF(I,J,K,N) = MATRIX COEFFICIENTS (INPUT, REAL*8)
C  RESID(I,J,K) = RESIDUALS (INPUT, REAL*8)

C***********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'rock.h'
      INCLUDE 'wells.h'
      INCLUDE 'layout.h'

      INCLUDE 'tfluidsc.h'
      INCLUDE 'tbaldat.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK

      REAL*8 COF(IDIM,JDIM,KDIM,-13:13), POR(IDIM,JDIM,KDIM)
      REAL*8 FLDEN(IDIM,JDIM,KDIM), PRES(IDIM,JDIM,KDIM)
      REAL*8 RESID(IDIM,JDIM,KDIM)

      INTEGER IOFF,JOFF,KOFF,IERR,IO,KO,JO,LL,L
c------------------------------------------------------------

      CALL OPENBUG()
      IF (.NOT.BUGOPEN) RETURN

      WRITE (NFBUG,1) TIM,DELTIM,CURRENT
    1 FORMAT(/' DEBUG OUTPUT AT TIME =',F10.4,', DELTIM =',F10.5/
     & ' TOTAL WATER =',G16.8)

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,IERR)

      WRITE(NFBUG,16) IL1,IL2,JL1V(KL2),JL2V(KL2),KL1,KL2,IOFF,JOFF,KOFF
   16 FORMAT(' PROC 0: IL1',I4,', IL2',I4,', JL1(KL2)',I4,', JL2(KL2)',
     & I4,', KL1',I4,', KL2',I4/' IOFF',I4,', JOFF',I4,', KOFF',I4)

      IO=(IL1+IL2)/2

      DO 10 LL=1,3
      IF (LL.EQ.1) THEN
         KO=KL1
         JO=JL1V(KO)
      ELSE
         IF (LL.EQ.2) THEN
            KO=(KL1+KL2)/2
            IF (NUMPRC.EQ.1) THEN
               JO=(JL1V(KO)+JL2V(KO))/2
            ELSE
               JO=JL2V(KO)
            ENDIF
         ELSE
            KO=KL2
            JO=JL2V(KO)
         ENDIF
      ENDIF
      IF (KEYOUT(IO,JO,KO).NE.1) GO TO 10

      WRITE (NFBUG,11) IO+IOFF,JO+JOFF,KO+KOFF
   11 FORMAT(/' I LOCATION=',I5,', J LOCATION =',I5,', K LOCATION =',I5)

      DO L=-13,13

      WRITE (NFBUG,3) L,COF(IO,JO,KO,L)
    3  FORMAT (' COF(I,J,K,',I2,')',T22,G16.7)
      ENDDO

      WRITE (NFBUG,5) RESID(IO,JO,KO)
    5 FORMAT (' RESID(I,J,K)',T22,G17.9)

      WRITE (NFBUG,14) PRES(IO,JO,KO)
   14 FORMAT (' PRES(I,J,K)',T22,G17.9)

   10 CONTINUE

      END

C********************************************************************
      SUBROUTINE TVEL_EX(INP)
C********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
        INCLUDE 'blkary.h'
        INCLUDE 'tarydat.h'
        INCLUDE 'mpfaary.h'

CGUS
C INP = 0 RT0 VELOCITY STORAGE ((IDIM+1)*(JDIM+1)*(KDIM+1))
C     = 1 EBDDF1 VELOCITY STORAGE (64*(IDIM+1)*(JDIM+1)*(KDIM+1))
C
      LOGICAL ONCEONLY
      DATA ONCEONLY /.TRUE./
      INTEGER IVEL(10)
      DATA  IVEL /10*0/
      EXTERNAL TVELCOMP
      INTEGER INP

      IF(ONCEONLY) THEN
         ONCEONLY = .FALSE.
         IVEL(1) = 9
         IVEL(2) = N_TRAN
         IVEL(3) = N_AINVF
         IVEL(4) = N_PRES
         IVEL(5) = N_VPROP
         IVEL(6) = N_FPROP
         IVEL(7) = N_VDIM
         IVEL(8) = N_FDIM
         IVEL(9) = N_KCR
      ENDIF

      IF (INP==0) THEN
        IVEL(10)  = N_VEL
        CALL CALLWORK(TVELCOMP,IVEL)
      ELSE
CGUS NOT OPERATIONAL YET
C        IVEL(10)  = N_MP_VEL
C        CALL CALLWORK(TVELCOMP_MP,IVEL)
      ENDIF

      END

C********************************************************************
      SUBROUTINE TVELCOMP (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                KL2,KEYOUT,NBLK,TRAN,AINVF,PRES,VOLPROP,FACEPROP,
     &                VOLDIM,FACEDIM,KEYOUTCR,VEL)
C********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),KL1
     &       ,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK
     &       ,VOLPROP(IDIM+1,JDIM+1,KDIM+1,8)
     &       ,FACEPROP(IDIM+1,JDIM+1,KDIM+1,12)
     &       ,VOLDIM(IDIM+1,JDIM+1,KDIM+1)
     &       ,FACEDIM(IDIM+1,JDIM+1,KDIM+1)
     &       ,KEYOUTCR(IDIM+1,JDIM+1,KDIM+1)

      REAL*8 TRAN(12,8,IDIM+1,JDIM+1,KDIM+1)
     &      ,AINVF(12,IDIM+1,JDIM+1,KDIM+1),PRES(IDIM,JDIM,KDIM)
     &      ,VEL(IDIM,JDIM,KDIM,3)

      INTEGER I,J,K,VPROP(8),FPROP(12),KR

      REAL*8 P(8)

      VEL = 0.D0

      DO K = KL1,KL2+1
      DO J = 1,JDIM+1
      DO I = IL1,IL2+1

         KR = KEYOUTCR(I,J,K)
         IF (KR==1.OR.KR==2) THEN

           VPROP = VOLPROP(I,J,K,:)
           FPROP = FACEPROP(I,J,K,:)

           CALL GETCORNERLOCAL(P,I,J,K,PRES,IDIM,JDIM,KDIM,VPROP)

           CALL VELLOCALUPDATE(VEL(1,1,1,1),VEL(1,1,1,2),VEL(1,1,1,3)
     &                ,I,J,K,TRAN(1,1,I,J,K),AINVF(1,I,J,K),P,VPROP
     &                ,VOLDIM(I,J,K),FPROP,FACEDIM(I,J,K),IDIM,JDIM
     &                ,KDIM,KEYOUT)
         ENDIF

      ENDDO
      ENDDO
      ENDDO

      RETURN
      END



ctm   TAMEEM
c======================================================================
      SUBROUTINE GSAVE_OLDTIMP_MR(NERR)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'tarydat.h'
C
      INTEGER NERR,ISAVE1(7)
      LOGICAL ONCEONLY
      EXTERNAL CALC_GSAVE_OLDTIM1
      INTEGER FRAC,DUM,IDIM,JDIM,KDIM

      DATA ISAVE1/7*0/,ONCEONLY/.TRUE./

      IF(ONCEONLY) THEN
         ONCEONLY=.FALSE.
         ISAVE1(1) = 6
         ISAVE1(2) = N_FLDEN
         ISAVE1(3) = N_FLDEN3
         ISAVE1(4) = N_PRES
         ISAVE1(5) = N_PRESN3
         ISAVE1(6) = N_PV
         ISAVE1(7) = N_PVN3
      ENDIF


      CALL CALLWORK(CALC_GSAVE_OLDTIM1,ISAVE1)

      RETURN
      END
ctm   TAMEEM

ctm   TAMEEM

c======================================================================
      SUBROUTINE CALC_GSAVE_OLDTIM1 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &               JL1V,JL2V, KL1,KL2,KEYOUT,NBLK,FLDEN,FLDEN3,
     &               PRES,PRESN3,PV,PVN3)
c======================================================================
      IMPLICIT NONE
C
C
C   SAVE DATA AT OLD PRESSURE TIME STEP
C
C
      INTEGER IDIM, JDIM, KDIM, LDIM, NBLK
      INTEGER I, J, K, IL1, IL2,KL1, KL2, JL1, JL2
      INTEGER  JL1V(KDIM),JL2V(KDIM),    KEYOUT(IDIM,JDIM,KDIM)
C
      REAL*8 FLDEN(IDIM,JDIM,KDIM), FLDEN3(IDIM,JDIM,KDIM)
      REAL*8 PRES(IDIM,JDIM,KDIM), PRESN3(IDIM,JDIM,KDIM)
      REAL*8 PV(IDIM,JDIM,KDIM),   PVN3(IDIM,JDIM,KDIM)
C

c      WRITE(*,*), 'IN CALC_GSAVE_OLDTIMP_MR - 1'
c      DO 100 K=1,KDIM
c      DO 100 J=1,JDIM
c      DO 100 I=1,IDIM

      DO K = KL1,KL2
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2
            DO I = IL1,IL2
               IF(KEYOUT(I,J,K).EQ.1) THEN

!bw      IF (KEYOUT(I,J,K).EQ.0) CYCLE
c         WRITE(*,*), 'IN CALC_GSAVE_OLDTIMP_MR - 2'
                   FLDEN3(I,J,K) = FLDEN(I,J,K)
                   PRESN3(I,J,K) = PRES(I,J,K)
                   PVN3(I,J,K) = PV(I,J,K)

               ENDIF
            ENDDO
         ENDDO
      ENDDO

c  100 CONTINUE

      RETURN
      END

cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ctm   TAMEEM


ctm   TAMEEM
c Retrieve old values before multirate loop ..
c======================================================================
      SUBROUTINE RET_OLDTIMP_MR(NERR)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'tarydat.h'
C
      INTEGER NERR,ISAVE(7)
      LOGICAL ONCEONLY
      EXTERNAL CALC_GSAVE_OLDTIMP
      INTEGER FRAC,DUM,IDIM,JDIM,KDIM

      DATA ISAVE/7*0/,ONCEONLY/.TRUE./

      IF(ONCEONLY) THEN
         ONCEONLY=.FALSE.
         ISAVE(1) = 6
         ISAVE(2) = N_FLDEN3
         ISAVE(3) = N_FLDENN
         ISAVE(4) = N_PRESN3
         ISAVE(5) = N_PRESN
         ISAVE(6) = N_PVN3
         ISAVE(7) = N_PVN
      ENDIF

      CALL CALLWORK(CALC_GSAVE_OLDTIMP,ISAVE)

      RETURN
      END
ctm   TAMEEM

ctm   TAMEEM
c======================================================================
      SUBROUTINE CALC_GSAVE_OLDTIMP (IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &              JL1V,JL2V, KL1,KL2,KEYOUT,NBLK,FLDEN3,FLDENN,
     &              PRESN3,PRESN,PVN3,PVN)
c======================================================================
      IMPLICIT NONE
C
C
C   SAVE DATA AT OLD PRESSURE TIME STEP
C
      INTEGER IDIM, JDIM, KDIM, LDIM, NBLK
      INTEGER I, J, K, IL1, IL2,KL1, KL2, JL1, JL2
      INTEGER  JL1V(KDIM),JL2V(KDIM),    KEYOUT(IDIM,JDIM,KDIM)
C
      REAL*8 FLDEN3(IDIM,JDIM,KDIM), FLDENN(IDIM,JDIM,KDIM)
      REAL*8 PRESN3(IDIM,JDIM,KDIM), PRESN(IDIM,JDIM,KDIM)
      REAL*8 PVN3(IDIM,JDIM,KDIM),   PVN(IDIM,JDIM,KDIM)

      DO K = KL1,KL2
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2
            DO I = IL1,IL2
               IF(KEYOUT(I,J,K).EQ.1) THEN
                 FLDENN(I,J,K) = FLDEN3(I,J,K)
                 PRESN(I,J,K) = PRESN3(I,J,K)
                 PVN(I,J,K) = PVN3(I,J,K)
              ENDIF
            ENDDO
         ENDDO
      ENDDO


      RETURN
      END
ctm   TAMEEM

ctm   TAMEEM
c routines for calculating the norms

c======================================================================
c      SUBROUTINE GSAVE_FOR_MULTIRATE(GCITER, M_ITER, NERR)
       SUBROUTINE GSAVE_FOR_MULTIRATE(NERR)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'tarydat.h'
      INCLUDE 'earydat.h'
      INCLUDE 'control.h'
      INCLUDE 'blkary.h'
C
      INTEGER NERR,ISAVE(6)
      LOGICAL ONCEONLY
      EXTERNAL CALC_GSAVE_MULTIRATE
      INTEGER FRAC,DUM,IDIM,JDIM,KDIM
c      INTEGER GCITER, M_ITER

      DATA ISAVE/6*0/,ONCEONLY/.TRUE./

      IF(ONCEONLY) THEN
         ONCEONLY=.FALSE.
         ISAVE(1) = 5
         ISAVE(2) = N_PRESN_NM1
         ISAVE(3) = N_PRESN_N1
         ISAVE(4) = N_PRES
         ISAVE(5) = N_VSTRAIN
         ISAVE(6) = N_VSTRAIN_NM1
c         ISAVE(7) = N_I4U
c         ISAVE(8) = N_I4U1
      ENDIF

c      I4UTIL = GCITER
c      I4UTIL1 = M_ITER
      CALL CALLWORK(CALC_GSAVE_MULTIRATE,ISAVE)

      RETURN
      END
ctm   TAMEEM

ctm   TAMEEM
c======================================================================
      SUBROUTINE CALC_GSAVE_MULTIRATE (IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &                JL1V,JL2V, KL1,KL2,KEYOUT,NBLK,PRESN_NM1,
     &                PRESN_N1, PRES,VSTRAIN, VSTRAIN_NM1)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'control.h'
C
C
C
C
      INTEGER IDIM, JDIM, KDIM, LDIM, NBLK
      INTEGER I, J, K, IL1, IL2,KL1, KL2
      INTEGER  JL1V(KDIM),JL2V(KDIM),    KEYOUT(IDIM,JDIM,KDIM)
C
      REAL*8 PRESN_NM1(IDIM,JDIM,KDIM,Q_MULTIRATE)
      REAL*8 PRESN_N1(IDIM,JDIM,KDIM,Q_MULTIRATE)
      REAL*8 PRES(IDIM,JDIM,KDIM)
      REAL*8 VSTRAIN(IDIM,JDIM,KDIM)
      REAL*8 VSTRAIN_NM1(IDIM,JDIM,KDIM)
      INTEGER JL1, JL2, I1, I2, I3


      IF(GCITER_C.EQ.0.AND.M_ITER.EQ.1)  THEN
c     first iterative coupling iteration
c     also, first local flow iteration
        DO I3 = KL1,KL2
           JL1 = JL1V(I3)
           JL2 = JL2V(I3)
           DO I2 = JL1,JL2
              DO I1 = IL1,IL2
                 IF(KEYOUT(I1,I2,I3).EQ.1) THEN
                    VSTRAIN_NM1(I1,I2,I3) = VSTRAIN(I1,I2,I3)
                 ENDIF
              ENDDO
           ENDDO
        ENDDO

      ENDIF

      IF(GCITER_C.EQ.0) THEN
c     first iterative coupling iteration

          DO K = KL1,KL2
            JL1 = JL1V(K)
            JL2 = JL2V(K)
            DO J = JL1,JL2
               DO I = IL1,IL2
                  IF(KEYOUT(I,J,K).EQ.1) THEN
                      PRESN_NM1(I,J,K, M_ITER) = PRES(I,J,K)
                  ENDIF
               ENDDO
            ENDDO
          ENDDO


      ELSE
c     subsequent iterative coupling iterations

          DO K = KL1,KL2
             JL1 = JL1V(K)
             JL2 = JL2V(K)
             DO J = JL1,JL2
               DO I = IL1,IL2
                 IF(KEYOUT(I,J,K).EQ.1) THEN
                    PRESN_N1(I,J,K, M_ITER) = PRES(I,J,K)
                 ENDIF
               ENDDO
             ENDDO
          ENDDO


      ENDIF

      RETURN
      END

ctm   TAMEEM

ctm   TAMEEM

c======================================================================
      SUBROUTINE COMPUTE_KONVG_NORM(NERR)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'tarydat.h'
      INCLUDE 'earydat.h'
      INCLUDE 'control.h'
      INCLUDE 'blkary.h'
C
      INTEGER NERR,ISAVE(11)
      LOGICAL ONCEONLY
      EXTERNAL CALC_KONVG_N_AUX
      INTEGER FRAC,DUM,IDIM,JDIM,KDIM

      DATA ISAVE/11*0/,ONCEONLY/.TRUE./

      IF(ONCEONLY) THEN
         ONCEONLY=.FALSE.
         ISAVE(1) = 10
         ISAVE(2) = N_PRESN_NM1
         ISAVE(3) = N_PRESN_N1
         ISAVE(4) = N_VSTRAIN
         ISAVE(5) = N_VSTRAIN_NM1
         ISAVE(6) = N_BIOTA
         ISAVE(7) = N_EVOL
         ISAVE(8) = N_PRES
         ISAVE(9) = N_POR
         ISAVE(10) = N_MODUL
         ISAVE(11) = N_POISS
      ENDIF

      CALL CALLWORK(CALC_KONVG_N_AUX,ISAVE)

      RETURN
      END
ctm   TAMEEM


ctm   TAMEEM
c======================================================================
      SUBROUTINE CALC_KONVG_N_AUX (IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &                JL1V,JL2V, KL1,KL2,KEYOUT,NBLK,PRESN_NM1,
     &                PRESN_N1, VSTRAIN, VSTRAIN_NM1, BIOTA, EVOL,
     &                PRES, POR, MODUL, POISS)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'control.h'
C
C
C
C
      INTEGER IDIM, JDIM, KDIM, LDIM, NBLK
      INTEGER I, J, K, IL1, IL2,KL1, KL2
      INTEGER  JL1V(KDIM),JL2V(KDIM),    KEYOUT(IDIM,JDIM,KDIM)
C
      REAL*8 PRESN_NM1(IDIM,JDIM,KDIM,Q_MULTIRATE)
      REAL*8 PRESN_N1(IDIM,JDIM,KDIM,Q_MULTIRATE)
      REAL*8 PRES(IDIM,JDIM,KDIM)
      REAL*8 VSTRAIN(IDIM,JDIM,KDIM)
      REAL*8 VSTRAIN_NM1(IDIM,JDIM,KDIM)
      REAL*8 BIOTA(IDIM,JDIM,KDIM)
      REAL*8 EVOL(IDIM,JDIM,KDIM)
      REAL*8 POR(IDIM,JDIM,KDIM)
      REAL*8 MODUL(IDIM,JDIM,KDIM)
      REAL*8 POISS(IDIM,JDIM,KDIM)
      REAL*8 LAMBDA(IDIM,JDIM,KDIM)
      REAL*8 term1, term2, term3, comp_norm
      REAL*8 DIFF, DIFF1, DIFF2, X, V1, V2
      INTEGER q
      INTEGER JL1, JL2, I1, I2, I3, ITER

c  Computing the lame constant LAMBDA
c  This is essentially the same calculation as what
c  was done in eidata.df

      q = Q_MULTIRATE
c
      term1 = 0.0
      term2 = 0.0
      term3 = 0.0
      DIFF = 0.0
      DIFF1 = 0.0
      DIFF2 = 0.0
      comp_norm = 0.0

      DO K = KL1,KL2
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2
            DO I = IL1,IL2
               IF(KEYOUT(I,J,K).EQ.1) THEN

                  IF(POR(I,J,K).GT.0.D0) THEN
                    V1 = MODUL(I,J,K)
                    V2 = POISS(I,J,K)
                    X = 1.0D0 - 2.0D0 * V2
                    IF(X.GE.0.D0) THEN
                       LAMBDA(I,J,K) = V2 * V1 / ((1.0D0 + V2)* X)
                    ELSE
                       LAMBDA(I,J,K) = 1.0D15
                    ENDIF
                  ELSE
                    LAMBDA(I,J,K) = 0.D0
                  ENDIF
               ENDIF
            ENDDO
         ENDDO
      ENDDO
c



c The last finter flow time step needs this correction ..

      DO K = KL1,KL2
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2
            DO I = IL1,IL2
               IF(KEYOUT(I,J,K).EQ.1) THEN
                  PRESN_N1(I,J,K,q) = PRES(I,J,K)
               ENDIF
            ENDDO
         ENDDO
      ENDDO


c computing first term:

      DO I3 = KL1,KL2
         JL1 = JL1V(I3)
         JL2 = JL2V(I3)
         DO I2 = JL1,JL2
            DO I1 = IL1,IL2
               IF(KEYOUT(I1,I2,I3).EQ.1) THEN
                  DIFF = VSTRAIN(I1,I2,I3) - VSTRAIN_NM1(I1,I2,I3)
                  DIFF = DIFF * DIFF
                  DIFF = DIFF * EVOL(I1,I2,I3)
                  DIFF = DIFF * LAMBDA(I1,I2,I3)*LAMBDA(I1,I2,I3)
                  DIFF = DIFF / q
                  term1 = term1 + DIFF
               ENDIF
            ENDDO
         ENDDO
      ENDDO

c computing second term:

      DO ITER = 1,q
        DO I3 = KL1,KL2
           JL1 = JL1V(I3)
           JL2 = JL2V(I3)
           DO I2 = JL1,JL2
              DO I1 = IL1,IL2
                 IF(KEYOUT(I1,I2,I3).EQ.1) THEN
                    DIFF1 = PRESN_N1(I1,I2,I3,ITER)
                    DIFF1 = DIFF1 - PRESN_NM1(I1,I2,I3,ITER)
                    DIFF2 = 0.0
                    IF(ITER.GT.1) THEN
                      DIFF2 = PRESN_N1(I1,I2,I3,ITER-1)
                      DIFF2 = DIFF2 - PRESN_NM1(I1,I2,I3,ITER-1)
                    ENDIF
                    DIFF = DIFF1 - DIFF2
                    DIFF1 = VSTRAIN(I1,I2,I3)-VSTRAIN_NM1(I1,I2,I3)
                    DIFF = DIFF * DIFF1
                    DIFF = DIFF * EVOL(I1,I2,I3)
                    DIFF = DIFF * BIOTA(I1,I2,I3)
                    DIFF = DIFF * 2 * GAMMA_C * LAMBDA(I1,I2,I3)
                    DIFF = DIFF / q
                    term2 = term2 + DIFF
                 ENDIF
              ENDDO
           ENDDO
        ENDDO
      ENDDO

c computing third term:

      DO ITER = 1,q
        DO I3 = KL1,KL2
           JL1 = JL1V(I3)
           JL2 = JL2V(I3)
           DO I2 = JL1,JL2
              DO I1 = IL1,IL2
                 IF(KEYOUT(I1,I2,I3).EQ.1) THEN
                    DIFF1 = PRESN_N1(I1,I2,I3,ITER)
                    DIFF1 = DIFF1 - PRESN_NM1(I1,I2,I3,ITER)
                    DIFF2 = 0.0
                    IF(ITER.GT.1) THEN
                      DIFF2 = PRESN_N1(I1,I2,I3,ITER-1)
                      DIFF2 = DIFF2 - PRESN_NM1(I1,I2,I3,ITER-1)
                    ENDIF
                    DIFF = DIFF1 - DIFF2
                    DIFF = DIFF * DIFF
                    DIFF = DIFF * EVOL(I1,I2,I3)
                    DIFF = DIFF * BIOTA(I1,I2,I3)*BIOTA(I1,I2,I3)
                    DIFF = DIFF * GAMMA_C * GAMMA_C
                    term3 = term3 + DIFF
                 ENDIF
              ENDDO
           ENDDO
        ENDDO
      ENDDO

      comp_norm = term1 - term2 + term3
      WRITE(*,*) 'COMP_NORM  ', comp_norm

c  update values for next iterative coupling iteration:

      DO I3 = KL1,KL2
         JL1 = JL1V(I3)
         JL2 = JL2V(I3)
         DO I2 = JL1,JL2
            DO I1 = IL1,IL2
               IF(KEYOUT(I1,I2,I3).EQ.1) THEN
                  VSTRAIN_NM1(I1,I2,I3) = VSTRAIN(I1,I2,I3)
               ENDIF
            ENDDO
         ENDDO
      ENDDO


      DO ITER = 1,q
        DO K = KL1,KL2
           JL1 = JL1V(K)
           JL2 = JL2V(K)
           DO J = JL1,JL2
              DO I = IL1,IL2
                 IF(KEYOUT(I,J,K).EQ.1) THEN
                    PRESN_NM1(I,J,K,ITER) = PRESN_N1(I,J,K,ITER)
                 ENDIF
              ENDDO
           ENDDO
        ENDDO
      ENDDO

      RETURN
      END

ctm   TAMEEM

ctm   TAMEEM
c======================================================================
      SUBROUTINE GSAVE_OLDTIMP(NERR)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'tarydat.h'
C
      INTEGER NERR,ISAVE(7)
      LOGICAL ONCEONLY
      EXTERNAL CALC_GSAVE_OLDTIMP4
      INTEGER FRAC,DUM,IDIM,JDIM,KDIM

      DATA ISAVE/7*0/,ONCEONLY/.TRUE./

      IF(ONCEONLY) THEN
         ONCEONLY=.FALSE.
         ISAVE(1) = 10
         ISAVE(2) = N_FLDEN
         ISAVE(3) = N_FLDENN
         ISAVE(4) = N_PRES
         ISAVE(5) = N_PRESN
         ISAVE(6) = N_PV
         ISAVE(7) = N_PVN
      ENDIF

      CALL CALLWORK(CALC_GSAVE_OLDTIMP4,ISAVE)

      RETURN
      END

ctm   TAMEEM

ctm   TAMEEM
c======================================================================
      SUBROUTINE CALC_GSAVE_OLDTIMP4 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &              JL1V,JL2V, KL1,KL2,KEYOUT,NBLK,FLDEN,FLDENN,
     &              PRES,PRESN,PV,PVN)
c======================================================================
      IMPLICIT NONE
C
C
C   SAVE DATA AT OLD PRESSURE TIME STEP
C
      INTEGER IDIM, JDIM, KDIM, LDIM, NBLK
      INTEGER I, J, K, IL1, IL2,KL1, KL2, JL1, JL2
      INTEGER  JL1V(KDIM),JL2V(KDIM),    KEYOUT(IDIM,JDIM,KDIM)
C
      REAL*8 FLDEN(IDIM,JDIM,KDIM), FLDENN(IDIM,JDIM,KDIM)
      REAL*8 PRES(IDIM,JDIM,KDIM), PRESN(IDIM,JDIM,KDIM)
      REAL*8 PV(IDIM,JDIM,KDIM),   PVN(IDIM,JDIM,KDIM)
C

      DO K = KL1,KL2
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2
            DO I = IL1,IL2
               IF(KEYOUT(I,J,K).EQ.1) THEN
                   FLDENN(I,J,K) = FLDEN(I,J,K)
                   PRESN(I,J,K) = PRES(I,J,K)
                   PVN(I,J,K) = PV(I,J,K)
               ENDIF
            ENDDO
         ENDDO
      ENDDO


      RETURN
      END
ctm   TAMEEM



