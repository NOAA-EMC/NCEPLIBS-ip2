module ipolates_mod
  use polates0_mod
  use polates1_mod
  use polates2_mod
  use polates3_mod
  use polates4_mod
  use polates6_mod
  use ip_grid_descriptor_mod
  use ip_grid_factory_mod
  use ip_grid_mod
  implicit none

  private
  public :: ipolates

  interface ipolates
     module procedure ipolates_grib1
     module procedure ipolates_grib2
  end interface ipolates
  

contains

  SUBROUTINE IPOLATES_grib1(IP,IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI, &
       NO,RLAT,RLON,IBO,LO,GO,IRET)
    IMPLICIT NONE
    !
    INTEGER,    INTENT(IN   ) :: IP, IPOPT(20), KM, MI, MO
    INTEGER,    INTENT(IN   ) :: IBI(KM), KGDSI(200), KGDSO(200)
    INTEGER,    INTENT(INOUT) :: NO
    INTEGER,    INTENT(  OUT) :: IRET, IBO(KM)
    !
    LOGICAL*1,  INTENT(IN   ) :: LI(MI,KM)
    LOGICAL*1,  INTENT(  OUT) :: LO(MO,KM)
    !
    REAL,       INTENT(IN   ) :: GI(MI,KM)
    REAL,       INTENT(INOUT) :: RLAT(MO),RLON(MO)
    REAL,       INTENT(  OUT) :: GO(MO,KM)
    !
    INTEGER                   :: K, N

    type(grib1_descriptor) :: desc_in, desc_out
    class(ip_grid), allocatable :: grid_in, grid_out

    desc_in = init_descriptor(kgdsi)
    desc_out = init_descriptor(kgdso)

    grid_in = init_grid(desc_in)
    grid_out = init_grid(desc_out)

    ! BILINEAR INTERPOLATION
    IF(IP.EQ.0) THEN
       CALL interpolate_bilinear_scalar(IPOPT,grid_in,grid_out,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  BICUBIC INTERPOLATION
    ELSEIF(IP.EQ.1) THEN
       ! CALL POLATES1(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       CALL interpolate_bicubic_scalar(IPOPT,grid_in,grid_out,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  NEIGHBOR INTERPOLATION
    ELSEIF(IP.EQ.2) THEN
       CALL POLATES2(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  BUDGET INTERPOLATION
    ELSEIF(IP.EQ.3) THEN
       CALL POLATES3(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  SPECTRAL INTERPOLATION
    ELSEIF(IP.EQ.4) THEN
       CALL POLATES4(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  NEIGHBOR-BUDGET INTERPOLATION
    ELSEIF(IP.EQ.6) THEN
       CALL POLATES6(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  UNRECOGNIZED INTERPOLATION METHOD
    ELSE
       IF(KGDSO(1).GE.0) NO=0
       DO K=1,KM
          IBO(K)=1
          DO N=1,NO
             LO(N,K)=.FALSE.
             GO(N,K)=0.
          ENDDO
       ENDDO
       IRET=1
    ENDIF
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  END SUBROUTINE IPOLATES_GRIB1
  

  SUBROUTINE IPOLATES_grib2(IP,IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
       IGDTNUMO,IGDTMPLO,IGDTLENO, &
       MI,MO,KM,IBI,LI,GI, &
       NO,RLAT,RLON,IBO,LO,GO,IRET)
    !$$$  SUBPROGRAM DOCUMENTATION BLOCK
    !
    ! SUBPROGRAM:  IPOLATES   IREDELL'S POLATE FOR SCALAR FIELDS
    !   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
    !
    ! ABSTRACT: THIS SUBPROGRAM INTERPOLATES SCALAR FIELDS
    !           FROM ANY GRID TO ANY GRID (JOE IRWIN'S DREAM).
    !           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
    !           THE FOLLOWING INTERPOLATION METHODS ARE POSSIBLE:
    !             (IP=0) BILINEAR
    !             (IP=1) BICUBIC
    !             (IP=2) NEIGHBOR
    !             (IP=3) BUDGET
    !             (IP=4) SPECTRAL
    !             (IP=6) NEIGHBOR-BUDGET
    !           SOME OF THESE METHODS HAVE INTERPOLATION OPTIONS AND/OR
    !           RESTRICTIONS ON THE INPUT OR OUTPUT GRIDS, BOTH OF WHICH
    !           ARE DOCUMENTED MORE FULLY IN THEIR RESPECTIVE SUBPROGRAMS.
    !
    !           THE INPUT AND OUTPUT GRIDS ARE DEFINED BY THEIR GRIB 2 GRID
    !           DEFINITION TEMPLATE AS DECODED BY THE NCEP G2 LIBRARY.  THE
    !           CURRENT CODE RECOGNIZES THE FOLLOWING PROJECTIONS, WHERE
    !           "IGDTNUMI/O" IS THE GRIB 2 GRID DEFINTION TEMPLATE NUMBER
    !           FOR THE INPUT AND OUTPUT GRIDS, RESPECTIVELY:
    !             (IGDTNUMI/O=00) EQUIDISTANT CYLINDRICAL
    !             (IGDTNUMI/O=01) ROTATED EQUIDISTANT CYLINDRICAL. "E" AND
    !                             NON-"E" STAGGERED
    !             (IGDTNUMI/O=10) MERCATOR CYLINDRICAL
    !             (IGDTNUMI/O=20) POLAR STEREOGRAPHIC AZIMUTHAL
    !             (IGDTNUMI/O=30) LAMBERT CONFORMAL CONICAL
    !             (IGDTNUMI/O=40) GAUSSIAN CYLINDRICAL
    !
    !           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
    !           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED.
    !           ON THE OTHER HAND, DATA MAY BE INTERPOLATED TO A SET OF STATION
    !           POINTS IF "IGDTNUMO"<0 (OR SUBTRACTED FROM 255 FOR THE BUDGET 
    !           OPTION), IN WHICH CASE THE NUMBER OF POINTS AND
    !           THEIR LATITUDES AND LONGITUDES MUST BE INPUT.
    !
    !           INPUT BITMAPS WILL BE INTERPOLATED TO OUTPUT BITMAPS.
    !           OUTPUT BITMAPS WILL ALSO BE CREATED WHEN THE OUTPUT GRID
    !           EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
    !           THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
    !        
    ! PROGRAM HISTORY LOG:
    !   96-04-10  IREDELL
    ! 2015-07-13  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAYS
    !                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAYS.
    !
    ! USAGE:    CALL IPOLATES(IP,IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI, &
    !                         IGDTNUMO,IGDTMPLO,IGDTLENO, &
    !                         MI,MO,KM,IBI,LI,GI, &
    !                         NO,RLAT,RLON,IBO,LO,GO,IRET)
    !
    !   INPUT ARGUMENT LIST:
    !     IP       - INTEGER INTERPOLATION METHOD
    !                (IP=0 FOR BILINEAR;
    !                 IP=1 FOR BICUBIC;
    !                 IP=2 FOR NEIGHBOR;
    !                 IP=3 FOR BUDGET;
    !                 IP=4 FOR SPECTRAL;
    !                 IP=6 FOR NEIGHBOR-BUDGET)
    !     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
    !                (IP=0: MIN % FOR MASK, SEARCH RADIUS
    !                 IP=1: CONSTRAINT OPTION, MIN % FOR MASK
    !                 IP=2: SEARCH RADIUS
    !                 IP=3: NUMBER IN RADIUS, RADIUS WEIGHTS, SEARCH RADIUS
    !                 IP=4: SPECTRAL SHAPE, SPECTRAL TRUNCATION
    !                 IP=6: NUMBER IN RADIUS, RADIUS WEIGHTS, MIN % FOR MASK
    !     IGDTNUMI - INTEGER GRID DEFINITION TEMPLATE NUMBER - INPUT GRID.
    !                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE:
    !                  00 - EQUIDISTANT CYLINDRICAL
    !                  01 - ROTATED EQUIDISTANT CYLINDRICAL.  "E"
    !                       AND NON-"E" STAGGERED
    !                  10 - MERCATOR CYCLINDRICAL
    !                  20 - POLAR STEREOGRAPHIC AZIMUTHAL
    !                  30 - LAMBERT CONFORMAL CONICAL
    !                  40 - GAUSSIAN EQUIDISTANT CYCLINDRICAL
    !     IGDTMPLI - INTEGER (IGDTLENI) GRID DEFINITION TEMPLATE ARRAY -
    !                INPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
    !                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE 
    !                (SECTION 3 INFO):
    !                ALL MAP PROJECTIONS:
    !                 (1):  SHAPE OF EARTH, OCTET 15
    !                 (2):  SCALE FACTOR OF SPHERICAL EARTH RADIUS,
    !                       OCTET 16
    !                 (3):  SCALED VALUE OF RADIUS OF SPHERICAL EARTH,
    !                       OCTETS 17-20
    !                 (4):  SCALE FACTOR OF MAJOR AXIS OF ELLIPTICAL EARTH,
    !                       OCTET 21
    !                 (5):  SCALED VALUE OF MAJOR AXIS OF ELLIPTICAL EARTH,
    !                       OCTETS 22-25
    !                 (6):  SCALE FACTOR OF MINOR AXIS OF ELLIPTICAL EARTH,
    !                       OCTET 26
    !                 (7):  SCALED VALUE OF MINOR AXIS OF ELLIPTICAL EARTH,
    !                       OCTETS 27-30
    !                EQUIDISTANT CYCLINDRICAL:
    !                 (8):  NUMBER OF POINTS ALONG A PARALLEL, OCTS 31-34
    !                 (9):  NUMBER OF POINTS ALONG A MERIDIAN, OCTS 35-38
    !                 (10): BASIC ANGLE OF INITIAL PRODUCTION DOMAIN,
    !                       OCTETS 39-42.
    !                 (11): SUBDIVISIONS OF BASIC ANGLE, OCTETS 43-46
    !                 (12): LATITUDE OF FIRST GRID POINT, OCTETS 47-50
    !                 (13): LONGITUDE OF FIRST GRID POINT, OCTETS 51-54
    !                 (14): RESOLUTION AND COMPONENT FLAGS, OCTET 55
    !                 (15): LATITUDE OF LAST GRID POINT, OCTETS 56-59
    !                 (16): LONGITUDE OF LAST GRID POINT, OCTETS 60-63
    !                 (17): I-DIRECTION INCREMENT, OCTETS 64-67
    !                 (18): J-DIRECTION INCREMENT, OCTETS 68-71
    !                 (19): SCANNING MODE, OCTET 72
    !                MERCATOR CYCLINDRICAL:
    !                 (8):  NUMBER OF POINTS ALONG A PARALLEL, OCTS 31-34
    !                 (9):  NUMBER OF POINTS ALONG A MERIDIAN, OCTS 35-38
    !                 (10): LATITUDE OF FIRST POINT, OCTETS 39-42
    !                 (11): LONGITUDE OF FIRST POINT, OCTETS 43-46
    !                 (12): RESOLUTION AND COMPONENT FLAGS, OCTET 47
    !                 (13): TANGENT LATITUDE, OCTETS 48-51
    !                 (14): LATITUDE OF LAST POINT, OCTETS 52-55
    !                 (15): LONGITUDE OF LAST POINT, OCTETS 56-59
    !                 (16): SCANNING MODE FLAGS, OCTET 60
    !                 (17): ORIENTATION OF GRID, OCTETS 61-64
    !                 (18): LONGITUDINAL GRID LENGTH, OCTETS 65-68
    !                 (19): LATITUDINAL GRID LENGTH, OCTETS 69-72
    !                LAMBERT CONFORMAL CONICAL:
    !                 (8):  NUMBER OF POINTS ALONG X-AXIS, OCTS 31-34
    !                 (9):  NUMBER OF POINTS ALONG Y-AXIS, OCTS 35-38
    !                 (10): LATITUDE OF FIRST POINT, OCTETS 39-42
    !                 (11): LONGITUDE OF FIRST POINT, OCTETS 43-46
    !                 (12): RESOLUTION OF COMPONENT FLAG, OCTET 47
    !                 (13): LATITUDE WHERE GRID LENGTHS SPECIFIED,
    !                       OCTETS 48-51
    !                 (14): LONGITUDE OF MERIDIAN THAT IS PARALLEL TO
    !                       Y-AXIS, OCTETS 52-55
    !                 (15): X-DIRECTION GRID LENGTH, OCTETS 56-59
    !                 (16): Y-DIRECTION GRID LENGTH, OCTETS 60-63
    !                 (17): PROJECTION CENTER FLAG, OCTET 64
    !                 (18): SCANNING MODE, OCTET 65
    !                 (19): FIRST TANGENT LATITUDE FROM POLE, OCTETS 66-69
    !                 (20): SECOND TANGENT LATITUDE FROM POLE, OCTETS 70-73
    !                 (21): LATITUDE OF SOUTH POLE OF PROJECTION,
    !                       OCTETS 74-77
    !                 (22): LONGITUDE OF SOUTH POLE OF PROJECTION,
    !                       OCTETS 78-81
    !                GAUSSIAN CYLINDRICAL:
    !                 (8):  NUMBER OF POINTS ALONG A PARALLEL, OCTS 31-34
    !                 (9):  NUMBER OF POINTS ALONG A MERIDIAN, OCTS 35-38
    !                 (10): BASIC ANGLE OF INITIAL PRODUCTION DOMAIN,
    !                       OCTETS 39-42
    !                 (11): SUBDIVISIONS OF BASIC ANGLE, OCTETS 43-46
    !                 (12): LATITUDE OF FIRST GRID POINT, OCTETS 47-50
    !                 (13): LONGITUDE OF FIRST GRID POINT, OCTETS 51-54
    !                 (14): RESOLUTION AND COMPONENT FLAGS, OCTET 55
    !                 (15): LATITUDE OF LAST GRID POINT, OCTETS 56-59
    !                 (16): LONGITUDE OF LAST GRID POINT, OCTETS 60-63
    !                 (17): I-DIRECTION INCREMENT, OCTETS 64-67
    !                 (18): NUMBER OF PARALLELS BETWEEN POLE AND EQUATOR,
    !                       OCTETS 68-71
    !                 (19): SCANNING MODE, OCTET 72
    !                POLAR STEREOGRAPHIC AZIMUTHAL:
    !                 (8):  NUMBER OF POINTS ALONG X-AXIS, OCTETS 31-34
    !                 (9):  NUMBER OF POINTS ALONG Y-AXIS, OCTETS 35-38
    !                 (10): LATITUDE OF FIRST GRID POINT, OCTETS 39-42
    !                 (11): LONGITUDE OF FIRST GRID POINT, OCTETS 43-46
    !                 (12): RESOLUTION AND COMPONENT FLAGS, OCTET 47
    !                 (13): TRUE LATITUDE, OCTETS 48-51
    !                 (14): ORIENTATION LONGITUDE, OCTETS 52-55
    !                 (15): X-DIRECTION GRID LENGTH, OCTETS 56-59
    !                 (16): Y-DIRECTION GRID LENGTH, OCTETS 60-63
    !                 (17): PROJECTION CENTER FLAG, OCTET 64
    !                 (18): SCANNING MODE FLAGS, OCTET 65
    !                ROTATED EQUIDISTANT CYCLINDRICAL:
    !                 (8):  NUMBER OF POINTS ALONG A PARALLEL, OCTS 31-34
    !                 (9):  NUMBER OF POINTS ALONG A MERIDIAN, OCTS 35-38
    !                 (10): BASIC ANGLE OF INITIAL PRODUCTION DOMAIN,
    !                       OCTETS 39-42
    !                 (11): SUBDIVISIONS OF BASIC ANGLE, OCTETS 43-46
    !                 (12): LATITUDE OF FIRST GRID POINT, OCTETS 47-50
    !                 (13): LONGITUDE OF FIRST GRID POINT, OCTETS 51-54
    !                 (14): RESOLUTION AND COMPONENT FLAGS, OCTET 55
    !                 (15): LATITUDE OF LAST GRID POINT, OCTETS 56-59
    !                 (16): LONGITUDE OF LAST GRID POINT, OCTETS 60-63
    !                 (17): I-DIRECTION INCREMENT, OCTETS 64-67
    !                 (18): J-DIRECTION INCREMENT, OCTETS 68-71
    !                 (19): SCANNING MODE, OCTET 72
    !                 (20): LATITUDE OF SOUTHERN POLE OF PROJECTION,
    !                       OCTETS 73-76
    !                 (21): LONGITUDE OF SOUTHERN POLE OF PROJECTION,
    !                       OCTETS 77-80
    !                 (22): ANGLE OF ROTATION OF PROJECTION, OCTS 81-84
    !     IGDTLENI - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY - INPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTNUMO - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
    !                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE. SEE "IGDTNUMI"
    !                FOR SPECIFIC TEMPLATE DEFINITIONS.  NOTE: IGDTNUMO<0
    !                MEANS INTERPOLATE TO RANDOM STATION POINTS.
    !     IGDTMPLO - INTEGER (IGDTLENO) GRID DEFINITION TEMPLATE ARRAY -
    !                OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
    !                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !                SEE "IGDTMPLI" FOR DEFINITION OF ARRAY ELEMENTS
    !     IGDTLENO - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY - OUTPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
    !                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
    !     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
    !                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
    !     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
    !     IBI      - INTEGER (KM) INPUT BITMAP FLAGS
    !     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF RESPECTIVE IBI(K)=1)
    !     GI       - REAL (MI,KM) INPUT FIELDS TO INTERPOLATE
    !     RLAT     - REAL (NO) OUTPUT LATITUDES IN DEGREES (IF IGDTNUMO<0)
    !     RLON     - REAL (NO) OUTPUT LONGITUDES IN DEGREES (IF IGDTNUMO<0)
    !
    !   OUTPUT ARGUMENT LIST:
    !     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF IGDTNUMO>=0)
    !     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF IGDTNUMO>=0)
    !     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF IGDTNUMO>=0)
    !     IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
    !     LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
    !     GO       - REAL (MO,KM) OUTPUT FIELDS INTERPOLATED
    !     IRET     - INTEGER RETURN CODE
    !                0    SUCCESSFUL INTERPOLATION
    !                1    UNRECOGNIZED INTERPOLATION METHOD
    !                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
    !                3    UNRECOGNIZED OUTPUT GRID
    !                1X   INVALID BICUBIC METHOD PARAMETERS
    !                3X   INVALID BUDGET METHOD PARAMETERS
    !                4X   INVALID SPECTRAL METHOD PARAMETERS
    !
    ! SUBPROGRAMS CALLED:
    !   POLATES0     INTERPOLATE SCALAR FIELDS (BILINEAR)
    !   POLATES1     INTERPOLATE SCALAR FIELDS (BICUBIC)
    !   POLATES2     INTERPOLATE SCALAR FIELDS (NEIGHBOR)
    !   POLATES3     INTERPOLATE SCALAR FIELDS (BUDGET)
    !   POLATES4     INTERPOLATE SCALAR FIELDS (SPECTRAL)
    !   POLATES6     INTERPOLATE SCALAR FIELDS (NEIGHBOR-BUDGET)
    !
    ! REMARKS: EXAMPLES DEMONSTRATING RELATIVE CPU COSTS.
    !   THIS EXAMPLE IS INTERPOLATING 12 LEVELS OF TEMPERATURES
    !   FROM THE 360 X 181 GLOBAL GRID (NCEP GRID 3)
    !   TO THE 93 X 68 HAWAIIAN MERCATOR GRID (NCEP GRID 204).
    !   THE EXAMPLE TIMES ARE FOR THE C90.  AS A REFERENCE, THE CP TIME
    !   FOR UNPACKING THE GLOBAL 12 TEMPERATURE FIELDS IS 0.04 SECONDS.
    !
    !   METHOD      IP  IPOPT          CP SECONDS
    !   --------    --  -------------  ----------
    !   BILINEAR    0                   0.03
    !   BICUBIC     1   0               0.07
    !   BICUBIC     1   1               0.07
    !   NEIGHBOR    2                   0.01
    !   BUDGET      3   -1,-1           0.48
    !   SPECTRAL    4   0,40            0.22
    !   SPECTRAL    4   1,40            0.24
    !   SPECTRAL    4   0,-1            0.42
    !   N-BUDGET    6   -1,-1           0.15
    !
    !   THE SPECTRAL INTERPOLATION IS FAST FOR THE MERCATOR GRID.
    !   HOWEVER, FOR SOME GRIDS THE SPECTRAL INTERPOLATION IS SLOW.
    !   THE FOLLOWING EXAMPLE IS INTERPOLATING 12 LEVELS OF TEMPERATURES
    !   FROM THE 360 X 181 GLOBAL GRID (NCEP GRID 3)
    !   TO THE 93 X 65 CONUS LAMBERT CONFORMAL GRID (NCEP GRID 211).
    !
    !   METHOD      IP  IPOPT          CP SECONDS
    !   --------    --  -------------  ----------
    !   BILINEAR    0                   0.03
    !   BICUBIC     1   0               0.07
    !   BICUBIC     1   1               0.07
    !   NEIGHBOR    2                   0.01
    !   BUDGET      3   -1,-1           0.51
    !   SPECTRAL    4   0,40            3.94
    !   SPECTRAL    4   1,40            5.02
    !   SPECTRAL    4   0,-1           11.36
    !   N-BUDGET    6   -1,-1           0.18
    !
    ! ATTRIBUTES:
    !   LANGUAGE: FORTRAN 90
    !
    !$$$
    IMPLICIT NONE
    !
    INTEGER,        INTENT(IN   )     :: IP, IPOPT(20), KM, MI, MO
    INTEGER,        INTENT(IN   )     :: IBI(KM)
    INTEGER,        INTENT(IN   )     :: IGDTNUMI, IGDTLENI
    INTEGER,        INTENT(IN   )     :: IGDTMPLI(IGDTLENI)
    INTEGER,        INTENT(IN   )     :: IGDTNUMO, IGDTLENO
    INTEGER,        INTENT(IN   )     :: IGDTMPLO(IGDTLENO)
    INTEGER,        INTENT(  OUT)     :: NO
    INTEGER,        INTENT(  OUT)     :: IRET, IBO(KM)
    !
    LOGICAL*1,      INTENT(IN   )     :: LI(MI,KM)
    LOGICAL*1,      INTENT(  OUT)     :: LO(MO,KM)
    !
    REAL,           INTENT(IN   )     :: GI(MI,KM)
    REAL,           INTENT(INOUT)     :: RLAT(MO),RLON(MO)
    REAL,           INTENT(  OUT)     :: GO(MO,KM)
    !
    INTEGER                           :: K, N

    type(grib2_descriptor) :: desc_in, desc_out
    class(ip_grid), allocatable :: grid_in, grid_out

    desc_in = init_descriptor(igdtnumi, igdtleni, igdtmpli)
    desc_out = init_descriptor(igdtnumo, igdtleno, igdtmplo)

    grid_in = init_grid(desc_in)
    grid_out = init_grid(desc_out)
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  BILINEAR INTERPOLATION
    IF(IP.EQ.0) THEN
       
       ! CALL POLATES0(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
       !      MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       CALL interpolate_bilinear_scalar(IPOPT,grid_in,grid_out,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  BICUBIC INTERPOLATION
    ELSEIF(IP.EQ.1) THEN
       ! CALL POLATES1(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
       !      MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       CALL interpolate_bicubic_scalar(IPOPT,grid_in,grid_out,MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  NEIGHBOR INTERPOLATION
    ELSEIF(IP.EQ.2) THEN
       CALL POLATES2(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
            MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  BUDGET INTERPOLATION
    ELSEIF(IP.EQ.3) THEN
       CALL POLATES3(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
            MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  SPECTRAL INTERPOLATION
    ELSEIF(IP.EQ.4) THEN
       CALL POLATES4(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
            MI,MO,KM,IBI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  NEIGHBOR-BUDGET INTERPOLATION
    ELSEIF(IP.EQ.6) THEN
       CALL POLATES6(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
            MI,MO,KM,IBI,LI,GI,NO,RLAT,RLON,IBO,LO,GO,IRET)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  UNRECOGNIZED INTERPOLATION METHOD
    ELSE
       IF(IGDTNUMO.GE.0) NO=0
       DO K=1,KM
          IBO(K)=1
          DO N=1,NO
             LO(N,K)=.FALSE.
             GO(N,K)=0.
          ENDDO
       ENDDO
       IRET=1
    ENDIF
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  END SUBROUTINE IPOLATES_GRIB2



end module ipolates_mod

