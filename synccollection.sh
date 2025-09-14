#!/usr/bin/env bash
#
# synccollection.sh - Download Internet Archive collections to your Mac
#
# A BASH port of the original .NET SyncCollection application that downloads
# collections from the Internet Archive, with resume capability and progress tracking.
#
# ORIGINAL AUTHOR: malfunct
# ORIGINAL REPOSITORY: https://github.com/malfunct/SyncCollection
# ORIGINAL LICENSE: MIT License
#
# BASH PORT AUTHOR: Paul Lee
# BASH PORT VERSION: 1.0.0
# BASH PORT LICENSE: MIT License
# BASH PORT REPOSITORY: https://github.com/paullee/Bash
#
# =============================================================================
# DESCRIPTION
# =============================================================================
#
# This script downloads collections from the Internet Archive with the following
# features:
#
# ✅ Resume Capability - Only downloads new or updated items
# ✅ Progress Tracking - Real-time download progress and statistics
# ✅ Error Handling - Comprehensive error handling with meaningful messages
# ✅ Dry Run Mode - Preview what would be downloaded without actually downloading
# ✅ Verbose Logging - Detailed debug information when needed
# ✅ Input Validation - Validates collection names and row counts
# ✅ Retry Logic - Automatic retry for failed network requests
# ✅ Cleanup - Automatic cleanup of temporary files
# ✅ Cross-Platform - Works on macOS and other Unix-like systems
#
# =============================================================================
# USAGE
# =============================================================================
#
# Basic Usage:
#   ./synccollection.sh                                    # Download default collection
#   ./synccollection.sh apple_ii_library_4am              # Download specific collection
#   ./synccollection.sh 50 softwarelibrary                # Download first 50 items
#
# Advanced Usage:
#   ./synccollection.sh --verbose 100 softwarelibrary     # Verbose mode with 100 items
#   ./synccollection.sh --dry-run 10 softwarelibrary      # Preview what would be downloaded
#   ./synccollection.sh --help                            # Show help
#   ./synccollection.sh --version                         # Show version
#
# Command Line Options:
#   -h, --help      Show help message and exit
#   -v, --verbose   Enable verbose output
#   -n, --dry-run   Show what would be downloaded without actually downloading
#   -V, --version   Show version information and exit
#
# Arguments:
#   rows        Number of items to download (default: 30000, max: 100000)
#   collection  Collection identifier (default: apple_ii_library_4am)
#
# Popular Collections:
#   apple_ii_library_4am    Apple II Library 4am collection
#   softwarelibrary         Software Library collection
#   apple2_games           Apple II Games collection
#   msdos_games            MS-DOS Games collection
#
# =============================================================================
# DEPENDENCIES
# =============================================================================
#
# Required:
#   curl    - HTTP client (usually pre-installed on macOS)
#   jq      - JSON processor (install via: brew install jq)
#
# Installation:
#   brew install jq
#   chmod +x synccollection.sh
#
# =============================================================================
# EXAMPLES
# =============================================================================
#
# Download the default Apple II Library 4am collection:
#   ./synccollection.sh
#
# Download the Software Library collection:
#   ./synccollection.sh softwarelibrary
#
# Download first 50 items from the Software Library:
#   ./synccollection.sh 50 softwarelibrary
#
# Preview what would be downloaded (dry run):
#   ./synccollection.sh --dry-run 10 softwarelibrary
#
# Verbose mode with detailed logging:
#   ./synccollection.sh --verbose 100 softwarelibrary
#
# Download to a specific root directory:
#   ./synccollection.sh --root-dir /path/to/collections
#   ./synccollection.sh -r /Volumes/Data/IA 50 softwarelibrary
#
# =============================================================================
# HOW IT WORKS
# =============================================================================
#
# 1. Validation - Validates command line arguments and system dependencies
# 2. Metadata Fetching - Retrieves collection metadata from Internet Archive API
# 3. State Management - Maintains local file list (fileList.txt) to track downloads
# 4. Smart Downloading - Only downloads new or updated items
# 5. Progress Tracking - Shows real-time progress and statistics
# 6. Error Handling - Gracefully handles network errors and failed downloads
# 7. Cleanup - Automatically cleans up temporary files
#
# File Structure:
#   collection_name/
#   ├── fileList.txt          # Local tracking file (tab-separated: identifier, update_date)
#   ├── fileListOld.txt       # Previous version (backup)
#   ├── item1.zip             # Downloaded items
#   ├── item2.zip
#   └── ...
#
# =============================================================================
# EXIT CODES
# =============================================================================
#
# 0 - Success
# 1 - General error (missing dependencies, invalid arguments, etc.)
# 2 - Network error (failed to fetch collection metadata)
# 3 - File system error (permission denied, disk full, etc.)
#
# =============================================================================
# TROUBLESHOOTING
# =============================================================================
#
# Common Issues:
#
# 1. "jq: command not found"
#    Solution: brew install jq
#
# 2. "Permission denied"
#    Solution: chmod +x synccollection.sh
#
# 3. "Collection not found"
#    Solution: Verify the collection ID exists on Internet Archive
#
# 4. "Rate limited"
#    Solution: Wait a few minutes before retrying
#
# Debug Mode:
#   ./synccollection.sh --verbose 10 softwarelibrary
#
# Dry Run Mode:
#   ./synccollection.sh --dry-run 10 softwarelibrary
#
# =============================================================================
# LICENSE
# =============================================================================
#
# MIT License
#
# Copyright (c) 2025 Paul Lee
# Copyright (c) 2023 malfunct (original .NET version)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================


set -euo pipefail

# Script metadata
SCRIPT_NAME=""
SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_NAME
SCRIPT_VERSION="1.0.0"
readonly SCRIPT_VERSION
SCRIPT_AUTHOR="Paul Lee"
readonly SCRIPT_AUTHOR
SCRIPT_LICENSE="MIT"
readonly SCRIPT_LICENSE

# Original author attribution
ORIGINAL_AUTHOR="malfunct"
readonly ORIGINAL_AUTHOR
ORIGINAL_REPOSITORY="https://github.com/malfunct/SyncCollection"
readonly ORIGINAL_REPOSITORY
ORIGINAL_LICENSE="MIT"
readonly ORIGINAL_LICENSE

# Default values
DEFAULT_COLLECTION="apple_ii_library_4am"
readonly DEFAULT_COLLECTION
DEFAULT_ROWS="30000"
readonly DEFAULT_ROWS
DEFAULT_ROOT_DIR=""  # Empty means current directory
readonly DEFAULT_ROOT_DIR
MAX_ROWS="100000"  # Reasonable upper limit
readonly MAX_ROWS
MIN_ROWS="1"       # Minimum rows to process
readonly MIN_ROWS

# Internet Archive API configuration
IA_BASE_URL="https://archive.org"
readonly IA_BASE_URL
IA_SEARCH_URL="${IA_BASE_URL}/advancedsearch.php"
readonly IA_SEARCH_URL
IA_COMPRESS_URL="${IA_BASE_URL}/compress"
readonly IA_COMPRESS_URL

# File names
FILE_LIST_NAME="fileList.txt"
readonly FILE_LIST_NAME
FILE_LIST_OLD_NAME="fileListOld.txt"
readonly FILE_LIST_OLD_NAME

# Colors for output (using tput for better compatibility)
RED=""
RED="$(tput setaf 1 2>/dev/null || printf '\033[0;31m')"
readonly RED
GREEN=""
GREEN="$(tput setaf 2 2>/dev/null || printf '\033[0;32m')"
readonly GREEN
YELLOW=""
YELLOW="$(tput setaf 3 2>/dev/null || printf '\033[1;33m')"
readonly YELLOW
BLUE=""
BLUE="$(tput setaf 4 2>/dev/null || printf '\033[0;34m')"
readonly BLUE
BOLD=""
BOLD="$(tput bold 2>/dev/null || printf '\033[1m')"
readonly BOLD
RESET=""
RESET="$(tput sgr0 2>/dev/null || printf '\033[0m')"
readonly RESET

# Global variables
COLLECTIONS=()
ROWS=""
ROOT_DIR=""
VERBOSE=false
DRY_RUN=false

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Print colored output to stderr
print_info() {
    echo -e "${BLUE}[INFO]${RESET} $*" >&2
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*" >&2
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $*" >&2
}

print_error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

print_debug() {
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${RESET} $*" >&2
    fi
}

# Print usage information
show_usage() {
    cat << EOF
${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${RESET} - Internet Archive Collection Downloader

${BOLD}DESCRIPTION:${RESET}
    Download collections from the Internet Archive with resume capability.
    Only downloads new or updated items, skipping already downloaded files.

    ${BOLD}Original .NET version by:${RESET} ${ORIGINAL_AUTHOR}
    ${BOLD}Original repository:${RESET} ${ORIGINAL_REPOSITORY}
    ${BOLD}BASH port by:${RESET} ${SCRIPT_AUTHOR}

${BOLD}USAGE:${RESET}
    ${SCRIPT_NAME} [options] [rows] [collection1] [collection2] ...

${BOLD}ARGUMENTS:${RESET}
    rows         Number of items to download (default: ${DEFAULT_ROWS}, max: ${MAX_ROWS})
    collection   Collection identifier(s) (default: ${DEFAULT_COLLECTION})
                Multiple collections can be specified

${BOLD}OPTIONS:${RESET}
    -h, --help         Show this help message and exit
    -v, --verbose      Enable verbose output
    -n, --dry-run      Show what would be downloaded without actually downloading
    -r, --root-dir     Root directory for collection folders (default: current directory)
    -V, --version      Show version information and exit

${BOLD}EXAMPLES:${RESET}
    ${SCRIPT_NAME}                                    # Download default collection
    ${SCRIPT_NAME} apple_ii_library_4am              # Download specific collection
    ${SCRIPT_NAME} 50 softwarelibrary                # Download first 50 items
    ${SCRIPT_NAME} collection1 collection2           # Download multiple collections
    ${SCRIPT_NAME} 100 coll1 coll2 coll3             # Download 100 items from 3 collections
    ${SCRIPT_NAME} --verbose 100 softwarelibrary     # Verbose mode with 100 items
    ${SCRIPT_NAME} --dry-run 10 softwarelibrary      # Preview what would be downloaded
    ${SCRIPT_NAME} --root-dir /path/to/collections   # Download to specific root directory
    ${SCRIPT_NAME} -r /Volumes/Data/IA 50 softwarelibrary  # Download 50 items to /Volumes/Data/IA

${BOLD}POPULAR COLLECTIONS:${RESET}
    apple_ii_library_4am    Apple II Library 4am collection
    softwarelibrary         Software Library collection
    apple2_games           Apple II Games collection
    msdos_games            MS-DOS Games collection

${BOLD}DEPENDENCIES:${RESET}
    curl    - HTTP client (usually pre-installed on macOS)
    jq      - JSON processor (install via: brew install jq)

${BOLD}INSTALLATION:${RESET}
    brew install jq
    chmod +x ${SCRIPT_NAME}

${BOLD}AUTHOR:${RESET}
    ${SCRIPT_AUTHOR} (BASH port)
    ${ORIGINAL_AUTHOR} (original .NET version)

${BOLD}LICENSE:${RESET}
    ${SCRIPT_LICENSE}

${BOLD}REPOSITORIES:${RESET}
    BASH port: https://github.com/paullee/Bash
    Original:  ${ORIGINAL_REPOSITORY}
EOF
}

# Print version information
show_version() {
    cat << EOF
${SCRIPT_NAME} version ${SCRIPT_VERSION}
BASH port by: ${SCRIPT_AUTHOR}
Original .NET version by: ${ORIGINAL_AUTHOR}
License: ${SCRIPT_LICENSE}
BASH port repository: https://github.com/paullee/Bash
Original repository: ${ORIGINAL_REPOSITORY}
EOF
}

# Log function with timestamp
log() {
    local level="$1"
    shift
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] [${level}] $*" >&2
}

# Cleanup function for trap
cleanup() {
    local exit_code=$?
    print_debug "Cleaning up temporary files..."

    # Remove any temporary files
    if [[ -n "${TEMP_FILES:-}" ]]; then
        for temp_file in ${TEMP_FILES}; do
            if [[ -f "${temp_file}" ]]; then
                rm -f "${temp_file}"
                print_debug "Removed temporary file: ${temp_file}"
            fi
        done
    fi

    if [[ ${exit_code} -ne 0 ]]; then
        print_error "Script exited with error code: ${exit_code}"
    fi

    exit "${exit_code}"
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Helper function to call a function and capture its return code
call_function() {
    "$@"
    return $?
}

# Helper function to check if a command exists and store result
check_command_exists() {
    local cmd="$1"
    local result_var="$2"
    command -v "${cmd}" >/dev/null 2>&1
    eval "${result_var}=\$?"
}

# Validate collection identifier
validate_collection() {
    local collection="$1"

    # Basic validation: alphanumeric, underscores, hyphens, dots
    if [[ ! "${collection}" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        print_error "Invalid collection identifier: '${collection}'"
        print_error "Collection identifiers should contain only alphanumeric characters, underscores, hyphens, and dots"
        return 1
    fi

    # Check length
    if [[ ${#collection} -gt 100 ]]; then
        print_error "Collection identifier too long: ${#collection} characters (max: 100)"
        return 1
    fi

    return 0
}

# Validate rows parameter
validate_rows() {
    local rows="$1"

    # Check if it's a number
    if [[ ! "${rows}" =~ ^[0-9]+$ ]]; then
        print_error "Invalid rows parameter: '${rows}' (must be a number)"
        return 1
    fi

    # Check range
    if [[ "${rows}" -lt "${MIN_ROWS}" ]]; then
        print_error "Rows must be at least ${MIN_ROWS} (got: ${rows})"
        return 1
    fi

    if [[ "${rows}" -gt "${MAX_ROWS}" ]]; then
        print_warning "Rows value ${rows} exceeds recommended maximum of ${MAX_ROWS}"
        print_warning "This may result in very long processing times"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! ${REPLY} =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled by user"
            exit 0
        fi
    fi

    return 0
}

# Check system dependencies
check_dependencies() {
    local missing_deps=()

    print_debug "Checking system dependencies..."

    local curl_exists jq_exists
    check_command_exists curl curl_exists
    check_command_exists jq jq_exists

    if [[ ${curl_exists} -ne 0 ]]; then
        missing_deps+=("curl")
    fi
    if [[ ${jq_exists} -ne 0 ]]; then
        missing_deps+=("jq")
    fi

    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        echo
        echo "Install missing dependencies:"
        for dep in "${missing_deps[@]}"; do
            case "${dep}" in
                "curl")
                    echo "  curl: Usually pre-installed on macOS"
                    echo "        If missing, install via: brew install curl"
                    ;;
                "jq")
                    echo "  jq:   Install via: brew install jq"
                    ;;
                *)
                    echo "  ${dep}: Unknown dependency"
                    ;;
            esac
        done
        echo
        echo "Note: This script requires bash 3.2+ (macOS default) or bash 4.0+"
        exit 1
    fi

    print_debug "All dependencies found"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

# Parse command line arguments
parse_arguments() {
    local args=("$@")
    local i=0
    local positional_args=()

    # First pass: collect all options and their values
    while [[ ${i} -lt ${#args[@]} ]]; do
        case "${args[${i}]}" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                print_debug "Verbose mode enabled"
                ;;
            -n|--dry-run)
                DRY_RUN=true
                print_info "Dry run mode enabled - no files will be downloaded"
                ;;
            -r|--root-dir)
                if [[ $((i + 1)) -ge ${#args[@]} ]]; then
                    print_error "Error: --root-dir requires a directory path"
                    exit 1
                fi
                ROOT_DIR="${args[$((i + 1))]}"
                print_debug "Root directory set to: ${ROOT_DIR}"
                i=$((i + 1))  # Skip the next argument as it's the directory path
                ;;
            -V|--version)
                show_version
                exit 0
                ;;
            -*)
                print_error "Unknown option: ${args[${i}]}"
                echo "Use --help for usage information"
                exit 1
                ;;
            *)
                # Collect positional arguments for later processing
                positional_args+=("${args[${i}]}")
                ;;
        esac
        ((i++))
    done

    # Set default root directory if not provided
    if [[ -z "${ROOT_DIR}" ]]; then
        ROOT_DIR="${DEFAULT_ROOT_DIR}"
    fi

    # Validate root directory if provided
    if [[ -n "${ROOT_DIR}" ]]; then
        if [[ ! -d "${ROOT_DIR}" ]]; then
            print_info "Root directory does not exist, creating: ${ROOT_DIR}"
            if ! mkdir -p "${ROOT_DIR}"; then
                print_error "Failed to create root directory: ${ROOT_DIR}"
                exit 1
            fi
        fi
        # Convert to absolute path
        ROOT_DIR="$(cd "${ROOT_DIR}" && pwd)"
        print_debug "Using root directory: ${ROOT_DIR}"
    else
        print_debug "Using current directory as root"
    fi

    # Process positional arguments
    case ${#positional_args[@]} in
        0)
            COLLECTIONS=("${DEFAULT_COLLECTION}")
            ROWS="${DEFAULT_ROWS}"
            print_info "Using default collection: ${DEFAULT_COLLECTION}"
            ;;
        1)
            # Check if first argument is a number (rows) or collection name
            if [[ "${positional_args[0]}" =~ ^[0-9]+$ ]]; then
                ROWS="${positional_args[0]}"
                COLLECTIONS=("${DEFAULT_COLLECTION}")
                print_info "Using ${ROWS} rows with default collection: ${DEFAULT_COLLECTION}"
            else
                COLLECTIONS=("${positional_args[0]}")
                ROWS="${DEFAULT_ROWS}"
                print_info "Using collection: ${positional_args[0]} with default rows: ${ROWS}"
            fi
            ;;
        *)
            # Check if first argument is a number (rows)
            if [[ "${positional_args[0]}" =~ ^[0-9]+$ ]]; then
                ROWS="${positional_args[0]}"
                COLLECTIONS=("${positional_args[@]:1}")
                print_info "Using ${ROWS} rows with collections: ${COLLECTIONS[*]}"
            else
                ROWS="${DEFAULT_ROWS}"
                COLLECTIONS=("${positional_args[@]}")
                print_info "Using collections: ${COLLECTIONS[*]} with default rows: ${ROWS}"
            fi
            ;;
    esac

    # Validate arguments
    if ! validate_rows "${ROWS}"; then
        exit 1
    fi

    # Validate all collections
    for collection in "${COLLECTIONS[@]}"; do
        if ! validate_collection "${collection}"; then
            exit 1
        fi
    done

    print_debug "Parsed arguments: collections='${COLLECTIONS[*]}', rows='${ROWS}'"
}

# =============================================================================
# FILE SYSTEM OPERATIONS
# =============================================================================

# Create collection directory
create_collection_directory() {
    local collection="$1"
    local collection_dir

    # Determine the full path for the collection directory
    if [[ -n "${ROOT_DIR}" ]]; then
        collection_dir="${ROOT_DIR}/${collection}"
    else
        collection_dir="${collection}"
    fi

    if [[ ! -d "${collection_dir}" ]]; then
        print_info "Creating directory: ${collection_dir}"
        if ! mkdir -p "${collection_dir}"; then
            print_error "Failed to create directory: ${collection_dir}"
            exit 3
        fi
    fi

    # Change to the collection directory for downloads
    if ! cd "${collection_dir}"; then
        print_error "Failed to change to directory: ${collection_dir}"
        exit 3
    fi
}

# Archive old download list
archive_old_download_list() {
    local collection="$1"
    local file_list_path="${FILE_LIST_NAME}"
    local file_list_old_path="${FILE_LIST_OLD_NAME}"

    if [[ -f "${file_list_path}" ]]; then
        if [[ -f "${file_list_old_path}" ]]; then
            rm -f "${file_list_old_path}"
        fi
        mv "${file_list_path}" "${file_list_old_path}"
        print_info "Archived old file list"

        # Restore the file list so we can check what's already downloaded
        cp "${file_list_old_path}" "${file_list_path}"
    fi
}

# =============================================================================
# DATE COMPARISON FUNCTIONS
# =============================================================================

# Parse ISO 8601 date to Unix timestamp
parse_iso_date() {
    local date_str="$1"
    local timestamp

    # Try different date formats
    timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "${date_str}" "+%s" 2>/dev/null) || \
    timestamp=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${date_str}" "+%s" 2>/dev/null) || \
    timestamp=$(date -j -f "%Y-%m-%d %H:%M:%S" "${date_str}" "+%s" 2>/dev/null) || \
    timestamp="0"

    echo "${timestamp}"
}

# Check if item needs downloading
item_needs_download() {
    local identifier="$1"
    local update_date="$2"
    local local_file="$3"

    print_debug "Checking if item needs download: ${identifier}"

    # Check if item exists in local file list
    if [[ -f "${local_file}" ]]; then
        local local_date
        local_date=$(grep "^${identifier}" "${local_file}" | cut -f2)

        if [[ -n "${local_date}" ]]; then
            print_debug "Found local date for ${identifier}: ${local_date}"

            # Compare dates
            local remote_timestamp
            local local_timestamp
            remote_timestamp=$(parse_iso_date "${update_date}")
            local_timestamp=$(parse_iso_date "${local_date}")

            print_debug "Date comparison: remote=${remote_timestamp}, local=${local_timestamp}"

            if [[ "${remote_timestamp}" -gt "${local_timestamp}" ]]; then
                print_debug "Remote is newer, needs download"
                return 0  # Needs download
            else
                print_debug "Local is newer or same, no download needed"
                return 1  # No download needed
            fi
        else
            print_debug "Item not found in local file list, needs download"
        fi
    else
        print_debug "Local file list not found, needs download"
    fi

    return 0  # Needs download (not in local list)
}

# Add item to local file list
add_to_local_file_list() {
    local identifier="$1"
    local update_date="$2"
    local local_file="$3"

    print_debug "Adding item to local file list: ${identifier}"

    # Remove existing entry if it exists
    if [[ -f "${local_file}" ]]; then
        grep -v "^${identifier}" "${local_file}" > "${local_file}.tmp" 2>/dev/null || touch "${local_file}.tmp"
        mv "${local_file}.tmp" "${local_file}"
    fi

    # Add new entry
    echo -e "${identifier}\t${update_date}" >> "${local_file}"
}

# =============================================================================
# INTERNET ARCHIVE API FUNCTIONS
# =============================================================================

# Build Internet Archive search URL
build_search_url() {
    local collection="$1"
    local rows="$2"

    # URL encode the collection parameter
    local encoded_collection
    encoded_collection=$(printf '%s\n' "${collection}" | sed "s/[[\.*^$()+?{|]/\\&/g")

    echo "${IA_SEARCH_URL}?q=collection%3A${encoded_collection}&fl%5B%5D=identifier&fl%5B%5D=oai_updatedate&sort%5B%5D=identifier+asc&sort%5B%5D=&sort%5B%5D=&rows=${rows}&output=json"
}

# Get search results from Internet Archive
get_search_results() {
    local collection="$1"
    local url
    url=$(build_search_url "${collection}" "${ROWS}")

    print_info "Fetching collection metadata from Internet Archive..."
    print_debug "URL: ${url}"

    local response
    local http_code

    # Make HTTP request with timeout and retry logic
    local max_retries=3
    local retry_count=0

    while [[ ${retry_count} -lt ${max_retries} ]]; do
        if response=$(curl -s -w "%{http_code}" --connect-timeout 30 --max-time 300 "${url}" 2>/dev/null); then
            break
        else
            ((retry_count++))
            if [[ ${retry_count} -lt ${max_retries} ]]; then
                print_warning "Request failed, retrying... (attempt $((retry_count + 1))/${max_retries})"
                sleep 2
            else
                print_error "Failed to fetch collection metadata after ${max_retries} attempts"
                exit 2
            fi
        fi
    done

    http_code="${response: -3}"
    local json_response="${response%???}"

    if [[ "${http_code}" != "200" ]]; then
        print_error "Request failed with HTTP code: ${http_code}"
        case "${http_code}" in
            404)
                print_error "Collection not found: ${collection}"
                ;;
            429)
                print_error "Rate limited. Please try again later."
                ;;
            500|502|503|504)
                print_error "Server error. Please try again later."
                ;;
            *)
                print_error "Unexpected HTTP status code: ${http_code}"
                ;;
        esac
        exit 2
    fi

    # Parse JSON and extract identifiers and update dates
    local temp_file
    temp_file=$(mktemp)
    TEMP_FILES="${TEMP_FILES:-} ${temp_file}"

    # Validate JSON response
    if ! echo "${json_response}" | jq empty 2>/dev/null; then
        print_error "Invalid JSON response from Internet Archive"
        exit 2
    fi

    local num_found
    num_found=$(echo "${json_response}" | jq -r '.response.numFound // 0')
    print_info "Found ${num_found} items in collection"

    if [[ "${num_found}" -eq 0 ]]; then
        print_warning "No items found in collection: ${collection}"
        echo "${temp_file}"
        return
    fi

    # Extract each document's identifier and latest update date
    if ! echo "${json_response}" | jq -r '.response.docs[] | "\(.identifier)\t\(.oai_updatedate[-1])"' > "${temp_file}"; then
        print_error "Failed to parse collection data"
        exit 2
    fi

    local count
    count=$(wc -l < "${temp_file}" 2>/dev/null || echo "0")
    print_info "Parsed ${count} items from search results"

    if [[ "${count}" -eq 0 ]]; then
        print_warning "No valid items found in collection data"
    fi

    echo "${temp_file}"
}

# =============================================================================
# DOWNLOAD FUNCTIONS
# =============================================================================

# Download a single file
download_file() {
    local identifier="$1"
    local url="$2"
    local download_path="$3"
    local count="$4"
    local total="$5"

    print_info "[${count}/${total}] Downloading: ${download_path}"
    print_debug "[${count}/${total}] From: ${url}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        print_info "[${count}/${total}] [DRY RUN] Would download: ${download_path}"
        return 0
    fi

    # Download with progress indicator
    if curl -L -o "${download_path}" --progress-bar --connect-timeout 30 --max-time 1800 "${url}" 2>/dev/null; then
        print_success "[${count}/${total}] Successfully downloaded: ${download_path}"
        return 0
    else
        print_error "[${count}/${total}] Failed to download: ${download_path}"
        # Remove failed download
        [[ -f "${download_path}" ]] && rm -f "${download_path}"
        return 1
    fi
}

# Download files
download_files() {
    local collection="$1"
    local search_results_file="$2"
    local local_file="${FILE_LIST_NAME}"
    local resource_base="${IA_COMPRESS_URL}"
    local count=0
    local total_downloads=0
    local successful_downloads=0
    local failed_downloads=0

    print_debug "Starting download process..."

    # Count total items to download
    while IFS=$'\t' read -r identifier update_date; do
        if [[ -n "${identifier}" && -n "${update_date}" ]]; then
            if item_needs_download "${identifier}" "${update_date}" "${local_file}"; then
                total_downloads=$((total_downloads + 1))
            fi
        fi
    done < "${search_results_file}"

    print_info "Found ${total_downloads} items to download"

    if [[ "${total_downloads}" -eq 0 ]]; then
        print_info "All items are already up to date"
        return 0
    fi

    # Download items
    while IFS=$'\t' read -r identifier update_date; do
        if [[ -n "${identifier}" && -n "${update_date}" ]]; then
            if item_needs_download "${identifier}" "${update_date}" "${local_file}"; then
                count=$((count + 1))
                local download_path="${identifier}.zip"
                local url="${resource_base}/${identifier}"

                if download_file "${identifier}" "${url}" "${download_path}" "${count}" "${total_downloads}"; then
                    add_to_local_file_list "${identifier}" "${update_date}" "${local_file}"
                    successful_downloads=$((successful_downloads + 1))
                else
                    failed_downloads=$((failed_downloads + 1))
                fi
            fi
        fi
    done < "${search_results_file}"

    # Print summary
    print_info "Download summary:"
    print_info "  Total items processed: ${total_downloads}"
    print_success "  Successfully downloaded: ${successful_downloads}"
    if [[ ${failed_downloads} -gt 0 ]]; then
        print_warning "  Failed downloads: ${failed_downloads}"
    fi

    # Return appropriate exit code
    if [[ ${failed_downloads} -gt 0 ]]; then
        return 1
    fi
    return 0
}

# =============================================================================
# COLLECTION PROCESSING FUNCTIONS
# =============================================================================

# Process a single collection
process_collection() {
    local collection="$1"
    local collection_index="$2"
    local total_collections="$3"

    print_info "========================================================"
    print_info "Processing collection ${collection_index} of ${total_collections}: ${collection}"
    print_info "========================================================"

    # Create collection directory
    create_collection_directory "${collection}"

    # Archive old download list
    archive_old_download_list "${collection}"

    # Get search results
    local search_results_file
    search_results_file=$(get_search_results "${collection}")

    # Download files
    if download_files "${collection}" "${search_results_file}"; then
        print_success "Collection '${collection}' processed successfully!"
        return 0
    else
        print_error "Collection '${collection}' completed with errors"
        return 1
    fi
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    print_info "${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${RESET} - Internet Archive Collection Downloader"
    print_info "========================================================"
    print_info "BASH port by: ${SCRIPT_AUTHOR}"
    print_info "Original .NET version by: ${ORIGINAL_AUTHOR}"
    print_info "Original repository: ${ORIGINAL_REPOSITORY}"

    # Check dependencies
    check_dependencies

    # Parse command line arguments
    parse_arguments "$@"

    # Process each collection
    local total_collections=${#COLLECTIONS[@]}
    local successful_collections=0
    local failed_collections=0
    local collection_index=0

    print_info "Processing ${total_collections} collection(s): ${COLLECTIONS[*]}"
    print_info "Using ${ROWS} rows per collection"
    if [[ -n "${ROOT_DIR}" ]]; then
        print_info "Root directory: ${ROOT_DIR}"
    else
        print_info "Root directory: current directory"
    fi

    for collection in "${COLLECTIONS[@]}"; do
        collection_index=$((collection_index + 1))

        if process_collection "${collection}" "${collection_index}" "${total_collections}"; then
            successful_collections=$((successful_collections + 1))
        else
            failed_collections=$((failed_collections + 1))
        fi
    done

    # Print final summary
    print_info "========================================================"
    print_info "FINAL SUMMARY"
    print_info "========================================================"
    print_info "Total collections processed: ${total_collections}"
    print_success "Successfully processed: ${successful_collections}"

    if [[ ${failed_collections} -gt 0 ]]; then
        print_warning "Failed collections: ${failed_collections}"
        print_error "SyncCollection completed with errors"
        exit 1
    else
        print_success "SyncCollection completed successfully!"
        exit 0
    fi
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
