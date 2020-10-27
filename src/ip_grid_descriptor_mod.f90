module ip_grid_descriptor_mod
  implicit none
  private

  public :: ip_grid_descriptor
  public :: grib1_descriptor, grib2_descriptor
  public :: init_grib1_descriptor, init_grib2_descriptor

  type, abstract :: ip_grid_descriptor
     integer :: grid_number
     integer :: im, jm
  end type ip_grid_descriptor

  type, extends(ip_grid_descriptor) :: grib1_descriptor
     integer :: gds(200)
   contains
  end type grib1_descriptor
    
  type, extends(ip_grid_descriptor) :: grib2_descriptor
     integer :: gdt_num, gdt_len
     integer, allocatable :: gdt_tmpl(:)
     contains
  end type grib2_descriptor

contains

  function init_grib1_descriptor(gds) result(desc)
    type(grib1_descriptor) :: desc
    integer, intent(in) :: gds(:)
    desc%gds = gds
    desc%grid_number = gds(1)
  end function init_grib1_descriptor

  function init_grib2_descriptor(gdt_num, gdt_len, gdt_tmpl) result(desc)
    type(grib2_descriptor) :: desc
    integer, intent(in) :: gdt_num, gdt_len, gdt_tmpl(:)
    desc%grid_number = gdt_num

    desc%gdt_num = gdt_num
    desc%gdt_len = gdt_len
    allocate(desc%gdt_tmpl(gdt_len))
    desc%gdt_tmpl = gdt_tmpl
    
  end function init_grib2_descriptor

end module ip_grid_descriptor_mod
