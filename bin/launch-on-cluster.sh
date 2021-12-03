#!/bin/bash

USAGE_STRING="usage: ${0} [--help] [--runsub=<runsub-file>] [--var=<VARIABLE>=<VALUE>]* [--ctag=<gitlab-container-tag>] [--config=<config-tag>] [--npar=<npar>] [--nexp=<nexp>] [-- <app-args>*]"

getopt --test
[[ $? -eq 4 ]] || { echo "getopt program on this machine is too old" >&2 ; exit 4; }
temp_args=$(getopt --name ${0} --options hr:C:c:n:x:v: --longoptions help,runsub:,ctag:,config:,npar:,nexp:,var: -- "$@")
[[ $? -eq 0 ]] || { echo "${USAGE_STRING}" >&2 ; exit 1; }

eval set -- "${temp_args}"

SSD_CONTAINER_TAG="MUST-SPECIFY-CONTAINER"
SSD_CONFIG_TAG="MUST-SPECIFY-CONFIG"
export NEXP=1
NPAR=1

SSD_RUNSUB_FILE=run.sub

while true; do
    case "$1" in
        -h|--help)
            echo "${USAGE_STRING}"
            exit 0
            ;;
	-r|--runsub)
	    SSD_RUNSUB_FILE="$2"
	    shift 2
	    ;;
        -C|--ctag)
            SSD_CONTAINER_TAG="$2"
            shift 2
            ;;
	-c|--config)
	    SSD_CONFIG_TAG="$2"
	    shift 2
	    ;;
	-x|--nexp)
	    NEXP="$2"
	    shift 2
	    ;;
	-n|--npar)
	    NPAR="$2"
	    shift 2
	    ;;
	-v|--var)
	    echo need to export "$2"
	    exit 17
	    shift 2
	    ;;
        --)                     # end of args
            shift
            break
            ;;
        *)
            echo "Internal error: unrecognized option $1" >&2
            exit 3
            ;;
    esac
done

SSD_LAUNCHER_EXTRA_ARGS="$@"
# following is a trick to add a space to the beginning of
# SSD_LAUNCHER_EXTRA_ARGS only if SSD_LAUNCHER_EXTRA_ARGS is non-empty:
SSD_LAUNCHER_EXTRA_ARGS="${SSD_LAUNCHER_EXTRA_ARGS:+ ${SSD_LAUNCHER_EXTRA_ARGS}}"

################################################################################
####### Given login host, figure out platform, and thus config file name #######
################################################################################

SSD_LOGIN_HOST=$(hostname | sed -E 's/-login.*$//')

DGXSYSTEM=$(case ${SSD_LOGIN_HOST} in
		circe|draco-rno) echo DGX2; ;;
		draco|prom) echo DGX1; ;;
		selene) echo DGXA100; ;;
		*) echo UNKNOWN!; ;;
	    esac)

CONFIG_FILE_NAME="config_${DGXSYSTEM}_${SSD_CONFIG_TAG}.sh"

################################################################################
######### Source config file to get DGXNNODES, DGXNGPU, WALLTIME, etc ##########
################################################################################

source ${CONFIG_FILE_NAME} || (echo "ERROR: Could not find config file ${CONFIG_FILE_NAME}"; exit 1)

################################################################################
# add any additional command line args
################################################################################
export EXTRA_PARAMS="${EXTRA_PARAMS}${SSD_LAUNCHER_EXTRA_ARGS}"

################################################################################
######### Calculate paper-cut differences between cluster sbatch args ##########
################################################################################

SSD_ACCT=$(case ${SSD_LOGIN_HOST} in
	       draco|draco-rno) echo ent_mlperf_bmark_ssd; ;;
	       circe) echo mlperft-ssd; ;;
	       selene) echo mlperf; ;;
	       *) echo UNKNOWN!; ;;
	   esac)

SSD_CLUSTER_ADD_ARGS=$(case ${SSD_LOGIN_HOST} in
			   draco-rno) echo "--gpus-per-node=${DGXNGPU} --exclusive --reservation=early_testing"; ;;
			   draco) echo "--gpus-per-node=${DGXNGPU} --exclusive"; ;;
			   circe) echo ""; ;;
			   selene) echo "--partition=luna"; ;;
			   *) echo UNKNOWN!; ;;
		       esac)

#case ${SSD_LOGIN_HOST} in
#      draco) export CLEAR_CACHES=0 ;;
#esac

SSD_SBATCH_ARGS="${SSD_CLUSTER_ADD_ARGS} --nodes=${DGXNNODES} --time=${WALLTIME} --account=${SSD_ACCT}"

echo "config file is ${CONFIG_FILE_NAME}, WALLTIME is ${WALLTIME}"
echo args are ${SSD_SBATCH_ARGS}
# container locations:
# gitlab-master.nvidia.com:5005/mfrank/mlperf-containers:<tag>
# gitlab-master.nvidia.com:5005/dl/mlperf/optimized:single_stage_detector.mxnet.1404578
# perhaps nvcr.io/nvidian/mxnet:20.06-py3

################################################################################
################### Launch the sbatch ####################
################################################################################

for parjob in $(seq ${NPAR}); do
    CONT=gitlab-master.nvidia.com/mfrank/mlperf-containers:${SSD_CONTAINER_TAG} sbatch ${SSD_SBATCH_ARGS} --job-name=mlperf:::ssd:${SSD_CONFIG_TAG}-${parjob} ${SSD_RUNSUB_FILE}
done
