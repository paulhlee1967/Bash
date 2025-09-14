# Bash Scripts Collection

A collection of miscellaneous bash scripts developed on macOS for various automation and utility tasks.

## Scripts

### `sync-asimov.sh` ⭐ **ENHANCED**
A robust FTP mirroring script with comprehensive error handling, logging, and validation for downloading Apple II software from the Asimov FTP server.

**Features:**
- ✅ **FTP Mirroring** - Mirrors entire directories from FTP servers using `lftp`
- ✅ **Error Handling** - Comprehensive error handling with meaningful messages
- ✅ **Logging Support** - Optional file logging with timestamps
- ✅ **Dry Run Mode** - Preview what would be downloaded without actually downloading
- ✅ **Verbose Output** - Detailed debug information when needed
- ✅ **Input Validation** - Validates parameters and dependencies
- ✅ **Flexible Configuration** - Customizable remote host, directory, and local destination
- ✅ **Progress Tracking** - Real-time sync progress and status updates

**Usage:**
```bash
# Basic usage (requires local directory)
./sync-asimov.sh /local/destination

# With custom FTP server and directory
./sync-asimov.sh ftp.example.com /pub/files /local/path

# Advanced usage with options
./sync-asimov.sh -v -l ftp.example.com /pub/files /local/path
./sync-asimov.sh --dry-run ftp.example.com /pub/files /local/path
```

**Options:**
- `-h, --help`: Show help message and exit
- `-v, --verbose`: Enable verbose output
- `-q, --quiet`: Suppress non-error output
- `-d, --dry-run`: Show what would be done without actually doing it
- `-l, --log`: Enable logging to file

**Arguments:**
- `REMOTE_HOST`: FTP server hostname (default: ftp.apple.asimov.net)
- `REMOTE_DIR`: Remote directory path (default: /pub/apple_II)
- `LOCAL_DIR`: Local destination directory (required)

**Requirements:**
- `lftp` (install with `brew install lftp`)

### `synccollection.sh` ⭐ **ENHANCED**
A robust BASH script for downloading Internet Archive collections with resume capability and comprehensive error handling.

**Original .NET version by:** [malfunct](https://github.com/malfunct/SyncCollection)  
**BASH port by:** Paul Lee

**Features:**
- ✅ **Resume Capability** - Only downloads new or updated items
- ✅ **Progress Tracking** - Real-time download progress and statistics  
- ✅ **Error Handling** - Comprehensive error handling with meaningful messages
- ✅ **Dry Run Mode** - Preview what would be downloaded without actually downloading
- ✅ **Verbose Logging** - Detailed debug information when needed
- ✅ **Input Validation** - Validates collection names and row counts
- ✅ **Retry Logic** - Automatic retry for failed network requests
- ✅ **Cleanup** - Automatic cleanup of temporary files

**Usage:**
```bash
# Basic usage
./synccollection.sh                                    # Download default collection
./synccollection.sh softwarelibrary                    # Download specific collection
./synccollection.sh 50 apple_ii_library_4am           # Download first 50 items

# Advanced usage
./synccollection.sh --verbose 100 softwarelibrary     # Verbose mode
./synccollection.sh --dry-run 10 softwarelibrary      # Preview downloads
./synccollection.sh --help                            # Show help
./synccollection.sh --version                         # Show version
```

**Options:**
- `-h, --help`: Show help message and exit
- `-v, --verbose`: Enable verbose output
- `-n, --dry-run`: Show what would be downloaded without actually downloading
- `-V, --version`: Show version information and exit

**Arguments:**
- `rows`: Number of items to download (default: 30000, max: 100000)
- `collection`: Collection identifier (default: apple_ii_library_4am)

**Requirements:**
- `curl` (usually pre-installed on macOS)
- `jq` (install with `brew install jq`)

**Documentation:**
- All documentation is self-contained within the script
- Run `./synccollection.sh --help` for complete usage information

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd Bash
```

2. Make scripts executable:
```bash
chmod +x *.sh
```

3. Install required dependencies:
```bash
# For sync-asimov.sh
brew install lftp

# For synccollection.sh (enhanced version)
brew install jq
# curl is usually pre-installed on macOS
```

4. Run the scripts:
```bash
# sync-asimov.sh - Download Apple II software from Asimov FTP
./sync-asimov.sh /path/to/local/destination

# synccollection.sh - Download Internet Archive collections
./synccollection.sh
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Contributing

Feel free to submit issues, feature requests, or pull requests to improve these scripts.

## Notes

- Scripts are designed for macOS and may require modifications for other Unix-like systems
- All scripts include proper error handling and use `set -euo pipefail` for robust execution
- Paths in scripts may need adjustment based on your specific setup
