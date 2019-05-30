# *** manually set environments (for gnu compiler) of ip2 ***

# !!! module environment (*THEIA*) !!!
 module load gcc/6.2.0

 ANCHORDIR=..
 export COMP=gnu
 export IP2_VER=v1.0.0
 export IP2_SRC=
 export IP2_INC4=$ANCHORDIR/include/ip2_${IP2_VER}_4
 export IP2_INC8=$ANCHORDIR/include/ip2_${IP2_VER}_8
 export IP2_INCd=$ANCHORDIR/include/ip2_${IP2_VER}_d
 export IP2_LIB4=$ANCHORDIR/libip2_${IP2_VER}_4.a
 export IP2_LIB8=$ANCHORDIR/libip2_${IP2_VER}_8.a
 export IP2_LIBd=$ANCHORDIR/libip2_${IP2_VER}_d.a

 export CC=gcc
 export FC=gfortran
 export CPP=cpp
 export OMPCC="$CC -fopenmp"
 export OMPFC="$FC -fopenmp"
 export MPICC=mpigcc
 export MPIFC=mpigfortran

 export DEBUG="-g -O0"
 export CFLAGS="-O3 -fPIC"
 export FFLAGS="-O3 -fconvert=little-endian -fPIC"
 export FREEFORM="-ffree-form"
 export FPPCPP="-cpp"
 export CPPFLAGS="-P -traditional-cpp"
 export MPICFLAGS="-O3 -fPIC"
 export MPIFFLAGS="-O3 -fPIC"
 export MODPATH="-J"
 export I4R4=""
 export I4R8="-fdefault-real-8"
 export I8R8="-fdefault-integer-8 -fdefault-real-8"

 export CPPDEFS=""
 export CFLAGSDEFS="-DUNDERSCORE -DLINUX"
 export FFLAGSDEFS=""

 export USECC=""
 export USEFC="YES"
 export DEPS=""
