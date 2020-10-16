#include <stdio.h>
#include <stdlib.h>

#include "iplib.h"

/**************************************************************
  Unit test to ensure the 'c' wrapper routine for gdswzd 
  is working.

  Call gdswzd for a rotated lat/lon grid with "B" stagger
  and print out the corner point lat/lons and the number
  of valid grid points returned.

  Tests the single precision version of gdswzd.
**************************************************************/

int main()
{
  int *igdtmpl;
  int igdtnum, igdtlen, iopt, npts, nret;
  float fill;
  float *xpts, *ypts, *rlon, *rlat;
  float *crot, *srot, *xlon, *xlat, *ylon, *ylat, *area;

  int im = 251;
  int jm = 201;

  igdtnum = 1;

  igdtlen = 22;
  igdtmpl = (int *) malloc(igdtlen * sizeof(int));

  igdtmpl[0] = 6;
  igdtmpl[1] = 255;
  igdtmpl[2] = -1;
  igdtmpl[3] = 255;
  igdtmpl[4] = -1;
  igdtmpl[5] = 255;
  igdtmpl[6] = -1;
  igdtmpl[7] = im;
  igdtmpl[8] = jm;
  igdtmpl[9] = 0;
  igdtmpl[10] = -1;
  igdtmpl[11] = -45036000;
  igdtmpl[12] = 299961000;
  igdtmpl[13] = 56;
  igdtmpl[14] = 45036000;
  igdtmpl[15] = 60039000;
  igdtmpl[16] = 0;
  igdtmpl[17] = 0;
  igdtmpl[18] = 64;
  igdtmpl[19] = -36000000;
  igdtmpl[20] = 254000000;
  igdtmpl[21] = 0;

  iopt = 1;
  npts = im * jm;
  fill = -9999.0;

  xpts = (float *) malloc(npts * sizeof(float));
  ypts = (float *) malloc(npts * sizeof(float));
  rlon = (float *) malloc(npts * sizeof(float));
  rlat = (float *) malloc(npts * sizeof(float));
  crot = (float *) malloc(npts * sizeof(float));
  srot = (float *) malloc(npts * sizeof(float));
  xlon = (float *) malloc(npts * sizeof(float));
  xlat = (float *) malloc(npts * sizeof(float));
  ylon = (float *) malloc(npts * sizeof(float));
  ylat = (float *) malloc(npts * sizeof(float));
  area = (float *) malloc(npts * sizeof(float));

  for (int j=0; j<jm; j++) {
  for (int i=0; i<im; i++) {
     xpts[j*im+i] = i+1;
     ypts[j*im+i] = j+1;
  }
  }

  nret=0;

  gdswzd(igdtnum, igdtmpl, igdtlen, iopt, npts, fill,
         xpts, ypts, rlon, rlat, &nret,
         crot, srot, xlon, xlat, ylon, ylat, area);

  printf(" Points returned from gdswzd = %d \n", nret);
  printf(" Expected points returned    = 50451 \n\n");

  printf(" First corner point lat/lon = %f %f \n", rlat[0], rlon[0]-360);
  printf(" Expected lat/lon           = -7.491 -144.134 \n\n");

  printf(" Last corner point lat/lon  = %f %f \n", rlat[nret-1], rlon[nret-1]);
  printf(" Expected lat/lon           = 44.539 14.802 \n");

/*
  for (int n=0; n<nret; n++) {
    printf(" n = %d crot, srot %f %f \n", n, crot[n], srot[n]);
     printf(" n = %d rlon[n], rlat[n] = %f %f \n", n, rlon[n], rlat[n]);
  }
*/

  free(xpts);
  free(ypts);
  free(rlon);
  free(rlat);
  free(crot);
  free(srot);
  free(xlon);
  free(xlat);
  free(ylon);
  free(ylat);
  free(area);
  free(igdtmpl);

  return 0;
}
