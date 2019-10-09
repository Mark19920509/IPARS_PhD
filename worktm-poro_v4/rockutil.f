C  ROCKUTIL.F - auxiliary routines for manipulation of porosities
c               and permeabilities
c
c  SUBROUTINE PERMSCALE
c     (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
c     KL2,KEYOUT,NBLK,RARY1,RARY2)
c  SUBROUTINE GETPOR
c     (IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
c      KL2,KEYOUT,NBLK,RARY1,RARY2)

C  CODE HISTORY:

c  Malgo Peszynska, 9/00   added GETPOR
c 	
C*********************************************************************
      SUBROUTINE PERMSCALE
     &	(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &                   KL2,KEYOUT,NBLK,RARY1,RARY2)
C*********************************************************************

C  Copies ALL elements of one REAL*4 grid-element array to another
c  with scaling (intended for permeabilities).
C  This is a work routine.

C  RARY1(I,J,K) = Source array (input, REAL*4) to be multipled by PERM_VTOH
C  RARY2(I,J,K) = Target array (output, REAL*4)

C*********************************************************************
      include 'rock.h'

      REAL*4 RARY1(IDIM,JDIM,KDIM),RARY2(IDIM,JDIM,KDIM)

      DO 1 K=1,KDIM
      DO 1 J=1,JDIM
      DO 1 I=1,IDIM
    1 RARY2(I,J,K)=RARY1(I,J,K)*PERM_HTOV

      END

C*********************************************************************
      SUBROUTINE GETPOR
     &	(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,JL2V,KL1,
     &  	                 KL2,KEYOUT,NBLK,POR,ARY)
C*********************************************************************

C  Copies ALL elements of one REAL*4 grid-element array to another,
c  which is REAL*8.
C  This is a work routine.

C  POR(I,J,K) = Source array (input, REAL*4)
C  ARY(I,J,K) = Target array (output, REAL*8)

C*********************************************************************

       IMPLICIT NONE
C       include 'msjunk.h'

      INCLUDE 'layout.h'

      INTEGER IDIM, JDIM, KDIM, LDIM, NBLK
      INTEGER IL1, IL2, JL1, JL2, KL1, KL2

      INTEGER JL1V(KDIM),JL2V(KDIM),    KEYOUT(IDIM,JDIM,KDIM)

      REAL*4 POR(IDIM,JDIM,KDIM)
      REAL*8 ARY(IDIM,JDIM,KDIM)
C -------------------------------------------------------------
      INTEGER I,J,K

c --------------------------------------------------------------
      DO K=KL1,KL2
         DO J=JL1V(K),JL2V(K)
            DO I=IL1,IL2
               IF(KEYOUT(I,J,K).EQ.1) THEN
                ARY(I,J,K)=POR(I,J,K)
             ENDIF
          ENDDO
       ENDDO
      ENDDO

      END

