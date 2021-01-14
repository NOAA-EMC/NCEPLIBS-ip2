module polates0_mod
  use ijkgds_mod
  use gdswzd_mod
  use ip_grid_mod
  use ip_grid_descriptor_mod
  use ip_grid_factory_mod
  implicit none

  private
  public :: polates0

  interface polates0
     module procedure polates0_grib1
     module procedure polates0_grib2
  end interface polates0

contains

  SUBROUTINE POLATES0_grib2(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,  &
       IGDTNUMO,IGDTMPLO,IGDTLENO,MI,MO,KM,IBI,LI,GI, &
       NO,RLAT,RLON,IBO,LO,GO,IRET)
    !$$$  SUBPROGRAM DOCUMENTATION BLOCK
    !
    ! SUBPROGRAM:  POLATES0   INTERPOLATE SCALAR FIELDS (BILINEAR)
    !   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
    !
    ! ABSTRACT: THIS SUBPROGRAM PERFORMS BILINEAR INTERPOLATION
    !           FROM ANY GRID TO ANY GRID FOR SCALAR FIELDS.
    !           OPTIONS ALLOW VARYING THE MINIMUM PERCENTAGE FOR MASK,
    !           I.E. PERCENT VALID INPUT DATA REQUIRED TO MAKE OUTPUT DATA,
    !           (IPOPT(1)) WHICH DEFAULTS TO 50 (IF IPOPT(1)=-1).
    !           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
    !           IF NO INPUT DATA IS FOUND NEAR THE OUTPUT POINT, A SPIRAL
    !           SEARCH MAY BE INVOKED BY SETTING IPOPT(2)> 0.
    !           NO SEARCHING IS DONE IF OUTPUT POINT IS OUTSIDE THE INPUT GRID.
    !           THE CODE RECOGNIZES THE FOLLOWING PROJECTIONS, WHERE
    !           "IGDTNUMI/O" IS THE GRIB 2 GRID DEFINTION TEMPLATE NUMBER
    !           FOR THE INPUT AND OUTPUT GRIDS, RESPECTIVELY:
    !             (IGDTNUMI/O=00) EQUIDISTANT CYLINDRICAL
    !             (IGDTNUMI/O=01) ROTATED EQUIDISTANT CYLINDRICAL. "E" AND
    !                             NON-"E" STAGGERED
    !             (IGDTNUMI/O=10) MERCATOR CYLINDRICAL
    !             (IGDTNUMI/O=20) POLAR STEREOGRAPHIC AZIMUTHAL
    !             (IGDTNUMI/O=30) LAMBERT CONFORMAL CONICAL
    !             (IGDTNUMI/O=40) GAUSSIAN CYLINDRICAL
    !           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
    !           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED.
    !           ON THE OTHER HAND, THE OUTPUT CAN BE A SET OF STATION POINTS
    !           IF IGDTNUMO<0, IN WHICH CASE THE NUMBER OF POINTS
    !           AND THEIR LATITUDES AND LONGITUDES MUST BE INPUT.
    !           INPUT BITMAPS WILL BE INTERPOLATED TO OUTPUT BITMAPS.
    !           OUTPUT BITMAPS WILL ALSO BE CREATED WHEN THE OUTPUT GRID
    !           EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
    !           THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
    !        
    ! PROGRAM HISTORY LOG:
    !   96-04-10  IREDELL
    ! 1999-04-08  IREDELL  SPLIT IJKGDS INTO TWO PIECES
    ! 2001-06-18  IREDELL  INCLUDE MINIMUM MASK PERCENTAGE OPTION
    ! 2007-05-22  IREDELL  EXTRAPOLATE UP TO HALF A GRID CELL
    ! 2008-06-04  GAYNO    ADDED SPIRAL SEARCH OPTION
    ! 2009-10-19  IREDELL  SAVE WEIGHTS AND THREAD FOR PERFORMANCE
    ! 2012-06-26  GAYNO    FIX OUT-OF-BOUNDS ERROR.  SEE NCEPLIBS
    !                      TICKET #9.
    ! 2015-01-27  GAYNO    REPLACE CALLS TO GDSWIZ WITH NEW MERGED
    !                      VERSION OF GDSWZD.
    ! 2015-07-13  GAYNO    CONVERT TO GRIB 2. REPLACE GRIB 1 KGDS ARRAYS
    !                      WITH GRIB 2 GRID DEFINITION TEMPLATE ARRAYS.
    !
    ! USAGE:    CALL POLATES0(IPOPT,IGDTNUMI,IGDTMPLI,IGDTLENI,  &
    !                    IGDTNUMO,IGDTMPLO,IGDTLENO,MI,MO,KM,IBI,LI,GI, &
    !                    NO,RLAT,RLON,IBO,LO,GO,IRET)
    !
    !   INPUT ARGUMENT LIST:
    !     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
    !                IPOPT(1) IS MINIMUM PERCENTAGE FOR MASK
    !                (DEFAULTS TO 50 IF IPOPT(1)=-1)
    !                IPOPT(2) IS WIDTH OF SQUARE TO EXAMINE IN SPIRAL SEARCH
    !                (DEFAULTS TO NO SEARCH IF IPOPT(2)=-1)
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
    !                (SECTION 3 INFO).  SEE COMMENTS IN ROUTINE 
    !                IPOLATES FOR COMPLETE DEFINITION.
    !     IGDTLENI - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY - INPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTNUMO - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
    !                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE. IGDTNUMO<0
    !                MEANS INTERPOLATE TO RANDOM STATION POINTS.
    !                OTHERWISE, SAME DEFINITION AS "IGDTNUMI".
    !     IGDTMPLO - INTEGER (IGDTLENO) GRID DEFINITION TEMPLATE ARRAY -
    !                OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
    !                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !                (SECTION 3 INFO).  SEE COMMENTS IN ROUTINE
    !                IPOLATES FOR COMPLETE DEFINITION.
    !     IGDTLENO - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY - OUTPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
    !                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
    !     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
    !                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
    !     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
    !     IBI      - INTEGER (KM) INPUT BITMAP FLAGS
    !     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF SOME IBI(K)=1)
    !     GI       - REAL (MI,KM) INPUT FIELDS TO INTERPOLATE
    !     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF IGDTNUMO<0)
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
    !                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
    !                3    UNRECOGNIZED OUTPUT GRID
    !
    ! SUBPROGRAMS CALLED:
    !   GDSWZD       GRID DESCRIPTION SECTION WIZARD
    !   IJKGDS0      SET UP PARAMETERS FOR IJKGDS1
    !   IJKGDS1      RETURN FIELD POSITION FOR A GIVEN GRID POINT
    !   POLFIXS      MAKE MULTIPLE POLE SCALAR VALUES CONSISTENT
    !   CHECK_GRIDS0 DETERMINE IF INPUT OR OUTPUT GRIDS HAVE CHANGED
    !                BETWEEN CALLS TO THIS ROUTINE.
    !
    ! ATTRIBUTES:
    !   LANGUAGE: FORTRAN 90
    !
    !$$$
    INTEGER,               INTENT(IN   ) :: IGDTNUMI, IGDTLENI
    INTEGER,               INTENT(IN   ) :: IGDTMPLI(IGDTLENI)
    INTEGER,               INTENT(IN   ) :: IGDTNUMO, IGDTLENO
    INTEGER,               INTENT(IN   ) :: IGDTMPLO(IGDTLENO)
    INTEGER,               INTENT(IN   ) :: IPOPT(20)
    INTEGER,               INTENT(IN   ) :: MI,MO,KM
    INTEGER,               INTENT(IN   ) :: IBI(KM)
    INTEGER,               INTENT(INOUT) :: NO
    INTEGER,               INTENT(  OUT) :: IRET, IBO(KM)
    !
    LOGICAL*1,             INTENT(IN   ) :: LI(MI,KM)
    LOGICAL*1,             INTENT(  OUT) :: LO(MO,KM)
    !
    REAL,                  INTENT(IN   ) :: GI(MI,KM)
    REAL,                  INTENT(INOUT) :: RLAT(MO),RLON(MO)
    REAL,                  INTENT(  OUT) :: GO(MO,KM)
    !
    REAL,                  PARAMETER     :: FILL=-9999.
    !
    INTEGER                              :: IJKGDSA(20)
    INTEGER                              :: IJX(2),IJY(2)
    INTEGER                              :: MP,N,I,J,K
    INTEGER                              :: NK,NV,IJKGDS1
    INTEGER                              :: MSPIRAL,I1,J1,IXS,JXS
    INTEGER                              :: MX,KXS,KXT,IX,JX,NX
    INTEGER,ALLOCATABLE,SAVE             :: NXY(:,:,:)
    INTEGER,SAVE                         :: NOX=-1,IRETX=-1
    !
    LOGICAL                              :: SAME_GRIDI, SAME_GRIDO
    !
    REAL                                 :: WX(2),WY(2)
    REAL                                 :: XPTS(MO),YPTS(MO)
    REAL                                 :: PMP,XIJ,YIJ,XF,YF,G,W
    REAL,ALLOCATABLE,SAVE                :: RLATX(:),RLONX(:),WXY(:,:,:)

    type(grib2_descriptor) :: desc_in, desc_out
    class(ip_grid), allocatable :: grid_in, grid_out

    IRET=0
    MP=IPOPT(1)
    IF(MP.EQ.-1.OR.MP.EQ.0) MP=50
    IF(MP.LT.0.OR.MP.GT.100) IRET=32
    PMP=MP*0.01
    MSPIRAL=MAX(IPOPT(2),0)

    desc_in = init_descriptor(igdtnumi, igdtleni, igdtmpli)
    desc_out = init_descriptor(igdtnumo, igdtleno, igdtmplo)

    grid_in = init_grid(desc_in)
    grid_out = init_grid(desc_out)

    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    CALL CHECK_GRIDS0(IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO,IGDTLENO, &
         SAME_GRIDI,SAME_GRIDO) 
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  SAVE OR SKIP WEIGHT COMPUTATION
    IF(IRET==0.AND.(IGDTNUMO<0.OR..NOT.SAME_GRIDI.OR..NOT.SAME_GRIDO))THEN
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  COMPUTE NUMBER OF OUTPUT POINTS AND THEIR LATITUDES AND LONGITUDES.
       IF(IGDTNUMO.GE.0) THEN
          CALL GDSWZD(grid_out, 0,MO,FILL,XPTS,YPTS, &
               RLON,RLAT,NO)
          IF(NO.EQ.0) IRET=3
       ENDIF
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  LOCATE INPUT POINTS
       CALL GDSWZD(grid_in,-1,NO,FILL,XPTS,YPTS,RLON,RLAT,NV)
       IF(IRET.EQ.0.AND.NV.EQ.0) IRET=2
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  ALLOCATE AND SAVE GRID DATA
       IF(NOX.NE.NO) THEN
          IF(NOX.GE.0) DEALLOCATE(RLATX,RLONX,NXY,WXY)
          ALLOCATE(RLATX(NO),RLONX(NO),NXY(2,2,NO),WXY(2,2,NO))
          NOX=NO
       ENDIF
       IRETX=IRET
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  COMPUTE WEIGHTS
       IF(IRET.EQ.0) THEN
          !$OMP PARALLEL DO PRIVATE(N,XIJ,YIJ,IJX,IJY,XF,YF,J,I,WX,WY) SCHEDULE(STATIC)
          DO N=1,NO
             RLONX(N)=RLON(N)
             RLATX(N)=RLAT(N)
             XIJ=XPTS(N)
             YIJ=YPTS(N)
             IF(XIJ.NE.FILL.AND.YIJ.NE.FILL) THEN
                IJX(1:2)=FLOOR(XIJ)+(/0,1/)
                IJY(1:2)=FLOOR(YIJ)+(/0,1/)
                XF=XIJ-IJX(1)
                YF=YIJ-IJY(1)
                WX(1)=(1-XF)
                WX(2)=XF
                WY(1)=(1-YF)
                WY(2)=YF
                DO J=1,2
                   DO I=1,2
                      NXY(I,J,N)=grid_in%field_pos(ijx(i), ijy(j)) !IJKGDS1(IJX(I),IJY(J),IJKGDSA)
                      WXY(I,J,N)=WX(I)*WY(J)
                   ENDDO
                ENDDO
             ELSE
                NXY(:,:,N)=0
             ENDIF
          ENDDO
       ENDIF
    ENDIF
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  INTERPOLATE OVER ALL FIELDS
    IF(IRET.EQ.0.AND.IRETX.EQ.0) THEN
       IF(IGDTNUMO.GE.0) THEN
          NO=NOX
          DO N=1,NO
             RLON(N)=RLONX(N)
             RLAT(N)=RLATX(N)
          ENDDO
       ENDIF
       !$OMP PARALLEL DO &
       !$OMP PRIVATE(NK,K,N,G,W,J,I) &
       !$OMP PRIVATE(I1,J1,IXS,JXS,MX,KXS,KXT,IX,JX,NX) SCHEDULE(STATIC)
       DO NK=1,NO*KM
          K=(NK-1)/NO+1
          N=NK-NO*(K-1)
          G=0
          W=0
          DO J=1,2
             DO I=1,2
                IF(NXY(I,J,N).GT.0)THEN
                   IF(IBI(K).EQ.0.OR.LI(NXY(I,J,N),K)) THEN
                      G=G+WXY(I,J,N)*GI(NXY(I,J,N),K)
                      W=W+WXY(I,J,N)
                   ENDIF
                ENDIF
             ENDDO
          ENDDO
          LO(N,K)=W.GE.PMP
          IF(LO(N,K)) THEN
             GO(N,K)=G/W
          ELSEIF(MSPIRAL.GT.0.AND.XPTS(N).NE.FILL.AND.YPTS(N).NE.FILL) THEN
             I1=NINT(XPTS(N))
             J1=NINT(YPTS(N))
             IXS=SIGN(1.,XPTS(N)-I1)
             JXS=SIGN(1.,YPTS(N)-J1)
             SPIRAL : DO MX=1,MSPIRAL**2
                KXS=SQRT(4*MX-2.5)
                KXT=MX-(KXS**2/4+1)
                SELECT CASE(MOD(KXS,4))
                CASE(1)
                   IX=I1-IXS*(KXS/4-KXT)
                   JX=J1-JXS*KXS/4
                CASE(2)
                   IX=I1+IXS*(1+KXS/4)
                   JX=J1-JXS*(KXS/4-KXT)
                CASE(3)
                   IX=I1+IXS*(1+KXS/4-KXT)
                   JX=J1+JXS*(1+KXS/4)
                CASE DEFAULT
                   IX=I1-IXS*KXS/4
                   JX=J1+JXS*(KXS/4-KXT)
                END SELECT
                NX=grid_in%field_pos(ix, jx)
                IF(NX.GT.0.)THEN
                   IF(LI(NX,K).OR.IBI(K).EQ.0)THEN
                      GO(N,K)=GI(NX,K)
                      LO(N,K)=.TRUE.
                      EXIT SPIRAL
                   ENDIF
                ENDIF
             ENDDO SPIRAL
             IF(.NOT.LO(N,K))THEN
                IBO(K)=1
                GO(N,K)=0.
             ENDIF
          ELSE
             GO(N,K)=0.
          ENDIF
       ENDDO
       DO K=1,KM
          IBO(K)=IBI(K)
          IF(.NOT.ALL(LO(1:NO,K))) IBO(K)=1
       ENDDO
       IF(IGDTNUMO.EQ.0) CALL POLFIXS(NO,MO,KM,RLAT,IBO,LO,GO)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ELSE
       IF(IRET.EQ.0) IRET=IRETX
       IF(IGDTNUMO.GE.0) NO=0
    ENDIF
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  END SUBROUTINE POLATES0_GRIB2
  ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SUBROUTINE CHECK_GRIDS0(IGDTNUMI,IGDTMPLI,IGDTLENI, &
       IGDTNUMO,IGDTMPLO,IGDTLENO, &
       SAME_GRIDI,SAME_GRIDO) 
    !$$$  SUBPROGRAM DOCUMENTATION BLOCK
    !
    ! SUBPROGRAM:  CHECK_GRIDS0   CHECK GRID INFORMATION
    !   PRGMMR: GAYNO       ORG: W/NMC23       DATE: 2015-07-13
    !
    ! ABSTRACT: DETERMINE WHETHER THE INPUT OR OUTPUT GRID SPECS
    !           HAVE CHANGED.
    !
    ! PROGRAM HISTORY LOG:
    ! 2015-07-13  GAYNO     INITIAL VERSION
    !
    ! USAGE:  CALL CHECK_GRIDS0(IGDTNUMI,IGDTMPLI,IGDTLENI,IGDTNUMO,IGDTMPLO, &
    !                           IGDTLENO, SAME_GRIDI, SAME_GRIDO)
    !
    !   INPUT ARGUMENT LIST:
    !     IGDTNUMI - INTEGER GRID DEFINITION TEMPLATE NUMBER - INPUT GRID.
    !                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTMPLI - INTEGER (IGDTLENI) GRID DEFINITION TEMPLATE ARRAY -
    !                INPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
    !                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTLENI - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY - INPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTNUMO - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
    !                CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
    !                NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTMPLO - INTEGER (IGDTLENO) GRID DEFINITION TEMPLATE ARRAY -
    !                OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
    !                OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     IGDTLENO - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
    !                TEMPLATE ARRAY - OUTPUT GRID.  CORRESPONDS TO THE GFLD%IGDTLEN
    !                COMPONENT OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
    !     
    !   OUTPUT ARGUMENT LIST:
    !     SAME_GRIDI  - WHEN TRUE, THE INPUT GRID HAS NOT CHANGED BETWEEN CALLS.
    !     SAME_GRIDO  - WHEN TRUE, THE OUTPUT GRID HAS NOT CHANGED BETWEEN CALLS.
    !
    ! ATTRIBUTES:
    !   LANGUAGE: FORTRAN 90
    !
    !$$$
    IMPLICIT NONE
    !
    INTEGER,        INTENT(IN   ) :: IGDTNUMI, IGDTLENI
    INTEGER,        INTENT(IN   ) :: IGDTMPLI(IGDTLENI)
    INTEGER,        INTENT(IN   ) :: IGDTNUMO, IGDTLENO
    INTEGER,        INTENT(IN   ) :: IGDTMPLO(IGDTLENO)
    !
    LOGICAL,        INTENT(  OUT) :: SAME_GRIDI, SAME_GRIDO
    !
    INTEGER, SAVE                 :: IGDTNUMI_SAVE=-9999 
    INTEGER, SAVE                 :: IGDTLENI_SAVE=-9999
    INTEGER, SAVE                 :: IGDTMPLI_SAVE(1000)=-9999
    INTEGER, SAVE                 :: IGDTNUMO_SAVE=-9999 
    INTEGER, SAVE                 :: IGDTLENO_SAVE=-9999
    INTEGER, SAVE                 :: IGDTMPLO_SAVE(1000)=-9999
    !
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    SAME_GRIDI=.FALSE.
    IF(IGDTNUMI==IGDTNUMI_SAVE)THEN
       IF(IGDTLENI==IGDTLENI_SAVE)THEN
          IF(ALL(IGDTMPLI==IGDTMPLI_SAVE(1:IGDTLENI)))THEN
             SAME_GRIDI=.TRUE.
          ENDIF
       ENDIF
    ENDIF
    !
    IGDTNUMI_SAVE=IGDTNUMI
    IGDTLENI_SAVE=IGDTLENI
    IGDTMPLI_SAVE(1:IGDTLENI)=IGDTMPLI
    IGDTMPLI_SAVE(IGDTLENI+1:1000)=-9999
    !
    SAME_GRIDO=.FALSE.
    IF(IGDTNUMO==IGDTNUMO_SAVE)THEN
       IF(IGDTLENO==IGDTLENO_SAVE)THEN
          IF(ALL(IGDTMPLO==IGDTMPLO_SAVE(1:IGDTLENO)))THEN
             SAME_GRIDO=.TRUE.
          ENDIF
       ENDIF
    ENDIF
    !
    IGDTNUMO_SAVE=IGDTNUMO
    IGDTLENO_SAVE=IGDTLENO
    IGDTMPLO_SAVE(1:IGDTLENO)=IGDTMPLO
    IGDTMPLO_SAVE(IGDTLENO+1:1000)=-9999
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  END SUBROUTINE CHECK_GRIDS0



  !> @file
  !! INTERPOLATE SCALAR FIELDS (BILINEAR)
  !! @author IREDELL @date 96-04-10
  !
  !> THIS SUBPROGRAM PERFORMS BILINEAR INTERPOLATION
  !! FROM ANY GRID TO ANY GRID FOR SCALAR FIELDS.
  !! OPTIONS ALLOW VARYING THE MINIMUM PERCENTAGE FOR MASK,
  !! I.E. PERCENT VALID INPUT DATA REQUIRED TO MAKE OUTPUT DATA,
  !! (IPOPT(1)) WHICH DEFAULTS TO 50 (IF IPOPT(1)=-1).
  !! ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
  !! IF NO INPUT DATA IS FOUND NEAR THE OUTPUT POINT, A SPIRAL
  !! SEARCH MAY BE INVOKED BY SETTING IPOPT(2)> 0.
  !! NO SEARCHING IS DONE IF OUTPUT POINT IS OUTSIDE THE INPUT GRID.
  !! THE GRIDS ARE DEFINED BY THEIR GRID DESCRIPTION SECTIONS
  !! (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63).
  !! THE CURRENT CODE RECOGNIZES THE FOLLOWING PROJECTIONS:
  !! (KGDS(1)=000) EQUIDISTANT CYLINDRICAL
  !! (KGDS(1)=001) MERCATOR CYLINDRICAL
  !! (KGDS(1)=003) LAMBERT CONFORMAL CONICAL
  !! (KGDS(1)=004) GAUSSIAN CYLINDRICAL (SPECTRAL NATIVE)
  !! (KGDS(1)=005) POLAR STEREOGRAPHIC AZIMUTHAL
  !! (KGDS(1)=203) ROTATED EQUIDISTANT CYLINDRICAL (E-STAGGER)
  !! (KGDS(1)=205) ROTATED EQUIDISTANT CYLINDRICAL (B-STAGGER)
  !! WHERE KGDS COULD BE EITHER INPUT KGDSI OR OUTPUT KGDSO.
  !! AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
  !! AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED.
  !! ON THE OTHER HAND, THE OUTPUT CAN BE A SET OF STATION POINTS
  !! IF KGDSO(1)<0, IN WHICH CASE THE NUMBER OF POINTS
  !! AND THEIR LATITUDES AND LONGITUDES MUST BE INPUT.
  !! INPUT BITMAPS WILL BE INTERPOLATED TO OUTPUT BITMAPS.
  !! OUTPUT BITMAPS WILL ALSO BE CREATED WHEN THE OUTPUT GRID
  !! EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
  !! THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
  !!        
  !! PROGRAM HISTORY LOG:
  !! -  96-04-10  IREDELL
  !! - 1999-04-08  IREDELL  SPLIT IJKGDS INTO TWO PIECES
  !! - 2001-06-18  IREDELL  INCLUDE MINIMUM MASK PERCENTAGE OPTION
  !! - 2007-05-22  IREDELL  EXTRAPOLATE UP TO HALF A GRID CELL
  !! - 2008-06-04  GAYNO    ADDED SPIRAL SEARCH OPTION
  !! - 2009-10-19  IREDELL  SAVE WEIGHTS AND THREAD FOR PERFORMANCE
  !! - 2012-06-26  GAYNO    FIX OUT-OF-BOUNDS ERROR.  SEE NCEPLIBS
  !!                      TICKET #9.
  !! - 2015-01-27  GAYNO    REPLACE CALLS TO GDSWIZ WITH NEW MERGED
  !!                      VERSION OF GDSWZD.
  !!
  !! @param IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
  !!                IPOPT(1) IS MINIMUM PERCENTAGE FOR MASK
  !!                (DEFAULTS TO 50 IF IPOPT(1)=-1)
  !!                IPOPT(2) IS WIDTH OF SQUARE TO EXAMINE IN SPIRAL SEARCH
  !!                (DEFAULTS TO NO SEARCH IF IPOPT(2)=-1)
  !! @param KGDSI    - INTEGER (200) INPUT GDS PARAMETERS AS DECODED BY W3FI63
  !! @param KGDSO    - INTEGER (200) OUTPUT GDS PARAMETERS
  !!                (KGDSO(1)<0 IMPLIES RANDOM STATION POINTS)
  !! @param MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
  !!                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
  !! @param MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
  !!                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
  !! @param KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
  !! @param IBI      - INTEGER (KM) INPUT BITMAP FLAGS
  !! @param LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF SOME IBI(K)=1)
  !! @param GI       - REAL (MI,KM) INPUT FIELDS TO INTERPOLATE
  !! @param[out] NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)<0)
  !! @param[out] RLAT     - REAL (NO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)<0)
  !! @param[out] RLON     - REAL (NO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)<0)
  !! @param[out] IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
  !! @param[out] LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
  !! @param[out] GO       - REAL (MO,KM) OUTPUT FIELDS INTERPOLATED
  !! @param[out] IRET     - INTEGER RETURN CODE
  !!                0    SUCCESSFUL INTERPOLATION
  !!                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
  !!                3    UNRECOGNIZED OUTPUT GRID
  !!
  !! SUBPROGRAMS CALLED:
  !! -  GDSWZD       GRID DESCRIPTION SECTION WIZARD
  !! -  IJKGDS0      SET UP PARAMETERS FOR IJKGDS1
  !! -  (IJKGDS1)    RETURN FIELD POSITION FOR A GIVEN GRID POINT
  !! -  POLFIXS      MAKE MULTIPLE POLE SCALAR VALUES CONSISTENT
  !!
  SUBROUTINE POLATES0_grib1(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,GI, &
       NO,RLAT,RLON,IBO,LO,GO,IRET)!
    INTEGER,               INTENT(IN   ):: IPOPT(20),KGDSI(200)
    INTEGER,               INTENT(IN   ):: KGDSO(200),MI,MO,KM
    INTEGER,               INTENT(IN   ):: IBI(KM)
    INTEGER,               INTENT(INOUT):: NO
    INTEGER,               INTENT(  OUT):: IRET, IBO(KM)
    !
    LOGICAL*1,             INTENT(IN   ):: LI(MI,KM)
    LOGICAL*1,             INTENT(  OUT):: LO(MO,KM)
    !
    REAL,                  INTENT(IN   ):: GI(MI,KM)
    REAL,                  INTENT(INOUT):: RLAT(MO),RLON(MO)
    REAL,                  INTENT(  OUT):: GO(MO,KM)
    !
    REAL,                  PARAMETER    :: FILL=-9999.
    !
    INTEGER                             :: IJKGDSA(20)
    INTEGER                             :: IJX(2),IJY(2)
    INTEGER                             :: MP,N,I,J,K
    INTEGER                             :: NK,NV,IJKGDS1
    INTEGER                             :: MSPIRAL,I1,J1,IXS,JXS
    INTEGER                             :: MX,KXS,KXT,IX,JX,NX
    INTEGER,ALLOCATABLE,SAVE            :: NXY(:,:,:)
    INTEGER,SAVE                        :: KGDSIX(200)=-1,KGDSOX(200)=-1
    INTEGER,SAVE                        :: NOX=-1,IRETX=-1
    !
    REAL                                :: WX(2),WY(2)
    REAL                                :: XPTS(MO),YPTS(MO)
    REAL                                :: PMP,XIJ,YIJ,XF,YF,G,W
    REAL,ALLOCATABLE,SAVE               :: RLATX(:),RLONX(:),WXY(:,:,:)

    type(grib1_descriptor) :: desc_in, desc_out
    class(ip_grid), allocatable :: grid_in, grid_out
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  SET PARAMETERS
    IRET=0
    MP=IPOPT(1)
    IF(MP.EQ.-1.OR.MP.EQ.0) MP=50
    IF(MP.LT.0.OR.MP.GT.100) IRET=32
    PMP=MP*0.01
    MSPIRAL=MAX(IPOPT(2),0)


    !desc_in = init_descriptor(kgdsi)
    !desc_out = init_descriptor(kgdso)

    !grid_in = init_grid(desc_in)
    !grid_out = init_grid(desc_out)
    
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  SAVE OR SKIP WEIGHT COMPUTATION
    IF(IRET.EQ.0.AND.(KGDSO(1).LT.0.OR. &
         ANY(KGDSI.NE.KGDSIX).OR.ANY(KGDSO.NE.KGDSOX))) THEN
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  COMPUTE NUMBER OF OUTPUT POINTS AND THEIR LATITUDES AND LONGITUDES.
       IF(KGDSO(1).GE.0) THEN
          CALL GDSWZD(KGDSO, 0,MO,FILL,XPTS,YPTS,RLON,RLAT,NO)
          IF(NO.EQ.0) IRET=3
       ENDIF
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  LOCATE INPUT POINTS
       CALL GDSWZD(KGDSI,-1,NO,FILL,XPTS,YPTS,RLON,RLAT,NV)
       IF(IRET.EQ.0.AND.NV.EQ.0) IRET=2
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  ALLOCATE AND SAVE GRID DATA
       KGDSIX=KGDSI
       KGDSOX=KGDSO
       IF(NOX.NE.NO) THEN
          IF(NOX.GE.0) DEALLOCATE(RLATX,RLONX,NXY,WXY)
          ALLOCATE(RLATX(NO),RLONX(NO),NXY(2,2,NO),WXY(2,2,NO))
          NOX=NO
       ENDIF
       IRETX=IRET
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       !  COMPUTE WEIGHTS
       IF(IRET.EQ.0) THEN
          CALL IJKGDS0(KGDSI,IJKGDSA)
          !$OMP PARALLEL DO PRIVATE(N,XIJ,YIJ,IJX,IJY,XF,YF,J,I,WX,WY)
          DO N=1,NO
             RLONX(N)=RLON(N)
             RLATX(N)=RLAT(N)
             XIJ=XPTS(N)
             YIJ=YPTS(N)
             IF(XIJ.NE.FILL.AND.YIJ.NE.FILL) THEN
                IJX(1:2)=FLOOR(XIJ)+(/0,1/)
                IJY(1:2)=FLOOR(YIJ)+(/0,1/)
                XF=XIJ-IJX(1)
                YF=YIJ-IJY(1)
                WX(1)=(1-XF)
                WX(2)=XF
                WY(1)=(1-YF)
                WY(2)=YF
                DO J=1,2
                   DO I=1,2
                      NXY(I,J,N)=IJKGDS1(IJX(I),IJY(J),IJKGDSA)!grid_in%field_pos(ijx(i), ijy(j))
                      WXY(I,J,N)=WX(I)*WY(J)
                   ENDDO
                ENDDO
             ELSE
                NXY(:,:,N)=0
             ENDIF
          ENDDO
       ENDIF
    ENDIF
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    !  INTERPOLATE OVER ALL FIELDS
    IF(IRET.EQ.0.AND.IRETX.EQ.0) THEN
       IF(KGDSO(1).GE.0) THEN
          NO=NOX
          DO N=1,NO
             RLON(N)=RLONX(N)
             RLAT(N)=RLATX(N)
          ENDDO
       ENDIF
       !$OMP PARALLEL DO &
       !$OMP PRIVATE(NK,K,N,G,W,J,I) &
       !$OMP PRIVATE(I1,J1,IXS,JXS,MX,KXS,KXT,IX,JX,NX)
       DO NK=1,NO*KM
          K=(NK-1)/NO+1
          N=NK-NO*(K-1)
          G=0
          W=0
          DO J=1,2
             DO I=1,2
                IF(NXY(I,J,N).GT.0)THEN
                   IF(IBI(K).EQ.0.OR.LI(NXY(I,J,N),K)) THEN
                      G=G+WXY(I,J,N)*GI(NXY(I,J,N),K)
                      W=W+WXY(I,J,N)
                   ENDIF
                ENDIF
             ENDDO
          ENDDO
          LO(N,K)=W.GE.PMP
          IF(LO(N,K)) THEN
             GO(N,K)=G/W
          ELSEIF(MSPIRAL.GT.0.AND.XPTS(N).NE.FILL.AND.YPTS(N).NE.FILL) THEN
             I1=NINT(XPTS(N))
             J1=NINT(YPTS(N))
             IXS=SIGN(1.,XPTS(N)-I1)
             JXS=SIGN(1.,YPTS(N)-J1)
             SPIRAL : DO MX=1,MSPIRAL**2
                KXS=SQRT(4*MX-2.5)
                KXT=MX-(KXS**2/4+1)
                SELECT CASE(MOD(KXS,4))
                CASE(1)
                   IX=I1-IXS*(KXS/4-KXT)
                   JX=J1-JXS*KXS/4
                CASE(2)
                   IX=I1+IXS*(1+KXS/4)
                   JX=J1-JXS*(KXS/4-KXT)
                CASE(3)
                   IX=I1+IXS*(1+KXS/4-KXT)
                   JX=J1+JXS*(1+KXS/4)
                CASE DEFAULT
                   IX=I1-IXS*KXS/4
                   JX=J1+JXS*(KXS/4-KXT)
                END SELECT
                NX=IJKGDS1(IX,JX,IJKGDSA)!grid_in%field_pos(ix, jx) 
                IF(NX.GT.0.)THEN
                   IF(LI(NX,K).OR.IBI(K).EQ.0)THEN
                      GO(N,K)=GI(NX,K)
                      LO(N,K)=.TRUE.
                      EXIT SPIRAL
                   ENDIF
                ENDIF
             ENDDO SPIRAL
             IF(.NOT.LO(N,K))THEN
                IBO(K)=1
                GO(N,K)=0.
             ENDIF
          ELSE
             GO(N,K)=0.
          ENDIF
       ENDDO
       DO K=1,KM
          IBO(K)=IBI(K)
          IF(.NOT.ALL(LO(1:NO,K))) IBO(K)=1
       ENDDO
       IF(KGDSO(1).EQ.0) CALL POLFIXS(NO,MO,KM,RLAT,RLON,IBO,LO,GO)
       ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    ELSE
       IF(IRET.EQ.0) IRET=IRETX
       IF(KGDSO(1).GE.0) NO=0
    ENDIF
    ! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  END SUBROUTINE POLATES0_grib1

end module polates0_mod
