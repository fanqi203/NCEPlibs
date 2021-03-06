      SUBROUTINE GDSWIZCA(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,
     &                    LROT,CROT,SROT)
C$$$  SUBPROGRAM DOCUMENTATION BLOCK
C
C SUBPROGRAM:  GDSWIZCA   GDS WIZARD FOR ROTATED EQUIDISTANT CYLINDRICAL
C   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
C
C ABSTRACT: THIS SUBPROGRAM DECODES THE GRIB GRID DESCRIPTION SECTION
C           (PASSED IN INTEGER FORM AS DECODED BY SUBPROGRAM W3FI63)
C           AND RETURNS ONE OF THE FOLLOWING:
C             (IOPT=+1) EARTH COORDINATES OF SELECTED GRID COORDINATES
C             (IOPT=-1) GRID COORDINATES OF SELECTED EARTH COORDINATES
C           FOR ROTATED EQUIDISTANT CYLINDRICAL PROJECTIONS.
C           IF THE SELECTED COORDINATES ARE MORE THAN ONE GRIDPOINT
C           BEYOND THE THE EDGES OF THE GRID DOMAIN, THEN THE RELEVANT
C           OUTPUT ELEMENTS ARE SET TO FILL VALUES.
C           THE ACTUAL NUMBER OF VALID POINTS COMPUTED IS RETURNED TOO.
C
C PROGRAM HISTORY LOG:
C   96-04-10  IREDELL
C
C USAGE:    CALL GDSWIZCA(KGDS,IOPT,NPTS,FILL,XPTS,YPTS,RLON,RLAT,NRET,
C     &                   LROT,CROT,SROT)
C
C   INPUT ARGUMENT LIST:
C     KGDS     - INTEGER (200) GDS PARAMETERS AS DECODED BY W3FI63
C     IOPT     - INTEGER OPTION FLAG
C                (+1 TO COMPUTE EARTH COORDS OF SELECTED GRID COORDS)
C                (-1 TO COMPUTE GRID COORDS OF SELECTED EARTH COORDS)
C     NPTS     - INTEGER MAXIMUM NUMBER OF COORDINATES
C     FILL     - REAL FILL VALUE TO SET INVALID OUTPUT DATA
C                (MUST BE IMPOSSIBLE VALUE; SUGGESTED VALUE: -9999.)
C     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT>0
C     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT>0
C     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT<0
C                (ACCEPTABLE RANGE: -360. TO 360.)
C     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT<0
C                (ACCEPTABLE RANGE: -90. TO 90.)
C     LROT     - INTEGER FLAG TO RETURN VECTOR ROTATIONS IF 1
C
C   OUTPUT ARGUMENT LIST:
C     XPTS     - REAL (NPTS) GRID X POINT COORDINATES IF IOPT<0
C     YPTS     - REAL (NPTS) GRID Y POINT COORDINATES IF IOPT<0
C     RLON     - REAL (NPTS) EARTH LONGITUDES IN DEGREES E IF IOPT>0
C     RLAT     - REAL (NPTS) EARTH LATITUDES IN DEGREES N IF IOPT>0
C     NRET     - INTEGER NUMBER OF VALID POINTS COMPUTED
C     CROT     - REAL (NPTS) CLOCKWISE VECTOR ROTATION COSINES IF LROT=1
C     SROT     - REAL (NPTS) CLOCKWISE VECTOR ROTATION SINES IF LROT=1
C                (UGRID=CROT*UEARTH-SROT*VEARTH;
C                 VGRID=SROT*UEARTH+CROT*VEARTH)
C
C ATTRIBUTES:
C   LANGUAGE: FORTRAN 77
C
C$$$
      INTEGER KGDS(200)
      REAL XPTS(NPTS),YPTS(NPTS),RLON(NPTS),RLAT(NPTS)
      REAL CROT(NPTS),SROT(NPTS)
      INTEGER,PARAMETER:: KD=SELECTED_REAL_KIND(15,45)
      REAL(KIND=KD):: RERTH,PI,DPR
      REAL(KIND=KD):: RLAT1,RLON1,DLON,DLAT
      REAL(KIND=KD):: HI,HJ,HS,DLATS,DLONS
      REAL(KIND=KD):: RLONR,RLATR,RLON0
      REAL(KIND=KD):: SLAT1,CLAT1,CLON1
      REAL(KIND=KD):: SLONR,CLONR
      REAL(KIND=KD):: SLATR,CLATR
      REAL(KIND=KD):: SLAT,SLON,CLAT,CLON
      REAL(KIND=KD):: DENOM,SLAT0,CLAT0,DIFF
      REAL(KIND=KD):: XMIN,XMAX,YMIN,YMAX
      PARAMETER(RERTH=6.3712E6_KD)
      PARAMETER(PI=3.14159265358979_KD,DPR=180._KD/PI)
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      IF(KGDS(1).EQ.202) THEN
        RLAT1=FLOAT(KGDS(4))*1.E-3_KD
        RLON1=FLOAT(KGDS(5))*1.E-3_KD
        IROT=MOD(KGDS(6)/8,2)
        IM=KGDS(7)
        JM=KGDS(8)
        DLON=FLOAT(KGDS(9))*1.E-3_KD
        DLAT=FLOAT(KGDS(10))*1.E-3_KD
        ISCAN=MOD(KGDS(11)/128,2)
        JSCAN=MOD(KGDS(11)/64,2)
        NSCAN=MOD(KGDS(11)/32,2)
        HI=(-1._KD)**ISCAN
        HJ=(-1._KD)**(1-JSCAN)
        DLONS=HI*DLON
        DLATS=HJ*DLAT
        RLONR=-FLOAT((IM-1)/2)*DLONS
        RLATR=-FLOAT((JM-1)/2)*DLATS
        SLAT1=SIN(RLAT1/DPR)
        CLAT1=COS(RLAT1/DPR)
        SLONR=SIN(RLONR/DPR)
        CLONR=COS(RLONR/DPR)
        SLATR=SIN(RLATR/DPR)
        CLATR=COS(RLATR/DPR)
        DENOM=1._KD-(CLATR*SLONR)**2
        SLAT0=(SLAT1*CLATR*CLONR-SLATR*SQRT(DENOM-SLAT1**2))/DENOM
        CLAT0=SQRT(1._KD-SLAT0**2)
        RLON0=RLON1+HI*DPR*ACOS((CLAT0*CLATR*CLONR-SLAT0*SLATR)/CLAT1)
C  THE FOLLOWING INDENTED LINES ARE A TEMPORARY FIX OF IMPRECISE GRID.
C  CAUTION: CENTRAL LATITUDE AND LONGITUDE ARE ASSUMED TO BE INTEGERS.
         SLAT0=SIN(NINT(ASIN(SLAT0)*DPR)/DPR)
         CLAT0=SQRT(1._KD-SLAT0**2)
         RLON0=NINT(RLON0)
         HS=SIGN(1._KD,
     &      MOD(RLON1-RLON0+180._KD+3600._KD,360._KD)-180._KD)
         CLON1=COS((RLON1-RLON0)/DPR)
         SLATR=CLAT0*SLAT1-SLAT0*CLAT1*CLON1
         CLATR=SQRT(1._KD-SLATR**2)
         CLONR=(CLAT0*CLAT1*CLON1+SLAT0*SLAT1)/CLATR
         RLATR=DPR*ASIN(SLATR)
         RLONR=HS*DPR*ACOS(CLONR)
         DLATS=RLATR/FLOAT(-(JM-1)/2)
         DLONS=RLONR/FLOAT(-(IM-1)/2)
        XMIN=0._KD
        XMAX=FLOAT(IM+1)
        IF(IM.EQ.NINT(360._KD/ABS(DLONS))) XMAX=FLOAT(IM+2)
        YMIN=0._KD
        YMAX=FLOAT(JM+1)
        NRET=0
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  TRANSLATE GRID COORDINATES TO EARTH COORDINATES
        IF(IOPT.EQ.0.OR.IOPT.EQ.1) THEN
          DO N=1,NPTS
            IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND.
     &         YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
              DIFF=XPTS(N)-FLOAT((IM+1)/2)
              HS=HI*SIGN(1._KD,DIFF)
              RLONR=(XPTS(N)-FLOAT((IM+1)/2))*DLONS
              RLATR=(YPTS(N)-FLOAT((JM+1)/2))*DLATS
              CLONR=COS(RLONR/DPR)
              SLATR=SIN(RLATR/DPR)
              CLATR=COS(RLATR/DPR)
              SLAT=CLAT0*SLATR+SLAT0*CLATR*CLONR
              IF(SLAT.LE.-1._KD) THEN
                CLAT=0._KD
                CLON=COS(RLON0/DPR)
                RLON(N)=0.
                RLAT(N)=-90.
              ELSEIF(SLAT.GE.1._KD) THEN
                CLAT=0._KD
                CLON=COS(RLON0/DPR)
                RLON(N)=0.
                RLAT(N)=90.
              ELSE
                CLAT=SQRT(1._KD-SLAT**2)
                CLON=(CLAT0*CLATR*CLONR-SLAT0*SLATR)/CLAT
                CLON=MIN(MAX(CLON,-1._KD),1._KD)
                RLON(N)=MOD(RLON0+HS*DPR*ACOS(CLON)+3600._KD,360._KD)
                RLAT(N)=DPR*ASIN(SLAT)
              ENDIF
              NRET=NRET+1
              IF(LROT.EQ.1) THEN
                IF(IROT.EQ.1) THEN
                  IF(CLATR.LE.0._KD) THEN
                    CROT(N)=-SIGN(1._KD,SLATR*SLAT0)
                    SROT(N)=0.
                  ELSE
                    SLON=SIN((RLON(N)-RLON0)/DPR)
                    CROT(N)=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
                    SROT(N)=SLAT0*SLON/CLATR
                  ENDIF
                ELSE
                  CROT(N)=1.
                  SROT(N)=0.
                ENDIF
              ENDIF
            ELSE
              RLON(N)=FILL
              RLAT(N)=FILL
            ENDIF
          ENDDO
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  TRANSLATE EARTH COORDINATES TO GRID COORDINATES
        ELSEIF(IOPT.EQ.-1) THEN
          DO N=1,NPTS
            IF(ABS(RLON(N)).LE.360.0.AND.ABS(RLAT(N)).LE.90.0) THEN
              HS=SIGN(1._KD,
     &           MOD(RLON(N)-RLON0+180._KD+3600._KD,360._KD)-180._KD)
              CLON=COS((RLON(N)-RLON0)/DPR)
              SLAT=SIN(RLAT(N)/DPR)
              CLAT=COS(RLAT(N)/DPR)
              SLATR=CLAT0*SLAT-SLAT0*CLAT*CLON
              IF(SLATR.LE.-1._KD) THEN
                CLATR=0._KD
                RLONR=0._KD
                RLATR=-90._KD
              ELSEIF(SLATR.GE.1._KD) THEN
                CLATR=0._KD
                RLONR=0._KD
                RLATR=90._KD
              ELSE
                CLATR=SQRT(1._KD-SLATR**2)
                CLONR=(CLAT0*CLAT*CLON+SLAT0*SLAT)/CLATR
                CLONR=MIN(MAX(CLONR,-1._KD),1._KD)
                RLONR=HS*DPR*ACOS(CLONR)
                RLATR=DPR*ASIN(SLATR)
              ENDIF
              XPTS(N)=FLOAT((IM+1)/2)+RLONR/DLONS
              YPTS(N)=FLOAT((JM+1)/2)+RLATR/DLATS
              IF(XPTS(N).GE.XMIN.AND.XPTS(N).LE.XMAX.AND.
     &           YPTS(N).GE.YMIN.AND.YPTS(N).LE.YMAX) THEN
                NRET=NRET+1
                IF(LROT.EQ.1) THEN
                  IF(IROT.EQ.1) THEN
                    IF(CLATR.LE.0._KD) THEN
                      CROT(N)=-SIGN(1._KD,SLATR*SLAT0)
                      SROT(N)=0.
                    ELSE
                      SLON=SIN((RLON(N)-RLON0)/DPR)
                      CROT(N)=(CLAT0*CLAT+SLAT0*SLAT*CLON)/CLATR
                      SROT(N)=SLAT0*SLON/CLATR
                    ENDIF
                  ELSE
                    CROT(N)=1.
                    SROT(N)=0.
                  ENDIF
                ENDIF
              ELSE
                XPTS(N)=FILL
                YPTS(N)=FILL
              ENDIF
            ELSE
              XPTS(N)=FILL
              YPTS(N)=FILL
            ENDIF
          ENDDO
        ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
C  PROJECTION UNRECOGNIZED
      ELSE
        IRET=-1
        IF(IOPT.GE.0) THEN
          DO N=1,NPTS
            RLON(N)=FILL
            RLAT(N)=FILL
          ENDDO
        ENDIF
        IF(IOPT.LE.0) THEN
          DO N=1,NPTS
            XPTS(N)=FILL
            YPTS(N)=FILL
          ENDDO
        ENDIF
      ENDIF
C - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      END
