C  BLKARY.H - GRID-BLOCK ARRAYS USED BY ALL MODELS

      INTEGER NXDIM(10),NYDIM(10),NZDIM(10),
     & I4UTIL,I4UTIL1,I4UTIL2,N_XC,
     & N_YC,N_ZC,N_ROCK,N_POR,N_DEPTH,N_TCOFX,N_TCOFY,N_TCOFZ,N_PORO,
     & N_R8U,N_R4U,N_I4U,N_I4U1,N_I4U2,N_KTU,N_XPERM,N_YPERM,N_ZPERM,
     & N_KPU,KTU,KPU,N_EVOL,
     & N_DUNKV(19),N_COFV(19),N_RESIDV(19),N_BC_TYPE(3),
     & N_MYPRC

      REAL*4 R4UTIL
      REAL*8 R8UTIL
      CHARACTER*50 TITU

      COMMON /BLKARY/R8UTIL,R4UTIL,NXDIM,NYDIM,NZDIM
     & ,I4UTIL,I4UTIL1,I4UTIL2
     & ,N_XC,N_YC,N_ZC,N_ROCK,N_POR,N_DEPTH,N_TCOFX,N_TCOFY,N_TCOFZ
     & ,N_PORO,N_XPERM,N_YPERM,N_ZPERM,N_R8U,N_R4U
     & ,N_I4U,N_I4U1,N_I4U2,N_KTU,N_KPU,N_EVOL
     & ,N_BC_TYPE,N_MYPRC,N_DUNKV,N_COFV,N_RESIDV,KTU,KPU
     & ,TITU

C --- SAUMIK,BGANIS
      REAL*8  MIDPOINTS(10,2,204,204)
      INTEGER N_PORTRUE,N_RC,N_RCP,N_RCV,
     &        NEW_COMM,NEW_RANK,FLOW_COMM(10),
     &        NPAY,START1,GLOBAL
      LOGICAL FLAGBLK(10),NONMATCHING,HETEROGENEOUS

      COMMON /BLKARY2/MIDPOINTS,
     &   N_PORTRUE,N_RC,N_RCP,N_RCV,
     &   NEW_COMM,NEW_RANK,FLOW_COMM,
     &   NPAY,START1,GLOBAL,FLAGBLK,NONMATCHING,HETEROGENEOUS

! Variables for big cranfield problem
      INTEGER OB_LAYER,UB_LAYER
      COMMON /BIG/ OB_LAYER,UB_LAYER
C --- SAUMIK,BGANIS

C*****************  ARRAYS FOR ALL MODELS

C  N_XC, N_YC, N_ZC = GRID BLOCK CORNER ARRAY NUMBERS (FT,REAL*4)
C                     VALID ONLY FOR KNDGRD = 2

C  N_ROCK = ARRAY NUMBER FOR ROCK TYPE OF GRID ELEMENTS

C  N_POR = ARRAY NUMBER FOR POROSITY OF GRID ELEMENTS (REAL*4)
C                                           (REAL*8 FOR MFMFE)
C  N_PORO = ARRAY NUMBER FOR POROSITY OF GRID ELEMENTS (REAL*8)
C  N_DEPTH = ARRAY NUMBER FOR BLOCK CENTER DEPTH (FT,REAL*8)

C  N_TCOFX = ARRAY NUMBERS FOR TRANSMISSABILITY COEFFICIENT CONSTANT
C  N_TCOFY   FACTORS (REAL*8)
C  N_TCOFZ

C  N_XPERM = ARRAY NUMBERS FOR PERMEABILITIES (md,REAL*4)
C  N_YPERM
C  N_ZPERM

C  THE FOLLOWING 3 ARRAYS ARE ALLOCATED BY INDIVIDUAL PHYSICAL MODELS
C  BUT THE FRAMEWORK MUST ALSO KEEP TRACK OF THEM FOR THE LINEAR SOLVERS

C  N_DUNKV(n) = ARRAY NUMBER FOR LINEAR SOLUTION RESULT OF MODEL n

C  N_COFV(n) = ARRAY NUMBER FOR JACOBIAN OF MODEL n

C  N_RESIDV(n) = ARRAY NUMBER FOR RESIDUAL OF MODEL n

C*****************  UTILITY VARIABLES FOR ARRAY OPERATIONS

C  N_R8U, N_R4U, N_I4U = ARRAY NUMBERS FOR R8UTIL, R4UTIL, AND I4UTIL

C  R8UTIL = UTILITY VARIABLE (REAL*8)

C  R4UTIL = UTILITY VARIABLE (REAL*4)

C  I4UTIL = UTILITY VARIABLE (INTEGER)

C  N_KTU, N_KPU = ARRAY NUMBERS FOR KTU AND KPU

C  KTU = UTILITY VARIABLE TYPE FOR PRINTING GRID-BLOCK ARRAYS

C  KPU = UTILITY CENTER/CORNER KEY FOR PRINTING GRID-BLOCK ARRAYS

C  TITU = UTILITY TITLE FOR PRINTING GRID-BLOCK ARRAYS (CHARACTER*50)
C         USED BY GEAOUT

C  N_BC_TYPE = BOUNDARY-ELEMENT ARRAY NUMBER FOR BOUNDARY TYPE, (INTEGER)
C              0: NO-FLOW BOUNDARY CONDITION, 1: PRESSURE SPECIFIED
C              BOUNDARY CONDITION.
C              THREE VALUES FOR X, Y, Z DIRECTION RESPECTIVELY.

C  NX(Y,Z)DIM(I) = X(Y,Z) DIMENSION OF FAULT BLOCK I

C  N_EVOL = ELEMENT VOLUME FOR HEXAHEDRA (KNDGRD=3, MPFA models)