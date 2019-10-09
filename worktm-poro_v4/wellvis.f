C  WELL LOCATION DATA
C  Have to output a full grid array, containing zeros
C  except where a well is present, and at those cells we
C  store the type of the well, so type can be plotted.

C  This is a work routine, since it needs direct access to the
C  grid arrays.

      SUBROUTINE WELLVIS(IDIM,JDIM,KDIM,LDIM,IL1,IL2,
     &                   JL1V,JL2V,KL1,KL2,
     &                   KEYOUT,NBLK,
     &                   DUMMY,NDIR)

       INTEGER JL1V(KDIM),JL2V(KDIM), KEYOUT(IDIM,JDIM,KDIM)
       INTEGER IOFF,JOFF,KOFF,MERR
       INTEGER NBLK,NDIR,I,J,K,L
       REAL*8  DUMMY(IDIM,JDIM,KDIM)
c -------------------------------------------------------
c   NDIR = 1 means put well locations into dummy
c   NDIR = 0 means clean up dummy to just zeros
c -------------------------------------------------------

C       include 'msjunk.h'

       INCLUDE "wells.h"
       INCLUDE "control.h"

        CALL BLKOFF(NBLK,IOFF,JOFF,KOFF,MERR)
        DO  L= 1, NUMWEL
          DO M = 1, NUMELE(L)
c           write(*,*) myprc,'inside wellvis',L,NDIR, LOCWEL(6,m,l)
            IF(LOCWEL(6,M,L).EQ.MYPRC.and.LOCWEL(1,M,L).EQ.NBLK) then
               I = LOCWEL(3,M,L)-IOFF
               J = LOCWEL(4,M,L)-JOFF
               K = LOCWEL(5,M,L)-KOFF
C             write(*,*) 'well',L,I,J,K,KWELL(L)
               if(NDIR.EQ.1) DUMMY(i,j,k) = kwell(L)
               if(NDIR.EQ.0) DUMMY(i,j,k) = 0.D0
            ENDIF
          ENDDO
        ENDDO

        return
        end
