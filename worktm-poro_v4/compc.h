C  COMPC.H - WORK SPACE FOR COMP.FOR

      PARAMETER (NUMSL=50, NIRL=30, NSTML=400, NREGRL=10, NDOL=10)

      INTEGER IREG(NIRL),NUMVAL(NUMSL),NUMLOC(NUMSL),VREGR(NREGRL),
     & NUMDO(NDOL),LOCDO(NDOL)
      LOGICAL KDIM,KSTG,LSUBR
      CHARACTER*1 A(NSTML),TAG,STAG,SUB2(9),OPPS(16)

      COMMON /COMPC/NKODU,NKODL,NRU1,NRU2,NREGL,NVU,NVL,NIRU,NRONE,
     & NIFU,NREGR,NSTGU,KDIM,KSTG,NDOU,LSTFUN,LSUBR,N1KVD,NSTGL,NCHRL,
     & IREG,NUMVAL,NUMLOC,VREGR,NUMDO,LOCDO,TAG,STAG,SUB2,OPPS,A