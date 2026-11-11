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
# BASH PORT VERSION: 1.2.0
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
# ✅ Resume Capability - Downloads only new, updated, or missing zips
# ✅ Mirror - Deletes local zips that have left the collection once the full set was fetched
# ✅ Progress Tracking - Real-time download progress and statistics
# ✅ Error Handling - Comprehensive error handling with meaningful messages
# ✅ Dry Run Mode - Preview downloads and removals without changing files
# ✅ Verbose Logging - Detailed debug information when needed
# ✅ Input Validation - Validates collection names and row counts
# ✅ Retry Logic - Automatic retry for failed network requests
# ✅ Cleanup - Automatic cleanup of temporary files
# ✅ Exclude Patterns - Skip matching names and delete matching zips already on disk
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
#   ./synccollection.sh --dry-run 10 softwarelibrary      # Preview the sync without saving files
#   ./synccollection.sh --exclude '*demo*' --exclude '*beta*' 50 softwarelibrary
#   ./synccollection.sh --dry-run --exclude '*demo*' 10 apple_ii_library_4am
#   ./synccollection.sh --help                            # Show help
#   ./synccollection.sh --version                         # Show version
#
# Command Line Options:
#   -h, --help      Show help message and exit
#   -v, --verbose   Enable verbose output
#   -n, --dry-run   Preview the sync. No zip is saved, removed, or recorded
#   -r, --root-dir  Directory for collection folders (default: current directory)
#   -x, --exclude   Skip matching names and delete matching zips already saved
#   -j, --jobs      Number of items to download at once (default: 4, max: 8)
#   -V, --version   Show version information and exit
#
# Options may appear in any order. The directory must follow --root-dir, and
# the pattern must follow each --exclude. A row count must be the first
# positional argument, before any collection name.
#
# Arguments:
#   rows        Number of items to sync (default: 50000, max: 100000)
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
# Preview the sync without saving, removing, or recording files:
#   ./synccollection.sh --dry-run 10 softwarelibrary
#
# Verbose mode with detailed logging:
#   ./synccollection.sh --verbose 100 softwarelibrary
#
# Skip items whose names match a pattern. Each saved file is still one zip,
# and the pattern does not need a .zip suffix:
#   ./synccollection.sh --exclude '*demo*' --exclude '*beta*' 50 softwarelibrary
#
# Preview which item names would be skipped:
#   ./synccollection.sh --dry-run --exclude '*demo*' 10 apple_ii_library_4am
#
# Download to a specific root directory. The directory is created if needed:
#   ./synccollection.sh --root-dir /path/to/collections
#   ./synccollection.sh -r /Volumes/Data/IA 50 softwarelibrary
#
# Root directory and exclude patterns can be combined, in any option order:
#   ./synccollection.sh --exclude '*demo*' --root-dir /Volumes/Data/IA 50 softwarelibrary
#
# =============================================================================
# HOW IT WORKS
# =============================================================================
#
# 1. Validation - Validates command line arguments and system dependencies
# 2. Metadata Fetching - Retrieves collection metadata in pages of 50000
# 3. State Management - Maintains local file list (fileList.txt) to track downloads
# 4. Smart Downloading - Compares the whole file list in one pass
#    - Same or older remote date, and the zip is on disk: leave it in place
#    - Newer remote date, missing fileList.txt row, or missing zip: download
#    - A zip copied in by hand is not treated as already synced
# 5. Mirror - When every item in the collection was fetched, delete local zips
#    whose items are gone. A short row count keeps zips outside that fetch.
#    The file list is rewritten from the items that remain.
# 6. Exclude Filtering - Optional shell globs match the item name. They do not
#    look inside the archive and do not need a .zip suffix. A match is not
#    downloaded. A matching zip already on disk is deleted, and its file list
#    row is removed, including when the row count does not cover the collection.
# 7. Progress Tracking - Shows real-time progress and statistics
# 8. Error Handling - Gracefully handles network errors and failed downloads
# 9. Cleanup - Automatically cleans up temporary files
#
# File Structure:
#   collection_name/
#   ├── fileList.txt          # Local tracking file (tab-separated: identifier, update_date)
#   ├── fileListOld.txt       # Previous version (backup)
#   ├── item1.zip             # Downloaded items
#   └── item2.zip
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
# Dry Run Mode (no zips saved or removed, fileList.txt unchanged):
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
SCRIPT_VERSION="1.2.0"
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
DEFAULT_ROWS="50000"
readonly DEFAULT_ROWS
DEFAULT_ROOT_DIR=""  # Empty means current directory
readonly DEFAULT_ROOT_DIR
MAX_ROWS="100000"  # Reasonable upper limit
readonly MAX_ROWS
MIN_ROWS="1"       # Minimum rows to process
readonly MIN_ROWS
# Catalog page size. 50000 matches the default row count, so a collection
# that fits in one request is fetched from the start. A later page uses a
# deep result offset, and Archive.org rejects that with HTTP 507.
IA_PAGE_SIZE="50000"
readonly IA_PAGE_SIZE
DEFAULT_JOBS="4"
readonly DEFAULT_JOBS
MAX_JOBS="8"
readonly MAX_JOBS

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
EXCLUDE_PATTERNS=()
JOBS="${DEFAULT_JOBS}"
PARALLEL_DOWNLOADS=false
SEARCH_COMPLETE=false
SEARCH_NUM_FOUND=0
SEARCH_FETCHED=0
SEARCH_RESULTS_FILE=""
START_DIR=""
COLLECTION_DIR=""
SYNC_WORK=""

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
${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${RESET} - Internet Archive Collection Sync

${BOLD}DESCRIPTION:${RESET}
    Download collections from the Internet Archive. Each item is saved as
    <identifier>.zip. Sync state is the update date stored in fileList.txt,
    in the collection folder:

    - The same or an older remote date leaves the existing zip in place.
    - A newer remote date, a missing fileList.txt row, or a missing zip
      downloads the item again. A zip copied in by hand is overwritten
      unless its name and date are already in fileList.txt.
    - --exclude matches the item name, not files inside the zip. Do not add
      .zip to the pattern. A match is not downloaded. A matching zip already
      on disk is deleted, and its fileList.txt row is removed.
    - When the fetch includes every item in the collection, a local zip whose
      item has left the collection is deleted.
    - When the row count stops the fetch early, zips outside that fetch are
      kept. Excluded names are still removed.

    Options may appear in any order. The path must follow --root-dir, the
    pattern must follow each --exclude, and the number must follow --jobs.
    A row count must be the first positional argument, before any collection
    name.

    ${BOLD}Original .NET version by:${RESET} ${ORIGINAL_AUTHOR}
    ${BOLD}Original repository:${RESET} ${ORIGINAL_REPOSITORY}
    ${BOLD}BASH port by:${RESET} ${SCRIPT_AUTHOR}

${BOLD}USAGE:${RESET}
    ${SCRIPT_NAME} [options] [rows] [collection1] [collection2] ...

${BOLD}ARGUMENTS:${RESET}
    rows         Number of items to fetch (default: ${DEFAULT_ROWS}, max: ${MAX_ROWS}).
                Items that left the collection are removed only when this
                covers the whole collection
    collection   Collection identifier(s) (default: ${DEFAULT_COLLECTION})
                Multiple collections can be specified

${BOLD}OPTIONS:${RESET}
    -h, --help         Show this help message and exit
    -v, --verbose      Enable verbose output
    -n, --dry-run      Preview the sync. Nothing is saved, removed, or recorded
    -r, --root-dir DIR Collection folders are created under DIR (default: current directory).
                       DIR is created if it does not exist
    -x, --exclude PAT  Skip an item when its name matches PAT (shell glob).
                       Repeat for more patterns. Quote patterns so the shell
                       does not expand them. Patterns are case-sensitive and
                       match the item name. You do not need to add .zip.
                       Matching items are not downloaded. A matching zip
                       already on disk is deleted.
    -j, --jobs N       Download N items at the same time (default: ${DEFAULT_JOBS}, maximum: ${MAX_JOBS})
    -V, --version      Show version information and exit

${BOLD}EXAMPLES:${RESET}
    ${SCRIPT_NAME}                                    # Download default collection
    ${SCRIPT_NAME} apple_ii_library_4am              # Download specific collection
    ${SCRIPT_NAME} 50 softwarelibrary                # Download first 50 items
    ${SCRIPT_NAME} collection1 collection2           # Download multiple collections
    ${SCRIPT_NAME} 100 coll1 coll2 coll3             # Download 100 items from 3 collections
    ${SCRIPT_NAME} --verbose 100 softwarelibrary     # Verbose mode with 100 items
    ${SCRIPT_NAME} --jobs 1 100 softwarelibrary      # Download one item at a time
    ${SCRIPT_NAME} --dry-run 10 softwarelibrary      # Preview the sync without saving files
    ${SCRIPT_NAME} --exclude '*demo*' --exclude '*beta*' 50 softwarelibrary
    ${SCRIPT_NAME} --dry-run --exclude '*demo*' 10 apple_ii_library_4am
    ${SCRIPT_NAME} --root-dir /path/to/collections   # Download to a specific root directory
    ${SCRIPT_NAME} -r /Volumes/Data/IA 50 softwarelibrary  # Download 50 items to /Volumes/Data/IA
    ${SCRIPT_NAME} --exclude '*demo*' --root-dir /Volumes/Data/IA 50 softwarelibrary

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

    if [[ -n "${SYNC_WORK:-}" && -d "${SYNC_WORK}" ]]; then
        rm -rf "${SYNC_WORK}"
    fi

    if [[ -n "${COLLECTION_DIR:-}" && -d "${COLLECTION_DIR}" ]]; then
        find "${COLLECTION_DIR}" -maxdepth 1 -type f -name '*.zip.partial' -delete 2>/dev/null || true
        rm -f "${COLLECTION_DIR}/${FILE_LIST_NAME}.tmp"
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

# Validate concurrent download count
validate_jobs() {
    local jobs="$1"

    if [[ ! "${jobs}" =~ ^[0-9]+$ ]] || [[ "${jobs}" -lt 1 ]]; then
        print_error "Invalid jobs value: '${jobs}' (use a whole number from 1 to ${MAX_JOBS})"
        return 1
    fi

    if [[ "${jobs}" -gt "${MAX_JOBS}" ]]; then
        print_error "Jobs value ${jobs} is above the maximum of ${MAX_JOBS}"
        return 1
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
                print_info "Dry run mode enabled - no files will be saved, removed, or recorded"
                ;;
            -j|--jobs)
                if [[ $((i + 1)) -ge ${#args[@]} ]]; then
                    print_error "Error: --jobs requires a number"
                    exit 1
                fi
                JOBS="${args[$((i + 1))]}"
                print_debug "Concurrent downloads set to: ${JOBS}"
                i=$((i + 1))
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
            -x|--exclude)
                if [[ $((i + 1)) -ge ${#args[@]} ]]; then
                    print_error "Error: --exclude requires a pattern"
                    exit 1
                fi
                local exclude_pattern="${args[$((i + 1))]}"
                if [[ -z "${exclude_pattern}" ]]; then
                    print_error "Error: --exclude pattern must not be empty"
                    exit 1
                fi
                EXCLUDE_PATTERNS+=("${exclude_pattern}")
                print_debug "Exclude pattern: ${exclude_pattern}"
                i=$((i + 1))  # Skip the next argument as it's the pattern
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

    if ! validate_jobs "${JOBS}"; then
        exit 1
    fi

    # Validate all collections
    for collection in "${COLLECTIONS[@]}"; do
        if ! validate_collection "${collection}"; then
            exit 1
        fi
    done

    if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
        print_debug "Exclude patterns: ${EXCLUDE_PATTERNS[*]}"
    fi
    print_debug "Parsed arguments: collections='${COLLECTIONS[*]}', rows='${ROWS}'"
}

# =============================================================================
# FILE SYSTEM OPERATIONS
# =============================================================================

# Create collection directory
create_collection_directory() {
    local collection="$1"
    local collection_dir

    # Determine the full path for the collection directory. Later collections
    # must not be created inside the previous one after this function cds.
    if [[ -n "${ROOT_DIR}" ]]; then
        collection_dir="${ROOT_DIR}/${collection}"
    else
        collection_dir="${START_DIR}/${collection}"
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

    COLLECTION_DIR="${collection_dir}"
}

# Copy the current file list aside before this run rewrites it.
archive_old_download_list() {
    local file_list_path="${FILE_LIST_NAME}"
    local file_list_old_path="${FILE_LIST_OLD_NAME}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        return 0
    fi

    if [[ -f "${file_list_path}" ]]; then
        cp "${file_list_path}" "${file_list_old_path}"
        print_info "Backed up file list to ${file_list_old_path}"
    fi
}

# =============================================================================
# SYNC PLANNING
# =============================================================================

# Internet Archive item identifiers are a single safe path component.
valid_item_name() {
    [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]]
}

# Classify every remote item in one pass.
# ISO-8601 dates in the forms the Archive sends sort as digits, so this does
# not fork date(1) once per item.
#
# Prints: action, identifier, remote date, stored date
#   download  needs a zip
#   keep      leave the zip and the stored date
#   nodate    remote item has no usable update date
classify_items() {
    local file_list="$1"
    local zip_ids="$2"
    local search_file="$3"

    {
        echo "#LIST"
        if [[ -f "${file_list}" ]]; then
            cat "${file_list}"
        fi
        echo "#ZIPS"
        if [[ -f "${zip_ids}" ]]; then
            cat "${zip_ids}"
        fi
        echo "#REMOTE"
        cat "${search_file}"
    } | awk -F '\t' -v OFS='\t' '
        function norm(s,    x) {
            x = s
            gsub(/[^0-9]/, "", x)
            if (length(x) < 8) {
                return ""
            }
            return substr(x "00000000000000", 1, 14)
        }
        $0 == "#LIST" { section = "list"; next }
        $0 == "#ZIPS" { section = "zips"; next }
        $0 == "#REMOTE" { section = "remote"; next }
        section == "list" {
            if ($1 != "") {
                local_date[$1] = $2
                in_list[$1] = 1
            }
            next
        }
        section == "zips" {
            if ($1 != "") {
                zip[$1] = 1
            }
            next
        }
        section == "remote" {
            id = $1
            remote = $2
            if (id == "" || seen[id]++) {
                next
            }
            if (remote == "") {
                old = (id in in_list) ? local_date[id] : ""
                print "nodate", id, "", old
                next
            }
            if (!(id in in_list)) {
                print "download", id, remote, ""
                next
            }
            old = local_date[id]
            rn = norm(remote)
            ln = norm(old)
            if (rn == "" || (ln != "" && rn <= ln)) {
                if (rn != "" && !(id in zip)) {
                    print "download", id, remote, old
                } else {
                    print "keep", id, remote, old
                }
            } else {
                print "download", id, remote, old
            }
        }
    '
}

# Print the identifier of each top-level zip that uses a safe item name.
list_local_zip_ids() {
    local path name

    find . -maxdepth 1 -type f -name '*.zip' -print0 > "${SYNC_WORK}/zips.null"
    while IFS= read -r -d '' path; do
        name=$(basename -- "${path}")
        name="${name%.zip}"
        if valid_item_name "${name}"; then
            printf '%s\n' "${name}"
        else
            print_debug "Ignoring local file with an unusual name: ${path}"
        fi
    done < "${SYNC_WORK}/zips.null"
}

# =============================================================================
# INTERNET ARCHIVE API FUNCTIONS
# =============================================================================

# Build one page of an Internet Archive search.
build_search_url() {
    local collection="$1"
    local page_rows="$2"
    local page="$3"
    local encoded_collection

    encoded_collection=$(printf '%s\n' "${collection}" | sed "s/[[\.*^$()+?{|]/\\&/g")

    echo "${IA_SEARCH_URL}?q=collection%3A${encoded_collection}&fl%5B%5D=identifier&fl%5B%5D=oai_updatedate&sort%5B%5D=identifier+asc&rows=${page_rows}&page=${page}&output=json"
}

# Download one search page. Returns 0 and writes the body on HTTP 200.
fetch_search_body() {
    local url="$1"
    local dest="$2"
    local max_retries=3
    local retry_count=0
    local http_code=""

    while [[ ${retry_count} -lt ${max_retries} ]]; do
        http_code=""
        if http_code=$(curl -sS --compressed -o "${dest}" -w "%{http_code}" --connect-timeout 30 --max-time 300 "${url}" 2>"${dest}.err"); then
            :
        fi
        if [[ -z "${http_code}" ]]; then
            http_code="000"
        fi

        if [[ "${http_code}" == "200" ]]; then
            rm -f "${dest}.err"
            return 0
        fi

        retry_count=$((retry_count + 1))
        if [[ ${retry_count} -lt ${max_retries} ]]; then
            print_warning "Request failed (HTTP ${http_code}), retrying... (attempt $((retry_count + 1))/${max_retries})"
            sleep 2
        fi
    done

    print_error "Failed to fetch collection metadata after ${max_retries} attempts (HTTP ${http_code})"
    if [[ -s "${dest}.err" ]]; then
        print_debug "curl: $(<"${dest}.err")"
    fi
    rm -f "${dest}.err"

    case "${http_code}" in
        404)
            print_error "Collection not found"
            ;;
        429)
            print_error "Rate limited. Please try again later."
            ;;
        500|502|503|504)
            print_error "Server error. Please try again later."
            ;;
        000)
            print_error "Could not reach the Internet Archive."
            ;;
        *)
            print_error "Unexpected HTTP status code: ${http_code}"
            ;;
    esac
    return 1
}

# Append identifier and latest update date rows from one search response.
append_search_docs() {
    local body="$1"
    local dest="$2"

    if ! jq -e '.response.numFound != null' "${body}" >/dev/null 2>&1; then
        print_error "Search response did not include a result count"
        return 1
    fi

    jq -r '
        .response.docs[]?
        | [
            (.identifier // ""),
            (
              if (.oai_updatedate | type) == "array" then (.oai_updatedate[-1] // "")
              elif (.oai_updatedate | type) == "string" then .oai_updatedate
              else ""
              end
            )
          ]
        | @tsv
    ' "${body}" >> "${dest}"
}

# Get search results from Internet Archive.
# Pages until ROWS items or the whole collection, whichever is smaller.
# Sets SEARCH_RESULTS_FILE, SEARCH_NUM_FOUND, SEARCH_FETCHED, and SEARCH_COMPLETE.
# SEARCH_COMPLETE is true only when every item in the collection was fetched.
get_search_results() {
    local collection="$1"
    local combined page target fetched want url body
    local num_found before after got unique

    combined=$(mktemp)
    TEMP_FILES="${TEMP_FILES:-} ${combined}"
    : > "${combined}"

    SEARCH_COMPLETE=false
    SEARCH_NUM_FOUND=0
    SEARCH_FETCHED=0
    page=1
    target=0
    fetched=0

    while true; do
        want="${IA_PAGE_SIZE}"
        if [[ ${page} -eq 1 ]]; then
            if [[ "${ROWS}" -lt "${want}" ]]; then
                want="${ROWS}"
            fi
        else
            want=$((target - fetched))
            if [[ ${want} -le 0 ]]; then
                break
            fi
            if [[ ${want} -gt ${IA_PAGE_SIZE} ]]; then
                want="${IA_PAGE_SIZE}"
            fi
        fi

        # Cap the number of pages. This is not the page size.
        if [[ ${page} -gt 10000 ]]; then
            print_error "Stopped after too many search pages"
            exit 2
        fi

        url=$(build_search_url "${collection}" "${want}" "${page}")
        if [[ ${page} -eq 1 ]]; then
            print_info "Fetching collection metadata from Internet Archive..."
        else
            print_info "Fetching metadata page ${page} (${fetched} items so far)..."
        fi
        print_debug "URL: ${url}"

        body=$(mktemp)
        TEMP_FILES="${TEMP_FILES:-} ${body}"
        if ! fetch_search_body "${url}" "${body}"; then
            exit 2
        fi

        if ! jq empty "${body}" >/dev/null 2>&1; then
            print_error "Invalid JSON response from Internet Archive"
            exit 2
        fi

        if ! num_found=$(jq -r '.response.numFound // empty' "${body}"); then
            print_error "Failed to parse collection data"
            exit 2
        fi
        if [[ ! "${num_found}" =~ ^[0-9]+$ ]]; then
            print_error "Search response did not include a result count"
            exit 2
        fi

        SEARCH_NUM_FOUND="${num_found}"
        if [[ ${num_found} -lt ${ROWS} ]]; then
            target="${num_found}"
        else
            target="${ROWS}"
        fi

        if [[ ${page} -eq 1 ]]; then
            print_info "Found ${num_found} items in collection"
            if [[ ${num_found} -eq 0 ]]; then
                SEARCH_COMPLETE=true
                SEARCH_RESULTS_FILE="${combined}"
                print_warning "No items found in collection: ${collection}"
                return 0
            fi
        fi

        before=$(wc -l < "${combined}" | tr -d ' ')
        if ! append_search_docs "${body}" "${combined}"; then
            exit 2
        fi
        after=$(wc -l < "${combined}" | tr -d ' ')
        got=$((after - before))
        rm -f "${body}"

        if [[ ${got} -eq 0 ]]; then
            if [[ ${fetched} -lt ${target} ]]; then
                print_error "Search results ended after ${fetched} items; expected ${target}"
                exit 2
            fi
            break
        fi

        fetched=$((fetched + got))
        if [[ ${fetched} -ge ${target} ]]; then
            break
        fi
        page=$((page + 1))
    done

    unique=$(awk -F '\t' 'NF && $1 != "" && !seen[$1]++ { n++ } END { print n+0 }' "${combined}")
    SEARCH_FETCHED="${unique}"

    if [[ ${SEARCH_FETCHED} -ge ${SEARCH_NUM_FOUND} ]]; then
        SEARCH_COMPLETE=true
    elif [[ ${fetched} -ge ${ROWS} || ${SEARCH_FETCHED} -ge ${ROWS} ]]; then
        SEARCH_COMPLETE=false
    else
        print_error "Search results ended after ${SEARCH_FETCHED} items; expected ${target}"
        exit 2
    fi

    print_info "Parsed ${SEARCH_FETCHED} items from search results"
    SEARCH_RESULTS_FILE="${combined}"
}

# =============================================================================
# DOWNLOAD FUNCTIONS
# =============================================================================

# Return 0 when the item name matches an exclude pattern.
# The pattern is compared to the item identifier. The .zip suffix on the
# saved file is not part of the name, so patterns do not need to end in .zip.
filename_excluded() {
    local name="$1"
    local pattern

    if [[ ${#EXCLUDE_PATTERNS[@]} -eq 0 ]]; then
        return 1
    fi

    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        # shellcheck disable=SC2254
        if [[ "${name}" == ${pattern} ]]; then
            return 0
        fi
    done
    return 1
}

# Download one zip. A failed transfer leaves the previous zip in place.
download_file() {
    local identifier="$1"
    local download_path="$2"
    local count="$3"
    local total="$4"
    local url="${IA_COMPRESS_URL}/${identifier}"
    local partial="${download_path}.partial"
    local -a curl_args

    if ! valid_item_name "${identifier}"; then
        print_error "[${count}/${total}] Refusing unsafe identifier: ${identifier}"
        return 1
    fi

    print_info "[${count}/${total}] Downloading: ${download_path}"
    print_debug "[${count}/${total}] From: ${url}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        print_info "[${count}/${total}] [DRY RUN] Would download: ${download_path}"
        return 0
    fi

    curl_args=(-L --fail --retry 3 --retry-delay 2 --retry-connrefused --connect-timeout 30 --max-time 1800 -o "${partial}")
    if [[ "${PARALLEL_DOWNLOADS}" == "true" ]]; then
        curl_args+=(-sS)
    else
        curl_args+=(--progress-bar)
    fi

    if curl "${curl_args[@]}" "${url}"; then
        if mv -f -- "${partial}" "${download_path}"; then
            print_success "[${count}/${total}] Successfully downloaded: ${download_path}"
            return 0
        fi
        print_error "[${count}/${total}] Failed to save: ${download_path}"
        rm -f -- "${partial}"
        return 1
    fi

    print_error "[${count}/${total}] Failed to download: ${download_path}"
    rm -f -- "${partial}"
    return 1
}

# Download the rows in list_file. Successful rows land in success_file.
perform_downloads() {
    local list_file="$1"
    local success_file="$2"
    local fail_file="$3"
    local total="$4"
    local count=0
    local identifier=""
    local update_date=""
    local result_dir=""
    local fifo=""
    local slot=0
    local ok_count=0
    local fail_count=0

    : > "${success_file}"
    : > "${fail_file}"

    if [[ "${total}" -eq 0 ]]; then
        return 0
    fi

    if [[ "${DRY_RUN}" == "true" || "${JOBS}" -le 1 || "${total}" -le 1 ]]; then
        while IFS=$'\t' read -r identifier update_date; do
            [[ -z "${identifier}" ]] && continue
            count=$((count + 1))
            if download_file "${identifier}" "${identifier}.zip" "${count}" "${total}"; then
                if [[ "${DRY_RUN}" != "true" ]]; then
                    printf '%s\t%s\n' "${identifier}" "${update_date}" >> "${success_file}"
                fi
            else
                printf '%s\n' "${identifier}" >> "${fail_file}"
            fi
        done < "${list_file}"
        return 0
    fi

    result_dir="${SYNC_WORK}/results"
    mkdir -p "${result_dir}"
    fifo=$(mktemp -u "${TMPDIR:-/tmp}/synccollection.fifo.XXXXXX")
    if ! mkfifo "${fifo}"; then
        print_error "Failed to create a download queue"
        return 1
    fi
    exec 3<>"${fifo}"
    rm -f "${fifo}"

    PARALLEL_DOWNLOADS=true
    while [[ ${slot} -lt ${JOBS} ]]; do
        printf '\n' >&3
        slot=$((slot + 1))
    done

    while IFS=$'\t' read -r identifier update_date; do
        [[ -z "${identifier}" ]] && continue
        count=$((count + 1))
        IFS= read -r -u 3
        (
            set +e
            trap - EXIT INT TERM
            trap 'printf "\n" >&3' EXIT
            if download_file "${identifier}" "${identifier}.zip" "${count}" "${total}"; then
                printf '%s\t%s\n' "${identifier}" "${update_date}" > "${result_dir}/${count}.ok"
            else
                printf '%s\n' "${identifier}" > "${result_dir}/${count}.fail"
            fi
        ) &
    done < "${list_file}"

    wait || true
    exec 3>&- || true
    exec 3<&- || true
    PARALLEL_DOWNLOADS=false

    find "${result_dir}" -name '*.ok' -exec cat {} \; >> "${success_file}" 2>/dev/null || true
    find "${result_dir}" -name '*.fail' -exec cat {} \; >> "${fail_file}" 2>/dev/null || true

    ok_count=$(awk 'NF { n++ } END { print n+0 }' "${success_file}")
    fail_count=$(awk 'NF { n++ } END { print n+0 }' "${fail_file}")
    if [[ $((ok_count + fail_count)) -lt ${total} ]]; then
        print_warning "$((total - ok_count - fail_count)) downloads did not report a result"
    fi
    return 0
}

# Local zips to delete. Reason is "excluded" or "not in the collection".
build_removal_list() {
    local remote_ids="$1"
    local local_ids="$2"
    local excluded_ids="$3"
    local mirror="$4"

    {
        echo "#REMOTE"
        cat "${remote_ids}"
        echo "#LOCAL"
        cat "${local_ids}"
        echo "#EXCLUDE"
        cat "${excluded_ids}"
    } | awk -F '\t' -v OFS='\t' -v mirror="${mirror}" '
        $0 == "#REMOTE" { section = "remote"; next }
        $0 == "#LOCAL" { section = "local"; next }
        $0 == "#EXCLUDE" { section = "exclude"; next }
        section == "remote" { if ($1 != "") remote[$1] = 1; next }
        section == "local" { if ($1 != "") local[$1] = 1; next }
        section == "exclude" { if ($1 != "") exclude[$1] = 1; next }
        END {
            for (id in local) {
                if (exclude[id]) {
                    print id, "excluded"
                } else if (mirror == 1 && !remote[id]) {
                    print id, "not in the collection"
                }
            }
        }
    ' | sort -t $'\t' -k1,1
}

# Rewrite fileList.txt from the items this run decided to keep.
# complete=1 drops stored rows whose items were not fetched.
# complete=0 keeps stored rows outside this fetch, except excluded names.
write_file_list() {
    local dest="$1"
    local excluded_ids="$2"
    local fail_ids="$3"
    local keep_rows="$4"
    local success_rows="$5"
    local old_list="$6"
    local complete="$7"
    local tmp="${dest}.tmp"

    {
        echo "#DROP"
        cat "${excluded_ids}"
        echo "#FAIL"
        cat "${fail_ids}"
        echo "#KEEP"
        cat "${keep_rows}"
        echo "#OK"
        cat "${success_rows}"
        echo "#OLD"
        if [[ -f "${old_list}" ]]; then
            cat "${old_list}"
        fi
    } | awk -F '\t' -v OFS='\t' -v complete="${complete}" '
        $0 == "#DROP" { section = "drop"; next }
        $0 == "#FAIL" { section = "fail"; next }
        $0 == "#KEEP" { section = "keep"; next }
        $0 == "#OK" { section = "ok"; next }
        $0 == "#OLD" { section = "old"; next }
        section == "drop" { if ($1 != "") drop[$1] = 1; next }
        section == "fail" { if ($1 != "") fail[$1] = 1; next }
        section == "keep" || section == "ok" {
            if ($1 != "" && !drop[$1]) {
                date[$1] = $2
                want[$1] = 1
            }
            next
        }
        section == "old" {
            if ($1 == "" || drop[$1]) {
                next
            }
            if (complete == 1) {
                if (fail[$1] && !($1 in want)) {
                    date[$1] = $2
                    want[$1] = 1
                }
            } else if (!($1 in want)) {
                date[$1] = $2
                want[$1] = 1
            }
        }
        END {
            for (id in want) {
                if (want[id]) {
                    print id, date[id]
                }
            }
        }
    ' | sort -t $'\t' -k1,1 > "${tmp}"

    mv -f -- "${tmp}" "${dest}"
}

# Download what changed, delete what should not remain, then rewrite the file list.
sync_files() {
    local search_results_file="$1"
    local work file_list mirror_removals action id remote old existing
    local download_count exclude_count success_count fail_count
    local removal_count removed_ok removal_failed complete_flag status
    local reason

    work=$(mktemp -d "${TMPDIR:-/tmp}/synccollection.XXXXXX")
    SYNC_WORK="${work}"
    file_list="${FILE_LIST_NAME}"
    if [[ ! -f "${file_list}" ]]; then
        file_list="${work}/empty-list"
        : > "${file_list}"
    fi

    list_local_zip_ids | sort -u > "${work}/local_ids.txt"
    classify_items "${file_list}" "${work}/local_ids.txt" "${search_results_file}" > "${work}/plan.tsv"

    : > "${work}/remote_ids.txt"
    : > "${work}/excluded_ids.txt"
    : > "${work}/to_download.tsv"
    : > "${work}/to_keep.tsv"

    mirror_removals=true
    if [[ "${SEARCH_COMPLETE}" != "true" ]]; then
        mirror_removals=false
    fi

    while IFS=$'\t' read -r action id remote old; do
        [[ -z "${id}" ]] && continue
        if ! valid_item_name "${id}"; then
            mirror_removals=false
            print_warning "Skipping unusual identifier from the collection: ${id}"
            continue
        fi
        printf '%s\n' "${id}" >> "${work}/remote_ids.txt"
        if filename_excluded "${id}"; then
            printf '%s\n' "${id}" >> "${work}/excluded_ids.txt"
            continue
        fi
        case "${action}" in
            download)
                printf '%s\t%s\n' "${id}" "${remote}" >> "${work}/to_download.tsv"
                ;;
            keep|nodate)
                if [[ -n "${old}" ]]; then
                    printf '%s\t%s\n' "${id}" "${old}" >> "${work}/to_keep.tsv"
                elif [[ -n "${remote}" ]]; then
                    printf '%s\t%s\n' "${id}" "${remote}" >> "${work}/to_keep.tsv"
                fi
                ;;
        esac
    done < "${work}/plan.tsv"

    while IFS= read -r existing; do
        [[ -z "${existing}" ]] && continue
        if filename_excluded "${existing}"; then
            printf '%s\n' "${existing}" >> "${work}/excluded_ids.txt"
        fi
    done < "${work}/local_ids.txt"

    while IFS=$'\t' read -r existing _; do
        [[ -z "${existing}" ]] && continue
        if valid_item_name "${existing}" && filename_excluded "${existing}"; then
            printf '%s\n' "${existing}" >> "${work}/excluded_ids.txt"
        fi
    done < "${file_list}"

    sort -u -o "${work}/excluded_ids.txt" "${work}/excluded_ids.txt"
    sort -u -o "${work}/remote_ids.txt" "${work}/remote_ids.txt"

    download_count=$(awk 'NF { n++ } END { print n+0 }' "${work}/to_download.tsv")
    exclude_count=$(awk 'NF { n++ } END { print n+0 }' "${work}/excluded_ids.txt")

    if [[ "${download_count}" -gt 0 ]]; then
        print_info "Found ${download_count} items to download"
    fi
    if [[ "${exclude_count}" -gt 0 ]]; then
        print_info "Excluding ${exclude_count} item names"
    fi

    if [[ "${mirror_removals}" == "true" ]]; then
        if [[ "${SEARCH_NUM_FOUND}" -eq 0 ]]; then
            print_warning "The collection is empty. Local zips in this folder will be removed."
        else
            print_info "Fetched all ${SEARCH_NUM_FOUND} items. Zips for items that have left the collection will be removed."
        fi
    elif [[ "${SEARCH_COMPLETE}" != "true" ]]; then
        print_warning "Fetched ${SEARCH_FETCHED} of ${SEARCH_NUM_FOUND} items because of the row limit. Zips outside this fetch are kept. Excluded names already on disk are still removed. Pass at least ${SEARCH_NUM_FOUND} rows to mirror the whole collection."
    else
        print_warning "Some identifiers could not be handled safely, so zips for items that have left the collection will be kept."
    fi

    if ! perform_downloads "${work}/to_download.tsv" "${work}/success.tsv" "${work}/fail.tsv" "${download_count}"; then
        SYNC_WORK=""
        rm -rf "${work}"
        return 1
    fi

    if [[ "${mirror_removals}" == "true" ]]; then
        build_removal_list "${work}/remote_ids.txt" "${work}/local_ids.txt" "${work}/excluded_ids.txt" 1 > "${work}/removals.tsv"
    else
        build_removal_list "${work}/remote_ids.txt" "${work}/local_ids.txt" "${work}/excluded_ids.txt" 0 > "${work}/removals.tsv"
    fi

    removal_count=0
    removed_ok=0
    removal_failed=0
    while IFS=$'\t' read -r id reason; do
        [[ -z "${id}" ]] && continue
        if [[ ! -f "${id}.zip" ]]; then
            continue
        fi
        removal_count=$((removal_count + 1))
        if [[ "${DRY_RUN}" == "true" ]]; then
            print_info "Would remove ${id}.zip (${reason})"
        elif rm -f -- "${id}.zip"; then
            print_info "Removed ${id}.zip (${reason})"
            removed_ok=$((removed_ok + 1))
        else
            print_error "Failed to remove ${id}.zip"
            removal_failed=$((removal_failed + 1))
        fi
    done < "${work}/removals.tsv"

    success_count=$(awk 'NF { n++ } END { print n+0 }' "${work}/success.tsv")
    fail_count=$(awk 'NF { n++ } END { print n+0 }' "${work}/fail.tsv")
    if [[ "${DRY_RUN}" == "true" ]]; then
        success_count=0
        fail_count=0
    elif [[ $((success_count + fail_count)) -lt ${download_count} ]]; then
        fail_count=$((download_count - success_count))
    fi

    if [[ "${DRY_RUN}" != "true" ]]; then
        complete_flag=0
        if [[ "${mirror_removals}" == "true" ]]; then
            complete_flag=1
        fi
        write_file_list "${FILE_LIST_NAME}" \
            "${work}/excluded_ids.txt" \
            "${work}/fail.tsv" \
            "${work}/to_keep.tsv" \
            "${work}/success.tsv" \
            "${file_list}" \
            "${complete_flag}"
    fi

    print_info "Sync summary:"
    print_info "  Items fetched: ${SEARCH_FETCHED} of ${SEARCH_NUM_FOUND}"
    if [[ "${DRY_RUN}" == "true" ]]; then
        print_info "  Would download: ${download_count}"
        print_info "  Would remove: ${removal_count}"
    else
        print_success "  Downloaded: ${success_count}"
        if [[ ${fail_count} -gt 0 ]]; then
            print_warning "  Failed downloads: ${fail_count}"
        fi
        print_info "  Removed: ${removed_ok}"
        if [[ ${removal_failed} -gt 0 ]]; then
            print_warning "  Failed removals: ${removal_failed}"
        fi
    fi
    if [[ ${exclude_count} -gt 0 ]]; then
        print_info "  Excluded names: ${exclude_count}"
    fi
    if [[ "${DRY_RUN}" != "true" && ${download_count} -eq 0 && ${removal_count} -eq 0 && ${fail_count} -eq 0 && ${removal_failed} -eq 0 ]]; then
        if [[ "${mirror_removals}" == "true" ]]; then
            print_info "Collection is already in sync"
        elif [[ "${SEARCH_COMPLETE}" != "true" ]]; then
            print_info "No changes in this fetch"
        fi
    fi

    status=0
    if [[ ${fail_count} -gt 0 || ${removal_failed} -gt 0 ]]; then
        status=1
    fi

    SYNC_WORK=""
    rm -rf "${work}"
    return "${status}"
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

    # Fetch the catalog in this shell. A command substitution would discard
    # SEARCH_COMPLETE and the result counts. A failed fetch leaves the
    # collection folder unchanged.
    get_search_results "${collection}"

    archive_old_download_list

    if sync_files "${SEARCH_RESULTS_FILE}"; then
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
    START_DIR=$(pwd)

    print_info "${BOLD}${SCRIPT_NAME} v${SCRIPT_VERSION}${RESET} - Internet Archive Collection Sync"
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
    print_info "Concurrent downloads: ${JOBS}"
    if [[ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]]; then
        print_info "Excluding item names that match:"
        local exclude_pattern
        for exclude_pattern in "${EXCLUDE_PATTERNS[@]}"; do
            print_info "  ${exclude_pattern}"
            if [[ "${exclude_pattern}" == "*" ]]; then
                print_warning "This pattern matches every item name. Matching zips already on disk will be removed."
            fi
        done
    fi
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
