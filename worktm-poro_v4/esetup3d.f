C*********************************************************************
      SUBROUTINE ESETUP_KEYOUT(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &           JL2V,KL1,KL2,KEYOUT,NBLK,KEYOUT_CR)
C*********************************************************************
C Setup keyout values for corner points. It's a workroutine
C
C INPUT:
C   KEYOUT_CR = CORNER POINT KEYOUT (OUTPUT, INTEGER)
C*********************************************************************
      INCLUDE 'control.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        KEYOUT_CR(IDIM,JDIM,KDIM)

      INTEGER I,J,K,KEY,CTR1,CTR2

      JL1V(KL1-1)=JL1V(KL1)
      JL2V(KL1-1)=JL2V(KL1)
      JL1V(KL2+1)=JL1V(KL2)
      JL2V(KL2+1)=JL2V(KL2)
      JL1V(KL1-2)=JL1V(KL1)
      JL2V(KL1-2)=JL2V(KL1)
      JL1V(KL2+2)=JL1V(KL2)
      JL2V(KL2+2)=JL2V(KL2)
      DO K=1,KDIM
         DO J=1,JDIM
            DO I=1,IDIM
               KEYOUT_CR(I,J,K)=KEYOUT(I,J,K)
            ENDDO
         ENDDO
      ENDDO
      DO K=1,KDIM
         DO J=1,JDIM
            DO I=IL1,IL2
               KEY=KEYOUT(I,J,K)
               IF(KEY.NE.0) THEN
                  KEYOUT_CR(I,J,K)=KEY
                  IF (J.LT.JDIM) KEYOUT_CR(I,J+1,K)=KEY
                  IF (K.LT.KDIM) KEYOUT_CR(I,J,K+1)=KEY
                  IF (J.LT.JDIM.AND.K.LT.KDIM) KEYOUT_CR(I,J+1,K+1)=KEY
                  IF (I.LT.IDIM) THEN
                     KEYOUT_CR(I+1,J,K)=KEY
                     IF(J.LT.JDIM) KEYOUT_CR(I+1,J+1,K)=KEY
                     IF(K.LT.KDIM) KEYOUT_CR(I+1,J,K+1)=KEY
                     IF(J.LT.JDIM.AND.K.LT.KDIM)
     &                  KEYOUT_CR(I+1,J+1,K+1)=KEY
                  ENDIF
               ENDIF
            ENDDO
         ENDDO
      ENDDO

      END


C*********************************************************************
      SUBROUTINE ESETUP_ELEM_NODE(IDIM,JDIM,KDIM,LDIM,IL1,IL2,JL1V,
     &           JL2V,KL1,KL2,KEYOUT,NBLK,ELEM_LID,NODE_LID)
C*********************************************************************
C Setup local element id to be sent to porohex. It's a workroutine
C
C OUTPUT:
C   ELEM_LID = LOCAL ELEMENT ID TO BE SENT TO POROHEX
C              INCLUDES BOTH ACTIVE AND GHOST ELEMENT
C********************************************************************
      IMPLICIT NONE
      INCLUDE 'control.h'
      INCLUDE 'hypre.h'

      INTEGER IDIM,JDIM,KDIM,LDIM,IL1,IL2,KL1,KL2,NBLK
      INTEGER JL1V(KDIM),JL2V(KDIM),KEYOUT(IDIM,JDIM,KDIM),
     &        ELEM_LID(IDIM,JDIM,KDIM),NODE_LID(IDIM,JDIM,KDIM)

      INTEGER I,J,K,CTR,JL1,JL2

      ELEM_LID = 0
      NODE_LID = 0
      CTR = 0

      DO K=KL1-1,KL2+1
         JL1 = MIN(JL1V(K-1),JL1V(K),JL1V(K+1))
         JL2 = MAX(JL2V(K-1),JL2V(K),JL2V(K+1))
         DO J=JL1-1,JL2+1
            DO I=IL1,IL2
               IF (KEYOUT(I,J,K).EQ.1 .OR. KEYOUT(I,J,K).EQ.-1) THEN
                  CTR = CTR+1
                  ELEM_LID(I,J,K) = CTR
                  NODE_LID(I,J,K)=1
                  IF (J.LT.JDIM) NODE_LID(I,J+1,K)=1
                  IF (K.LT.KDIM) NODE_LID(I,J,K+1)=1
                  IF (J.LT.JDIM.AND.K.LT.KDIM) NODE_LID(I,J+1,K+1)=1
                  IF (I.LT.IDIM) THEN
                     NODE_LID(I+1,J,K)=1
                     IF(J.LT.JDIM) NODE_LID(I+1,J+1,K)=1
                     IF(K.LT.KDIM) NODE_LID(I+1,J,K+1)=1
                     IF(J.LT.JDIM.AND.K.LT.KDIM)
     &                  NODE_LID(I+1,J+1,K+1)=1
                  ENDIF
               ENDIF
             ENDDO
         ENDDO
      ENDDO
      POROHEX_LALLELEM = CTR

      CTR = 0
      DO K = 1,KDIM
         DO J = 1,JDIM
            DO I = IL1,IL2+1
               IF (NODE_LID(I,J,K).EQ.1) THEN
                  CTR = CTR+1
                  NODE_LID(I,J,K) = CTR
               ENDIF
            ENDDO
         ENDDO
      ENDDO
      POROHEX_LALLSIZE = CTR

      END






