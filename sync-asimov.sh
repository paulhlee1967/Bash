#!/bin/bash

#===============================================================================
# FTP Mirror Sync Script
#===============================================================================
# Description:  Mirrors an FTP site to a local directory using lftp
# Author:       Paul Lee
# Version:      2.0
# License:      MIT
# Dependencies: lftp
#
# Usage:        ./sync-asimov.sh [OPTIONS] [REMOTE_HOST] [REMOTE_DIR] [LOCAL_DIR]
#
# Arguments:
#   REMOTE_HOST    FTP server hostname (default: ftp.apple.asimov.net)
#   REMOTE_DIR     Remote directory path (default: /pub/apple_II)
#   LOCAL_DIR      Local destination directory
#
# Options:
#   -h, --help     Show this help message
#   -v, --verbose  Enable verbose output
#   -q, --quiet    Suppress non-error output
#   -d, --dry-run  Show what would be done without actually doing it
#   -l, --log      Enable logging to file (default: disabled)
#
# Examples:
#   ./sync-asimov.sh
#   ./sync-asimov.sh ftp.example.com /pub/files /local/path
#   ./sync-asimov.sh -v -l ftp.example.com /pub/files /local/path
#   ./sync-asimov.sh --dry-run ftp.example.com /pub/files /local/path
#===============================================================================

set -euo pipefail  # Exit on error, undefined vars, pipe failures

#===============================================================================
# Configuration and Defaults
#===============================================================================

# Default values
DEFAULT_REMOTE_HOST="ftp.apple.asimov.net"
DEFAULT_REMOTE_DIR="/pub/apple_II"
DEFAULT_LOCAL_DIR=""

# Script configuration
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${SCRIPT_DIR}/${SCRIPT_NAME%.*}.log"

# Global variables
REMOTE_HOST=""
REMOTE_DIR=""
LOCAL_DIR=""
VERBOSE=false
QUIET=false
DRY_RUN=false
ENABLE_LOGGING=false

#===============================================================================
# Logging Functions
#===============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ "${ENABLE_LOGGING}" == "true" ]]; then
            echo "[${timestamp}] [${level}] [${message}]" >> "${LOG_FILE}"
    fi

    case "${level}" in
        "ERROR")
            echo "ERROR: ${message}" >&2
            ;;
        "WARN")
            if [[ "${QUIET}" != "true" ]]; then
                echo "WARNING: ${message}" >&2
            fi
            ;;
        "INFO")
            if [[ "${QUIET}" != "true" ]]; then
                echo "INFO: ${message}"
            fi
            ;;
        "DEBUG")
            if [[ "${VERBOSE}" == "true" && "${QUIET}" != "true" ]]; then
                echo "DEBUG: ${message}"
            fi
            ;;
        *)
            echo "UNKNOWN: ${message}" >&2
            ;;
    esac
}

log_error() { log "ERROR" "$@"; }
log_warn() { log "WARN" "$@"; }
log_info() { log "INFO" "$@"; }
log_debug() { log "DEBUG" "$@"; }

#===============================================================================
# Utility Functions
#===============================================================================

show_help() {
    cat << EOF
FTP Mirror Sync Script

DESCRIPTION:
    Mirrors an FTP site to a local directory using lftp with comprehensive
    error handling, logging, and validation.

USAGE:
    ${SCRIPT_NAME} [OPTIONS] [REMOTE_HOST] [REMOTE_DIR] [LOCAL_DIR]

ARGUMENTS:
    REMOTE_HOST    FTP server hostname (default: ${DEFAULT_REMOTE_HOST})
    REMOTE_DIR     Remote directory path (default: ${DEFAULT_REMOTE_DIR})
    LOCAL_DIR      Local destination directory (required)

OPTIONS:
    -h, --help     Show this help message and exit
    -v, --verbose  Enable verbose output
    -q, --quiet    Suppress non-error output
    -d, --dry-run  Show what would be done without actually doing it
    -l, --log      Enable logging to file: ${LOG_FILE}

EXAMPLES:
    ${SCRIPT_NAME} /local/destination
    ${SCRIPT_NAME} ftp.example.com /pub/files /local/path
    ${SCRIPT_NAME} -v -l ftp.example.com /pub/files /local/path
    ${SCRIPT_NAME} --dry-run ftp.example.com /pub/files /local/path

DEPENDENCIES:
    lftp - Required for FTP operations

EOF
}

check_dependencies() {
    log_debug "Checking dependencies..."

    if ! command -v lftp >/dev/null 2>&1; then
        log_error "lftp is required but not installed. Please install lftp first."
        log_info "On macOS: brew install lftp"
        log_info "On Ubuntu/Debian: sudo apt-get install lftp"
        log_info "On CentOS/RHEL: sudo yum install lftp"
        exit 1
    fi

    log_debug "Dependencies check passed"
}

validate_parameters() {
    log_debug "Validating parameters..."

    # Set defaults if not provided
    REMOTE_HOST="${REMOTE_HOST:-${DEFAULT_REMOTE_HOST}}"
    REMOTE_DIR="${REMOTE_DIR:-${DEFAULT_REMOTE_DIR}}"

    # Validate required parameters
    if [[ -z "${LOCAL_DIR}" ]]; then
        log_error "LOCAL_DIR is required"
        echo
        show_help
        exit 1
    fi

    # Validate local directory
    if [[ ! -d "$(dirname "${LOCAL_DIR}")" ]]; then
        log_error "Parent directory of LOCAL_DIR does not exist: $(dirname "${LOCAL_DIR}")"
        exit 1
    fi

    # Create local directory if it doesn't exist
    if [[ ! -d "${LOCAL_DIR}" ]]; then
        log_info "Creating local directory: ${LOCAL_DIR}"
        if [[ "${DRY_RUN}" != "true" ]]; then
            mkdir -p "${LOCAL_DIR}" || {
                log_error "Failed to create local directory: ${LOCAL_DIR}"
                exit 1
            }
        else
            log_info "DRY RUN: Would create directory ${LOCAL_DIR}"
        fi
    fi

    log_debug "Parameter validation completed"
}

#===============================================================================
# Main Functions
#===============================================================================

parse_arguments() {
    log_debug "Parsing command line arguments..."

    while [[ $# -gt 0 ]]; do
    case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -q|--quiet)
                QUIET=true
                shift
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -l|--log)
                ENABLE_LOGGING=true
                shift
                ;;
            -*)
                log_error "Unknown option: ${1}"
                show_help
                exit 1
                ;;
            *)
                # Positional arguments
                if [[ -z "${REMOTE_HOST}" ]]; then
                    REMOTE_HOST="${1}"
                elif [[ -z "${REMOTE_DIR}" ]]; then
                    REMOTE_DIR="${1}"
                elif [[ -z "${LOCAL_DIR}" ]]; then
                    LOCAL_DIR="${1}"
                else
                    log_error "Too many arguments"
                    show_help
                    exit 1
                fi
                shift
                ;;
        esac
    done

    log_debug "Arguments parsed successfully"
}

run_sync() {
    log_info "Starting FTP mirror sync..."
    log_info "Remote: ${REMOTE_HOST}:${REMOTE_DIR}"
    log_info "Local:  ${LOCAL_DIR}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "DRY RUN MODE - No actual sync will be performed"
        log_info "Would run: lftp -e \"mirror --verbose --delete ${REMOTE_DIR} \"${LOCAL_DIR}\"; quit\" ${REMOTE_HOST}"
        return 0
    fi

    # Prepare lftp command
    local lftp_cmd="mirror --verbose --delete ${REMOTE_DIR} \"${LOCAL_DIR}\"; quit"

    if [[ "${VERBOSE}" == "true" ]]; then
        log_debug "Executing: lftp -e \"${lftp_cmd}\" ${REMOTE_HOST}"
    fi

    # Execute lftp command
    if lftp -e "${lftp_cmd}" "${REMOTE_HOST}"; then
        log_info "FTP mirror sync completed successfully"
    else
        local exit_code=$?
        log_error "FTP mirror sync failed with exit code: ${exit_code}"
        exit "${exit_code}"
    fi
}

cleanup() {
    log_debug "Performing cleanup..."
    # Add any cleanup tasks here if needed
}

#===============================================================================
# Main Execution
#===============================================================================

main() {
    # Set up signal handlers
    trap cleanup EXIT
    trap 'log_error "Script interrupted"; exit 130' INT TERM

    # Parse command line arguments
    parse_arguments "$@"

    # Check dependencies
    check_dependencies

    # Validate parameters
    validate_parameters

    # Log configuration
    log_info "Configuration:"
    log_info "  Remote Host: ${REMOTE_HOST}"
    log_info "  Remote Dir:  ${REMOTE_DIR}"
    log_info "  Local Dir:   ${LOCAL_DIR}"
    log_info "  Verbose:     ${VERBOSE}"
    log_info "  Quiet:       ${QUIET}"
    log_info "  Dry Run:     ${DRY_RUN}"
    log_info "  Logging:     ${ENABLE_LOGGING}"
    if [[ "${ENABLE_LOGGING}" == "true" ]]; then
        log_info "  Log File:    ${LOG_FILE}"
    fi

    # Run the sync
    run_sync

    log_info "Script completed successfully"
}

# Run main function with all arguments
main "$@"

