# Interpolation Library 2

**The NCEPLIBS-ip2 library has been deprecated. Please do not use
it in new work.** All functionality from the NCEPLIBS-ip2 library has
been merged into the
[NCEPLIBS-ip](https://github.com/NOAA-EMC/NCEPLIBS-ip) library. Please
use the NCEPLIBS-ip library for all future development. **No further
release of NCEPLIBS-ip2 will be made.**

The NCEP general interpolation library 2 contains Fortran 90
subprograms to be used for interpolating between nearly all grids used
at NCEP. The library is particularly efficient when interpolating many
fields at one time.

This is part of the [NCEPLIBS](https://github.com/NOAA-EMC/NCEPLIBS)
project.

There are currently six interpolation methods available in the
library:
- bilinear
- bicubic
- neighbor
- budget
- spectral
- neighbor-budget

To submit bug reports, feature requests, or other code-related issues including installation and usage questions, please create a [GitHub issue](https://github.com/NOAA-EMC/NCEPLIBS-ip2/issues). For general NCEPLIBS inquiries, contact [Edward Hartnett](mailto:edward.hartnett@noaa.gov) (secondary point of contact [Alex Richert](mailto:alexander.richert@noaa.gov)).

### Authors

* NCEP/EMC Developers

Code Manager: [George Gayno](mailto:george.gayno@noaa.gov)

### Prerequisites

This package requires the [NCEPLIBS-sp](https://github.com/NOAA-EMC/NCEPLIBS-sp) library.

### Installing

```
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX=/path/to/install /path/to/NCEPLIBS-ip2
make -j2
make install
```

### Testing

Testing requires [pFUnit](https://github.com/Goddard-Fortran-Ecosystem/pFUnit).

```
cmake -DENABLE_TESTS=ON -DCMAKE_PREFIX_PATH="/path/to/pfunit;/path/to/NCEPLIBS" /path/to/NCEPLIBS-ip
make -j2
make test
```

## Disclaimer

The United States Department of Commerce (DOC) GitHub project code is
provided on an "as is" basis and the user assumes responsibility for
its use. DOC has relinquished control of the information and no longer
has responsibility to protect the integrity, confidentiality, or
availability of the information. Any claims against the Department of
Commerce stemming from the use of its GitHub project will be governed
by all applicable Federal law. Any reference to specific commercial
products, processes, or services by service mark, trademark,
manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of
Commerce. The Department of Commerce seal and logo, or the seal and
logo of a DOC bureau, shall not be used in any manner to imply
endorsement of any commercial product or activity by DOC or the United
States Government.
