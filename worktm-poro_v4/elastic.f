C CODE HISTORY:
C    TAMEEM ALMANI   07/27/2016 INCLUDE NECESSARY CHANGES FOR
C                               COUPLING WITH MECHANICS
C************************************************************************
      SUBROUTINE EAVERAGE_DISP(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                        KL1,KL2,KEYOUT,NBLK,EDISP,AVGDISP)
C************************************************************************
C Calculate average displacements for a grid block
C DISPOUT = 1  ==> CENTER OF GRID BLOCK
C DISPOUT = 2  ==> TOP OF GRID BLOCK
C DISPOUT = 3  ==> BOTTOM OF GRID BLOCK
C
C INPUT:
C   EDISP(I,J,K,L) = NODAL DISPLACEMENTS (IN)
C
C OUTPUT:
C   AVGDISP(L,I,J,K) = AVERAGE DISPLACEMENTS (FT)
C************************************************************************
      IMPLICIT NONE
      INCLUDE 'emodel.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM), JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  EDISP(IDIM*JDIM*KDIM,3),AVGDISP(IDIM,JDIM,KDIM,*)

      INTEGER I1,I2,I3,J,K,JL1,JL2,KOF,JOF,N1P,N12P,N,L,NDIM,JMAP(8)
      REAL*8  WEIGHT,X,ZERO,ONE
      PARAMETER(ZERO=0.0D0, ONE=1.0D0)

      NDIM = 3
      N1P = IDIM
      N12P = IDIM * JDIM

      IF(DISPOUT.EQ.1) THEN
         JMAP(1) = 0
         JMAP(2) = 1
         JMAP(3) = N1P
         JMAP(4) = N1P + 1
         JMAP(5) = N12P
         JMAP(6) = N12P + 1
         JMAP(7) = N12P + N1P
         JMAP(8) = N12P + N1P + 1
         N = 2**NDIM
      ELSE
         IF(DISPOUT.EQ.2) THEN
            JMAP(1) = 0
            JMAP(2) = N1P
            JMAP(3) = N12P
            JMAP(4) = N12P + N1P
            N = 2**(NDIM-1)
         ELSE
            JMAP(1) = 1
            JMAP(2) = N1P + 1
            JMAP(3) = N12P + 1
            JMAP(4) = N12P + N1P + 1
            N = 2**(NDIM-1)
         ENDIF
      ENDIF

      WEIGHT = ONE/N
      KOF = (KL1 - 2) * N12P
      DO I3 = KL1,KL2
         JL1 = JL1V(I3)
         JL2 = JL2V(I3)
         KOF = KOF + N12P
         JOF = KOF + (JL1 - 2) * N1P
         DO I2 = JL1,JL2
            JOF = JOF + N1P
            J = JOF + IL1 - 1
            DO I1 = IL1,IL2
               J = J + 1
               IF(KEYOUT(I1,I2,I3).LE.0) GO TO 1
               DO L = 1,NDIM
                  X = ZERO
                  AVGDISP(I1,I2,I3,L) = ZERO
                  DO K = 1,N
                     X = X + EDISP(J+JMAP(K),L)
                  ENDDO
                  AVGDISP(I1,I2,I3,L) = WEIGHT * X
               ENDDO
   1           CONTINUE
            ENDDO
         ENDDO
      ENDDO
      END

C*********************************************************************
      SUBROUTINE EPRTDISP(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
     &                   KEYOUT,NBLK,KEYOUT_CR,EDISP)
C*********************************************************************
C Update displacement after each newtonian step
C
C INPUT:
C   KEYOUT_CR(I,J,K) = KEYOUT VALUE FOR A CORNER POINT
C
C OUTPUT:
C   EDISP(L,I,J,K) = NODAL DISPLACEMENTS (IN)
C*********************************************************************

      INCLUDE 'control.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM)
      REAL*8  EDISP(IDIM,JDIM,KDIM,3)
      INTEGER IOFF,JOFF,KOFF,NERR
      INTEGER I,J,K,JL1,JL2,NUMCR
      INTEGER DISPNUM
      CHARACTER*8 DISPNAME

      DISPNUM = 500
         DISPNAME = 'disp_'//CHAR(48+NBLK)//'_'//CHAR(48+NSTEP)
      OPEN(UNIT=DISPNUM,FILE=DISPNAME,STATUS='replace')

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)
      WRITE(DISPNUM,*) 'IOFF=',IOFF,'JOFF=',JOFF,'KOFF=',KOFF
      NUMCR = 0
      DO K = KL1,KL2 + 1
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2 + 1
            DO I = IL1,IL2 + 1
               IF(KEYOUT_CR(I,J,K).GT.0) THEN
                  NUMCR = NUMCR+1
                  WRITE(DISPNUM,*) 'AT I=',I+IOFF,'J=',J+JOFF,
     &                              'K=',K+KOFF
                  WRITE(DISPNUM,*) 'EDISP X Y Z=',EDISP(I,J,K,1),
     &                              EDISP(I,J,K,2),EDISP(I,J,K,3)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      WRITE(DISPNUM,*) 'NUMCR=',NUMCR

      CLOSE(DISPNUM)

      END

C*********************************************************************
      SUBROUTINE EPRTPRES(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,KL2,
     &                   KEYOUT,NBLK,PRES)
C*********************************************************************
C OUTPUT PRESSURE FROM FLOW MODEL
C
C INPUT:
C   PRES(I,J,K) = PRESSURE FROM FLOW MODEL
C*********************************************************************

      INCLUDE 'control.h'
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  PRES(IDIM,JDIM,KDIM)
      INTEGER IOFF,JOFF,KOFF,NERR
      INTEGER I,J,K,JL1,JL2
      INTEGER PRESNUM
      CHARACTER*6 PRESNAME

      IF(NUMPRC.EQ.1) THEN
         PRESNAME = 'PRES_'//CHAR(48+9)
      ELSE
         PRESNAME = 'PRES_'//CHAR(48+MYPRC)
      ENDIF
      OPEN(UNIT=PRESNUM,FILE=PRESNAME,STATUS='replace')

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)
      WRITE(PRESNUM,*) 'AT TIME =',TIM,'DELTIM=',DELTIM
      WRITE(PRESNUM,*) 'IOFF=',IOFF,'JOFF=',JOFF,'KOFF=',KOFF
      DO K = KL1,KL2
         JL1 = JL1V(K)
         JL2 = JL2V(K)
         DO J = JL1,JL2
            DO I = IL1,IL2
               IF(KEYOUT(I,J,K).GT.0) THEN
                  WRITE(PRESNUM,*) 'AT I=',I+IOFF,'J=',J+JOFF,
     &                              'K=',K+KOFF
                  WRITE(PRESNUM,*) 'PRES=',PRES(I,J,K)
               ENDIF
            ENDDO
         ENDDO
      ENDDO
      CLOSE(PRESNUM)

      END

c======================================================================
      SUBROUTINE EGET_GELEI_LSIZE(NERR)
c======================================================================
      IMPLICIT NONE
C
      INCLUDE 'blkary.h'
      INCLUDE 'control.h'
      INCLUDE 'earydat.h'
C
C Assign GELEINDEX(IDIM,JDIM,KDIM,3) AND LSIZE
C
      INTEGER NERR
      INTEGER IGELEI(3)
      EXTERNAL EcalcGELEI
      EXTERNAL EcalcLELEI_LSIZE
      IGELEI(1) = 2
      IGELEI(2) = N_KEYOUT_CR
      IGELEI(3) = N_POROHEX_GELEI

      call callwork(EcalcLELEI_LSIZE,IGELEI)

c      CALL WAITALL()

      call callwork(EcalcGELEI,IGELEI)
      CALL TIMON(38)
      CALL GELEI_UPDATE(N_POROHEX_GELEI)
      CALL TIMOFF(38)

      RETURN
      END


c======================================================================
      SUBROUTINE EcalcLELEI_LSIZE(idim,jdim,kdim,ldim,il1,il2,
     &     jl1v,jl2v,kl1,kl2,keyout,nblk,keyout_cr,geleindex)
c======================================================================
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'hypre.h'

      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),
     &     jl2v(kdim),kl1,kl2,keyout(idim,jdim,kdim),nblk,
     &     keyout_cr(idim,jdim,kdim)
      integer geleindex(idim,jdim,kdim)
      integer i,j,k,ne

      POROHEX_LSIZE = 0
      GELEINDEX = 0
      ne = 0
      do 5 k= 1, kdim
      do 5 j= 1, jdim
      do 5 i= il1, il2+1
         if(keyout_cr(i,j,k).eq.1) then
            ne = ne + 1
            geleindex(i,j,k) = ne
         endif
    5 continue

      POROHEX_LSIZE = NE
      POROHEX_GSIZE = NE

      return
      end


c======================================================================
      SUBROUTINE EcalcGELEI(idim,jdim,kdim,ldim,il1,il2,
     &     jl1v,jl2v,kl1,kl2,keyout,nblk,keyout_cr,geleindex)
c======================================================================
      IMPLICIT NONE
C
C  Input: geleindex for local dof index
C Output: geleindex for global dof index
C   Also, compute common variables: ilower and iupper
C
      include 'mpif.h'
      include 'control.h'
      include 'layout.h'
      include 'hypre.h'
C
      integer idim,jdim,kdim,ldim,il1,il2,jl1v(kdim),
     &     jl2v(kdim),kl1,kl2,keyout(idim,jdim,kdim),nblk,
     &     keyout_cr(idim,jdim,kdim)
      integer geleindex(idim,jdim,kdim)
C
      integer i,j,k,nb, Procsize(1,0:NUMPRC-1),m,ilowvec(0:NUMPRC-1),
     &        GJ,GK,KERR,IOFF,JOFF,KOFF,wsize,IERR
C

c bag8, bw - get value of ilower, iupper, lsize...

      call MPI_ALLGATHER(POROHEX_LSIZE,1,MPI_INTEGER,Procsize,1,
     &                   MPI_INTEGER,MPI_COMM_WORLD,IERR)

      ilowvec = 0
      do i = 0, NUMPRC-1
         wsize = 0
         do m = 0, i-1
            wsize = wsize + Procsize(1,m)
         enddo
         ilowvec(i) = wsize + 1
      enddo
      POROHEX_GSIZE = 0
      DO I=0,NUMPRC-1
         POROHEX_GSIZE=POROHEX_GSIZE+PROCSIZE(1,I)
      ENDDO
      porohex_ilower = ilowvec(myprc)
      porohex_iupper = porohex_ilower + POROHEX_LSIZE -1

C  prcmap(M)
C  M = N0MAP(NUMBLK) + GK * NYMAP(NUMBLK) + GJ
C  NUMBLK = GRID-BLOCK NUMBER
C  GJ = Y INDEX IN THE BLOCK
C  GK = Z INDEX IN THE BLOCK

      do 10 k= 1, kdim
      do 10 j= 1, jdim
      do 10 i= il1, il2+1
         if(keyout_cr(i,j,k).eq.1) then
            geleindex(i,j,k) = geleindex(i,j,k) + porohex_ilower - 1
         endif

   10 CONTINUE
c      WRITE(*,*)'POROHEX_IUPPER=',porohex_iupper
      return
      end

C*********************************************************************
      SUBROUTINE GELEI_UPDATE(N_GELEI)
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'earydat.h'

      INTEGER N_GELEI,ICOMP(5)
      CHARACTER*2 CTYPE
      EXTERNAL ECOMPACT_GELEI,EUNFOLD_GELEI

      ICOMP(1) = 4
      ICOMP(2) = N_GELEI
      ICOMP(3) = N_KEYCR_ELE
      ICOMP(4) = N_KEYOUT_CR
      ICOMP(5) = N_UPDATE_I4

      CALL UPDATE(N_GELEI,2)
      CALL CALLWORK(ECOMPACT_GELEI,ICOMP)
      CALL UPDATE(N_UPDATE_I4,2)
      CALL CALLWORK(EUNFOLD_GELEI,ICOMP)

      END

C*********************************************************************
      SUBROUTINE ENODE_UPDATE(N_ARRAY,CTYPE)
C*********************************************************************
C  SUBROUTINE UPDATE NODAL-BASED ARRAY
C  THIS VERSION SUPPORT UPDATING N_POROHEX_GELEI,N_EDISP,N_ZERO_NODE
C
C  BY BIN WANG, 06/09/2010
      IMPLICIT NONE
      INCLUDE 'earydat.h'

      INTEGER N_ARRAY,ICOMP(5)
      CHARACTER*2 CTYPE
      EXTERNAL ECOMPACTI4,EUNFOLDI4,ECOMPACTR8,EUNFOLDR8,
     &         ECOMPACTFG,EUNFOLDFG

      ICOMP(1) = 4
      ICOMP(2) = N_ARRAY
      ICOMP(3) = N_KEYCR_ELE
      ICOMP(4) = N_KEYOUT_CR
      CALL UPDATE(N_ARRAY,2)


      IF (CTYPE.EQ.'I4') THEN
         ICOMP(5) = N_UPDATE_I4
         CALL CALLWORK(ECOMPACTI4,ICOMP)
         CALL UPDATE(N_UPDATE_I4,2)
         CALL CALLWORK(EUNFOLDI4,ICOMP)
      ELSEIF (CTYPE.EQ.'R8') THEN
         ICOMP(5) = N_UPDATE_R8
         CALL CALLWORK(ECOMPACTR8,ICOMP)
         CALL UPDATE(N_UPDATE_R8,2)
         CALL CALLWORK(EUNFOLDR8,ICOMP)
      ELSEIF (CTYPE.EQ.'FG') THEN
         ICOMP(5) = N_UPDATE_FG
         CALL CALLWORK(ECOMPACTFG,ICOMP)
         CALL UPDATE(N_UPDATE_FG,2)
         CALL CALLWORK(EUNFOLDFG,ICOMP)
      ENDIF


      END


C*********************************************************************
      SUBROUTINE EBUILDKEYCP(KERR)
C*********************************************************************
      IMPLICIT NONE

      INCLUDE 'earydat.h'

      INTEGER IBUILD(3),KERR
      EXTERNAL EBUILDKEYCPW

      IBUILD(1) = 2
      IBUILD(2) = N_KEYOUT_CR
      IBUILD(3) = N_KEYCR_ELE

      CALL CALLWORK(EBUILDKEYCPW,IBUILD)
      CALL UPDATE(N_KEYCR_ELE,2)

      END

C*********************************************************************
      SUBROUTINE EBUILDKEYCPW(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                       KL1, KL2,KEYOUT,NBLK,KEYOUT_CR,KEYCR_ELE)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = KL1,KL2
         DO J = JL1V(K),JL2V(K)
            DO I = IL1,IL2
               IF (KEYOUT(I,J,K).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     KEYCR_ELE(I,J,K,NODE) = KEYOUT_CR(II,JJ,KK)
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE ECOMPACT_GELEI(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &       KL1,KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK
      INTEGER ORIGARR(IDIM,JDIM,KDIM),COMPARR(IDIM,JDIM,KDIM,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (KEYOUT(I,J,K).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     COMPARR(I,J,K,NODE) = ORIGARR(II,JJ,KK)
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE EUNFOLD_GELEI(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &       KL1,KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER I,J,K,L,NODE,II,JJ,KK,ELE,JL1,JL2
      INTEGER ORIGARR(IDIM,JDIM,KDIM),COMPARR(IDIM,JDIM,KDIM,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (abs(KEYOUT(I,J,K)).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     ORIGARR(II,JJ,KK) = COMPARR(I,J,K,NODE)
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE ECOMPACTI4(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &           KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK
      INTEGER ORIGARR(IDIM,JDIM,KDIM,3),COMPARR(IDIM,JDIM,KDIM,3,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (KEYOUT(I,J,K).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     DO L = 1,3
                        COMPARR(I,J,K,L,NODE) = ORIGARR(II,JJ,KK,L)
                     ENDDO
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE EUNFOLDI4(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &           KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER I,J,K,L,NODE,II,JJ,KK,ELE,JL1,JL2
      INTEGER ORIGARR(IDIM,JDIM,KDIM,3),COMPARR(IDIM,JDIM,KDIM,3,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (ABS(KEYOUT(I,J,K)).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     DO L = 1,3
                        ORIGARR(II,JJ,KK,L) = COMPARR(I,J,K,L,NODE)
                     ENDDO
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE ECOMPACTR8(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &           KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK
      REAL*8  ORIGARR(IDIM,JDIM,KDIM,3),COMPARR(IDIM,JDIM,KDIM,3,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = KL1,KL2
         DO J = JL1V(K),JL2V(K)
            DO I = IL1,IL2
               IF (KEYOUT(I,J,K).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     DO L = 1,3
                        COMPARR(I,J,K,L,NODE) = ORIGARR(II,JJ,KK,L)
                     ENDDO
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE EUNFOLDR8(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &           KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK,ELE,JL1,JL2
      REAL*8  ORIGARR(IDIM,JDIM,KDIM,3),COMPARR(IDIM,JDIM,KDIM,3,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
                IF (ABS(KEYOUT(I,J,K)).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     DO L = 1,3
                        ORIGARR(II,JJ,KK,L) = COMPARR(I,J,K,L,NODE)
                     ENDDO
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE ECOMPACTFG(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &           KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK
      LOGICAL ORIGARR(IDIM,JDIM,KDIM),COMPARR(IDIM,JDIM,KDIM,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &            0,0,1, 1,0,1, 0,1,1, 1,1,1/

      DO K = KL1,KL2
         DO J = JL1V(K),JL2V(K)
            DO I = IL1,IL2
               IF (KEYOUT(I,J,K).EQ.1) THEN
                  DO NODE = 1,8
                     II = I+OFFSET(1,NODE)
                     JJ = J+OFFSET(2,NODE)
                     KK = K+OFFSET(3,NODE)
                     COMPARR(I,J,K,NODE) = ORIGARR(II,JJ,KK)
                  ENDDO
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE EUNFOLDFG(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &           KL2,KEYOUT,NBLK,ORIGARR,KEYCR_ELE,KEYOUT_CR,COMPARR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM)
      INTEGER KEYCR_ELE(IDIM,JDIM,KDIM,8)
      INTEGER I,J,K,L,NODE,II,JJ,KK,ELE,JL1,JL2
      LOGICAL ORIGARR(IDIM,JDIM,KDIM),COMPARR(IDIM,JDIM,KDIM,8)
      INTEGER OFFSET(3,8)
      DATA OFFSET/-1,-1,-1,  0,-1,-1,  -1, 0,-1,  0, 0,-1,
     &            -1,-1, 0,  0,-1, 0,  -1, 0, 0,  0, 0, 0/

      DO K = KL2+1,KL1-1,-1
         IF (K.EQ.(KL2+1)) THEN
            JL1 = MIN(JL1V(K),JL1V(K-1))
            JL2 = MAX(JL2V(K),JL2V(K-1))
         ELSEIF (K.EQ.(KL1-1)) THEN
            JL1 = MIN(JL1V(K),JL1V(K+1))
            JL2 = MAX(JL2V(K),JL2V(K+1))
         ELSE
            JL1 = MIN(JL1V(K-1),JL1V(K),JL1V(K+1))
            JL2 = MAX(JL2V(K-1),JL2V(K),JL2V(K+1))
         ENDIF
         DO J = JL2+1,JL1-1,-1
            DO I = IL2+1,IL1,-1
               IF ((KEYOUT_CR(I,J,K).EQ.(-1)).
     &             AND.(KEYOUT(I,J,K).EQ.0)) THEN
                   DO ELE = 1,7
                      II = I+OFFSET(1,ELE)
                      JJ = J+OFFSET(2,ELE)
                      KK = K+OFFSET(3,ELE)
                      IF (KEYOUT(II,JJ,KK).EQ.(-1)) THEN
                         NODE = 9-ELE
                         IF (KEYCR_ELE(II,JJ,KK,NODE).EQ.1) THEN
                            ORIGARR(I,J,K) = COMPARR(II,JJ,KK,NODE)
                            GOTO 100
                         ENDIF
                      ENDIF
                   ENDDO
               ENDIF
 100           CONTINUE
            ENDDO
         ENDDO
      ENDDO

      END

C**********************************************************************
      SUBROUTINE EPRTBDDISP(KERR)
C**********************************************************************
      IMPLICIT NONE
      INCLUDE 'ebdary.h'
      INCLUDE 'earydat.h'

      INTEGER KERR
      INTEGER IPRT(8)
      EXTERNAL EPRTBDDISPW

      IPRT(1) = 7
      IPRT(2) = N_KEYOUT_CR
      IPRT(3) = N_DISPBD(1)
      IPRT(4) = N_DISPBD(2)
      IPRT(5) = N_DISPBD(3)
      IPRT(6) = N_DISPBD(4)
      IPRT(7) = N_DISPBD(5)
      IPRT(8) = N_DISPBD(6)

      CALL CALLWORK(EPRTBDDISPW,IPRT)

      END


C**********************************************************************
      SUBROUTINE EPRTBDDISPW(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                    KL1,KL2,KEYOUT,NBLK,KEYOUT_CR,BDVAL1,BDVAL2,
     &                    BDVAL3,BDVAL4,BDVAL5,BDVAL6)
C**********************************************************************
      IMPLICIT NONE

      INCLUDE 'control.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM)
      REAL*8 BDVAL1(*),BDVAL2(*),BDVAL3(*),BDVAL4(*),BDVAL5(*),
     &       BDVAL6(*)
      INTEGER I,J,K,LOFF,L,NBP,IOFF,JOFF,KOFF,NERR,II

      INTEGER DISPNUM
      CHARACTER*8 DISPNAME

      DISPNUM = 100
      IF(NUMPRC.EQ.1) THEN
         DISPNAME = 'BDDISP_'//CHAR(48+9)
      ELSE
         DISPNAME = 'BDDISP_'//CHAR(48+MYPRC)
      ENDIF
      OPEN(UNIT=DISPNUM,FILE=DISPNAME,STATUS='replace')
      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,NERR)

      WRITE(DISPNUM,*) "IDIM=",IDIM,"JDIM=",JDIM,"KDIM=",KDIM
      WRITE(DISPNUM,*) "IOFF=",IOFF,"JOFF=",JOFF,"KOFF=",KOFF
cbw -X SIDE
      NBP = JDIM*KDIM
      DO L = 1,3
         LOFF = (L-1)*NBP*4
         WRITE(DISPNUM,*) "-X SIDE,DIRECTION=",L
         DO K = 1,KDIM
            DO J = 1,JDIM
               WRITE(DISPNUM,*) "BDVAL1(",J+JOFF,K+KOFF,L,",1 TO 4)=",
     &              (BDVAL1(LOFF+(II-1)*NBP+(K-1)*JDIM+J),II=1,4)
            ENDDO
         ENDDO
      ENDDO

cbw +X SIDE
      NBP = JDIM*KDIM
      DO L = 1,3
         LOFF = (L-1)*NBP*4
         WRITE(DISPNUM,*) "+X SIDE,DIRECTION=",L
         DO K = 1,KDIM
            DO J = 1,JDIM
               WRITE(DISPNUM,*) "BDVAL2(",J+JOFF,K+KOFF,L,"1 TO 4)=",
     &              (BDVAL2(LOFF+(II-1)*NBP+(K-1)*JDIM+J),II=1,4)
            ENDDO
         ENDDO
      ENDDO

cbw -Y SIDE
      NBP = IDIM*KDIM
      DO L = 1,3
         LOFF = (L-1)*NBP*4
         WRITE(DISPNUM,*) "-Y SIDE,DIRECTION=",L
         DO K = 1,KDIM
            DO I = 1,IDIM
               WRITE(DISPNUM,*) "BDVAL3(",I+IOFF,K+KOFF,L,"1 TO 4)=",
     &              (BDVAL3(LOFF+(II-1)*NBP+(K-1)*IDIM+I),II=1,4)
            ENDDO
         ENDDO
      ENDDO

cbw +Y SIDE
      NBP = IDIM*KDIM
      DO L = 1,3
         LOFF = (L-1)*NBP*4
         WRITE(DISPNUM,*) "+Y SIDE,DIRECTION=",L
         DO K = 1,KDIM
            DO I = 1,IDIM
               WRITE(DISPNUM,*) "BDVAL4(",I+IOFF,K+KOFF,L,"1 TO 4)=",
     &              (BDVAL4(LOFF+(II-1)*NBP+(K-1)*IDIM+I),II=1,4)
            ENDDO
         ENDDO
      ENDDO

cbw -Z SIDE
      NBP = IDIM*JDIM
      DO L = 1,3
         LOFF = (L-1)*NBP*4
         WRITE(DISPNUM,*) "-Z SIDE,DIRECTION=",L
         DO J = 1,JDIM
            DO I = 1,IDIM
               WRITE(DISPNUM,*) "BDVAL5(",I+IOFF,J+JOFF,L,"1 TO 4)=",
     &              (BDVAL5(LOFF+(II-1)*NBP+(J-1)*IDIM+I),II=1,4)
            ENDDO
         ENDDO
      ENDDO

cbw +Z SIDE
      NBP = IDIM*JDIM
      DO L = 1,3
         LOFF = (L-1)*NBP*4
         WRITE(DISPNUM,*) "+Z SIDE,DIRECTION=",L
         DO J = 1,JDIM
            DO I = 1,IDIM
               WRITE(DISPNUM,*) "BDVAL6(",I+IOFF,J+JOFF,L,"1 TO 4)=",
     &              (BDVAL6(LOFF+(II-1)*NBP+(J-1)*IDIM+I),II=1,4)
            ENDDO
         ENDDO
      ENDDO

      CLOSE(DISPNUM)

      END

C*********************************************************************
      SUBROUTINE BULKDEN_1PH(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                      KL2,KEYOUT,NBLK,ROCKD,PV,DUNK,BULKDEN,
     &                      EVOL)
C*********************************************************************
C Compute body force for single phase flow model
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  DUNK(IDIM,JDIM,KDIM),       ROCKD(IDIM,JDIM,KDIM)
      REAL*8  BULKDEN(IDIM,JDIM,KDIM),    PV(IDIM,JDIM,KDIM)
      REAL*8  EVOL(IDIM,JDIM,KDIM)

      INTEGER I1,I2,I3,JL1,JL2
      REAL*8  PVOL

      DO I3 = KL1,KL2
         JL1 = JL1V(I3)
         JL2 = JL2V(I3)
         DO I2 = JL1,JL2
            DO I1 = IL1,IL2
               IF(KEYOUT(I1,I2,I3).GT.0) THEN
                  PVOL = PV(I1,I2,I3)
                  BULKDEN(I1,I2,I3)=PVOL*DUNK(I1,I2,I3)/EVOL(I1,I2,I3)
     &                              + ROCKD(I1,I2,I3)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END


ctm
c commented
cC*********************************************************************
c      SUBROUTINE BULKDEN_2PH(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
c     &                      KL2,KEYOUT,NBLK,ROCKD,PV,BULKDEN,EVOL,
c     &                      WDEN,ODEN,SWAT)
cC*********************************************************************
cC Compute body force for single phase flow model
cC*********************************************************************
c      IMPLICIT NONE
c      INCLUDE 'control.h'
c      INCLUDE 'emodel.h'
c
c      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
c      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
c      REAL*8  WDEN(IDIM,JDIM,KDIM),       ODEN(IDIM,JDIM,KDIM),
c     &        ROCKD(IDIM,JDIM,KDIM),      SWAT(IDIM,JDIM,KDIM)
c      REAL*8  BULKDEN(IDIM,JDIM,KDIM),    PV(IDIM,JDIM,KDIM)
c      REAL*8  EVOL(IDIM,JDIM,KDIM)
c
c      INTEGER I1,I2,I3,JL1,JL2
c      REAL*8  PVOL, SATW, SATO, FDEN
c
c      DO I3 = KL1,KL2
c         JL1 = JL1V(I3)
c         JL2 = JL2V(I3)
c         DO I2 = JL1,JL2
c            DO I1 = IL1,IL2
c               IF(KEYOUT(I1,I2,I3).GT.0) THEN
c                  PVOL = PV(I1,I2,I3)
c                  SATW = SWAT(I1,I2,I3)
c                  SATO = 1.D0 - SATW
c                  FDEN = WDEN(I1,I2,I3)*SATW+ODEN(I1,I2,I3)*SATO
c                  BULKDEN(I1,I2,I3)=PVOL*FDEN/EVOL(I1,I2,I3)
c     &                              + ROCKD(I1,I2,I3)
c                  BULKDEN(I1,I2,I3)=BULKDEN(I1,I2,I3)
c               ENDIF
c            ENDDO
c         ENDDO
c      ENDDO
c
c      END

ctm

ctm
C*********************************************************************
      SUBROUTINE BULKDEN_2PH(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                      KL2,KEYOUT,NBLK,ROCKD,PV,BULKDEN,EVOL,
     &                      COIL,CWAT)
C*********************************************************************
C Compute body force for single phase flow model
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  ROCKD(IDIM,JDIM,KDIM),      COIL(IDIM,JDIM,KDIM),
     &        CWAT(IDIM,JDIM,KDIM),    PV(IDIM,JDIM,KDIM),
     &        EVOL(IDIM,JDIM,KDIM), BULKDEN(IDIM,JDIM,KDIM)

      INTEGER I1,I2,I3,JL1,JL2
      REAL*8  PVOL, FDEN

      DO I3 = KL1,KL2
         JL1 = JL1V(I3)
         JL2 = JL2V(I3)
         DO I2 = JL1,JL2
            DO I1 = IL1,IL2
               IF(KEYOUT(I1,I2,I3).GT.0) THEN
                  PVOL = PV(I1,I2,I3)
                  FDEN = COIL(I1,I2,I3)+CWAT(I1,I2,I3)
                  BULKDEN(I1,I2,I3)=PVOL*FDEN/EVOL(I1,I2,I3)
     &                              + ROCKD(I1,I2,I3)
                  BULKDEN(I1,I2,I3)=BULKDEN(I1,I2,I3)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END
ctm



CC*********************************************************************
C      SUBROUTINE BULKDEN_3PH(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C     &                      KL2,KEYOUT,NBLK,BULKDEN,EVOL,ROCK_WEIGHT,
C     &                      PV,EPMD,SAT)
CC*********************************************************************
C      USE xgendat
C      IMPLICIT NONE
C      INCLUDE 'control.h'
C      INCLUDE 'emodel.h'
C      INCLUDE 'xmodel.h'
C      INCLUDE 'xresprop.h'
C      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK,JL1,JL2
C      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
C      REAL*8  ROCK_WEIGHT(IDIM,JDIM,KDIM)
C      REAL*8  BULKDEN(IDIM,JDIM,KDIM), PV(IDIM,JDIM,KDIM)
C      REAL*8  EVOL(IDIM,JDIM,KDIM)
C      REAL*8  EPMD(IDIM,JDIM,KDIM,NCINPH), SAT(IDIM,JDIM,KDIM,NPH)
C      INTEGER I1,I2,I3,IC,LC,IPH
C      REAL*8  SATURA,PVOL,MOLWT,PHDEN(3)
C
C      DO I3 = KL1,KL2
C         JL1 = JL1V(I3)
C         JL2 = JL2V(I3)
C         DO I2 = JL1,JL2
C            DO I1 = IL1,IL2
C               IF(KEYOUT(I1,I2,I3).GT.0) THEN
C                  PVOL = PV(I1,I2,I3)
C                  DO IPH=1,NPH
C                     PHDEN(IPH) = 0.D0
C                     SATURA = SAT(I1,I2,I3,IPH)
C                     DO IC=1,NC
C                        LC=ICINPH(IC,IPH)
C                        IF(LC.EQ. 0) CYCLE
C                        IF(IC.EQ.1) THEN
C                           MOLWT=WATMOLW
C                        ELSE
C                           MOLWT=WMOL(IC-1)
C                        ENDIF
C                        PHDEN(IPH) = PHDEN(IPH) + EPMD(I1,I2,I3,LC)*
C     &                               MOLWT
C                     ENDDO
C                     BULKDEN(I1,I2,I3) = BULKDEN(I1,I2,I3) +
C     &                    PHDEN(IPH)*SATURA*PVOL
C                  ENDDO
C                  BULKDEN(I1,I2,I3) = BULKDEN(I1,I2,I3)/EVOL(I1,I2,I3) +
C     &                    ROCK_WEIGHT(I1,I2,I3)
C               ENDIF
C            ENDDO
C         ENDDO
C      ENDDO
C
C      END

C*********************************************************************
      SUBROUTINE ESETUP_FRAC_PROFILE(NERR)
C*********************************************************************
C SETUP FRACTURE PROFILE
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'fracture.h'
      INCLUDE 'earydat.h'
      INCLUDE 'blkary.h'
      INCLUDE 'hypre.h'

      INTEGER NERR,JFRAC(10)
      EXTERNAL ESETUP_FNODE_TYPE,ESETUP_OFNODE,EFRAC_AFFINE,
     &         ESETUP_CRAC_IBC

      POROHEX_LFALLSIZE=0
      POROHEX_LFSIZE=0
      POROHEX_GFSIZE=0
      POROHEX_IFLOWER=1
      POROHEX_IFUPPER=1
      TOTAL_CRACKED_FACE=0

      IF (NUMFRAC.GT.0) THEN

C SETUP FRACTURE NODE TYPE, FIND OPEN FRACTURE NODE
      JFRAC(1) = 2
      JFRAC(2) = N_KEYOUT_CR
      JFRAC(3) = N_FNODE_TYPE
      CALL CALLWORK(ESETUP_FNODE_TYPE,JFRAC)
      CALL TIMON(38)
      CALL UPDATE(N_FNODE_TYPE,4)
      CALL TIMOFF(38)

C SETUP LOCAL ID FOR OPEN FRACTURE NODE(ACTIVE+GHOST)
C SETUP GLOBAL ID FOR OPEN FRACTURE NODE
      JFRAC(1) = 6
      JFRAC(2) = N_KEYOUT_CR
      JFRAC(3) = N_NODE_LID
      JFRAC(4) = N_FNODE_TYPE
      JFRAC(5) = N_OFNODE_LID
      JFRAC(6) = N_OFNODE_GID
      JFRAC(7) = N_POROHEX_GELEI
      CALL CALLWORK(ESETUP_OFNODE,JFRAC)
      CALL TIMON(38)
      CALL UPDATE(N_OFNODE_GID,4)
      CALL UPDATE(N_POROHEX_GELEI,4)
      CALL TIMOFF(38)
      ENDIF

C CREATE FRACTURE-TYPE ARRAYS
      CALL EFRAC_ARRAY(NERR)

      IF (NUMFRAC.GT.0) THEN
C CREATE MAPPING FROM OPEN FRACTURE NODE TO ITS ASSOCIATED
C    RESERVOIR NODE (LOCAL NODE I,J,K, AND LOCAL NODE ID)
C FIND LOCAL ID FOR ELEMENT WHOSE CONNECTIVITY LIST NEEDS TO
C    BE CHANGED FOR EACH OPEN FRACTURE NODE
      JFRAC(1) = 9
      JFRAC(2) = N_KEYOUT_CR
      JFRAC(3) = N_FNODE_TYPE
      JFRAC(4) = N_ELEM_LID
      JFRAC(5) = N_NODE_LID
      JFRAC(6) = N_OFNODE_LID
      JFRAC(7) = N_OFNODE_GID
      JFRAC(8) = N_OFNODE_AFFINE
      JFRAC(9) = N_OFNODE_KEYOUT
      JFRAC(10) = N_OFNODE_L2GID
      CALL CALLWORK(EFRAC_AFFINE,JFRAC)

C SETUP N_CRAC_IBC
      JFRAC(1) = 2
      JFRAC(2) = N_CRAC_IBC
      JFRAC(3) = N_ELEM_LID
      CALL CALLWORK(ESETUP_CRAC_IBC,JFRAC)
      ENDIF

      END

C*********************************************************************
      SUBROUTINE ESETUP_FNODE_TYPE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                      JL2V,KL1,KL2,KEYOUT,NBLK,KEYOUT_CR,
     &                      FNODE_TYPE)
C*********************************************************************
C SETUP FNODE_TYPE FOR IDENTIFYING OPEN FRACTURE NODES
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'fracture.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM),  FNODE_TYPE(IDIM,JDIM,KDIM)
      INTEGER FOFFSET(3,4,6),OFFSET(3,8),FACE_NODE(4,6),NB_ELEM(3,8)
      DATA    OFFSET /0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &                0,0,1, 1,0,1, 0,1,1, 1,1,1/
      DATA    FACE_NODE /1,3,7,5,  2,4,8,6,
     &                   1,5,6,2,  3,7,8,4,
     &                   1,2,4,3,  5,6,8,7/
      DATA    NB_ELEM /-1,-1,-1,   0,-1,-1,
     &                 -1, 0,-1,   0, 0,-1,
     &                 -1,-1, 0,   0,-1, 0,
     &                 -1, 0, 0,   0, 0, 0/

      INTEGER FRAC,FACE,I,J,K,II,JJ,KK,IOFF,JOFF,KOFF,KERR,NODE,
     &        IFACE,TNBELEM,ELEM,JL1,JL2,IM,JM,KM,IFACE2
      LOGICAL ELEIN

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,KERR)

      FNODE_TYPE = 0

      DO FACE = 1,6
         DO NODE = 1,4
            FOFFSET(1,NODE,FACE)=OFFSET(1,FACE_NODE(NODE,FACE))
            FOFFSET(2,NODE,FACE)=OFFSET(2,FACE_NODE(NODE,FACE))
            FOFFSET(3,NODE,FACE)=OFFSET(3,FACE_NODE(NODE,FACE))
         ENDDO
      ENDDO

      TOTAL_CRACKED_FACE=0
      DO FRAC = 1,NUMFRAC
         DO FACE = 1,NUMFRACFACE(FRAC)
            IF (FRACFACEPROC(FACE,FRAC).EQ.0) CYCLE
            TOTAL_CRACKED_FACE=TOTAL_CRACKED_FACE+1
            I = FRACFACE(1,FACE,FRAC)-IOFF
            J = FRACFACE(2,FACE,FRAC)-JOFF
            K = FRACFACE(3,FACE,FRAC)-KOFF
            IFACE = FRACFACE(4,FACE,FRAC)
            IM=I
            JM=J
            KM=K
            IF (IFACE.EQ.1) THEN
               IM=I-1
               IFACE2=2
            ENDIF
            IF (IFACE.EQ.2) THEN
               IM=I+1
               IFACE2=1
            ENDIF
            IF (IFACE.EQ.3) THEN
               JM=J-1
               IFACE2=4
            ENDIF
            IF (IFACE.EQ.4) THEN
               JM=J+1
               IFACE2=3
            ENDIF
            IF (IFACE.EQ.5) THEN
               KM=K-1
               IFACE2=6
            ENDIF
            IF (IFACE.EQ.6) THEN
               KM=K+1
               IFACE2=5
            ENDIF
            IF (KEYOUT(I,J,K).EQ.1 .OR. KEYOUT(I,J,K).EQ.-1) THEN
               DO NODE = 1,4
                  II=I+FOFFSET(1,NODE,IFACE)
                  JJ=J+FOFFSET(2,NODE,IFACE)
                  KK=K+FOFFSET(3,NODE,IFACE)
                  IF(KEYOUT_CR(II,JJ,KK).EQ.1) THEN
                    FNODE_TYPE(II,JJ,KK)=FNODE_TYPE(II,JJ,KK)+1
                  ENDIF
               ENDDO
            ELSEIF (KEYOUT(IM,JM,KM).EQ.1 .OR.
     &             KEYOUT(IM,JM,KM).EQ.-1) THEN
               DO NODE = 1,4
                  II=IM+FOFFSET(1,NODE,IFACE2)
                  JJ=JM+FOFFSET(2,NODE,IFACE2)
                  KK=KM+FOFFSET(3,NODE,IFACE2)
                  IF(KEYOUT_CR(II,JJ,KK).EQ.1) THEN
                    FNODE_TYPE(II,JJ,KK)=FNODE_TYPE(II,JJ,KK)+1
                  ENDIF
               ENDDO
            ENDIF
         ENDDO
      ENDDO

! FIND FRACTURE NODE AT BOUNDARY, SET AS OPEN FRACTURE NODE
      DO K=KL1-1,KL2+1
         JL1=MIN(JL1V(K-1),JL1V(K),JL1V(k+1))
         JL2=MAX(JL2V(K-1),JL2V(K),JL2V(k+1))
         DO J=JL1-1,JL2+1
            DO I=IL1,IL2+1
               IF(KEYOUT_CR(I,J,K).EQ.1) THEN
                 IF(FNODE_TYPE(I,J,K).GT.4) THEN
                   WRITE(*,10) I+IOFF,J+JOFF,K+KOFF
                   WRITE(NFOUT,10) I+IOFF,J+JOFF,K+KOFF
                   STOP 13
                 ENDIF
                 IF(FNODE_TYPE(I,J,K).EQ.4) CYCLE
                 IF(FNODE_TYPE(I,J,K).LE.1) CYCLE
                 TNBELEM=0
                 DO ELEM=1,8
                    II=I+NB_ELEM(1,ELEM)
                    JJ=J+NB_ELEM(2,ELEM)
                    KK=K+NB_ELEM(3,ELEM)
                    IF((II.GE.1 .AND. II.LE.IDIM) .AND.
     &                 (JJ.GE.1 .AND. JJ.LE.JDIM) .AND.
     &                 (KK.GE.1 .AND. KK.LE.KDIM)) THEN
                       IF(KEYOUT(II,JJ,KK).NE.0) THEN
                         TNBELEM=TNBELEM+1
                       ENDIF
                    ENDIF
                 ENDDO
                 IF(TNBELEM.LT.8) THEN
                   FNODE_TYPE(I,J,K)=4
                 ENDIF
               ENDIF
            ENDDO
         ENDDO
      ENDDO

 10   FORMAT(/,'ERROR: MORE THAN 4 FRACFACE SHARING NODE('
     &       ,I5,1X,I5,1X,I5,')',/,'CHECK FRACFACE INPUT!')
      END


C*********************************************************************
      SUBROUTINE ESETUP_OFNODE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                      JL2V,KL1,KL2,KEYOUT,NBLK,KEYOUT_CR,
     &                      NODE_LID,FNODE_TYPE,OFNODE_LID,OFNODE_GID,
     &                      GELEINDEX)
C*********************************************************************
C SETUP LOCAL AND GLOBAL ID FOR OPEN FRACTURE NODES
C UPDATE GLOBAL ID FOR REGULAR RESERVOIR NODE
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'fracture.h'
      INCLUDE 'mpif.h'
      INCLUDE 'hypre.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM),  FNODE_TYPE(IDIM,JDIM,KDIM)
      INTEGER OFNODE_LID(IDIM,JDIM,KDIM), OFNODE_GID(IDIM,JDIM,KDIM)
      INTEGER NODE_LID(IDIM,JDIM,KDIM)
      INTEGER GELEINDEX(IDIM,JDIM,KDIM)

      INTEGER I,J,K,CTR1,CTR2,KERR
      INTEGER PROCSIZE(1,0:NUMPRC-1), ILOWVEC(0:NUMPRC-1)
      INTEGER FRAC,FACE,IFACE,IM,JM,KM,IFACE2,NODE,II,JJ,KK,NNEIGH
      INTEGER FOFFSET(3,4,6),OFFSET(3,8),FACE_NODE(4,6),NB_ELEM(3,8)
      DATA    OFFSET /0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &                0,0,1, 1,0,1, 0,1,1, 1,1,1/
      DATA    FACE_NODE /1,3,7,5,  2,4,8,6,
     &                   1,5,6,2,  3,7,8,4,
     &                   1,2,4,3,  5,6,8,7/
      DATA    NB_ELEM /-1,-1,-1,   0,-1,-1,
     &                 -1, 0,-1,   0, 0,-1,
     &                 -1,-1, 0,   0,-1, 0,
     &                 -1, 0, 0,   0, 0, 0/
      LOGICAL ELEIN
      INTEGER IOFF,JOFF,KOFF

      OFNODE_LID = 0
      OFNODE_GID = 0
      CTR1 = 0
      CTR2 = 0

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,KERR)

      DO FACE = 1,6
         DO NODE = 1,4
            FOFFSET(1,NODE,FACE)=OFFSET(1,FACE_NODE(NODE,FACE))
            FOFFSET(2,NODE,FACE)=OFFSET(2,FACE_NODE(NODE,FACE))
            FOFFSET(3,NODE,FACE)=OFFSET(3,FACE_NODE(NODE,FACE))
         ENDDO
      ENDDO

!BW RULE OUT OPEN FRACTURE NODES ATTACHED TO ELEMENTS NOT INCLUDED
!   IN THE LOCAL SYSTEM
      DO FRAC = 1,NUMFRAC
         DO FACE = 1,NUMFRACFACE(FRAC)
            I = FRACFACE(1,FACE,FRAC)-IOFF
            J = FRACFACE(2,FACE,FRAC)-JOFF
            K = FRACFACE(3,FACE,FRAC)-KOFF
            IFACE = FRACFACE(4,FACE,FRAC)
            IM=I
            JM=J
            KM=K
            IFACE2=IFACE
            IF (IFACE.EQ.1) THEN
               IM=I-1
               IFACE2=2
            ENDIF
            IF (IFACE.EQ.3) THEN
               JM=J-1
               IFACE2=4
            ENDIF
            IF (IFACE.EQ.5) THEN
               KM=K-1
               IFACE2=6
            ENDIF
            IF (ELEIN(IM,JM,KM,IDIM,JDIM,KDIM)) THEN
               IF (KEYOUT(IM,JM,KM).EQ.-2) THEN
                  DO NODE = 1,4
                     II=IM+FOFFSET(1,NODE,IFACE2)
                     JJ=JM+FOFFSET(2,NODE,IFACE2)
                     KK=KM+FOFFSET(3,NODE,IFACE2)
                     IF(FNODE_TYPE(II,JJ,KK).EQ.4) THEN
                        NNEIGH=0
                        IF (IFACE2.EQ.2) THEN
                           IF (IABS(KEYOUT(II-1,JJ-1,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II-1,JJ,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II-1,JJ-1,KK)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II-1,JJ,KK)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                        ELSEIF (IFACE2.EQ.4) THEN
                           IF (IABS(KEYOUT(II-1,JJ-1,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II,JJ-1,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II-1,JJ-1,KK)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II,JJ-1,KK)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                        ELSEIF (IFACE2.EQ.6) THEN
                           IF (IABS(KEYOUT(II-1,JJ-1,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II,JJ-1,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II-1,JJ,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                           IF (IABS(KEYOUT(II,JJ,KK-1)).EQ.1) THEN
                              NNEIGH=1
                           ENDIF
                        ENDIF
                        IF (NNEIGH.EQ.0) FNODE_TYPE(II,JJ,KK)=0
                     ENDIF
                  ENDDO
               ENDIF
            ENDIF
         ENDDO
      ENDDO

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = IL1,IL2+1
               IF (NODE_LID(I,J,K).GT.0) THEN
                 IF (FNODE_TYPE(I,J,K).EQ.4) THEN
                   CTR1=CTR1+1
                   OFNODE_LID(I,J,K)=CTR1
                   IF(KEYOUT_CR(I,J,K).EQ.1) THEN
                     CTR2=CTR2+1
                     OFNODE_GID(I,J,K)=CTR2
                   ENDIF
                 ENDIF
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      POROHEX_LFALLSIZE=CTR1 ! TOTAL LOCAL OPEN FRACTURE NODE
      POROHEX_LFSIZE=CTR2    ! TOTAL LOCAL ACTIVE OPEN FRACTURE NODE

!UPDATE GLOBAL OPEN FRACTURE NODE ID ACROSS ALL PROCESSORS

      PROCSIZE=0
      ILOWVEC=0
      CALL MPI_ALLGATHER(POROHEX_LFSIZE,1,MPI_INTEGER,PROCSIZE,1,
     &                   MPI_INTEGER,MPI_COMM_WORLD,KERR)

      DO I=0,NUMPRC-1
         CTR1=0
         DO J=0,I-1
            CTR1=CTR1+PROCSIZE(1,J)
         ENDDO
         ILOWVEC(I)=CTR1+1
      ENDDO

      POROHEX_ILOWER=POROHEX_ILOWER+ILOWVEC(MYPRC)-1
      POROHEX_IUPPER=POROHEX_IUPPER+ILOWVEC(MYPRC)-1+POROHEX_LFSIZE

      POROHEX_IFLOWER=ILOWVEC(MYPRC)
      POROHEX_IFUPPER=POROHEX_IFLOWER+POROHEX_LFSIZE-1

! UPDATE GLOBAL ID FOR OPEN FRACTURE NODE
      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = IL1,IL2+1
               IF(OFNODE_GID(I,J,K).GT.0) THEN
                 OFNODE_GID(I,J,K)=OFNODE_GID(I,J,K)+POROHEX_ILOWER-1
     &                                              +POROHEX_LSIZE
               ENDIF
            ENDDO
         ENDDO
      ENDDO

!UPDATE GLOBAL ID FOR ACTIVE RESERVOIR NODE
      DO K= 1, KDIM
         DO J= 1, JDIM
            DO I= IL1, IL2+1
               IF(KEYOUT_CR(I,J,K).EQ.1) THEN
                  GELEINDEX(I,J,K)=GELEINDEX(I,J,K)+ILOWVEC(MYPRC)-1
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      POROHEX_GFSIZE=0
      DO I=0,NUMPRC-1
         POROHEX_GFSIZE=POROHEX_GFSIZE+PROCSIZE(1,I)
      ENDDO

      END


C*********************************************************************
      SUBROUTINE EFRAC_AFFINE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                      JL2V,KL1,KL2,KEYOUT,NBLK,KEYOUT_CR,
     &                      FNODE_TYPE,ELEM_LID,NODE_LID,OFNODE_LID,
     &                      OFNODE_GID,OFNODE_AFFINE,OFNODE_KEYOUT,
     &                      OFNODE_L2GID)
C*********************************************************************
C N_OFNODE_AFFINE(1:3,LFALLSIZE) = RESERVOIR NODE (I,J,K) ASSOCIATED WITH
C                                  LOCAL OPEN FRACTURE NODE
C N_OFNODE_AFFINE(4,LFALLSIZE) = LOCAL RESERVOIR NODE ID ASSOCIATED WITH
C                                  LOCAL OPEN FRACTURE NODE
C N_OFNODE_AFFINE(5,LFALLSIZE) = NUMBER OF LOCAL ELEMENTS ASSOCIATED WITH
C                                  LOCAL OPEN FRACTURE NODE
C N_OFNODE_AFFINE(6:9,LFALLSIZE) = LOCAL ELEMENT ID ASSOCIATED WITH
C                                  LOCAL OPEN FRACTURE NODE WHOSE CONNECTIVITY
C                                  LIST NEEDS TO BE CHANGED
C N_OFNODE_KEYOUT(1:LFALLSIZE) = KEYOUT ARRAY FOR LOCAL OPEN FRACTURE NODE
C N_OFNODE_L2GID(1:LFALLSIZE) = LOCAL OPEN FRACTURE ID TO GLOBAL NODE ID
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'fracture.h'
      INCLUDE 'hypre.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM),  FNODE_TYPE(IDIM,JDIM,KDIM)
      INTEGER ELEM_LID(IDIM,JDIM,KDIM),   NODE_LID(IDIM,JDIM,KDIM)
      INTEGER OFNODE_LID(IDIM,JDIM,KDIM), OFNODE_GID(IDIM,JDIM,KDIM)
      INTEGER OFNODE_AFFINE(9,POROHEX_LFALLSIZE)
      INTEGER OFNODE_KEYOUT(POROHEX_LFALLSIZE)
      INTEGER OFNODE_L2GID(POROHEX_LFALLSIZE)
      INTEGER FOFFSET(3,4,6),OFFSET(3,8),FACE_NODE(4,6),NB_ELEM(3,8)
      DATA    OFFSET /0,0,0, 1,0,0, 0,1,0, 1,1,0,
     &                0,0,1, 1,0,1, 0,1,1, 1,1,1/
      DATA    FACE_NODE /1,3,7,5,  2,4,8,6,
     &                   1,5,6,2,  3,7,8,4,
     &                   1,2,4,3,  5,6,8,7/
      DATA    NB_ELEM /-1,-1,-1,   0,-1,-1,
     &                 -1, 0,-1,   0, 0,-1,
     &                 -1,-1, 0,   0,-1, 0,
     &                 -1, 0, 0,   0, 0, 0/
      LOGICAL ELEIN

      INTEGER FRAC,FACE,I,J,K,II,JJ,KK,IOFF,JOFF,KOFF,KERR,NODE,
     &        IFACE,ELEM,JL1,JL2,OFNODE,I1,J1,K1,EID,CTR1,IM,JM,KM,
     &        IFACE2,IFACE3

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,KERR)
      OFNODE_AFFINE=0
      OFNODE_KEYOUT=0

      DO FACE = 1,6
         DO NODE = 1,4
            FOFFSET(1,NODE,FACE)=OFFSET(1,FACE_NODE(NODE,FACE))
            FOFFSET(2,NODE,FACE)=OFFSET(2,FACE_NODE(NODE,FACE))
            FOFFSET(3,NODE,FACE)=OFFSET(3,FACE_NODE(NODE,FACE))
         ENDDO
      ENDDO

      DO FRAC=1,NUMFRAC
         DO FACE=1,NUMFRACFACE(FRAC)
            IM = FRACFACE(1,FACE,FRAC)-IOFF
            JM = FRACFACE(2,FACE,FRAC)-JOFF
            KM = FRACFACE(3,FACE,FRAC)-KOFF
            IFACE2 = FRACFACE(4,FACE,FRAC)

            I=IM
            J=JM
            K=KM
            IFACE=IFACE2

            IF (IFACE2.EQ.1) THEN
               I=IM-1
               IFACE=2
            ENDIF
            IF (IFACE2.EQ.3) THEN
               J=JM-1
               IFACE=4
            ENDIF
            IF (IFACE2.EQ.5) THEN
               K=KM-1
               IFACE=6
            ENDIF

            IF (IFACE.EQ.2) IFACE3=1
            IF (IFACE.EQ.4) IFACE3=3
            IF (IFACE.EQ.6) IFACE3=5

            IF (ELEIN(I,J,K,IDIM,JDIM,KDIM)) THEN
               IF (ELEM_LID(I,J,K).GT.0) THEN
                  DO NODE = 1,4
                     II=I+FOFFSET(1,NODE,IFACE)
                     JJ=J+FOFFSET(2,NODE,IFACE)
                     KK=K+FOFFSET(3,NODE,IFACE)
                     IF(FNODE_TYPE(II,JJ,KK).EQ.4 .AND.
     &                  NODE_LID(II,JJ,KK).GT.0) THEN
                       FNODE_TYPE(II,JJ,KK)=-4
                       OFNODE=OFNODE_LID(II,JJ,KK)
                       OFNODE_AFFINE(1,OFNODE)=II
                       OFNODE_AFFINE(2,OFNODE)=JJ
                       OFNODE_AFFINE(3,OFNODE)=KK
                       OFNODE_AFFINE(4,OFNODE)=NODE_LID(II,JJ,KK)
                       CTR1=0
                       DO ELEM=1,4
                          EID=FACE_NODE(ELEM,IFACE3)
                          I1=II+NB_ELEM(1,EID)
                          J1=JJ+NB_ELEM(2,EID)
                          K1=KK+NB_ELEM(3,EID)
                          IF(ELEM_LID(I1,J1,K1).GT.0) THEN
                            CTR1=CTR1+1
                            OFNODE_AFFINE(CTR1+5,OFNODE)
     &                               =ELEM_LID(I1,J1,K1)
                          ENDIF
                       ENDDO
                       OFNODE_AFFINE(5,OFNODE)=CTR1
                       OFNODE_KEYOUT(OFNODE)=KEYOUT_CR(II,JJ,KK)
                       OFNODE_L2GID(OFNODE)=OFNODE_GID(II,JJ,KK)
                     ENDIF
                  ENDDO
               ENDIF
            ENDIF
         ENDDO
      ENDDO

C RESTORE FNODE_TYPE ARRAY AFTER TEMPORORY USE
      DO K=1,KDIM
         DO J=1,JDIM
            DO I=IL1,IL2+1
               IF(FNODE_TYPE(I,J,K).EQ.-4) THEN
                 FNODE_TYPE(I,J,K)=4
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE ESETUP_CRAC_IBC(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                      JL2V,KL1,KL2,KEYOUT,NBLK,CRAC_IBC,
     &                      ELEM_LID)
C*********************************************************************
C
C*********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'fracture.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      INTEGER ELEM_LID(IDIM,JDIM,KDIM)
      REAL*8  CRAC_IBC(3,TOTAL_CRACKED_FACE)
      INTEGER FRAC,FACE,I,J,K,IOFF,JOFF,KOFF,KERR

      CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,KERR)

      TOTAL_CRACKED_FACE=0
      DO FRAC = 1, NUMFRAC
         DO FACE = 1, NUMFRACFACE(FRAC)
            I = FRACFACE(1,FACE,FRAC) - IOFF
            J = FRACFACE(2,FACE,FRAC) - JOFF
            K = FRACFACE(3,FACE,FRAC) - KOFF
            IF (FRACFACEPROC(FACE,FRAC).EQ.0) CYCLE
            TOTAL_CRACKED_FACE=TOTAL_CRACKED_FACE+1
            IF(ELEM_LID(I,J,K).LE.0) CYCLE
            CRAC_IBC(1,TOTAL_CRACKED_FACE) = ELEM_LID(I,J,K)
            CRAC_IBC(2,TOTAL_CRACKED_FACE) = FRACFACE(4,FACE,FRAC)
            CRAC_IBC(3,TOTAL_CRACKED_FACE) = PFN(FACE,FRAC)   !bw
         ENDDO
      ENDDO

      END


C======================================================================
      SUBROUTINE HYPRE_POROHEX(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &     KL1,KL2,KEYOUT,NBLK,KEYOUT_CR,GELEINDEX,GSTIFF,
     &     GSTIFF_ROW_INDEX,GSTIFF_COL_INDEX,ACTIVE_NODE,RESIDUE,
     &     TL_LOAD,NODE_ST_DOF,NODE_ST_GDOF,ROWS,OFNODE_DISP,
     &     OFNODE_DISP_TMP,OFNODE_KEYOUT,NNTIM,TL_NONZERO,NODE_TL,
     &     OFNODE_GNUM,OFNODE_GNUM_TMP,OFNODE_L2GID)
C======================================================================
      IMPLICIT NONE

      INCLUDE 'control.h'
      INCLUDE 'mpif.h'
      INCLUDE 'emodel.h'
      INCLUDE 'hypre.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM),GELEINDEX(IDIM,JDIM,KDIM)
      INTEGER NNTIM,TL_NONZERO,NODE_TL
      REAL*8  GSTIFF(TL_NONZERO),
     &        OFNODE_DISP(3,POROHEX_GFSIZE),RESIDUE(NODE_TL*3),
     &        TL_LOAD(NODE_TL*3),OFNODE_DISP_TMP(3,POROHEX_GFSIZE)
      INTEGER GSTIFF_ROW_INDEX(NODE_TL*3+1),GSTIFF_COL_INDEX(TL_NONZERO)
      INTEGER ACTIVE_NODE(NODE_TL),NODE_ST_DOF(NODE_TL),
     &        NODE_ST_GDOF(NODE_TL),ROWS(NODE_TL*3),
     &        OFNODE_KEYOUT(POROHEX_LFALLSIZE),
     &        OFNODE_GNUM(POROHEX_GFSIZE),
     &        OFNODE_GNUM_TMP(POROHEX_GFSIZE),
     &        OFNODE_L2GID(POROHEX_LFALLSIZE)

      INTEGER IERR
      INTEGER IROW, NNZ,INROW,III,LOOP
      INTEGER COLS(243)
      DOUBLE PRECISION VALUES(243)
      INTEGER NUM_ITERATIONS
      DOUBLE PRECISION FINAL_RES_NORM

      INTEGER I,J,K,LROW,LCOL,COL1,COL2,COL3,CTR,COLIND,DIR,NODE
      INTEGER HILOWER,HIUPPER,HLSIZE,BUFSIZE
      INTEGER tmpNROWS,tmpNCOLS(3),tmpROWS(3),tmpCOLS(3)
      REAL*8 tmpVALUES(3)

c bag8 moved from emodel.dh
      INTEGER*8  MATRIX_A, PAR_A, EPRECOND, ESOLVER
      COMMON /PEHYPRE/MATRIX_A, PAR_A, EPRECOND, ESOLVER
      INTEGER*8  GOT_PRECOND

      CALL TIMON(37)

      HILOWER=(POROHEX_ILOWER-1)*3+1
      HIUPPER=POROHEX_IUPPER*3
      HLSIZE=3*(POROHEX_LSIZE+POROHEX_LFSIZE)

C SKIP STIFFNESS MATRIX ASSEMBLING AND SOLVER/PRECONDITIONER SETUP
C STAGE IF NOT IN INITIALIZATION

      IF (NNTIM.EQ.1) GOTO 500
      IF (NNTIM.EQ.2) GOTO 600

C SETUP GLOBAL ID ARRAY ASSOCIATED WITH OFNODE_DISP

      OFNODE_GNUM=0
      CTR=0
      DO I=1,POROHEX_LFALLSIZE
         IF (OFNODE_KEYOUT(I).EQ.1) THEN
            CTR=CTR+1
            NODE=POROHEX_IFLOWER+CTR-1
            OFNODE_GNUM(NODE)=OFNODE_L2GID(I)
         ENDIF
      ENDDO
      IF (CTR.NE.POROHEX_LFSIZE) THEN
         WRITE(*,*) "ERROR IN HYPRE_POROHEX"
         STOP 13
      ENDIF

! UPDATE OFNODE_GNUM ACROSS ALL PROCESSORS
      CALL TIMON(38)
      IF (NUMPRC.GT.1 .AND. POROHEX_GFSIZE .GT. 0) THEN
         OFNODE_GNUM_TMP=0
         CALL MPI_ALLREDUCE(OFNODE_GNUM,OFNODE_GNUM_TMP,POROHEX_GFSIZE,
     &                      MPI_INTEGER,MPI_SUM,MPI_COMM_WORLD,IERR)

         OFNODE_GNUM=OFNODE_GNUM_TMP
      ENDIF
      CALL TIMOFF(38)

C INITIALIZE TOTAL NUMBER OF LINEAR ITERATION FOR POROELASTICITY MODEL
      POROHEXLINT = 0

      MATRIX_A = 0
      PAR_A = 0
      EPRECOND = 0
      GOT_PRECOND = 0
      ESOLVER = 0
      B = 0
      X = 0
      PAR_B = 0
      PAR_X = 0

C     CREATE THE MATRIX.
C     NOTE THAT THIS IS A SQUARE MATRIX, SO WE INDICATE THE ROW PARTITION
C     SIZE TWICE (SINCE NUMBER OF ROWS = NUMBER OF COLS)

      CALL TIMON(39)
      CALL HYPRE_IJMATRIXCREATE( MPI_COMM_WORLD, HILOWER,
     &     HIUPPER, HILOWER, HIUPPER, MATRIX_A, IERR )

C     CHOOSE A PARALLEL CSR FORMAT STORAGE (SEE THE USER''S MANUAL)
      CALL HYPRE_IJMATRIXSETOBJECTTYPE( MATRIX_A, HYPRE_PARCSR, IERR)

C     INITIALIZE BEFORE SETTING COEFFICIENTS
      CALL HYPRE_IJMATRIXINITIALIZE( MATRIX_A, IERR)

C SET MATRIX VALUES FROM GSTIFF
      DO I = 1,NODE_TL
         IF (ACTIVE_NODE(I).EQ.1) THEN
            DO J = 1,3
               COLS=0
               VALUES=0.D0
               LROW=NODE_ST_DOF(I)+J-1
               IROW=NODE_ST_GDOF(I)+J-1
               COL1=GSTIFF_ROW_INDEX(LROW)
               COL2=GSTIFF_ROW_INDEX(LROW+1)-1
               NNZ=COL2-COL1+1
               CTR=0
               DO K=COL1,COL2
                  CTR=CTR+1
                  COLIND=GSTIFF_COL_INDEX(K)
                  NODE=COLIND/3+1
                  DIR=MOD(COLIND,3)
                  IF (DIR.EQ.0) THEN
                     NODE=NODE-1
                     DIR = 3
                  ENDIF
                  COL3=NODE_ST_GDOF(NODE)+DIR-1
                  COLS(CTR)=COL3
                  VALUES(CTR)=GSTIFF(K)
               ENDDO
               CALL HYPRE_IJMATRIXSETVALUES(
     &              MATRIX_A, 1, NNZ, IROW, COLS, VALUES, IERR)
            ENDDO
         ENDIF
      ENDDO
C     ASSEMBLE AFTER SETTING THE COEFFICIENTS
      CALL HYPRE_IJMATRIXASSEMBLE( MATRIX_A, IERR)

C     GET PARCSR MATRIX OBJECT
      CALL HYPRE_IJMATRIXGETOBJECT( MATRIX_A, PAR_A, IERR)
      CALL TIMOFF(39)

C     CREATE THE RHS AND SOLUTION
      CALL TIMON(41)
      CALL HYPRE_IJVECTORCREATE(MPI_COMM_WORLD,
     &     HILOWER, HIUPPER, B, IERR )
      CALL HYPRE_IJVECTORSETOBJECTTYPE(B, HYPRE_PARCSR, IERR)
      CALL HYPRE_IJVECTORINITIALIZE(B, IERR)

      CALL HYPRE_IJVECTORCREATE(MPI_COMM_WORLD,
     &     HILOWER, HIUPPER, X, IERR )
      CALL HYPRE_IJVECTORSETOBJECTTYPE(X, HYPRE_PARCSR, IERR)
      CALL HYPRE_IJVECTORINITIALIZE(X, IERR)

      DO INROW = 1, HLSIZE
         ROWS(INROW) = HILOWER + INROW -1
      ENDDO

C SET RHS TO BE ZERO (INITIALIZATION)
      TL_LOAD = 0.D0

      CALL HYPRE_IJVECTORSETVALUES(
     &     B, HLSIZE, ROWS, TL_LOAD, IERR)
      CALL HYPRE_IJVECTORSETVALUES(
     &     X, HLSIZE, ROWS, TL_LOAD, IERR)

      CALL HYPRE_IJVECTORASSEMBLE( B, IERR)
      CALL HYPRE_IJVECTORASSEMBLE( X, IERR)

C GET THE X AND B OBJECTS

      CALL HYPRE_IJVECTORGETOBJECT( B, PAR_B, IERR)
      CALL HYPRE_IJVECTORGETOBJECT( X, PAR_X, IERR)
      CALL TIMOFF(41)

! bag8 debug
      IF ((MYPRC.EQ.0).AND.(PRINT_LEVEL.GT.0)) THEN
        WRITE(*,*)'HYPRE_SOL_ID=',HYPRE_SOL_ID
        WRITE(*,*)'PRECOND_ID=',PRECOND_ID
        WRITE(*,*)'LSOL_TOL=',LSOL_TOL
        WRITE(*,*)'LSOL_ITMAX=',LSOL_ITMAX
        WRITE(*,*)'K_DIM=',K_DIM
        WRITE(*,*)'COARSEN_TYPE=',COARSEN_TYPE
        WRITE(*,*)'MEASURE_TYPE=',MEASURE_TYPE
        WRITE(*,*)'STRONG_THRES=',STRONG_THRES
        WRITE(*,*)'TRUNC_FACTOR=',TRUNC_FACTOR
        WRITE(*,*)'CYCLE_TYPE=',CYCLE_TYPE
        WRITE(*,*)'RELAX_TYPE=',RELAX_TYPE
        WRITE(*,*)'MAX_LEVELS=',MAX_LEVELS
      ENDIF

C SETUP SOLVER/PRECONDITIONER IN THE INITIALIZATION STAGE, NO NEED TO
C REDO THESE FOR EACH TIME STEP IN ISOTROPIC LINEAR ELASTICITY MODEL
C BECAUSE STIFFNESS MATRIX IS CONSTANT

C     CHOOSE A SOLVER AND SOLVE THE SYSTEM
      CALL TIMON(40)
C     AMG
      IF ( HYPRE_SOL_ID .EQ. 0 ) THEN
c         LSOL_ITMAX = 500
c         STRONG_THRESHOLD = 0.9D0
c         CYCLE_TYPE = 2
c         RELAX_TYPE = 6

C        CREATE SOLVER
         CALL HYPRE_BOOMERAMGCREATE(ESOLVER, IERR)

C        SET SOME PARAMETERS (SEE REFERENCE MANUAL FOR MORE PARAMETERS)

C        PRINT SOLVE INFO + PARAMETERS
C        FALGOUT COARSENING
         CALL HYPRE_BOOMERAMGSETCOARSENTYPE(ESOLVER, coarsen_type, IERR)
C        G-S/JACOBI HYBRID RELAXATION
         CALL HYPRE_BOOMERAMGSETRELAXTYPE(ESOLVER, RELAX_TYPE, IERR)
C        SWEEEPS ON EACH LEVEL
         CALL HYPRE_BOOMERAMGSETNUMSWEEPS(ESOLVER, num_sweeps, IERR)
C         MAXIMUM NUMBER OF LEVELS
         CALL HYPRE_BOOMERAMGSETMAXLEVELS(ESOLVER, max_levels, IERR)
C        CONV. TOLERANCE
         CALL HYPRE_BOOMERAMGSETTOL(ESOLVER, LSOL_TOL, IERR)
C         MAXIMUM NUMBER OF ITERATIONS
         CALL HYPRE_BOOMERAMGSETMAXITER(ESOLVER, LSOL_ITMAX, IERR)
C         STRONG THRESHOLD
         CALL HYPRE_BOOMERAMGSETSTRONGTHRSHLD
     &                        (ESOLVER, STRONG_THRES, IERR)
C         SET PRINT LEVEL
         CALL HYPRE_BOOMERAMGSETPRINTLEVEL(ESOLVER, print_level, IERR)
C         SET CYCLE TYPE
         CALL HYPRE_BOOMERAMGSETCYCLETYPE(ESOLVER, CYCLE_TYPE, IERR)
C         USE NODAL SYSTEM
C         CALL HYPRE_BOOMERAMGSETNODAL(ESOLVER, 1, IERR)
C         SET 3D NODAL SYSTEM
         CALL HYPRE_BOOMERAMGSETNUMFUNCTIONS(ESOLVER, 3, IERR)

         CALL HYPRE_BOOMERAMGSETUP(
     &        ESOLVER, PAR_A, PAR_B, PAR_X, IERR )

C     AMG-PCG
      ELSEIF ( HYPRE_SOL_ID .EQ. 1 ) THEN
c        MAXITER = 200

        CALL HYPRE_PARCSRPCGCREATE(MPI_COMM_WORLD, SOLVER, IERR)
        CALL HYPRE_PARCSRPCGSETMAXITER(ESOLVER, LSOL_ITMAX, IERR)
        CALL HYPRE_PARCSRPCGSETTOL(ESOLVER, LSOL_TOL, IERR)
        CALL HYPRE_PARCSRPCGSETTWONORM(ESOLVER, 1, IERR)
        CALL HYPRE_PARCSRPCGSETRELCHANGE(ESOLVER, 0, IERR)
        CALL HYPRE_PARCSRPCGSETPRINTLEVEL(ESOLVER, print_level, IERR)

CBW   SETUP AMG PRECONDITIONER

c         PRECOND_ID = 2
c         MAXITER = 1
c         COARSEN_TYPE = 6
c         MEASURE_TYPE = 0
c         SETUP_TYPE = 1
c         STRONG_THRESHOLD = 0.9D0
c         TRUNC_FACTOR = 0.D0
c         CYCLE_TYPE = 1
c         RELAX_TYPE = 6

          CALL HYPRE_BOOMERAMGCREATE(EPRECOND, IERR)
          CALL HYPRE_BOOMERAMGSETCOARSENTYPE(EPRECOND,COARSEN_TYPE,IERR)
          CALL HYPRE_BOOMERAMGSETMEASURETYPE(EPRECOND,MEASURE_TYPE,IERR)
          CALL HYPRE_BOOMERAMGSETSTRONGTHRSHLD(EPRECOND,
     &                                        STRONG_THRES, IERR)
          CALL HYPRE_BOOMERAMGSETTRUNCFACTOR(EPRECOND, TRUNC_FACTOR,
     &                                       IERR)
          CALL HYPRE_BOOMERAMGSETPRINTLEVEL(EPRECOND, print_level, IERR)
          CALL HYPRE_BOOMERAMGSETMAXITER(EPRECOND, LSOL_ITMAX, IERR)
          CALL HYPRE_BOOMERAMGSETCYCLETYPE(EPRECOND, CYCLE_TYPE, IERR)
          CALL HYPRE_BOOMERAMGSETMAXLEVELS(EPRECOND,
     &                                  max_levels, IERR)
          CALL HYPRE_PARCSRPCGSETPRECOND(ESOLVER, PRECOND_ID,
     &                                     EPRECOND, IERR)
          CALL HYPRE_BOOMERAMGSETSETUPTYPE(EPRECOND,1,IERR)
          CALL HYPRE_PARCSRPCGGETPRECOND(ESOLVER, GOT_PRECOND,
     &                                   IERR)
          CALL HYPRE_BOOMERAMGSETRELAXTYPE(EPRECOND,RELAX_TYPE,IERR)
C         USE NODAL SYSTEM
C         CALL HYPRE_BOOMERAMGSETNODAL(EPRECOND, 1, IERR)
C         SET 3D NODAL SYSTEM
         CALL HYPRE_BOOMERAMGSETNUMFUNCTIONS(EPRECOND, 3, IERR)

        IF (GOT_PRECOND .NE. EPRECOND) THEN
          PRINT *, 'HYPRE_PARCSRPCGGETPRECOND GOT BAD PRECOND'
          STOP
c        ELSE
c          PRINT *, 'HYPRE_PARCSRPCGGETPRECOND GOT GOOD PRECOND'
        ENDIF

        CALL HYPRE_PARCSRPCGSETUP(ESOLVER, PAR_A, PAR_B,
     &                              PAR_X, IERR)

C     AMG-GMRES
      ELSEIF ( HYPRE_SOL_ID .EQ. 2 ) THEN

c         K_DIM = 100
c         MAXITER = 200

         CALL HYPRE_PARCSRGMRESCREATE(MPI_COMM_WORLD, ESOLVER, IERR)
         CALL HYPRE_PARCSRGMRESSETKDIM(ESOLVER, K_DIM, IERR)
         CALL HYPRE_PARCSRGMRESSETMAXITER(ESOLVER, LSOL_ITMAX, IERR)
         CALL HYPRE_PARCSRGMRESSETTOL(ESOLVER, LSOL_TOL, IERR)
         CALL HYPRE_PARCSRGMRESSETLOGGING(ESOLVER, 1, IERR)
         CALL HYPRE_PARCSRGMRESSETPRINTLEVEL(ESOLVER,print_level,IERR)

CBW   SETUP AMG PRECONDITIONER

          if (precond_id.eq.0) goto 666

c         PRECOND_ID = 2
c         MAXITER = 1
c         COARSEN_TYPE = 6
c         MEASURE_TYPE = 0
c         SETUP_TYPE = 1
c         STRONG_THRESHOLD = 0.9D0
c         TRUNC_FACTOR = 0.D0
c         CYCLE_TYPE = 1
c         RELAX_TYPE = 6

          CALL HYPRE_BOOMERAMGCREATE(EPRECOND, IERR)
          CALL HYPRE_BOOMERAMGSETCOARSENTYPE(EPRECOND,
     &                                    COARSEN_TYPE, IERR)
          CALL HYPRE_BOOMERAMGSETMEASURETYPE(EPRECOND, MEASURE_TYPE,
     &                                          IERR)
          CALL HYPRE_BOOMERAMGSETSTRONGTHRSHLD(EPRECOND,
     &                                        STRONG_THRES, IERR)
          CALL HYPRE_BOOMERAMGSETTRUNCFACTOR(EPRECOND, TRUNC_FACTOR,
     &                                       IERR)
          CALL HYPRE_BOOMERAMGSETPRINTLEVEL(EPRECOND,print_level,IERR)
          CALL HYPRE_BOOMERAMGSETNUMSWEEPS(EPRECOND,1,IERR)
          CALL HYPRE_BOOMERAMGSETTOL(EPRECOND,0.D0,IERR)
          CALL HYPRE_BOOMERAMGSETMAXITER(EPRECOND, 1, IERR)
          CALL HYPRE_BOOMERAMGSETCYCLETYPE(EPRECOND, CYCLE_TYPE, IERR)
          CALL HYPRE_BOOMERAMGSETMAXLEVELS(EPRECOND, max_levels, IERR)
C         USE NODAL SYSTEM
C         CALL HYPRE_BOOMERAMGSETNODAL(EPRECOND, 1, IERR)
C         SET 3D NODAL SYSTEM
         CALL HYPRE_BOOMERAMGSETNUMFUNCTIONS(EPRECOND, 3, IERR)
          CALL HYPRE_BOOMERAMGSETRELAXTYPE(EPRECOND,RELAX_TYPE,IERR)
          CALL HYPRE_PARCSRGMRESSETPRECOND(ESOLVER, PRECOND_ID,
     &                                     EPRECOND, IERR)
          CALL HYPRE_BOOMERAMGSETSETUPTYPE(EPRECOND,1,IERR)
          CALL HYPRE_PARCSRGMRESGETPRECOND(ESOLVER, GOT_PRECOND,
     &                                   IERR)

        IF (GOT_PRECOND .NE. EPRECOND) THEN
          PRINT *, 'HYPRE_PARCSRGMRESGETPRECOND GOT BAD PRECOND'
          STOP
c        ELSE
c          PRINT *, 'HYPRE_PARCSRGMRESGETPRECOND GOT GOOD PRECOND'
        ENDIF

  666   continue

        CALL HYPRE_PARCSRGMRESSETUP(ESOLVER, PAR_A, PAR_B,
     &                              PAR_X, IERR)
      ELSE
         IF (MYPRC .EQ. 0) THEN
           PRINT *,'INVALID SOLVER ID SPECIFIED'
           STOP
         ENDIF
      ENDIF
      CALL TIMOFF(40)

      CALL HYPRE_IJVECTORDESTROY(B, IERR)
      CALL HYPRE_IJVECTORDESTROY(X, IERR)

C   NNTIM > 0, GOTO 500 DIRECTLY
 500  CONTINUE
      CALL TIMON(41)
C     CREATE THE RHS AND SOLUTION
      CALL HYPRE_IJVECTORCREATE(MPI_COMM_WORLD,
     &     HILOWER, HIUPPER, B, IERR )
      CALL HYPRE_IJVECTORSETOBJECTTYPE(B, HYPRE_PARCSR, IERR)
      CALL HYPRE_IJVECTORINITIALIZE(B, IERR)

      CALL HYPRE_IJVECTORCREATE(MPI_COMM_WORLD,
     &     HILOWER, HIUPPER, X, IERR )
      CALL HYPRE_IJVECTORSETOBJECTTYPE(X, HYPRE_PARCSR, IERR)
      CALL HYPRE_IJVECTORINITIALIZE(X, IERR)

C bag8
C SET MATRIX VALUES FROM GSTIFF
      CALL HYPRE_IJMATRIXINITIALIZE( MATRIX_A, IERR)
      DO I = 1,NODE_TL
         IF (ACTIVE_NODE(I).EQ.1) THEN
            DO J = 1,3
               COLS=0
               VALUES=0.D0
               LROW=NODE_ST_DOF(I)+J-1
               IROW=NODE_ST_GDOF(I)+J-1
               COL1=GSTIFF_ROW_INDEX(LROW)
               COL2=GSTIFF_ROW_INDEX(LROW+1)-1
               NNZ=COL2-COL1+1
               CTR=0
               DO K=COL1,COL2
                  CTR=CTR+1
                  COLIND=GSTIFF_COL_INDEX(K)
                  NODE=COLIND/3+1
                  DIR=MOD(COLIND,3)
                  IF (DIR.EQ.0) THEN
                     NODE=NODE-1
                     DIR = 3
                  ENDIF
                  COL3=NODE_ST_GDOF(NODE)+DIR-1
                  COLS(CTR)=COL3
                  VALUES(CTR)=GSTIFF(K)
               ENDDO
               CALL HYPRE_IJMATRIXSETVALUES(
     &              MATRIX_A, 1, NNZ, IROW, COLS, VALUES, IERR)
            ENDDO
         ENDIF
      ENDDO
      CALL HYPRE_IJMATRIXASSEMBLE( MATRIX_A, IERR)
      CALL HYPRE_IJMATRIXGETOBJECT( MATRIX_A, PAR_A, IERR)

C SET RHS VALUES FROM RESIDUE
      TL_LOAD=0.D0    ! USED AS TEMP SPACE FOR RHS IN HYPRE
      CTR=0
      DO I = 1,NODE_TL
         IF (ACTIVE_NODE(I).EQ.1) THEN
            CTR=CTR+1
            TL_LOAD(((CTR-1)*3+1):(CTR*3))=
     &               RESIDUE(NODE_ST_DOF(I):(NODE_ST_DOF(I)+2))
            ROWS((CTR-1)*3+1)=NODE_ST_GDOF(I)
            ROWS((CTR-1)*3+2)=NODE_ST_GDOF(I)+1
            ROWS((CTR-1)*3+3)=NODE_ST_GDOF(I)+2
         ENDIF
      ENDDO

      RESIDUE = 0.D0  ! USED AS TEMP SPACE FOR INITIAL GUESS

      CALL HYPRE_IJVECTORSETVALUES(
     &     B, HLSIZE, ROWS, tl_load, IERR )
      CALL HYPRE_IJVECTORSETVALUES(
     &     X, HLSIZE, ROWS, residue, IERR)

      CALL HYPRE_IJVECTORASSEMBLE( B, IERR)
      CALL HYPRE_IJVECTORASSEMBLE( X, IERR)

C GET THE X AND B OBJECTS

      CALL HYPRE_IJVECTORGETOBJECT( B, PAR_B, IERR)
      CALL HYPRE_IJVECTORGETOBJECT( X, PAR_X, IERR)
      CALL TIMOFF(41)

C     CHOOSE A SOLVER AND SOLVE THE SYSTEM
C     AMG
      IF ( HYPRE_SOL_ID .EQ. 0 ) THEN
         CALL TIMON(42)
         CALL HYPRE_BOOMERAMGSOLVE(
     &        ESOLVER, PAR_A, PAR_B, PAR_X, IERR )
         CALL TIMOFF(42)

C        RUN INFO - NEEDED LOGGING TURNED ON
         CALL HYPRE_BOOMERAMGGETNUMITERATIONS(ESOLVER, NUM_ITERATIONS,
     &        IERR)
         CALL HYPRE_BOOMERAMGGETFINALRELTVRES(ESOLVER, FINAL_RES_NORM,
     &        IERR)

C     AMG-PCG
      ELSEIF ( HYPRE_SOL_ID .EQ. 1 ) THEN
        CALL TIMON(42)
        CALL HYPRE_PARCSRPCGSOLVE(ESOLVER, PAR_A, PAR_B,
     &                              PAR_X, IERR)
        CALL TIMOFF(42)

        CALL HYPRE_PARCSRPCGGETNUMITERATIONS(ESOLVER,
     &                                       NUM_ITERATIONS, IERR)
        CALL HYPRE_PARCSRPCGGETFINALRELATIVE(ESOLVER,
     &                                       FINAL_RES_NORM, IERR)

C     AMG-GMRES
      ELSEIF ( HYPRE_SOL_ID .EQ. 2 ) THEN
        CALL TIMON(42)
        CALL HYPRE_PARCSRGMRESSOLVE(ESOLVER, PAR_A, PAR_B,
     &                              PAR_X, IERR)
        CALL TIMOFF(42)

        CALL HYPRE_PARCSRGMRESGETNUMITERATIO(ESOLVER,
     &                                       NUM_ITERATIONS, IERR)
        CALL HYPRE_PARCSRGMRESGETFINALRELATI(ESOLVER,
     &                                       FINAL_RES_NORM, IERR)

      ELSE
         IF (MYPRC .EQ. 0) THEN
           PRINT *,'INVALID SOLVER ID SPECIFIED'
           STOP
         ENDIF
      ENDIF

ctm   TAMEEM
         IF (MYPRC .EQ. 0) THEN
            TOTAL_NUM_LIN_ITER_M = TOTAL_NUM_LIN_ITER_M +
     &              NUM_ITERATIONS
         ENDIF
ctm   TAMEEM

C STORE SOLUTION TO RESIDUE
      CALL TIMON(41)
      RESIDUE = 0.D0  ! USED AS TEMP SPACE FOR GETTING SOLUTION FROM HYPRE
      CALL HYPRE_IJVECTORGETVALUES(X, HLSIZE, ROWS, RESIDUE , IERR)
      CALL TIMOFF(41)

C     PRINT THE SOLUTION
      IF ( PRINT_SOL .EQ. 1 ) THEN
         CALL HYPRE_IJMATRIXPRINT( MATRIX_A, "IJ.OUT.A", IERR)
         CALL HYPRE_IJVECTORPRINT( X, "IJ.OUT.X", IERR)
         CALL HYPRE_IJVECTORPRINT( B, "IJ.OUT.B", IERR)
      ELSEIF ( PRINT_SOL .EQ. 2 ) THEN
         CALL HYPRE_IJMATRIXPRINT( MATRIX_A, "NEW_IJ.OUT.A", IERR)
         CALL HYPRE_IJVECTORPRINT( X, "NEW_IJ.OUT.X", IERR)
         CALL HYPRE_IJVECTORPRINT( B, "NEW_IJ.OUT.B", IERR)
      ENDIF

      POROHEXLINT = POROHEXLINT+NUM_ITERATIONS
      IF (MYPRC.EQ.0) THEN
        IF (IERR.EQ.0) THEN
          WRITE(*,'(1X,1P,A,I6,A,E11.4)')
     &      'HYPRE_POROHEX: ITER=',NUM_ITERATIONS,
     &      ' LIN RESID=',FINAL_RES_NORM
        ELSE
          WRITE(*,'(1X,1P,A,I6,A,E11.4,A,I4,A)')
     &      'HYPRE_POROHEX: ITER=',NUM_ITERATIONS,
     &      ' LIN RESID=',FINAL_RES_NORM,
     &      ' (IERR=',IERR,')'
        ENDIF
      ENDIF
      CALL HYPRE_CLEARALLERRORS(IERR)

C     CLEAN UP

C   NNTIM = 0 : INITIALIZATION
C           1 : NORMAL TIME STEP
C           2 : QUIT
C

      CALL HYPRE_IJVECTORDESTROY(B, IERR)
      CALL HYPRE_IJVECTORDESTROY(X, IERR)

      CALL TIMOFF(37)

      RETURN

 600  IF (NNTIM.EQ.2) THEN
         IF (HYPRE_SOL_ID.EQ.0) THEN
            CALL HYPRE_BOOMERAMGDESTROY(ESOLVER, IERR )
         ELSEIF (HYPRE_SOL_ID.EQ.1) THEN
            if (precond_id.ne.0)
     &        CALL HYPRE_BOOMERAMGDESTROY(EPRECOND, IERR)
            CALL HYPRE_PARCSRPCGDESTROY(ESOLVER, IERR)
         ELSEIF (HYPRE_SOL_ID.EQ.2) THEN
            if (precond_id.ne.0)
     &        CALL HYPRE_BOOMERAMGDESTROY(EPRECOND, IERR)
            CALL HYPRE_PARCSRGMRESDESTROY(ESOLVER, IERR)
         ENDIF
         CALL HYPRE_IJMATRIXDESTROY(MATRIX_A, IERR)
      ENDIF

      CALL TIMOFF(37)
      END


C======================================================================
      SUBROUTINE POROHEX_COPY_EDISP(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &     JL2V,KL1,KL2,KEYOUT,NBLK,KEYOUT_CR,GELEINDEX,
     &     TL_LOAD,EDISP,NODE_ST_DOF,NODE_ST_GDOF,OFNODE_DISP,
     &     OFNODE_DISP_TMP,OFNODE_KEYOUT,NODE_TL,
     &     NODE_LID,OFNODE_GNUM,OFNODE_GNUM_TMP,OFNODE_L2GID)
C======================================================================
      IMPLICIT NONE
C
      INCLUDE 'control.h'
      INCLUDE 'mpif.h'
      INCLUDE 'emodel.h'
      INCLUDE 'hypre.h'
C
      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM),
     &        KL1,KL2,KEYOUT(IDIM,JDIM,KDIM),NBLK
      INTEGER KEYOUT_CR(IDIM,JDIM,KDIM),GELEINDEX(IDIM,JDIM,KDIM)
      INTEGER NODE_TL
      REAL*8  EDISP(IDIM,JDIM,KDIM,3),
     &        OFNODE_DISP(3,POROHEX_GFSIZE),
     &        TL_LOAD(NODE_TL*3),OFNODE_DISP_TMP(3,POROHEX_GFSIZE)
      INTEGER NODE_ST_DOF(NODE_TL),
     &        NODE_ST_GDOF(NODE_TL),
     &        OFNODE_KEYOUT(POROHEX_LFALLSIZE),
     &        NODE_LID(IDIM,JDIM,KDIM),
     &        OFNODE_GNUM(POROHEX_GFSIZE),
     &        OFNODE_GNUM_TMP(POROHEX_GFSIZE),
     &        OFNODE_L2GID(POROHEX_LFALLSIZE)

      INTEGER IERR,BUFSIZE
      INTEGER I,J,K,LROW,CTR,NODE,GID,GID2,CTR1,NNTIM

      CTR=0
      DO K=1,KDIM
         DO J=1,JDIM
            DO I=IL1,IL2+1
               NODE=NODE_LID(I,J,K)
               IF (NODE.GT.0) THEN
                  CTR=CTR+1
                  LROW=NODE_ST_DOF(NODE)

                  EDISP(I,J,K,1)=TL_LOAD(LROW)
                  EDISP(I,J,K,2)=TL_LOAD(LROW+1)
                  EDISP(I,J,K,3)=TL_LOAD(LROW+2)
               ENDIF
            ENDDO
         ENDDO
      ENDDO
      CTR1=CTR

      DO I=1,POROHEX_LFALLSIZE
         GID=OFNODE_L2GID(I)
         DO J=1,POROHEX_GFSIZE
            GID2=OFNODE_GNUM(J)
            IF (GID.EQ.GID2) THEN
               CTR=CTR+1
               LROW=NODE_ST_DOF(CTR)

               OFNODE_DISP(1,J)=TL_LOAD(LROW)
               OFNODE_DISP(2,J)=TL_LOAD(LROW+1)
               OFNODE_DISP(3,J)=TL_LOAD(LROW+2)
               EXIT
            ENDIF
         ENDDO
      ENDDO

      CALL TIMON(38)
      IF (NUMPRC.GT.1 .AND. POROHEX_GFSIZE .GT. 0) THEN
         OFNODE_DISP_TMP = 0.D0
         BUFSIZE=3*POROHEX_GFSIZE
         CALL MPI_ALLREDUCE(OFNODE_DISP,OFNODE_DISP_TMP,BUFSIZE,
     &                      MPI_REAL8,MPI_SUM,MPI_COMM_WORLD,IERR)

         OFNODE_DISP=OFNODE_DISP_TMP
      ENDIF
      CALL TIMOFF(38)

      IF (CTR.NE.NODE_TL) THEN
         WRITE(*,*) "ERROR IN POROHEX_COPY_EDISP"
         write(*,*) "NODE_TL=",NODE_TL,"CTR=",CTR
         write(*,*) "POROHEX_LFALLSIZE=",POROHEX_LFALLSIZE
         write(*,*) "CTR1=",CTR1
         write(*,*) "OFNODE_L2GID=",OFNODE_L2GID
         write(*,*) "OFNODE_GNUM=",OFNODE_GNUM
         STOP 13
      ENDIF

      END


C======================================================================
      SUBROUTINE update_width(frac_width,frac_width_tmp,num)
C======================================================================
      IMPLICIT NONE
C
      INCLUDE 'mpif.h'

      REAL*8 FRAC_WIDTH(NUM),FRAC_WIDTH_TMP(NUM)
      INTEGER NUM,IERR

      FRAC_WIDTH=0.D0
      CALL MPI_ALLREDUCE(FRAC_WIDTH_TMP,FRAC_WIDTH,NUM,
     &                   MPI_REAL8,MPI_SUM,MPI_COMM_WORLD,IERR)


      END





C*********************************************************************
      SUBROUTINE COORD2DISP(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                      KL1,KL2,KEYOUT,NBLK,EDISP,XC,YC,ZC,
     &                      KEYOUT_CR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      REAL*8  EDISP(IDIM,JDIM,KDIM,3),XC(IDIM+1,JDIM+1,KDIM+1),
     &        YC(IDIM+1,JDIM+1,KDIM+1),ZC(IDIM+1,JDIM+1,KDIM+1)
      INTEGER I,J,K

      EDISP=0.D0

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (KEYOUT_CR(I,J,K).NE.0) THEN
                  EDISP(I,J,K,1)=XC(I,J,K)
                  EDISP(I,J,K,2)=YC(I,J,K)
                  EDISP(I,J,K,3)=ZC(I,J,K)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE DISP2COORD(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                      KL1,KL2,KEYOUT,NBLK,EDISP,XC,YC,ZC,
     &                      KEYOUT_CR)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)
      REAL*8  EDISP(IDIM,JDIM,KDIM,3),XC(IDIM+1,JDIM+1,KDIM+1),
     &        YC(IDIM+1,JDIM+1,KDIM+1),ZC(IDIM+1,JDIM+1,KDIM+1)
      INTEGER I,J,K

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (KEYOUT_CR(I,J,K).NE.0) THEN
                  XC(I,J,K)=EDISP(I,J,K,1)
                  YC(I,J,K)=EDISP(I,J,K,2)
                  ZC(I,J,K)=EDISP(I,J,K,3)
               ENDIF
            ENDDO
         ENDDO
      ENDDO
      EDISP=0.D0

      END


C*********************************************************************
      SUBROUTINE EPROCOUTPUT(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                      KL1,KL2,KEYOUT,NBLK,PROCN,KEYOUT_CR)
C*********************************************************************
      IMPLICIT NONE

      INCLUDE 'control.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  PROCN(IDIM,JDIM,KDIM)
      INTEGER I,J,K,KEYOUT_CR(IDIM,JDIM,KDIM)

      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = 1,IDIM
               IF (KEYOUT_CR(I,J,K).GT.0) THEN
                  PROCN(I,J,K)=(MYPRC+1)*1.0D0
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C************************************************************************
      SUBROUTINE EFFEC_MEAN_STRESS(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                             JL2V,KL1,KL2,KEYOUT,NBLK,MODUL,POISS,
     &                             VOLSTRN,EMSTRESS)
C************************************************************************
C Calculate effective mean stresses at grid center
C
C INPUT:
C   LAMBDA(I,J,K) = LAME'S CONSTANT LAMBDA (PSI)
C   MU(I,J,K) = LAME'S CONSTANT MU
C   VOLSTRN(I,J,K) = VOLUMETRIC STRAIN
C
C OUTPUT:
C   EMSTRESS(I,J,K) = EFFECTIVE MEAN STRESSES (PSI) AT GRID CENTER
C************************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
!C      INCLUDE 'xthermal.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  MODUL(IDIM,JDIM,KDIM),      POISS(IDIM,JDIM,KDIM)
      REAL*8  VOLSTRN(IDIM,JDIM,KDIM)
      REAL*8  EMSTRESS(IDIM,JDIM,KDIM)

      INTEGER I,J,K,JL1,JL2,NDIM
      REAL*8  U,V,W,ZERO,LAMBDAVAL,MUVAL
      REAL*8  V1,V2,X
      PARAMETER(ZERO=0.0D0)
      NDIM = 3
      IF(NDIM.EQ.3) THEN
         DO K = KL1,KL2
            JL1 = JL1V(K)
            JL2 = JL2V(K)
            DO J = JL1,JL2
               DO I = IL1,IL2
                  EMSTRESS(I,J,K)=ZERO
                  IF (KEYOUT(I,J,K).LE.0) GOTO 1
                  V1 = MODUL(I,J,K)
                  V2 = POISS(I,J,K)
                  X = 1.0D0 - 2.0D0 * V2
                  IF(X.GE.ZERO) THEN
                     LAMBDAVAL = V2 * V1 / ((1.0D0 + V2)* X)
                  ELSE
                     LAMBDAVAL = 1.0D15
                  ENDIF
                  MUVAL = 0.5D0 * V1 / (1.D0 + V2)
                  IF (LAMBDAVAL.GT.ZERO) THEN
                     U = 3.0D0 * LAMBDAVAL
                     V = 2.0D0 * MUVAL
                     W = U + V
                     W = W / 3.D0
                     EMSTRESS(I,J,K) = W * VOLSTRN(I,J,K)
                  ELSE
                     EMSTRESS(I,J,K) = ZERO
                  ENDIF
   1              CONTINUE
               ENDDO
            ENDDO
         ENDDO
      ELSE
         IF(LEVELC) WRITE(NFOUT,10)
         NERRC = NERRC + 1
         RETURN
      ENDIF
   10 FORMAT(/'ERROR:NOT SETUP FOR 1D, 2D EFFECTIVE MEAN STRESS
     &CALCULATION')

      END

C***********************************************************************
      SUBROUTINE PE_PERM()
C***********************************************************************
C ADDED BY SAUMIK
C TRANSIENT PERMEABILITY
C MODIFIED BY JAMMOUL ON 9/22/2016
C ADDED KOZENY-CARMAN (MODEL 6)

      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'layout.h'
      INCLUDE 'blkary.h'
      INCLUDE 'earydat.h'
      INCLUDE 'emodel.h'

      INTEGER JPERM(14)
      EXTERNAL PE_UPPERM
      INTEGER KERR
      DATA     JPERM/14*0/

      KERR=0

      JPERM(1)=13
      JPERM(2)=N_EMSTRESS
      JPERM(3)=N_EMSTRESS_REF
      JPERM(4)=N_XPERM
      JPERM(5)=N_YPERM
      JPERM(6)=N_ZPERM
      JPERM(7)=N_XPERM_REF
      JPERM(8)=N_YPERM_REF
      JPERM(9)=N_ZPERM_REF
      JPERM(10)=N_MODUL
      JPERM(11)=N_POISS
      JPERM(12)=N_EVOL
      JPERM(13)=N_EPV_FLOW
      JPERM(14)=N_POR
      CALL CALLWORK(PE_UPPERM,JPERM)

      CALL TIMON(38)
      CALL UPDATE(N_XPERM,2)
      CALL UPDATE(N_YPERM,2)
      CALL UPDATE(N_ZPERM,2)
      CALL TIMOFF(38)

      CALL SDPWELL(KERR)

      END

C***********************************************************************
      SUBROUTINE PE_UPPERM(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                     KL2,KEYOUT,NBLK,EMSTRESS,EMSTRESS_REF,
     &                     XPERM,YPERM, ZPERM,XPERMREF,YPERMREF,
     &                     ZPERMREF,MODUL,POISS,EVOL, EPV_FLOW, POR)
C***********************************************************************
C ADDED BY SAUMIK
C TRANSIENT PERMEABILITY
C MODIFIED BY JAMMOUL
C ADDED KOZENY-CARMAN (MODEL 6)

      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'
      INCLUDE 'earydat.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  EMSTRESS(IDIM,JDIM,KDIM), EMSTRESS_REF(IDIM,JDIM,KDIM)
      REAL*4  XPERM(IDIM,JDIM,KDIM),  YPERM(IDIM,JDIM,KDIM)
      REAL*4  ZPERM(IDIM,JDIM,KDIM)
      REAL*4  XPERMREF(IDIM,JDIM,KDIM),YPERMREF(IDIM,JDIM,KDIM)
      REAL*4  ZPERMREF(IDIM,JDIM,KDIM)
      REAL*8  MODUL(IDIM,JDIM,KDIM),POISS(IDIM,JDIM,KDIM)
      REAL*8  EVOL(IDIM, JDIM,KDIM)
      REAL*8  EPV_FLOW(IDIM,JDIM,KDIM), POR(IDIM,JDIM,KDIM)

      INTEGER I,J,K,JL1,JL2
      REAL*8  COEFFICIENT
      INTEGER*4 TYPEP
      REAL*8  PARA
      REAL*8  INITIAL_POROSITY
      REAL*8  VSTRAIN_POROSITY
      REAL*8  YOUNG,POISSON,PI
      PARAMETER(PI=3.14159D0)

      TYPEP = TYPESDP
      DO K=KL1,KL2
         JL1=JL1V(K)
         JL2=JL2V(K)
         DO J=JL1,JL2
            DO I=IL1,IL2
               IF (KEYOUT(I,J,K).GT.0) THEN
                  COEFFICIENT=1.D0
                  IF (TYPEP.EQ.1) THEN
                     PARA=COEFB
                     COEFFICIENT=EXP(PARA*(EMSTRESS(I,J,K)-
     &                                     EMSTRESS_REF(I,J,K)))
                     IF (COEFFICIENT.LT.0.D0) THEN
                        COEFFICIENT=0.D0
                     ENDIF
                  ELSEIF (TYPEP.EQ.2) THEN
                     PARA=COEFM
                     COEFFICIENT=(1.D0+PARA*EMSTRESS(I,J,K))/
     &                           (1.D0+PARA*EMSTRESS_REF(I,J,K))
                     IF (COEFFICIENT.LT.0.D0) THEN
                        COEFFICIENT=0.D0
                     ENDIF
                  ELSEIF (TYPEP.EQ.3) THEN
                     PARA=COEFN
                     COEFFICIENT=(EPV_FLOW(I,J,K)/POR(I,J,K))**PARA
                     IF (COEFFICIENT.LT.0.D0) THEN
                        COEFFICIENT=0.D0
                     ENDIF
                  ELSEIF (TYPEP.EQ.4) THEN
                     YOUNG=MODUL(I,J,K)
                     POISSON=POISS(I,J,K)
                     PARA=3.D0*PI*(1-POISSON**2.D0)
                     PARA=PARA/(4.D0*YOUNG)
                     PARA=PARA*(EMSTRESS(I,J,K)-EMSTRESS_REF(I,J,K))
                     COEFFICIENT=PARA**2.D0
                     COEFFICIENT=COEFFICIENT**(1/3.D0)
                     IF (EMSTRESS(I,J,K).LT.EMSTRESS_REF(I,J,K)) THEN
                        COEFFICIENT=-COEFFICIENT
                     ENDIF
                     COEFFICIENT=1.D0+COEFFICIENT
                     COEFFICIENT=COEFFICIENT**2.D0
                  ELSEIF (TYPEP.EQ.5) THEN
                     YOUNG=MODUL(I,J,K)
                     POISSON=POISS(I,J,K)
                     PARA=3.D0*PI*(1-POISSON**2.D0)
                     PARA=PARA/(4.D0*YOUNG)
                     PARA=PARA*(EMSTRESS(I,J,K)-EMSTRESS_REF(I,J,K))
                     COEFFICIENT=PARA**2.D0
                     COEFFICIENT=COEFFICIENT**(1/3.D0)
                     COEFFICIENT=COEFFICIENT*2.D0
                     IF (EMSTRESS(I,J,K).LT.EMSTRESS_REF(I,J,K)) THEN
                        COEFFICIENT=-COEFFICIENT
                     ENDIF
                     COEFFICIENT=1.D0+COEFFICIENT
                     COEFFICIENT=COEFFICIENT**4.D0
                  ELSEIF (TYPEP.EQ.6) THEN
                     INITIAL_POROSITY=POR(I,J,K)/EVOL(I,J,K)
                     VSTRAIN_POROSITY=EPV_FLOW(I,J,K)/EVOL(I,J,K)
                     COEFFICIENT=VSTRAIN_POROSITY**3.D0
                     PARA=(1-INITIAL_POROSITY)**2.D0
                     COEFFICIENT=COEFFICIENT*PARA
                     COEFFICIENT=COEFFICIENT/(INITIAL_POROSITY**3.D0)
                     PARA=(1-VSTRAIN_POROSITY)**2.D0
                     COEFFICIENT=COEFFICIENT/PARA
                  ENDIF
                  XPERM(I,J,K)=XPERMREF(I,J,K)*COEFFICIENT
                  YPERM(I,J,K)=YPERMREF(I,J,K)*COEFFICIENT
                  ZPERM(I,J,K)=ZPERMREF(I,J,K)*COEFFICIENT
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C***********************************************************************
      SUBROUTINE SDPWELL(NERR)
C***********************************************************************

C  Routine updates ELEPERM AND ELECONS for stress-dependent permeability

C  NERR = Error number stepped by 1 on error (input & output, INTEGER)

C***********************************************************************
      IMPLICIT NONE
C      INCLUDE 'msjunk.h'

      INCLUDE 'control.h'
      INCLUDE 'wells.h'
      INCLUDE 'blkary.h'
      INCLUDE 'layout.h'
      INCLUDE 'unitsex.h'
      INCLUDE 'mpfaary.h'

      INTEGER NA(11),I,K,NELE,NERR
      EXTERNAL WELLSDP

      IF (LEVELE.AND.BUGKEY(1)) WRITE (NFBUG,*)'PROC',MYPRC,
     & ' ENTERING SUBROUTINE SDPWELL'

      IF (NUMWEL.LT.1) RETURN

C  LOCATE WELL ELEMENTS ON THE CURRENT PROCESSOR AND COMPUTE WELL ELEMENT
C  PRODUCTIVITY INDEX CONSTANT FACTORS

      NA(1)=10
      NA(2)=N_KPU
      NA(3)=N_XPERM
      NA(4)=N_YPERM
      NA(5)=N_ZPERM
      NA(6)=N_XYPERM
      NA(7)=N_YZPERM
      NA(8)=N_XZPERM
      NA(9)=N_XC
      NA(10)=N_YC
      NA(11)=N_ZC

      DO 3 I=1,NUMWEL
         NELE=NUMELE(I)
         NUMELE(I)=0
         KPU=I
         IF (KNDGRD.EQ.3) CALL CALLWORK(WELLSDP,NA)
C        CORNER-POINT WITH MPFA
         IF (NELE.NE.NUMELE(I)) THEN
            WRITE(NFOUT,*) "ERROR: IN WELLSDP, NUMELE NOT MATCH"
            WRITE(*,*) "ERROR: IN WELLSDP, NUMELE NOT MATCH"
            NERR=NERR+1
            STOP 13
         ENDIF
         DO 18 K=1,NUMELE(I)
   18    ELECONS(K,I)=ELELEN(K,I)*ELEPERM(K,I)*ELEGEOM(K,I)
    3 CONTINUE

      RETURN

      END

c======================================================================
      SUBROUTINE WELLSDP (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
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
      REAL*8 XMIN,XMAX,YMIN,YMAX,ZMIN,ZMAX

      INTEGER IOFF,JOFF,KOFF,MERR,N,NI,I,J,K,JL1,JL2,IG,JG,KG,
     &        IX,JY,KZ,IC,NIF,M,MM,LL

      IF (LEVELE.AND.BUGKEY(1)) WRITE (NFBUG,*)'PROC',MYPRC,
     & ', BLOCK',NBLK,', WELL',NW,' ENTERING SUBROUTINE WELLSDP'

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
c returns interection in plane coordinates
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
        GOTO 4
      ENDIF

! bag8 - additional check if well endpoints are inside element
!   These if-statements could be improved with checks for well top/bottom
!   to be inside convex hull of 8 vertices...
      IF (NIF.EQ.1) THEN

      IF ((XW1.GT.XMIN).AND.(XW1.LT.XMAX).AND.
     &    (YW1.GT.YMIN).AND.(YW1.LT.YMAX).AND.
     &    (ZW1.GT.ZMIN).AND.(ZW1.LT.ZMAX)) THEN
        NIF=2
        XI(2)=XW1
        YI(2)=YW1
        ZI(2)=ZW1
      ELSEIF ((XW2.GT.XMIN).AND.(XW2.LT.XMAX).AND.
     &    (YW2.GT.YMIN).AND.(YW2.LT.YMAX).AND.
     &    (ZW2.GT.ZMIN).AND.(ZW2.LT.ZMAX)) THEN
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

      NUMELE(NW)=NUMELE(NW)+1
      M=NUMELE(NW)

C APPROXIMATE AVERAGE PERMEABILITY NORMAL TO THE WELLBORE

      DUM1=(XW2-XW1)**2
      DUM2=(YW2-YW1)**2
      DUM3=(ZW2-ZW1)**2
      ELEPERM(M,NW)=(DUM3*SQRT(XPERM(I,J,K)*YPERM(I,J,K))+
     & DUM2*SQRT(XPERM(I,J,K)*ZPERM(I,J,K))+
     & DUM1*SQRT(YPERM(I,J,K)*ZPERM(I,J,K)))/(DUM1+DUM2+DUM3)

    4 CONTINUE
    3 CONTINUE
    2 CONTINUE
    1 CONTINUE

      END

C***********************************************************************
      SUBROUTINE CPYINITPORE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                       KL2,KEYOUT,NBLK,OLD,NEW)
C***********************************************************************

      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  NEW(IDIM,JDIM,KDIM)
      REAL*4  OLD(IDIM,JDIM,KDIM)

      INTEGER I,J,K,IL1,IL2,KL1,KL2

      DO K=1,KDIM
         DO J=1,JDIM
            DO I=1,IDIM
               NEW(I,J,K)=OLD(I,J,K)
            ENDDO
         ENDDO
      ENDDO

      END

! bag8
C***********************************************************************
      SUBROUTINE CPYPERMTOR8(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                       KL2,KEYOUT,NBLK,PERM,PERM_REF,PERM_R8)
C***********************************************************************
      IMPLICIT NONE
      INCLUDE 'emodel.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,I,J,K,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  PERM_R8(IDIM,JDIM,KDIM)
      REAL*4  PERM(IDIM,JDIM,KDIM),PERM_REF(IDIM,JDIM,KDIM)

      IF (PLOT_PERM_CHANGE) THEN
        DO K=1,KDIM
          DO J=1,JDIM
            DO I=1,IDIM
              PERM_R8(I,J,K)=PERM(I,J,K)-PERM_REF(I,J,K)
            ENDDO
          ENDDO
        ENDDO
      ELSE
        DO K=1,KDIM
          DO J=1,JDIM
            DO I=1,IDIM
              PERM_R8(I,J,K)=PERM(I,J,K)
            ENDDO
          ENDDO
        ENDDO
      ENDIF

      END

C***********************************************************************
      SUBROUTINE POR_VOL(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                KL1,KL2,KEYOUT,NBLK,EVOL,POR,PORTRUE)
C***********************************************************************
      IMPLICIT NONE
      INCLUDE 'layout.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V(KDIM),JL2V(KDIM)
      INTEGER KL1,KL2,NBLK,KEYOUT(IDIM,JDIM,KDIM)
      REAL*8 EVOL(IDIM,JDIM,KDIM),POR(IDIM,JDIM,KDIM),
     &       PORTRUE(IDIM,JDIM,KDIM)
C
      INTEGER I,J,K
C
      DO 100 K = KL1,KL2
      DO 100 J = JL1V(K),JL2V(K)
      DO 100 I = IL1,IL2
      IF(KEYOUT(I,J,K).LE.0) CYCLE
!      IF(MFMFE_BRICKS) PORTRUE(I,J,K) = POR(I,J,K)
      PORTRUE(I,J,K) = POR(I,J,K)
      POR(I,J,K) = POR(I,J,K) * EVOL(I,J,K)
 100  CONTINUE

      RETURN

      END

C*********************************************************************
C      SUBROUTINE COMPDEN_3PH(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
C     &                       KL2,KEYOUT,NBLK,BULKDEN,PV,EPMD,SAT,EVOL)
C*********************************************************************
C      USE XGENDAT

C      IMPLICIT NONE
C      INCLUDE 'control.h'
C      INCLUDE 'emodel.h'
C      INCLUDE 'xmodel.h'
C      INCLUDE 'xresprop.h'

C      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK,JL1,JL2
C      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
C      REAL*8  BULKDEN(IDIM,JDIM,KDIM), PV(IDIM,JDIM,KDIM)
C      REAL*8  EPMD(IDIM,JDIM,KDIM,NCINPH), SAT(IDIM,JDIM,KDIM,NPH)
C      REAL*8  EVOL(IDIM,JDIM,KDIM)
C      INTEGER I1,I2,I3,IC,LC,IPH
C      REAL*8  U0,SATURA,PVOL,MOLWT,PHDEN(3),ELVOL

C      DO I3 = KL1,KL2
C         JL1 = JL1V(I3)
C         JL2 = JL2V(I3)
C         DO I2 = JL1,JL2
C            DO I1 = IL1,IL2
C               IF(KEYOUT(I1,I2,I3).GT.0) THEN
C                 PVOL = PV(I1,I2,I3)
C                 ELVOL = EVOL(I1,I2,I3)
C                 DO IPH=1,NPH ! NPH IS # OF PHASES...!
C                    PHDEN(IPH) = 0.D0
C                    SATURA = SAT(I1,I2,I3,IPH) ! PHASE SATURATION...!
C                    DO IC=1,NC ! NC IS # OF COMPONENTS...!
C                       LC=ICINPH(IC,IPH)
C                       IF(LC.EQ. 0) CYCLE ! COMPONENT IC NOT PRESENT...!
C                       IF(IC.EQ.1) THEN
C                          MOLWT=WATMOLW ! MOL.WT OF WATER...!
C                       ELSE
C                          MOLWT=WMOL(IC-1) ! MOL.WT OF COMPONENT (IC-1)...!
C                       ENDIF
C                       PHDEN(IPH) = PHDEN(IPH) + EPMD(I1,I2,I3,LC)*
C     &                              MOLWT
C                    ENDDO
C                    IF(ELVOL.NE.0.D0) THEN
C                    BULKDEN(I1,I2,I3) = BULKDEN(I1,I2,I3) +
C     &                                  PHDEN(IPH)*SATURA*PVOL/ELVOL
C                    ENDIF
C                 ENDDO
C               ENDIF
C            ENDDO
C         ENDDO
C      ENDDO
C      END

C*********************************************************************
      SUBROUTINE ADD_ROCK_DEN(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                        KL2,KEYOUT,NBLK,BULKDEN,ROCKD)
C*********************************************************************

      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'emodel.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK,JL1,JL2
      INTEGER JL1V(KDIM),JL2V(KDIM),      KEYOUT(IDIM,JDIM,KDIM)
      REAL*8  ROCKD(IDIM,JDIM,KDIM),      BULKDEN(IDIM,JDIM,KDIM)
      INTEGER I1,I2,I3

      DO I3 = KL1,KL2
         JL1 = JL1V(I3)
         JL2 = JL2V(I3)
         DO I2 = JL1,JL2
            DO I1 = IL1,IL2
               IF(KEYOUT(I1,I2,I3).GT.0) THEN
                  BULKDEN(I1,I2,I3)=BULKDEN(I1,I2,I3)+ROCKD(I1,I2,I3)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE GETPOROSITY(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                  KL2,KEYOUT,NBLK,EPV,POROSITY,EVOL)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER KEYOUT(IDIM,JDIM,KDIM),JL1V(KDIM),JL2V(KDIM)
      REAL*8  POROSITY(IDIM,JDIM,KDIM),EPV(IDIM,JDIM,KDIM),
     &        EVOL(IDIM,JDIM,KDIM)

      INTEGER I,J,K

      DO K=1,KDIM
         DO J=1,JDIM
            DO I=1,IDIM
               IF(KEYOUT(I,J,K).NE.1) CYCLE
               IF(EVOL(I,J,K).NE.0.D0) THEN
               POROSITY(I,J,K)=EPV(I,J,K)/EVOL(I,J,K)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE GETPOREVOLUME(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,
     &                  KL1,KL2,KEYOUT,NBLK,PV,POROSITY,EVOL)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER KEYOUT(IDIM,JDIM,KDIM),JL1V(KDIM),JL2V(KDIM)
      REAL*8  POROSITY(IDIM,JDIM,KDIM),PV(IDIM,JDIM,KDIM),
     &        EVOL(IDIM,JDIM,KDIM)

      INTEGER I,J,K

      DO K=1,KDIM
         DO J=1,JDIM
            DO I=1,IDIM
               IF(KEYOUT(I,J,K).NE.1) CYCLE
               IF(EVOL(I,J,K).NE.0.D0) THEN
               PV(I,J,K)=POROSITY(I,J,K)*EVOL(I,J,K)
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE GETUPDATEDVAR1(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                  JL2V,KL1,KL2,KEYOUT,NBLK,PV,EVOL,RC)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER KEYOUT(IDIM,JDIM,KDIM),JL1V(KDIM),JL2V(KDIM)
      REAL*8  PV(IDIM,JDIM,KDIM),RC(IDIM,JDIM,KDIM)
      REAL*8  EVOL(IDIM,JDIM,KDIM)

      INTEGER I,J,K

      DO K=1,KDIM
         DO J=1,JDIM
            DO I=1,IDIM
               IF(KEYOUT(I,J,K).NE.1) CYCLE
               PV(I,J,K)=PV(I,J,K)+RC(I,J,K)*EVOL(I,J,K)
            ENDDO
         ENDDO
      ENDDO

      END

C*********************************************************************
      SUBROUTINE GETUPDATEDVAR2(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &                  JL2V,KL1,KL2,KEYOUT,NBLK,PV,RC)
C*********************************************************************
      IMPLICIT NONE

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER KEYOUT(IDIM,JDIM,KDIM),JL1V(KDIM),JL2V(KDIM)
      REAL*8  PV(IDIM,JDIM,KDIM),RC(IDIM,JDIM,KDIM)

      INTEGER I,J,K

      DO K=1,KDIM
         DO J=1,JDIM
            DO I=1,IDIM
               IF(KEYOUT(I,J,K).NE.1) CYCLE
               PV(I,J,K)=PV(I,J,K)+RC(I,J,K)
            ENDDO
         ENDDO
      ENDDO

      END


C************************************************************************
C                        END OF ELASTIC.F
C************************************************************************
