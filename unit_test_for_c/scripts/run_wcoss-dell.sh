#!/bin/bash
 
#-------------------------------------------------------
# Script to run the 'c' unit test on WCOSS Phase 3
# Dell compute nodes.
#
# Simply invoke this script on the command line
# with no arguments.
#
# Output is piped to "unit_test.log"
#-------------------------------------------------------

#set -x

module purge
module load EnvVars/1.0.2
module load ips/18.0.1.163
module load lsf/10.1

bsub -oo unit_test.log -eo unit_test.log -q dev -J ip_unit_test \
     -n 1 -R span[ptile=1] \
     -P GFS-T2O -W 0:01 -cwd $(pwd) "export OMP_NUM_THREADS=1; run_unit_test.ksh"

exit 0
