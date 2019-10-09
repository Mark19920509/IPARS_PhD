C============================================================
      MODULE eprojmod
      IMPLICIT NONE
      SAVE
      INTEGER, ALLOCATABLE :: VAL1(:),VAL3(:),SKIP(:),INFLAG(:)
      INTEGER, ALLOCATABLE :: VAL2(:,:),VAL4(:,:)
      REAL*8, ALLOCATABLE :: VOL1(:,:),VOL2(:,:),POINT(:,:)
      INTEGER :: NMECHELE,NFLOWELE
      INTEGER :: MXINTPOINT = 6*6*6*6*4
      INTEGER :: MXINTBIG = 25000
      INTEGER :: MXINTSMALL = 2000

      END

C*********************************************************************
      SUBROUTINE GETNUMELE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &     KL2,KEYOUT,NBLK,I4U)
C*********************************************************************
      USE eprojmod
      IMPLICIT NONE
      INCLUDE 'layout.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER IERR,I4U
      I4U = IDIM*JDIM*KDIM
      END

C============================================================
      SUBROUTINE PROJECTION_OPERATORS(NERR)
C============================================================
      USE eprojmod
      IMPLICIT NONE
      include 'blkary.h'
      include 'control.h'

      INTEGER COPYARG(4)
      DATA COPYARG / 4*0/
      INTEGER NERR,IERR
      EXTERNAL GETPROJECTORS
      EXTERNAL GETL2PROJECTORS
      EXTERNAL GETNUMELE

      MODACT = 15
      CALL CALLWORK(GETNUMELE,[1,N_I4U])
      NMECHELE = I4UTIL
      MODACT = 17
      CALL CALLWORK(GETNUMELE,[1,N_I4U])
      NFLOWELE = MAX(I4UTIL,1)
C      MODACT = 16
C      CALL CALLWORK(GETNUMELE,[1,N_I4U])
C      NFLOWELE = MAX(I4UTIL,1)

       MODACT = 0

       ALLOCATE(VAL1(NMECHELE),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate VAL1'
       ALLOCATE(SKIP(NMECHELE),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate SKPI'
       ALLOCATE(VAL3(NFLOWELE),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate VAL3'
       ALLOCATE(INFLAG(NFLOWELE),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate INFLAG'
       ALLOCATE(VAL2(MXINTBIG,MXINTSMALL),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate VAL2'
       ALLOCATE(VOL1(MXINTBIG,MXINTSMALL),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate VOL1'
       ALLOCATE(VAL4(MXINTBIG,MXINTSMALL),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate VAL4'
       ALLOCATE(VOL2(MXINTBIG,MXINTSMALL),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate VOL2'
       ALLOCATE(POINT(MXINTPOINT,3),STAT=IERR)
       IF (IERR.NE.0) STOP 'Could not allocate POINT'

! saumik - # of flow elements either intersecting or inside
!          a mechanics element
      VAL1 = 0

! saumik - location of those flow elements
      VAL2 = 0

! saumik - # of mechanics elements intersecting a flow element
      VAL3 = 0

! saumik - location of those mechanics elements
      VAL4 = 0

! saumik - store entire volume if flow element is inside mechanics element
!          store intersection volume if flow element intersects
!          mechanics element
      VOL1 = 0.D0

! saumik - store intersection volume if mechanics element intersects
!          flow element
      VOL2 = 0.D0

! saumik - skip=0 for porohex elements involved in projections
      SKIP = 1

      COPYARG(1)=3
      COPYARG(2)=N_XC
      COPYARG(3)=N_YC
      COPYARG(4)=N_ZC

      CALL PROJECTIONS(GETPROJECTORS,COPYARG)

      END

C=======================================================================
      SUBROUTINE GETPROJECTORS (IDIMP,JDIMP,KDIMP,IL1P,IL2P,JL1VP,JL2VP,
     &                          KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &                          IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,
     &                          XC_P,YC_P,ZC_P,XC_F,YC_F,ZC_F,NBLK)
C=======================================================================
      USE eprojmod
      IMPLICIT NONE
      include 'control.h'
      include 'blkary.h'
      include 'mpif.h'
      include 'emodel.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)

      INTEGER KF,JF,IFL,KP,JP,IP

      REAL*8 XP(3,8),XF(3,8),VOLH,CHECK,TETVOLUME
      LOGICAL INSIDE,INTERSECT,OUTSIDE,ONCEONLY
      INTEGER IOFFP,JOFFP,KOFFP,IOFF,JOFF,KOFF,NERR,LOCP,LOCF
      INTEGER I,J,K,IIP,JJP,KKP,IIF,JJF,KKF,COUNTP,COUNTF,R
      REAL*8 XPMAX(3),XPMIN(3),XFMAX(3),XFMIN(3),TOL
      DATA TOL /1.D-3/

      CALL BLKOFF(1,IOFFP,JOFFP,KOFFP,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

C     -----------------
C     FLOW TO MECHANICS
C     -----------------

      COUNTP = 0
      DO KP = KL1P,KL2P
         DO JP = JL1VP(KP),JL2VP(KP)
            DO IP = IL1P,IL2P
               IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
               IIP = IP + IOFFP - 1
               JJP = JP + JOFFP - 1
               KKP = KP + KOFFP - 1
               IF((IIP+1).LE.OB_LAYER.OR.(IIP+1).GE.UB_LAYER) CYCLE
! saumik - porohex element location
!               LOCP = (IIP+1-OB_LAYER)*NZDIM(1)*NYDIM(1)+KKP*NYDIM(1)
!     &                +JJP+1
               LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP
               COUNTF = 0
               ONCEONLY = .TRUE.
               CHECK = 0.D0
               DO KF = KL1F,KL2F
                  DO JF = JL1VF(KF),JL2VF(KF)
                     DO IFL = IL1F,IL2F
                        IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
                        IIF = IFL + IOFF - 1
                        JJF = JF  + JOFF - 1
                        KKF = KF  + KOFF - 1
! saumik - flow element location
!                        LOCF = IIF*NZDIM(NBLK)*NYDIM(NBLK)+
!     &                         KKF*NYDIM(NBLK)+JJF+1
                        LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF

! saumik - xp(3,8) - coordinate information for porohex element
                        CALL GETX(XC_P,YC_P,ZC_P,XP,IDIMP,JDIMP,KDIMP,
     &                            IP,JP,KP)
! saumik - xf(3,8) - coordinate information for flow element
                        CALL GETX(XC_F,YC_F,ZC_F,XF,IDIMF,JDIMF,KDIMF,
     &                            IFL,JF,KF)

! saumik - determine if flow element is inside, outside
!          or intersecting the porohex element
                        CALL INOROUT(XP,XF,INSIDE,INTERSECT,
     &                               OUTSIDE,LOCP,LOCF,XFMIN,XFMAX,
     &                               XPMIN,XPMAX)

! saumik - restrict to storage of only those porohex elements involved
!          in projections
                        IF(OUTSIDE) CYCLE

! saumik - skip(locp)=0 for porohex elements involved in projections
                        SKIP(LOCP) = 0

! saumik - local count of number of porohex elements involved in projections
                        IF(ONCEONLY) COUNTP = COUNTP + 1
                        ONCEONLY = .FALSE.

! saumik - # of flow elements either intersecting or inside current
!          mechanics element
                        COUNTF = COUNTF + 1
                        VAL1(LOCP) = COUNTF

! saumik - store location of flow elements
                        VAL2(COUNTP,COUNTF) = LOCF

                        IF(INSIDE) THEN

! saumik - take the entire volume if flow element is inside mechanics element
                           VOL1(COUNTP,COUNTF) = VOLH(XF)
                           CHECK = CHECK + VOLH(XF)

                        ELSEIF(INTERSECT) THEN

! saumik - compute the intersection volume if flow element intersects
!          mechanics element
                           CALL INTERSECTION(XP,XF,LOCP,LOCF,TETVOLUME,
     &                                       XFMIN,XFMAX,XPMIN,XPMAX)

                           VOL1(COUNTP,COUNTF) = TETVOLUME
                           CHECK = CHECK + TETVOLUME
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
! saumik - debugging
!               IF(SKIP(LOCP).EQ.0) THEN
!                  CHECK = CHECK/VOLH(XP)
!                  WRITE(10+MYPRC,*)"POROCHECK",CHECK,IIP+1,JJP+1,KKP+1
!               ENDIF
            ENDDO
         ENDDO
      ENDDO

C     -----------------
C     MECHANICS TO FLOW
C     -----------------

      COUNTF = 0
      DO KF = KL1F,KL2F
         DO JF = JL1VF(KF),JL2VF(KF)
            DO IFL = IL1F,IL2F
               IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
               IIF = IFL + IOFF - 1
               JJF = JF  + JOFF - 1
               KKF = KF  + KOFF - 1
!               LOCF = IIF*NZDIM(NBLK)*NYDIM(NBLK)+
!     &                         KKF*NYDIM(NBLK)+JJF+1
               LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF
               COUNTP = 0
               ONCEONLY = .TRUE.
               CHECK = 0.D0
               DO KP = KL1P,KL2P
                  DO JP = JL1VP(KP),JL2VP(KP)
                     DO IP = IL1P,IL2P
                        IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
                        IIP = IP + IOFFP - 1
                        JJP = JP + JOFFP - 1
                        KKP = KP + KOFFP - 1
!                        LOCP = (IIP+1-OB_LAYER)*NZDIM(1)*NYDIM(1)
!     &                         +KKP*NYDIM(1)+JJP+1
                        LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP

! saumik - skip mechanics elements not interacting with flow
                        IF(SKIP(LOCP).EQ.1) CYCLE

                        CALL GETX(XC_P,YC_P,ZC_P,XP,IDIMP,JDIMP,KDIMP,
     &                            IP,JP,KP)
                        CALL GETX(XC_F,YC_F,ZC_F,XF,IDIMF,JDIMF,KDIMF,
     &                            IFL,JF,KF)

                        CALL INOROUT(XP,XF,INSIDE,INTERSECT,
     &                               OUTSIDE,LOCP,LOCF,XFMIN,XFMAX,
     &                               XPMIN,XPMAX)

                        IF(INSIDE) THEN

                           VAL3(LOCF) = 0
                           INFLAG(LOCF) = LOCP
                           CHECK = CHECK + VOLH(XF)
                           GOTO 2

                        ELSEIF(INTERSECT) THEN

                           IF(ONCEONLY) COUNTF = COUNTF + 1
                           ONCEONLY = .FALSE.
                           COUNTP = COUNTP + 1

! saumik - # of mechanics elements intersecting current flow element
                           VAL3(LOCF) = COUNTP

! saumik - location of mechanics elements intersecting current flow element
                           VAL4(COUNTF,COUNTP) = LOCP

                           CALL INTERSECTION(XP,XF,LOCP,LOCF,TETVOLUME,
     &                                       XFMIN,XFMAX,XPMIN,XPMAX)

                           CHECK = CHECK + TETVOLUME
                           VOL2(COUNTF,COUNTP) = TETVOLUME
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
    2          CONTINUE
! saumik - debugging
!               CHECK = CHECK/VOLH(XF)
!               WRITE(11+MYPRC,*)"FLOWCHECK",CHECK,IIF+1,JJF+1,KKF+1
            ENDDO
         ENDDO
      ENDDO

      END

C============================================================
      SUBROUTINE GETX (XC,YC,ZC,X,IDIM,JDIM,KDIM,I,J,K)
C============================================================
      IMPLICIT NONE

      INTEGER I,J,K,N,II,JJ,KK,OFFSET(3,8)
      REAL*8  X(3,8)
      REAL*8  XC(IDIM+1,JDIM+1,KDIM+1),
     &        YC(IDIM+1,JDIM+1,KDIM+1),
     &        ZC(IDIM+1,JDIM+1,KDIM+1)
      INTEGER IDIM,JDIM,KDIM
      DATA OFFSET/0,0,0, 1,0,0, 1,1,0, 0,1,0,
     &            0,0,1, 1,0,1, 1,1,1, 0,1,1/

      DO N = 1,8
         II = I  + OFFSET(1,N)
         JJ = J  + OFFSET(2,N)
         KK = K  + OFFSET(3,N)
         X(1,N) = XC(II,JJ,KK)
         X(2,N) = YC(II,JJ,KK)
         X(3,N) = ZC(II,JJ,KK)
      ENDDO

      END

!C======================================================================
!      SUBROUTINE INOROUT (XP,XF,INSIDE,INTERSECT,OUTSIDE,LOCP,LOCF,
!     &                    XFMIN,XFMAX,XPMIN,XPMAX)
!C======================================================================
!      IMPLICIT NONE
!
!      REAL*8 XP(3,8),XF(3,8),TOL
!      REAL*8 XPMAX(3),XPMIN(3),XFMAX(3),XFMIN(3)
!      INTEGER I,LOCP,LOCF
!
!      LOGICAL INSIDE,INTERSECT,OUTSIDE
!      LOGICAL OUTSIDE1,OUTSIDE2,OUTSIDE3,OUTSIDE4,OUTSIDE5,OUTSIDE6
!      DATA TOL/1.D0/
!
!      INSIDE = .FALSE.
!      INTERSECT = .FALSE.
!      OUTSIDE = .FALSE.
!
!      DO I = 1,3
!
!C     ITH DIMENSION
!
!         XPMAX(I) = MAX(XP(I,1),XP(I,2),XP(I,3),XP(I,4),XP(I,5),XP(I,6),
!     &                  XP(I,7),XP(I,8))
!         XPMIN(I) = MIN(XP(I,1),XP(I,2),XP(I,3),XP(I,4),XP(I,5),XP(I,6),
!     &                  XP(I,7),XP(I,8))
!         XFMAX(I) = MAX(XF(I,1),XF(I,2),XF(I,3),XF(I,4),XF(I,5),XF(I,6),
!     &                  XF(I,7),XF(I,8))
!         XFMIN(I) = MIN(XF(I,1),XF(I,2),XF(I,3),XF(I,4),XF(I,5),XF(I,6),
!     &                  XF(I,7),XF(I,8))
!      ENDDO
!
!      IF ((XFMIN(1).GE.(XPMIN(1)-TOL)).AND.
!     &    (XFMAX(1).LE.(XPMAX(1)+TOL)).AND.
!
!C     COMPARE X COORDINATES
!
!     &    (XFMIN(2).GE.(XPMIN(2)-TOL)).AND.
!     &    (XFMAX(2).LE.(XPMAX(2)+TOL)).AND.
!
!C     COMPARE Y COORDINATES
!
!     &    (XFMIN(3).GE.(XPMIN(3)-TOL)).AND.
!     &    (XFMAX(3).LE.(XPMAX(3)+TOL)))THEN
!
!C     COMPARE Z COORDINATES
!
!          INSIDE = .TRUE.
!          GO TO 1
!      ENDIF
!
!      OUTSIDE1 = .FALSE.
!      OUTSIDE2 = .FALSE.
!      OUTSIDE3 = .FALSE.
!      OUTSIDE4 = .FALSE.
!      OUTSIDE5 = .FALSE.
!      OUTSIDE6 = .FALSE.
!
!      IF (XFMIN(1).GE.(XPMAX(1)-TOL)) OUTSIDE1 = .TRUE.
!      IF (XFMIN(2).GE.(XPMAX(2)-TOL)) OUTSIDE2 = .TRUE.
!      IF (XFMIN(3).GE.(XPMAX(3)-TOL)) OUTSIDE3 = .TRUE.
!      IF (XFMAX(1).LE.(XPMIN(1)+TOL)) OUTSIDE4 = .TRUE.
!      IF (XFMAX(2).LE.(XPMIN(2)+TOL)) OUTSIDE5 = .TRUE.
!      IF (XFMAX(3).LE.(XPMIN(3)+TOL)) OUTSIDE6 = .TRUE.
!
!      IF (INSIDE.OR.OUTSIDE1.OR.OUTSIDE2.OR.OUTSIDE3.OR.OUTSIDE4.OR.
!     &    OUTSIDE5.OR.OUTSIDE6) THEN
!          INTERSECT = .FALSE.
!      ELSE
!          INTERSECT = .TRUE.
!      ENDIF
!
!      IF((.NOT.INSIDE).AND.(.NOT.INTERSECT)) OUTSIDE = .TRUE.
!
!   1  CONTINUE
!      RETURN
!      END
!
C======================================================================
      SUBROUTINE INOROUT (XP,XF,INSIDE,INTERSECT,OUTSIDE,LOCP,LOCF,
     &                    XFMIN,XFMAX,XPMIN,XPMAX)
C======================================================================
      IMPLICIT NONE

      REAL*8 XP(3,8),XF(3,8),TOL,TETRAVOL,VOLH,VOLSUM
      REAL*8 XPMAX(3),XPMIN(3),XFMAX(3),XFMIN(3)
      INTEGER I,LOCP,LOCF,FACEMAP(6,4),OUTCOUNT,J

      LOGICAL INSIDE,INTERSECT,OUTSIDE
      DATA TOL/1.D-3/

      INSIDE=.FALSE.
      INTERSECT=.FALSE.
      OUTSIDE=.FALSE.

      FACEMAP(1,:) = [1,5,8,4]
      FACEMAP(2,:) = [2,3,7,6]
      FACEMAP(3,:) = [1,2,6,5]
      FACEMAP(4,:) = [3,4,8,7]
      FACEMAP(5,:) = [1,4,3,2]
      FACEMAP(6,:) = [5,6,7,8]

      DO I = 1,3
         XPMAX(I) = MAX(XP(I,1),XP(I,2),XP(I,3),XP(I,4),XP(I,5),XP(I,6),
     &                  XP(I,7),XP(I,8))
         XPMIN(I) = MIN(XP(I,1),XP(I,2),XP(I,3),XP(I,4),XP(I,5),XP(I,6),
     &                  XP(I,7),XP(I,8))
         XFMAX(I) = MAX(XF(I,1),XF(I,2),XF(I,3),XF(I,4),XF(I,5),XF(I,6),
     &                  XF(I,7),XF(I,8))
         XFMIN(I) = MIN(XF(I,1),XF(I,2),XF(I,3),XF(I,4),XF(I,5),XF(I,6),
     &                  XF(I,7),XF(I,8))
      ENDDO

      OUTCOUNT = 0

      DO I=1,8

      VOLSUM = 0.D0

      DO J=1,6
       VOLSUM = VOLSUM + TETRAVOL(XP(:,FACEMAP(J,1)),XP(:,FACEMAP(J,2)),
     &                            XP(:,FACEMAP(J,3)),XF(:,I))
       VOLSUM = VOLSUM + TETRAVOL(XP(:,FACEMAP(J,1)),XP(:,FACEMAP(J,3)),
     &                            XP(:,FACEMAP(J,4)),XF(:,I))
      ENDDO

      IF(DABS(VOLSUM/VOLH(XP)-1.D0).GT.TOL) OUTCOUNT = OUTCOUNT + 1
      ENDDO

      IF(OUTCOUNT.EQ.0) THEN
         INSIDE=.TRUE.
      ELSEIF(OUTCOUNT.EQ.8) THEN
         OUTSIDE=.TRUE.
      ELSE
         INTERSECT=.TRUE.
      ENDIF

      RETURN
      END

C======================================================================
      SUBROUTINE INTERSECTION(XP,XF,LOCP,LOCF,TETVOLUME,
     &                        XFMIN,XFMAX,XPMIN,XPMAX)
C======================================================================
      USE eprojmod
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'

      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'mpif.h'
      include 'blkary.h'
      include 'emodel.h'

      REAL*8 XP(3,8),XF(3,8),CP(8,6),CF(8,6)
      REAL*8 P(3),PNEW(3),TOL,TOL1,TANGENT(3),TANGENTVAL,CURVATURE(3),
     &       CURVATUREVAL,TETVOLUME
      REAL*8 FACECOORDP(3,4,6),FACECOORDF(3,4,6),STORE(3),PTEMP(4,3)
      REAL*8 XPMAX(3),XPMIN(3),XFMAX(3),XFMIN(3)

      REAL*8 EDGE1(3),EDGE2(3)
      REAL*8 FLOW1(3),FLOW2(3),PORO1(3),PORO2(3)

      INTEGER I,J,K,L,II,LOCAL,LOCP,LOCF,PTCOUNT
      LOGICAL FLAG,GO
      DATA TOL1 /1.D-8/

      IF(MECH_BC_NCASE.EQ.100) THEN
         TOL = 1.D-3
      ELSE
         TOL = 1.D-1
      ENDIF

C     CONSTRUCT S1, DELS1, S2, DELS2
C     FACECOORD (DIMENSION #,LOCAL NODE #,LOCAL FACE #)

      FACECOORDP = 0.D0
      FACECOORDF = 0.D0

      CALL FORMSURFACE_HEX(XP,CP,FACECOORDP)
      CALL FORMSURFACE_HEX(XF,CF,FACECOORDF)

      GLOBAL = 0
      POINT = 0.D0

      DO I = 1,6

         FLAG = .FALSE.
         CALL GETFLAG(I,FLAG,FACECOORDF,XP,LOCP,LOCF)

         IF(.NOT.FLAG) CYCLE

         DO J = 1,6

            PTEMP = 0.D0
            CALL GETPOINT(I,PTEMP,FACECOORDF,XP,PTCOUNT)

            DO II = 1,PTCOUNT

            P = PTEMP(II,:)

            CALL FINDTANGENT(CF,CF,I,J,P,TANGENT,TANGENTVAL)

            IF(TANGENTVAL.GT.TOL1) THEN

               CALL APPROXIMANT_NEWTON(CF,CF,I,J,P,PNEW,TANGENT,
     &              TANGENTVAL,CURVATURE,CURVATUREVAL)

               CALL EDGEBOUNDS(I,J,XF,EDGE1,EDGE2)
               IF(PNEW(1).GE.(EDGE1(1)-TOL).AND.
     &            PNEW(1).LE.(EDGE2(1)+TOL).AND.
     &            PNEW(2).GE.(EDGE1(2)-TOL).AND.
     &            PNEW(2).LE.(EDGE2(2)+TOL).AND.
     &            PNEW(3).GE.(EDGE1(3)-TOL).AND.
     &            PNEW(3).LE.(EDGE2(3)+TOL))THEN

                  PNEW = P
                  GLOBAL = GLOBAL + 1
                  POINT(GLOBAL,:) = P

                  DO WHILE(
     &                     PNEW(1).GE.(XPMIN(1)-TOL).AND.
     &                     PNEW(1).LE.(XPMAX(1)+TOL).AND.
     &                     PNEW(2).GE.(XPMIN(2)-TOL).AND.
     &                     PNEW(2).LE.(XPMAX(2)+TOL).AND.
     &                     PNEW(3).GE.(XPMIN(3)-TOL).AND.
     &                     PNEW(3).LE.(XPMAX(3)+TOL).AND.
     &                     PNEW(1).GE.(EDGE1(1)-TOL).AND.
     &                     PNEW(1).LE.(EDGE2(1)+TOL).AND.
     &                     PNEW(2).GE.(EDGE1(2)-TOL).AND.
     &                     PNEW(2).LE.(EDGE2(2)+TOL).AND.
     &                     PNEW(3).GE.(EDGE1(3)-TOL).AND.
     &                     PNEW(3).LE.(EDGE2(3)+TOL))

                     P = PNEW
                     CALL FINDTANGENT(CF,CF,I,J,P,TANGENT,TANGENTVAL)
                     CALL APPROXIMANT_NEWTON(CF,CF,I,J,P,PNEW,TANGENT,
     &                    TANGENTVAL,CURVATURE,CURVATUREVAL)

                  ENDDO

                  GLOBAL = GLOBAL + 1
                  POINT(GLOBAL,:) = P
                  STORE = P
               ENDIF
            ENDIF

            DO K = 1,6

               P = STORE

               CALL FINDTANGENT(CF,CP,J,K,P,TANGENT,TANGENTVAL)
               TANGENT = -1.D0 * TANGENT

               IF(TANGENTVAL.GT.TOL1) THEN

                  CALL APPROXIMANT_NEWTON(CF,CP,J,K,P,PNEW,TANGENT,
     &                 TANGENTVAL,CURVATURE,CURVATUREVAL)

                  CALL FACEBOUNDS(J,XF,K,XP,FLOW1,FLOW2,PORO1,PORO2)
                  IF(
     &               PNEW(1).GE.(PORO1(1)-TOL).AND.
     &               PNEW(1).LE.(PORO2(1)+TOL).AND.
     &               PNEW(2).GE.(PORO1(2)-TOL).AND.
     &               PNEW(2).LE.(PORO2(2)+TOL).AND.
     &               PNEW(3).GE.(PORO1(3)-TOL).AND.
     &               PNEW(3).LE.(PORO2(3)+TOL).AND.
     &               PNEW(1).GE.(FLOW1(1)-TOL).AND.
     &               PNEW(1).LE.(FLOW2(1)+TOL).AND.
     &               PNEW(2).GE.(FLOW1(2)-TOL).AND.
     &               PNEW(2).LE.(FLOW2(2)+TOL).AND.
     &               PNEW(3).GE.(FLOW1(3)-TOL).AND.
     &               PNEW(3).LE.(FLOW2(3)+TOL)) THEN

                     PNEW = P

                     DO WHILE(
     &                        PNEW(1).GE.(PORO1(1)-TOL).AND.
     &                        PNEW(1).LE.(PORO2(1)+TOL).AND.
     &                        PNEW(2).GE.(PORO1(2)-TOL).AND.
     &                        PNEW(2).LE.(PORO2(2)+TOL).AND.
     &                        PNEW(3).GE.(PORO1(3)-TOL).AND.
     &                        PNEW(3).LE.(PORO2(3)+TOL).AND.
     &                        PNEW(1).GE.(FLOW1(1)-TOL).AND.
     &                        PNEW(1).LE.(FLOW2(1)+TOL).AND.
     &                        PNEW(2).GE.(FLOW1(2)-TOL).AND.
     &                        PNEW(2).LE.(FLOW2(2)+TOL).AND.
     &                        PNEW(3).GE.(FLOW1(3)-TOL).AND.
     &                        PNEW(3).LE.(FLOW2(3)+TOL))

                        P = PNEW
                        CALL FINDTANGENT(CF,CP,J,K,P,TANGENT,TANGENTVAL)
                        TANGENT = -1.D0 * TANGENT
                        CALL APPROXIMANT_NEWTON(CF,CP,J,K,P,PNEW,
     &                       TANGENT,TANGENTVAL,CURVATURE,CURVATUREVAL)

                     ENDDO

                     GLOBAL = GLOBAL + 1
                     POINT(GLOBAL,:) = P
                     STORE = P
                  ENDIF
               ENDIF

               DO L = 1,6

                  P = STORE

                  CALL FINDTANGENT(CP,CP,K,L,P,TANGENT,TANGENTVAL)

                  IF(TANGENTVAL.GT.TOL1) THEN

                     CALL APPROXIMANT(P,PNEW,TANGENT)

                     IF(
     &                  PNEW(1).GE.(XPMIN(1)-TOL).AND.
     &                  PNEW(1).LE.(XPMAX(1)+TOL).AND.
     &                  PNEW(2).GE.(XPMIN(2)-TOL).AND.
     &                  PNEW(2).LE.(XPMAX(2)+TOL).AND.
     &                  PNEW(3).GE.(XPMIN(3)-TOL).AND.
     &                  PNEW(3).LE.(XPMAX(3)+TOL).AND.
     &                  PNEW(1).GE.(XFMIN(1)-TOL).AND.
     &                  PNEW(1).LE.(XFMAX(1)+TOL).AND.
     &                  PNEW(2).GE.(XFMIN(2)-TOL).AND.
     &                  PNEW(2).LE.(XFMAX(2)+TOL).AND.
     &                  PNEW(3).GE.(XFMIN(3)-TOL).AND.
     &                  PNEW(3).LE.(XFMAX(3)+TOL)) THEN

                        PNEW = P

                        DO WHILE(
     &                           PNEW(1).GE.(XPMIN(1)-TOL).AND.
     &                           PNEW(1).LE.(XPMAX(1)+TOL).AND.
     &                           PNEW(2).GE.(XPMIN(2)-TOL).AND.
     &                           PNEW(2).LE.(XPMAX(2)+TOL).AND.
     &                           PNEW(3).GE.(XPMIN(3)-TOL).AND.
     &                           PNEW(3).LE.(XPMAX(3)+TOL).AND.
     &                           PNEW(1).GE.(XFMIN(1)-TOL).AND.
     &                           PNEW(1).LE.(XFMAX(1)+TOL).AND.
     &                           PNEW(2).GE.(XFMIN(2)-TOL).AND.
     &                           PNEW(2).LE.(XFMAX(2)+TOL).AND.
     &                           PNEW(3).GE.(XFMIN(3)-TOL).AND.
     &                           PNEW(3).LE.(XFMAX(3)+TOL))

                           P = PNEW
                           CALL APPROXIMANT(P,PNEW,TANGENT)

                        ENDDO

                        GLOBAL = GLOBAL + 1
                        POINT(GLOBAL,:) = P
                     ENDIF
                  ENDIF
               ENDDO ! L
            ENDDO ! K
            ENDDO ! II
         ENDDO ! J
      ENDDO ! I

      IF(GLOBAL.LT.8) THEN
         TETVOLUME = 0.D0
      ELSE
         CALL IPTETGEN(TETVOLUME,GLOBAL,POINT(:,1),POINT(:,2),
     &              POINT(:,3))
      ENDIF

      END

C======================================================================
      SUBROUTINE GETFLAG(N,FLAG,FACECOORD,XP,LOCP,LOCF)
C======================================================================
      IMPLICIT NONE

      INTEGER N,M,LOCP,LOCF,J,FACEMAP(6,4)
      LOGICAL FLAG
      REAL*8 FACECOORD(3,4,6),X(3),TOL,XP(3,8),VOLSUM,VOLH,TETRAVOL
      DATA TOL/1.D-3/

      FACEMAP(1,:) = [1,5,8,4]
      FACEMAP(2,:) = [2,3,7,6]
      FACEMAP(3,:) = [1,2,6,5]
      FACEMAP(4,:) = [3,4,8,7]
      FACEMAP(5,:) = [1,4,3,2]
      FACEMAP(6,:) = [5,6,7,8]

      DO M = 1,4

         X(1:3) = FACECOORD(1:3,M,N)

         VOLSUM = 0.D0

         DO J=1,6
         VOLSUM = VOLSUM + TETRAVOL(XP(:,FACEMAP(J,1)),
     &                              XP(:,FACEMAP(J,2)),
     &                              XP(:,FACEMAP(J,3)),X)
         VOLSUM = VOLSUM + TETRAVOL(XP(:,FACEMAP(J,1)),
     &                              XP(:,FACEMAP(J,3)),
     &                              XP(:,FACEMAP(J,4)),X)
         ENDDO

         IF(DABS(VOLSUM/VOLH(XP)-1.D0).GT.TOL) THEN
            FLAG=.FALSE.
         ELSE
            FLAG=.TRUE.
         ENDIF
      ENDDO

      END

C======================================================================
      SUBROUTINE GETPOINT(N,PT,FACECOORD,XP,PTCOUNT)
C======================================================================
      IMPLICIT NONE

      INTEGER N,M,PTCOUNT,FACEMAP(6,4),J
      REAL*8 PT(4,3),VOLSUM,TETRAVOL,VOLH,XP(3,8)
      REAL*8 FACECOORD(3,4,6),X(3),TOL
      DATA TOL/1.D-3/

      FACEMAP(1,:) = [1,5,8,4]
      FACEMAP(2,:) = [2,3,7,6]
      FACEMAP(3,:) = [1,2,6,5]
      FACEMAP(4,:) = [3,4,8,7]
      FACEMAP(5,:) = [1,4,3,2]
      FACEMAP(6,:) = [5,6,7,8]

      PTCOUNT = 0

      DO M = 1,4

         X(1:3) = FACECOORD(1:3,M,N)

         VOLSUM = 0.D0

         DO J=1,6
         VOLSUM = VOLSUM + TETRAVOL(XP(:,FACEMAP(J,1)),
     &                              XP(:,FACEMAP(J,2)),
     &                              XP(:,FACEMAP(J,3)),X)
         VOLSUM = VOLSUM + TETRAVOL(XP(:,FACEMAP(J,1)),
     &                              XP(:,FACEMAP(J,3)),
     &                              XP(:,FACEMAP(J,4)),X)
         ENDDO

         IF(DABS(VOLSUM/VOLH(XP)-1.D0).GT.TOL) THEN
         ELSE
            PTCOUNT=PTCOUNT+1
            PT(PTCOUNT,1:3) = X(1:3)
         ENDIF
      ENDDO

      END

C======================================================================
      SUBROUTINE FORMSURFACE_HEX(X,C,FACECOORD)
C======================================================================
      IMPLICIT NONE

      REAL*8 X(3,8)

      REAL*8 FACECOORD(3,4,6)

      REAL*8 XHEX(4,8),SHEX(4),UHEX(4,4),VTHEX(8,8),SAHEX(4)
      INTEGER FACEI,I,J,K

! saumik
!      s := c1*xyz + c2*xy + c3*yz + c4*xz
!          + c5*x + c6*y + c7*z + 1.d0 = 0.d0

      REAL*8 C(8,6),VHEX(8,4),M(12,8),AHEX(12,4),DELHATSHAT(3),
     &       JACIT(12,3),BHEXTEMP(12),BHEX(12,1)
      REAL*8 FINALHEX(8),WORKHEX(40),WORKAHEX(24),Y(4)
      INTEGER INFO,IFLAG,RANK

      CALL FACEINFO (X,FACECOORD)

      DO FACEI = 1,6
         DO J = 1,4
            XHEX(J,1) = FACECOORD(1,J,FACEI)*FACECOORD(2,J,FACEI)*
     &                       FACECOORD(3,J,FACEI)
            XHEX(J,2) = FACECOORD(1,J,FACEI)*FACECOORD(2,J,FACEI)
            XHEX(J,3) = FACECOORD(2,J,FACEI)*FACECOORD(3,J,FACEI)
            XHEX(J,4) = FACECOORD(1,J,FACEI)*FACECOORD(3,J,FACEI)
            XHEX(J,5) = FACECOORD(1,J,FACEI)
            XHEX(J,6) = FACECOORD(2,J,FACEI)
            XHEX(J,7) = FACECOORD(3,J,FACEI)
            XHEX(J,8) = 1.D0
         ENDDO

! saumik - singular value decomposition of xhex(4,8)
         CALL DGESVD ('A','A',4,8,XHEX,4,SHEX,UHEX,4,VTHEX,8,
     &                 WORKHEX,40,INFO)
         IF(INFO.NE.0) WRITE(*,*)" --- PROBLEM WITH SVD --- "

         DO I = 5,8
            DO J = 1,8
               VHEX(J,I-4) = VTHEX(I,J)
            ENDDO
         ENDDO

         M = 0.D0

         M(1,1) = FACECOORD(2,1,FACEI)*FACECOORD(3,1,FACEI)
         M(2,1) = FACECOORD(1,1,FACEI)*FACECOORD(3,1,FACEI)
         M(3,1) = FACECOORD(1,1,FACEI)*FACECOORD(2,1,FACEI)
         M(1,2) = FACECOORD(2,1,FACEI)
         M(1,4) = FACECOORD(3,1,FACEI)
         M(2,2) = FACECOORD(1,1,FACEI)
         M(2,3) = FACECOORD(3,1,FACEI)
         M(3,3) = FACECOORD(2,1,FACEI)
         M(3,4) = FACECOORD(1,1,FACEI)
         M(1,5) = 1.D0
         M(2,6) = 1.D0
         M(3,7) = 1.D0

         M(1+3,1) = FACECOORD(2,2,FACEI)*FACECOORD(3,2,FACEI)
         M(2+3,1) = FACECOORD(1,2,FACEI)*FACECOORD(3,2,FACEI)
         M(3+3,1) = FACECOORD(1,2,FACEI)*FACECOORD(2,2,FACEI)
         M(1+3,2) = FACECOORD(2,2,FACEI)
         M(1+3,4) = FACECOORD(3,2,FACEI)
         M(2+3,2) = FACECOORD(1,2,FACEI)
         M(2+3,3) = FACECOORD(3,2,FACEI)
         M(3+3,3) = FACECOORD(2,2,FACEI)
         M(3+3,4) = FACECOORD(1,2,FACEI)
         M(1+3,5) = 1.D0
         M(2+3,6) = 1.D0
         M(3+3,7) = 1.D0

         M(1+6,1) = FACECOORD(2,3,FACEI)*FACECOORD(3,3,FACEI)
         M(2+6,1) = FACECOORD(1,3,FACEI)*FACECOORD(3,3,FACEI)
         M(3+6,1) = FACECOORD(1,3,FACEI)*FACECOORD(2,3,FACEI)
         M(1+6,2) = FACECOORD(2,3,FACEI)
         M(1+6,4) = FACECOORD(3,3,FACEI)
         M(2+6,2) = FACECOORD(1,3,FACEI)
         M(2+6,3) = FACECOORD(3,3,FACEI)
         M(3+6,3) = FACECOORD(2,3,FACEI)
         M(3+6,4) = FACECOORD(1,3,FACEI)
         M(1+6,5) = 1.D0
         M(2+6,6) = 1.D0
         M(3+6,7) = 1.D0

         M(1+9,1) = FACECOORD(2,4,FACEI)*FACECOORD(3,4,FACEI)
         M(2+9,1) = FACECOORD(1,4,FACEI)*FACECOORD(3,4,FACEI)
         M(3+9,1) = FACECOORD(1,4,FACEI)*FACECOORD(2,4,FACEI)
         M(1+9,2) = FACECOORD(2,4,FACEI)
         M(1+9,4) = FACECOORD(3,4,FACEI)
         M(2+9,2) = FACECOORD(1,4,FACEI)
         M(2+9,3) = FACECOORD(3,4,FACEI)
         M(3+9,3) = FACECOORD(2,4,FACEI)
         M(3+9,4) = FACECOORD(1,4,FACEI)
         M(1+9,5) = 1.D0
         M(2+9,6) = 1.D0
         M(3+9,7) = 1.D0

         CALL DGEMM('N','N',12,4,8,1.D0,M,12,VHEX,8,0.D0,AHEX,12)

         DELHATSHAT = 0.D0
         IF((FACEI.EQ.1).OR.(FACEI.EQ.2)) THEN
            DELHATSHAT(1) = 1.D0
         ELSEIF((FACEI.EQ.3).OR.(FACEI.EQ.4)) THEN
            DELHATSHAT(2) = 1.D0
         ELSE
            DELHATSHAT(3) = 1.D0
         ENDIF

         CALL GETJAC(X,FACEI,JACIT)
         CALL DGEMV('N',12,3,1.D0,JACIT,12,DELHATSHAT,1,0.D0,BHEXTEMP,1)

         BHEX(:,1) = BHEXTEMP
         CALL DGELSS(12,4,1,AHEX,12,BHEX,12,SAHEX,-1.D0,RANK,WORKAHEX,
     &               24,INFO)
         IF(INFO.NE.0) WRITE(*,*)" PROBLEM WITH LEAST SQUARES SOLVE "
         DO I = 1,4
            Y(I) = BHEX(I,1)
         ENDDO

         CALL DGEMV('N',8,4,1.D0,VHEX,8,Y,1,0.D0,FINALHEX,1)
         DO I = 1,8
            IF(FINALHEX(8).NE.0.D0)FINALHEX(I) = FINALHEX(I)/FINALHEX(8)
            C(I,FACEI) = FINALHEX(I)
         ENDDO

      ENDDO

      END

C======================================================================
      SUBROUTINE GETJAC(X,FACEI,FINAL)
C======================================================================
      IMPLICIT NONE

      INTEGER FACEI,NODE,IPIV(3),INFO,I,J,K,FACEMAP(6,4),ROW
      REAL*8 X(3,8),JMAT(3,3),JACI(3,3),HATX(3),TEMP(3,3),FINAL(12,3)

      FACEMAP(1,:) = [1,5,8,4]
      FACEMAP(2,:) = [2,3,7,6]
      FACEMAP(3,:) = [1,2,6,5]
      FACEMAP(4,:) = [3,4,8,7]
      FACEMAP(5,:) = [1,4,3,2]
      FACEMAP(6,:) = [5,6,7,8]

      FINAL = 0.D0
      DO I = 1,4
         NODE =  FACEMAP(FACEI,I)
         TEMP = 0.D0
         JMAT = 0.D0
         JACI = 0.D0

         IF (NODE.EQ.1)THEN
             HATX(1)=0.0D0
             HATX(2)=0.0D0
             HATX(3)=0.0D0
         ELSEIF (NODE.EQ.2)THEN
             HATX(1)=1.0D0
             HATX(2)=0.0D0
             HATX(3)=0.0D0
         ELSEIF (NODE.EQ.3)THEN
             HATX(1)=1.0D0
             HATX(2)=1.0D0
             HATX(3)=0.0D0
         ELSEIF (NODE.EQ.4)THEN
             HATX(1)=0.0D0
             HATX(2)=1.0D0
             HATX(3)=0.0D0
         ELSEIF (NODE.EQ.5)THEN
             HATX(1)=0.0D0
             HATX(2)=0.0D0
             HATX(3)=1.0D0
         ELSEIF (NODE.EQ.6)THEN
             HATX(1)=1.0D0
             HATX(2)=0.0D0
             HATX(3)=1.0D0
         ELSEIF (NODE.EQ.7)THEN
             HATX(1)=1.0D0
             HATX(2)=1.0D0
             HATX(3)=1.0D0
         ELSEIF (NODE.EQ.8) THEN
             HATX(1)=0.0D0
             HATX(2)=1.0D0
             HATX(3)=1.0D0
         ENDIF

         CALL JACMAT(X,HATX,JMAT)

         CALL GETEYE(JACI,3,3)
         CALL DGESV(3,3,JMAT,3,IPIV,JACI,3,INFO)
         TEMP = TRANSPOSE(JACI)

         DO J = 1,3
            ROW = (I-1)*3 + J
            DO K = 1,3
               FINAL(ROW,K) = TEMP(J,K)
            ENDDO
         ENDDO

      ENDDO

      END

C======================================================================
      SUBROUTINE FACEINFO (X,FACECOORD)
C======================================================================
      IMPLICIT NONE

      REAL*8 X(3,8)
      INTEGER FACEI,I,J
      INTEGER FACEMAP(6,4)
      REAL*8 FACECOORD(3,4,6)

      FACEMAP(1,:) = [1,5,8,4]
      FACEMAP(2,:) = [2,3,7,6]
      FACEMAP(3,:) = [1,2,6,5]
      FACEMAP(4,:) = [3,4,8,7]
      FACEMAP(5,:) = [1,4,3,2]
      FACEMAP(6,:) = [5,6,7,8]

      DO FACEI = 1,6
         DO J = 1,4
            DO I = 1,3
! saumik - coordinate of ith dimension of jth local node of face # facei
               FACECOORD(I,J,FACEI) = X(I,FACEMAP(FACEI,J))
            ENDDO
         ENDDO
      ENDDO

      END

C======================================================================
      SUBROUTINE EDGEBOUNDS(I,J,XF,EDGE1,EDGE2)
C======================================================================
      IMPLICIT NONE

      REAL*8 XF(3,8),EDGE1(3),EDGE2(3)
      INTEGER I,J,EDGEMAP(6,6,2),NODE1,NODE2
      REAL*8 POINT1(3),POINT2(3)

      EDGEMAP(1,3,:) = [1,5]
      EDGEMAP(1,4,:) = [4,8]
      EDGEMAP(1,5,:) = [1,4]
      EDGEMAP(1,6,:) = [5,8]

      EDGEMAP(3,1,:) = [1,5]
      EDGEMAP(4,1,:) = [4,8]
      EDGEMAP(5,1,:) = [1,4]
      EDGEMAP(6,1,:) = [5,8]

      EDGEMAP(2,3,:) = [2,6]
      EDGEMAP(2,4,:) = [3,7]
      EDGEMAP(2,5,:) = [2,3]
      EDGEMAP(2,6,:) = [6,7]

      EDGEMAP(3,2,:) = [2,6]
      EDGEMAP(4,2,:) = [3,7]
      EDGEMAP(5,2,:) = [2,3]
      EDGEMAP(6,2,:) = [6,7]

      EDGEMAP(3,5,:) = [1,2]
      EDGEMAP(3,6,:) = [5,6]

      EDGEMAP(5,3,:) = [1,2]
      EDGEMAP(6,3,:) = [5,6]

      EDGEMAP(4,5,:) = [3,4]
      EDGEMAP(4,6,:) = [7,8]

      EDGEMAP(5,4,:) = [3,4]
      EDGEMAP(6,4,:) = [7,8]

      NODE1 = EDGEMAP(I,J,1)
      NODE2 = EDGEMAP(I,J,2)

      POINT1 = XF(:,NODE1)
      POINT2 = XF(:,NODE2)

      EDGE1(1) = MIN(POINT1(1),POINT2(1))
      EDGE2(1) = MAX(POINT1(1),POINT2(1))

      EDGE1(2) = MIN(POINT1(2),POINT2(2))
      EDGE2(2) = MAX(POINT1(2),POINT2(2))

      EDGE1(3) = MIN(POINT1(3),POINT2(3))
      EDGE2(3) = MAX(POINT1(3),POINT2(3))

      END

C======================================================================
      SUBROUTINE FACEBOUNDS(J,XF,K,XP,FLOW1,FLOW2,PORO1,PORO2)
C======================================================================
      IMPLICIT NONE

      REAL*8 XF(3,8),XP(3,8)
      REAL*8 FLOW1(3),FLOW2(3),PORO1(3),PORO2(3)
      INTEGER J,K,FACEMAP(6,4),NODES(4),I

      FACEMAP(1,:) = [1,5,8,4]
      FACEMAP(2,:) = [2,3,7,6]
      FACEMAP(3,:) = [1,2,6,5]
      FACEMAP(4,:) = [3,4,8,7]
      FACEMAP(5,:) = [1,4,3,2]
      FACEMAP(6,:) = [5,6,7,8]

      NODES = FACEMAP(J,:)

      DO I=1,3
         FLOW1(I) = 100000.D0
         FLOW2(I) = 0.D0
         PORO1(I) = 100000.D0
         PORO2(I) = 0.D0
      ENDDO

      DO I = 1,4
         FLOW1(1) = MIN(FLOW1(1),XF(1,NODES(I)))
         FLOW2(1) = MAX(FLOW2(1),XF(1,NODES(I)))

         FLOW1(2) = MIN(FLOW1(2),XF(2,NODES(I)))
         FLOW2(2) = MAX(FLOW2(2),XF(2,NODES(I)))

         FLOW1(3) = MIN(FLOW1(3),XF(3,NODES(I)))
         FLOW2(3) = MAX(FLOW2(3),XF(3,NODES(I)))
      ENDDO

      NODES = FACEMAP(K,:)

      DO I = 1,4
         PORO1(1) = MIN(PORO1(1),XP(1,NODES(I)))
         PORO2(1) = MAX(PORO2(1),XP(1,NODES(I)))

         PORO1(2) = MIN(PORO1(2),XP(2,NODES(I)))
         PORO2(2) = MAX(PORO2(2),XP(2,NODES(I)))

         PORO1(3) = MIN(PORO1(3),XP(3,NODES(I)))
         PORO2(3) = MAX(PORO2(3),XP(3,NODES(I)))
      ENDDO

      END

C======================================================================
      SUBROUTINE APPROXIMANT_NEWTON(CP,CF,I,J,PT,PTNEW,TANGENT,
     &                              TANGENTVAL,CURVATURE,CURVATUREVAL)
C======================================================================
      IMPLICIT NONE
      INCLUDE 'emodel.h'

      REAL*8 CP(8,6),CF(8,6)
      REAL*8 PT(3),TANGENT(3),TANGENTVAL,CURVATURE(3),CURVATUREVAL,
     &       MATRIX(2,2),RHS(2),S(2),WORK(10),STEP,TOL
      REAL*8 PTNEW(3)
      INTEGER I,J,RANK,INFO
      DATA TOL /1.D-6/

      IF(MECH_BC_NCASE.EQ.100) THEN
         STEP = 1.D-1
      ELSE
         STEP = 1.D0
      ENDIF

! saumik - get r''(p)
      CALL FINDCURVATURE(CP,CF,I,J,PT,TANGENT,CURVATURE,CURVATUREVAL)

      IF(CURVATUREVAL.LE.TOL) THEN
        PTNEW = PT + STEP*TANGENT

      ELSE
! saumik - second order taylor approximant
         PTNEW = PT + STEP*TANGENT + STEP**2.D0/2.D0*CURVATURE

! saumik - newton corrector
         CALL NEWTON(CP,CF,I,J,PTNEW)
      ENDIF

      END

C======================================================================
      SUBROUTINE APPROXIMANT(PT,PTNEW,TANGENT)
C======================================================================
      IMPLICIT NONE
      INCLUDE 'emodel.h'

      REAL*8 TANGENT(3)
      REAL*8 PT(3),PTNEW(3),STEP

! saumik - first order taylor approximant; default step size of 1.d-1
      IF(MECH_BC_NCASE.EQ.100) THEN
         STEP = 1.D-1
      ELSE
         STEP = 1.D0
      ENDIF

      PTNEW = PT + STEP*TANGENT

      END

C======================================================================
      SUBROUTINE FINDTANGENT(CP,CF,I,J,PT,TANGENT,TANGENTVAL)
C======================================================================
      IMPLICIT NONE

      REAL*8 CP(8,6),CF(8,6),C1,C2,C3,C4,C5,C6,C7,
     &       PI,PJ,PK,FI,FJ,FK
      REAL*8 PT(3),TANGENT(3),TANGENTVAL
      INTEGER I,J,K

      IF((I.EQ.1.AND.J.EQ.2).OR.(I.EQ.2.AND.J.EQ.1).OR.
     &   (I.EQ.3.AND.J.EQ.4).OR.(I.EQ.4.AND.J.EQ.3).OR.
     &   (I.EQ.5.AND.J.EQ.6).OR.(I.EQ.6.AND.J.EQ.5)) THEN
        TANGENTVAL = 0.D0
        RETURN
      ENDIF

      C1 = CP(1,I)
      C2 = CP(2,I)
      C3 = CP(3,I)
      C4 = CP(4,I)
      C5 = CP(5,I)
      C6 = CP(6,I)
      C7 = CP(7,I)
      PI = C1*PT(2)*PT(3) + C2*PT(2) + C4*PT(3) + C5
      PJ = C1*PT(1)*PT(3) + C2*PT(1) + C3*PT(3) + C6
      PK = C1*PT(1)*PT(2) + C3*PT(2) + C4*PT(1) + C7

      C1 = CF(1,J)
      C2 = CF(2,J)
      C3 = CF(3,J)
      C4 = CF(4,J)
      C5 = CF(5,J)
      C6 = CF(6,J)
      C7 = CF(7,J)
      FI = C1*PT(2)*PT(3) + C2*PT(2) + C4*PT(3) + C5
      FJ = C1*PT(1)*PT(3) + C2*PT(1) + C3*PT(3) + C6
      FK = C1*PT(1)*PT(2) + C3*PT(2) + C4*PT(1) + C7

      TANGENT = 0.D0
      TANGENTVAL = 0.D0

      TANGENT(1) = PJ*FK - PK*FJ
      TANGENT(2) = PK*FI - PI*FK
      TANGENT(3) = PI*FJ - PJ*FI

      CALL L2_NORM(TANGENT,3,TANGENTVAL)
      IF(TANGENTVAL.EQ.0.D0) RETURN

      DO K = 1,3
         TANGENT(K) = TANGENT(K)/TANGENTVAL
      ENDDO

      END

C======================================================================
      SUBROUTINE FINDCURVATURE(CP,CF,I,J,PT,TANGENT,CURVATURE,
     &                         CURVATUREVAL)
C======================================================================
      IMPLICIT NONE

      REAL*8 CP(8,6),CF(8,6)
      REAL*8 PT(3),TANGENT(3),DELS1(3),DELS2(3),MATRIX(2,2),RHS(2),
     &       WORK(10),CURVATURE(3),CURVATUREVAL,S(2),DET,TOL
      INTEGER I,J,K,RANK,INFO
      DATA TOL /1.D-6/

      CALL GETMATRIX(CP,CF,I,J,PT,MATRIX,DELS1,DELS2,DET)

      IF(DET.LT.TOL) THEN
         CURVATUREVAL = 0.D0
         RETURN
      ENDIF

      CALL GETRHS(CP,CF,I,J,PT,TANGENT,RHS)
      CALL DGELSS(2,2,1,MATRIX,2,RHS,2,S,-1.D0,RANK,WORK,10,INFO)

! saumik - r'' = beta*dels1 + gamma*dels2
      CURVATURE = RHS(1)*DELS1 + RHS(2)*DELS2

      CALL L2_NORM(CURVATURE,3,CURVATUREVAL)
      IF(CURVATUREVAL.EQ.0.D0) RETURN

      DO K = 1,3
         CURVATURE(K) = CURVATURE(K)/CURVATUREVAL
      ENDDO

      END

C======================================================================
      SUBROUTINE GETRHS(CP,CF,I,J,PT,TANGENT,RHS)
C======================================================================
      IMPLICIT NONE

      REAL*8 CP(8,6),CF(8,6),PT(3)
      REAL*8 TANGENT(3),RHS(2)
      REAL*8 HESSIAN1(3,3),HESSIAN2(3,3)
      REAL*8 HESS1_T(3),HESS2_T(3)
      INTEGER I,J

      HESSIAN1 = 0.D0
      HESSIAN2 = 0.D0

      HESSIAN1(1,2) = CP(1,I)*PT(3) + CP(2,I)
      HESSIAN1(2,1) = HESSIAN1(1,2)
      HESSIAN1(1,3) = CP(1,I)*PT(2) + CP(4,I)
      HESSIAN1(3,1) = HESSIAN1(1,3)
      HESSIAN1(2,3) = CP(1,I)*PT(1) + CP(3,I)
      HESSIAN1(3,2) = HESSIAN1(2,3)

      CALL DGEMV('N',3,3,1.D0,HESSIAN1,3,TANGENT,1,0.D0,HESS1_T,1)

      RHS(1) = TANGENT(1)*HESS1_T(1) + TANGENT(2)*HESS1_T(2) +
     &         TANGENT(3)*HESS1_T(3)
      RHS(1) = -1.D0*RHS(1)

      HESSIAN2(1,2) = CF(1,J)*PT(3) + CF(2,J)
      HESSIAN2(2,1) = HESSIAN1(1,2)
      HESSIAN2(1,3) = CF(1,J)*PT(2) + CF(4,J)
      HESSIAN2(3,1) = HESSIAN1(1,3)
      HESSIAN2(2,3) = CF(1,J)*PT(1) + CF(3,J)
      HESSIAN2(3,2) = HESSIAN1(2,3)

      CALL DGEMV('N',3,3,1.D0,HESSIAN2,3,TANGENT,1,0.D0,HESS2_T,1)

      RHS(2) = TANGENT(1)*HESS2_T(1) + TANGENT(2)*HESS2_T(2) +
     &         TANGENT(3)*HESS2_T(3)
      RHS(2) = -1.D0*RHS(2)

      END

C======================================================================
      SUBROUTINE NEWTON(CP,CF,I,J,PT)
C======================================================================
      IMPLICIT NONE

      REAL*8 CP(8,6),CF(8,6)
      REAL*8 PT(3),MATRIX(2,2),RHS(2),DELTA(3),DELS1(3),DELS2(3),
     &       TOL,DELTANORM,PTNORM,WORK(10),S(2),DET
      INTEGER I,J,RANK,INFO,ITER
      DATA TOL/1.D-8/

      CALL L2_NORM(PT,3,PTNORM)
      DELTANORM = PTNORM
      ITER = 0

      DO WHILE(DELTANORM.GT.TOL*PTNORM)
         ITER = ITER + 1
         CALL GETMATRIX(CP,CF,I,J,PT,MATRIX,DELS1,DELS2,DET)
         CALL GETRHS_NEWTON(CP,CF,I,J,PT,RHS)
         CALL DGELSS(2,2,1,MATRIX,2,RHS,2,S,-1.D0,RANK,WORK,10,INFO)

         DELTA = RHS(1)*DELS1 + RHS(2)*DELS2
         PT = PT + DELTA
         CALL L2_NORM(DELTA,3,DELTANORM)
      ENDDO

      RETURN
      END

C======================================================================
      SUBROUTINE GETMATRIX(CP,CF,I,J,PT,MATRIX,DELS1,DELS2,DET)
C======================================================================
      IMPLICIT NONE

      REAL*8 CP(8,6),CF(8,6),PT(3)
      REAL*8 MATRIX(2,2),DELS1(3),DELS2(3),DET
      INTEGER I,J

      DELS1(1) = CP(1,I)*PT(2)*PT(3)+CP(2,I)*PT(2)+CP(4,I)*PT(3)+CP(5,I)
      DELS1(2) = CP(1,I)*PT(1)*PT(3)+CP(2,I)*PT(1)+CP(3,I)*PT(3)+CP(6,I)
      DELS1(3) = CP(1,I)*PT(1)*PT(2)+CP(3,I)*PT(2)+CP(4,I)*PT(1)+CP(7,I)

      DELS2(1) = CF(1,J)*PT(2)*PT(3)+CF(2,J)*PT(2)+CF(4,J)*PT(3)+CF(5,J)
      DELS2(2) = CF(1,J)*PT(1)*PT(3)+CF(2,J)*PT(1)+CF(3,J)*PT(3)+CF(6,J)
      DELS2(3) = CF(1,J)*PT(1)*PT(2)+CF(3,J)*PT(2)+CF(4,J)*PT(1)+CF(7,J)

      MATRIX = 0.D0
      MATRIX(1,1) = DELS1(1)**2.D0 + DELS1(2)**2.D0 + DELS1(3)**2.D0
      MATRIX(1,2) = DELS1(1)*DELS2(1) + DELS1(2)*DELS2(2) +
     &              DELS1(3)*DELS2(3)
      MATRIX(2,1) = MATRIX(1,2)
      MATRIX(2,2) = DELS2(1)**2.D0 + DELS2(2)**2.D0 + DELS2(3)**2.D0

      DET = DABS(MATRIX(1,1)*MATRIX(2,2) - MATRIX(1,2)*MATRIX(2,1))

      END

C======================================================================
      SUBROUTINE GETRHS_NEWTON(CP,CF,I,J,PT,RHS)
C======================================================================
      IMPLICIT NONE

      REAL*8 CP(8,6),CF(8,6),PT(3)
      REAL*8 RHS(2)
      INTEGER I,J

      RHS(1)=CP(1,I)*PT(1)*PT(2)*PT(3)+CP(2,I)*PT(1)*PT(2)+
     &       CP(3,I)*PT(2)*PT(3)+CP(4,I)*PT(1)*PT(3)+CP(5,I)*PT(1)+
     &       CP(6,I)*PT(2)+CP(7,I)*PT(3)+1.D0
      RHS(1) = -1.D0*RHS(1)

      RHS(2)=CF(1,J)*PT(1)*PT(2)*PT(3)+CF(2,J)*PT(1)*PT(2)+
     &       CF(3,J)*PT(2)*PT(3)+CF(4,J)*PT(1)*PT(3)+CF(5,J)*PT(1)+
     &       CF(6,J)*PT(2)+CF(7,J)*PT(3)+1.D0
      RHS(2) = -1.D0*RHS(2)

      END

C======================================================================
      SUBROUTINE FLOWTOMECHANICS (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP
      REAL*8  XF1,YF1,ZF1,XP1,YP1,ZP1
      REAL*8  XF2,YF2,ZF2,XP2,YP2,ZP2

      DO KF=1,KDIMF
         DO JF=1,JDIMF
            DO IFL=1,IDIMF
               IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
               XF1=XC_F(IFL,JF,KF)
               YF1=YC_F(IFL,JF,KF)
               ZF1=ZC_F(IFL,JF,KF)
               XF2=XC_F(IFL+1,JF+1,KF+1)
               YF2=YC_F(IFL+1,JF+1,KF+1)
               ZF2=ZC_F(IFL+1,JF+1,KF+1)
               DO KP=1,KDIMP
                  DO JP=1,JDIMP
                     DO IP=1,IDIMP
                        IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
                        XP1=XC_P(IP,JP,KP)
                        YP1=YC_P(IP,JP,KP)
                        ZP1=ZC_P(IP,JP,KP)
                        XP2=XC_P(IP+1,JP+1,KP+1)
                        YP2=YC_P(IP+1,JP+1,KP+1)
                        ZP2=ZC_P(IP+1,JP+1,KP+1)
                        IF ((XP1.EQ.XF1).AND.(YP1.EQ.YF1)
     &                 .AND.(ZP1.EQ.ZF1).AND.(XP2.EQ.XF2)
     &                 .AND.(YP2.EQ.YF2).AND.(ZP2.EQ.ZF2))THEN
                            ARRAYP(IP,JP,KP)=ARRAYF(IFL,JF,KF)
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
      END

C======================================================================
      SUBROUTINE MECHANICSTOFLOW (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP
      REAL*8  XF1,YF1,ZF1,XP1,YP1,ZP1
      REAL*8  XF2,YF2,ZF2,XP2,YP2,ZP2

      DO KF=1,KDIMF
         DO JF=1,JDIMF
            DO IFL=1,IDIMF
               IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
               XF1=XC_F(IFL,JF,KF)
               YF1=YC_F(IFL,JF,KF)
               ZF1=ZC_F(IFL,JF,KF)
               XF2=XC_F(IFL+1,JF+1,KF+1)
               YF2=YC_F(IFL+1,JF+1,KF+1)
               ZF2=ZC_F(IFL+1,JF+1,KF+1)
               DO KP=1,KDIMP
                  DO JP=1,JDIMP
                     DO IP=1,IDIMP
                        IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
                        XP1=XC_P(IP,JP,KP)
                        YP1=YC_P(IP,JP,KP)
                        ZP1=ZC_P(IP,JP,KP)
                        XP2=XC_P(IP+1,JP+1,KP+1)
                        YP2=YC_P(IP+1,JP+1,KP+1)
                        ZP2=ZC_P(IP+1,JP+1,KP+1)
                        IF ((XP1.EQ.XF1).AND.(YP1.EQ.YF1)
     &                 .AND.(ZP1.EQ.ZF1).AND.(XP2.EQ.XF2)
     &                 .AND.(YP2.EQ.YF2).AND.(ZP2.EQ.ZF2))THEN
                            ARRAYF(IFL,JF,KF)=ARRAYP(IP,JP,KP)
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO
      END

C======================================================================
      SUBROUTINE FLOWTOMECHANICSNONMATCHING (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP,M
      INTEGER IOFFP,JOFFP,KOFFP,IOFF,JOFF,KOFF,NERR,LOCP,LOCF
      INTEGER IIP,JJP,KKP,IIF,JJF,KKF,COUNTP
      REAL*8 XP(3,8),XF(3,8),TEMP,RATIO,TOL
      DATA TOL /1.D-2/

      CALL BLKOFF(1,IOFFP,JOFFP,KOFFP,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

      COUNTP = 0
      DO KP = KL1P,KL2P
         DO JP = JL1VP(KP),JL2VP(KP)
            DO IP = IL1P,IL2P
               IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
               IIP = IP + IOFFP - 1
               JJP = JP + JOFFP - 1
               KKP = KP + KOFFP - 1
!               LOCP = (IIP+1-OB_LAYER)*NZDIM(1)*NYDIM(1)
!     &                +KKP*NYDIM(1)+JJP+1
               LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP

! saumik - skip porohex elements not talking to flow
               IF(SKIP(LOCP).EQ.1) CYCLE
               COUNTP = COUNTP + 1
               TEMP = 0.D0
               DO KF = KL1F,KL2F
                  DO JF = JL1VF(KF),JL2VF(KF)
                     DO IFL = IL1F,IL2F
                        IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
                        IIF = IFL + IOFF - 1
                        JJF = JF  + JOFF - 1
                        KKF = KF  + KOFF - 1
!                        LOCF = IIF*NZDIM(NBLK)*NYDIM(NBLK)+
!     &                         KKF*NYDIM(NBLK)+JJF+1
                        LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF
! saumik - loop over second index of vol1 array
                        DO M = 1,VAL1(LOCP)
                           IF(LOCF.EQ.VAL2(COUNTP,M)) THEN
                              IF(EVOLP(IP,JP,KP).NE.0.D0) THEN
                              RATIO = VOL1(COUNTP,M)/EVOLP(IP,JP,KP)
                              IF(RATIO.GT.TOL) THEN
                              TEMP = TEMP + ARRAYF(IFL,JF,KF)*RATIO
                              ENDIF
                              ENDIF
                           ENDIF
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
               ARRAYP(IP,JP,KP) = TEMP
            ENDDO
         ENDDO
      ENDDO

      END

C======================================================================
      SUBROUTINE MECHANICSTOFLOWNONMATCHING (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP,M
      INTEGER IOFFP,JOFFP,KOFFP,IOFF,JOFF,KOFF,NERR,LOCP,LOCF
      INTEGER IIP,JJP,KKP,IIF,JJF,KKF,COUNTF
      REAL*8 XP(3,8),XF(3,8),TEMP
      LOGICAL ONCEONLY

      CALL BLKOFF(1,IOFFP,JOFFP,KOFFP,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

      COUNTF = 0
      DO KF = KL1F,KL2F
         DO JF = JL1VF(KF),JL2VF(KF)
            DO IFL = IL1F,IL2F
               IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
               IIF = IFL + IOFF - 1
               JJF = JF  + JOFF - 1
               KKF = KF  + KOFF - 1
!               LOCF = IIF*NZDIM(NBLK)*NYDIM(NBLK)+
!     &                         KKF*NYDIM(NBLK)+JJF+1
               LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF
               TEMP = 0.D0
               ONCEONLY = .TRUE.
               DO KP = KL1P,KL2P
                  DO JP = JL1VP(KP),JL2VP(KP)
                     DO IP = IL1P,IL2P
                        IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
                        IIP = IP + IOFFP - 1
                        JJP = JP + JOFFP - 1
                        KKP = KP + KOFFP - 1
!                        LOCP = (IIP+1-OB_LAYER)*NZDIM(1)*NYDIM(1)
!     &                         +KKP*NYDIM(1)+JJP+1
                        LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP

! saumik - skip mechanics elements with no connection to payzone
                        IF(SKIP(LOCP).EQ.1) CYCLE

! saumik - flow element inside a mechanics element
                        IF(VAL3(LOCF).EQ.0) THEN
                           IF(LOCP.EQ.INFLAG(LOCF))
     &                     ARRAYF(IFL,JF,KF) = ARRAYP(IP,JP,KP)

! saumik - flow element intersects mechanics element
                        ELSE
                           IF(ONCEONLY) COUNTF = COUNTF + 1
                           ONCEONLY = .FALSE.

! saumik - loop over second index of vol2 array
                           DO M = 1,VAL3(LOCF)
                              IF(LOCP.EQ.VAL4(COUNTF,M)) THEN
                                 IF(EVOLF(IFL,JF,KF).NE.0.D0) THEN
                                 TEMP = TEMP + ARRAYP(IP,JP,KP)*
     &                                  VOL2(COUNTF,M)/EVOLF(IFL,JF,KF)
                                 ENDIF
                              ENDIF
                           ENDDO
                           ARRAYF(IFL,JF,KF) = TEMP
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO

      END

C======================================================================
      SUBROUTINE BULKUPSCALE (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP,M
      INTEGER IOFFP,JOFFP,KOFFP,IOFF,JOFF,KOFF,NERR,LOCP,LOCF
      INTEGER IIP,JJP,KKP,IIF,JJF,KKF,COUNTP
      REAL*8 XP(3,8),XF(3,8),TEMP,RATIO,TOL,TEMPA
      DATA TOL /1.D-2/

      CALL BLKOFF(1,IOFFP,JOFFP,KOFFP,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

      COUNTP = 0
      DO KP = KL1P,KL2P
         DO JP = JL1VP(KP),JL2VP(KP)
            DO IP = IL1P,IL2P
               IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
               IIP = IP + IOFFP - 1
               JJP = JP + JOFFP - 1
               KKP = KP + KOFFP - 1
               LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP

! SAUMIK - SKIP POROHEX ELEMENTS NOT TALKING TO FLOW
               IF(SKIP(LOCP).EQ.1) CYCLE
               COUNTP = COUNTP + 1
               TEMP = 0.D0
               TEMPA = 0.D0
               DO KF = KL1F,KL2F
                  DO JF = JL1VF(KF),JL2VF(KF)
                     DO IFL = IL1F,IL2F
                        IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
                        IIF = IFL + IOFF - 1
                        JJF = JF  + JOFF - 1
                        KKF = KF  + KOFF - 1
                        LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF
! SAUMIK - LOOP OVER SECOND INDEX OF VOL1 ARRAY
                        DO M = 1,VAL1(LOCP)
                           IF(LOCF.EQ.VAL2(COUNTP,M)) THEN
                              IF(EVOLP(IP,JP,KP).NE.0.D0) THEN
                              RATIO = VOL1(COUNTP,M)/EVOLP(IP,JP,KP)
                              IF(RATIO.GT.TOL) THEN
                              TEMP = TEMP + 1.D0/ARRAYF(IFL,JF,KF)*
     &                               VOL1(COUNTP,M)/EVOLP(IP,JP,KP)
                              TEMPA = TEMPA +
     &                                1.D0/(1.D0-BIOTAFLOW(IFL,JF,KF))*
     &                                VOL1(COUNTP,M)/EVOLP(IP,JP,KP)
                              ENDIF
                              ENDIF
                           ENDIF
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
               IF(TEMP.NE.0.D0) ARRAYP(IP,JP,KP) = 1.D0/TEMP
               IF(TEMPA.NE.0.D0) BIOTA(IP,JP,KP) = 1.D0-1.D0/TEMPA
            ENDDO
         ENDDO
      ENDDO

      END

C======================================================================
      SUBROUTINE FLOWTOMECHANICSHETERO (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP,M
      INTEGER IOFFP,JOFFP,KOFFP,IOFF,JOFF,KOFF,NERR,LOCP,LOCF
      INTEGER IIP,JJP,KKP,IIF,JJF,KKF,COUNTP
      REAL*8 XP(3,8),XF(3,8),TEMP,RATIO,TOL
      REAL*8 BULKFLOW,BULKPORO,ADD
      DATA TOL /1.D-2/

      CALL BLKOFF(1,IOFFP,JOFFP,KOFFP,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

      COUNTP = 0
      DO KP = KL1P,KL2P
         DO JP = JL1VP(KP),JL2VP(KP)
            DO IP = IL1P,IL2P
               IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
               IIP = IP + IOFFP - 1
               JJP = JP + JOFFP - 1
               KKP = KP + KOFFP - 1
               LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP

               IF(SKIP(LOCP).EQ.1) CYCLE
               COUNTP = COUNTP + 1
               TEMP = 0.D0
               DO KF = KL1F,KL2F
                  DO JF = JL1VF(KF),JL2VF(KF)
                     DO IFL = IL1F,IL2F
                        IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
                        IIF = IFL + IOFF - 1
                        JJF = JF  + JOFF - 1
                        KKF = KF  + KOFF - 1
                        LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF
                        DO M = 1,VAL1(LOCP)
                           IF(LOCF.EQ.VAL2(COUNTP,M)) THEN
                              IF(EVOLP(IP,JP,KP).NE.0.D0) THEN
                              RATIO = VOL1(COUNTP,M)/EVOLP(IP,JP,KP)
                              IF(RATIO.GT.TOL) THEN
                              ADD = ARRAYF(IFL,JF,KF)*RATIO
                              !BULKFLOW IS BULK MODULUS OF FLOW ELEMENT
                              BULKFLOW = MODULFLOW(IFL,JF,KF)/3.D0
     &                                 /(1.D0-2.D0*POISSFLOW(IFL,JF,KF))
                              ADD = ADD*BIOTAFLOW(IFL,JF,KF)/BULKFLOW
                              !BULKPORO IS BULK MODULUS OF POROMECHANICS ELEMENT
                              BULKPORO = MODUL(IP,JP,KP)/3.D0
     &                                 /(1.D0-2.D0*POISS(IP,JP,KP))
                              ADD = ADD*BULKPORO/BIOTA(IP,JP,KP)
                              TEMP = TEMP + ADD
                              ENDIF
                              ENDIF
                           ENDIF
                        ENDDO
                     ENDDO
                  ENDDO
               ENDDO
               ARRAYP(IP,JP,KP) = TEMP
            ENDDO
         ENDDO
      ENDDO

      END

C======================================================================
      SUBROUTINE MECHANICSTOFLOWHETERO (IDIMP,JDIMP,KDIMP,IL1P,
     &           IL2P,JL1VP,JL2VP,KL1P,KL2P,KEYOUTP,IDIMF,JDIMF,KDIMF,
     &           IL1F,IL2F,JL1VF,JL2VF,KL1F,KL2F,KEYOUTF,ARRAYP,
     &           XC_P,YC_P,ZC_P,EVOLP,ARRAYF,XC_F,YC_F,ZC_F,EVOLF,NBLK,
     &           MODUL,MODULFLOW,POISS,POISSFLOW,BIOTA,BIOTAFLOW)
C======================================================================
      USE eprojmod
      IMPLICIT NONE

      include 'control.h'
      include 'blkary.h'

      INTEGER IDIMP,JDIMP,KDIMP,IL1P,IL2P,KL1P,KL2P,NBLK
      INTEGER IDIMF,JDIMF,KDIMF,IL1F,IL2F,KL1F,KL2F
      INTEGER JL1VP(KDIMP),JL2VP(KDIMP),JL1VF(KDIMF),JL2VF(KDIMF)
      INTEGER KEYOUTP(IDIMP,JDIMP,KDIMP),KEYOUTF(IDIMF,JDIMF,KDIMF)
      REAL*8  ARRAYP(IDIMP,JDIMP,KDIMP),ARRAYF(IDIMF,JDIMF,KDIMF)
      REAL*8  EVOLP(IDIMP,JDIMP,KDIMP),EVOLF(IDIMF,JDIMF,KDIMF)

      REAL*8  MODUL(IDIMP,JDIMP,KDIMP),MODULFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  POISS(IDIMP,JDIMP,KDIMP),POISSFLOW(IDIMF,JDIMF,KDIMF)
      REAL*8  BIOTA(IDIMP,JDIMP,KDIMP),BIOTAFLOW(IDIMF,JDIMF,KDIMF)

      REAL*8  XC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        YC_P(IDIMP+1,JDIMP+1,KDIMP+1),
     &        ZC_P(IDIMP+1,JDIMP+1,KDIMP+1)
      REAL*8  XC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        YC_F(IDIMF+1,JDIMF+1,KDIMF+1),
     &        ZC_F(IDIMF+1,JDIMF+1,KDIMF+1)
      INTEGER KF,JF,IFL,KP,JP,IP,M
      INTEGER IOFFP,JOFFP,KOFFP,IOFF,JOFF,KOFF,NERR,LOCP,LOCF
      INTEGER IIP,JJP,KKP,IIF,JJF,KKF,COUNTF
      REAL*8 XP(3,8),XF(3,8),TEMP
      LOGICAL ONCEONLY

      REAL*8 BULKFLOW,BULKPORO,ADD

      CALL BLKOFF(1,IOFFP,JOFFP,KOFFP,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

      COUNTF = 0
      DO KF = KL1F,KL2F
         DO JF = JL1VF(KF),JL2VF(KF)
            DO IFL = IL1F,IL2F
               IF(KEYOUTF(IFL,JF,KF).NE.1) CYCLE
               IIF = IFL + IOFF - 1
               JJF = JF  + JOFF - 1
               KKF = KF  + KOFF - 1
               LOCF = (IFL-1)*KDIMF*JDIMF + (KF-1)*JDIMF + JF
               TEMP = 0.D0
               ONCEONLY = .TRUE.
               DO KP = KL1P,KL2P
                  DO JP = JL1VP(KP),JL2VP(KP)
                     DO IP = IL1P,IL2P
                        IF(KEYOUTP(IP,JP,KP).NE.1) CYCLE
                        IIP = IP + IOFFP - 1
                        JJP = JP + JOFFP - 1
                        KKP = KP + KOFFP - 1
                        LOCP = (IP-1)*KDIMP*JDIMP + (KP-1)*JDIMP + JP

                        IF(SKIP(LOCP).EQ.1) CYCLE

                        IF(VAL3(LOCF).EQ.0) THEN
                           IF(LOCP.EQ.INFLAG(LOCF)) THEN
                           !BULKFLOW IS BULK MODULUS OF FLOW ELEMENT
                           BULKFLOW = MODULFLOW(IFL,JF,KF)/3.D0
     &                              /(1.D0-2.D0*POISSFLOW(IFL,JF,KF))
                           !BULKPORO IS BULK MODULUS OF POROMECHANICS ELEMENT
                           BULKPORO = MODUL(IP,JP,KP)/3.D0
     &                              /(1.D0-2.D0*POISS(IP,JP,KP))
                           ARRAYF(IFL,JF,KF) = BULKPORO/BULKFLOW
     &                                         *ARRAYP(IP,JP,KP)
                           ENDIF
                        ELSE
                           IF(ONCEONLY) COUNTF = COUNTF + 1
                           ONCEONLY = .FALSE.

                           DO M = 1,VAL3(LOCF)
                              IF(LOCP.EQ.VAL4(COUNTF,M)) THEN
                                 IF(EVOLF(IFL,JF,KF).NE.0.D0) THEN
                                 ADD = ARRAYP(IP,JP,KP)*
     &                                 VOL2(COUNTF,M)/EVOLF(IFL,JF,KF)
                                 BULKFLOW = MODULFLOW(IFL,JF,KF)/3.D0
     &                                 /(1.D0-2.D0*POISSFLOW(IFL,JF,KF))
                                 BULKPORO = MODUL(IP,JP,KP)/3.D0
     &                                 /(1.D0-2.D0*POISS(IP,JP,KP))
                                 ADD = ADD*BULKPORO/BULKFLOW
                                 TEMP = TEMP + ADD
                                 ENDIF
                              ENDIF
                           ENDDO
                           ARRAYF(IFL,JF,KF) = TEMP
                        ENDIF
                     ENDDO
                  ENDDO
               ENDDO
            ENDDO
         ENDDO
      ENDDO

      END

