 program driver

!-----------------------------------------------------------------
! Interpolate a global lat/lon grid of scalars to several
! grids of various projections using all ipolates 
! interpolation options.
!-----------------------------------------------------------------

 use omp_lib
 use get_input_data

 implicit none

 integer :: nthreads, myid

!$omp parallel private (nthreads, myid)
 myid = omp_get_thread_num()
 if (myid == 0) then
   nthreads = omp_get_num_threads()
   print*,"- RUNNING WITH ", nthreads, " THREADS."
 endif
!$omp end parallel

 call read_input_data

 call interp

!print*,"- NORMAL TERMINATION"

 stop
 end program driver
