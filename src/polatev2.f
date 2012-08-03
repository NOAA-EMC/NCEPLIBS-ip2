C-----------------------------------------------------------------------
      SUBROUTINE POLATEV2(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,UI,VI,
     &                    NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:  POLATEV2   INTERPOLATE VECTOR FIELDS (NEIGHBOR)
C   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
C
C ABSTRACT: THIS SUBPROGRAM PERFORMS NEIGHBOR INTERPOLATION
C           FROM ANY GRID TO ANY GRID FOR VECTOR FIELDS.
C           OPTIONS ALLOW CHOOSING THE WIDTH OF THE GRID SQUARE
C           (IPOPT(1)) TO SEARCH FOR VALID DATA, WHICH DEFAULTS TO 1
C           (IF IPOPT(1)=-1).  ODD WIDTH SQUARES ARE CENTERED ON
C           THE NEAREST INPUT GRID POINT; EVEN WIDTH SQUARES ARE
C           CENTERED ON THE NEAREST FOUR INPUT GRID POINTS.
C           SQUARES ARE SEARCHED FOR VALID DATA IN A SPIRAL PATTERN
C           STARTING FROM THE CENTER.  NO SEARCHING IS DONE WHERE
C           THE OUTPUT GRID IS OUTSIDE THE INPUT GRID.
C           ONLY HORIZONTAL INTERPOLATION IS PERFORMED.
C           THE GRIDS ARE DEFINED BY THEIR GRID DESCRIPTION SECTIONS
C           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63).
C           THE CURRENT CODE RECOGNIZES THE FOLLOWING PROJECTIONS:
C             (KGDS(1)=000) EQUIDISTANT CYLINDRICAL
C             (KGDS(1)=001) MERCATOR CYLINDRICAL
C             (KGDS(1)=003) LAMBERT CONFORMAL CONICAL
C             (KGDS(1)=004) GAUSSIAN CYLINDRICAL (SPECTRAL NATIVE)
C             (KGDS(1)=005) POLAR STEREOGRAPHIC AZIMUTHAL
C             (KGDS(1)=202) ROTATED EQUIDISTANT CYLINDRICAL (ETA NATIVE)
C           WHERE KGDS COULD BE EITHER INPUT KGDSI OR OUTPUT KGDSO.
C           THE INPUT AND OUTPUT VECTORS ARE ROTATED SO THAT THEY ARE
C           EITHER RESOLVED RELATIVE TO THE DEFINED GRID
C           IN THE DIRECTION OF INCREASING X AND Y COORDINATES
C           OR RESOLVED RELATIVE TO EASTERLY AND NORTHERLY DIRECTIONS,
C           AS DESIGNATED BY THEIR RESPECTIVE GRID DESCRIPTION SECTIONS.
C           AS AN ADDED BONUS THE NUMBER OF OUTPUT GRID POINTS
C           AND THEIR LATITUDES AND LONGITUDES ARE ALSO RETURNED
C           ALONG WITH THEIR VECTOR ROTATION PARAMETERS.
C           ON THE OTHER HAND, THE OUTPUT CAN BE A SET OF STATION POINTS
C           IF KGDSO(1)<0, IN WHICH CASE THE NUMBER OF POINTS
C           AND THEIR LATITUDES AND LONGITUDES MUST BE INPUT 
C           ALONG WITH THEIR VECTOR ROTATION PARAMETERS.
C           INPUT BITMAPS WILL BE INTERPOLATED TO OUTPUT BITMAPS.
C           OUTPUT BITMAPS WILL ALSO BE CREATED WHEN THE OUTPUT GRID
C           EXTENDS OUTSIDE OF THE DOMAIN OF THE INPUT GRID.
C           THE OUTPUT FIELD IS SET TO 0 WHERE THE OUTPUT BITMAP IS OFF.
C        
C PROGRAM HISTORY LOG:
C   96-04-10  IREDELL
C 1999-04-08  IREDELL  SPLIT IJKGDS INTO TWO PIECES
C 2001-06-18  IREDELL  INCLUDE SPIRAL SEARCH OPTION
C 2002-01-17  IREDELL  SAVE DATA FROM LAST CALL FOR OPTIMIZATION
C 2006-01-04  GAYNO    MINOR BUG FIX
C 2007-10-30  IREDELL  SAVE WEIGHTS AND THREAD FOR PERFORMANCE
C 2012-06-26  GAYNO    FIX OUT-OF-BOUNDS ERROR.  SEE NCEPLIBS
C                      TICKET #9.
C
C USAGE:    CALL POLATEV2(IPOPT,KGDSI,KGDSO,MI,MO,KM,IBI,LI,UI,VI,
C    &                    NO,RLAT,RLON,CROT,SROT,IBO,LO,UO,VO,IRET)
C
C   INPUT ARGUMENT LIST:
C     IPOPT    - INTEGER (20) INTERPOLATION OPTIONS
C                IPOPT(1) IS WIDTH OF SQUARE TO EXAMINE IN SPIRAL SEARCH
C                (DEFAULTS TO 1 IF IPOPT(1)=-1)
C     KGDSI    - INTEGER (200) INPUT GDS PARAMETERS AS DECODED BY W3FI63
C     KGDSO    - INTEGER (200) OUTPUT GDS PARAMETERS
C                (KGDSO(1)<0 IMPLIES RANDOM STATION POINTS)
C     MI       - INTEGER SKIP NUMBER BETWEEN INPUT GRID FIELDS IF KM>1
C                OR DIMENSION OF INPUT GRID FIELDS IF KM=1
C     MO       - INTEGER SKIP NUMBER BETWEEN OUTPUT GRID FIELDS IF KM>1
C                OR DIMENSION OF OUTPUT GRID FIELDS IF KM=1
C     KM       - INTEGER NUMBER OF FIELDS TO INTERPOLATE
C     IBI      - INTEGER (KM) INPUT BITMAP FLAGS
C     LI       - LOGICAL*1 (MI,KM) INPUT BITMAPS (IF SOME IBI(K)=1)
C     UI       - REAL (MI,KM) INPUT U-COMPONENT FIELDS TO INTERPOLATE
C     VI       - REAL (MI,KM) INPUT V-COMPONENT FIELDS TO INTERPOLATE
C     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)<0)
C     RLAT     - REAL (NO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)<0)
C     RLON     - REAL (NO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)<0)
C     CROT     - REAL (NO) VECTOR ROTATION COSINES (IF KGDSO(1)<0)
C     SROT     - REAL (NO) VECTOR ROTATION SINES (IF KGDSO(1)<0)
C                (UGRID=CROT*UEARTH-SROT*VEARTH;
C                 VGRID=SROT*UEARTH+CROT*VEARTH)
C
C   OUTPUT ARGUMENT LIST:
C     NO       - INTEGER NUMBER OF OUTPUT POINTS (ONLY IF KGDSO(1)>=0)
C     RLAT     - REAL (MO) OUTPUT LATITUDES IN DEGREES (IF KGDSO(1)>=0)
C     RLON     - REAL (MO) OUTPUT LONGITUDES IN DEGREES (IF KGDSO(1)>=0)
C     CROT     - REAL (NO) VECTOR ROTATION COSINES (IF KGDSO(1)>=0)
C     SROT     - REAL (NO) VECTOR ROTATION SINES (IF KGDSO(1)>=0)
C                (UGRID=CROT*UEARTH-SROT*VEARTH;
C                 VGRID=SROT*UEARTH+CROT*VEARTH)
C     IBO      - INTEGER (KM) OUTPUT BITMAP FLAGS
C     LO       - LOGICAL*1 (MO,KM) OUTPUT BITMAPS (ALWAYS OUTPUT)
C     UO       - REAL (MO,KM) OUTPUT U-COMPONENT FIELDS INTERPOLATED
C     VO       - REAL (MO,KM) OUTPUT V-COMPONENT FIELDS INTERPOLATED
C     IRET     - INTEGER RETURN CODE
C                0    SUCCESSFUL INTERPOLATION
C                2    UNRECOGNIZED INPUT GRID OR NO GRID OVERLAP
C                3    UNRECOGNIZED OUTPUT GRID
C
C SUBPROGRAMS CALLED:
C   GDSWIZ       GRID DESCRIPTION SECTION WIZARD
C   IJKGDS0      SET UP PARAMETERS FOR IJKGDS1
C   (IJKGDS1)    RETURN FIELD POSITION FOR A GIVEN GRID POINT
C   (MOVECT)     MOVE A VECTOR ALONG A GREAT CIRCLE
C   POLFIXV      MAKE MULTIPLE POLE VECTOR VALUES CONSISTENT
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C
C$$$
      IMPLICIT NONE
      INTEGER,INTENT(IN):: IPOPT(20),KGDSI(200),KGDSO(200),MI,MO,KM
      INTEGER,INTENT(IN):: IBI(KM)
      LOGICAL*1,INTENT(IN):: LI(MI,KM)
      REAL,INTENT(IN):: UI(MI,KM),VI(MI,KM)
      INTEGER,INTENT(INOUT):: NO
      REAL,INTENT(INOUT):: RLAT(MO),RLON(MO),CROT(MO),SROT(MO)
      INTEGER,INTENT(OUT):: IBO(KM)
      LOGICAL*1,INTENT(OUT):: LO(MO,KM)
      REAL,INTENT(OUT):: UO(MO,KM),VO(MO,KM)
      INTEGER,INTENT(OUT):: IRET
      REAL XPTS(MO),YPTS(MO)
      INTEGER IJKGDSA(20)
      REAL,PARAMETER:: FILL=-9999.
      INTEGER MSPIRAL,N,K,NK,NV,IJKGDS1
      INTEGER I1,J1,IXS,JXS,MX,KXS,KXT,IX,JX,NX
      REAL DUM
      REAL XPTI(MI),YPTI(MI),RLOI(MI),RLAI(MI),CROI(MI),SROI(MI)
      REAL CX,SX,CM,SM,UROT,VROT
      INTEGER,SAVE:: KGDSIX(200)=-1,KGDSOX(200)=-1,NOX=-1,IRETX=-1
      INTEGER,ALLOCATABLE,SAVE:: NXY(:)
      REAL,ALLOCATABLE,SAVE:: RLATX(:),RLONX(:),XPTSX(:),YPTSX(:),
     &                        CROTX(:),SROTX(:),CXY(:),SXY(:)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  SET PARAMETERS
      IRET=0
      MSPIRAL=MAX(IPOPT(1),1)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  SAVE OR SKIP WEIGHT COMPUTATION
      IF(IRET.EQ.0.AND.(KGDSO(1).LT.0.OR.
     &    ANY(KGDSI.NE.KGDSIX).OR.ANY(KGDSO.NE.KGDSOX))) THEN
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  COMPUTE NUMBER OF OUTPUT POINTS AND THEIR LATITUDES AND LONGITUDES.
        IF(KGDSO(1).GE.0) THEN
          CALL GDSWIZ(KGDSO, 0,MO,FILL,XPTS,YPTS,RLON,RLAT,NO,
     &                1,CROT,SROT)
          IF(NO.EQ.0) IRET=3
        ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  LOCATE INPUT POINTS
        CALL GDSWIZ(KGDSI,-1,NO,FILL,XPTS,YPTS,RLON,RLAT,NV,0,DUM,DUM)
        IF(IRET.EQ.0.AND.NV.EQ.0) IRET=2
        CALL GDSWIZ(KGDSI, 0,MI,FILL,XPTI,YPTI,RLOI,RLAI,NV,1,CROI,SROI)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  ALLOCATE AND SAVE GRID DATA
        KGDSIX=KGDSI
        KGDSOX=KGDSO
        IF(NOX.NE.NO) THEN
          IF(NOX.GE.0) DEALLOCATE(RLATX,RLONX,XPTSX,YPTSX,
     &                            CROTX,SROTX,NXY,CXY,SXY)
          ALLOCATE(RLATX(NO),RLONX(NO),XPTSX(NO),YPTSX(NO),
     &             CROTX(NO),SROTX(NO),NXY(NO),CXY(NO),SXY(NO))
          NOX=NO
        ENDIF
        IRETX=IRET
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  COMPUTE WEIGHTS
        IF(IRET.EQ.0) THEN
          CALL IJKGDS0(KGDSI,IJKGDSA)
C$OMP PARALLEL DO
C$OMP&PRIVATE(N,CM,SM)
          DO N=1,NO
            RLONX(N)=RLON(N)
            RLATX(N)=RLAT(N)
            XPTSX(N)=XPTS(N)
            YPTSX(N)=YPTS(N)
            CROTX(N)=CROT(N)
            SROTX(N)=SROT(N)
            IF(XPTS(N).NE.FILL.AND.YPTS(N).NE.FILL) THEN
              NXY(N)=IJKGDS1(NINT(XPTS(N)),NINT(YPTS(N)),IJKGDSA)
              IF(NXY(N).GT.0) THEN
                CALL MOVECT(RLAI(NXY(N)),RLOI(NXY(N)),
     &                      RLAT(N),RLON(N),CM,SM)
                CXY(N)=CM*CROI(NXY(N))+SM*SROI(NXY(N))
                SXY(N)=SM*CROI(NXY(N))-CM*SROI(NXY(N))
              ENDIF
            ELSE
              NXY(N)=0
            ENDIF
          ENDDO
        ENDIF
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  INTERPOLATE OVER ALL FIELDS
      IF(IRET.EQ.0.AND.IRETX.EQ.0) THEN
        IF(KGDSO(1).GE.0) THEN
          NO=NOX
          DO N=1,NO
            RLON(N)=RLONX(N)
            RLAT(N)=RLATX(N)
            CROT(N)=CROTX(N)
            SROT(N)=SROTX(N)
          ENDDO
        ENDIF
        DO N=1,NO
          XPTS(N)=XPTSX(N)
          YPTS(N)=YPTSX(N)
        ENDDO
C$OMP PARALLEL DO
C$OMP&PRIVATE(NK,K,N,I1,J1,IXS,JXS,MX,KXS,KXT,IX,JX,NX)
C$OMP&PRIVATE(CM,SM,CX,SX,UROT,VROT)
        DO NK=1,NO*KM
          K=(NK-1)/NO+1
          N=NK-NO*(K-1)
          UO(N,K)=0
          VO(N,K)=0
          LO(N,K)=.FALSE.
          IF(NXY(N).GT.0) THEN
            IF(IBI(K).EQ.0.OR.LI(NXY(N),K)) THEN
              UROT=CXY(N)*UI(NXY(N),K)-
     &             SXY(N)*VI(NXY(N),K)
              VROT=SXY(N)*UI(NXY(N),K)+
     &             CXY(N)*VI(NXY(N),K)
              UO(N,K)=CROT(N)*UROT-SROT(N)*VROT
              VO(N,K)=SROT(N)*UROT+CROT(N)*VROT
              LO(N,K)=.TRUE.
C SPIRAL AROUND UNTIL VALID DATA IS FOUND.
            ELSEIF(MSPIRAL.GT.1) THEN
              I1=NINT(XPTS(N))
              J1=NINT(YPTS(N))
              IXS=SIGN(1.,XPTS(N)-I1)
              JXS=SIGN(1.,YPTS(N)-J1)
              DO MX=2,MSPIRAL**2
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
                NX=IJKGDS1(IX,JX,IJKGDSA)
                IF(NX.GT.0) THEN
                  IF(LI(NX,K)) THEN
                    CALL MOVECT(RLAI(NX),RLOI(NX),RLAT(N),RLON(N),CM,SM)
                    CX=CM*CROI(NX)+SM*SROI(NX)
                    SX=SM*CROI(NX)-CM*SROI(NX)
                    UROT=CX*UI(NX,K)-SX*VI(NX,K)
                    VROT=SX*UI(NX,K)+CX*VI(NX,K)
                    UO(N,K)=CROT(N)*UROT-SROT(N)*VROT
                    VO(N,K)=SROT(N)*UROT+CROT(N)*VROT
                    LO(N,K)=.TRUE.
                    EXIT
                  ENDIF
                ENDIF
              ENDDO
            ENDIF
          ENDIF
        ENDDO
        DO K=1,KM
          IBO(K)=IBI(K)
          IF(.NOT.ALL(LO(1:NO,K))) IBO(K)=1
        ENDDO
        IF(KGDSO(1).EQ.0) CALL POLFIXV(NO,MO,KM,RLAT,RLON,IBO,LO,UO,VO)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      ELSE
        IF(IRET.EQ.0) IRET=IRETX
        IF(KGDSO(1).GE.0) NO=0
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      END
