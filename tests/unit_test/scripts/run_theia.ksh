#!/bin/sh --login

#------------------------------------------------------------
# Script to run the unit test on Theia compute nodes.
#
# To run, type: 'sbatch $script'.
#
# Output is put in "unit_test.log"
#------------------------------------------------------------

#SBATCH --ntasks=1
#SBATCH --mem=5000M
#SBATCH -t 0:15:00
#SBATCH -A fv3-cpu
#SBATCH -J ip2_unit_test
#SBATCH -q debug
#SBATCH -o unit_test.log
#SBATCH -e unit_test.log

set -x

module purge
module load intel/15.6.233

export OMP_NUM_THREADS=1

rundir=${SLURM_SUBMIT_DIR}
cd $rundir

./run_unit_test.ksh

exit 0
