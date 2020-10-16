program test_mercator_bicubic
  use input_data_mod
  use interp_mod
  implicit none

  call read_input_data
  call interp("8", "1")
end program test_mercator_bicubic
