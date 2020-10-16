program test_polar_stereo_neighbor_budget
  use input_data_mod
  use interp_mod
  implicit none

  call read_input_data
  call interp("212", "6")
end program test_polar_stereo_neighbor_budget
