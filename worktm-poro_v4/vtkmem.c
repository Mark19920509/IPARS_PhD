// SGT 9/25/09 - Memory management routine in C for vtk visualization
#include <stdlib.h>
#include <math.h>
#include "memory.h"
#include "cfsimple.h"
#include "visualc.h"

FORTSUB  vtkcallwork_  (FORTSUB (*subadd) (), PINT4 subdat);

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
FORTSUB vtkcallwork_ (FORTSUB (*subadd) (), PINT4 d)
{
// *******************************************************************

// Calls a work routine for all grid block for which a processor has
// grid elements.

// subadd = Name of the work routine (input).  The FORTRAN statement
// EXTERNAL WORK
// must appear in the subroutine that calls CALLWORK.

// d[ ]= Work routine data vector. (input)
// d[0] = na = Number of arguments after the 12 standard arguments.
// d[1] to d(na) = numary values set by ALCGEA, ALCRFA, or PNTVAR.

// Note:  na is constrained to the following values: 0 to 20, 25, 30, 35,
//        40, 45, 50, 55, 60, and 65.  If an na value is less than 60 but not
//        in this set, the argument list can be filled out with dummy arguments.

// Note:  allblk = 0 ==> Call work routine even if processor has no elements
//                       in the fault block
//        allblk = 1 ==> Call work routine only if processor has elements
//                       in the fault block

// The first 12 arguments of all work routines are:

// IDIM, JDIM, KDIM = The first three local dimensions of grid-element arrays
// (input).  Space for communication layers are included in these dimensions.

// LDIM = The first dimension of grid-refinement arrays (input).

// IL1, IL2 = the smallest and largest local I indexes for which the work
// routine is responsible (input).

// JL1V(K), JL2V(K) = the smallest and largest local J indexes for which
// the work routine is responsible in row K. (input).

// KL1, KL2 = the smallest and largest local K indexes for which the work
// routine is responsible (input).

// KEYOUT(I,J,K) = an array defining element type.  Local indexes are
// used as subscripts for KEYOUT. (input)
// 0  ==> The grid element does not exist.  It may be outside the boundary
//        of the reservoir or may represent a shale.
// 1  ==> The grid element exists and belongs to the current processor.
//        The element is not refined.
// -1 ==> The grid element exists but belongs to a neighboring processor.
//        The element is not refined.
// N  ==> The grid element exists and belongs to the current processor.
//        The element is refined and N points to the 1st refinement index.
// -N ==> The grid element exists but belongs to a neighboring processor.
//        The element is refined and N points to the 1st refinement index.

// NBLK = Grid-block number (input) (mod 1).

// *******************************************************************
  int n, narg, nbp, nblk, j1, k1, j2, k2, j2g, k2g, pid, mpptr, nocontinue;
  char pvtufilename[MAXSTRLEN];
  void **a;
  FILE *pvtuPtr;

  narg = d[0] + 12L;

  for (nbcw = 0; nbcw < numblks; nbcw++){

//    if ( (CurrentModel !=0) &&
//	 (blkmodel_c[nbcw] != CurrentModel) && (allblk !=0) ) {
//
////      if(mm_debug)
////	  fprintf(fmemory,
////	  	    "\n Skipping block %d with model %d for the model %d",
////	      nbcw,blkmodel_c[nbcw],CurrentModel);
//
//      continue;
//    } else {
//
////      if(mm_debug)
////      fprintf(fmemory,
////	      "\n Continuing for block %d model %d with current model %d",
////	     nbcw,blkmodel_c[nbcw],CurrentModel);
//
//   }


// saumik
    if (*mblock)
    {
     if((*modact !=0) && (blkmodel_c[nbcw] != *modact) && (allblk !=0))
       continue;
    }
    else
    {
    if((CurrentModel !=0) && (blkmodel_c[nbcw] != CurrentModel)
                          && (allblk !=0) )
      continue;
    }
// saumik
    if ((myelem[nbcw] > 0) || (allblk == 0)){
      nbp = nbcw + 1;
      a = &(aryadd[nbcw][0]);

      // check if there would be no calls with NULL ptrs passed
      // for all grid arrays
      nocontinue = 0;
      for (mpptr=1;mpptr < d[0];mpptr++) {
	const int modptr = arymodel[d[mpptr]];

	if (
	    (a[d[mpptr]] == NULL) ||
	    ( ( CurrentModel*modptr !=0) && (modptr!=CurrentModel) )
	    ) {
	  printf	("\n Null ptr for array %d", d[mpptr]);	
	  //  if(mm_debug)
	  //  fprintf	(fmemory,
	  // "\n Null ptr for array %d", d[mpptr]);	
	
	  nocontinue = 1; break;
	} else	{	
		
	  //	if (mm_debug)
	  //	  fprintf(fmemory,
	  //   "\n CALLWORK OK ptr for array %d Block agreement: %d=%d ? %d",
	  //    d[mpptr], modptr, CurrentModel,
	  //  (modptr*CurrentModel==0 ? 1 :
	  //(modptr == CurrentModel)
	  //	   ));	
	}
      }
      if (nocontinue) break;

      // now that all the NULL ptrs have been checked,
      // pass the appropriate arguments
      switch(narg)
      {
         case 12:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp);
            break;
         case 13:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]));
            break;
         case 14:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]));
            break;
         case 15:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]));
            break;
         case 16:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]));
            break;
         case 17:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]));
            break;
         case 18:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]));
            break;
         case 19:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]));
            break;
         case 20:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]));
            break;
         case 21:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]));
            break;
         case 22:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]));
            break;
         case 23:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]));
            break;
         case 24:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]));
            break;
         case 25:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]));
            break;
         case 26:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]));
            break;
         case 27:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]));
            break;
         case 28:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]));
            break;
         case 29:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]));
            break;
         case 30:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]));
            break;
         case 31:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]));
            break;
         case 32:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]));
            break;
// MP: put more values
         case 33:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]));
            break;
         case 34:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]));		
            break;
         case 35:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]));		
            break;
         case 36:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]));
            break;
         case 37:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]));
            break;
         case 38:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]));
            break;
         case 39:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]));
            break;
         case 40:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]));
            break;
         case 41:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]));
            break;
         case 42:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]));
            break;
         case 43:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]));
            break;
         case 44:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]));
            break;
         case 45:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]));
            break;
         case 46:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]));
            break;
         case 47:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]));
            break;
         case 48:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]));
            break;
         case 49:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]));
            break;
         case 50:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]));
            break;
         case 51:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]));
            break;
         case 52:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]));
            break;
         case 53:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]));
            break;
         case 54:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]));
            break;
         case 55:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]));
            break;
         case 56:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]));
            break;
         case 57:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]));
            break;
         case 58:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]));
            break;
         case 59:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]));
            break;
         case 60:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]));
            break;
         case 61:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]));
            break;
         case 62:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]));
            break;
         case 63:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]));
            break;
         case 64:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]));
            break;
         case 65:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]));
            break;
         case 66:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]));
            break;
         case 67:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]));
            break;
         case 68:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]));
            break;
         case 69:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]));
            break;
         case 70:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]));
            break;
         case 71:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]));
            break;
         case 72:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]),*(a+d[60]));
            break;
         case 73:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]),*(a+d[60]),
               *(a+d[61]));
            break;
         case 74:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]),*(a+d[60]),
               *(a+d[61]),*(a+d[62]));
            break;
         case 75:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]),*(a+d[60]),
               *(a+d[61]),*(a+d[62]),*(a+d[63]));
            break;
         case 76:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]),*(a+d[60]),
               *(a+d[61]),*(a+d[62]),*(a+d[63]),*(a+d[64]));
            break;
         case 77:
            (*subadd) (&(idim[nbcw]),&(jdim[nbcw]),&(kdim[nbcw]),&dimr,
               &(iloc1[nbcw]),&(iloc2[nbcw]),jloc1[nbcw],jloc2[nbcw],
               &(kloc1[nbcw]),&(kloc2[nbcw]),keyout[nbcw],&nbp,
               *(a+d[1]),*(a+d[2]),*(a+d[3]),*(a+d[4]),*(a+d[5]),
               *(a+d[6]),*(a+d[7]),*(a+d[8]),*(a+d[9]),*(a+d[10]),
               *(a+d[11]),*(a+d[12]),*(a+d[13]),*(a+d[14]),*(a+d[15]),
               *(a+d[16]),*(a+d[17]),*(a+d[18]),*(a+d[19]),*(a+d[20]),
               *(a+d[21]),*(a+d[22]),*(a+d[23]),*(a+d[24]),*(a+d[25]),
               *(a+d[26]),*(a+d[27]),*(a+d[28]),*(a+d[29]),*(a+d[30]),
               *(a+d[31]),*(a+d[32]),*(a+d[33]),*(a+d[34]),*(a+d[35]),
               *(a+d[36]),*(a+d[37]),*(a+d[38]),*(a+d[39]),*(a+d[40]),
               *(a+d[41]),*(a+d[42]),*(a+d[43]),*(a+d[44]),*(a+d[45]),
               *(a+d[46]),*(a+d[47]),*(a+d[48]),*(a+d[49]),*(a+d[50]),
               *(a+d[51]),*(a+d[52]),*(a+d[53]),*(a+d[54]),*(a+d[55]),
               *(a+d[56]),*(a+d[57]),*(a+d[58]),*(a+d[59]),*(a+d[60]),
               *(a+d[61]),*(a+d[62]),*(a+d[63]),*(a+d[64]),*(a+d[65]));
            break;
         default:
            break;
         }
      }
   }
nbcw = -1;
allblk = 1L;

const int visflag = _Vis_flag;
//if ((visflag != 7) && (visflag != 8) && (visflag != 10)) // original code
if ((visflag != 7) && (visflag != 8) && (visflag != 10) && (!*mblock))
{
  fprintf(stderr,"Warning: Invalid visflag %d at step %d for vtkoutput\n",
          visflag,_Nstep);
  return;
}

if(mynod == 0)
{
   // gp  - extend support for dirname to vtk output
   sprintf(pvtufilename,"%s%s_nstep_%d.pvtu",DIRname,ROOTname,_Nstep);
   pvtuPtr = fopen(pvtufilename,"a");
   if(pvtuPtr==NULL)
   {
      fprintf(stderr,"Error opening file %s\n",pvtufilename);
      return;
   }
   for(pid = 0; pid < numprcs; pid++)
      for(nblk = 0; nblk < numblks; nblk++)
         if(prcblk[nblk][pid] > 0)
            fprintf(pvtuPtr,"    <Piece Source=\"%s_ZONE.%d.%d.%d.%d.vtu\"/>\n",
                    ROOTname,nblk,pid,visflag,_Nstep);
   fclose(pvtuPtr);
}

return;
}