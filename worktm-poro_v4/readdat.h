C  READDAT.H - KEY WORD INPUT DATA

      INTEGER LENBLK,LOCBLK,NBLKG,IGLT,JGLT,KGLT,KNDARY,NTYPGA,ND4GA,
     &        KERRGA,NUMRGA,IDIML,JDIML,KDIML
      REAL*8 FACMU,FACAU
      LOGICAL ISUNT,ISUNTD,NOTINDX,NOERASE
      CHARACTER*1 UNTSTD,UNTDEF,VNAMGA
      COMMON /READAT/FACMU,FACAU,ISUNT,ISUNTD,NOERASE,NOTINDX,NBLKG,
     & IGLT,JGLT,KGLT,KNDARY,NTYPGA,ND4GA,KERRGA,NUMRGA,IDIML,JDIML,
     & KDIML,LOCBLK(3000),LENBLK(3000),UNTSTD(60),
     & UNTDEF(60),VNAMGA(60)

C*********************************************************************
C  NOTES:

C  1.  USED DURING KEYWORD INPUT
