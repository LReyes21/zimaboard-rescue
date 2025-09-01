#!/bin/bash
# verify-setup.sh - Verification script for ZimaBoard Rescue Template
# Tests all dependencies and functionality

# Note: Don't use 'set -e' because we want to continue testing even if some tests fail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to print colored output
print_test() {
    ((TESTS_TOTAL++))
    echo -n -e "${BLUE}[TEST $TESTS_TOTAL]${NC} $1 ... "
}

print_pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}PASS${NC}"
}

print_fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}FAIL${NC}"
    if [[ -n "$1" ]]; then
        echo -e "  ${RED}Error:${NC} $1"
    fi
}

print_skip() {
    echo -e "${YELLOW}SKIP${NC}"
    if [[ -n "$1" ]]; then
        echo -e "  ${YELLOW}Reason:${NC} $1"
    fi
}

# Test functions
test_command_exists() {
    local cmd=$1
    local name=$2
    print_test "Command '$name' exists"
    if command -v "$cmd" &> /dev/null; then
        print_pass
        return 0
    else
        print_fail "Command '$cmd' not found"
        return 1
    fi
}

test_python_module() {
    local module=$1
    print_test "Python module '$module'"
    if python3 -c "import $module" 2>/dev/null; then
        print_pass
        return 0
    else
        print_fail "Cannot import Python module '$module'"
        return 1
    fi
}

test_script_executable() {
    local script=$1
    local name=$2
    print_test "Script '$name' is executable"
    if [[ -x "$script" ]]; then
        print_pass
        return 0
    else
        print_fail "Script '$script' is not executable"
        return 1
    fi
}

test_script_runs() {
    local script=$1
    local args=$2
    local name=$3
    print_test "Script '$name' runs without error"
    if [[ -n "$args" ]]; then
        if $script "$args" &>/dev/null; then
            print_pass
            return 0
        else
            print_fail "Script '$script $args' failed to run"
            return 1
        fi
    else
        if $script &>/dev/null; then
            print_pass
            return 0
        else
            print_fail "Script '$script' failed to run"
            return 1
        fi
    fi
}

test_directory_exists() {
    local dir=$1
    print_test "Directory '$dir' exists"
    if [[ -d "$dir" ]]; then
        print_pass
        return 0
    else
        print_fail "Directory '$dir' does not exist"
        return 1
    fi
}

test_file_exists() {
    local file=$1
    print_test "File '$file' exists"
    if [[ -f "$file" ]]; then
        print_pass
        return 0
    else
        print_fail "File '$file' does not exist"
        return 1
    fi
}

test_network_capability() {
    local cmd=$1
    local name=$2
    print_test "Network capability '$name'"
    if $cmd &>/dev/null; then
        print_pass
        return 0
    else
        print_fail "Network test '$cmd' failed"
        return 1
    fi
}

# Main verification
main() {
    echo "======================================"
    echo "ZimaBoard Rescue Template Verification"
    echo "======================================"
    echo
    
    # Test system commands
    echo "Testing System Commands:"
    echo "------------------------"
    test_command_exists "python3" "Python 3"
    test_command_exists "pip3" "pip3"
    test_command_exists "git" "Git"
    test_command_exists "curl" "curl"
    test_command_exists "shellcheck" "ShellCheck"
    test_command_exists "dnsmasq" "dnsmasq"
    test_command_exists "tcpdump" "tcpdump"
    test_command_exists "arping" "arping"
    test_command_exists "nmap" "Nmap"
    test_command_exists "ethtool" "ethtool"
    test_command_exists "ping" "ping"
    echo
    
    # Test Python modules
    echo "Testing Python Modules:"
    echo "-----------------------"
    test_python_module "sqlite3"
    test_python_module "os"
    test_python_module "sys"
    test_python_module "argparse"
    test_python_module "datetime"
    echo
    
    # Test Python tools
    echo "Testing Python Tools:"
    echo "---------------------"
    print_test "flake8 command"
    if python3 -m flake8 --version &>/dev/null; then
        print_pass
    else
        print_fail "flake8 not working"
    fi
    echo
    
    # Test project structure
    echo "Testing Project Structure:"
    echo "--------------------------"
    test_directory_exists "scripts"
    test_directory_exists "data"
    test_directory_exists "diagnostics"
    test_directory_exists "docs"
    test_directory_exists "template"
    echo
    
    # Test critical files
    echo "Testing Critical Files:"
    echo "-----------------------"
    test_file_exists "README.md"
    test_file_exists "PLAYBOOK.md"
    test_file_exists "metadata.yml"
    test_file_exists "scripts/add_record.py"
    test_file_exists "scripts/generate_dashboard.py"
    test_file_exists "scripts/rescue_dhcp.sh"
    test_file_exists "scripts/collect_diagnostics.sh"
    test_file_exists "scripts/fix_boot_order.sh"
    echo
    
    # Test script permissions
    echo "Testing Script Permissions:"
    echo "---------------------------"
    test_script_executable "scripts/rescue_dhcp.sh" "rescue_dhcp.sh"
    test_script_executable "scripts/collect_diagnostics.sh" "collect_diagnostics.sh"
    test_script_executable "scripts/fix_boot_order.sh" "fix_boot_order.sh"
    test_script_executable "scripts/setup-prerequisites.sh" "setup-prerequisites.sh"
    test_script_executable "scripts/verify-setup.sh" "verify-setup.sh"
    echo
    
    # Test script functionality
    echo "Testing Script Functionality:"
    echo "-----------------------------"
    test_script_runs "python3 scripts/add_record.py" "--help" "add_record.py --help"
    test_script_runs "python3 scripts/generate_dashboard.py" "" "generate_dashboard.py"
    test_script_runs "shellcheck" "scripts/rescue_dhcp.sh" "shellcheck on rescue_dhcp.sh"
    test_script_runs "python3 -m flake8" "scripts/add_record.py" "flake8 on add_record.py"
    echo
    
    # Test network tools (basic functionality)
    echo "Testing Network Tools:"
    echo "----------------------"
    test_network_capability "ping -c 1 -W 1 127.0.0.1" "ping localhost"
    
    print_test "ethtool help"
    if ethtool --help &>/dev/null; then
        print_pass
    else
        print_fail "ethtool help failed"
    fi
    
    print_test "nmap version"
    if nmap --version &>/dev/null; then
        print_pass
    else
        print_fail "nmap version failed"
    fi
    
    print_test "tcpdump version"
    if tcpdump --version &>/dev/null; then
        print_pass
    else
        print_fail "tcpdump version failed"
    fi
    
    print_test "dnsmasq version"
    if dnsmasq --version &>/dev/null; then
        print_pass
    else
        print_fail "dnsmasq version failed"
    fi
    echo
    
    # Test dashboard generation
    echo "Testing Dashboard Generation:"
    echo "-----------------------------"
    print_test "Dashboard HTML generation"
    if python3 scripts/generate_dashboard.py &>/dev/null; then
        if [[ -f "dashboard/index.html" ]]; then
            print_pass
        else
            print_fail "dashboard/index.html was not created"
        fi
    else
        print_fail "Dashboard generation script failed"
    fi
    
    print_test "Dashboard HTML validity"
    if [[ -f "dashboard/index.html" ]]; then
        if grep -q "<html" "dashboard/index.html" && grep -q "</html>" "dashboard/index.html"; then
            print_pass
        else
            print_fail "Generated HTML appears invalid"
        fi
    else
        print_skip "No dashboard HTML to test"
    fi
    echo
    
    # Summary
    echo "======================================"
    echo "VERIFICATION SUMMARY"
    echo "======================================"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo "Total tests:  $TESTS_TOTAL"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
        echo -e "${GREEN}Your ZimaBoard Rescue Template is ready for use.${NC}"
        echo
        echo "Next steps:"
        echo "  1. Edit metadata.yml with your device information"
        echo "  2. Create your first record: python3 scripts/add_record.py --help"
        echo "  3. Generate dashboard: python3 scripts/generate_dashboard.py"
        echo "  4. For emergencies, see: PLAYBOOK.md"
        echo
        return 0
    else
        echo -e "${RED}✗ $TESTS_FAILED TEST(S) FAILED${NC}"
        echo -e "${RED}Please address the failed tests before using the template.${NC}"
        echo
        echo "For help:"
        echo "  • Check README.md for setup instructions"
        echo "  • Run: sudo scripts/setup-prerequisites.sh"
        echo "  • Check GitHub issues: https://github.com/LReyes21/zimaboard-rescue/issues"
        echo
        return 1
    fi
}

# Run main function
main "$@"
