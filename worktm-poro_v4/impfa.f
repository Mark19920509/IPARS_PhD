C  IMPFA.F - INITIALIZE DATA IN GRID-ELEMENT ARRAYS - MPFA MODELS

C  ROUTINES IN THIS MODULE:
C  SUBROUTINE DEPTH3 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                    KL1,KL2,KEYOUT,NBLK,DEPTH,XC,YC,ZC)
C  SUBROUTINE CALLWELLIJK3()
C  SUBROUTINE WELLIJK2 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C                       KL2,KEYOUT,NBLK,NW,XPERM,YPERM,ZPERM,
C                       XYPERM,YZPERM,XZPERM,XC,YC,ZC)
C  SUBROUTINE WELLIJK3 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C                       KL2,KEYOUT,NBLK,NW,XPERM,YPERM,ZPERM,
C                       XYPERM,YZPERM,XZPERM,XC,YC,ZC)
C  SUBROUTINE GET_CLOSEST_PLANE(PLANE,FACECOOR)
C  SUBROUTINE MAP_TO_PLANE(PLANE,COOR,NEWCOOR)
C  SUBROUTINE INTERSECT_PLANE_LINE(PLANE,LINE1,LINE2,NEWCOOR,FLAG)
C  SUBROUTINE MPFA_SET_AINV_TRAN(KERR)
C  SUBROUTINE CALCAINVTRAN(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                         KL1,KL2,KEYOUT,NBLK,KEYOUTCR,VOLPROP,VOLDIM,
C                         FACEPROP,FACEDIM,PERMINV,AINV,TRAN)
C  SUBROUTINE MPFA_INIT(KERR)
C  SUBROUTINE CALCMPFACRPROP(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
C                 JL2V,KL1,KL2,KEYOUT,NBLK,KEYOUTCR,VOLPROP,FACEPROP)
C  SUBROUTINE CALCFACES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                 KL1,KL2,KEYOUT,NBLK,XC,YC,ZC,DEPTH,FACEPROP)
C  SUBROUTINE GETFACECENTER(I1,J1,K1,I2,J2,K2,I3,J3,K3,I4,J4,
C                  K4,XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
C  SUBROUTINE GETFACEPROPVAL (I1,J1,K1,F1,I2,J2,K2,F2,I3,
C                  J3,K3,F3,I4,J4,K4,F4,MPFA_BTYPE,IDIM,JDIM,
C                   KDIM,FACEPROP)
C  SUBROUTINE UPDATEFACES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2VC,KL1,
C                  KL2,KEYOUT,NBLK,FACEPROP)
C  SUBROUTINE DNFROMNEIGHBOR(IN,JN,KN,I,J,K,INDEX,FACEPROP,
C                       IDIM,JDIM,KDIM)
C  SUBROUTINE CALCVOLFACEDIM(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C  SUBROUTINE CALCAREA(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C  SUBROUTINE ELEMENTAREA(X,FAREA)
C  SUBROUTINE GETAREA(X,I1,I2,I3,I4,AREA)
C  SUBROUTINE ADDFACE(FAREA,I,J,K,FACEAREA,IDIM,JDIM,KDIM)
C  SUBROUTINE MPFA_SET_AINV_TRAN(KERR)
C  SUBROUTINE CALCAINVTRAN(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C     &     KL1,KL2,KEYOUT,NBLK,KEYOUTCR,VOLPROP,VOLDIM,
C     &     FACEPROP,FACEDIM,PERMINV,AINV,TRAN)
C  SUBROUTINE GETAINVTRAN(AINV,TRAN,PERMINV,I,J,K,
C     &                       FINDEX,VINDEX,FPROP,VPROP,
C     &                       IDIM,JDIM,KDIM,FDIM,VDIM)
C  SUBROUTINE DOROCK2 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C     &                   KL2,KEYOUT,NBLK,DEPTH,POR,XPERM,YPERM,ZPERM)
C  CODE HISTORY:

C  GURPREET SINGH      2011-2014
C  BEN GANIS           05/01/16    MFMFE_BRICKS AND FIX FOR WELLIJK3

C*********************************************************************
      SUBROUTINE DEPTH3 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
     &                   KEYOUT,NBLK,DEPTH,XC,YC,ZC)
C*********************************************************************

C  Calculate block center depth array for corner point grid option.
C  This is a work routine.
C  DEPTH = 0. at x=0., y=0., z=0.
C  DEPTH(I,J,K) = Block center depth in feet for fault block NBLK
C                 (output, REAL*8)
C  XC(I,J,K),YC(I,J,K),ZC(I,J,K) = Corner point locations for fault
C                 block NBLK (input, REAL*4)

C*********************************************************************
      IMPLICIT NONE

      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      REAL*8 X,Y,Z,DEPTH(IDIM,JDIM,KDIM)
      REAL*8 XC(IDIM+1,JDIM+1,KDIM+1),YC(IDIM+1,JDIM+1,KDIM+1),
     &       ZC(IDIM+1,JDIM+1,KDIM+1)
      INTEGER I,J,K,KL1,KL2,JL1V(KDIM),JL2V(KDIM),IL1,IL2,
     &         IDIM,JDIM,KDIM,LDIM,NBLK,KEYOUT(IDIM,JDIM,KDIM)

      DO K=2,KDIM
      DO J=2,JDIM
      DO I=2,IDIM
      X=XC(I,J,K)
      X=0.125D0*(X+XC(I,J,K-1)+XC(I,J-1,K)+XC(I,J-1,K-1)+
     &   XC(I-1,J,K)+XC(I-1,J,K-1)+XC(I-1,J-1,K)+XC(I-1,J-1,K-1))
      Y=YC(I,J,K)
      Y=0.125D0*(Y+YC(I,J,K-1)+YC(I,J-1,K)+YC(I,J-1,K-1)+
     &   YC(I-1,J,K)+YC(I-1,J,K-1)+YC(I-1,J-1,K)+YC(I-1,J-1,K-1))
      Z=ZC(I,J,K)
      Z=0.125D0*(Z+ZC(I,J,K-1)+ZC(I,J-1,K)+ZC(I,J-1,K-1)+
     &   ZC(I-1,J,K)+ZC(I-1,J,K-1)+ZC(I-1,J-1,K)+ZC(I-1,J-1,K-1))
      DEPTH(I-1,J-1,K-1)=DOWN(1,NBLK)*X+DOWN(2,NBLK)*Y+DOWN(3,NBLK)*Z
      ENDDO
      ENDDO
      ENDDO

      END

! bag8
c======================================================================
      SUBROUTINE SET_MFMFE_BRICKS(IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &   JL1V,JL2V,KL1,KL2,KEYOUT,NBLK,XC,YC,ZC)
c======================================================================
c  This subroutine sets XC,YC,ZC 3D arrays using brick geometry data
c  stored in XREC,YREC,ZREC 1D arrays.
c======================================================================
      IMPLICIT NONE
      INCLUDE 'blkary.h'
      INCLUDE 'control.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &   KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK
      REAL*8 XC(IDIM+1,JDIM+1,KDIM+1),YC(IDIM+1,JDIM+1,KDIM+1),
     &       ZC(IDIM+1,JDIM+1,KDIM+1)
      INTEGER I,J,K,IOFF,JOFF,KOFF,IERR

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,IERR)
      IF (IERR.NE.0) STOP 'Problem in SET_MFMFE_BRICKS'

! bag8 - To match behavior of GETGRDA(XC,YC,ZC), we must fill coords of
!        both entire bounding and all ghost layers.
      DO K=1,KDIM+1
      DO J=1,JDIM+1
      DO I=1,IDIM+1
        IF ((I+IOFF.GE.1).AND.(I+IOFF.LE.NXDIM(NBLK)+1).AND.
     &      (J+JOFF.GE.1).AND.(J+JOFF.LE.NYDIM(NBLK)+1).AND.
     &      (K+KOFF.GE.1).AND.(K+KOFF.LE.NZDIM(NBLK)+1)) THEN
          XC(I,J,K)=XREC(I+IOFF,NBLK)
          YC(I,J,K)=YREC(J+JOFF,NBLK)
          ZC(I,J,K)=ZREC(K+KOFF,NBLK)
        ENDIF
      ENDDO
      ENDDO
      ENDDO

      END

c======================================================================
      SUBROUTINE WELLIJK2 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &     KL2,KEYOUT,NBLK,NW,XPERM,YPERM,ZPERM,XYPERM,YZPERM,XZPERM,
     &     XC,YC,ZC)
c======================================================================
C  Routine locates the grid elements of a well for the corner-point
C  grid option.  Assigns well to a processor.  Computes open interval,
C  permeability normal to the wellbore, and default geometric factor
C  for each element penatrated.  This is a work routine. More additions
C  later for general geometry.
C
C  NW = Well number (input, INTEGER)
C
C  XPERM(I,J,K),YPERM(I,J,K),ZPERM(I,J,K) = Element permeabilities in
C  the x,y, and z directions.
C  XYPERM(I,J,K),YZPERM(I,J,K),XZPERM(I,J,K) =
C
C MORE THAN ONE PROCESSOR MAY CLAIM PARTS OF A WELL
c======================================================================
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'wells.h'
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),IX,JY,KZ,IC
      REAL*4 XPERM(IDIM,JDIM,KDIM),YPERM(IDIM,JDIM,KDIM),
     &       ZPERM(IDIM,JDIM,KDIM),XYPERM(IDIM,JDIM,KDIM),
     &       YZPERM(IDIM,JDIM,KDIM),XZPERM(IDIM,JDIM,KDIM)
      REAL*8 XC(IDIM+1,JDIM+1,KDIM+1),YC(IDIM+1,JDIM+1,KDIM+1),
     &       ZC(IDIM+1,JDIM+1,KDIM+1)
      REAL*8 XW1,XW2,YW1,YW2,ZW1,ZW2,XT,YT,ZT,
     & DXW,DYW,DZW,TOLW,DUM1,DUM2,DUM3,XI(6),YI(6),ZI(6),DMM,DLL
      REAL*8 XG(8),YG(8),ZG(8),XX(3,8)
      INTEGER L
      REAL*8 VOLH

      IF (LEVELE.AND.BUGKEY(1)) WRITE (NFBUG,*)'PROC',MYPRC,
     & ', BLOCK',NBLK,', WELL',NW,' ENTERING SUBROUTINE WELIJK2'

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,MERR)

C  LOOP OVER WELL INTERVALS

      NI=NWELLI(NW)

      DO 1 N=1,NI
      IF (NBWELI(N,NW).NE.NBLK) GO TO 1
      XW1=WELLTOP(1,N,NW)
      XW2=WELLBOT(1,N,NW)
      YW1=WELLTOP(2,N,NW)
      YW2=WELLBOT(2,N,NW)
      ZW1=WELLTOP(3,N,NW)
      ZW2=WELLBOT(3,N,NW)
      DXW=XW2-XW1
      DYW=YW2-YW1
      DZW=ZW2-ZW1

      TOLW=1.D-8*(DXW**2+DYW**2+DZW**2)
      IF (TOLW.LE.0.D0) GO TO 1

C  LOOP OVER GRID ELEMENTS

      DO 2 K=KL1,KL2
      KG=K+KOFF
      JL1=JL1V(K)
      JL2=JL2V(K)

      DO 3 J=JL1,JL2
      JG=J+JOFF

      DO 4 I=IL1,IL2
      IF (KEYOUT(I,J,K).LE.0) GO TO 4
      IG=I+IOFF

      IC=0
      DO KZ=K,K+1
      DO JY=J,J+1
      DO IX=I,I+1
            IC=IC+1
            ZG(IC)=ZC(IX,JY,KZ)
            YG(IC)=YC(IX,JY,KZ)
            XG(IC)=XC(IX,JY,KZ)
      ENDDO
      ENDDO
      ENDDO

      NIF=0
      IF (XW2.NE.XW1) THEN
         DUM1=(XG(1)-XW1)/DXW
         IF (DUM1.LT.0.D0) DUM1=0.D0
         IF (DUM1.GT.1.D0) DUM1=1.D0
         YT=YW1+DUM1*DYW
         IF ((YG(1)-YT)*(YG(3)-YT).LE.0.D0) THEN
            ZT=ZW1+DUM1*DZW
            IF ((ZG(1)-ZT)*(ZG(5)-ZT).LE.0.D0) THEN
               NIF=NIF+1
               XI(NIF)=XW1+DUM1*DXW
               YI(NIF)=YT
               ZI(NIF)=ZT
            ENDIF
         ENDIF
         DUM1=(XG(2)-XW1)/(XW2-XW1)
         IF (DUM1.LT.0.D0) DUM1=0.D0
         IF (DUM1.GT.1.D0) DUM1=1.D0
         YT=YW1+DUM1*(YW2-YW1)
         IF ((YG(1)-YT)*(YG(3)-YT).LE.0.D0) THEN
            ZT=ZW1+DUM1*(ZW2-ZW1)
            IF ((ZG(1)-ZT)*(ZG(5)-ZT).LE.0.D0) THEN
               NIF=NIF+1
               XI(NIF)=XW1+DUM1*DXW
               YI(NIF)=YT
               ZI(NIF)=ZT
            ENDIF
         ENDIF
      ENDIF

      IF (YW2.NE.YW1) THEN
         DUM1=(YG(1)-YW1)/(YW2-YW1)
         IF (DUM1.LT.0.D0) DUM1=0.D0
         IF (DUM1.GT.1.D0) DUM1=1.D0
         XT=XW1+DUM1*(XW2-XW1)
         IF ((XG(1)-XT)*(XG(2)-XT).LE.0.D0) THEN
            ZT=ZW1+DUM1*(ZW2-ZW1)
            IF ((ZG(1)-ZT)*(ZG(5)-ZT).LE.0.D0) THEN
               NIF=NIF+1
               XI(NIF)=XT
               YI(NIF)=YW1+DUM1*DYW
               ZI(NIF)=ZT
            ENDIF
         ENDIF
         DUM1=(YG(3)-YW1)/(YW2-YW1)
         IF (DUM1.LT.0.D0) DUM1=0.D0
         IF (DUM1.GT.1.D0) DUM1=1.D0
         XT=XW1+DUM1*(XW2-XW1)
         IF ((XG(1)-XT)*(XG(2)-XT).LE.0.D0) THEN
            ZT=ZW1+DUM1*(ZW2-ZW1)
            IF ((ZG(1)-ZT)*(ZG(5)-ZT).LE.0.D0) THEN
               NIF=NIF+1
               XI(NIF)=XT
               YI(NIF)=YW1+DUM1*DYW
               ZI(NIF)=ZT
            ENDIF
         ENDIF
      ENDIF

      IF (ZW2.NE.ZW1) THEN
         DUM1=(ZG(1)-ZW1)/(ZW2-ZW1)
         IF (DUM1.LT.0.D0) DUM1=0.D0
         IF (DUM1.GT.1.D0) DUM1=1.D0
         XT=XW1+DUM1*(XW2-XW1)
         IF ((XG(1)-XT)*(XG(2)-XT).LE.0.D0) THEN
            YT=YW1+DUM1*(YW2-YW1)
            IF ((YG(1)-YT)*(YG(3)-YT).LE.0.D0) THEN
               NIF=NIF+1
               XI(NIF)=XT
               YI(NIF)=YT
               ZI(NIF)=ZW1+DUM1*DZW
            ENDIF
         ENDIF
         DUM1=(ZG(5)-ZW1)/(ZW2-ZW1)
         IF (DUM1.LT.0.D0) DUM1=0.D0
         IF (DUM1.GT.1.D0) DUM1=1.D0
         XT=XW1+DUM1*(XW2-XW1)
         IF ((XG(1)-XT)*(XG(2)-XT).LE.0.D0) THEN
            YT=YW1+DUM1*(YW2-YW1)
            IF ((YG(1)-YT)*(YG(3)-YT).LE.0.D0) THEN
               NIF=NIF+1
               XI(NIF)=XT
               YI(NIF)=YT
               ZI(NIF)=ZW1+DUM1*DZW
            ENDIF
         ENDIF
      ENDIF

      IF (NIF.LT.2) GO TO 4
      DUM1=0.D0
      DO 5 L=2,NIF
      DO 5 M=1,L-1
      DUM2=(XI(M)-XI(L))**2+(YI(M)-YI(L))**2+(ZI(M)-ZI(L))**2
      IF (DUM2.GT.DUM1) THEN
         MM=M
         LL=L
         DUM1=DUM2
      ENDIF
    5 CONTINUE
      IF (DUM1.LT.TOLW) GO TO 4

      NWELPRC(NW)=MYPRC
      NUMELE(NW)=NUMELE(NW)+1
      M=NUMELE(NW)
      NUMELET(NW)=M
      LOCWEL(1,M,NW)=NBLK
      LOCWEL(2,M,NW)=NI
      LOCWEL(3,M,NW)=IG
      LOCWEL(4,M,NW)=JG
      LOCWEL(5,M,NW)=KG
      LOCWEL(6,M,NW)=MYPRC
      ELELEN(M,NW)=SQRT(DUM1)
      DMM=DOWN(1,NBLK)*XI(MM)+DOWN(2,NBLK)*YI(MM)+DOWN(3,NBLK)*ZI(MM)
      DLL=DOWN(1,NBLK)*XI(LL)+DOWN(2,NBLK)*YI(LL)+DOWN(3,NBLK)*ZI(LL)
      ELEDEP(M,NW)=.5D0*(DMM+DLL)
      ELEXYZ(1,M,NW)=.5D0*(XI(MM)+XI(LL))
      ELEXYZ(2,M,NW)=.5D0*(YI(MM)+YI(LL))
      ELEXYZ(3,M,NW)=.5D0*(ZI(MM)+ZI(LL))
      IF (DMM.LT.DEPTOP(NW)) DEPTOP(NW)=DMM
      IF (DLL.LT.DEPTOP(NW)) DEPTOP(NW)=DLL
      IF (DMM.GT.DEPBOT(NW)) DEPBOT(NW)=DMM
      IF (DLL.GT.DEPBOT(NW)) DEPBOT(NW)=DLL

C  THIS IS A GUESS FOR THE AVERAGE PERMEABILITY NORMAL TO THE WELLBORE

      DUM1=(XW2-XW1)**2
      DUM2=(YW2-YW1)**2
      DUM3=(ZW2-ZW1)**2
      ELEPERM(M,NW)=(DUM3*SQRT(XPERM(I,J,K)*YPERM(I,J,K))+
     & DUM2*SQRT(XPERM(I,J,K)*ZPERM(I,J,K))+
     & DUM1*SQRT(YPERM(I,J,K)*ZPERM(I,J,K)))/(DUM1+DUM2+DUM3)

C  DEFAULT GEOMETRIC FACTOR
C Need to compute the volume of hexahedron
c      DUM1=(XG(2)-XG(1))*(YG(3)-YG(1))*(ZG(5)-ZG(1))

      DO L=1,8
        IF ((L.EQ.3).OR.(L.EQ.7)) THEN
        XX(1,L)=XG(L+1)
        XX(2,L)=YG(L+1)
        XX(3,L)=ZG(L+1)
        ELSEIF ((L.EQ.4).OR.(L.EQ.8)) THEN
        XX(1,L)=XG(L-1)
        XX(2,L)=YG(L-1)
        XX(3,L)=ZG(L-1)
        ELSE
        XX(1,L)=XG(L)
        XX(2,L)=YG(L)
        XX(3,L)=ZG(L)
        ENDIF
      ENDDO

      DUM1 = VOLH(XX)

      IF (DUM1.LT.0.D0) DUM1=-DUM1
      DUM1=.208*SQRT(DUM1/ELELEN(M,NW))
      ELEGEOM(M,NW)=6.283185/(LOG(DUM1*2.D0/WELDIAM(N,NW))+
     & WELSKIN(N,NW))

    4 CONTINUE
    3 CONTINUE
    2 CONTINUE
    1 CONTINUE

      END

c======================================================================
      SUBROUTINE WELLIJK3 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &     KL2,KEYOUT,NBLK,NW,XPERM,YPERM,ZPERM,XYPERM,YZPERM,XZPERM,
     &     XC,YC,ZC)
c======================================================================
C  Routine locates the grid elements of a well for the corner-point
C  grid option.  Assigns well to a processor.  Computes open interval,
C  permeability normal to the wellbore, and default geometric factor
C  for each element penatrated.  This is a work routine. More additions
C  later for general geometry.
C
C  NW = Well number (input, INTEGER)
C
C  XPERM(I,J,K),YPERM(I,J,K),ZPERM(I,J,K) = Element permeabilities in
C  the x,y, and z directions.
C  XYPERM(I,J,K),YZPERM(I,J,K),XZPERM(I,J,K) =
C
C MORE THAN ONE PROCESSOR MAY CLAIM PARTS OF A WELL
C
C  Mika Juntunen 8/23/2011 CORRECTING IDENTIFICATION OF WELL ELEMENTS
C
C
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'

      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'wells.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK,NW
      REAL*4 XPERM(IDIM,JDIM,KDIM),YPERM(IDIM,JDIM,KDIM),
     &       ZPERM(IDIM,JDIM,KDIM),XYPERM(IDIM,JDIM,KDIM),
     &       YZPERM(IDIM,JDIM,KDIM),XZPERM(IDIM,JDIM,KDIM)
      REAL*8 XC(IDIM+1,JDIM+1,KDIM+1),YC(IDIM+1,JDIM+1,KDIM+1),
     &       ZC(IDIM+1,JDIM+1,KDIM+1)
      REAL*8 XW1,XW2,YW1,YW2,ZW1,ZW2,XT,YT,ZT,
     & DXW,DYW,DZW,TOLW,DUM1,DUM2,DUM3,XI(6),YI(6),ZI(6),DMM,DLL
      REAL*8 XG(8),YG(8),ZG(8),XX(3,8)
      INTEGER L, FACE
      REAL*8 VOLH
      INTEGER FACEI, FACEMAP(6,4)
      REAL*8 FACECOOR(4,3), NEWFACECOOR(4,3), PLANE(4,3)
      REAL*8 T1(3),T2(3),T3(3),COOR(3),cos_a1,cos_a2,cos_b1,cos_b2
      INTEGER FLAG
      INTEGER IOFF,JOFF,KOFF,MERR,N,NI,I,J,K,JL1,JL2,IG,JG,KG,
     &        IX,JY,KZ,IC,NIF,M,MM,LL
      REAL*8 XMIN,XMAX,YMIN,YMAX,ZMIN,ZMAX
      LOGICAL ONCE,DBG

      IF (LEVELE.AND.BUGKEY(1)) WRITE (NFBUG,*)'PROC',MYPRC,
     & ', BLOCK',NBLK,', WELL',NW,' ENTERING SUBROUTINE WELLIJK3'

! bag8 debug
      DBG = .FALSE.
      ONCE = .TRUE.

c build map from element faces to element nodes
c in practice, index of XG,YG,ZG
c face coordinates are numbered counterclockwise

      FACEMAP(1,:) = [1,2,6,5]
      FACEMAP(2,:) = [3,4,8,7]
      FACEMAP(3,:) = [1,3,7,5]
      FACEMAP(4,:) = [2,4,8,6]
      FACEMAP(5,:) = [5,6,8,7]
      FACEMAP(6,:) = [1,2,4,3]

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,MERR)

C  LOOP OVER WELL INTERVALS

      NI=NWELLI(NW)

      DO 1 N=1,NI
      IF (NBWELI(N,NW).NE.NBLK) GO TO 1

c get well top and bottom coordinates
      XW1=WELLTOP(1,N,NW)
      XW2=WELLBOT(1,N,NW)
      YW1=WELLTOP(2,N,NW)
      YW2=WELLBOT(2,N,NW)
      ZW1=WELLTOP(3,N,NW)
      ZW2=WELLBOT(3,N,NW)

c compute well 'length' in coordinate directions
      DXW=XW2-XW1
      DYW=YW2-YW1
      DZW=ZW2-ZW1

c check that well is not of zero length
      TOLW=1.D-12*(DXW**2+DYW**2+DZW**2)
      IF (TOLW.LE.0.D0) GO TO 1

C  LOOP OVER GRID ELEMENTS

      DO 2 K=KL1,KL2
      KG=K+KOFF
      JL1=JL1V(K)
      JL2=JL2V(K)

      DO 3 J=JL1,JL2
      JG=J+JOFF

      DO 4 I=IL1,IL2
      IF (KEYOUT(I,J,K).LE.0) GO TO 4
      IG=I+IOFF

c get this element node coordinates
      IC=0
      DO KZ=K,K+1
      DO JY=J,J+1
      DO IX=I,I+1
            IC=IC+1
            ZG(IC)=ZC(IX,JY,KZ)
            YG(IC)=YC(IX,JY,KZ)
            XG(IC)=XC(IX,JY,KZ)
      ENDDO
      ENDDO
      ENDDO

c number of intersections found
      NIF=0

c loop over element faces
      DO 44 FACEI=1,6

c get face coordinates
        FACECOOR(1,1) = XG(FACEMAP(FACEI,1));
        FACECOOR(2,1) = XG(FACEMAP(FACEI,2));
        FACECOOR(3,1) = XG(FACEMAP(FACEI,3));
        FACECOOR(4,1) = XG(FACEMAP(FACEI,4));

        FACECOOR(1,2) = YG(FACEMAP(FACEI,1));
        FACECOOR(2,2) = YG(FACEMAP(FACEI,2));
        FACECOOR(3,2) = YG(FACEMAP(FACEI,3));
        FACECOOR(4,2) = YG(FACEMAP(FACEI,4));

        FACECOOR(1,3) = ZG(FACEMAP(FACEI,1));
        FACECOOR(2,3) = ZG(FACEMAP(FACEI,2));
        FACECOOR(3,3) = ZG(FACEMAP(FACEI,3));
        FACECOOR(4,3) = ZG(FACEMAP(FACEI,4));

c get 'closest' plane to face coordinates
c this is an approximation of the closest plane
c see GET_CLOSEST_PLANE2 for more details
        CALL GET_CLOSEST_PLANE(PLANE,FACECOOR)

c check that we found a plane, if not then cycle i.e. goto 44
        DUM1 = SQRT(PLANE(2,1)**2+PLANE(2,2)**2+PLANE(2,3)**2)
        DUM2 = SQRT(PLANE(3,1)**2+PLANE(3,2)**2+PLANE(3,3)**2)

        IF ((DUM1.LE.1.0E-10).OR.(DUM2.LE.1.0E-10)) GOTO 44

c map each of the face nodes to plane
c returns plane coordinates, see map_to_plane2 for details
        CALL MAP_TO_PLANE(PLANE,FACECOOR(1,:),NEWFACECOOR(1,:))
        CALL MAP_TO_PLANE(PLANE,FACECOOR(2,:),NEWFACECOOR(2,:))
        CALL MAP_TO_PLANE(PLANE,FACECOOR(3,:),NEWFACECOOR(3,:))
        CALL MAP_TO_PLANE(PLANE,FACECOOR(4,:),NEWFACECOOR(4,:))

c get well intersection with the plane
c returns intersection in plane coordinates
        CALL INTERSECT_PLANE_LINE(PLANE,[XW1,YW1,ZW1],
     &       [XW2,YW2,ZW2],COOR,FLAG)

c check if we found coordinates for the well, if not goto 44
        IF (FLAG.NE.0) GOTO 44

c See if COOR is inside the given face (in plane coordinates).
c In practice, check whether the angle between face edges is greater
c than the angle between edge and COOR (well intersection coordinate).
c All is done in plane coordinates, i.e. in 2D

c First pick vertex 1. Corresponding edges are between vertexes 4 and 2.
        T1(:) = NEWFACECOOR(2,:)-NEWFACECOOR(1,:)
        T2(:) = NEWFACECOOR(4,:)-NEWFACECOOR(1,:)
        T3(:) = COOR(:)-NEWFACECOOR(1,:)
        DUM1 = SQRT(T1(1)**2+T1(2)**2)
        T1(:) = T1(:)/DUM1
        DUM1 = SQRT(T2(1)**2+T2(2)**2)
        T2(:) = T2(:)/DUM1
        DUM1 = SQRT(T3(1)**2+T3(2)**2)
        T3(:) = T3(:)/DUM1

c Angle between edge from vertex 1 to 2 and edge from vertex 1 to 4
        cos_a1 = T1(1)*T2(1)+T1(2)*T2(2)
c Angle between edge from vertex 1 to 2 and COOR
        cos_b1 = T1(1)*T3(1)+T1(2)*T3(2)
c If not inside face, goto 44
        IF(cos_b1-cos_a1.LE.-1.0E-2) GOTO 44

c Angle between edge from vertex 1 to 4 and COOR
        cos_b1 = T2(1)*T3(1)+T2(2)*T3(2)
c If not inside face, goto 44
        IF(cos_b1-cos_a1.LE.-1.0E-2) GOTO 44

c Then pick vertex 3. Corresponding edges are still between vertexes 4 and 2.
        T1(:) = NEWFACECOOR(2,:)-NEWFACECOOR(3,:)
        T2(:) = NEWFACECOOR(4,:)-NEWFACECOOR(3,:)
        T3(:) = COOR(:)-NEWFACECOOR(3,:)
        DUM1 = SQRT(T1(1)**2+T1(2)**2)
        T1(:) = T1(:)/DUM1
        DUM1 = SQRT(T2(1)**2+T2(2)**2)
        T2(:) = T2(:)/DUM1
        DUM1 = SQRT(T3(1)**2+T3(2)**2)
        T3(:) = T3(:)/DUM1

c Angle between edge from vertex 3 to 2 and edge from vertex 3 to 4
        cos_a1 = T1(1)*T2(1)+T1(2)*T2(2)
c Angle between edge from vertex 3 to 2 and COOR
        cos_b1 = T1(1)*T3(1)+T1(2)*T3(2)

c If not inside face, goto 44
        IF(cos_b1-cos_a1.LE.-1.0E-2) GOTO 44

c Angle between edge from vertex 3 to 4 and COOR
        cos_b1 = T2(1)*T3(1)+T2(2)*T3(2)
c If not inside face, goto 44
        IF(cos_b1-cos_a1.LE.-1.0E-2) GOTO 44

c found an intersection point inside face, map it to x y z coordinates
        T1(1) = PLANE(1,1)+COOR(1)*PLANE(2,1)+COOR(2)*PLANE(3,1)
        T1(2) = PLANE(1,2)+COOR(1)*PLANE(2,2)+COOR(2)*PLANE(3,2)
        T1(3) = PLANE(1,3)+COOR(1)*PLANE(2,3)+COOR(2)*PLANE(3,3)
        COOR(:) = T1(:)

c add intersection point
        NIF=NIF+1
        XI(NIF)=COOR(1)
        YI(NIF)=COOR(2)
        ZI(NIF)=COOR(3)

c end loop over faces
   44 CONTINUE

c if only one intersection found, continue
      IF (NIF.EQ.0) GO TO 4

! bag8 - sanity check for preceeding calculations:
!   If both well top and bottom are completely outside of element bounding box,
!   then preceeding calculations mistakenly identified element intersections.

      XMIN=MINVAL(XG)
      XMAX=MAXVAL(XG)
      YMIN=MINVAL(YG)
      YMAX=MAXVAL(YG)
      ZMIN=MINVAL(ZG)
      ZMAX=MAXVAL(ZG)
      IF ( ((XW1.LT.XMIN).AND.(XW2.LT.XMIN)).OR.
     &     ((XW1.GT.XMAX).AND.(XW2.GT.XMAX)).OR.
     &     ((YW1.LT.YMIN).AND.(YW2.LT.YMIN)).OR.
     &     ((YW1.GT.YMAX).AND.(YW2.GT.YMAX)).OR.
     &     ((ZW1.LT.ZMIN).AND.(ZW2.LT.ZMIN)).OR.
     &     ((ZW1.GT.ZMAX).AND.(ZW2.GT.ZMAX)) ) THEN
        IF (DBG) THEN
          WRITE(*,'(1x,a,i2,a,i3,a,3i4,a,i1)')
     &      'Sanity check caught, NW=',
     &      NW,' MYPRC=',MYPRC,' IG,JG,KG=',IG,JG,KG,' NIF=',NIF
          WRITE(10+MYPRC,'(1x,a,i2,a,i3,a,3i4,a,i1)')
     &      'Sanity check caught, NW=',
     &      NW,' MYPRC=',MYPRC,' IG,JG,KG=',IG,JG,KG,' NIF=',NIF
          WRITE(10+MYPRC,*)'XG=',XG
          WRITE(10+MYPRC,*)'YG=',ZG
          WRITE(10+MYPRC,*)'ZG=',ZG
          WRITE(10+MYPRC,*)'XW1,XW2=',XW1,XW2
          WRITE(10+MYPRC,*)'YW1,YW2=',YW1,YW2
          WRITE(10+MYPRC,*)'ZW1,ZW2=',ZW1,ZW2
          WRITE(10+MYPRC,*)'NIF=',NIF
        ENDIF
        GOTO 4
      ENDIF

! bag8 - additional check if well endpoints are inside element
!   These if-statements could be improved with checks for well top/bottom
!   to be inside convex hull of 8 vertices...
      IF (NIF.EQ.1) THEN

      IF ((XW1.GT.XMIN).AND.(XW1.LT.XMAX).AND.
     &    (YW1.GT.YMIN).AND.(YW1.LT.YMAX).AND.
     &    (ZW1.GT.ZMIN).AND.(ZW1.LT.ZMAX)) THEN
        IF (DBG) THEN
          WRITE(*,'(1X,A,I2,A,I3,A,3I4,A,I1)')
     &      'Found extra element, NW=',
     &      NW,' MYPRC=',MYPRC,' IG,JG,KG=',IG,JG,KG,' NIF=',NIF
          WRITE(10+MYPRC,'(1X,A,I2,A,I3,A,3I4,A,I1)')
     &      'Found extra element, NW=',
     &      NW,' MYPRC=',MYPRC,' IG,JG,KG=',IG,JG,KG,' NIF=',NIF
          WRITE(10+MYPRC,*)'XG=',XG
          WRITE(10+MYPRC,*)'YG=',ZG
          WRITE(10+MYPRC,*)'ZG=',ZG
          WRITE(10+MYPRC,*)'XW1,XW2=',XW1,XW2
          WRITE(10+MYPRC,*)'YW1,YW2=',YW1,YW2
          WRITE(10+MYPRC,*)'ZW1,ZW2=',ZW1,ZW2
          WRITE(10+MYPRC,*)'NIF=',NIF
        ENDIF
        NIF=2
        XI(2)=XW1
        YI(2)=YW1
        ZI(2)=ZW1
      ELSEIF ((XW2.GT.XMIN).AND.(XW2.LT.XMAX).AND.
     &    (YW2.GT.YMIN).AND.(YW2.LT.YMAX).AND.
     &    (ZW2.GT.ZMIN).AND.(ZW2.LT.ZMAX)) THEN
        IF (DBG) THEN
          WRITE(*,'(1X,A,I2,A,I3,A,3I4,A,I1)')
     &      'Found extra element, NW=',
     &      NW,' MYPRC=',MYPRC,' IG,JG,KG=',IG,JG,KG,' NIF=',NIF
          WRITE(10+MYPRC,'(1X,A,I2,A,I3,A,3I4,A,I1)')
     &      'Found extra element, NW=',
     &      NW,' MYPRC=',MYPRC,' IG,JG,KG=',IG,JG,KG,' NIF=',NIF
          WRITE(10+MYPRC,*)'XG=',XG
          WRITE(10+MYPRC,*)'YG=',ZG
          WRITE(10+MYPRC,*)'ZG=',ZG
          WRITE(10+MYPRC,*)'XW1,XW2=',XW1,XW2
          WRITE(10+MYPRC,*)'YW1,YW2=',YW1,YW2
          WRITE(10+MYPRC,*)'ZW1,ZW2=',ZW1,ZW2
          WRITE(10+MYPRC,*)'NIF=',NIF
        ENDIF
        NIF=2
        XI(2)=XW2
        YI(2)=YW2
        ZI(2)=ZW2
      ENDIF

      ENDIF

c if only one intersection found, cycle to next element
      IF (NIF.LT.2) GO TO 4

c at least two intersections found, take the longest piece
      DUM1=0.D0
      DO 5 L=2,NIF
      DO 5 M=1,L-1
      DUM2=(XI(M)-XI(L))**2+(YI(M)-YI(L))**2+(ZI(M)-ZI(L))**2
      IF (DUM2.GT.DUM1) THEN
         MM=M
         LL=L
         DUM1=DUM2
      ENDIF
    5 CONTINUE
      IF (DUM1.LT.TOLW) GO TO 4

c add longest piece to well data
      NWELPRC(NW)=MYPRC
      NUMELE(NW)=NUMELE(NW)+1
      M=NUMELE(NW)
      NUMELET(NW)=M
      LOCWEL(1,M,NW)=NBLK
      LOCWEL(2,M,NW)=NI
      LOCWEL(3,M,NW)=IG
      LOCWEL(4,M,NW)=JG
      LOCWEL(5,M,NW)=KG
      LOCWEL(6,M,NW)=MYPRC
      ELELEN(M,NW)=SQRT(DUM1)
      DMM=DOWN(1,NBLK)*XI(MM)+DOWN(2,NBLK)*YI(MM)+DOWN(3,NBLK)*ZI(MM)
      DLL=DOWN(1,NBLK)*XI(LL)+DOWN(2,NBLK)*YI(LL)+DOWN(3,NBLK)*ZI(LL)
      ELEDEP(M,NW)=.5D0*(DMM+DLL)
      ELEXYZ(1,M,NW)=.5D0*(XI(MM)+XI(LL))
      ELEXYZ(2,M,NW)=.5D0*(YI(MM)+YI(LL))
      ELEXYZ(3,M,NW)=.5D0*(ZI(MM)+ZI(LL))
      IF (DMM.LT.DEPTOP(NW)) DEPTOP(NW)=DMM
      IF (DLL.LT.DEPTOP(NW)) DEPTOP(NW)=DLL
      IF (DMM.GT.DEPBOT(NW)) DEPBOT(NW)=DMM
      IF (DLL.GT.DEPBOT(NW)) DEPBOT(NW)=DLL

C APPROXIMATE AVERAGE PERMEABILITY NORMAL TO THE WELLBORE

      DUM1=(XW2-XW1)**2
      DUM2=(YW2-YW1)**2
      DUM3=(ZW2-ZW1)**2
      ELEPERM(M,NW)=(DUM3*SQRT(XPERM(I,J,K)*YPERM(I,J,K))+
     & DUM2*SQRT(XPERM(I,J,K)*ZPERM(I,J,K))+
     & DUM1*SQRT(YPERM(I,J,K)*ZPERM(I,J,K)))/(DUM1+DUM2+DUM3)

C Compute the volume of hexahedron for geometric factor

      DO L=1,8
        IF ((L.EQ.3).OR.(L.EQ.7)) THEN
        XX(1,L)=XG(L+1)
        XX(2,L)=YG(L+1)
        XX(3,L)=ZG(L+1)
        ELSEIF ((L.EQ.4).OR.(L.EQ.8)) THEN
        XX(1,L)=XG(L-1)
        XX(2,L)=YG(L-1)
        XX(3,L)=ZG(L-1)
        ELSE
        XX(1,L)=XG(L)
        XX(2,L)=YG(L)
        XX(3,L)=ZG(L)
        ENDIF
      ENDDO

      DUM1 = VOLH(XX)

      IF (DUM1.LT.0.D0) DUM1=-DUM1
      DUM1=.208*SQRT(DUM1/ELELEN(M,NW))
      ELEGEOM(M,NW)=6.283185/(LOG(DUM1*2.D0/WELDIAM(N,NW))+
     & WELSKIN(N,NW))

! bag8 debug
      IF (DBG) THEN
      IF (ONCE) THEN
        WRITE(*,*)'WELLIJK3 debug output for NW=',NW
      ENDIF
      WRITE(10+MYPRC,'(A,5I4)')'In WELLIJK: NW,N,I,J,K=',NW,N,I,J,K
      WRITE(10+MYPRC,*)'NWELPRC=',NWELPRC(NW)
      WRITE(10+MYPRC,*)'NUMELE=',NUMELE(NW)
      WRITE(10+MYPRC,*)'NUMELET=',NUMELET(NW)
      WRITE(10+MYPRC,*)'LOCWEL=',LOCWEL(1:6,M,NW)
      WRITE(10+MYPRC,*)'ELELEN=',ELELEN(M,NW)
      WRITE(10+MYPRC,*)'ELEDEP=',ELEDEP(M,NW)
      WRITE(10+MYPRC,*)'ELEXYZ=',ELEXYZ(1:3,M,NW)
      WRITE(10+MYPRC,*)'DEPTOP=',DEPTOP(NW)
      WRITE(10+MYPRC,*)'DEPBOT=',DEPBOT(NW)
      WRITE(10+MYPRC,*)'ELEPERM=',ELEPERM(M,NW)
      WRITE(10+MYPRC,*)'ELEGEOM=',ELEGEOM(M,NW)
      ONCE = .FALSE.
      ENDIF

    4 CONTINUE
    3 CONTINUE
    2 CONTINUE
    1 CONTINUE

      END

C
c======================================================================
      SUBROUTINE GET_CLOSEST_PLANE(PLANE,FACECOOR)
c======================================================================
c Given four points in FACECOOR(4,3) computes an approximation to
c a plane that would go close to all four points.
c Returns plane in PLANE(4,3) s.t.
c row1:       vector to middle of facecoor, i.e. point on plane
c row2 and 3: vectors from corner to corner, i.e. tangents to plane
c row4        normal vector
C
C  Mika Juntunen 8/23/2011
C

      REAL*8 FACECOOR(4,3), PLANE(4,3)
      INTEGER I,J,MAP(4,3)
      REAL*8 T1(3), T2(3), TMP1, TMP2

      PLANE = 0.0D0

c compute the middle point, this is the 'point on plane'
      DO I=1,4
         DO J=1,3
            PLANE(1,J) = PLANE(1,J)+FACECOOR(I,J)
         ENDDO
      ENDDO
      PLANE(1,1) = PLANE(1,1)/4.0D0
      PLANE(1,2) = PLANE(1,2)/4.0D0
      PLANE(1,3) = PLANE(1,3)/4.0D0

c compute 'corner to corner vectors'
      DO I=1,3
         T1(I) = FACECOOR(3,I)-FACECOOR(1,I)
         T2(I) = FACECOOR(4,I)-FACECOOR(2,I)
      ENDDO

c check if the face is nearly collapsed
c if so, return all zeros
c no warnings
      TMP1 = SQRT( T1(1)**2 +T1(2)**2 +T1(3)**2 )
      TMP2 = SQRT( T2(1)**2 +T2(2)**2 +T2(3)**2 )
      IF ( (ABS(TMP1-TMP2).GE.1.0E9) .OR.
     &     (ABS(TMP1).LE.1.0E-12) .OR.
     &     (ABS(TMP2).LE.1.0E-12) ) RETURN

c normalize vectors and add to plane
      DO I=1,3
         T1(I) = T1(I)/TMP1
         T2(I) = T2(I)/TMP2
         PLANE(2,I) = T1(I)
         PLANE(3,I) = T2(I)
      ENDDO

c compute normal vector (cross product)
      PLANE(4,1) =  1.0D0*(T1(2)*T2(3)-T1(3)*T2(2))
      PLANE(4,2) = -1.0D0*(T1(1)*T2(3)-T1(3)*T2(1))
      PLANE(4,3) =  1.0D0*(T1(1)*T2(2)-T1(2)*T2(1))

c normalize normal vector
      TMP1 = SQRT(PLANE(4,1)**2+PLANE(4,2)**2+PLANE(4,3)**2)
      PLANE(4,:) = PLANE(4,:)/TMP1

      END

C
c======================================================================
      SUBROUTINE MAP_TO_PLANE(PLANE,COOR,NEWCOOR)
c======================================================================
c maps given COOR to given PLANE,
c returns NEWCOOR where the coordinates are
c alpha,beta,gamma corresponding to
c COOR(:) = PLANE(1,:)+alpha*PLANE(2,:)+beta*PLANE(3,:)+gamma*PLANE(4,:)
C
C  Mika Juntunen 8/23/2011
C
      REAL*8 PLANE(4,3)
      REAL*8 COOR(3),NEWCOOR(3),T1(3)
      REAL*8 AMAT(3,3),BVEC(3),TMP
      INTEGER I,J,INFO,IPIV(3)

c build system to solve
      DO I=1,3
         DO J=1,3
            AMAT(J,I) = PLANE(I+1,J)
         ENDDO
         BVEC(I) = COOR(I)-PLANE(1,I)
         IPIV(I) = 0
      ENDDO

c solve system
      CALL DGESV( 3, 1, AMAT, 3, IPIV, BVEC, 3, INFO )
      IF (INFO.GT.0) THEN
         WRITE(*,*) 'MAP_TO_PLANE: BLAS CANNOT INVERT!!'
         STOP
      ENDIF
      NEWCOOR(:) = BVEC(:)

      END


C
c======================================================================
      SUBROUTINE INTERSECT_PLANE_LINE(PLANE,LINE1,LINE2,NEWCOOR,FLAG)
c======================================================================
c Tries to find intersection of line, between points line1 and line2,
c and the plane given by PLANE.
c Returns NEWCOOR that are in PLANE coordinates alpha, beta, gamma.
c The regular coordinates would be
c line1 = PLANE(1,:)+alpha*PLANE(2,:)+beta*PLANE(3,:)+gamma*(line2-line1)
c
c If problem ocurred, returns flag = 1
C
C  Mika Juntunen 8/23/2011
C
      REAL*8 PLANE(4,3)
      REAL*8 LINE1(3),LINE2(3),NEWCOOR(3),T1(3)
      REAL*8 AMAT(3,3),BVEC(3), TMP
      INTEGER I,J,INFO,IPIV(3)
      INTEGER FLAG

c set default FLAG=1 i.e. error
      FLAG=1

c get vector between line ends and normalize
      T1(:) = LINE2(:)-LINE1(:)
      TMP = SQRT(T1(1)**2+T1(2)**2+T1(3)**2)
      T1(:) = T1(:)/TMP

c build system to be solved
      DO I=1,2
         DO J=1,3
            AMAT(J,I) = PLANE(I+1,J)
         ENDDO
      ENDDO
      BVEC(:) = LINE1(:)-PLANE(1,:)
      AMAT(:,3) = T1(:)

c solve system, if problem ocurred, return all zero and keep flag=1
      NEWCOOR = 0.0D0
      CALL DGESV( 3, 1, AMAT, 3, IPIV, BVEC, 3, INFO )
      IF (INFO.GT.0) RETURN

c if there was a problem, return zero vector and keep flag=1
      IF ( ISNAN(BVEC(1)).OR.ABS(BVEC(1)).GE.1.0E12 ) RETURN
      IF ( ISNAN(BVEC(2)).OR.ABS(BVEC(2)).GE.1.0E12 ) RETURN
      IF ( ISNAN(BVEC(3)).OR.ABS(BVEC(3)).GE.1.0E12 ) RETURN

c if well segment is 'below' the plane, return flag=1
c that is, if gamma>0
      IF (BVEC(3).GT.0.0d0) RETURN

c if well segment is 'above' the plane, return flag=1
c that is, if |gamma|>|line2-line1|
      T1(:) = LINE2(:)-LINE1(:)
      TMP = SQRT(T1(1)**2+T1(2)**2+T1(3)**2)
      IF (ABS(BVEC(3)).GT.TMP) RETURN

c set intersection point and set flag=0
      NEWCOOR(:) = BVEC(:)
      FLAG=0

      END

C======================================================================
      SUBROUTINE CALLWELLIJK3()
C======================================================================
      IMPLICIT NONE

      INCLUDE 'blkary.h'
      INCLUDE 'mpfaary.h'

      INTEGER NA(11)
      EXTERNAL WELLIJK3

      NA(1) = 10
      NA(2) = N_KPU
      NA(3) = N_XPERM
      NA(4) = N_YPERM
      NA(5) = N_ZPERM
      NA(6) = N_XYPERM
      NA(7) = N_YZPERM
      NA(8) = N_XZPERM
      NA(9) = N_XC
      NA(10) = N_YC
      NA(11) = N_ZC

      CALL CALLWORK(WELLIJK3,NA)

      RETURN
      END
C======================================================================
      SUBROUTINE MPFA_SET_AINV_TRAN(KERR)
C======================================================================
      IMPLICIT NONE
C
C CALCULATE AINV AND STORE IN N_AINV, CALCULATE TRAN AND STORE IN N_TRAN
C
      INCLUDE 'mpfaary.h'
      INCLUDE 'blkary.h'
C
      INTEGER KERR,ITRAN(9)
      LOGICAL ONCEONLY
      EXTERNAL CALCAINVTRAN
      DATA ITRAN/9*0/, ONCEONLY/.TRUE./

      IF (ONCEONLY) THEN
         ONCEONLY = .FALSE.

         ITRAN(1) = 8
         ITRAN(2) = N_KCR
         ITRAN(3) = N_VPROP
         ITRAN(4) = N_VDIM
         ITRAN(5) = N_FPROP
         ITRAN(6) = N_FDIM
         ITRAN(7) = N_PERMINV
         ITRAN(8) = N_AINV
         ITRAN(9) = N_TRAN
      ENDIF

      CALL CALLWORK(CALCAINVTRAN,ITRAN)

      RETURN
      END

C======================================================================
      SUBROUTINE CALCAINVTRAN(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &     KL1,KL2,KEYOUT,NBLK,KEYOUTCR,VOLPROP,VOLDIM,
     &     FACEPROP,FACEDIM,PERMINV,AINV,TRAN)
C======================================================================
      IMPLICIT NONE
C
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK
      INTEGER KEYOUTCR(IDIM+1,JDIM+1,KDIM+1),
     &        VOLPROP(IDIM+1,JDIM+1,KDIM+1,8),
     &        VOLDIM(IDIM+1,JDIM+1,KDIM+1),
     &        FACEPROP(IDIM+1,JDIM+1,KDIM+1,12),
     &        FACEDIM(IDIM+1,JDIM+1,KDIM+1)
      REAL*8  TRAN(12,8,IDIM+1,JDIM+1,KDIM+1),
     &        AINV(12,12,IDIM+1,JDIM+1,KDIM+1),
     &        PERMINV(3,3,8,IDIM,JDIM,KDIM)
      INTEGER VPROP(8),FPROP(12),VINDEX(8),FINDEX(12),VDIM,FDIM
      INTEGER I,J,K,L,M,KR

C
C LOOP OVER VERTICES (I,J,K)
C

      DO K = KL1,KL2+1
      DO J = 1, JDIM+1
      DO I = IL1,IL2+1
      KR = KEYOUTCR(I,J,K)

      IF((KR.EQ.1).OR.(KR.EQ.2)) THEN

         FDIM=FACEDIM(I,J,K)
         IF (FDIM.NE.0) THEN

            VDIM=VOLDIM(I,J,K)

            VINDEX = 0
            FINDEX = 0

            DO M = 1, 8
               VPROP(M) = VOLPROP(I,J,K,M)
            ENDDO
            DO M = 1, 12
               FPROP(M) = FACEPROP(I,J,K,M)
            ENDDO

C GET VINDEX AND FINDEX FROM VPROP AND FPROP
            CALL GETDOFINDEX(I,J,K,VPROP,FPROP,VDIM,FDIM,VINDEX,
     &                          FINDEX)

            CALL GETAINVTRAN(AINV(1,1,I,J,K),TRAN(1,1,I,J,K),PERMINV,
     &                       I,J,K,FINDEX,VINDEX,FPROP,VPROP,
     &                       IDIM,JDIM,KDIM,FDIM,VDIM)
         ENDIF
      ENDIF

      ENDDO
      ENDDO
      ENDDO

      RETURN
      END

C======================================================================
      SUBROUTINE GETAINVTRAN(AINV,TRAN,PERMINV,I,J,K,
     &                       FINDEX,VINDEX,FPROP,VPROP,
     &                       IDIM,JDIM,KDIM,FDIM,VDIM)
C======================================================================
      IMPLICIT NONE
      INCLUDE 'control.h'

      INTEGER I,J,K,FDIM,VDIM,FINDEX(FDIM),VINDEX(VDIM),FPROP(12),
     &        VPROP(8),IDIM,JDIM,KDIM

      REAL*8 AINV(12,12),TRAN(12,8),PERMINV(3,3,8,IDIM,JDIM,KDIM)

      INTEGER IPIV(FDIM),INFO,ROW,L,M,N
      REAL*8 TMPA(FDIM,FDIM),TMPB(FDIM,VDIM),TMPAINV(FDIM,FDIM),
     &       TMPTRAN(FDIM,VDIM)

      INTEGER ZEROROWS(12)
      LOGICAL ZP

CGUS INITIALIZE VECTOR TO ZERO
      AINV    = 0.D0
      TRAN    = 0.D0
      TMPAINV = 0.D0
      TMPTRAN = 0.D0
      TMPA    = 0.D0
      TMPB    = 0.D0

C INITIALIZE AINV AS THE IDENTITY MATRIX
      DO ROW=1,FDIM
         TMPAINV(ROW,ROW)=1.D0
      ENDDO

C COMPUTE VELOCITY MASS MATRIX STORE IN TEMPA
      CALL GETA(TMPA,FDIM,I,J,K,FINDEX,IDIM,JDIM,KDIM,PERMINV,
     &          VPROP)
C COMPUTE PRESSURE DIFFERENCE MATRIX AND STORE IN B
      CALL GETB(TMPB,FDIM,VDIM,FINDEX,VINDEX)

! bag8 - fix for zero perm cells
      ZEROROWS(:)=0
      ZP = .FALSE.
      DO ROW=1,FDIM
        IF (TMPA(ROW,ROW).EQ.0.D0) THEN
          ZEROROWS(ROW)=1
          ZP = .TRUE.
          TMPA(:,ROW)=0.D0
          TMPA(ROW,ROW)=1.D0
        ENDIF
      ENDDO

C COMPUTE A^{-1} AND STORE IN TMPAINV
      CALL DGESV(FDIM,FDIM,TMPA,FDIM,IPIV,TMPAINV,FDIM,INFO)
      IF (INFO.NE.0) THEN
         WRITE(0,'(2a,4i4)')'GETAINVTRAN: ERROR BLAS CANNOT INVERT A',
     &     '; myprc,i,j,k=',myprc,i,j,k
         STOP
      ENDIF

! bag8 - fix for zero perm cells
      IF (ZP) THEN
        DO ROW=1,FDIM
          IF (ZEROROWS(ROW).EQ.1) THEN
            TMPAINV(:,ROW)=0.D0
          ENDIF
        ENDDO
      ENDIF

C CALCULATE AINV*B AND STORE IN TMPTRAN(FDIM,VDIM)
      CALL DGEMM('N','N',FDIM,VDIM,FDIM,1.D0,TMPAINV,FDIM,TMPB,FDIM,
     &           0.D0,TMPTRAN,FDIM)

C STORE IN GLOBAL AINV AND TRAN
      DO L = 1,FDIM
         DO M = 1,FDIM
            AINV(FINDEX(L),FINDEX(M)) = TMPAINV(L,M)
         ENDDO
         DO N = 1,VDIM
            TRAN(FINDEX(L),VINDEX(N)) = TMPTRAN(L,N)
         ENDDO
      ENDDO

      RETURN
      END

c======================================================================
      SUBROUTINE MPFA_INIT(KERR)
c======================================================================
C      USE dualmod
      implicit none
C
C  MPFA corner point properties
C
      include 'mpfaary.h'
      include 'blkary.h'
      include 'layout.h'
C      include 'sblkc.h'

      integer kerr,iMPFAcr(4),iface(6),iupfce(2),iva(5),ivfdim(6)
      logical onceonly
      external calcMPFAcrProp,calcFaces,updateFaces,calcVOLFACEdim,
     &     calcArea
      data iMPFAcr/4*0/, iface/6*0/,iupfce/2*0/,ivfdim/6*0/,
     &     iva/5*0/,onceonly/.true./

! bag8
C      integer idual(3),iprop(5),nbem(19)
C      data idual/3*0/,iprop/5*0/,onceonly/.true./,
C     &     nbem/19*0/
C      external calcMPFAdual3,calcMPFAdual5,calcMPFAdual6a,
C     &     calcMPFAdual6b,tmsendprops,DPropDebug6,DPropVTK,
C     &     DNormalFaces

      if(onceonly) then
         onceonly=.false.

         iMPFAcr(1) = 3
         iMPFAcr(2) = n_kcr
         iMPFAcr(3) = n_vprop
         iMPFAcr(4) = n_fprop

         iface(1)=5
         iface(2)=n_xc
         iface(3)=n_yc
         iface(4)=n_zc
         iface(5)=n_depth
         iface(6)=n_fprop

         iupfce(1)=1
         iupfce(2)=n_fprop

         ivfdim(1) = 5
         ivfdim(2) = n_vprop
         ivfdim(3) = n_fprop
         ivfdim(4) = n_kcr
         ivfdim(5) = n_vdim
         ivfdim(6) = n_fdim

         iva(1) = 4
         iva(2) = n_xc
         iva(3) = n_yc
         iva(4) = n_zc
         iva(5) = n_farea

! bag8
C         idual(1)=3
C         idual(2)=n_vprop
C         idual(3)=n_fprop

C         iprop(1)=4
C         iprop(2)=n_vprop
C         iprop(3)=n_fprop
C         iprop(4)=n_bufdim
C         iprop(5)=n_bufif

      endif

      call callwork(calcMPFAcrProp,iMPFAcr)

      call callwork(calcFaces,iface)

! bag8 - multiblock hexahedra
C      if (evfem_hex.eq.3) then
C        call callwork(calcMPFAdual3,idual)
C      elseif (evfem_hex.eq.5) then
C        call callwork(calcMPFAdual5,idual)
C      elseif (evfem_hex.eq.6) then
C        call callwork(calcMPFAdual6a,idual) ! Set my vprop fprop
C        call callwork(tmsendprops,iprop)    ! Fill buffer
C        NBEM=160
C        CALL PIFBUF8(NBEM,kerr)             ! Swap buffer between blocks
C        call callwork(calcMPFAdual6b,iprop) ! Set adjacent vprop fprop
C      endif


C EXCHANGE FACEPROP FACES BETWEEN PROCESSORS
C
C EXCHANGE PHYSICAL PARAMETERS WITH NEIGHBORING PROCESSORS
C
      call callwork(updateFaces,iupfce)

      call callwork(calcVOLFACEdim,ivfdim)

      call callwork(calcArea,iva)

! bag8 - multiblock hexahedra
C      if (evfem_hex.eq.5) then
C        CALL TMSET_COORD5()
C      elseif (evfem_hex.eq.6) then
C        CALL TMSET_COORD6()
C        CALL REALLOC_DUALMOD()
C        CALL CALLWORK(DNormalFaces,iprop)
C        CALL TMSET_PERMCC()
C!        call callwork(DPropDebug6,iprop)    ! debug
C      endif

      return
      end

C======================================================================
      subroutine calcMPFAcrProp(idim,jdim,kdim,ldim,il1,il2,jl1v,jl2v,
     &     kl1,kl2,keyout,nblk,keyoutcr,volprop,faceprop)
C======================================================================
      implicit none
c
      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),jl2v(kdim),
     &     kl1,kl2,keyout(idim,jdim,kdim),nblk
      integer keyoutcr(idim+1,jdim+1,kdim+1),
     &     volprop(idim+1,jdim+1,kdim+1,8),
     &     faceprop(idim+1,jdim+1,kdim+1,12)
c
      logical ELEIN
      integer i,j,k,jl1,jl2,keyp1,keyp2,keyp3,keyp4,keyp5,
     &     keyp6,keyp7,keyp8,l,m,n,count,kcr

c
c Pressure dofs and corresponding volumes. This part is
c dependent on coordinate.

c p1: (i-1,j-1,k-1)
c p2: (i  ,j-1,k-1)
c p3: (i  ,j  ,k-1)
c p4: (i-1,j  ,k-1)
c p5: (i-1,j-1,k)
c p6: (i  ,j-1,k)
c p7: (i  ,j  ,k)
c p8: (i-1,j  ,k)

c Velocity dofs and corresponding volumes
c f4  : p4 p1
c f2  : p3 p2
c f10 : p7 p6
c f12 : p8 p5
c
c f3  : p4 p3
c f1  : p1 p2
c f9  : p5 p6
c f11 : p8 p7
c
c f8  : p4 p8
c f5  : p1 p5
c f6  : p2 p6
c f7  : p3 p7

C LOOP OVER ALL CORNER POINTS
C
C INITIALIZATION: POINT, FACE, VOLUMES ARE ALL OUTSIDE OF THE DOMAIN
C
C
C ASSIGNING KEYOUTCR
C

      do k = 1,kdim+1
      do j = 1,jdim+1
      do i = 1,idim+1
        keyoutcr(i,j,k) = 0

        count = 0
        do l = 0,1
        do m = 0,1
        do n = 0,1
           if (ELEIN(i-l,j-m,k-n,idim,jdim,kdim)) then
              if (keyout(i-l,j-m,k-n).ne.0) count = count + 1
           endif
        enddo
        enddo
        enddo
c Interior vertex (either belong or not to current processor)
c external boundary vertex (either belong or not to current processor)

        if (count.eq.8) keyoutcr(i,j,k) = 1
        if ((count.gt.0).and.(count.lt.8)) keyoutcr(i,j,k) = 2

c added extral flag -1: interior corner not belong to current processor

        count = 0
        do l = 0,1
        do m = 0,1
        do n = 0,1
           if (ELEIN(i-l,j-m,k-n,idim,jdim,kdim)) then
              if (keyout(i-l,j-m,k-n).gt.0) count = count + 1
           endif
        enddo
        enddo
        enddo
        if ((count.eq.0).and.(keyoutcr(i,j,k).eq.1)) then
           keyoutcr(i,j,k) = -1
        endif

c added extral flag -2: boundary corner not belong to current processor

        count = 0
        do l = 0,1
        do m = 0,1
        do n = 0,1
           if (ELEIN(i-l,j-m,k-n,idim,jdim,kdim)) then
              if (keyout(i-l,j-m,k-n).gt.0) count = count + 1
           endif
        enddo
        enddo
        enddo
        if ((count.eq.0).and.(keyoutcr(i,j,k).eq.2)) then
           keyoutcr(i,j,k) = -2
        endif
      enddo
      enddo
      enddo


      VOLPROP = -1
      FACEPROP = -1

      do k = kl1,kl2+1
      do j = 2,jdim+1
      do i = il1,il2+1

         kcr = keyoutcr(i,j,k)
         if ((kcr.eq.0).or.(kcr.eq.-1).or.(kcr.eq.-2)) cycle

            keyp1 = keyout (i-1,j-1,k-1)
            keyp2 = keyout (i  ,j-1,k-1)
            keyp3 = keyout (i  ,j  ,k-1)
            keyp4 = keyout (i-1,j  ,k-1)
            keyp5 = keyout (i-1,j-1,k)
            keyp6 = keyout (i  ,j-1,k)
            keyp7 = keyout (i  ,j  ,k)
            keyp8 = keyout (i-1,j  ,k)

c
c     assigning volprop when the volume is inside the block
c     -1: outside   0 : inside the block
c
           if (keyp1.ne.0) volprop(i,j,k,1) = 0
           if (keyp2.ne.0) volprop(i,j,k,2) = 0
           if (keyp3.ne.0) volprop(i,j,k,3) = 0
           if (keyp4.ne.0) volprop(i,j,k,4) = 0
           if (keyp5.ne.0) volprop(i,j,k,5) = 0
           if (keyp6.ne.0) volprop(i,j,k,6) = 0
           if (keyp7.ne.0) volprop(i,j,k,7) = 0
           if (keyp8.ne.0) volprop(i,j,k,8) = 0
c
c     Assign faceprop when the face is not outside.
c     If the face is on the external boundary, we give
c     initially zero neumann. Later calFaces, we update
c     the right boundary type.
c
c     -1: outside   0: interior of the block
c     1 : external nonzero Neumann
c     2 : external dirichlet
c     3 : zero neumann

c f4  : p4 p1
           count = 0
           if (keyp4.eq.0) count = count + 1
           if (keyp1.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,4) = 0
           if (count.eq.1) faceprop(i,j,k,4) = 3
c f2  : p3 p2
           count = 0
           if (keyp3.eq.0) count = count + 1
           if (keyp2.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,2) = 0
           if (count.eq.1) faceprop(i,j,k,2) = 3

c f10 : p7 p6
           count = 0
           if (keyp7.eq.0) count = count + 1
           if (keyp6.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,10) = 0
           if (count.eq.1) faceprop(i,j,k,10) = 3
c f12 : p8 p5
           count = 0
           if (keyp8.eq.0) count = count + 1
           if (keyp5.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,12) = 0
           if (count.eq.1) faceprop(i,j,k,12) = 3
c f3  : p4 p3
           count = 0
           if (keyp4.eq.0) count = count + 1
           if (keyp3.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,3) = 0
           if (count.eq.1) faceprop(i,j,k,3) = 3
c f1  : p1 p2
           count = 0
           if (keyp1.eq.0) count = count + 1
           if (keyp2.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,1) = 0
           if (count.eq.1) faceprop(i,j,k,1) = 3
c f9  : p5 p6
           count = 0
           if (keyp5.eq.0) count = count + 1
           if (keyp6.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,9) = 0
           if (count.eq.1) faceprop(i,j,k,9) = 3
c f11 : p8 p7
           count = 0
           if (keyp8.eq.0) count = count + 1
           if (keyp7.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,11) = 0
           if (count.eq.1) faceprop(i,j,k,11) = 3
c f8  : p4 p8
           count = 0
           if (keyp4.eq.0) count = count + 1
           if (keyp8.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,8) = 0
           if (count.eq.1) faceprop(i,j,k,8) = 3
c f5  : p1 p5
           count = 0
           if (keyp1.eq.0) count = count + 1
           if (keyp5.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,5) = 0
           if (count.eq.1) faceprop(i,j,k,5) = 3
c f6  : p2 p6
           count = 0
           if (keyp2.eq.0) count = count + 1
           if (keyp6.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,6) = 0
           if (count.eq.1) faceprop(i,j,k,6) = 3
c f7  : p3 p7
           count = 0
           if (keyp3.eq.0) count = count + 1
           if (keyp7.eq.0) count = count + 1
           if (count.eq.0) faceprop(i,j,k,7) = 0
           if (count.eq.1) faceprop(i,j,k,7) = 3

       enddo
       enddo
       enddo

      return
      end

c======================================================================
      subroutine calcFaces(idim,jdim,kdim,ldim,il1,il2,jl1v,jl2v,
     &     kl1,kl2,keyout,nblk,xc,yc,zc,depth,faceprop)
c======================================================================
      implicit none
c
c subroutine calcFaces to find faceprop
c
      include 'boundary.h'
      include 'control.h'
      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),jl2v(kdim),
     &     kl1,kl2,keyout(idim,jdim,kdim),nblk
      real*8 xc(idim+1,jdim+1,kdim+1),yc(idim+1,jdim+1,kdim+1),
     &       zc(idim+1,jdim+1,kdim+1),
     &     depth(idim,jdim,kdim)
c
      integer faceprop(idim+1,jdim+1,kdim+1,12)
c
      integer i,j,k,jl1,jl2,l,IB,NTYPE,NDIR,NFOFF,MPFA_BTYPE
      real*8 PQ,DPQ,TE,XB,YB,ZB,DEPB,PT(3)
      integer itemp,jtemp,ktemp


      IF (NBND_REG.EQ.0.OR.NBEL.EQ.0) RETURN
      TE = TIM + DELTIM
C
C  LOOP OVER THE bdary condition regions
C
      DO 100 IB=1,NBND_REG

C ntype, 1: constant Dirichlet, 2: Dirichlet with gravity
C        3: user specified function, 0: no-flow, < 0: non-zero flux
C        -1: constant flux,   -2: user specified function flux
C
         NTYPE = NBND_TYPE(IB)
c
c convert IPARS boundary type to MPFA boundary type
c
         IF (NTYPE.LT.0) MPFA_BTYPE = 1
         IF (NTYPE.GT.0) MPFA_BTYPE = 2
         IF (NTYPE.EQ.0) MPFA_BTYPE = 3

         IF(NBLK.EQ.1.AND.IB.EQ.1) NFOFF=1
         IF(NBLK.GT.1.AND.IB.EQ.1) NFOFF=LOFFBND(NBND_REG,NBLK-1)+1
         IF(IB.NE.1) NFOFF=LOFFBND(IB-1,NBLK)+1

c for types 1, 2 or 4 get the current value from table

!         IF((NTYPE.NE.3).AND.(NTYPE.NE.-2)) THEN
!             CALL LOOKUP(NTABBND(IB,1),TE,PQ,DPQ)
!         ENDIF

c loop over all bdary elements in this region
         DO 200 L=NFOFF,LOFFBND(IB,NBLK)
            I = LOCBND(1,L)
            J = LOCBND(2,L)
            K = LOCBND(3,L)
            NDIR = LOCBND(4,L)
            IF ((NTYPE.EQ.3).OR.(NTYPE.EQ.-2)) THEN

              PQ = 0.D0
              IF(NDIR.EQ.1)THEN
                Itemp = I+1
                CALL GETFACECENTER(Itemp,J,K, Itemp,J+1,K,
     &                             Itemp,J+1,K+1, Itemp,J,K+1,
     &                             XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
              ELSEIF(NDIR.EQ.2)THEN
                Itemp = I
                CALL GETFACECENTER(Itemp,J,K, Itemp,J+1,K,
     &                             Itemp,J+1,K+1, Itemp,J,K+1,
     &                             XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
              ELSEIF(NDIR.EQ.3)THEN
                Jtemp = J+1
		CALL GETFACECENTER(I,Jtemp,K, I+1,Jtemp,K,
     &                             I+1,Jtemp,K+1, I,Jtemp,K+1,
     &                             XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
              ELSEIF(NDIR.EQ.4)THEN
                Jtemp = J
		CALL GETFACECENTER(I,Jtemp,K, I+1,Jtemp,K,
     &                             I+1,Jtemp,K+1, I,Jtemp,K+1,
     &                             XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
              ELSEIF(NDIR.EQ.5)THEN
                Ktemp = K+1
                CALL GETFACECENTER(I,J,Ktemp, I+1,J,Ktemp,
     &                             I+1,J+1,Ktemp, I,J+1,Ktemp,
     &                             XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
              ELSEIF(NDIR.EQ.6)THEN
                Ktemp = K
                CALL GETFACECENTER(I,J,Ktemp, I+1,J,Ktemp,
     &                             I+1,J+1,Ktemp, I,J+1,Ktemp,
     &                             XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
              ELSE
                write(0,*)'IMPFA.DF: NDIR IS WRONG'
                stop
              ENDIF
C
C DEPB IS NOT USED IN INPUT FILE
C
              IF (NTYPE.EQ.-2) THEN
                 DEPB = DEPTH(I,J,K)
                 CALL BDMOD(NBDPROG(IB),XB,YB,ZB,DEPB,PQ)
              ELSEIF (NTYPE.EQ.3) THEN
                 DEPB = DEPTH(I,J,K)
                 CALL BDMOD(NBDPROG(IB),XB,YB,ZB,DEPB,PQ)
              ENDIF

            ENDIF

c
c assign MPFA_TYPE to faceprop
c

c x- faces
          IF (NDIR.EQ.1) THEN
	    ITEMP = I+1
            call getFacePropVal
     &         (ITEMP,j,k,11,    ITEMP,j+1,k,9,
     &          ITEMP,j+1,k+1,1, ITEMP,j,k+1,3,
     &          MPFA_BTYPE,idim,jdim,kdim,faceprop)
c x+ faces
          ELSEIF (NDIR.EQ.2) THEN
            ITEMP = I
 	    call getFacePropVal
     &         (ITEMP,j,k,11,    ITEMP,j+1,k,9,
     &          ITEMP,j+1,k+1,1, ITEMP,j,k+1,3,
     &          MPFA_BTYPE,idim,jdim,kdim,faceprop)
c y- faces
          ELSEIF (NDIR.EQ.3) THEN
            JTEMP = j+1
            call getFacePropVal
     &         (i,JTEMP,k,10,    i+1,JTEMP,k,12,
     &          i+1,JTEMP,k+1,4, i,JTEMP,k+1,2,
     &          MPFA_BTYPE,idim,jdim,kdim,faceprop)
c y+ faces
          ELSEIF (NDIR.EQ.4) THEN
	    JTEMP = j
            call getFacePropVal
     &         (i,JTEMP,k,10,     i+1,JTEMP,k,12,
     &          i+1,JTEMP,k+1,4,  i,JTEMP,k+1,2,
     &           MPFA_BTYPE,idim,jdim,kdim,faceprop)

c z- faces
          ELSEIF (NDIR.EQ.5) THEN
            KTEMP = k+1
            call getFacePropVal
     &         (i,j,KTEMP,7, i+1,j,KTEMP,8,
     &          i+1,j+1,KTEMP,5, i,j+1,KTEMP,6,
     &           MPFA_BTYPE,idim,jdim,kdim,faceprop)

c z+ faces
          ELSEIF (NDIR.EQ.6) THEN
            KTEMP = k
            call getFacePropVal
     &         (i,j,KTEMP,7, i+1,j,KTEMP,8,
     &          i+1,j+1,KTEMP,5, i,j+1,KTEMP,6,
     &           MPFA_BTYPE,idim,jdim,kdim,faceprop)
          ELSE
            write(0,*)'IMPFA.DF: NDIR IS WRONG'
            stop
          ENDIF

 200     CONTINUE
 100  CONTINUE

      return
      end



c======================================================================
      SUBROUTINE GETFACECENTER(I1,J1,K1,I2,J2,K2,I3,J3,K3,I4,J4,K4,
     &                         XB,YB,ZB,XC,YC,ZC,IDIM,JDIM,KDIM)
c======================================================================
      IMPLICIT NONE
      INTEGER I1,J1,K1,I2,J2,K2,I3,J3,K3,I4,J4,K4,IDIM,JDIM,KDIM
      real*8 xc(idim+1,jdim+1,kdim+1),yc(idim+1,jdim+1,kdim+1),
     &       zc(idim+1,jdim+1,kdim+1)

      REAL*8 XB,YB,ZB

      XB = 0.25D0*(XC(I1,J1,K1)+XC(I2,J2,K2)+XC(I3,J3,K3)+XC(I4,J4,K4))
      YB = 0.25D0*(YC(I1,J1,K1)+YC(I2,J2,K2)+YC(I3,J3,K3)+YC(I4,J4,K4))
      ZB = 0.25D0*(ZC(I1,J1,K1)+ZC(I2,J2,K2)+ZC(I3,J3,K3)+ZC(I4,J4,K4))

      RETURN
      END

c======================================================================
      subroutine getFacePropVal
     &     (i1,j1,k1,f1,i2,j2,k2,f2,i3,j3,k3,f3,i4,j4,k4,f4,
     &     MPFA_BTYPE,idim,jdim,kdim,faceprop)
c======================================================================
      implicit none
      integer i1,j1,k1,f1,i2,j2,k2,f2,i3,j3,k3,f3,i4,j4,k4,f4,
     &     MPFA_BTYPE,idim,jdim,kdim
      integer faceprop(idim+1,jdim+1,kdim+1,12)
c
      faceprop(i1,j1,k1,f1) = MPFA_BTYPE
      faceprop(i2,j2,k2,f2) = MPFA_BTYPE
      faceprop(i3,j3,k3,f3) = MPFA_BTYPE
      faceprop(i4,j4,k4,f4) = MPFA_BTYPE

      return
      end

c======================================================================
      subroutine updateFaces(idim,jdim,kdim,ldim,il1,il2,jl1v,jl2v,
     &     kl1,kl2,keyout,nblk,faceprop)
c======================================================================
      implicit none
C
C SUBROUTINE UPDATEFACES TO UPDATE FACEPROP, FACEVAL AFTER EXCHANGE
C
      include 'boundary.h'

      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),jl2v(kdim),
     &     kl1,kl2,keyout(idim,jdim,kdim),nblk
c
      integer faceprop(idim+1,jdim+1,kdim+1,12)
c
      integer i,j,k,l,jl1,jl2,IB,NTYPE,NDIR,NFOFF,MPFA_BTYPE
      INTEGER ITEMP,JTEMP,KTEMP

c      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,IERR)

      IF (NBND_REG.EQ.0.OR.NBEL.EQ.0) RETURN

C  LOOP OVER THE bdary condition regions
      DO 100 IB=1,NBND_REG

c ntype, 1: constant Dirichlet, 2: Dirichlet with gravity
c        3: user specified function, 0: no-flow, < 0: non-zero flux
         NTYPE = NBND_TYPE(IB)
c
c convert IPARS boundary type to MPFA boundary type
c
         IF (NTYPE.LT.0) MPFA_BTYPE = 1
         IF (NTYPE.GT.0) MPFA_BTYPE = 2
         IF (NTYPE.EQ.0) MPFA_BTYPE = 3

         IF(NBLK.EQ.1.AND.IB.EQ.1) NFOFF=1
         IF(NBLK.GT.1.AND.IB.EQ.1) NFOFF=LOFFBND(NBND_REG,NBLK-1)+1
         IF(IB.NE.1) NFOFF=LOFFBND(IB-1,NBLK)+1

c loop over all bdary elements in this region
         DO 200 L=NFOFF,LOFFBND(IB,NBLK)
           I = LOCBND(1,L)
           J = LOCBND(2,L)
           K = LOCBND(3,L)
           NDIR = LOCBND(4,L)


c x- faces
	   IF(NDIR.EQ.1)THEN

            ITEMP = I+1
            jl1=jl1v(k)
            jl2=jl2v(k)

            if (j.eq.jl1) then

               call DNfromNeighbor(ITEMP,j-1,k,ITEMP,j,k,9,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j-1,k+1,ITEMP,j,k+1,1,
     &              faceprop,idim,jdim,kdim)

            elseif(j.eq.jl2) then

               call DNfromNeighbor(ITEMP,j+2,k,ITEMP,j+1,k,11,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j+2,k+1,ITEMP,j+1,k+1,3,
     &              faceprop,idim,jdim,kdim)

            endif

            if(k.eq.kl1) then

               call DNfromNeighbor(ITEMP,j,k-1,ITEMP,j,k,3,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j+1,k-1,ITEMP,j+1,k,1,
     &              faceprop,idim,jdim,kdim)

            elseif(k.eq.kl2) then

               call DNfromNeighbor(ITEMP,j,k+2,ITEMP,j,k+1,11,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j+1,k+2,ITEMP,j+1,k+1,9,
     &              faceprop,idim,jdim,kdim)

            endif

c x+ face
	   ELSEIF(NDIR.EQ.2)THEN
	    ITEMP = I
            jl1=jl1v(k)
            jl2=jl2v(k)

            if (j.eq.jl1) then

               call DNfromNeighbor(ITEMP,j-1,k,ITEMP,j,k,9,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j-1,k+1,ITEMP,j,k+1,1,
     &              faceprop,idim,jdim,kdim)

            elseif(j.eq.jl2) then

               call DNfromNeighbor(ITEMP,j+2,k,ITEMP,j+1,k,11,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j+2,k+1,ITEMP,j+1,k+1,3,
     &              faceprop,idim,jdim,kdim)

            endif

            if(k.eq.kl1) then

               call DNfromNeighbor(ITEMP,j,k-1,ITEMP,j,k,3,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j+1,k-1,ITEMP,j+1,k,1,
     &              faceprop,idim,jdim,kdim)

            elseif(k.eq.kl2) then

               call DNfromNeighbor(ITEMP,j,k+2,ITEMP,j,k+1,11,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(ITEMP,j+1,k+2,ITEMP,j+1,k+1,9,
     &              faceprop,idim,jdim,kdim)

            endif

c y- faces
	   ELSEIF(NDIR.EQ.3)THEN
	    JTEMP = J+1

            if (i.eq.il1) then

               call DNfromNeighbor(i-1,JTEMP,k,i,JTEMP,k,12,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i-1,JTEMP,k+1,i,JTEMP,k+1,4,
     &              faceprop,idim,jdim,kdim)

            elseif(i.eq.il2)then

               call DNfromNeighbor(i+2,JTEMP,k,i+1,JTEMP,k,10,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+2,JTEMP,k+1,i+1,JTEMP,k+1,2,
     &              faceprop,idim,jdim,kdim)

            endif

            if (k.eq.kl1) then

               call DNfromNeighbor(i,JTEMP,k-1,i,JTEMP,k,2,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,JTEMP,k-1,i+1,JTEMP,k,4,
     &              faceprop,idim,jdim,kdim)

            elseif(k.eq.kl2)then

               call DNfromNeighbor(i,JTEMP,k+2,i,JTEMP,k+1,10,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,JTEMP,k+2,i+1,JTEMP,k+1,12,
     &              faceprop,idim,jdim,kdim)

            endif

c y+ faces
	   ELSEIF(NDIR.EQ.4)THEN
	    JTEMP = J
            if (i.eq.il1) then

               call DNfromNeighbor(i-1,JTEMP,k,i,JTEMP,k,12,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i-1,JTEMP,k+1,i,JTEMP,k+1,4,
     &              faceprop,idim,jdim,kdim)

            elseif(i.eq.il2)then

               call DNfromNeighbor(i+2,JTEMP,k,i+1,JTEMP,k,10,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+2,JTEMP,k+1,i+1,JTEMP,k+1,2,
     &              faceprop,idim,jdim,kdim)

            endif

            if (k.eq.kl1) then

               call DNfromNeighbor(i,JTEMP,k-1,i,JTEMP,k,2,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,JTEMP,k-1,i+1,JTEMP,k,4,
     &              faceprop,idim,jdim,kdim)

            elseif(k.eq.kl2)then

               call DNfromNeighbor(i,JTEMP,k+2,i,JTEMP,k+1,10,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,JTEMP,k+2,i+1,JTEMP,k+1,12,
     &              faceprop,idim,jdim,kdim)

            endif

c z- faces
	   ELSEIF(NDIR.EQ.5)THEN

	    KTEMP = K+1
            jl1=jl1v(k)
            jl2=jl2v(k)

            if (i.eq.il1)then

               call DNfromNeighbor(i-1,j,KTEMP,i,j,KTEMP,8,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i-1,j+1,KTEMP,i,j+1,KTEMP,5,
     &              faceprop,idim,jdim,kdim)

            elseif(i.eq.il2)then

               call DNfromNeighbor(i+2,j,KTEMP,i+1,j,KTEMP,7,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+2,j+1,KTEMP,i+1,j+1,KTEMP,6,
     &              faceprop,idim,jdim,kdim)

            endif

            if (j.eq.jl1)then

               call DNfromNeighbor(i,j-1,KTEMP,i,j,KTEMP,6,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,j-1,KTEMP,i+1,j,KTEMP,5,
     &              faceprop,idim,jdim,kdim)

            elseif(j.eq.jl2)then

               call DNfromNeighbor(i,j+2,KTEMP,i,j+1,KTEMP,7,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,j+2,KTEMP,i+1,j+1,KTEMP,8,
     &              faceprop,idim,jdim,kdim)

            endif

c z+ faces
	   ELSEIF(NDIR.EQ.6)THEN
	    KTEMP = K
            jl1=jl1v(k)
            jl2=jl2v(k)

            if (i.eq.il1)then

               call DNfromNeighbor(i-1,j,KTEMP,i,j,KTEMP,8,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i-1,j+1,KTEMP,i,j+1,KTEMP,5,
     &              faceprop,idim,jdim,kdim)

            elseif(i.eq.il2)then

               call DNfromNeighbor(i+2,j,KTEMP,i+1,j,KTEMP,7,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+2,j+1,KTEMP,i+1,j+1,KTEMP,6,
     &              faceprop,idim,jdim,kdim)

            endif

            if (j.eq.jl1)then

               call DNfromNeighbor(i,j-1,KTEMP,i,j,KTEMP,6,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,j-1,KTEMP,i+1,j,KTEMP,5,
     &              faceprop,idim,jdim,kdim)

            elseif(j.eq.jl2)then

               call DNfromNeighbor(i,j+2,KTEMP,i,j+1,KTEMP,7,
     &              faceprop,idim,jdim,kdim)

               call DNfromNeighbor(i+1,j+2,KTEMP,i+1,j+1,KTEMP,8,
     &              faceprop,idim,jdim,kdim)

            endif
	   ELSE
	      write(0,*)'IMPFA.DF: NDIR IS WORONG'
	   ENDIF
 200     continue

 100  continue

      return
      end

c======================================================================
      subroutine DNfromNeighbor(in,jn,kn,i,j,k,index,
     &     faceprop,idim,jdim,kdim)
c======================================================================
      implicit none
c
      integer in,jn,kn,i,j,k,index,idim,jdim,kdim
c
      integer faceprop(idim+1,jdim+1,kdim+1,12)
c
      integer fpropn


      fpropn = faceprop(in,jn,kn,index)

      if ((fpropn.eq.1).or.(fpropn.eq.2))then
         faceprop(i,j,k,index) = fpropn
      endif

      return
      end

c======================================================================
      subroutine calcVOLFACEdim(idim,jdim,kdim,ldim,il1,il2,jl1v,jl2v,
     &                kl1,kl2,keyout,nblk,volprop,faceprop,keyoutcr,
     &                voldim,facedim)
c======================================================================
      implicit none

      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),jl2v(kdim),
     &     kl1,kl2,keyout(idim,jdim,kdim),nblk,
     &     volprop(idim+1,jdim+1,kdim+1,8),
     &     faceprop(idim+1,jdim+1,kdim+1,12),
     &     keyoutcr(idim+1,jdim+1,kdim+1),voldim(idim+1,jdim+1,kdim+1),
     &     facedim(idim+1,jdim+1,kdim+1)
c
      integer i,j,k,jl1,jl2,l,count


c
c  initialization
c

      voldim = 0
      facedim = 0

      do 200 k = kl1, kl2+1
      do 200 j = 1, jdim+1
      do 200 i = il1, il2+1
         if (keyoutcr(i,j,k).eq.1)then
            voldim(i,j,k) = 8
            facedim(i,j,k) = 12
         elseif (keyoutcr(i,j,k).eq.2)then

              count = 0
              do l = 1,8
                 if (volprop(i,j,k,l).eq.0) count = count + 1
              enddo
              voldim(i,j,k) = count

              count = 0
              do l = 1, 12
                 if ((faceprop(i,j,k,l).eq.0).or.
     &                (faceprop(i,j,k,l).eq.2)) count = count + 1
              enddo
              facedim(i,j,k) = count

           endif

 200    continue

      return
      end


c======================================================================
      subroutine calcArea(idim,jdim,kdim,ldim,il1,il2,jl1v,jl2v,
     &     kl1,kl2,keyout,nblk,xc,yc,zc,facearea)
c======================================================================
      implicit none
c
      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),jl2v(kdim),
     &     kl1,kl2,keyout(idim,jdim,kdim),nblk,jl1,jl2
      real*8 xc(idim+1,jdim+1,kdim+1),yc(idim+1,jdim+1,kdim+1),
     &       zc(idim+1,jdim+1,kdim+1)

      real*8 facearea(idim+1,jdim+1,kdim+1,12)
c
      integer n,II,JJ,KK,I,J,K,OFFSET(3,8)
      real*8 X(3,8),farea(6)
c
      DATA OFFSET/0,0,0, 1,0,0, 1,1,0, 0,1,0,
     &     0,0,1, 1,0,1, 1,1,1, 0,1,1/

      do 50 k = 1,kdim+1
      do 50 j = 1,jdim+1
      do 50 i = 1,idim+1
      do 50 n = 1,12
          facearea(i,j,k,n) = 0.0d0
 50   continue

      do 100 k = 1, kdim
      do 100 j = 1, jdim
      do 100 i = 1, idim

         if (keyout(i,j,k).ne.0) then

         do 11 n = 1, 8
            II = I  + OFFSET(1,N)
            JJ = J  + OFFSET(2,N)
            KK = K  + OFFSET(3,N)

            X(1,N) = XC(II,JJ,KK)
            X(2,N) = YC(II,JJ,KK)
            X(3,N) = ZC(II,JJ,KK)
 11      continue

         call ElementArea(X,farea)
         call AddFace(farea,i,j,k,facearea,idim,jdim,kdim)

         endif

 100  enddo

      return
      end

c bag8, djw - needed for XPORE
c======================================================================
      subroutine calcEVOL(idim,jdim,kdim,ldim,il1,il2,jl1v,jl2v,
     &     kl1,kl2,keyout,nblk,xc,yc,zc,EVOL)
c======================================================================
      implicit none
c
      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),jl2v(kdim),
     &     kl1,kl2,keyout(idim,jdim,kdim),nblk,jl1,jl2
      real*8 xc(idim+1,jdim+1,kdim+1),yc(idim+1,jdim+1,kdim+1),
     &       zc(idim+1,jdim+1,kdim+1)
      real*8 EVOL(idim,jdim,kdim)
c
      integer I,J,K,N,II,JJ,KK,OFFSET(3,8)
      real*8 X(3,8)
      real*8 VOLH
c
      DATA OFFSET/0,0,0, 1,0,0, 1,1,0, 0,1,0,
     &     0,0,1, 1,0,1, 1,1,1, 0,1,1/

      do 100 k = 1, kdim
      do 100 j = 1, jdim
      do 100 i = 1, idim

         if (keyout(i,j,k).gt.0) then

         do n = 1, 8
            II = I  + OFFSET(1,N)
            JJ = J  + OFFSET(2,N)
            KK = K  + OFFSET(3,N)

            X(1,N) = XC(II,JJ,KK)
            X(2,N) = YC(II,JJ,KK)
            X(3,N) = ZC(II,JJ,KK)
         enddo

         EVOL(I,J,K) = VOLH(X)

         endif

 100  enddo

      return
      end


c======================================================================
      subroutine ElementArea(X,farea)
c======================================================================
      implicit none
c
c     ^(y) (Top/Bottom)
c     |
c     |
c     |__________(x) (Left/Right)
c      \
c        \
c          (z) (Front/Back)
c
c    4 -----------------3
c      \                 \
c     |  \              |  \
c     |   8-----------------7
c     |   |             |   |
c    1 \  |            2 \  |
c       \ |                \|
c         5-----------------6
c

      real*8 X(3,8),farea(6)

c x- face
      call getArea(X,1,4,8,5,farea(1))
c x+ face
      call getArea(X,2,3,7,6,farea(2))
c y- face
      call getArea(X,1,2,6,5,farea(3))
c y+ face
      call getArea(X,4,3,7,8,farea(4))
c z- face
      call getArea(X,1,2,3,4,farea(5))
c z+ face
      call getArea(X,5,6,7,8,farea(6))

      return
      end

c======================================================================
      subroutine getArea(X,i1,i2,i3,i4,area)
c======================================================================
      implicit none
C
C     Area of face.
C     Approximat the face by four triangles.
C     If the face is planar, the computation is exact.
C
c      i4 ------ i3
c       |         |
c       |   ic    |
c       |         |
c      i1 ------ i2
c
c
c
      integer i1,i2,i3,i4
      real*8 X(3,8),area
C
      real*8 TRI_AREA
C
      integer dim
      real*8 Xcen(3)
C
      do 100 dim = 1,3
         Xcen(dim) = 0.25d0*(X(dim,i1)+X(dim,i2)+X(dim,i3)+X(dim,i4))
  100 continue

      area =   Tri_AREA(Xcen,X(1,i1),X(1,i2))
     &       + Tri_AREA(Xcen,X(1,i2),X(1,i3))
     &       + Tri_AREA(Xcen,X(1,i3),X(1,i4))
     &       + Tri_AREA(Xcen,X(1,i4),X(1,i1))

      return
      end


c======================================================================
      subroutine AddFace(farea,i,j,k,facearea,idim,jdim,kdim)
c======================================================================
      implicit none
c
c     ^(y) (Top/Bottom)
c     |
c     |
c     |__________(x) (Left/Right)
c      \
c        \
c          (z) (Front/Back)
c
c      -----------------
c      \                 \
c     |  \              |  \
c     |   ------------------
c     |   |             |   |
c (i,j,k) |    (i,j,k)   \  |
c       \ |                \|
c         ------------------
c
c here i,j,k is volume index
c For the purpose of code simplification, we store extra
c information, for example, face(idim+2,...).
c This space is normally reserved for the communication.
c Since we do not need the communication, it is ok to occupy
c this space.
c
      integer i,j,k,idim,jdim,kdim
      real*8 facearea(idim+1,jdim+1,kdim+1,12),farea(12)

c x- face
      facearea(i,j,k,11) = farea(1)
      facearea(i,j+1,k,9) = farea(1)
      facearea(i,j+1,k+1,1) = farea(1)
      facearea(i,j,k+1,3) = farea(1)
c x+ face
      facearea(i+1,j,k,11) = farea(2)
      facearea(i+1,j+1,k,9) = farea(2)
      facearea(i+1,j+1,k+1,1) = farea(2)
      facearea(i+1,j,k+1,3) = farea(2)
c y- face
      facearea(i,j,k,10) = farea(3)
      facearea(i+1,j,k,12) = farea(3)
      facearea(i+1,j,K+1,4) = farea(3)
      facearea(i,j,k+1,2) = farea(3)
c y+ face
      facearea(i,j+1,k,10) = farea(4)
      facearea(i+1,j+1,k,12) = farea(4)
      facearea(i+1,j+1,K+1,4) = farea(4)
      facearea(i,j+1,k+1,2) = farea(4)
c z- face
      facearea(i,j,k,7) = farea(5)
      facearea(i+1,j,k,8) = farea(5)
      facearea(i+1,j+1,k,5) = farea(5)
      facearea(i,j+1,k,6) = farea(5)
c z+ face
      facearea(i,j,k+1,7) = farea(6)
      facearea(i+1,j,k+1,8) = farea(6)
      facearea(i+1,j+1,k+1,5) = farea(6)
      facearea(i,j+1,k+1,6) = farea(6)

      return
      end

c======================================================================

C======================================================================
      SUBROUTINE TRANC2 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
     &                   KEYOUT,NBLK,TX,TY,TZ,PX,PY,PZ,XC,YC,ZC)
C======================================================================

C  Calculate transmissability constant array for orthogonal grid option.
C  This is a dummy routine to mimic connectivity based upon keyout.
C  Example TX(I,J,K) = 1 (KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I-1,J,K).EQ.1)

C  TX(I,J,K) = Transmissability (OUTPUT, REAL*8)
C  TY(I,J,K)
C  TZ(I,J,K)

C======================================================================
      IMPLICIT NONE
      INCLUDE 'layout.h'
      INCLUDE 'blkary.h'
      INCLUDE 'emodel.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),KL1,KL2
     &        ,KEYOUT(IDIM,JDIM,KDIM),NBLK
      REAL*8 TX(IDIM,JDIM,KDIM),TY(IDIM,JDIM,KDIM),TZ(IDIM,JDIM,KDIM)
      REAL*8 DUM1,DUM2,DX,DY,DZ,CVC,C1,C2
      REAL*4 PX(IDIM,JDIM,KDIM),PY(IDIM,JDIM,KDIM),PZ(IDIM,JDIM,KDIM)
      REAL*8 XC(IDIM+1,JDIM+1,KDIM+1),YC(IDIM+1,JDIM+1,KDIM+1),
     &       ZC(IDIM+1,JDIM+1,KDIM+1)

      INTEGER MERR,I,J,K,JL1,JL2,IO,JO,KO

C bag8 - CVF = 2 sq-ft cp / md psi day
      CVC = 2 * CONV_FACTOR

C  PUT 0. PERMEABILITY IN UNUSED LOCATIONS

      DO 1 K=1,KDIM
      DO 1 J=1,JDIM
      DO 1 I=1,IDIM
      IF (KEYOUT(I,J,K).EQ.0) THEN
         TX(I,J,K)=0.D0
         TY(I,J,K)=0.D0
         TZ(I,J,K)=0.D0
         PX(I,J,K)=0.
         PY(I,J,K)=0.
         PZ(I,J,K)=0.
      ENDIF
    1 CONTINUE

C  CONVERT FROM PERMEABILITIES TO TRANSMISSABILITY COEFFICIENT CONSTANT

      DO 2 K=KL1,KL2
      JL1=JL1V(K)
      JL2=JL2V(K)
      DO 2 J=JL1,JL2
      IF (IL1.GT.1) THEN
         DUM1=PX(IL1-1,J,K)
      ELSE
         DUM1=0.D0
      ENDIF
      DO 3 I=IL1,IL2

! bag8 - this fixes stability check in comp_mfmfe model
      IO=I
      JO=J
      KO=K
      C1=0.25D0*(XC(IO,JO,KO)+XC(IO,JO+1,KO)+
     &           XC(IO,JO+1,KO+1)+XC(IO,JO,KO+1))
      C2=0.25D0*(XC(IO+1,JO,KO)+XC(IO+1,JO+1,KO)+
     &           XC(IO+1,JO+1,KO+1)+XC(IO+1,JO,KO+1))
      DX=ABS(C2-C1)
      C1=0.25D0*(YC(IO,JO,KO)+YC(IO+1,JO,KO)+
     &           YC(IO+1,JO,KO+1)+YC(IO,JO,KO+1))
      C2=0.25D0*(YC(IO,JO+1,KO)+YC(IO+1,JO+1,KO)+
     &           YC(IO+1,JO+1,KO+1)+YC(IO,JO+1,KO+1))
      DY=ABS(C2-C1)
      C1=0.25D0*(ZC(IO,JO,KO)+ZC(IO,JO+1,KO)+
     &           ZC(IO+1,JO+1,KO)+ZC(IO+1,JO,KO))
      C2=0.25D0*(ZC(IO,JO,KO+1)+ZC(IO,JO+1,KO+1)+
     &           ZC(IO+1,JO+1,KO+1)+ZC(IO+1,JO,KO+1))
      DZ=ABS(C2-C1)

      DUM2=PX(I,J,K)
      TX(I,J,K)=0.D0
      IF (I.GT.1)  THEN
        IF (DUM1.GT.0.D0.AND.DUM2.GT.0.D0.AND.
     &   (KEYOUT(I,J,K).EQ.1.OR.KEYOUT(I-1,J,K).EQ.1)) THEN
! bag8
         IO=I-1
         JO=J
         KO=K
         C1=0.25D0*(XC(IO,JO,KO)+XC(IO,JO+1,KO)+
     &              XC(IO,JO+1,KO+1)+XC(IO,JO,KO+1))
         C2=0.25D0*(XC(IO+1,JO,KO)+XC(IO+1,JO+1,KO)+
     &              XC(IO+1,JO+1,KO+1)+XC(IO+1,JO,KO+1))
         TX(I,J,K)=CVC*DY*DZ/(ABS(C2-C1)/DUM1+DX/DUM2)
        ENDIF
      ENDIF
    3 DUM1=DUM2
      IF (DUM2.GT.0.D0.AND.IL2.LT.IDIM.AND.PX(IL2+1,J,K).GT.0..AND.
     & (KEYOUT(IL2+1,J,K).EQ.1.OR.KEYOUT(IL2,J,K).EQ.1)) THEN
! bag8
         IO=IL2+1
         JO=J
         KO=K
         C1=0.25D0*(XC(IO,JO,KO)+XC(IO,JO+1,KO)+
     &              XC(IO,JO+1,KO+1)+XC(IO,JO,KO+1))
         C2=0.25D0*(XC(IO+1,JO,KO)+XC(IO+1,JO+1,KO)+
     &              XC(IO+1,JO+1,KO+1)+XC(IO+1,JO,KO+1))
         TX(IL2+1,J,K)=CVC*DY*DZ/(ABS(C2-C1)/PX(IL2+1,J,K)+DX/DUM2)
      ELSE
         IF (IL2.LT.IDIM) TX(IL2+1,J,K)=0.D0
      ENDIF
    2 CONTINUE

      DO 4 K=KL1,KL2
      JL1=JL1V(K)
      JL2=JL2V(K)
      DO 4 I=IL1,IL2
      IF (JL1.GT.1) THEN
         DUM1=PY(I,JL1-1,K)
      ELSE
         DUM1=0.D0
      ENDIF
      DO 5 J=JL1,JL2
      DUM2=PY(I,J,K)
      IF (DUM1.GT.0.D0.AND.DUM2.GT.0.D0.AND.J.GT.1.AND.
     & (KEYOUT(I,J,K).EQ.1.OR.KEYOUT(I,J-1,K).EQ.1)) THEN
! bag8
         IO=I
         JO=J-1
         KO=K
         C1=0.25D0*(YC(IO,JO,KO)+YC(IO+1,JO,KO)+
     &              YC(IO+1,JO,KO+1)+YC(IO,JO,KO+1))
         C2=0.25D0*(YC(IO,JO+1,KO)+YC(IO+1,JO+1,KO)+
     &              YC(IO+1,JO+1,KO+1)+YC(IO,JO+1,KO+1))
         TY(I,J,K)=CVC*DX*DZ/(ABS(C2-C1)/DUM1+DY/DUM2)
      ELSE
         TY(I,J,K)=0.D0
      ENDIF
    5 DUM1=DUM2
      IF (DUM2.GT.0.D0.AND.JL2.LT.JDIM.AND.PY(I,JL2+1,K).GT.0..AND.
     & (KEYOUT(I,JL2+1,K).EQ.1.OR.KEYOUT(I,JL2,K).EQ.1)) THEN
! bag8
         IO=I
         JO=JL2+1
         KO=K
         C1=0.25D0*(YC(IO,JO,KO)+YC(IO+1,JO,KO)+
     &              YC(IO+1,JO,KO+1)+YC(IO,JO,KO+1))
         C2=0.25D0*(YC(IO,JO+1,KO)+YC(IO+1,JO+1,KO)+
     &              YC(IO+1,JO+1,KO+1)+YC(IO,JO+1,KO+1))
         TY(I,JL2+1,K)=CVC*DX*DZ/(ABS(C2-C1)/PY(I,JL2+1,K)+DY/DUM2)
      ELSE
         TY(I,JL2+1,K)=0.D0
      ENDIF
    4 CONTINUE

      JL1=JDIM
      JL2=1
      DO 6 K=KL1,KL2
      IF (JL1V(K).LT.JL1) JL1=JL1V(K)
      IF (JL2V(K).GT.JL2) JL2=JL2V(K)
    6 CONTINUE

      DO 7 J=JL1,JL2
      DO 7 I=IL1,IL2
      IF (KL1.GT.1) THEN
         DUM1=PZ(I,J,KL1-1)
      ELSE
         DUM1=0.D0
      ENDIF
      DO 8 K=KL1,KL2
      DUM2=PZ(I,J,K)
      IF (DUM1.GT.0.D0.AND.DUM2.GT.0.D0.AND.K.GT.1.AND.
     & (KEYOUT(I,J,K).EQ.1.OR.KEYOUT(I,J,K-1).EQ.1)) THEN
! bag8
         IO=I
         JO=J
         KO=K-1
         C1=0.25D0*(ZC(IO,JO,KO)+ZC(IO+1,JO,KO)+
     &              ZC(IO+1,JO,KO+1)+ZC(IO,JO,KO+1))
         C2=0.25D0*(ZC(IO,JO+1,KO)+ZC(IO+1,JO+1,KO)+
     &              ZC(IO+1,JO+1,KO+1)+ZC(IO,JO+1,KO+1))
         TZ(I,J,K)=CVC*DX*DY/(ABS(C2-C1)/DUM1+DZ/DUM2)
      ELSE
         TZ(I,J,K)=0.D0
      ENDIF
    8 DUM1=DUM2
      IF (DUM2.GT.0.D0.AND.KL2.LT.KDIM.AND.PZ(I,J,KL2+1).GT.0..AND.
     & (KEYOUT(I,J,KL2+1).EQ.1.OR.KEYOUT(I,J,KL2).EQ.1)) THEN
! bag8
         IO=I
         JO=J
         KO=KL2+1
         C1=0.25D0*(ZC(IO,JO,KO)+ZC(IO+1,JO,KO)+
     &              ZC(IO+1,JO,KO+1)+ZC(IO,JO,KO+1))
         C2=0.25D0*(ZC(IO,JO+1,KO)+ZC(IO+1,JO+1,KO)+
     &              ZC(IO+1,JO+1,KO+1)+ZC(IO,JO+1,KO+1))
         TZ(I,J,KL2+1)=CVC*DX*DY/(ABS(C2-C1)/PZ(I,J,KL2+1)+DZ/DUM2)
      ELSE
         IF (KL2.LT.KDIM) TZ(I,J,KL2+1)=0.D0
      ENDIF
    7 CONTINUE

! Set perm for mandel problem
      IF (MECH_BC_NCASE.EQ.100) THEN
      DO K = KL1,KL2
      DO J = JL1V(K),JL2V(K)
      DO I = IL1,IL2
      IF (KEYOUT(I,J,K).EQ.1) THEN
      IF (PX(I,J,K).GT.0.D0) THEN
      MANDEL_PERM = PX(I,J,K)
      GOTO 10
      ENDIF
      ENDIF
      ENDDO
      ENDDO
      ENDDO
 10   CONTINUE
      ENDIF

      END

C*********************************************************************
      SUBROUTINE DOROCK2 (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                   KL2,KEYOUT,NBLK,DEPTH,POR,XPERM,YPERM,ZPERM)
C*********************************************************************

C  Modifies porosity and permeability arrays according to user supplied code.

C  DEPTH(I,J,K) = Depth array (input, REAL*8)

C  POR(I,J,K) = Porosity array (input and output, REAL*8)

C  XPERM(I,J,K) = Permeability arrays (input and output, REAL*8)

C  Note: The DEPTH array may be used in the program but may not be modified
C        since well depths are not modified by this program.
C*********************************************************************
C      INCLUDE 'msjunk.h'

      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'rockpg.h'

      REAL*8 DEPTH(IDIM,JDIM,KDIM),POR(IDIM,JDIM,KDIM)
      REAL*4 XPERM(IDIM,JDIM,KDIM),YPERM(IDIM,JDIM,KDIM),
     & ZPERM(IDIM,JDIM,KDIM)
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)

      CALL BLKDIM(NBLK,ID,JD,KD,MERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,MERR)
      RNBLK=NBLK
      RNBLK=RNBLK+1.D-6

      DO 1 K=1,KDIM
      KG=K+KOFF
      IF (KG.GT.0.AND.KG.LE.KD) THEN
         DO 2 J=1,JDIM
         JG=J+JOFF
         IF (JG.GT.0.AND.JG.LE.JD) THEN
            DO 3 I=1,IDIM
            IG=I+IOFF
            IF (IG.GT.0.AND.IG.LE.ID) THEN
               X=.5D0*(XREC(IG,NBLK)+XREC(IG+1,NBLK))
               Y=.5D0*(YREC(JG,NBLK)+YREC(JG+1,NBLK))
               Z=.5D0*(ZREC(KG,NBLK)+ZREC(KG+1,NBLK))
               DEP=DEPTH(I,J,K)
               PORP=POR(I,J,K)
               XPERMP=XPERM(I,J,K)
               YPERMP=YPERM(I,J,K)
               ZPERMP=ZPERM(I,J,K)
               CALL EXCDRV(NPGR,KE)

               IF (KE.NE.0) THEN
                  IF (LEVERR.LT.3) LEVERR=3
                  IF (LEVELC) WRITE (NFOUT,4)
                  RETURN
               ENDIF
    4          FORMAT(' ERROR # 418, USER PROGRAM ERROR IN ROCKMOD')

               IF (ABS(PORP-POR(I,J,K)).GT..00001) HPORMOD=.TRUE.
               IF (ABS(XPERMP-XPERM(I,J,K)).GT..001) HXPRMOD=.TRUE.
               IF (ABS(YPERMP-YPERM(I,J,K)).GT..001) HYPRMOD=.TRUE.
               IF (ABS(ZPERMP-ZPERM(I,J,K)).GT..001) HZPRMOD=.TRUE.
               POR(I,J,K)=PORP
               XPERM(I,J,K)=XPERMP
               YPERM(I,J,K)=YPERMP
               ZPERM(I,J,K)=ZPERMP
            ENDIF
    3       CONTINUE
         ENDIF
    2    CONTINUE
      ENDIF
    1 CONTINUE

      END