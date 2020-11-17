MODULE GDSWZD_MOD
  use ip_grid_descriptor_mod
  !$$$  MODULE DOCUMENTATION BLOCK
  !
  ! MODULE:  GDSWZD_MOD  GDS WIZARD MODULE
  !   PRGMMR: GAYNO     ORG: W/NMC23       DATE: 2015-01-21
  !
  ! ABSTRACT: DRIVER MODULE FOR GDSWZD ROUTINES.  THESE ROUTINES
  !           DO THE FOLLOWING FOR SEVERAL MAP PROJECTIONS:
  !            - CONVERT FROM EARTH TO GRID COORDINATES OR VICE VERSA.
  !            - COMPUTE VECTOR ROTATION SINES AND COSINES.
  !            - COMPUTE MAP JACOBIANS.
  !            - COMPUTE GRID BOX AREA.
  !           MAP PROJECTIONS INCLUDE:
  !            - EQUIDISTANT CYCLINDRICAL
  !            - MERCATOR CYLINDRICAL
  !            - GAUSSIAN CYLINDRICAL
  !            - POLAR STEREOGRAPHIC
  !            - LAMBERT CONFORMAL CONIC
  !            - ROTATED EQUIDISTANT CYCLINDRICAL ("E" AND
  !              NON-"E" STAGGERS).
  !
  ! PROGRAM HISTORY LOG:
  !   2015-01-21  GAYNO   INITIAL VERSION FROM A MERGER OF
  !                       ROUTINES GDSWIZ AND GDSWZD.
  !
  ! USAGE:  "USE GDSWZD_MOD"  THEN CALL THE PUBLIC DRIVER
  !         ROUTINE "GDSWZD".
  !
  ! ATTRIBUTES:
  !   LANGUAGE: FORTRAN 90
  !
  !$$$
  !
  IMPLICIT NONE

  PRIVATE
  public :: gdswzd

  INTERFACE GDSWZD
     ! grib_descriptor interface
     MODULE PROCEDURE GDSWZD_1D_ARRAY_desc
     MODULE PROCEDURE GDSWZD_2D_ARRAY_desc
     MODULE PROCEDURE GDSWZD_SCALAR_desc

     !grib2 interface for backwards compatibility
     MODULE PROCEDURE GDSWZD_1D_ARRAY_grib2
     MODULE PROCEDURE GDSWZD_2D_ARRAY_grib2
     MODULE PROCEDURE GDSWZD_SCALAR_grib2
  END INTERFACE GDSWZD


CONTAINS

  SUBROUTINE GDSWZD_SCALAR_grib2(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
       XPTS,YPTS,RLON,RLAT,NRET, &
       CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)

    INTEGER,        INTENT(IN   ) :: IGDTNUM, IGDTLEN
    INTEGER,        INTENT(IN   ) :: IGDTMPL(IGDTLEN)
    INTEGER,        INTENT(IN   ) :: IOPT, NPTS
    INTEGER,        INTENT(  OUT) :: NRET
    !
    REAL,           INTENT(IN   ) :: FILL
    REAL,           INTENT(INOUT) :: RLON, RLAT
    REAL,           INTENT(INOUT) :: XPTS, YPTS
    REAL, OPTIONAL, INTENT(  OUT) :: CROT, SROT
    REAL, OPTIONAL, INTENT(  OUT) :: XLON, XLAT
    REAL, OPTIONAL, INTENT(  OUT) :: YLON, YLAT, AREA


    type(grib2_descriptor) :: desc

    desc = init_grib2_descriptor(igdtnum, igdtlen, igdtmpl)
    call GDSWZD_SCALAR_desc(desc, iopt, npts, fill, xpts, ypts, rlon, rlat, &
         nret, crot, srot, xlon, xlat, ylon, ylat, area)

  end subroutine GDSWZD_SCALAR_grib2

  SUBROUTINE GDSWZD_2D_ARRAY_grib2(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
       XPTS,YPTS,RLON,RLAT,NRET, &
       CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)

    IMPLICIT NONE
    !
    INTEGER,        INTENT(IN   ) :: IGDTNUM, IGDTLEN
    INTEGER,        INTENT(IN   ) :: IGDTMPL(IGDTLEN)
    INTEGER,        INTENT(IN   ) :: IOPT, NPTS
    INTEGER,        INTENT(  OUT) :: NRET
    !
    REAL,           INTENT(IN   ) :: FILL
    REAL,           INTENT(INOUT) :: RLON(:,:),RLAT(:,:)
    REAL,           INTENT(INOUT) :: XPTS(:,:),YPTS(:,:)
    REAL, OPTIONAL, INTENT(  OUT) :: CROT(:,:),SROT(:,:)
    REAL, OPTIONAL, INTENT(  OUT) :: XLON(:,:),XLAT(:,:)
    REAL, OPTIONAL, INTENT(  OUT) :: YLON(:,:),YLAT(:,:),AREA(:,:)

    type(grib2_descriptor) :: desc
    desc = init_grib2_descriptor(igdtnum, igdtlen, igdtmpl)

    call GDSWZD_2D_ARRAY_desc(desc, iopt, npts, fill, xpts, ypts, rlon, rlat, &
         nret, crot, srot, xlon, xlat, ylon, ylat, area)

  end subroutine GDSWZD_2D_ARRAY_grib2

  SUBROUTINE GDSWZD_1D_ARRAY_grib2(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL, &
       XPTS,YPTS,RLON,RLAT,NRET, &
       CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)

    INTEGER,        INTENT(IN   ) :: IGDTNUM, IGDTLEN
    INTEGER,        INTENT(IN   ) :: IGDTMPL(IGDTLEN)
    INTEGER,        INTENT(IN   ) :: IOPT, NPTS
    INTEGER,        INTENT(  OUT) :: NRET
    !
    REAL,           INTENT(IN   ) :: FILL
    REAL,           INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
    REAL,           INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
    REAL, OPTIONAL, INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
    REAL, OPTIONAL, INTENT(  OUT) :: XLON(NPTS),XLAT(NPTS)
    REAL, OPTIONAL, INTENT(  OUT) :: YLON(NPTS),YLAT(NPTS),AREA(NPTS)

    type(grib2_descriptor) :: desc
    desc = init_grib2_descriptor(igdtnum, igdtlen, igdtmpl)

    call GDSWZD_1D_ARRAY_desc(desc, iopt, npts, fill, xpts, ypts, rlon, rlat, &
         nret, crot, srot, xlon, xlat, ylon, ylat, area)
    
  end subroutine GDSWZD_1D_ARRAY_grib2


  SUBROUTINE GDSWZD_SCALAR_desc(grid_desc,IOPT,NPTS,FILL, &
       XPTS,YPTS,RLON,RLAT,NRET, &
       CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)

    class(ip_grid_descriptor), intent(in) :: grid_desc

    INTEGER,        INTENT(IN   ) :: IOPT, NPTS
    INTEGER,        INTENT(  OUT) :: NRET
    !
    REAL,           INTENT(IN   ) :: FILL
    REAL,           INTENT(INOUT) :: RLON, RLAT
    REAL,           INTENT(INOUT) :: XPTS, YPTS
    REAL, OPTIONAL, INTENT(  OUT) :: CROT, SROT
    REAL, OPTIONAL, INTENT(  OUT) :: XLON, XLAT
    REAL, OPTIONAL, INTENT(  OUT) :: YLON, YLAT, AREA

    REAL                          :: RLONA(1),RLATA(1)
    REAL                          :: XPTSA(1),YPTSA(1)
    REAL                          :: CROTA(1),SROTA(1)
    REAL                          :: XLONA(1),XLATA(1)
    REAL                          :: YLONA(1),YLATA(1),AREAA(1)

    RLONA(1) = RLON
    RLATA(1) = RLAT
    XPTSA(1) = XPTS
    YPTSA(1) = YPTS

    NRET = 0

    ! CALL WITHOUT EXTRA FIELDS.

    IF (.NOT. PRESENT(CROT) .AND. &
         .NOT. PRESENT(SROT) .AND. &
         .NOT. PRESENT(XLON) .AND. &
         .NOT. PRESENT(XLAT) .AND. &
         .NOT. PRESENT(YLON) .AND. &
         .NOT. PRESENT(YLAT) .AND. &
         .NOT. PRESENT(AREA) ) THEN

       CALL GDSWZD_1D_ARRAY_desc(grid_desc,IOPT,NPTS,FILL, &
            XPTSA,YPTSA,RLONA,RLATA,NRET)

       RLON = RLONA(1)
       RLAT = RLATA(1)
       XPTS = XPTSA(1)
       YPTS = YPTSA(1)

    ENDIF

    ! MIMIC CALL TO OLD 'GDSWIZ' ROUTINES.

    IF (PRESENT(CROT) .AND. &
         PRESENT(SROT) .AND. &
         .NOT. PRESENT(XLON) .AND. &
         .NOT. PRESENT(XLAT) .AND. &
         .NOT. PRESENT(YLON) .AND. &
         .NOT. PRESENT(YLAT) .AND. &
         .NOT. PRESENT(AREA) ) THEN

       CALL GDSWZD_1D_ARRAY_desc(grid_desc,IOPT,NPTS,FILL, &
            XPTSA,YPTSA,RLONA,RLATA,NRET,CROTA,SROTA)

       RLON = RLONA(1)
       RLAT = RLATA(1)
       XPTS = XPTSA(1)
       YPTS = YPTSA(1)
       CROT = CROTA(1)
       SROT = SROTA(1)

    ENDIF

    ! MIMIC CALL TO OLD 'GDSWZD' ROUTINES.

    IF (PRESENT(CROT) .AND. &
         PRESENT(SROT) .AND. &
         PRESENT(XLON) .AND. &
         PRESENT(XLAT) .AND. &
         PRESENT(YLON) .AND. &
         PRESENT(YLAT) .AND. &
         PRESENT(AREA) ) THEN

       CALL GDSWZD_1D_ARRAY_desc(grid_desc,IOPT,NPTS,FILL, &
            XPTSA,YPTSA,RLONA,RLATA,NRET, &
            CROTA,SROTA,XLONA,XLATA,YLONA,YLATA,AREAA)

       RLON = RLONA(1)
       RLAT = RLATA(1)
       XPTS = XPTSA(1)
       YPTS = YPTSA(1)
       CROT = CROTA(1)
       SROT = SROTA(1)
       XLON = XLONA(1)
       XLAT = XLATA(1)
       YLON = YLONA(1)
       YLAT = YLATA(1)
       AREA = AREAA(1)

    ENDIF

    RETURN

  END SUBROUTINE GDSWZD_SCALAR_desc

  SUBROUTINE GDSWZD_2D_ARRAY_desc(grid_desc,IOPT,NPTS,FILL, &
       XPTS,YPTS,RLON,RLAT,NRET, &
       CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)

    IMPLICIT NONE
    class(ip_grid_descriptor), intent(in) :: grid_desc
    !
    INTEGER,        INTENT(IN   ) :: IOPT, NPTS
    INTEGER,        INTENT(  OUT) :: NRET
    !
    REAL,           INTENT(IN   ) :: FILL
    REAL,           INTENT(INOUT) :: RLON(:,:),RLAT(:,:)
    REAL,           INTENT(INOUT) :: XPTS(:,:),YPTS(:,:)
    REAL, OPTIONAL, INTENT(  OUT) :: CROT(:,:),SROT(:,:)
    REAL, OPTIONAL, INTENT(  OUT) :: XLON(:,:),XLAT(:,:)
    REAL, OPTIONAL, INTENT(  OUT) :: YLON(:,:),YLAT(:,:),AREA(:,:)

    CALL GDSWZD_1D_ARRAY_desc(grid_desc,IOPT,NPTS,FILL, &
         XPTS,YPTS,RLON,RLAT,NRET, &
         CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)

  END SUBROUTINE GDSWZD_2D_ARRAY_desc

  SUBROUTINE GDSWZD_1D_ARRAY_desc(grid_desc,IOPT,NPTS,FILL, &
       XPTS,YPTS,RLON,RLAT,NRET, &
       CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
    !$$$  SUBPROGRAM DOCUMENTATION BLOCK
    !
    ! SUBPROGRAM:  GDSWZD     GRID DESCRIPTION SECTION WIZARD
    !   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
    !
    ! ABSTRACT: THIS SUBPROGRAM DECODES THE GRIB 2 GRID DEFINITION 
    !           TEMPLATE (PASSED IN INTEGER FORM AS DECODED BY THE
    !           NCEP G2 LIBRARY) AND RETURNS ONE OF THE FOLLOWING:
    !             (IOPT= 0) GRID AND EARTH COORDINATES OF ALL GRID POINTS
    !             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
    !             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
    !           THE CURRENT CODE RECOGNIZES THE FOLLOWING PROJECTIONS,
    !           WHERE "IGDTNUM" IS THE GRID DEFINITION TEMPLATE NUMBER:
    !             (IGDTNUM=00) EQUIDISTANT CYLINDRICAL
    !             (IGDTNUM=01) ROTATED EQUIDISTANT CYLINDRICAL.  "E"
    !                          AND NON-"E" STAGGERED
    !             (IGDTNUM=10) MERCATOR CYCLINDRICAL
    !             (IGDTNUM=20) POLAR STEREOGRAPHIC AZIMUTHAL
    !             (IGDTNUM=30) LAMBERT CONFORMAL CONICAL
    !             (IGDTNUM=40) GAUSSIAN EQUIDISTANT CYCLINDRICAL
    !           IF THE SELECTED COORDINATES ARE MORE THAN ONE GRIDPOINT
    !           BEYOND THE THE EDGES OF THE GRID DOMAIN, THEN THE RELEVANT
    !           OUTPUT ELEMENTS ARE SET TO FILL VALUES.  ALSO IF IOPT=0,
    !           IF THE NUMBER OF GRID POINTS EXCEEDS THE NUMBER ALLOTTED,
    !           THEN ALL THE OUTPUT ELEMENTS ARE SET TO FILL VALUES.
    !           THE ACTUAL NUMBER OF VALID POINTS COMPUTED IS RETURNED TOO.
    !           OPTIONALLY, THE VECTOR ROTATIONS, MAP JACOBIANS AND
    !           GRID BOX AREAS MAY BE RETURNED.  TO COMPUTE THE
    !           VECTOR ROTATIONS, THE OPTIONAL ARGUMENTS 'SROT' AND 'CROT'
    !           MUST BE PRESENT.  TO COMPUTE THE MAP JACOBIANS, THE
    !           OPTIONAL ARGUMENTS 'XLON', 'XLAT', 'YLON', 'YLAT' MUST BE PRESENT.
    !           TO COMPUTE THE GRID BOX AREAS, THE OPTIONAL ARGUMENT
    !           'AREA' MUST BE PRESENT.
    !
    ! PROGRAM HISTORY LOG:
    ! 1996-04-10  IREDELL
    ! 1997-10-20  IREDELL  INCLUDE MAP OPTIONS
    ! 1998-08-20  BALDWIN  ADD TYPE 203 2-D ETA GRIDS
    ! 2008-04-11  GAYNO    ADD TYPE 205 - ROT LAT/LON B-STAGGER
    ! 2012-08-02  GAYNO    FIX COMPUTATION OF I/J FOR 203 GRIDS WITH
    !                      NSCAN /= 0.
    ! 2015-01-26  GAYNO    MERGER OF GDSWIZ AND GDSWZD.  MAKE MODULE.
    !                      REMOVE REFERENCES TO OBSOLETE NCEP GRID
    !                      201 AND 202. MAKE CROT,SORT,XLON,XLAT,
    !                      YLON,YLAT AND AREA OPTIONAL ARGUMENTS.
    ! 2015-07-13  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAY
    !                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAY.
    !                      REMOVED CALLS TO ROUTINES GDSWZDC9 AND
    !                      GDSWZDCA.  THESE ROUTINES WORKED FOR
    !                      ROTATED LAT/LON GRIDS THAT ARE NOW
    !                      OBSOLETE UNDER THE GRIB 2 STANDARD.
    !
    ! USAGE:    CALL GDSWZD(IGDTNUM,IGDTMPL,IGDTLEN,IOPT,NPTS,FILL,
    !    &                  XPTS,YPTS,RLON,RLAT,NRET,
    !    &                  CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
    !
    !   INPUT ARGUMENT LIST:
    !     IGDTNUM  - INTEGER GRID DEFINITION TEMPLATE NUMBER.
    !                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !                  00 - EQUIDISTANT CYLINDRICAL
    !                  01 - ROTATED EQUIDISTANT CYLINDRICAL.  "E"
    !                       AND NON-"E" STAGGERED
    !                  10 - MERCATOR CYCLINDRICAL
    !                  20 - POLAR STEREOGRAPHIC AZIMUTHAL
    !                  30 - LAMBERT CONFORMAL CONICAL
    !                  40 - GAUSSIAN EQUIDISTANT CYCLINDRICAL
    !     IGDTMPL  - INTEGER (IGDTLEN) GRID DEFINITION TEMPLATE ARRAY.
    !                CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE FOR
    !                SECTION THREE.
    !                ALL PROJECTIONS:
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
    !     IGDTLEN  - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IOPT     - INTEGER OPTION FLAG
    !                ( 0 TO COMPUTE EARTH COORDS OF ALL THE GRID POINTS)
    !                (+1 TO COMPUTE EARTH COORDS OF SELECTED GRID COORDS)
    !                (-1 TO COMPUTE GRID COORDS OF SELECTED EARTH COORDS)
    !     NPTS     - INTEGER MAXIMUM NUMBER OF COORDINATES
    !     FILL     - REAL FILL VALUE TO SET INVALID OUTPUT DATA
    !                (MUST BE IMPOSSIBLE VALUE; SUGGESTED VALUE: -9999.)
    !     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT>0
    !     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT>0
    !     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT<0
    !                (ACCEPTABLE RANGE: -360. TO 360.)
    !     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT<0
    !                (ACCEPTABLE RANGE: -90. TO 90.)
    !
    !   OUTPUT ARGUMENT LIST:
    !     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT<=0
    !     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT<=0
    !     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT>=0
    !     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT>=0
    !     NRET     - INTEGER NUMBER OF VALID POINTS COMPUTED
    !                (-1 IF PROJECTION UNRECOGNIZED)
    !     CROT     - REAL, OPTIONAL (NPTS) CLOCKWISE VECTOR ROTATION COSINES 
    !     SROT     - REAL, OPTIONAL (NPTS) CLOCKWISE VECTOR ROTATION SINES 
    !                (UGRID=CROT*UEARTH-SROT*VEARTH;
    !                 VGRID=SROT*UEARTH+CROT*VEARTH)
    !     XLON     - REAL, OPTIONAL (NPTS) DX/DLON IN 1/DEGREES
    !     XLAT     - REAL, OPTIONAL (NPTS) DX/DLAT IN 1/DEGREES
    !     YLON     - REAL, OPTIONAL (NPTS) DY/DLON IN 1/DEGREES
    !     YLAT     - REAL, OPTIONAL (NPTS) DY/DLAT IN 1/DEGREES
    !     AREA     - REAL, OPTIONAL (NPTS) AREA WEIGHTS IN M**2
    !                (PROPORTIONAL TO THE SQUARE OF THE MAP FACTOR
    !                 IN THE CASE OF CONFORMAL PROJECTIONS)
    !
    ! SUBPROGRAMS CALLED:
    !   GDSWZD_EQUID_CYLIND              GDS WIZARD FOR EQUIDISTANT CYLINDRICAL
    !   GDSWZD_MERCATOR                  GDS WIZARD FOR MERCATOR CYLINDRICAL
    !   GDSWZD_LAMBERT_CONF              GDS WIZARD FOR LAMBERT CONFORMAL CONICAL
    !   GDSWZD_GAUSSIAN                  GDS WIZARD FOR GAUSSIAN CYLINDRICAL
    !   GDSWZD_POLAR_STEREO              GDS WIZARD FOR POLAR STEREOGRAPHIC AZIMUTHAL
    !   GDSWZD_ROT_EQUID_CYLIND_EGRID    GDS WIZARD FOR ROTATED EQUIDISTANT CYLINDRICAL
    !   GDSWZD_ROT_EQUID_CYLIND          GDS WIZARD FOR ROTATED EQUIDISTANT CYLINDRICAL
    !
    ! ATTRIBUTES:
    !   LANGUAGE: FORTRAN 90
    !
    !$$$
    !
    USE GDSWZD_EQUID_CYLIND_MOD
    USE GDSWZD_MERCATOR_MOD
    USE GDSWZD_LAMBERT_CONF_MOD
    USE GDSWZD_GAUSSIAN_MOD
    USE GDSWZD_POLAR_STEREO_MOD
    USE GDSWZD_ROT_EQUID_CYLIND_EGRID_MOD
    USE GDSWZD_ROT_EQUID_CYLIND_MOD
    !
    IMPLICIT NONE
    !
    class(ip_grid_descriptor), intent(in) :: grid_desc
    INTEGER,        INTENT(IN   ) :: IOPT, NPTS
    INTEGER,        INTENT(  OUT) :: NRET
    !
    REAL,           INTENT(IN   ) :: FILL
    REAL,           INTENT(INOUT) :: RLON(NPTS),RLAT(NPTS)
    REAL,           INTENT(INOUT) :: XPTS(NPTS),YPTS(NPTS)
    REAL, OPTIONAL, INTENT(  OUT) :: CROT(NPTS),SROT(NPTS)
    REAL, OPTIONAL, INTENT(  OUT) :: XLON(NPTS),XLAT(NPTS)
    REAL, OPTIONAL, INTENT(  OUT) :: YLON(NPTS),YLAT(NPTS),AREA(NPTS)
    !
    INTEGER                       :: IS1, IM, JM, NM, KSCAN, NSCAN, N
    INTEGER                       :: IOPF, NN, I, J
    INTEGER                       :: I_OFFSET_ODD, I_OFFSET_EVEN
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    select type(grid_desc)
    type is(grib1_descriptor)
    type is(grib2_descriptor)
       associate(igdtnum => grid_desc%gdt_num, igdtmpl => grid_desc%gdt_tmpl, igdtlen => grid_desc%gdt_len)

         !  COMPUTE GRID COORDINATES FOR ALL GRID POINTS
         IF(IOPT.EQ.0) THEN
            IF(IGDTNUM==0) THEN
               IM=IGDTMPL(8)
               JM=IGDTMPL(9)
               NM=IM*JM
               NSCAN=MOD(IGDTMPL(19)/32,2)
            ELSEIF(IGDTNUM==1) THEN
               IM=IGDTMPL(8)
               JM=IGDTMPL(9)
               NM=IM*JM
               I_OFFSET_ODD=MOD(IGDTMPL(19)/8,2)
               I_OFFSET_EVEN=MOD(IGDTMPL(19)/4,2)
               IF(I_OFFSET_ODD/=I_OFFSET_EVEN)THEN
                  IF(I_OFFSET_ODD==0) THEN
                     IS1=(JM+1)/2
                  ELSE
                     IS1=JM/2
                  ENDIF
               ENDIF
               NSCAN=MOD(IGDTMPL(19)/32,2)
            ELSEIF(IGDTNUM==10) THEN
               IM=IGDTMPL(8)
               JM=IGDTMPL(9)
               NM=IM*JM
               NSCAN=MOD(IGDTMPL(16)/32,2)
            ELSEIF(IGDTNUM==20) THEN
               IM=IGDTMPL(8)
               JM=IGDTMPL(9)
               NM=IM*JM
               NSCAN=MOD(IGDTMPL(18)/32,2)
            ELSEIF(IGDTNUM==30) THEN
               IM=IGDTMPL(8)
               JM=IGDTMPL(9)
               NM=IM*JM
               NSCAN=MOD(IGDTMPL(18)/32,2)
            ELSEIF(IGDTNUM==40)THEN
               IM=IGDTMPL(8)
               JM=IGDTMPL(9)
               NM=IM*JM
               NSCAN=MOD(IGDTMPL(19)/32,2)
            ELSE ! PROJECTION NOT RECOGNIZED
               RLAT=FILL
               RLON=FILL
               XPTS=FILL
               YPTS=FILL
               RETURN
            ENDIF
            IF(NM.LE.NPTS) THEN
               IF(IGDTNUM==1.AND.(I_OFFSET_ODD/=I_OFFSET_EVEN)) THEN
                  KSCAN=I_OFFSET_ODD
                  DO N=1,NM
                     IF(NSCAN.EQ.0) THEN
                        J=(N-1)/IM+1
                        I=(N-IM*(J-1))*2-MOD(J+KSCAN,2)
                     ELSE
                        NN=(N*2)-1+KSCAN
                        I = (NN-1)/JM + 1
                        J = MOD(NN-1,JM) + 1
                        IF (MOD(JM,2)==0.AND.MOD(I,2)==0.AND.KSCAN==0) J = J + 1
                        IF (MOD(JM,2)==0.AND.MOD(I,2)==0.AND.KSCAN==1) J = J - 1
                     ENDIF
                     XPTS(N)=IS1+(I-(J-KSCAN))/2
                     YPTS(N)=(I+(J-KSCAN))/2
                  ENDDO
               ELSE
                  DO N=1,NM
                     IF(NSCAN.EQ.0) THEN
                        J=(N-1)/IM+1
                        I=N-IM*(J-1)
                     ELSE
                        I=(N-1)/JM+1
                        J=N-JM*(I-1)
                     ENDIF
                     XPTS(N)=I
                     YPTS(N)=J
                  ENDDO
               ENDIF
               DO N=NM+1,NPTS
                  XPTS(N)=FILL
                  YPTS(N)=FILL
               ENDDO
            ELSE ! NM > NPTS
               RLAT=FILL
               RLON=FILL
               XPTS=FILL
               YPTS=FILL
               RETURN
            ENDIF
            IOPF=1
         ELSE  ! IOPT /= 0
            IOPF=IOPT
            IF(IGDTNUM==1) THEN
               I_OFFSET_ODD=MOD(IGDTMPL(19)/8,2)
               I_OFFSET_EVEN=MOD(IGDTMPL(19)/4,2)
            ENDIF
         ENDIF ! IOPT CHECK
         ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
         !  EQUIDISTANT CYLINDRICAL
         IF(IGDTNUM==0) THEN
            CALL GDSWZD_EQUID_CYLIND(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL, &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  MERCATOR CYLINDRICAL
         ELSEIF(IGDTNUM==10) THEN
            CALL GDSWZD_MERCATOR(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL,  &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  LAMBERT CONFORMAL CONICAL
         ELSEIF(IGDTNUM==30) THEN
            CALL GDSWZD_LAMBERT_CONF(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL, &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  GAUSSIAN CYLINDRICAL
         ELSEIF(IGDTNUM==40) THEN
            CALL GDSWZD_GAUSSIAN(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL, &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  POLAR STEREOGRAPHIC AZIMUTHAL
         ELSEIF(IGDTNUM==20) THEN
            CALL GDSWZD_POLAR_STEREO(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL, &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  2-D E-STAGGERED ROTATED EQUIDISTANT CYLINDRICAL
         ELSEIF(IGDTNUM==1.AND.(I_OFFSET_ODD/=I_OFFSET_EVEN)) THEN
            CALL GDSWZD_ROT_EQUID_CYLIND_EGRID(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL, &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  2-D B-STAGGERED ROTATED EQUIDISTANT CYLINDRICAL
         ELSEIF(IGDTNUM==1) THEN
            CALL GDSWZD_ROT_EQUID_CYLIND(IGDTNUM,IGDTMPL,IGDTLEN,IOPF,NPTS,FILL, &
                 XPTS,YPTS,RLON,RLAT,NRET, &
                 CROT,SROT,XLON,XLAT,YLON,YLAT,AREA)
            ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            !  PROJECTION UNRECOGNIZED
         ELSE
            IF(IOPT.GE.0) THEN
               RLON=FILL
               RLAT=FILL
            ENDIF
            IF(IOPT.LE.0) THEN
               XPTS=FILL
               YPTS=FILL
            ENDIF
         ENDIF
       end associate
    end select

    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  END SUBROUTINE GDSWZD_1D_ARRAY_desc

END MODULE GDSWZD_MOD
