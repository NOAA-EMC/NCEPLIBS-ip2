program test_latlon_bilinear
  use input_data_mod
  use interp_mod
  implicit none

  call read_input_data
  call interp("3", "0")
end program test_latlon_bilinear
