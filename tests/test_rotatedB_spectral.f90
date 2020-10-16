program test_rotatedB_spectral
  use input_data_mod
  use interp_mod
  implicit none

  call read_input_data
  call interp("205", "4")
end program test_rotatedB_spectral
