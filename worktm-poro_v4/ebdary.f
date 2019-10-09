C EBDARY.F - INPUT ELASTIC MODEL BOUNDARY CONDITION DATA
C
C ROUTINES IN THIS FILE:
C
C     SUBROUTINE EBDARY(NTIME,NERR)
C
C     SUBROUTINE EBDARY_BE(VNAM,N_ARY,KARY,NFACE,NDIR,NTYP,
C                NUMRET,NERR)
C
C     SUBROUTINE EBDARY_SCAL(VNAM,VAL,VTYP,NFACE,NDIR,NTYP,
C                ND1,ND2,ND3,ND4,NUMRET,NERR)
C
C     SUBROUTINE ESETVNAM(VNAM,VNAMC,NB)
C
C     SUBROUTINE EBDARY_BEWR8(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                KL1,KL2,KEYOUT,NBLKA,BD_VAL)
C
C     SUBROUTINE EBDARY_FACES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                KL1,KL2,KEYOUT,NBLK)
C
C     SUBROUTINE EBDARY_UPDATE(KERR)
C
C     SUBROUTINE EBDARY_BE_WRK(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL)
C
C     SUBROUTINE EBDARY_WRK_BE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL)
C
C     SUBROUTINE ETRACTION_TOP(KERR)
C
C     SUBROUTINE ETRACTION_TOPW(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
C                      KL1,KL2,KEYOUT,NBLK,DEPTH,BD_VAL)

C     SUBROUTINE ETRACTION_SIDE(KERR)

C     SUBROUTINE EGETVAL  (VNAM,VAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,NERR)
C     ENTRY      EGETVALS (VNAM,SVAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,NERR)
C
C CODE HISTORY:
C     XIULI GAI  12/02/2001
C***********************************************************************
      SUBROUTINE EBDARY(NTIME,NERR)
C***********************************************************************
C Get elastic model boundary condition data
C
C NTIME = BOUNDARY CONDITION READING TIME
C       = 1 INITIALIZATION
C       = 2 TRANSIENT
C
C NERR  = ERROR KEY STEPED BY ONE FOR EACH ERROR (INPUT & OUTPUT, INTEGER)
C     ITYPE_BOUNDARY(1,1,NBLK) = -X SIDE, X-DIRECTION
C     ITYPE_BOUNDARY(1,2,NBLK) = -X SIDE, Y-DIRECTION
C     ITYPE_BOUNDARY(1,3,NBLK) = -X SIDE, Z-DIRECTION
C     ITYPE_BOUNDARY(2,:,NBLK) = +X SIDE,
C     ITYPE_BOUNDARY(3,1,NBLK) = -Y SIDE, X-DIRECTION
C     ITYPE_BOUNDARY(3,2,NBLK) = -Y SIDE, Y-DIRECTION
C     ITYPE_BOUNDARY(3,3,NBLK) = -Y SIDE, Z-DIRECTION
C     ITYPE_BOUNDARY(4,:,NBLK) = +Y SIDE,
C     ITYPE_BOUNDARY(5,:,NBLK) = -Z SIDE,
C     ITYPE_BOUNDARY(6,:,NBLK) = +Z SIDE,
C************************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'blkary.h'
      INCLUDE 'readdat.h'
      INCLUDE 'unitsex.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      EXTERNAL EBDARY_FACES,EDISP_FACES
      INTEGER  NERR,NTIME,NDIM_ELASTIC,NDIM

      INTEGER  I,J,K,JBD(2),KERR,NDUM,JINIT(4),IBDYTYPE
      REAL*8   DUM(6,3,10)
      CHARACTER*10 JTYPE(3),JSIDE(6)
      CHARACTER*50 TITL
c      LOGICAL  DPTYP

C FIND BOUNDARY FACES AND ALLOCATE MEMORY FOR BOUNDARY ELEMENTS

cbw   IBD_FACE: indicates whether a processor owns a physical boundary
cbw             , not includes ghost layers

         DO K=1,NUMBLK
            DO J=1,3
               DO I=1,6
                  ITYPE_BOUNDARY(I,J,K)=0
               ENDDO
            ENDDO
            DO I=1,6
               IBD_FACE(I,K)=.FALSE.
               DP_FACE(I,K)=.FALSE.
            ENDDO
         ENDDO

         JBD(1)=0
         CALL CALLWORK(EBDARY_FACES,JBD)
         CALL CALLWORK(EDISP_FACES,JBD)

cbw  B.C. Type flag arrays
         N_TYPEBD(1)=0
         N_TYPEBD(2)=0
         N_TYPEBD(3)=0
         N_TYPEBD(4)=0
         N_TYPEBD(5)=0
         N_TYPEBD(6)=0

cbw  Nodal Traction B.C. arrays
         N_TRACBD(1)=0
         N_TRACBD(2)=0
         N_TRACBD(3)=0
         N_TRACBD(4)=0
         N_TRACBD(5)=0
         N_TRACBD(6)=0

cbw  Dirichlet B.C. arrays
         N_DISPBD(1)=0
         N_DISPBD(2)=0
         N_DISPBD(3)=0
         N_DISPBD(4)=0
         N_DISPBD(5)=0
         N_DISPBD(6)=0

cbw  Face Traction B.C. arrays
         N_TRACFACE(1)=0
         N_TRACFACE(2)=0
         N_TRACFACE(3)=0
         N_TRACFACE(4)=0
         N_TRACFACE(5)=0
         N_TRACFACE(6)=0

cbw  Face Pressure B.C. arrays
         N_PRESFACE(1)=0
         N_PRESFACE(2)=0
         N_PRESFACE(3)=0
         N_PRESFACE(4)=0
         N_PRESFACE(5)=0
         N_PRESFACE(6)=0

         KERR = 0
               CALL EALCBEA('TYPEX ',4,3,N_TYPEBD(1),1,KERR)
               CALL EALCBEA('TRACX ',2,3,N_TRACBD(1),1,KERR)
               CALL EALCBEA('DISPX ',2,3,N_DISPBD(1),1,KERR)
               CALL EALCBEA('FTRACX ',2,3,N_TRACFACE(1),1,KERR)
               CALL EALCBEA('PRESX ',2,1,N_PRESFACE(1),1,KERR)
               CALL EALCBEA('TYPEXN ',4,3,N_TYPEBD(2),1,KERR)
               CALL EALCBEA('TRACXN ',2,3,N_TRACBD(2),1,KERR)
               CALL EALCBEA('DISPXN ',2,3,N_DISPBD(2),1,KERR)
               CALL EALCBEA('FTRACXN ',2,3,N_TRACFACE(2),1,KERR)
               CALL EALCBEA('PRESXN ',2,1,N_PRESFACE(2),1,KERR)
               CALL EALCBEA('TYPEY ',4,3,N_TYPEBD(3),2,KERR)
               CALL EALCBEA('TRACY ',2,3,N_TRACBD(3),2,KERR)
               CALL EALCBEA('DISPY ',2,3,N_DISPBD(3),2,KERR)
               CALL EALCBEA('FTRACY ',2,3,N_TRACFACE(3),2,KERR)
               CALL EALCBEA('PRESY ',2,1,N_PRESFACE(3),2,KERR)
               CALL EALCBEA('TYPEXN ',4,3,N_TYPEBD(4),2,KERR)
               CALL EALCBEA('TRACYN ',2,3,N_TRACBD(4),2,KERR)
               CALL EALCBEA('DISPYN ',2,3,N_DISPBD(4),2,KERR)
               CALL EALCBEA('FTRACYN ',2,3,N_TRACFACE(4),2,KERR)
               CALL EALCBEA('PRESYN ',2,1,N_PRESFACE(4),2,KERR)
               CALL EALCBEA('TYPEZ ',4,3,N_TYPEBD(5),3,KERR)
               CALL EALCBEA('TRACZ ',2,3,N_TRACBD(5),3,KERR)
               CALL EALCBEA('DISPZ ',2,3,N_DISPBD(5),3,KERR)
               CALL EALCBEA('FTRACZ ',2,3,N_TRACFACE(5),3,KERR)
               CALL EALCBEA('PRESZ ',2,1,N_PRESFACE(5),3,KERR)
               CALL EALCBEA('TYPEZN ',4,3,N_TYPEBD(6),3,KERR)
               CALL EALCBEA('TRACZN ',2,3,N_TRACBD(6),3,KERR)
               CALL EALCBEA('DISPZN ',2,3,N_DISPBD(6),3,KERR)
               CALL EALCBEA('FTRACZN ',2,3,N_TRACFACE(6),3,KERR)
               CALL EALCBEA('PRESZN ',2,1,N_PRESFACE(6),3,KERR)

      KERR = 0

CBW   READ TYPE OF BOUNDARY CONDITION FROM INPUT FILE, NODAL-BASED ARRAY
CBW             : 1 = NEUMANN B.C.             2 = DIRICHLET B.C.

      CALL EBDARY_BE('EBCXX[] ',N_TYPEBD(1),2,1,1,2,NDUM,KERR)
      CALL EBDARY_BE('EBCXY[] ',N_TYPEBD(1),2,1,2,2,NDUM,KERR)
      CALL EBDARY_BE('EBCXZ[] ',N_TYPEBD(1),2,1,3,2,NDUM,KERR)

      CALL EBDARY_BE('EBCXXN[] ',N_TYPEBD(2),2,2,1,2,NDUM,KERR)
      CALL EBDARY_BE('EBCXYN[] ',N_TYPEBD(2),2,2,2,2,NDUM,KERR)
      CALL EBDARY_BE('EBCXZN[] ',N_TYPEBD(2),2,2,3,2,NDUM,KERR)

      CALL EBDARY_BE('EBCYX[] ',N_TYPEBD(3),2,3,1,2,NDUM,KERR)
      CALL EBDARY_BE('EBCYY[] ',N_TYPEBD(3),2,3,2,2,NDUM,KERR)
      CALL EBDARY_BE('EBCYZ[] ',N_TYPEBD(3),2,3,3,2,NDUM,KERR)

      CALL EBDARY_BE('EBCYXN[] ',N_TYPEBD(4),2,4,1,2,NDUM,KERR)
      CALL EBDARY_BE('EBCYYN[] ',N_TYPEBD(4),2,4,2,2,NDUM,KERR)
      CALL EBDARY_BE('EBCYZN[] ',N_TYPEBD(4),2,4,3,2,NDUM,KERR)

      CALL EBDARY_BE('EBCZX[] ',N_TYPEBD(5),2,5,1,2,NDUM,KERR)
      CALL EBDARY_BE('EBCZY[] ',N_TYPEBD(5),2,5,2,2,NDUM,KERR)
      CALL EBDARY_BE('EBCZZ[] ',N_TYPEBD(5),2,5,3,2,NDUM,KERR)

      CALL EBDARY_BE('EBCZXN[] ',N_TYPEBD(6),2,6,1,2,NDUM,KERR)
      CALL EBDARY_BE('EBCZYN[] ',N_TYPEBD(6),2,6,2,2,NDUM,KERR)
      CALL EBDARY_BE('EBCZZN[] ',N_TYPEBD(6),2,6,3,2,NDUM,KERR)

C GET BOUNDARY TRACTION DATA

      CALL DEFAULT(EXTPRES)

C FACIAL TRACTION B.C. -------------------------------------------
C -X SIDE X,Y,Z DIRECTION TRACTION

      CALL EBDARY_BE('FXXST[psi] ',N_TRACFACE(1),1,1,1,4,NDUM,KERR)
      CALL EBDARY_BE('FXYST[psi] ',N_TRACFACE(1),1,1,2,4,NDUM,KERR)
      CALL EBDARY_BE('FXZST[psi] ',N_TRACFACE(1),1,1,3,4,NDUM,KERR)

C +X SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('FXXSTN[psi] ',N_TRACFACE(2),1,2,1,4,NDUM,KERR)
      CALL EBDARY_BE('FXYSTN[psi] ',N_TRACFACE(2),1,2,2,4,NDUM,KERR)
      CALL EBDARY_BE('FXZSTN[psi] ',N_TRACFACE(2),1,2,3,4,NDUM,KERR)

C -Y SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('FYXST[psi] ',N_TRACFACE(3),1,3,1,4,NDUM,KERR)
      CALL EBDARY_BE('FYYST[psi] ',N_TRACFACE(3),1,3,2,4,NDUM,KERR)
      CALL EBDARY_BE('FYZST[psi] ',N_TRACFACE(3),1,3,3,4,NDUM,KERR)

C +Y SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('FYXSTN[psi] ',N_TRACFACE(4),1,4,1,4,NDUM,KERR)
      CALL EBDARY_BE('FYZSTN[psi] ',N_TRACFACE(4),1,4,3,4,NDUM,KERR)
      CALL EBDARY_BE('FYYSTN[psi] ',N_TRACFACE(4),1,4,2,4,NDUM,KERR)

C -Z SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('FZXST[psi] ',N_TRACFACE(5),1,5,1,4,NDUM,KERR)
      CALL EBDARY_BE('FZYST[psi] ',N_TRACFACE(5),1,5,2,4,NDUM,KERR)
      CALL EBDARY_BE('FZZST[psi] ',N_TRACFACE(5),1,5,3,4,NDUM,KERR)

C +Z SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('FZXSTN[psi] ',N_TRACFACE(6),1,6,1,4,NDUM,KERR)
      CALL EBDARY_BE('FZYSTN[psi] ',N_TRACFACE(6),1,6,2,4,NDUM,KERR)
      CALL EBDARY_BE('FZZSTN[psi] ',N_TRACFACE(6),1,6,3,4,NDUM,KERR)

C NODAL TRACTION B.C. -------------------------------------------
C -X SIDE X,Y,Z DIRECTION TRACTION

      CALL EBDARY_BE('XXST[psi] ',N_TRACBD(1),2,1,1,2,NDUM,KERR)
      CALL EBDARY_BE('XYST[psi] ',N_TRACBD(1),2,1,2,2,NDUM,KERR)
      CALL EBDARY_BE('XZST[psi] ',N_TRACBD(1),2,1,3,2,NDUM,KERR)

C +X SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('XXSTN[psi] ',N_TRACBD(2),2,2,1,2,NDUM,KERR)
      CALL EBDARY_BE('XYSTN[psi] ',N_TRACBD(2),2,2,2,2,NDUM,KERR)
      CALL EBDARY_BE('XZSTN[psi] ',N_TRACBD(2),2,2,3,2,NDUM,KERR)

C -Y SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('YXST[psi] ',N_TRACBD(3),2,3,1,2,NDUM,KERR)
      CALL EBDARY_BE('YYST[psi] ',N_TRACBD(3),2,3,2,2,NDUM,KERR)
      CALL EBDARY_BE('YZST[psi] ',N_TRACBD(3),2,3,3,2,NDUM,KERR)

C +Y SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('YXSTN[psi] ',N_TRACBD(4),2,4,1,2,NDUM,KERR)
      CALL EBDARY_BE('YZSTN[psi] ',N_TRACBD(4),2,4,3,2,NDUM,KERR)
      CALL EBDARY_BE('YYSTN[psi] ',N_TRACBD(4),2,4,2,2,NDUM,KERR)

C -Z SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('ZXST[psi] ',N_TRACBD(5),2,5,1,2,NDUM,KERR)
      CALL EBDARY_BE('ZYST[psi] ',N_TRACBD(5),2,5,2,2,NDUM,KERR)
      CALL EBDARY_BE('ZZST[psi] ',N_TRACBD(5),2,5,3,2,NDUM,KERR)

C +Z SIDE X,Y,Z DIRECTION TRACTION
      CALL EBDARY_BE('ZXSTN[psi] ',N_TRACBD(6),2,6,1,2,NDUM,KERR)
      CALL EBDARY_BE('ZYSTN[psi] ',N_TRACBD(6),2,6,2,2,NDUM,KERR)
      CALL EBDARY_BE('ZZSTN[psi] ',N_TRACBD(6),2,6,3,2,NDUM,KERR)

C FACIAL PRESSURE B.C. -------------------------------------------
C -X SIDE X,Y,Z DIRECTION PRESSURE
      CALL EBDARY_BE('PRESX[psi] ',N_PRESFACE(1),1,1,1,4,NDUM,KERR)

C +X SIDE X,Y,Z DIRECTION PRESSURE
      CALL EBDARY_BE('PRESXN[psi] ',N_PRESFACE(2),1,2,1,4,NDUM,KERR)

C -Y SIDE X,Y,Z DIRECTION PRESSURE
      CALL EBDARY_BE('PRESY[psi] ',N_PRESFACE(3),1,3,1,4,NDUM,KERR)

C +Y SIDE X,Y,Z DIRECTION PRESSURE
      CALL EBDARY_BE('PRESYN[psi] ',N_PRESFACE(4),1,4,1,4,NDUM,KERR)

C -Z SIDE X,Y,Z DIRECTION PRESSURE
      CALL EBDARY_BE('PRESZ[psi] ',N_PRESFACE(5),1,5,1,4,NDUM,KERR)

C +Z SIDE X,Y,Z DIRECTION PRESSURE
      CALL EBDARY_BE('PRESZN[psi] ',N_PRESFACE(6),1,6,1,4,NDUM,KERR)
C ----------------------------------------------------------------

cbw INPUT USER-SPECIFIED DISPLACEMENT BOUNDARY CONDITION

C -X SIDE IN X,Y,Z DIRECTION
      CALL EBDARY_BE('XXDI[in] ',N_DISPBD(1),2,1,1,2,NDUM,KERR)
      CALL EBDARY_BE('XYDI[in] ',N_DISPBD(1),2,1,2,2,NDUM,KERR)
      CALL EBDARY_BE('XZDI[in] ',N_DISPBD(1),2,1,3,2,NDUM,KERR)

C +X SIDE IN X,Y,Z DIRECTION
      CALL EBDARY_BE('XXDIN[in] ',N_DISPBD(2),2,2,1,2,NDUM,KERR)
      CALL EBDARY_BE('XYDIN[in] ',N_DISPBD(2),2,2,2,2,NDUM,KERR)
      CALL EBDARY_BE('XZDIN[in] ',N_DISPBD(2),2,2,3,2,NDUM,KERR)

C -Y SIDE IN X,Y,Z DIRECTION
      CALL EBDARY_BE('YXDI[in] ',N_DISPBD(3),2,3,1,2,NDUM,KERR)
      CALL EBDARY_BE('YYDI[in] ',N_DISPBD(3),2,3,2,2,NDUM,KERR)
      CALL EBDARY_BE('YZDI[in] ',N_DISPBD(3),2,3,3,2,NDUM,KERR)

C +Y SIDE IN X,Y,Z DIRECTION
      CALL EBDARY_BE('YXDIN[in] ',N_DISPBD(4),2,4,1,2,NDUM,KERR)
      CALL EBDARY_BE('YYDIN[in] ',N_DISPBD(4),2,4,2,2,NDUM,KERR)
      CALL EBDARY_BE('YZDIN[in] ',N_DISPBD(4),2,4,3,2,NDUM,KERR)

C -Z SIDE IN X,Y,Z DIRECTION
      CALL EBDARY_BE('ZXDI[in] ',N_DISPBD(5),2,5,1,2,NDUM,KERR)
      CALL EBDARY_BE('ZYDI[in] ',N_DISPBD(5),2,5,2,2,NDUM,KERR)
      CALL EBDARY_BE('ZZDI[in] ',N_DISPBD(5),2,5,3,2,NDUM,KERR)

C +Z SIDE IN X,Y,Z DIRECTION
      CALL EBDARY_BE('ZXDIN[in] ',N_DISPBD(6),2,6,1,2,NDUM,KERR)
      CALL EBDARY_BE('ZYDIN[in] ',N_DISPBD(6),2,6,2,2,NDUM,KERR)
      CALL EBDARY_BE('ZZDIN[in] ',N_DISPBD(6),2,6,3,2,NDUM,KERR)

      NERR=NERR+KERR

cbw-mb
C SET ELASTIC DEFAULT BOUNDARY CONDITIONS AND PRINT
      NDIM_ELASTIC=3
      DO K=1,NUMBLK
         DO I = 1,2*NDIM_ELASTIC
            IF (IBD_FACE(I,K)) THEN
               DO J = 1,NDIM_ELASTIC
                  IF(ITYPE_BOUNDARY(I,J,K).EQ.0) THEN
                      ITYPE_BOUNDARY(I,J,K)= 4
                  ENDIF
               ENDDO
            ENDIF
         ENDDO
      ENDDO
      JSIDE(1) = '-X'
      JSIDE(2) = '+X'
      JSIDE(3) = '-Y'
      JSIDE(4) = '+Y'
      JSIDE(5) = '-Z'
      JSIDE(6) = '+Z'

cbw
c below part is cut from the part originally below the line
c "14 FORMAT (2X ..."
c the purpose is to output boundary conditions correctly

      CALL TIMON(38)
      IF(NUMPRC.GT.1) THEN
         NDIM=NDIM_ELASTIC
         DO K=1,NUMBLK
            DO J=1,NDIM
               DO I=1,2*NDIM
                  DUM(I,J,K)=ITYPE_BOUNDARY(I,J,K)
               ENDDO
            ENDDO
         ENDDO
         CALL MAXIT(3*6*10,DUM)
         NDIM=NDIM_ELASTIC
         DO K=1,NUMBLK
            DO J=1,NDIM
               DO I=1,2*NDIM
                  ITYPE_BOUNDARY(I,J,K)=DUM(I,J,K)+.1D0
               ENDDO
            ENDDO
         ENDDO
         CALL SPREAD(3*6*10,ITYPE_BOUNDARY)
         CALL TIMOFF(38)
      ENDIF

      DO I = 1, 2*NDIM_ELASTIC
         DO J = 1,NDIM_ELASTIC
            DO K = 1,NUMBLK
! ITYPE_BOUNDARY == -3, default zero traction B.C.
               IF (ITYPE_BOUNDARY(I,J,K).EQ.-3) THEN
                  ITYPE_BOUNDARY(I,J,K) = 3
               ENDIF
! ITYPE_BOUNDARY == -2, default zero displacement B.C.
               IF (ITYPE_BOUNDARY(I,J,K).EQ.-2) THEN
                  ITYPE_BOUNDARY(I,J,K) = 1
               ENDIF
! ITYPE_BOUNDARY == -1, user specified traction B.C.
               IF (ITYPE_BOUNDARY(I,J,K).EQ.-1) THEN
                  ITYPE_BOUNDARY(I,J,K) = 4
               ENDIF
            ENDDO
            IBDYTYPE = 0
            DO K = 1,NUMBLK
               IF (ITYPE_BOUNDARY(I,J,K).EQ.2) THEN
                  IBDYTYPE = ITYPE_BOUNDARY(I,J,K)
                  EXIT
               ENDIF
            ENDDO
            IF (IBDYTYPE.GT.0) THEN
               DO K = 1,NUMBLK
                  ITYPE_BOUNDARY(I,J,K) = IBDYTYPE
               ENDDO
            ENDIF
            IF (IBDYTYPE.EQ.0) THEN
               DO K = 1,NUMBLK
                  IF (ITYPE_BOUNDARY(I,J,K).EQ.4) THEN
                     IBDYTYPE = ITYPE_BOUNDARY(I,J,K)
                     EXIT
                  ENDIF
               ENDDO
               IF (IBDYTYPE.GT.0) THEN
                  DO K = 1,NUMBLK
                     ITYPE_BOUNDARY(I,J,K) = IBDYTYPE
                  ENDDO
               ENDIF
            ENDIF
         ENDDO
      ENDDO
cbw-mb

      IF(LEVELC) THEN
         WRITE(NFOUT,*)
         TITL = '*******'
         CALL PRTTIT(TITL)
         TITL = 'ELASTIC BOUNDARY CONDITIONS'
         CALL PRTTIT(TITL)
         WRITE(NFOUT,13)
      ENDIF
         DO K=1,NUMBLK
            DO I = 1,2*NDIM_ELASTIC
                  DO J = 1,NDIM_ELASTIC
                     IF (ITYPE_BOUNDARY(I,J,K).LE.2) THEN
                        IF (ITYPE_BOUNDARY(I,J,K).EQ.1) THEN
                           JTYPE(J) = 'ZERO_DISP'
                        ELSEIF(ITYPE_BOUNDARY(I,J,K).EQ.2) THEN
                           JTYPE(J) = 'DISP/MIXED'
                        ENDIF
                     ELSE
                        IF (ITYPE_BOUNDARY(I,J,K).EQ.3) THEN
                           JTYPE(J) = 'ZERO_TRAC'
                        ELSEIF (ITYPE_BOUNDARY(I,J,K).EQ.4) THEN
                           JTYPE(J) = 'TRACTION'
                        ENDIF
                     ENDIF
                  ENDDO
               IF (LEVELC) THEN
                  WRITE(NFOUT,14) K,JSIDE(I),(JTYPE(J),J=1,NDIM_ELASTIC)
               ENDIF
            ENDDO
         ENDDO
  13  FORMAT(/2X,'NBLK   SIDE     DIRECTION X
     &     DIRECTION Y      DIRECTION Z')
  14  FORMAT(2X,I3,5X,A4,4X,A,4X,A,4X,A)

      END

C***********************************************************************
      SUBROUTINE EBDARY_BE(VNAM,N_ARY,KARY,NFACE,NDIR,NTYP,
     &           NUMRET,NERR)
C***********************************************************************
C Poroelastic model boundary element input
C
C VNAM = CHARACTER STRING TO BE READ IN THE INPUT FILE
C        (INPUT, CHARACTER*60)
C
C N_ARY = BOUNDARY ELEMENT ARRAY NUMBER (INPUT,INTEGER)
C
C KARY = ARRAY KEY (INPUT,INTEGER)
C      = 1 ==> BLOCK CENTER ARRAY
C      = 2 ==> BLOCK CORNER ARRAY
C
C NFACE = BOUNDARY FACE NUMBER TO BE READ (INPUT,INTEGER)
C       = 1 ==> -X SIDE
C       = 2 ==> +X SIDE
C       = 3 ==> -Y SIDE
C       = 4 ==> +Y SIDE
C       = 5 ==> -Z SIDE
C       = 6 ==> +Z SIDE
C
C NDIR = DIRECTION NUMBER ON A BOUNDARY FACE (INPUT,INTEGER)
C       = 1 ==> X DIRECTION
C       = 2 ==> Y DIRECTION
C       = 3 ==> Z DIRECTION
C
C NTYP = BOUNDARY CONDITION TYPE
C       = 1 ==> ZERO DISPLACEMENT
C       = 3 ==> ZERO TRACTION
C       = 4 ==> TRACTION
C
C NUMRET = NUMBER OF VALUES READ TO THE ARRAY (OUTPUT, INTEGER)
C
C NERR = ERROR NUMBER STEPPED BY 1 FOR EACH DATA ERROR INCOUNTERED
C        (INPUT AND OUTPUT, INTEGER)
C **********************************************************************

      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'readdat.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'emodel.h'

      INTEGER MAXCHR,NDIM4
      PARAMETER (MAXCHR=100000000)
      CHARACTER*1 VNAM(*)
      INTEGER N_ARY,KARY,NFACE,NDIR,NTYP,NUMRET,NERR
      INTEGER PEMOD

      INTEGER  I,J,KA(2),NMOD,DIM4,KERR
      EXTERNAL EBDARY_BEWR8,EBDARY_BEWI4

      IF(N_ARY.EQ.0) RETURN
      CALL ARYTYPE(N_ARY,NTYPGA,NDIM4,PEMOD,KERR)
      IF(KERR.GT.0) THEN
         NERR=NERR+1
         RETURN
      ENDIF
      J=0
      DO I=1,60
         VNAMGA(I)=VNAM(I)
         IF (VNAMGA(I).EQ.']'.OR.(VNAMGA(I).EQ.' '.AND.J.EQ.0)) GO TO 2
         IF (VNAMGA(I).EQ.'[') J=1
      ENDDO

   2  NUMRGA=0
      KERRGA=0
      KNDARY=KARY
      IFACE=NFACE

      IBD_DIR=NDIR
      IBD_TYPE=NTYP

      KA(1)=1
      KA(2)=N_ARY
      CALL ALLBLOCKS()
!bw      IF (NTYPGA.NE.2) THEN
      IF (NTYPGA.NE.2 .AND. NTYPGA.NE.4) THEN
         NERR=NERR+1
         IF (LEVELC) WRITE(NFOUT,3)
         RETURN
      ELSEIF(NTYPGA.EQ.2) THEN
         CALL CALLWORK(EBDARY_BEWR8,KA)
      ELSEIF(NTYPGA.EQ.4) THEN
         CALL CALLWORK(EBDARY_BEWI4,KA)
      ENDIF
      NUMRET=NUMRGA
      NERR=NERR+KERRGA

   3  FORMAT('/ERR(PE100): ONLY REAL*8 TYPE OF BOUNDARY DATA ALLOWED')
      END

C**********************************************************************
      SUBROUTINE ESETVNAM(VNAM,VNAMC,NB)
C**********************************************************************
C PUT VARIABLE NAME AND BLOCK NUMBER TOGETER
C
C VNAM = VARIABLE NAME (INPUT, CHARACTER*)
C
C VNAMC = NEW VARIABLE NAME (OUTPUT, CHARACTER*)
C
C NB = FAULT BLOCK NUMBER (INPUT,INTEGER)
C**********************************************************************
      CHARACTER*1 VNAM(*),VNAMC(*)
      INTEGER NB

      INTEGER I,J
      CHARACTER*1 DIGITS(10)
      DATA DIGITS/'0','1','2','3','4','5','6','7','8','9'/
      PARAMETER (NVN=60+4)

      DO I=1,60
         L=I
         IF (VNAM(I).EQ.'['.OR.VNAM(I).EQ.' ') GO TO 2
         VNAMC(L)=VNAM(I)
      ENDDO
   2  J=L
      IF (NB.GT.99) THEN
         VNAMC(L)=DIGITS(1+NB/100)
         L=L+1
      ENDIF
      IF (NB.GT.9) THEN
         VNAMC(L)=DIGITS(1+MOD(NB,100)/10)
         L=L+1
      ENDIF
      VNAMC(L)=DIGITS(1+MOD(NB,10))
      L=L+1

      IF (VNAM(J).EQ.'[') THEN
         DO I=J,60
            VNAMC(L)=VNAM(I)
            L=L+1
            IF (VNAM(I).EQ.']') GO TO 4
         ENDDO
      ELSE
         IF (L.LE.NVN) VNAMC(L)=' '
      ENDIF
   4  CONTINUE
      END
C**********************************************************************
      SUBROUTINE EBDARY_BEWR8(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &           KL1,KL2,KEYOUT,NBLKA,BD_VAL)
C**********************************************************************
C Poroelastic model boundary element input
C
C OUTPUT:
C   BD_VAL(J) = TRACTION VALUES ON A BOUNDARY FACE
C**********************************************************************

      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER NVN,NERR,IDIMG,JDIMG,KDIMG,N
      PARAMETER (NVN=60+4)
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLKA
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BD_VAL(*)

      INTEGER I,J,L,KERR,ILOC
      CHARACTER*1 VNAMC(NVN)
      CHARACTER*2 VTYP(6)
      DATA VTYP/'R4','R8','I2','I4','L2','L4'/

      IF (IFACE.LE.0.OR.IFACE.GT.6) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF (IBD_DIR.LE.0.OR.IBD_DIR.GT.3) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
!bw      IF (.NOT.IBD_FACE(IFACE,NBLKA)) RETURN

C BUILD VARIABLE NAME FOR A SPECIFIC GRID BLOCK

      CALL ESETVNAM(VNAMGA,VNAMC,NBLKA)

C GET GRID BLOCK GLOBAL DIMENSIONS

   4  CALL BLKDIM(NBLKA,IDIMG,JDIMG,KDIMG,KERR)
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF

      IF (KNDARY.EQ.2) THEN
         IDIMG=IDIMG+1
         JDIMG=JDIMG+1
         KDIMG=KDIMG+1
      ENDIF

C PUT LOCAL-GLOBAL OFFSETS AND LOCAL DIMENSIONS IN /READAT/

      CALL BLKOFF(NBLKA,IGLT,JGLT,KGLT,NERR)
      IDIML=IDIM
      JDIML=JDIM
      KDIML=KDIM
      IF (IFACE.EQ.1.OR.IFACE.EQ.2) THEN
         IDIMG=1
         IDIML=1
         ILOC=(IBD_DIR-1)*JDIM*KDIM+1
      ELSE IF(IFACE.EQ.3.OR.IFACE.EQ.4) THEN
         JDIMG=1
         JDIML=1
         ILOC=(IBD_DIR-1)*IDIM*KDIM+1
      ELSE
         KDIMG=1
         KDIML=1
         ILOC=(IBD_DIR-1)*IDIM*JDIM+1
      ENDIF

C GET DATA FOR THE BOUNDARY ELEMENTS

      KERR=0
      NBLKG=NBLKA
      CALL EGETVAL (VNAMC,BD_VAL(ILOC),VTYP(NTYPGA),IDIMG,JDIMG,KDIMG,
     &     0,N,KERR)

      NUMRGA=NUMRGA+N
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF(N.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE
!bw      IF(NUMRGA.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE
      NBLKG=0

      END

C**********************************************************************
      SUBROUTINE EBDARY_BEWI4(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &           KL1,KL2,KEYOUT,NBLKA,BD_VAL)
C**********************************************************************
C Poroelastic model boundary element input
C
C OUTPUT:
C   BD_VAL(J) = TRACTION VALUES ON A BOUNDARY FACE
C**********************************************************************

      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER NVN,NERR,IDIMG,JDIMG,KDIMG,N
      PARAMETER (NVN=60+4)
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLKA
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER BD_VAL(*)

      INTEGER I,J,L,KERR,ILOC
      CHARACTER*1 VNAMC(NVN)
      CHARACTER*2 VTYP(6)
      DATA VTYP/'R4','R8','I2','I4','L2','L4'/

      IF (IFACE.LE.0.OR.IFACE.GT.6) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF (IBD_DIR.LE.0.OR.IBD_DIR.GT.3) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
!bw      IF (.NOT.IBD_FACE(IFACE,NBLKA)) RETURN

C BUILD VARIABLE NAME FOR A SPECIFIC GRID BLOCK

      CALL ESETVNAM(VNAMGA,VNAMC,NBLKA)

C GET GRID BLOCK GLOBAL DIMENSIONS

   4  CALL BLKDIM(NBLKA,IDIMG,JDIMG,KDIMG,KERR)
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF

      IF (KNDARY.EQ.2) THEN
         IDIMG=IDIMG+1
         JDIMG=JDIMG+1
         KDIMG=KDIMG+1
      ENDIF

C PUT LOCAL-GLOBAL OFFSETS AND LOCAL DIMENSIONS IN /READAT/

      CALL BLKOFF(NBLKA,IGLT,JGLT,KGLT,NERR)
      IDIML=IDIM
      JDIML=JDIM
      KDIML=KDIM
      IF (IFACE.EQ.1.OR.IFACE.EQ.2) THEN
         IDIMG=1
         IDIML=1
         ILOC=(IBD_DIR-1)*JDIM*KDIM+1
      ELSE IF(IFACE.EQ.3.OR.IFACE.EQ.4) THEN
         JDIMG=1
         JDIML=1
         ILOC=(IBD_DIR-1)*IDIM*KDIM+1
      ELSE
         KDIMG=1
         KDIML=1
         ILOC=(IBD_DIR-1)*IDIM*JDIM+1
      ENDIF

C GET DATA FOR THE BOUNDARY ELEMENTS

      KERR=0
      NBLKG=NBLKA
      CALL EGETVAL (VNAMC,BD_VAL(ILOC),VTYP(NTYPGA),IDIMG,JDIMG,KDIMG,
     &     0,N,KERR)

      NUMRGA=NUMRGA+N
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF(N.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE
!bw      IF(NUMRGA.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE
      NBLKG=0

      END

C**********************************************************************
      SUBROUTINE EBDARY_FACES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &           KL1,KL2,KEYOUT,NBLK)
C**********************************************************************
C Determine whether a processor owns a boundary face or not
C
C OUTPUT:
C   IBD_FACE(NDIR,NBLK) = INDICATOR OF A EXISTING BOUNDARY FACE
C                       = .TRUE.  INDICATES A BOUNDARY
C                       = .FALSE. NO BOUNDARY IN THE CURRENT PROCESSOR
C**********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER IDIMG,JDIMG,KDIMG,IOFF,JOFF,KOFF,NERR,I,J,K,J1,J2

      CALL BLKDIM(NBLK,IDIMG,JDIMG,KDIMG,NERR)
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

C X- SIDE

      DO K=KL1-1,KL2+1
         DO J=1,JDIM
            DO I=IL1,IL2
               IF (KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                  IBD_FACE(1,NBLK)=.TRUE.
                  GO TO 1
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   1  CONTINUE

C X+ SIDE

      DO K=KL1-1,KL2+1
         DO J=1,JDIM
            DO I=IL2,IL1,-1
               IF (KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                  IBD_FACE(2,NBLK)=.TRUE.
                  GO TO 2
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   2  CONTINUE

C Y- SIDE
      DO K=KL1-1,KL2+1
         DO I=IL1,IL2
            DO J=2,JDIM
               IF (KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                  IBD_FACE(3,NBLK)=.TRUE.
                  GO TO 3
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   3  CONTINUE

C Y+ SIDE

      DO K=KL1-1,KL2+1
         DO I=IL1,IL2
            DO J=JDIM-1,1,-1
               IF (KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                  IBD_FACE(4,NBLK)=.TRUE.
                  GO TO 4
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   4  CONTINUE

C Z- SIDE

      DO J=1,JDIM
         DO I=IL1,IL2
            DO K=KL1,KL2
               IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                  IBD_FACE(5,NBLK)=.TRUE.
                  GO TO 5
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   5  CONTINUE

C Z+ SIDE

      DO J=1,JDIM
         DO I=IL1,IL2
            DO K=KL2,KL1,-1
               IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K+1).EQ.0) THEN
               IBD_FACE(6,NBLK)=.TRUE.
               GO TO 6
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   6  CONTINUE

      BDARYIJK(1,1,NBLK)=IL1+IOFF
      BDARYIJK(2,1,NBLK)=IL2+IOFF
      BDARYIJK(1,3,NBLK)=KL1+KOFF
      BDARYIJK(2,3,NBLK)=KL2+KOFF
      J1=JDIM
      J2=1
      DO K=KL1,KL2
         IF(JL1V(K).LT.J1) J1=JL1V(K)
         IF(JL2V(K).GT.J2) J2=JL2V(K)
      ENDDO
      BDARYIJK(1,2,NBLK)=J1+JOFF
      BDARYIJK(2,2,NBLK)=J2+JOFF
      END


C**********************************************************************
      SUBROUTINE EDISP_FACES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &           KL1,KL2,KEYOUT,NBLK)
C**********************************************************************
C Determine whether a processor owns a boundary face
C (includes ghost layer)
C
C OUTPUT:
C   DP_FACE(NDIR,NBLK) = INDICATOR OF A EXISTING BOUNDARY FACE
C                       = .TRUE.  INDICATES A BOUNDARY (INCLUDES GHOST
C                                 LAYERS)
C                       = .FALSE. NO BOUNDARY IN THE CURRENT PROCESSOR
C**********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER IDIMG,JDIMG,KDIMG,IOFF,JOFF,KOFF,NERR,I,J,K,J1,J2

C X- SIDE

      DO K=KL1-1,KL2+1
         DO J=1,JDIM
            DO I=IL1,IL2
               IF (KEYOUT(I,J,K).NE.0.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                  DP_FACE(1,NBLK)=.TRUE.
                  GO TO 1
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   1  CONTINUE

C X+ SIDE

      DO K=KL1-1,KL2+1
         DO J=1,JDIM
            DO I=IL2,IL1,-1
               IF (KEYOUT(I,J,K).NE.0.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                  DP_FACE(2,NBLK)=.TRUE.
                  GO TO 2
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   2  CONTINUE

C Y- SIDE
      DO K=KL1-1,KL2+1
         DO I=IL1,IL2
            DO J=2,JDIM
               IF (KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                  DP_FACE(3,NBLK)=.TRUE.
                  GO TO 3
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   3  CONTINUE

C Y+ SIDE

      DO K=KL1-1,KL2+1
         DO I=IL1,IL2
            DO J=JDIM-1,1,-1
               IF (KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                  DP_FACE(4,NBLK)=.TRUE.
                  GO TO 4
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   4  CONTINUE

C Z- SIDE

      DO J=1,JDIM
         DO I=IL1,IL2
            DO K=KL1-1,KL2+2
               IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                  DP_FACE(5,NBLK)=.TRUE.
                  GO TO 5
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   5  CONTINUE

C Z+ SIDE

      DO J=1,JDIM
         DO I=IL1,IL2
            DO K=KL2+1,KL1-2,-1
               IF(KEYOUT(I,J,K).NE.1.AND.KEYOUT(I,J,K+1).EQ.0) THEN
               DP_FACE(6,NBLK)=.TRUE.
               GO TO 6
               ENDIF
            ENDDO
         ENDDO
      ENDDO
   6  CONTINUE

      END

C**********************************************************************
      SUBROUTINE EBDARY_UPDATE(KERR)
C**********************************************************************
C Update boundary condtion values between processors
C**********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'earydat.h'
      INCLUDE 'blkary.h'
      INCLUDE 'ebdary.h'

      INTEGER KERR,IBD,JCOPY(6),NDIM4
      REAL*8  ZERO
      EXTERNAL EBDARY_BE_WRK,EBDARY_WRK_BE,
     &         ETYPEBD_BE_WRK,ETYPEBD_WRK_BE,
     &         EFACE_BE_WRK,EFACE_WRK_BE
      external EPRES_BE_WRK, EPRES_WRK_BE
!bw may not need WAITALL() here
!       CALL WAITALL()

      JCOPY(1)=3
      JCOPY(2)=N_EDISP
      JCOPY(4)=N_KEYOUT_CR
! Update N_TYPEBD arrays first
! -X Boundary
      IF(N_TYPEBD(1).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TYPEBD(1)
         IFACE=1
         CALL CALLWORK(ETYPEBD_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(1).GT.0) THEN
         CALL CALLWORK(ETYPEBD_WRK_BE,JCOPY)
      ENDIF

! +X Boundary
      IF(N_TYPEBD(2).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TYPEBD(2)
         IFACE=2
         CALL CALLWORK(ETYPEBD_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(2).GT.0) THEN
         CALL CALLWORK(ETYPEBD_WRK_BE,JCOPY)
      ENDIF

! -Y Boundary
      IF(N_TYPEBD(3).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TYPEBD(3)
         IFACE=3
         CALL CALLWORK(ETYPEBD_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(3).GT.0) THEN
         CALL CALLWORK(ETYPEBD_WRK_BE,JCOPY)
      ENDIF

! +Y Boundary
      IF(N_TYPEBD(4).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TYPEBD(4)
         IFACE=4
         CALL CALLWORK(ETYPEBD_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(4).GT.0) THEN
         CALL CALLWORK(ETYPEBD_WRK_BE,JCOPY)
      ENDIF

! -Z Boundary
      IF(N_TYPEBD(5).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TYPEBD(5)
         IFACE=5
         CALL CALLWORK(ETYPEBD_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(5).GT.0) THEN
         CALL CALLWORK(ETYPEBD_WRK_BE,JCOPY)
      ENDIF

! +Z Boundary
      IF(N_TYPEBD(6).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TYPEBD(6)
         IFACE=6
         CALL CALLWORK(ETYPEBD_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(6).GT.0) THEN
         CALL CALLWORK(ETYPEBD_WRK_BE,JCOPY)
      ENDIF

!      CALL ESETARYR8N(N_EDISP,3)

! BW  Update Nodal-Based Traction/Displacement B.C. among processors
      JCOPY(1)=5
      JCOPY(2)=N_EDISP
      JCOPY(6)=N_KEYOUT_CR

! -X SIDES OF BOUNDARY
      IF(N_TYPEBD(1).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACBD(1)
         JCOPY(4)=N_DISPBD(1)
         JCOPY(5)=N_TYPEBD(1)
         IFACE=1
         CALL CALLWORK(EBDARY_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(1).GT.0) THEN
         CALL CALLWORK(EBDARY_WRK_BE,JCOPY)
      ENDIF

! +X SIDES OF BOUNDARY
      IF(N_TYPEBD(2).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACBD(2)
         JCOPY(4)=N_DISPBD(2)
         JCOPY(5)=N_TYPEBD(2)
         IFACE=2
         CALL CALLWORK(EBDARY_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(2).GT.0) THEN
         CALL CALLWORK(EBDARY_WRK_BE,JCOPY)
      ENDIF

! -Y SIDES OF BOUMDARY
      IF(N_TYPEBD(3).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACBD(3)
         JCOPY(4)=N_DISPBD(3)
         JCOPY(5)=N_TYPEBD(3)
         IFACE=3
         CALL CALLWORK(EBDARY_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(3).GT.0) THEN
         CALL CALLWORK(EBDARY_WRK_BE,JCOPY)
      ENDIF

! +Y SIDES OF BOUMDARY
      IF(N_TYPEBD(4).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACBD(4)
         JCOPY(4)=N_DISPBD(4)
         JCOPY(5)=N_TYPEBD(4)
         IFACE=4
         CALL CALLWORK(EBDARY_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(4).GT.0) THEN
         CALL CALLWORK(EBDARY_WRK_BE,JCOPY)
      ENDIF

! -Z SIDES OF BOUNDARY
      IF(N_TYPEBD(5).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACBD(5)
         JCOPY(4)=N_DISPBD(5)
         JCOPY(5)=N_TYPEBD(5)
         IFACE=5
         CALL CALLWORK(EBDARY_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(5).GT.0) THEN
         CALL CALLWORK(EBDARY_WRK_BE,JCOPY)
      ENDIF

! +Z SIDES OF BOUNDARY
      IF(N_TYPEBD(6).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACBD(6)
         JCOPY(4)=N_DISPBD(6)
         JCOPY(5)=N_TYPEBD(6)
         IFACE=6
         CALL CALLWORK(EBDARY_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,4)
       CALL TIMOFF(38)
      IF(N_TYPEBD(6).GT.0) THEN
         CALL CALLWORK(EBDARY_WRK_BE,JCOPY)
      ENDIF

!      CALL ESETARYR8N(N_EDISP,0.D0,24)

! BW  Update Face-Based Traction B.C. among processors
      JCOPY(1)=2
      JCOPY(2)=N_EDISP

! -X SIDES OF BOUNDARY
      IF(N_TRACFACE(1).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACFACE(1)
         IFACE=1
         CALL CALLWORK(EFACE_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_TRACFACE(1).GT.0) THEN
         CALL CALLWORK(EFACE_WRK_BE,JCOPY)
      ENDIF

! +X SIDES OF BOUNDARY
      IF(N_TRACFACE(2).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACFACE(2)
         IFACE=2
         CALL CALLWORK(EFACE_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_TRACFACE(2).GT.0) THEN
         CALL CALLWORK(EFACE_WRK_BE,JCOPY)
      ENDIF

! -Y SIDES OF BOUMDARY
      IF(N_TRACFACE(3).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACFACE(3)
         IFACE=3
         CALL CALLWORK(EFACE_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_TRACFACE(3).GT.0) THEN
         CALL CALLWORK(EFACE_WRK_BE,JCOPY)
      ENDIF

! +Y SIDES OF BOUMDARY
      IF(N_TRACFACE(4).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACFACE(4)
         IFACE=4
         CALL CALLWORK(EFACE_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_TRACFACE(4).GT.0) THEN
         CALL CALLWORK(EFACE_WRK_BE,JCOPY)
      ENDIF

! -Z SIDES OF BOUNDARY
      IF(N_TRACFACE(5).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACFACE(5)
         IFACE=5
         CALL CALLWORK(EFACE_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_TRACFACE(5).GT.0) THEN
         CALL CALLWORK(EFACE_WRK_BE,JCOPY)
      ENDIF

! +Z SIDES OF BOUNDARY
      IF(N_TRACFACE(6).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_TRACFACE(6)
         IFACE=6
         CALL CALLWORK(EFACE_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_TRACFACE(6).GT.0) THEN
         CALL CALLWORK(EFACE_WRK_BE,JCOPY)
      ENDIF

      CALL ESETARYR8N(N_EDISP,0.D0,3)

! BW  Update Face Pressure B.C. among processors
      JCOPY(1)=2
      JCOPY(2)=N_EDISP
! -X SIDES OF BOUNDARY
      IF(N_PRESFACE(1).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_PRESFACE(1)
         IFACE=1
         CALL CALLWORK(EPRES_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_PRESFACE(1).GT.0) THEN
         CALL CALLWORK(EPRES_WRK_BE,JCOPY)
      ENDIF
! +X SIDES OF BOUNDARY
      IF(N_PRESFACE(2).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_PRESFACE(2)
         IFACE=2
         CALL CALLWORK(EPRES_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_PRESFACE(2).GT.0) THEN
         CALL CALLWORK(EPRES_WRK_BE,JCOPY)
      ENDIF

! -Y SIDES OF BOUMDARY
      IF(N_PRESFACE(3).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_PRESFACE(3)
         IFACE=3
         CALL CALLWORK(EPRES_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_PRESFACE(3).GT.0) THEN
         CALL CALLWORK(EPRES_WRK_BE,JCOPY)
      ENDIF

! +Y SIDES OF BOUMDARY
      IF(N_PRESFACE(4).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_PRESFACE(4)
         IFACE=4
         CALL CALLWORK(EPRES_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_PRESFACE(4).GT.0) THEN
         CALL CALLWORK(EPRES_WRK_BE,JCOPY)
      ENDIF

! -Z SIDES OF BOUNDARY
      IF(N_PRESFACE(5).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_PRESFACE(5)
         IFACE=5
         CALL CALLWORK(EPRES_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_PRESFACE(5).GT.0) THEN
         CALL CALLWORK(EPRES_WRK_BE,JCOPY)
      ENDIF

! +Z SIDES OF BOUNDARY
      IF(N_PRESFACE(6).GT.0) THEN
         CALL ESETARYR8N(N_EDISP,0.D0,3)
         JCOPY(3)=N_PRESFACE(6)
         IFACE=6
         CALL CALLWORK(EPRES_BE_WRK,JCOPY)
      ENDIF
       CALL TIMON(38)
       CALL UPDATE(N_EDISP,2)
       CALL TIMOFF(38)
      IF(N_PRESFACE(6).GT.0) THEN
         CALL CALLWORK(EPRES_WRK_BE,JCOPY)
      ENDIF

      CALL ESETARYR8N(N_EDISP,0.D0,3)

      END

C**********************************************************************
      SUBROUTINE EBDARY_BE_WRK(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL1,
     &                    BD_VAL2,TYPEBD,KEY_CR)
C**********************************************************************
C Copy values from a 2D boundary element array to 3D grid element array
C before update
C
C INPUT:
C   BD_VAL1(*) = 2D GRID ELEMENT ARRAY, NODAL STRESS
C   BD_VAL2(*) = 2D GRID ELEMENT ARRAY, NODAL DISPLACEMENT
C
C OUTPUT:
C  BDARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'layout.h'
      INCLUDE 'ebdary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEY_CR(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3),BD_VAL1(*),
     &        BD_VAL2(*)
      INTEGER TYPEBD(*)
      integer arrsize

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NODE,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(1,L,NBLK).EQ.4) THEN
           DO K = KL1,KL2+1
              DO J = 2,JDIM-1
                 DO I = IL1,IL2+1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I-1,J,K).EQ.0) THEN
                       IF(TYPEBD(LOFF+(K-1)*JDIM+J).EQ.1) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL1(LOFF+(K-1)*JDIM+J)
                       ELSEIF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.2) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL2(LOFF+(K-1)*JDIM+J)
                       ENDIF
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(2,L,NBLK).EQ.4) THEN
           DO K = KL1,KL2+1
              DO J=2,JDIM-1
                 DO I=IL2+1,IL1,-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I+1,J,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.1) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL1(LOFF+(K-1)*JDIM+J)
                      ELSEIF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.2) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL2(LOFF+(K-1)*JDIM+J)
                      ENDIF
                      GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(3,L,NBLK).EQ.4) THEN
           DO K=KL1,KL2+1
              DO I=IL1,IL2+1
                 DO J=2,JDIM-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J-1,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.1) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL1(LOFF+(K-1)*IDIM+I)
                      ELSEIF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.2) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL2(LOFF+(K-1)*IDIM+I)
                      ENDIF
                      GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(4,L,NBLK).EQ.4) THEN
           DO K=KL1,KL2+1
              DO I=IL1,IL2+1
                 DO J=JDIM-1,2,-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J+1,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.1) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL1(LOFF+(K-1)*IDIM+I)
                      ELSEIF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.2) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL2(LOFF+(K-1)*IDIM+I)
                      ENDIF
                      GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(5,L,NBLK).EQ.4) THEN
           DO J=2,JDIM-1
              DO I=IL1,IL2+1
                 DO K=KL1,KL2+1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J,K-1).EQ.0) THEN
                      IF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.1) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL1(LOFF+(J-1)*IDIM+I)
                      ELSEIF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.2) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL2(LOFF+(J-1)*IDIM+I)
                      ENDIF
                      GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(6,L,NBLK).EQ.4) THEN
           DO J=2,JDIM-1
              DO I=IL1,IL2+1
                 DO K=KL2+1,KL1,-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J,K+1).EQ.0) THEN
                      IF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.1) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL1(LOFF+(J-1)*IDIM+I)
                      ELSEIF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.2) THEN
                          BDARY_WRK(I,J,K,L)=BD_VAL2(LOFF+(J-1)*IDIM+I)
                      ENDIF
                      GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO

  20  CONTINUE

      END
C**********************************************************************
      SUBROUTINE EBDARY_WRK_BE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL1,
     &                    BD_VAL2,TYPEBD,KEY_CR)
C**********************************************************************
C Copy values from a 3D grid element array to 2D boundary element array
C after update
C
C INPUT:
C  BDARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C
C OUTPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEY_CR(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3),BD_VAL1(*),
     &        BD_VAL2(*)
      INTEGER TYPEBD(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NODE,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(1,L,NBLK).EQ.4) THEN
           DO K = 1,KDIM
              DO J = 1,JDIM
                 DO I = IL1,IL2+1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I-1,J,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.1) THEN
                          BD_VAL1(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)
                      ELSEIF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.2) THEN
                          BD_VAL2(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)
                      ENDIF
                      GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(2,L,NBLK).EQ.4) THEN
           DO K = 1,KDIM
              DO J=1,JDIM
                 DO I=IL2+1,IL1,-1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I+1,J,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.1) THEN
                          BD_VAL1(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)
                      ELSEIF (TYPEBD(LOFF+(K-1)*JDIM+J).EQ.2) THEN
                          BD_VAL2(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)
                      ENDIF
                      GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(3,L,NBLK).EQ.4) THEN
           DO K=1,KDIM
              DO I=IL1,IL2+1
                 DO J=2,JDIM
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J-1,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.1) THEN
                          BD_VAL1(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ELSEIF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.2) THEN
                          BD_VAL2(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ENDIF
                      GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(4,L,NBLK).EQ.4) THEN
           DO K=1,KDIM
              DO I=IL1,IL2+1
                 DO J=JDIM-1,1,-1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J+1,K).EQ.0) THEN
                      IF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.1) THEN
                          BD_VAL1(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ELSEIF (TYPEBD(LOFF+(K-1)*IDIM+I).EQ.2) THEN
                          BD_VAL2(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ENDIF
                      GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(5,L,NBLK).EQ.4) THEN
           DO J=1,JDIM
              DO I=IL1,IL2+1
                 DO K=2,KDIM
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J,K-1).EQ.0) THEN
                      IF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.1) THEN
                          BD_VAL1(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ELSEIF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.2) THEN
                          BD_VAL2(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ENDIF
                      GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(6,L,NBLK).EQ.4) THEN
           DO J=1,JDIM
              DO I=IL1,IL2+1
                 DO K=KDIM-1,1,-1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J,K+1).EQ.0) THEN
                      IF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.1) THEN
                          BD_VAL1(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ELSEIF (TYPEBD(LOFF+(J-1)*IDIM+I).EQ.2) THEN
                          BD_VAL2(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                      ENDIF
                      GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
  20  CONTINUE

      END

C**********************************************************************
      SUBROUTINE EDISP_BE_WRK(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL,TYPEBD)
C**********************************************************************
C Copy values from a 2D boundary element array to 3D grid element array
C before update
C
C INPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C
C OUTPUT:
C   DARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'layout.h'
      INCLUDE 'ebdary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3,8),BD_VAL(*)
      INTEGER TYPEBD(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NODE,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP=4*JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.2) THEN
           DO K = KL1,KL2
              DO J = JL1V(K),JL2V(K)
                 DO I = IL1,IL2
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*JDIM*KDIM+
     &                        (K-1)*JDIM+J).EQ.2) THEN
                              BDARY_WRK(I,J,K,L,NODE)=BD_VAL(LOFF+
     &                        (NODE-1)*JDIM*KDIM+(K-1)*JDIM+J)
                          ENDIF
                       ENDDO
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = 4*JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.2) THEN
           DO K = KL1,KL2
              DO J=JL1V(K),JL2V(K)
                 DO I=IL2,IL1,-1
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*JDIM*KDIM+
     &                        (K-1)*JDIM+J).EQ.2) THEN
                              BDARY_WRK(I,J,K,L,NODE)=BD_VAL(LOFF+
     &                        (NODE-1)*JDIM*KDIM+(K-1)*JDIM+J)
                          ENDIF
                       ENDDO
                       GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = 4*IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.2) THEN
           DO K=KL1,KL2
              JL1=JL1V(K)
              JL2=JL2V(K)
              DO I=IL1,IL2
                 DO J=JL1,JL2
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*KDIM+
     &                        (K-1)*IDIM+I).EQ.2) THEN
                              BDARY_WRK(I,J,K,L,NODE)=BD_VAL(LOFF+
     &                        (NODE-1)*IDIM*KDIM+(K-1)*IDIM+I)
                          ENDIF
                       ENDDO
                       GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = 4*IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.2) THEN
           DO K=KL1,KL2
              JL1=JL1V(K)
              JL2=JL2V(K)
              DO I=IL1,IL2
                 DO J=JL2,JL1,-1
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*KDIM+
     &                        (K-1)*IDIM+I).EQ.2) THEN
                              BDARY_WRK(I,J,K,L,NODE)=BD_VAL(LOFF+
     &                        (NODE-1)*IDIM*KDIM+(K-1)*IDIM+I)
                          ENDIF
                       ENDDO
                       GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = 4*IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.2) THEN
           DO J=1+JLAY,JDIM-JLAY
              DO I=IL1,IL2
                 DO K=KL1,KL2
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*JDIM+
     &                        (J-1)*IDIM+I).EQ.2) THEN
                              BDARY_WRK(I,J,K,L,NODE)=BD_VAL(LOFF+
     &                        (NODE-1)*IDIM*JDIM+(J-1)*IDIM+I)
                          ENDIF
                       ENDDO
                       GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = 4*IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.2) THEN
           DO J=1+JLAY,JDIM-JLAY
              DO I=IL1,IL2
                 DO K=KL2,KL1,-1
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K+1).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*JDIM+
     &                        (J-1)*IDIM+I).EQ.2) THEN
                              BDARY_WRK(I,J,K,L,NODE)=BD_VAL(LOFF+
     &                        (NODE-1)*IDIM*JDIM+(J-1)*IDIM+I)
                          ENDIF
                       ENDDO
                       GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO

  20  CONTINUE

      END
C**********************************************************************
      SUBROUTINE EDISP_WRK_BE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL,TYPEBD)
C**********************************************************************
C Copy values from a 3D grid element array to 2D boundary element array
C after update
C
C INPUT:
C   DARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C
C OUTPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3,8),BD_VAL(*)
      INTEGER TYPEBD(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NODE,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = 4*JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.2) THEN
           DO K = 1,KDIM
              DO J = 1,JDIM
                 DO I = IL1,IL2
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*JDIM*KDIM+
     &                        (K-1)*JDIM+J).EQ.2) THEN
                              BD_VAL(LOFF+(NODE-1)*JDIM*KDIM+
     &                        (K-1)*JDIM+J)=BDARY_WRK(I,J,K,L,NODE)
                          ENDIF
                       ENDDO
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = 4*JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.2) THEN
           DO K = 1,KDIM
              DO J=1,JDIM
                 DO I=IL2,IL1,-1
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*JDIM*KDIM+
     &                        (K-1)*JDIM+J).EQ.2) THEN
                              BD_VAL(LOFF+(NODE-1)*JDIM*KDIM+
     &                        (K-1)*JDIM+J)=BDARY_WRK(I,J,K,L,NODE)
                          ENDIF
                       ENDDO
                       GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = 4*IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.2) THEN
           DO K=1,KDIM
              DO I=IL1,IL2
                 DO J=2,JDIM
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*KDIM+
     &                        (K-1)*IDIM+I).EQ.2) THEN
                              BD_VAL(LOFF+(NODE-1)*IDIM*KDIM+
     &                        (K-1)*IDIM+I)=BDARY_WRK(I,J,K,L,NODE)
                          ENDIF
                       ENDDO
                       GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = 4*IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.2) THEN
           DO K=1,KDIM
              DO I=IL1,IL2
                 DO J=JDIM-1,1,-1
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*KDIM+
     &                        (K-1)*IDIM+I).EQ.2) THEN
                              BD_VAL(LOFF+(NODE-1)*IDIM*KDIM+
     &                        (K-1)*IDIM+I)=BDARY_WRK(I,J,K,L,NODE)
                          ENDIF
                       ENDDO
                       GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = 4*IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.2) THEN
           DO J=1,JDIM
              DO I=IL1,IL2
                 DO K=2,KDIM
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*JDIM+
     &                        (J-1)*IDIM+I).EQ.2) THEN
                              BD_VAL(LOFF+(NODE-1)*IDIM*JDIM+
     &                        (J-1)*IDIM+I)=BDARY_WRK(I,J,K,L,NODE)
                          ENDIF
                       ENDDO
                       GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = 4*IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.2) THEN
           DO J=1,JDIM
              DO I=IL1,IL2
                 DO K=KDIM-1,1,-1
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K+1).EQ.0) THEN
                       DO NODE = 1,4
                          IF (TYPEBD(LOFF+(NODE-1)*IDIM*JDIM+
     &                        (J-1)*IDIM+I).EQ.2) THEN
                              BD_VAL(LOFF+(NODE-1)*IDIM*JDIM+
     &                        (J-1)*IDIM+I)=BDARY_WRK(I,J,K,L,NODE)
                          ENDIF
                       ENDDO
                       GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
  20  CONTINUE

      END

C**********************************************************************
      SUBROUTINE EFACE_BE_WRK(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL)
C**********************************************************************
C Copy values from a 2D boundary element array to 3D grid element array
C before update
C
C INPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C
C OUTPUT:
C   DARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'layout.h'
      INCLUDE 'ebdary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3),BD_VAL(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NBP,arrsize

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.4) THEN
           DO K = KL1,KL2
              DO J = JL1V(K),JL2V(K)
                 DO I = IL1,IL2
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=BD_VAL(LOFF+(K-1)*JDIM+J)
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.4) THEN
           DO K = KL1,KL2
              DO J=JL1V(K),JL2V(K)
                 DO I=IL2,IL1,-1
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=BD_VAL(LOFF+(K-1)*JDIM+J)
                       GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.4) THEN
           DO K=KL1,KL2
              JL1=JL1V(K)
              JL2=JL2V(K)
              DO I=IL1,IL2
                 DO J=JL1,JL2
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=BD_VAL(LOFF+(K-1)*IDIM+I)
                       GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.4) THEN
           DO K=KL1,KL2
              JL1=JL1V(K)
              JL2=JL2V(K)
              DO I=IL1,IL2
                 DO J=JL2,JL1,-1
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=BD_VAL(LOFF+(K-1)*IDIM+I)
                       GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.4) THEN
           DO J=1+JLAY,JDIM-JLAY
              DO I=IL1,IL2
                 DO K=KL1,KL2
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=BD_VAL(LOFF+(J-1)*IDIM+I)
                       GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.4) THEN
           DO J=1+JLAY,JDIM-JLAY
              DO I=IL1,IL2
                 DO K=KL2,KL1,-1
                    IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K+1).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=BD_VAL(LOFF+(J-1)*IDIM+I)
                       GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
  20  CONTINUE

      END
C**********************************************************************
      SUBROUTINE EFACE_WRK_BE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL)
C**********************************************************************
C Copy values from a 3D grid element array to 2D boundary element array
C after update
C
C INPUT:
C   BDARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C
C OUTPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3),BD_VAL(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.4) THEN
           DO K = 1,KDIM
              DO J = 1,JDIM
                 DO I = IL1,IL2
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                       BD_VAL(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.4) THEN
           DO K = 1,KDIM
              DO J=1,JDIM
                 DO I=IL2,IL1,-1
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                       BD_VAL(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)
                       GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.4) THEN
           DO K=1,KDIM
              DO I=IL1,IL2
                 DO J=2,JDIM
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                       BD_VAL(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                       GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.4) THEN
           DO K=1,KDIM
              DO I=IL1,IL2
                 DO J=JDIM-1,1,-1
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                       BD_VAL(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                       GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.4) THEN
           DO J=1,JDIM
              DO I=IL1,IL2
                 DO K=2,KDIM
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                       BD_VAL(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                       GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.4) THEN
           DO J=1,JDIM
              DO I=IL1,IL2
                 DO K=KDIM-1,1,-1
                    IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K+1).EQ.0) THEN
                       BD_VAL(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)
                       GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
  20  CONTINUE

      END


! BW update N_TYPEBD between processors
C**********************************************************************
      SUBROUTINE ETYPEBD_BE_WRK(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,TYPEBD,
     &                    KEY_CR)
C**********************************************************************
C Copy values from a 2D boundary element array to 3D grid element array
C before update
C
C INPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C
C OUTPUT:
C   DARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEY_CR(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3)
      INTEGER TYPEBD(*), ARRSIZE

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NODE,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN


      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(1,L,NBLK).EQ.4) THEN
           DO K = KL1,KL2+1
              DO J = 2,JDIM-1
                 DO I = IL1,IL2+1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I-1,J,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=TYPEBD(LOFF+(K-1)*JDIM+J)
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = JDIM*KDIM
      DO L=1,3
        LOFF=(L-1)*NBP
        IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(2,L,NBLK).EQ.4) THEN
           DO K = KL1,KL2+1
              DO J=2,JDIM-1
                 DO I=IL2+1,IL1,-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I+1,J,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=TYPEBD(LOFF+(K-1)*JDIM+J)
                       GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(3,L,NBLK).EQ.4) THEN
           DO K=KL1,KL2+1
              DO I=IL1,IL2+1
                 DO J=2,JDIM-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J-1,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=TYPEBD(LOFF+(K-1)*IDIM+I)
                       GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(4,L,NBLK).EQ.4) THEN
           DO K=KL1,KL2+1
              DO I=IL1,IL2+1
                 DO J=JDIM-1,2,-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J+1,K).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=TYPEBD(LOFF+(K-1)*IDIM+I)
                       GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(5,L,NBLK).EQ.4) THEN
           DO J=2,JDIM-1
              DO I=IL1,IL2+1
                 DO K=KL1,KL2+1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J,K-1).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=TYPEBD(LOFF+(J-1)*IDIM+I)
                       GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
        ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(6,L,NBLK).EQ.4) THEN
           DO J=2,JDIM-1
              DO I=IL1,IL2+1
                 DO K=KL2+1,KL1,-1
                    IF(KEY_CR(I,J,K).EQ.1.AND.KEY_CR(I,J,K+1).EQ.0) THEN
                       BDARY_WRK(I,J,K,L)=TYPEBD(LOFF+(J-1)*IDIM+I)
                       GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO

  20  CONTINUE

      END
C**********************************************************************
      SUBROUTINE ETYPEBD_WRK_BE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,TYPEBD,
     &                    KEY_CR)
C**********************************************************************
C Copy values from a 3D grid element array to 2D boundary element array
C after update
C
C INPUT:
C   DARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C
C OUTPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEY_CR(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3)
      INTEGER TYPEBD(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NODE,NBP

!bw      IF(.NOT.IBD_FACE(IFACE,NBLK)) RETURN
      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  NBP = JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(1,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(1,L,NBLK).EQ.4) THEN
           DO K = 1,KDIM
              DO J = 1,JDIM
                 DO I = IL1,IL2+1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I-1,J,K).EQ.0) THEN
                       TYPEBD(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)+.1D0
                       GO TO 11
                    ENDIF
                 ENDDO
  11             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  NBP = JDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(2,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(2,L,NBLK).EQ.4) THEN
           DO K = 1,KDIM
              DO J=1,JDIM
                 DO I=IL2+1,IL1,-1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I+1,J,K).EQ.0) THEN
                       TYPEBD(LOFF+(K-1)*JDIM+J)=BDARY_WRK(I,J,K,L)+.1D0
                       GO TO 12
                    ENDIF
                 ENDDO
  12             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(3,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(3,L,NBLK).EQ.4) THEN
           DO K=1,KDIM
              DO I=IL1,IL2+1
                 DO J=2,JDIM
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J-1,K).EQ.0) THEN
                       TYPEBD(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)+.1D0
                       GO TO 13
                    ENDIF
                 ENDDO
  13             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  NBP = IDIM*KDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(4,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(4,L,NBLK).EQ.4) THEN
           DO K=1,KDIM
              DO I=IL1,IL2+1
                 DO J=JDIM-1,1,-1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J+1,K).EQ.0) THEN
                       TYPEBD(LOFF+(K-1)*IDIM+I)=BDARY_WRK(I,J,K,L)+.1D0
                       GO TO 14
                    ENDIF
                 ENDDO
  14             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(5,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(5,L,NBLK).EQ.4) THEN
           DO J=1,JDIM
              DO I=IL1,IL2+1
                 DO K=2,KDIM
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J,K-1).EQ.0) THEN
                       TYPEBD(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)+.1D0
                       GO TO 15
                    ENDIF
                 ENDDO
  15             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  NBP = IDIM*JDIM
      DO L=1,3
         LOFF=(L-1)*NBP
         IF(ITYPE_BOUNDARY(6,L,NBLK).EQ.2 .OR.
     &     ITYPE_BOUNDARY(6,L,NBLK).EQ.4) THEN
           DO J=1,JDIM
              DO I=IL1,IL2+1
                 DO K=KDIM-1,1,-1
                    IF(KEY_CR(I,J,K).NE.0.AND.KEY_CR(I,J,K+1).EQ.0) THEN
                       TYPEBD(LOFF+(J-1)*IDIM+I)=BDARY_WRK(I,J,K,L)+.1D0
                       GO TO 16
                    ENDIF
                 ENDDO
  16             CONTINUE
              ENDDO
           ENDDO
         ENDIF
      ENDDO
  20  CONTINUE

      END

C**********************************************************************
      SUBROUTINE EPRES_BE_WRK(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL)
C**********************************************************************
C Copy values from a 2D boundary element array to 3D grid element array
C before update
C
C INPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C
C OUTPUT:
C   BDARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'layout.h'
      INCLUDE 'ebdary.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3),BD_VAL(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NBP,arrsize

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK
   1  CONTINUE
         DO K = KL1,KL2
            DO J = JL1V(K),JL2V(K)
               DO I = IL1,IL2
                  IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                     BDARY_WRK(I,J,K,1)=BD_VAL((K-1)*JDIM+J)
                     GO TO 11
                  ENDIF
               ENDDO
  11           CONTINUE
            ENDDO
         ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  CONTINUE
         DO K = KL1,KL2
            DO J=JL1V(K),JL2V(K)
               DO I=IL2,IL1,-1
                  IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                     BDARY_WRK(I,J,K,1)=BD_VAL((K-1)*JDIM+J)
                     GO TO 12
                  ENDIF
               ENDDO
  12           CONTINUE
            ENDDO
         ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  CONTINUE
        DO K=KL1,KL2
           JL1=JL1V(K)
           JL2=JL2V(K)
           DO I=IL1,IL2
              DO J=JL1,JL2
                 IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                    BDARY_WRK(I,J,K,1)=BD_VAL((K-1)*IDIM+I)
                    GO TO 13
                 ENDIF
              ENDDO
  13          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  CONTINUE
        DO K=KL1,KL2
           JL1=JL1V(K)
           JL2=JL2V(K)
           DO I=IL1,IL2
              DO J=JL2,JL1,-1
                 IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                    BDARY_WRK(I,J,K,1)=BD_VAL((K-1)*IDIM+I)
                    GO TO 14
                 ENDIF
              ENDDO
  14          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  CONTINUE
        DO J=1+JLAY,JDIM-JLAY
           DO I=IL1,IL2
              DO K=KL1,KL2
                 IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                    BDARY_WRK(I,J,K,1)=BD_VAL((J-1)*IDIM+I)
                    GO TO 15
                 ENDIF
              ENDDO
  15          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  CONTINUE
        DO J=1+JLAY,JDIM-JLAY
           DO I=IL1,IL2
              DO K=KL2,KL1,-1
                 IF(KEYOUT(I,J,K).EQ.1.AND.KEYOUT(I,J,K+1).EQ.0) THEN
                    BDARY_WRK(I,J,K,1)=BD_VAL((J-1)*IDIM+I)
                    GO TO 16
                 ENDIF
              ENDDO
  16          CONTINUE
           ENDDO
        ENDDO

  20  CONTINUE

      END
C**********************************************************************
      SUBROUTINE EPRES_WRK_BE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,BDARY_WRK,BD_VAL)
C**********************************************************************
C Copy values from a 3D grid element array to 2D boundary element array
C after update
C
C INPUT:
C   BDARY_WRK(I,J,K,L) = 3D GRID ELEMENT ARRAY
C
C OUTPUT:
C   BD_VAL(*) = 2D GRID ELEMENT ARRAY
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BDARY_WRK(IDIM,JDIM,KDIM,3),BD_VAL(*)

      INTEGER I,J,K,L,JL1,JL2,LOC,LOFF,NBP

      IF(.NOT.DP_FACE(IFACE,NBLK)) RETURN

      GO TO (1,2,3,4,5,6) IFACE

C COPY -X SIDE BOUNDARY VALUE TO BDARY_WRK

   1  CONTINUE
        DO K = 1,KDIM
           DO J = 1,JDIM
              DO I = IL1,IL2
                 IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I-1,J,K).EQ.0) THEN
                    BD_VAL((K-1)*JDIM+J)=BDARY_WRK(I,J,K,1)
                    GO TO 11
                 ENDIF
              ENDDO
  11          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY + X SIDE BOUNDARY VALUE TO BDARY_WRK

   2  CONTINUE
        DO K = 1,KDIM
           DO J=1,JDIM
              DO I=IL2,IL1,-1
                 IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I+1,J,K).EQ.0) THEN
                    BD_VAL((K-1)*JDIM+J)=BDARY_WRK(I,J,K,1)
                    GO TO 12
                 ENDIF
              ENDDO
  12          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY - Y SIDE BOUNDARY VALUE TO BDARY_WRK

   3  CONTINUE
        DO K=1,KDIM
           DO I=IL1,IL2
              DO J=2,JDIM
                 IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J-1,K).EQ.0) THEN
                    BD_VAL((K-1)*IDIM+I)=BDARY_WRK(I,J,K,1)
                    GO TO 13
                 ENDIF
              ENDDO
  13          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY + Y SIDE BOUNDARY VALUE TO BDARY_WRK

   4  CONTINUE
        DO K=1,KDIM
           DO I=IL1,IL2
              DO J=JDIM-1,1,-1
                 IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J+1,K).EQ.0) THEN
                    BD_VAL((K-1)*IDIM+I)=BDARY_WRK(I,J,K,1)
                    GO TO 14
                 ENDIF
              ENDDO
  14          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY - Z SIDE BOUNDARY VALUE TO BDARY_WRK

   5  CONTINUE
        DO J=1,JDIM
           DO I=IL1,IL2
              DO K=2,KDIM
                 IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K-1).EQ.0) THEN
                    BD_VAL((J-1)*IDIM+I)=BDARY_WRK(I,J,K,1)
                    GO TO 15
                 ENDIF
              ENDDO
  15          CONTINUE
           ENDDO
        ENDDO
      GO TO 20

C COPY + Z SIDE BOUNDARY VALUE TO BDARY_WRK

   6  CONTINUE
        DO J=1,JDIM
           DO I=IL1,IL2
              DO K=KDIM-1,1,-1
                 IF(KEYOUT(I,J,K).NE.0.AND.KEYOUT(I,J,K+1).EQ.0) THEN
                    BD_VAL((J-1)*IDIM+I)=BDARY_WRK(I,J,K,1)
                    GO TO 16
                 ENDIF
              ENDDO
  16          CONTINUE
           ENDDO
        ENDDO
  20  CONTINUE

      END

C*********************************************************************
      SUBROUTINE EGETVAL (VNAM,VAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,
     & NUMRET,NERR)
C*********************************************************************
C  EXTRACTS GRID ELEMENT DATA ON THE BOUNDARY FACES
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

      LOGICAL LQ,ENDAT,LV,SKIPIT,IN_I,IN_J,IN_K
      INTEGER NN(3,4),MUL(4),NGLT(3),L1REP(5),L2REP(5),NREP(5),IDIR(4)
      REAL*8 R8,VAL(*)
      CHARACTER*1 BLANK,QUOTE,COMMA,LEFT,RIGHT,EQUAL,COLON,ASTR,VNAM(*),
     & TOS(2),STP(4),TRU(4),FAL(5),III,JJJ,KKK,LLL,LBRAC,RBRAC,RECEND,
     & SVAL(*)
      CHARACTER*2 TYP(9),VTYP
      CHARACTER*50 E
      CHARACTER*60 UNTSTDS

      INCLUDE 'control.h'
      INCLUDE 'readdat.h'
!      INCLUDE 'scrat1.h'
      INCLUDE 'layout.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      EQUIVALENCE (UNTSTD(1),UNTSTDS)

      DATA BLANK/' '/,QUOTE/'"'/,COMMA/','/,LEFT/'('/,RIGHT/')'/,
     & EQUAL/'='/,COLON/':'/,ASTR/'*'/,TOS/'T','O'/,LBRAC/'['/,
     & STP/'S','T','E','P'/,III/'I'/,JJJ/'J'/,KKK/'K'/,LLL/'L'/,
     & RBRAC/']'/,TYP/'I2','I4','R4','R8','L2','L4','CS','FG','BT'/,
     & TRU/'T','R','U','E'/,FAL/'F','A','L','S','E'/

      ENTRY EGETVALS (VNAM,SVAL,VTYP,NDIM1,NDIM2,NDIM3,NDIM4,NUMRET,
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

C SET DIMENSIONS FOR BOUNDARY ELEMENT INPUT

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
         IF(IFACE.GT.0) THEN
            IF(IFACE.EQ.1.OR.IFACE.EQ.2) THEN
               MUL(1)=0
               I1=2
               I2=3
               I3=1
            ENDIF
            IF(IFACE.EQ.3.OR.IFACE.EQ.4) THEN
               MUL(2)=0
               I1=1
               I2=3
               I3=2
            ENDIF
            IF(IFACE.EQ.5.OR.IFACE.EQ.6) MUL(3)=0
         ENDIF
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
      IF (IFACE.GT.0) GO TO 50
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
      IDIR(1)=I1
      IDIR(2)=I2
      IDIR(3)=I3
      IDIR(4)=I4
      NDMAX=4
      IF (KVAR.EQ.7) NDMAX=3
      IF (KVAR.EQ.9) NDMAX=1
      IF (NBLAKG.GT.0.AND.IFACE.GT.0) NDMAX=2
      DO 16 I=1,NDMAX
      II=IDIR(I)
      IDUM=NN(2,II)
C  GET LOWER INDEX
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.COMMA) GO TO 16
      NOTINDX=.FALSE.
      CALL GETNUM(R8,KEY,L,LL)
      NOTINDX=.TRUE.
      IF (KEY.EQ.0) THEN
         L=LL
         NN(1,II)=R8+1.0D-2
         IF (NN(1,II).LT.1.OR.NN(1,II).GT.IDUM) GO TO 41
         NN(2,II)=R8+1.0D-2
      ENDIF
C  CHECK FOR , OR )
      IF (A(L).EQ.BLANK) L=L+1
      IF (A(L).EQ.COMMA) GO TO 16
      IF (A(L).EQ.RIGHT) GO TO 14
C  GET TO
      IF (A(L).NE.TOS(1).OR.A(L+1).NE.TOS(2)) GO TO 13
      L=L+2
C  GET UPPER INDEX
      NN(2,II)=IDUM
      NOTINDX=.FALSE.
      CALL GETNUM(R8,KEY,L,LL)
      NOTINDX=.TRUE.
      IF (KEY.EQ.0) THEN
         L=LL
         NN(2,II)=R8+1.0D-2
         IF (NN(2,II).LT.1.OR.NN(2,II).GT.IDUM) GO TO 41
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
         NN(3,II)=R8+1.0D-2
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

C  START DATA LOOP

      NUMREP=0
      ENDAT=.FALSE.
      LFILL=0
      NETPRN=0
      NRETR=0
      NBLK=0

C RESET LOOP INDICES FOR BOUNDARY ELEMENT INPUT
      IF(NBLKG.GT.0.AND.IFACE.GT.0) THEN
         IF(IFACE.EQ.1) THEN
            NN(1,1)=BDARYIJK(1,1,NBLKG)
            NN(2,1)=NN(1,1)
         ELSE IF(IFACE.EQ.2) THEN
            NN(2,1)=BDARYIJK(2,1,NBLKG)
            IF(KNDARY.EQ.2) NN(2,1)=NN(2,1)+1    !bw Nodal based array
            NN(1,1)=NN(2,1)
         ELSE IF(IFACE.EQ.3) THEN
            NN(1,2)=BDARYIJK(1,2,NBLKG)
            NN(2,2)=NN(1,2)
         ELSE IF(IFACE.EQ.4) THEN
            NN(2,2)=BDARYIJK(2,2,NBLKG)
            IF(KNDARY.EQ.2) NN(2,2)=NN(2,2)+1    !bw Nodal based array
            NN(1,2)=NN(2,2)
         ELSE IF(IFACE.EQ.5) THEN
            NN(1,3)=BDARYIJK(1,3,NBLKG)
            NN(2,3)=NN(1,3)
         ELSE IF(IFACE.EQ.6) THEN
            NN(2,3)=BDARYIJK(2,3,NBLKG)
            IF(KNDARY.EQ.2) NN(2,3)=NN(2,3)+1    !bw Nodal based array
            NN(1,3)=NN(2,3)
         ENDIF
      ENDIF
      I1_BD=BDARYIJK(1,I1,NBLKG)
      I2_BD=BDARYIJK(2,I1,NBLKG)
      J1_BD=BDARYIJK(1,I2,NBLKG)
      J2_BD=BDARYIJK(2,I2,NBLKG)
      K1_BD=BDARYIJK(1,I3,NBLKG)
      K2_BD=BDARYIJK(2,I3,NBLKG)
!bw Nodal based array
      IF (KNDARY.EQ.2) THEN
         I2_BD=BDARYIJK(2,I1,NBLKG)+1
         J2_BD=BDARYIJK(2,I2,NBLKG)+1
         K2_BD=BDARYIJK(2,I3,NBLKG)+1
      ENDIF
!bw
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
            IF (KNDARY.EQ.1) THEN
               MAPA=MAPA+N0MAP(NBLKG)+ND3*NYMAP(NBLKG)
            ELSEIF(KNDARY.EQ.2) THEN
               MAPA=MAPA+N0MAPN(NBLKG)+ND3*(NYMAP(NBLKG)+1)
            ENDIF
         ELSE
            IF (I1.EQ.3) THEN
               IF (KNDARY.EQ.1) THEN
                  MAPA=MAPA+N0MAP(NBLKG)+ND1*NYMAP(NBLKG)
               ELSEIF(KNDARY.EQ.2) THEN
                  MAPA=MAPA+N0MAPN(NBLKG)+ND1*(NYMAP(NBLKG)+1)
               ENDIF
            ELSE
               IF (I2.EQ.3) THEN
                  IF (KNDARY.EQ.1) THEN
                     MAPA=MAPA+N0MAP(NBLKG)+ND2*NYMAP(NBLKG)
                  ELSEIF(KNDARY.EQ.2) THEN
                     MAPA=MAPA+N0MAPN(NBLKG)+ND2*(NYMAP(NBLKG)+1)
                  ENDIF
               ELSE
                  IF (KNDARY.EQ.1) THEN
                     MAPA=MAPA+N0MAP(NBLKG)+ND4*NYMAP(NBLKG)
                  ELSEIF(KNDARY.EQ.2) THEN
                     MAPA=MAPA+N0MAPN(NBLKG)+ND4*(NYMAP(NBLKG)+1)
                  ENDIF
               ENDIF
            ENDIF
         ENDIF
         MAPPRC=PRCMAP(MAPA)
         IF (KNDARY.EQ.2) MAPPRC=PRCMAPN(MAPA)
!bw         IF (PRCMAP(MAPA).EQ.MYPRC) THEN
         IF (MAPPRC.EQ.MYPRC) THEN
            LOC=MUL(I1)*(ND1-NGLT(I1))+MUL(I2)*(ND2-NGLT(I2))
     &         +MUL(I3)*(ND3-NGLT(I3))+MUL(I4)*(ND4-1)+1
            IF (LOC.LT.0) THEN
               WRITE(*,*) "LOCATION 1,MYPRC=",MYPRC,
     &          'ND1,ND2,ND3,ND4=',ND1-NGLT(I1),ND2-NGLT(I2),
     &          ND3-NGLT(I3),ND4-1
               STOP 13
            ENDIF

!bw         ELSE IF (IFACE.GT.0.AND.PRCMAP(MAPA).EQ.-2) THEN
         ELSE IF (IFACE.GT.0.AND.MAPPRC.EQ.-2) THEN
            IN_I=.FALSE.
            IN_J=.FALSE.
            IN_K=.FALSE.
            IF(ND1.GE.I1_BD.AND.ND1.LE.I2_BD)
     &         IN_I=.TRUE.
            IF(ND2.GE.J1_BD.AND.ND2.LE.J2_BD)
     &         IN_J=.TRUE.
            IF(ND3.GE.K1_BD.AND.ND3.LE.K2_BD)
     &         IN_K=.TRUE.
            IF(IN_I.AND.IN_J.AND.IN_K) THEN
               LOC=MUL(I1)*(ND1-NGLT(I1))+MUL(I2)*(ND2-NGLT(I2))
     &         +MUL(I3)*(ND3-NGLT(I3))+MUL(I4)*(ND4-1)+1
               IF (LOC.LT.0) THEN
                  WRITE(*,*) "LOCATION 2,MYPRC=",MYPRC,'LOC<0'
                  STOP 13
               ENDIF
            ELSE
               SKIPIT=.TRUE.
            ENDIF
         ELSE
            SKIPIT=.TRUE.
         ENDIF
      ELSE
         LOC=MUL(I1)*(ND1-1)+MUL(I2)*(ND2-1)+MUL(I3)*(ND3-1)
     &      +MUL(I4)*(ND4-1)+1
         IF (LOC.LT.0) THEN
            WRITE(*,*) "LOCATION 3,MYPRC=",MYPRC,'LOC<0'
            STOP 13
         ENDIF
      ENDIF
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
      DO 96 I=LV1,LAST
      IF (A(I).EQ.QUOTE) LQ=.NOT.LQ
      IF ((A(I).EQ.COLON).AND.LQ) GO TO 97
      A(I)=BLANK
   96 CONTINUE
      ISUNTD=.FALSE.
      RETURN
      END

C***********************************************************************
      SUBROUTINE EBDARY_DP(VNAM,N_ARY,KARY,NFACE,NDIR,NTYP,
     &           NUMRET,NERR)
C***********************************************************************
C Poroelastic model displacement boundary condition input
C
C VNAM = CHARACTER STRING TO BE READ IN THE INPUT FILE
C        (INPUT, CHARACTER*60)
C
C N_ARY = BOUNDARY ELEMENT ARRAY NUMBER (INPUT,INTEGER)
C
C KARY = ARRAY KEY (INPUT,INTEGER)
C      = 1 ==> BLOCK CENTER ARRAY
C      = 2 ==> BLOCK CORNER ARRAY
C
C NFACE = BOUNDARY FACE NUMBER TO BE READ (INPUT,INTEGER)
C       = 1 ==> -X SIDE
C       = 2 ==> +X SIDE
C       = 3 ==> -Y SIDE
C       = 4 ==> +Y SIDE
C       = 5 ==> -Z SIDE
C       = 6 ==> +Z SIDE
C
C NDIR = DIRECTION NUMBER ON A BOUNDARY FACE (INPUT,INTEGER)
C       = 1 ==> X DIRECTION
C       = 2 ==> Y DIRECTION
C       = 3 ==> Z DIRECTION
C
C NTYP = BOUNDARY CONDITION TYPE
C       = 1 ==> ZERO DISPLACEMENT
C       = 2 ==> USER SPECIFIED DISPLACEMENT
C       = 3 ==> ZERO TRACTION
C       = 4 ==> TRACTION
C
C NUMRET = NUMBER OF VALUES READ TO THE ARRAY (OUTPUT, INTEGER)
C
C NERR = ERROR NUMBER STEPPED BY 1 FOR EACH DATA ERROR INCOUNTERED
C        (INPUT AND OUTPUT, INTEGER)
C **********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'control.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      INTEGER MAXCHR
      PARAMETER (MAXCHR=100000000)
      CHARACTER*1 VNAM(*)
      INTEGER N_ARY,KARY,NFACE,NDIR,NTYP,NUMRET,NERR

      INTEGER  I,J,KA(2),NMOD,NDIM4,KERR
      EXTERNAL EBDARY_DPWR8, EBDARY_DPWI4
      INTEGER PEMOD

      IF(N_ARY.EQ.0) RETURN
      CALL ARYTYPE(N_ARY,NTYPGA,NDIM4,PEMOD,KERR)
      IF(KERR.GT.0) THEN
         NERR=NERR+1
         RETURN
      ENDIF
      J=0
      DO I=1,60
         VNAMGA(I)=VNAM(I)
         IF (VNAMGA(I).EQ.']'.OR.(VNAMGA(I).EQ.' '.AND.J.EQ.0)) GO TO 2
         IF (VNAMGA(I).EQ.'[') J=1
      ENDDO

   2  NUMRGA=0
      KERRGA=0
      KNDARY=KARY
      IFACE=NFACE
      IBD_DIR=NDIR
      IBD_TYPE=NTYP
cbw      write(*,*) 'in EBDARY_DP,N_ARY=',N_ARY,'KERR=',KERR
cbw      write(*,*) 'in EBDARY_DP,VNAMGA=',VNAMGA

      KA(1)=1
      KA(2)=N_ARY
      CALL ALLBLOCKS()
      IF (NTYPGA.EQ.4) THEN
         CALL CALLWORK(EBDARY_DPWI4,KA)
      ELSE
         CALL CALLWORK(EBDARY_DPWR8,KA)
      ENDIF
      NUMRET=NUMRGA
      NERR=NERR+KERRGA

   3  FORMAT('/ERR(PE100): ONLY REAL*8 TYPE OF BOUNDARY DATA ALLOWED')
      END



C**********************************************************************
      SUBROUTINE EBDARY_DPWR8(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &           KL1,KL2,KEYOUT,NBLKA,BD_VAL)
C**********************************************************************
C Poroelastic model displacement boundary condition input
C
C OUTPUT:
C   BD_VAL(J) = DISPLACEMENT VALUES ON A BOUNDARY FACE
C**********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      INTEGER NVN
      PARAMETER (NVN=60+4)
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLKA
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  BD_VAL(*)

      INTEGER IDIMG,JDIMG,KDIMG,NERR,N
      INTEGER I,J,L,KERR,ILOC
      CHARACTER*1 VNAMC(NVN)
      CHARACTER*2 VTYP(6)
      DATA VTYP/'R4','R8','I2','I4','L2','L4'/

      IF (IFACE.LE.0.OR.IFACE.GT.6) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF (IBD_DIR.LE.0.OR.IBD_DIR.GT.3) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF (.NOT.IBD_FACE(IFACE,NBLKA)) RETURN

C BUILD VARIABLE NAME FOR A SPECIFIC GRID BLOCK

      CALL ESETVNAM(VNAMGA,VNAMC,NBLKA)

C GET GRID BLOCK GLOBAL DIMENSIONS

   4  CALL BLKDIM(NBLKA,IDIMG,JDIMG,KDIMG,KERR)
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF

      IF (KNDARY.EQ.2) THEN
         IDIMG=IDIMG+1
         JDIMG=JDIMG+1
         KDIMG=KDIMG+1
      ENDIF

C PUT LOCAL-GLOBAL OFFSETS AND LOCAL DIMENSIONS IN /READAT/

      CALL BLKOFF(NBLKA,IGLT,JGLT,KGLT,NERR)
      IDIML=IDIM
      JDIML=JDIM
      KDIML=KDIM
      IF (IFACE.EQ.1.OR.IFACE.EQ.2) THEN
         IDIMG=1
         IDIML=1
         ILOC=(IBD_DIR-1)*4*JDIM*KDIM+1
      ELSE IF(IFACE.EQ.3.OR.IFACE.EQ.4) THEN
         JDIMG=1
         JDIML=1
         ILOC=(IBD_DIR-1)*4*IDIM*KDIM+1
      ELSE
         KDIMG=1
         KDIML=1
         ILOC=(IBD_DIR-1)*4*IDIM*JDIM+1
      ENDIF

C GET DATA FOR THE BOUNDARY ELEMENTS

      N = 0
      KERR=0
      NBLKG=NBLKA
      CALL EGETVAL (VNAMC,BD_VAL(ILOC),VTYP(NTYPGA),IDIMG,JDIMG,KDIMG,
     &     4,N,KERR)
      NUMRGA=NUMRGA+N
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
!bw      IF(NUMRGA.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE
      IF(N.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE

cbag8
      NBLKG=0
c      IFACE=0

      END


C**********************************************************************
      SUBROUTINE EBDARY_DPWI4(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &           KL1,KL2,KEYOUT,NBLKA,BD_VAL)
C**********************************************************************
C Poroelastic model displacement boundary condition input
C
C OUTPUT:
C   BD_VAL(J) = DISPLACEMENT VALUES ON A BOUNDARY FACE
C**********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'
      INCLUDE 'readdat.h'
      INCLUDE 'emodel.h'
      INCLUDE 'ebdary.h'

      INTEGER NVN
      PARAMETER (NVN=60+4)
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLKA
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER  BD_VAL(*)

      INTEGER IDIMG,JDIMG,KDIMG,NERR,N
      INTEGER I,J,L,KERR,ILOC
      CHARACTER*1 VNAMC(NVN)
      CHARACTER*2 VTYP(6)
      DATA VTYP/'R4','R8','I2','I4','L2','L4'/

      IF (IFACE.LE.0.OR.IFACE.GT.6) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF (IBD_DIR.LE.0.OR.IBD_DIR.GT.3) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
      IF (.NOT.IBD_FACE(IFACE,NBLKA)) RETURN

C BUILD VARIABLE NAME FOR A SPECIFIC GRID BLOCK

      CALL ESETVNAM(VNAMGA,VNAMC,NBLKA)

C GET GRID BLOCK GLOBAL DIMENSIONS

   4  CALL BLKDIM(NBLKA,IDIMG,JDIMG,KDIMG,KERR)
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF

      IF (KNDARY.EQ.2) THEN
         IDIMG=IDIMG+1
         JDIMG=JDIMG+1
         KDIMG=KDIMG+1
      ENDIF

C PUT LOCAL-GLOBAL OFFSETS AND LOCAL DIMENSIONS IN /READAT/

      CALL BLKOFF(NBLKA,IGLT,JGLT,KGLT,NERR)
      IDIML=IDIM
      JDIML=JDIM
      KDIML=KDIM
      IF (IFACE.EQ.1.OR.IFACE.EQ.2) THEN
         IDIMG=1
         IDIML=1
         ILOC=(IBD_DIR-1)*4*JDIM*KDIM+1
      ELSE IF(IFACE.EQ.3.OR.IFACE.EQ.4) THEN
         JDIMG=1
         JDIML=1
         ILOC=(IBD_DIR-1)*4*IDIM*KDIM+1
      ELSE
         KDIMG=1
         KDIML=1
         ILOC=(IBD_DIR-1)*4*IDIM*JDIM+1
      ENDIF

C GET DATA FOR THE BOUNDARY ELEMENTS

      N = 0
      KERR=0
      NBLKG=NBLKA
      CALL EGETVAL (VNAMC,BD_VAL(ILOC),VTYP(NTYPGA),IDIMG,JDIMG,KDIMG,
     &     4,N,KERR)
      NUMRGA=NUMRGA+N
      IF(KERR.NE.0) THEN
         KERRGA=KERRGA+1
         RETURN
      ENDIF
!bw      IF(NUMRGA.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE
      IF(N.GT.0) ITYPE_BOUNDARY(IFACE,IBD_DIR,NBLKA) = IBD_TYPE

cbag8
      NBLKG=0
c      IFACE=0

      END