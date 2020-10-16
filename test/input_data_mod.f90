module input_data_mod
  implicit none
  
  !------------------------------------------------------------------------
  ! Read the data that will be interpolated.  Data is a global one-degree
  ! grid of albedo with no bitmap.
  !------------------------------------------------------------------------

  integer, parameter, public     :: i_input = 360
  integer, parameter, public     :: j_input = 180

  integer, parameter, public     :: input_gdtnum=0
  integer, parameter, public     :: input_gdtlen=19
  integer, public                :: input_gdtmpl(input_gdtlen)

  logical*1, public  :: input_bitmap(i_input,j_input)

  real, public       :: input_data(i_input,j_input)

  integer, parameter :: missing=b'11111111111111111111111111111111'

  data input_gdtmpl /6, 255, missing, 255, missing, 255, missing, &
       360, 180, 0, missing, -89500000, -180000000, &
       48, 89500000, 179000000, 1000000, 1000000, 64/

contains

  subroutine read_input_data

    implicit none

    character*100      :: input_file

    integer            :: iret
    integer, parameter :: iunit=9

    real(kind=4)       :: dummy(i_input,j_input)

    input_file="data/input_data/scalar/global_snoalb.bin"
    !print*,"- OPEN AND READ FILE ", trim(input_file)
    open(iunit, file=input_file, access='direct', recl=i_input*j_input*4,  &
         iostat=iret)

    if (iret /= 0) then
       print*,'- BAD OPEN OF FILE, IRET IS ', iret
       stop 2
    end if

    read(iunit, rec=1, iostat=iret) dummy
    input_data=dummy

    if (iret /= 0) then
       print*,"- BAD READ OF DATA. IRET IS ", iret
       stop 4
    end if

    close (iunit)

    input_bitmap=.true.

    return

  end subroutine read_input_data

end module input_data_mod
