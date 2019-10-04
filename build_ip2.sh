#!/bin/bash

 : ${THISDIR:=$(dirname $(readlink -f -n ${BASH_SOURCE[0]}))}
 CDIR=$PWD; cd $THISDIR

 source ./Conf/Analyse_args.sh
 source ./Conf/Collect_info.sh
 source ./Conf/Gen_cfunction.sh
 source ./Conf/Reset_version.sh

 if [[ ${sys} == "intel_general" ]]; then
   sys6=${sys:6}
   source ./Conf/Ip2_${sys:0:5}_${sys6^}.sh
   rinst=false
 elif [[ ${sys} == "gnu_general" ]]; then
   sys4=${sys:4}
   source ./Conf/Ip2_${sys:0:3}_${sys4^}.sh
   rinst=false
 else
   source ./Conf/Ip2_intel_${sys^}.sh
 fi
 $CC --version &> /dev/null || {
   echo "??? IP2: compilers not set." >&2
   exit 1
 }
 [[ -z ${IP2_VER+x} || -z ${IP2_LIB4+x} ]] && {
   [[ -z ${libver+x} || -z ${libver} ]] && {
     echo "??? IP2: \"libver\" not set." >&2
     exit
   }
   IP2_INC4=${libver}_4
   IP2_INC8=${libver}_8
   IP2_INCd=${libver}_d
   IP2_LIB4=lib${libver}_4.a
   IP2_LIB8=lib${libver}_8.a
   IP2_LIBd=lib${libver}_d.a
   IP2_VER=v${libver##*_v}
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

 $inst && {
#
#     Install libraries and source files
#
   $local && {
     instloc=..
     LIB_DIR=$instloc/lib
     INCP_DIR=$instloc/include
     [ -d $LIB_DIR ] || { mkdir -p $LIB_DIR; }
     [ -d $INCP_DIR ] || { mkdir -p $INCP_DIR; }
     LIB_DIR4=$LIB_DIR
     LIB_DIR8=$LIB_DIR
     LIB_DIRd=$LIB_DIR
     INCP_DIR4=$INCP_DIR
     INCP_DIR8=$INCP_DIR
     INCP_DIRd=$INCP_DIR
     SRC_DIR=
   } || {
     $rinst && {
       LIB_DIR4=$(dirname ${IP2_LIB4})
       LIB_DIR8=$(dirname ${IP2_LIB8})
       LIB_DIRd=$(dirname ${IP2_LIBd})
       INCP_DIR4=$(dirname $IP2_INC4)
       INCP_DIR8=$(dirname $IP2_INC8)
       INCP_DIRd=$(dirname $IP2_INCd)
       [ -d $IP2_INC4 ] && { rm -rf $IP2_INC4; } \
                       || { mkdir -p $INCP_DIR4; }
       [ -d $IP2_INC8 ] && { rm -rf $IP2_INC8; } \
                       || { mkdir -p $INCP_DIR8; }
       [ -d $IP2_INCd ] && { rm -rf $IP2_INCd; } \
                       || { mkdir -p $INCP_DIRd; }
       SRC_DIR=$IP2_SRC
     } || {
       LIB_DIR=$instloc/lib
       LIB_DIR4=$LIB_DIR
       LIB_DIR8=$LIB_DIR
       LIB_DIRd=$LIB_DIR
       INCP_DIR=$instloc/include
       INCP_DIR4=$INCP_DIR
       INCP_DIR8=$INCP_DIR
       INCP_DIRd=$INCP_DIR
       IP2_INC4=$INCP_DIR4/$IP2_INC4
       IP2_INC8=$INCP_DIR8/$IP2_INC8
       IP2_INCd=$INCP_DIRd/$IP2_INCd
       [ -d $IP2_INC4 ] && { rm -rf $IP2_INC4; } \
                       || { mkdir -p $INCP_DIR4; }
       [ -d $IP2_INC8 ] && { rm -rf $IP2_INC8; } \
                       || { mkdir -p $INCP_DIR8; }
       [ -d $IP2_INCd ] && { rm -rf $IP2_INCd; } \
                       || { mkdir -p $INCP_DIRd; }
       SRC_DIR=$instloc/src
       [[ $instloc == .. ]] && SRC_DIR=
     }
     [ -d $LIB_DIR4 ] || mkdir -p $LIB_DIR4
     [ -d $LIB_DIR8 ] || mkdir -p $LIB_DIR8
     [ -d $LIB_DIRd ] || mkdir -p $LIB_DIRd
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

