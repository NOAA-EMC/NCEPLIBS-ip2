 subroutine interp

!-------------------------------------------------------------------------
! Call the scalar polates routines to interpolate the input data
! using all available interpolation methods (neighbor, bilinear, etc.)
! several output grids of various map projections are tested.
!
! The routine reads in two arguments from stnd input.  The first is
! the grid to which you want to interpolate the data.
! The valid choices are:
!
!    3 -  one-degree global lat/lon (ncep grid 3)
!    8 -  mercator (ncep grid 8)
!  127 -  t254 gaussian (ncep grid 127)
!  203 -  rotated lat/lon e-staggered (number refers to the old
!                                      grib 1 gds octet 6)
!  205 -  rotated lat/lon b-staggered (number refers to the old
!                                      gds octet 6)
!  212 -  nh polar stereographic, spherical earth (number meaningless)
!  218 -  lambert conformal (ncep grid 218)
!
! The second argument is the interpolation option.  The valid choices:
!
!  0 - bilinear
!  1 - bicubic
!  2 - neighbor
!  3 - budget
!  4 - spectral
!  6 - budget-neighbor
!
! The interpolated data is compared against a baseline binary
! file.  Any differences are written to standard output.
!-------------------------------------------------------------------------

 use get_input_data, only : input_data, &
                            input_gdtnum, &
                            input_gdtlen, &
                            input_gdtmpl, &
                            input_bitmap, &
                            i_input, j_input

 implicit none

 character*1               :: interp_opt
 character*3               :: grid
 character*100             :: baseline_file

 integer(kind=4)           :: i1
 integer, allocatable      :: output_gdtmpl(:)
 integer                   :: ip, ipopt(20), output_gdtlen, output_gdtnum
 integer                   :: km, ibi, mi, iret, i, j
 integer                   :: i_output, j_output, mo, no, ibo
 integer                   :: num_pts_diff
 integer     , parameter   :: missing=b'11111111111111111111111111111111'

 logical*1, allocatable    :: output_bitmap(:,:)

 real, allocatable         :: output_rlat(:,:), output_rlon(:,:)
 real, allocatable         :: output_data(:,:)
 real(kind=4), allocatable :: baseline_data(:,:)
 real                      :: avgdiff, maxdiff
 real(kind=4)              :: output_data4

 integer, parameter        :: gdtlen3 = 19  ! ncep grid3; one-degree lat/lon
 integer                   :: gdtmpl3(gdtlen3)
 data gdtmpl3 / 6, 255, missing, 255, missing, 255, missing, 360, 181, 0, missing, &
                90000000, 0, 56, -90000000, 359000000, 1000000, 1000000, 0 /

 integer, parameter        :: gdtlen8 = 19  ! ncep grid8; mercator
 integer                   :: gdtmpl8(gdtlen8)
 data gdtmpl8 / 6, 255, missing, 255, missing, 255, missing, 116, 44, &
                -48670000, 3104000, 56, 22500000, 61050000, 0, 64, 0, &
                 318830000, 318830000/

 integer, parameter        :: gdtlen127=19  ! t254 gaussain
 integer                   :: gdtmpl127(gdtlen127)
 data gdtmpl127 /6, 255, missing, 255, missing, 255, missing, 768, 384, &
                 0, missing, 89642000, 0, 48, -89642000, 359531000,  &
                 469000, 192, 0/

 integer, parameter        :: gdtlen203=22 ! 12km eta, h pts
 integer                   :: gdtmpl203(gdtlen203)
 data gdtmpl203/6, 255, missing, 255, missing, 255, missing, 669, 1165, &
                0, missing, -7446260, 215860330, 56, 44560150, 14744790, &
                179641, 77320, 68, -36000000, 254000000, 0 /

 integer, parameter        :: gdtlen205=22 ! 12km nam, h pts
 integer                   :: gdtmpl205(gdtlen205)
 data gdtmpl205/6, 255, missing, 255, missing, 255, missing, 954, 835, &
                0, missing, -7491200, 215866300, 56, 44539600, 14801500, &
                126000, 108000, 64, -36000000, 254000000, 0 /

 integer, parameter        :: gdtlen212=18 ! nh polar, spherical earth
 integer                   :: gdtmpl212(gdtlen212)
 data gdtmpl212 /6, 255, missing, 255, missing, 255, missing, 512, 512, &
                 -20826000, 145000000, 56, 60000000, 280000000, 47625000, 47625000, &
                 0, 0/

 integer, parameter        :: gdtlen218 = 22 ! ncep grid 218; lambert conf
 integer                   :: gdtmpl218(gdtlen218)
 data gdtmpl218 / 6, 255, missing, 255, missing, 255, missing, 614, 428, &
                  12190000, 226541000, 56, 25000000, 265000000, &
                  12191000, 12191000, 0, 64, 25000000, 25000000, -90000000, 0/

 i1=1
 call getarg(i1, grid)
 i1=2
 call getarg(i1, interp_opt)

 select case (trim(grid))
   case ('3')
     output_gdtnum = 0
     output_gdtlen = gdtlen3
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl3
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case ('8')
     output_gdtnum = 10
     output_gdtlen = gdtlen8
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl8
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case ('127')
     output_gdtnum = 40
     output_gdtlen = gdtlen127
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl127
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case ('203')
     output_gdtnum = 1
     output_gdtlen = gdtlen203
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl203
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case ('205')
     output_gdtnum = 1
     output_gdtlen = gdtlen205
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl205
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case ('212')
     output_gdtnum = 20
     output_gdtlen = gdtlen212
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl212
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case ('218')
     output_gdtnum = 30
     output_gdtlen = gdtlen218
     allocate(output_gdtmpl(output_gdtlen))
     output_gdtmpl=gdtmpl218
     i_output = output_gdtmpl(8)
     j_output = output_gdtmpl(9)
   case default
     print*,"ERROR: ENTER VALID GRID NUMBER."
     stop 55
 end select
 print*,"- CALL IPOLATES FOR GRID: ", grid

 select case (interp_opt)
! bi-linear
   case ('0')           
     ip = 0
     ipopt = 0  
     ibi   = 0  ! no bitmap
! bi-cubic
   case ('1')          
     ip = 1
     ipopt = 0  
     ibi   = 0  ! no bitmap
! neighbor
   case ('2')       
     ip = 2
     ipopt = 0  
     ibi   = 0  ! no bitmap
! budget
   case ('3')       
     ip = 3
     ipopt = -1  
     ibi   = 0  ! no bitmap
! spectral 
   case ('4')         
     ip = 4
     ipopt(1) = 0  ! triangular
     ipopt(2) = -1 ! code chooses wave number
     ipopt(3:20)=0
     ibi   = 0     ! can't use bitmap with spectral
! neighbor-budget
   case ('6')            
     ip = 6
     ipopt = -1  
     ibi   = 0  ! no bitmap
   case default
     print*,"ERROR: ENTER VALID INTERP OPTION."
     stop 56
 end select
 print*,"- USE INTERP OPTION: ", interp_opt

 km = 1  ! number of fields to interpolate
 mi = i_input * j_input ! dimension of input grids

 mo = i_output * j_output 

 allocate (output_rlat(i_output,j_output))
 allocate (output_rlon(i_output,j_output))
 allocate (output_data(i_output,j_output))
 allocate (output_bitmap(i_output,j_output))

 call ipolates(ip, ipopt, input_gdtnum, input_gdtmpl, input_gdtlen, &
               output_gdtnum, output_gdtmpl, output_gdtlen, &
               mi, mo, km, ibi, input_bitmap, input_data, &
               no, output_rlat, output_rlon, ibo, output_bitmap, output_data, iret)

 deallocate (output_gdtmpl)

 if (iret /= 0) then
   print*,'- BAD STATUS FROM IPOLATES: ', iret
   stop 6
 end if

 if (no /= mo) then
   print*,'- ERROR: WRONG # OF POINTS RETURNED FROM IPOLATES'
   stop 7
 end if

!print*,'- SUCCESSFULL CALL TO IPOLATES'

 do j = 1, j_output
 do i = 1, i_output
    if (.not. output_bitmap(i,j)) then
      output_data(i,j) = -9.
    endif
 enddo
 enddo

 allocate (baseline_data(i_output,j_output))

 if (kind(output_data) == 8) then
   baseline_file = "../baseline_data/scalar/8_byte_bin/grid" // trim(grid) // ".opt" // interp_opt // ".bin_8"
 else
   baseline_file = "../baseline_data/scalar/4_byte_bin/grid" // trim(grid) // ".opt" // interp_opt // ".bin_4"
 endif

 open (12, file=baseline_file, access="direct", err=38, recl=mo*4)
 read (12, err=38, rec=1) baseline_data
 close (12)

 avgdiff=0.0
 maxdiff=0.0
 num_pts_diff=0

 do j = 1, j_output
 do i = 1, i_output
   output_data4 = real(output_data(i,j),4)
   if ( abs(output_data4 - baseline_data(i,j)) > 0.0001) then
     avgdiff = avgdiff + abs(output_data4-baseline_data(i,j))
     num_pts_diff = num_pts_diff + 1
     if (abs(output_data4-baseline_data(i,j)) > abs(maxdiff))then
       maxdiff = output_data4-baseline_data(i,j)
     endif
   endif
 enddo
 enddo
 
 print*,'- MAX/MIN OF DATA: ', maxval(output_data),minval(output_data)
 print*,'- NUMBER OF PTS DIFFERENT: ',num_pts_diff
 print*,'- PERCENT OF TOTAL: ',(float(num_pts_diff)/float(i_output*j_output))*100.
 print*,'- MAX DIFFERENCE: ', maxdiff
 if (num_pts_diff > 0) then
   avgdiff = avgdiff / float(num_pts_diff)
 endif
 print*,'- AVG DIFFERENCE: ', avgdiff

 deallocate (output_rlat, output_rlon, output_data, output_bitmap, baseline_data)

 return

 38 continue

 print*,'-ERROR READING BASELINE DATA FILE FILE.'
 stop 77

 end subroutine interp
