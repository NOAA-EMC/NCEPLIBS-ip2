 module get_input_data       

!------------------------------------------------------------------------
! Read the data that will be interpolated.  Data is a global one-degree
! grid of 500 mb u and v-component winds.  There is no bitmap.
! The data file is flat binary (little endian).
!------------------------------------------------------------------------

 integer, parameter, public     :: input_gdtnum=0
 integer, parameter, public     :: input_gdtlen=19
 integer, public                :: input_gdtmpl(input_gdtlen)

 integer, public                :: i_input, j_input

 logical*1, allocatable, public :: input_bitmap(:,:)

 real, allocatable, public      :: input_u_data(:,:)
 real, allocatable, public      :: input_v_data(:,:)

 integer, parameter :: missing=b'11111111111111111111111111111111'

 data input_gdtmpl /6, 255, missing, 255, missing, 255, missing, &
                    360, 181, 0, missing, 90000000, 0, &
                    48, -90000000, 359000000, 1000000, 1000000, 0/

 contains

 subroutine input_data

 implicit none

 character*100             :: input_file

 integer                   :: iret
 integer, parameter        :: iunit=9

 real(kind=4), allocatable :: dummy(:,:)

 i_input = input_gdtmpl(8)
 j_input = input_gdtmpl(9)

 input_file="./fort.9"
!print*,"- OPEN AND READ FILE ", trim(input_file)
 open(iunit, file=input_file, access='direct', recl=i_input*j_input*4, iostat=iret)

 if (iret /= 0) then
   print*,'- BAD OPEN OF INPUT DATA FILE, IRET IS ', iret
   stop 2
 end if

 allocate(dummy(i_input,j_input))

 read(iunit, rec=1, iostat=iret) dummy

 if (iret /= 0) then
   print*,"- BAD READ OF INPUT U-WIND DATA. IRET IS ", iret
   stop 4
 endif

 allocate(input_u_data(i_input,j_input))
 input_u_data=dummy

 read(iunit, rec=2, iostat=iret) dummy

 if (iret /= 0) then
   print*,"- BAD READ OF INPUT V-WIND DATA. IRET IS ", iret
   stop 4
 end if

 allocate(input_v_data(i_input,j_input))
 input_v_data=dummy

 close (iunit)

 deallocate(dummy)

 allocate(input_bitmap(i_input,j_input))
 input_bitmap=.true.

! impose pure north wind
!input_u_data=0.
!input_v_data=-1.

 return

 end subroutine input_data

 end module get_input_data
