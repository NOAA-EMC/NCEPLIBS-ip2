#!/bin/bash

 (( $# == 0 )) && {
   echo "*** Usage: $0 wcoss|dell|cray|theia|intel_general|gnu_general [debug|build] [[local]install[only]]" >&2
   exit 1
 }

 sys=${1,,}
 [[ $sys == wcoss || $sys == dell || $sys == cray ||\
    $sys == theia || $sys == intel_general || $sys == gnu_general ]] || {
   echo "*** Usage: $0 wcoss|dell|cray|theia|intel_general|gnu_general [debug|build] [[local]install[only]]" >&2
   exit 1
 }
 debg=false
 inst=false
 skip=false
 local=false
 (( $# > 1 )) && {
   [[ ${2,,} == build ]] && debg=false
   [[ ${2,,} == debug ]] && debg=true
   [[ ${2,,} == install ]] && inst=true
   [[ ${2,,} == localinstall ]] && { local=true; inst=true; }
   [[ ${2,,} == installonly ]] && { inst=true; skip=true; }
   [[ ${2,,} == localinstallonly ]] && { local=true; inst=true; skip=true; }
 }
 (( $# > 2 )) && {
   [[ ${3,,} == build ]] && debg=false
   [[ ${3,,} == debug ]] && debg=true
   [[ ${3,,} == install ]] && inst=true
   [[ ${3,,} == localinstall ]] && { local=true; inst=true; }
   [[ ${3,,} == installonly ]] && { inst=true; skip=true; }
   [[ ${3,,} == localinstallonly ]] && { local=true; inst=true; skip=true; }
 }

 source ./Conf/Collect_info.sh
 source ./Conf/Gen_cfunction.sh
 source ./Conf/Reset_version.sh

 if [[ ${sys} == "intel_general" ]]; then
   sys6=${sys:6}
   source ./Conf/Ip2_${sys:0:5}_${sys6^}.sh
 elif [[ ${sys} == "gnu_general" ]]; then
   sys4=${sys:4}
   source ./Conf/Ip2_${sys:0:3}_${sys4^}.sh
 else
   source ./Conf/Ip2_intel_${sys^}.sh
 fi
 $CC --version &> /dev/null || {
   echo "??? IP2: compilers not set." >&2
   exit 1
 }
 [[ -z $IP2_VER || -z $IP2_LIB4 ]] && {
   echo "??? IP2: module/environment not set." >&2
   exit 1
 }

set -x
 ip2Lib4=$(basename $IP2_LIB4)
 ip2Lib8=$(basename $IP2_LIB8)
 ip2Libd=$(basename $IP2_LIBd)
 ip2Inc4=$(basename $IP2_INC4)
 ip2Inc8=$(basename $IP2_INC8)
 ip2Incd=$(basename $IP2_INCd)

#################
 cd src
#################

 $skip || {
#-------------------------------------------------------------------
# Start building libraries
#
 echo
 echo "   ... build (i4/r4) ip2 library ..."
 echo
   make clean LIB=$ip2Lib4 MOD=$ip2Inc4
   mkdir -p $ip2Inc4
   FFLAGS4="$I4R4 $FFLAGS ${MODPATH}$ip2Inc4"
   collect_info ip2 4 OneLine4 LibInfo4
   ip2Info4=ip2_info_and_log4.txt
   $debg && make debug CPPDEFS="-DLSIZE=4" FFLAGS="$FFLAGS4" LIB=$ip2Lib4 \
                                                             &> $ip2Info4 \
         || make build CPPDEFS="-DLSIZE=4" FFLAGS="$FFLAGS4" LIB=$ip2Lib4 \
                                                             &> $ip2Info4
   make message MSGSRC="$(gen_cfunction $ip2Info4 OneLine4 LibInfo4)" LIB=$ip2Lib4

 echo
 echo "   ... build (i8/r8) ip2 library ..."
 echo
   make clean LIB=$ip2Lib8 MOD=$ip2Inc8
   mkdir -p $ip2Inc8
   FFLAGS8="$I8R8 $FFLAGS ${MODPATH}$ip2Inc8"
   collect_info ip2 8 OneLine8 LibInfo8
   ip2Info8=ip2_info_and_log8.txt
   $debg && make debug CPPDEFS="-DLSIZE=8" FFLAGS="$FFLAGS8" LIB=$ip2Lib8 \
                                                             &> $ip2Info8 \
         || make build CPPDEFS="-DLSIZE=8" FFLAGS="$FFLAGS8" LIB=$ip2Lib8 \
                                                             &> $ip2Info8
   make message MSGSRC="$(gen_cfunction $ip2Info8 OneLine8 LibInfo8)" LIB=$ip2Lib8

 echo
 echo "   ... build (i4/r8) ip2 library ..."
 echo
   make clean LIB=$ip2Libd MOD=$ip2Incd
   mkdir -p $ip2Incd
   FFLAGSd="$I4R8 $FFLAGS ${MODPATH}$ip2Incd"
   collect_info ip2 d OneLined LibInfod
   ip2Infod=ip2_info_and_logd.txt
   $debg && make debug CPPDEFS="-DLSIZE=D" FFLAGS="$FFLAGSd" LIB=$ip2Libd \
                                                             &> $ip2Infod \
         || make build CPPDEFS="-DLSIZE=D" FFLAGS="$FFLAGSd" LIB=$ip2Libd \
                                                             &> $ip2Infod
   make message MSGSRC="$(gen_cfunction $ip2Infod OneLined LibInfod)" LIB=$ip2Libd
 }

 $inst && {
#
#     Install libraries and source files
#
   $local && {
              LIB_DIR4=..
              LIB_DIR8=..
              LIB_DIRd=..
              INCP_DIR=../include
              [ -d $INCP_DIR ] || { mkdir -p $INCP_DIR; }
              INCP_DIR4=$INCP_DIR
              INCP_DIR8=$INCP_DIR
              INCP_DIRd=$INCP_DIR
              SRC_DIR=
             } || {
              LIB_DIR4=$(dirname $IP2_LIB4)
              LIB_DIR8=$(dirname $IP2_LIB8)
              LIB_DIRd=$(dirname $IP2_LIBd)
              INCP_DIR4=$(dirname $IP2_INC4)
              INCP_DIR8=$(dirname $IP2_INC8)
              INCP_DIRd=$(dirname $IP2_INCd)
              SRC_DIR=$IP2_SRC
              [ -d $LIB_DIR4 ] || mkdir -p $LIB_DIR4
              [ -d $LIB_DIR8 ] || mkdir -p $LIB_DIR8
              [ -d $LIB_DIRd ] || mkdir -p $LIB_DIRd
              [ -d $IP2_INC4 ] && { rm -rf $IP2_INC4; } \
                              || { mkdir -p $INCP_DIR4; }
              [ -d $IP2_INC8 ] && { rm -rf $IP2_INC8; } \
                              || { mkdir -p $INCP_DIR8; }
              [ -d $IP2_INCd ] && { rm -rf $IP2_INCd; } \
                              || { mkdir -p $INCP_DIRd; }
              [ -z $SRC_DIR ] || { [ -d $SRC_DIR ] || mkdir -p $SRC_DIR; }
             }

   make clean LIB=
   make install LIB=$ip2Lib4 MOD=$ip2Inc4 \
                LIB_DIR=$LIB_DIR4 INC_DIR=$INCP_DIR4 SRC_DIR=
   make install LIB=$ip2Lib8 MOD=$ip2Inc8 \
                LIB_DIR=$LIB_DIR8 INC_DIR=$INCP_DIR8 SRC_DIR=
   make install LIB=$ip2Libd MOD=$ip2Incd \
                LIB_DIR=$LIB_DIRd INC_DIR=$INCP_DIRd SRC_DIR=$SRC_DIR
 }

