#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
BUILD_DIR=${SCRIPT_DIR}/build

DOCKER_REG=${DOCKER_REG:-registry.hub.docker.com}
DOCKER_USR=${DOCKER_USR:-USR}
DOCKER_PSW=${DOCKER_PSW:-PWD}

DOCKER_REPO=${DOCKER_REPO:-REPO}
DOCKER_TAG=${DOCKER_TAG:-TAG}

HELM_REPO=${HELM_REG:-REG}
HELM_USR=${HELM_USR:-admin}
HELM_PSW=${HELM_PSW:-password}

errorExit() {
    echo -e "\nERROR: $1"
    echo
    exit 1
}

usage() {
    cat <<END_USAGE

${SCRIPT_NAME} - Script for building Docker image and Helm chart

Usage: ./${SCRIPT_NAME} <options>

--build             : [optional] Build the Docker image
--push              : [optional] Push the Docker image
--pack_helm         : [optional] Pack helm chart
--push_helm         : [optional] Push the the helm chart
--registry reg      : [optional] A custom docker registry
--docker_usr user   : [optional] Docker registry username
--docker_psw pass   : [optional] Docker registry password
--tag tag           : [optional] A custom app version
--helm_repo         : [optional] The helm repository to push to
--helm_usr          : [optional] The user for uploading to the helm repository
--helm_psw          : [optional] The password for uploading to the helm repository

-h | --help         : Show this usage

END_USAGE

    exit 1
}

# Docker login
dockerLogin() {
    echo -e "\nDocker login"

    if [ ! -z "${DOCKER_REG}" ]; then
        # Make sure credentials are set
        if [ -z "${DOCKER_USR}" ] || [ -z "${DOCKER_PSW}" ]; then
            errorExit "Docker credentials not set (DOCKER_USR and DOCKER_PSW)"
        fi

        docker login ${DOCKER_REG} -u ${DOCKER_USR} -p ${DOCKER_PSW} || errorExit "Docker login to ${DOCKER_REG} failed"
    else
        echo "Docker registry not set. Skipping"
    fi
}

# Build Docker images
buildDockerImage() {
    echo -e "\nBuilding ${DOCKER_REPO}:${DOCKER_TAG}"

    # Prepare build directory
    echo -e "\nPreparing files"
    mkdir -p ${BUILD_DIR}
    cp -v ${SCRIPT_DIR}/SimpleApp/* ${BUILD_DIR}

    echo -e "\nBuilding Docker image"
    docker build -t ${DOCKER_REG}/${DOCKER_REPO}:${DOCKER_TAG} ${BUILD_DIR} || errorExit "Building ${DOCKER_REPO}:${DOCKER_TAG} failed"
}

# Push Docker images
pushDockerImage() {
    echo -e "\nPushing ${DOCKER_REPO}:${DOCKER_TAG}"

    docker push ${DOCKER_REG}/${DOCKER_REPO}:${DOCKER_TAG} || errorExit "Pushing ${DOCKER_REPO}:${DOCKER_TAG} failed"
}

# Packing the helm chart
packHelmChart() {
    echo -e "\nPacking Helm chart"

    [ -d ${BUILD_DIR}/helm-chart ] && rm -rf ${BUILD_DIR}/helm-chart
    mkdir -p ${BUILD_DIR}/helm-chart

    helm package -d ${BUILD_DIR}/helm-chart ${SCRIPT_DIR}/App-chart || errorExit "Packing helm chart ${SCRIPT_DIR}/helm-chart failed"
}

# Pushing the Helm chart
pushHelmChart() {
    echo -e "\nPushing Helm chart"

    local chart_name=$(ls -1 ${BUILD_DIR}/helm-chart/*.tgz 2>/dev/null)
    echo "Helm chart: ${chart_name}"

    [ ! -z "${chart_name}" ] || errorExit "Did not find the helm chart to deploy"
    curl -u${HELM_USR}:${HELM_PSW} -T ${chart_name} "${HELM_REPO}/$(basename ${chart_name})" || errorExit "Uploading helm chart failed"
    echo
}

# Process command line options. See usage above for supported options
processOptions() {
    if [ $# -eq 0 ]; then
        usage
    fi

    while [[ $# > 0 ]]; do
        case "$1" in
        --build)
            BUILD="true"
            shift
            ;;
        --push)
            PUSH="true"
            shift
            ;;
        --pack_helm)
            PACK_HELM="true"
            shift
            ;;
        --push_helm)
            PUSH_HELM="true"
            shift
            ;;
        --registry)
            DOCKER_REG=${2}
            shift 2
            ;;
        --docker_usr)
            DOCKER_USR=${2}
            shift 2
            ;;
        --docker_psw)
            DOCKER_PSW=${2}
            shift 2
            ;;
        --tag)
            DOCKER_TAG=${2}
            shift 2
            ;;
        --helm_repo)
            HELM_REPO=${2}
            shift 2
            ;;
        --helm_usr)
            HELM_USR=${2}
            shift 2
            ;;
        --helm_psw)
            HELM_PSW=${2}
            shift 2
            ;;
        -h | --help)
            usage
            ;;
        *)
            usage
            ;;
        esac
    done
}

main() {
    echo -e "\nRunning"

    echo "DOCKER_REG:   ${DOCKER_REG}"
    echo "DOCKER_USR:   ${DOCKER_USR}"
    echo "DOCKER_REPO:  ${DOCKER_REPO}"
    echo "DOCKER_TAG:   ${DOCKER_TAG}"
    echo "HELM_REPO:    ${HELM_REPO}"
    echo "HELM_USR:     ${HELM_USR}"

    # Cleanup
    rm -rf ${BUILD_DIR}

    # Build and push docker images if needed
    if [ "${BUILD}" == "true" ]; then
        buildDockerImage
    fi
    if [ "${PUSH}" == "true" ]; then
        # Attempt docker login
        dockerLogin
        pushDockerImage
    fi

    # Pack and push helm chart if needed
    if [ "${PACK_HELM}" == "true" ]; then
        packHelmChart
    fi
    if [ "${PUSH_HELM}" == "true" ]; then
        pushHelmChart
    fi
}

############## Main

processOptions $*
main
