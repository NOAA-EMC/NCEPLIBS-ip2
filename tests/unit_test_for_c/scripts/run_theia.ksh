#!/bin/sh --login

#------------------------------------------------------------
# Script to run the 'c' unit test on Theia compute nodes.
#
# To run, type: 'sbatch $script'
#
# Output is put in "unit_test.log"
#------------------------------------------------------------

#SBATCH --ntasks=1
#SBATCH --mem=100M
#SBATCH -t 0:01:00
#SBATCH -A fv3-cpu
#SBATCH -q debug
#SBATCH -J ip2_unit_test_c
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
