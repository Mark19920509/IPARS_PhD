! -------------------------------------------------------------------
!     MCONTR0L.H - CONTROL DATA for Multi Model: included in control.h

      integer blkmodel,current_model

      common /cmmodel/ blkmodel (10), current_model

!*********************************************************************
! blkmodel() - array which describes which model should be used
! 	in which faultblock
! 	blkmodel(1) = 5 means in faultblock 1 model 5 (hydro) is used
!
! current_model - flag which describes if the current routine is
!      a framework routine (current_model =ALL =0)
!      or if it is a model dependent routine: then it indicates
!      for which model it is to be executed. (current_model = HYDRO)
!      these flags are later used by callwork to determine over which
!      fault blocks they should execute the code
!**********************************************************************