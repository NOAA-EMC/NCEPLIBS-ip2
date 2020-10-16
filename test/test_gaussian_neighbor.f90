program test_gaussian_neighbor
  use input_data_mod
  use interp_mod
  implicit none

  call read_input_data
  call interp("127", "2")
end program test_gaussian_neighbor
