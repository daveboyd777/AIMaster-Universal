#!/bin/bash

# AIMaster Universal - Test Runner
# Fixes Bats temp directory permissions issue

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Create writable temp directory for Bats
AIMASTER_BATS_TMPDIR="/tmp/aimaster-bats-$$"
mkdir -p "$AIMASTER_BATS_TMPDIR"

# Export temp directory for Bats
export BATS_TMPDIR="$AIMASTER_BATS_TMPDIR"
export TMPDIR="$AIMASTER_BATS_TMPDIR"

# Cleanup function
cleanup() {
    rm -rf "$AIMASTER_BATS_TMPDIR"
}
trap cleanup EXIT

echo -e "${BLUE}🧪 AIMaster Universal Test Runner${NC}"
echo -e "${BLUE}Using temp directory: $AIMASTER_BATS_TMPDIR${NC}"
echo ""

# Default to running all tests if no arguments provided
if [ $# -eq 0 ]; then
    TEST_TARGETS="tests/"
else
    TEST_TARGETS="$*"
fi

# Check if bats is installed
if ! command -v bats &> /dev/null; then
    echo -e "${RED}❌ Error: Bats is not installed${NC}"
    echo -e "${YELLOW}Install with: brew install bats-core${NC}"
    exit 1
fi

# Run tests
echo -e "${BLUE}Running tests: $TEST_TARGETS${NC}"
echo ""

# If running all tests, run each test file individually for better output
if [ "$TEST_TARGETS" = "tests/" ]; then
    echo -e "${BLUE}Running unit tests...${NC}"
    if ! bats --formatter pretty tests/unit/*.bats; then
        echo -e "${RED}❌ Unit tests failed${NC}"
        exit 1
    fi
    
    echo -e "${BLUE}Running integration tests...${NC}"
    if ! bats --formatter pretty tests/integration/*.bats; then
        echo -e "${RED}❌ Integration tests failed${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    # Run specific test targets
    if bats --formatter pretty "$TEST_TARGETS"; then
        echo ""
        echo -e "${GREEN}✅ All tests passed!${NC}"
        exit 0
    else
        echo ""
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
fi
