C  RESTC.H - RESTART I/O DATA

      INTEGER NBIN,JAIN,JBIN,KIN,MEIN,MMIN,NERIN,NMODIN
      LOGICAL FORMIN,FORMOUT
      COMMON /RESTC/ NBIN,JAIN,JBIN,KIN,MEIN,MMIN,NERIN,NMODIN,
     &   FORMIN,FORMOUT

C  NBIN  = CURRENT FAULT BLOCK

C  JAIN  = FIRST J VALUE IN DATA SUBSET

C  JBIN  = LAST J VALUE IN DATA SUBSET

C  KIN   = CURRENT K INDEX IN DATA SUBSET

C  MEIN  = CURRENT 4TH INDEX IN DATA SUBSET

C  MMIN  = REMAINING VALUES IN DATA SUBSET

C  NERIN = ERROR FLAG PASSED FROM RESTART WORK ROUTINES

C  NMODIN = PHYSICAL MODEL OF A RESTART ARRAY

C  FORMIN  = .TRUE.  ==> RESTART INPUT FILE IS FORMATED
C          = .FALSE. ==> RESTART INPUT FILE IS UNFORMATED

C  FORMOUT = .TRUE.  ==> RESTART OUTPUT FILE IS FORMATED
C          = .FALSE. ==> RESTART OUTPUT FILE IS UNFORMATED
