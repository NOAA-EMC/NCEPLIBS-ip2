program test_lambert_bilinear
  use input_data_mod
  use interp_mod
  implicit none

  call read_input_data
  call interp("218", "0")
end program test_lambert_bilinear
