C  WELLS.H - WELL DATA AVAILABLE TO ALL MODELS

      INTEGER LOCWEL,KNDHIS,KWELL,NBWELI,NWELLI,KWPERM,MODWEL,NTABPQ,
     &        NWELPRC,LINSYSW,NUMELE,NUMELET,NWFCUM,KWCF,KWFILE,KHISOUT,
     &        NHISQ,MYHIS,NFWELL,NUMWEL,NWELG,NUMEQW,NHISUSE,NTYPOUT
      REAL*4 WELLTOP,WELLBOT,WELSKIN,WELDIAM,ELECONS,WELGEOM,ELEPERM,
     &       ELEGEOM,ELEDEP
      REAL*8 WELHIS,WELDEN,WELBHP,DWELBHP,DWELDEN,QRESID,DRESID,ELEDUM,
     & SPQ,PLIMIT,
C     & SXC(2*(13+1),50),
C     & SXC(2*(13+1),50),
     & SWIC(50),SWPC(50),SGIC(50),SGPC(50),
     & SOPC(50),SOIC(50),SWIT,SWPT,SGIT,SGPT,SOPT,
     & SOIT
C     & ,SXT(2*(13+1))
C     & ,SXT(2*(13+1))
      REAL*8 ELELEN,DEPBOT,DEPTOP,QCOFW,VCOFQ,VCOFD,DCOFW,QCOFN,
     & DCOFN,ELEXYZ,ELELAMI,TIMHIS
      LOGICAL WOUTFLG(50),WELL_ALLOW_SHUTOFF(50)
      CHARACTER*40 WELNAM
      CHARACTER*30 WELFILE
      CHARACTER*30 WFCUM
      CHARACTER*40 TITHIS
      CHARACTER*40 TITHISC

      COMMON /WELLS/ WELHIS(100000,0:18),WELDEN(50),WELBHP(50),
     & DWELBHP(50),DWELDEN(50),QRESID(50),DRESID(50),
     & ELEDUM(13,100,50),SPQ(50),PLIMIT(50),
C     & SXC,
C     & SXC,
     & SWIC,SWPC,SGIC,SGPC,SOPC,SOIC,SWIT,SWPT,SGIT,SGPT,SOPT,SOIT,
C     & SXT,
C     & SXT,
     & DEPBOT(50),DEPTOP(50),WELLTOP(3,2,50),
     & WELLBOT(3,2,50),WELSKIN(2,50),
     & WELDIAM(2,50),ELELEN(100,50),
     & QCOFW(13,100,50),VCOFQ(13,100,50),
     & DCOFW(13,100,50),VCOFD(13,100,50),
     & QCOFN(2,50),DCOFN(2,50),
     & ELEDEP(100,50),ELEXYZ(3,100,50),
     & ELEPERM(100,50),ELEGEOM(100,50),
     & ELECONS(100,50),WELGEOM(6,100),TIMHIS(0:18),
     & ELELAMI(100,50),
     & NUMWEL,NWELG,NHISUSE,KHISOUT,NWELLI(50),NBWELI(2,50),
     & KWELL(50),NUMELE(50),NUMELET(50),NTYPOUT,KWPERM(50),
     & LOCWEL(6,100,50),MODWEL(50),LINSYSW(50),
     & NTABPQ(50),NWELPRC(50),WOUTFLG,WELL_ALLOW_SHUTOFF,
     & NHISQ,KNDHIS(100000,0:18),
     & MYHIS,NFWELL,NWFCUM,KWFILE,KWCF,WELNAM(50),TITHIS(34),
     & TITHISC(34),WELFILE,WFCUM

C*********************************************************************

C  WELHIS(n,t) = WELL HISTORY QUANITY n AT TIME LEVEL t (ANY DIMENSIONS)

C  WELLTOP(,s,t) = X,Y,Z OF TOP OF INTERVAL s FOR WELL t (FEET)

C  WELLBOT(,s,t) = X,Y,Z OF BOTTOM OF INTERVAL s FOR WELL t (FEET)

C  WELSKIN(s,t) = SKIN FACTOR OF INTERVAL s FOR WELL t (DIMENSIONLESS)

C  WELLDIAM(s,t)= WELLBORE DIAMETER OF INTERVAL s FOR WELL t (FEET)

C  ELELEN(n,t)  = OPEN INTERVAL LENGTH OF ELEMENT n OF WELL t (FEET)

C  ELEDEP(n,t)  = OPEN INTERVAL DEPTH OF ELEMENT n OF WELL t (FEET)

C  ELEPERM(n,t) = OPEN INTERVAL PERMEABILITY OF ELEMENT n OF WELL t (MD)

C  ELEGEOM(n,t) = GEOMETRY FACTOR OF ELEMENT n OF WELL t (DIMENSIONLESS)

C  ELELAMI(n,t) = LAMDA FOR ELEMENT n OF INJECTION WELL t

C  ELEXYZ(,n,t) = X,Y,Z OF ELEMENT n OF WELL t (FEET)

C  ELEDUM(n,t) = SPARE VARIABLE FOR ELEMENT n OF WELL t.  USED IN MULTIGRID

C  DEPBOT(t)    = BOTTOM HOLE DEPTH OF WELL t (FEET)

C  DEPTOP(t)    = TOP HOLE DEPTH OF WELL t (TOP OF COMPLETION) (FEET)

C  PLIMIT(t)    = PRESSURE LIMIT FOR RATE CONTROLED WELL t

C  MODWEL(t)    = PHYSICAL MODEL OF WELL t

C  LINSYSW(t)   = KEY FOR EQUATIONS ADDED TO LINEAR SYSTEM BY WELL t
C               = 0 ==> NO EQUATIONS ADDED
C               = 1 ==> PRESSURE EQUATION ADDED
C               = 2 ==> DENSITY EQUATION ADDED
C               = 3 ==> BOTH PRESSURE AND DENSITY EQUATIONS ADDED

C  ELECONS(n,t) = ELEGEOM * ELELEN * ELEPERM FOR ELEMENT n OF WELL t
C                 (FEET * MD)

C  WELGEOM(6,m) = USER OVERRIDES FOR THE GEOMETRIC FACTOR (DIMENSIONLESS)
C       (1-3,m) = I,J,K
C         (4,m) = FAULT BLOCK NUMBER
C         (5,m) = WELL NUMBER
C         (6,m) = GEOMETRIC FACTOR

C  TIMHIS(n)    = RESERVOIR TIME AT HISTORY TIME LEVEL n (DAYS)

C  NUMWEL       = NUMBER OF WELLS

C  NWELG        = MAX VALUE OF m IN WELGEOM(6,m)

C  NHISUSE      = NUMBER OF TIME LEVELS USED IN WELL HISTORIES

C  NHISQ        = NUMBER OF HISTORY QUANTITIES USED IN CURRENT TIME STEP

C  KHISOUT      = DISPOSITION KEY FOR WELL HISTORIES
C               = 0 ==> DISCARD (DO NOT COLLECT)
C               = 1 ==> PRINT IN STANDARD OUTPUT
C               = 2 ==> OUTPUT TO DISK
C               = 3 ==> BOTH PRINT AND DISK

C  NWELLI(t)    = NUMBER OF COMPLETION INTERVALS FOR WELL t

C  NBWELI(s,t) = FAULT BLOCK NUMBER OF INTERVAL s OF WELL t

C  KWELL(t)     = CURRENT WELL TYPE OF WELL t
C                 TYPES 1 TO 20 ARE INJECTION WELLS
C                 TYPES 21 AND GREATER ARE PRODUCTION WELLS
C                 ALL WELL TYPES ARE NOT IMPLEMENTED IN ALL MODELS
C               = 0 ==> SHUT IN
C               = 1 ==> WATER INJECTION, PRESSURE SPECIFIED
C               = 2 ==> WATER INJECTION, MASS RATE SPECIFIED
C               = 3 ==> GAS INJECTION, PRESSURE SPECIFIED
C               = 4 ==> GAS INJECTION, MASS RATE SPECIFIED
C               = 5 ==> WATER INJECTION, RESERVOIR VOLUME RATE SPECIFIED
C               = 6 ==> GAS INJECTION, RESERVOIR VOLUME RATE SPECIFIED
C               = 31 ==> PRODUCTION, PRESSURE SPECIFIED
C               = 32 ==> PRODUCTION, TOTAL MASS RATE SPECIFIED
C               = 33 ==> PRODUCTION, OIL MASS RATE SPECIFIED
C               = 34 ==> PRODUCTION, GAS MASS RATE SPECIFIED
C               = 35 ==> PRODUCTION, WATER MASS RATE SPECIFIED
C               = 36 ==> PRODUCTION, WATER+OIL MASS RATE SPECIFIED
C               = 37 ==> PRODUCTION, TOTAL RESERVOIR VOLUME RATE SPECIFIED
C               = 38 ==> PRODUCTION, OIL RESERVOIR VOLUME RATE SPECIFIED
C               = 39 ==> PRODUCTION, GAS RESERVOIR VOLUME RATE SPECIFIED

C  KWPERM(t)    = MINIMUM INJECTION RELATIVE PERMEABILITY KEY FOR WELL t
C               = 1 ==> .1
C               = 2 ==> SUM OF OTHER RELATIVE PERMEABILITIES

C  WOUTFLG(t)   = WELL OUTPUT FLAG FOR WELL t
C               = .TRUE.  ==> PRINT OUTPUT FOR WELL t
C               = .FALSE. ==> DO NOT PRINT OUTPUT FOR WELL t

C  NTABPQ(t)    = TABLE NUMBER OF WELL BHP/RATE TABLE FOR WELL t

C  NWELPRC(t)   = PROCESSOR THAT OWNS WELL t

C  NUMELE(t)    = NUMBER OF GRID ELEMENTS PENETRATED BY WELL t ON THE
C                 CURRENT PROCESSOR (THESE ELEMENTS ARE FIRST IN LOCWEL).
C                 ELELEN(),ELEDEP(),ELEPERM(), ELEGEOM(), AND ELECONS() ARE
C                 DEFINED ONLY FOR THESE ELEMENTS.

C  NUMELET(t)   = TOTAL GRID ELEMENTS PENETRATED BY WELL t ON ALL PROCESSORS

C  LOCWEL(1,n,t)= FAULT BLOCK NUMBER OF GRID ELEMENT n OF WELL t
C  LOCWEL(2,n,t)= WELL INTERVAL NUMBER OF GRID ELEMENT n OF WELL t
C  LOCWEL(3,n,t)= I INDEX (GLOBAL) OF GRID ELEMENT n OF WELL t
C  LOCWEL(4,n,t)= J INDEX (GLOBAL) OF GRID ELEMENT n OF WELL t
C  LOCWEL(5,n,t)= K INDEX (GLOBAL) OF GRID ELEMENT n OF WELL t
C  LOCWEL(6,n,t)= PROCESSOR NUMBER OF GRID ELEMENT n OF WELL t

C  KNDHIS(n,t)  = IDENTIFICATION OF WELL HISTORY QUANITY n AT TIME LEVEL t
C                 PACKED ACCORDING TO THE FOLLOWING RULES
C      0      ==> UNUSED
C     > 0     ==> WELL NUMBER + (50 + 1) * (DATA TYPE NUMBER)

C  MYHIS        = 0 ==> NO WELL HISTORY TO OUTPUT ON THIS PROCESSOR
C               = 1 ==> HAVE WELL HISTORY TO OUTPUT ON THIS PROCESSOR

C  NFWELL       = FILE NUMBER FOR WELL HISTORY OUTPUT

C  KWFILE       = STATUS OF WELL HISTORY FILE
C               = 0 ==> FILE CLOSED
C               = 1 ==> FILE OPEN

C  WELNAM(t)    = WELL NAME OF WELL t

C  TITHIS(h)    = DISCRIPTION OF WELL HISTORY DATA TYPE h
C  THE FOLLOWING DATA TYPES ARE DEFINED BY THE FRAMEWORK BUT MAY BE EXTENDED
C  OR COMPLETELY REPLACED BY INDIVIDUAL PHYSICAL MODELS:
C      1      ==> WATER INJECTION RATE
C      2      ==> OIL PRODUCTION RATE
C      3      ==> WATER PRODUCTION RATE
C      4      ==> GAS PRODUCTION RATE
C      5      ==> WATER/OIL RATIO
C      6      ==> GAS/OIL RATIO
C      7      ==> BOTTOM-HOLE PRESSURE
C      8      ==> GAS INJECTION RATE
C      9      ==> OIL INJECTION RATE

C  TITHISC(h)    = DISCRIPTION OF WELL HISTORY CUMULATIVE DATA TYPE h
C  THE FOLLOWING DATA TYPES ARE DEFINED BY THE FRAMEWORK BUT MAY BE EXTENDED
C  OR COMPLETELY REPLACED BY INDIVIDUAL PHYSICAL MODELS:
C      1      ==> WATER INJECTION
C      2      ==> OIL PRODUCTION
C      3      ==> WATER PRODUCTION
C      4      ==> GAS PRODUCTION
C      8      ==> GAS INJECTION
C      9      ==> OIL INJECTION

C  WELFILE      = FILE NAME FOR WELL HISTORY OUTPUT FILE

C  WELDEN(t) = WELLBORE DENSITY IN WELL t (LB / CU-FT)

C  WELBHP(t) = WELL BOTTOM HOLE PRESSURE IN WELL t (PSI)

C  DWELBHP(t) = CHANGE IN WELL BOTTOM HOLE PRESSURE IN WELL t

C  DWELDEN(t) = CHANGE IN WELLBORE DENSITY IN WELL t

C  QCOFW(v,s,t) = JACOBIAN COEFFICIENT FOR VARIABLE v IN INTERVAL s
C                 OF t, RATE EQUATION

C  DCOFW(v,s,t) = JACOBIAN COEFFICIENT FOR VARIABLE v IN INTERVAL s
C                 OF WELL t, DENSITY EQUATION

C  VCOFQ(v,s,t) = PRESSURE JACOBIAN COEFFICIENT FOR EQUATION v IN
C                 INTERVAL s OF WELL t

C  VCOFD(v,s,t) = DENSITY JACOBIAN COEFFICIENT FOR EQUATION v IN
C                 INTERVAL s OF WELL t

C  QCOFN(2,t) = JACOBIAN COEFFICIENTS FOR WELBHP AND WELDEN OF WELL t,
C               RATE EQUATION

C  DCOFN(2,t) = JACOBIAN COEFFICIENTS FOR WELBHP AND WELDEN OF WELL t,
C               DENSITY EQUATION

C  QRESID(t) = RESIDUAL FOR RATE EQUATION OF WELL t

C  DRESID(t) = RESIDUAL FOR DENSITY EQUATION OF WELL t

C bag8
C  WELL_ALLOW_SHUTOFF(t) = FLAG TO ALLOW WELL t TO SHUT OFF IF RESERVOIR PRES
C                          GOES BEYOND BHP (SWITCHING INJECTION TO PRODUCTION,
C                          OR VICE VERSA). DEFAULT IS "TRUE".  IF THIS CAUSES
C                          NUMERICAL INSTABILITY, IT MAY BE CONVENIENT TO SET
C                          FLAG TO "FALSE".
