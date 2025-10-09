#!/bin/bash

# FinTrack Release Helper Script
# This script helps create tagged releases for automatic APK building

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a Git repository!"
        exit 1
    fi
}

# Function to check if working directory is clean
check_clean_working_dir() {
    if ! git diff-index --quiet HEAD --; then
        print_warning "Working directory is not clean!"
        echo "Uncommitted changes:"
        git status --porcelain
        echo ""
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Aborted by user"
            exit 1
        fi
    fi
}

# Function to get the current version from pubspec.yaml
get_current_version() {
    if [ -f pubspec.yaml ]; then
        grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//'
    else
        print_error "pubspec.yaml not found!"
        exit 1
    fi
}

# Function to update version in pubspec.yaml
update_version() {
    local new_version=$1
    local build_number=$2
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/^version: .*/version: ${new_version}+${build_number}/" pubspec.yaml
    else
        # Linux
        sed -i "s/^version: .*/version: ${new_version}+${build_number}/" pubspec.yaml
    fi
}

# Function to validate version format
validate_version() {
    local version=$1
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[0-9]+)?)?$ ]]; then
        print_error "Invalid version format: $version"
        print_error "Expected format: MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-PRERELEASE"
        print_error "Examples: 1.0.0, 1.2.3, 2.0.0-beta.1"
        exit 1
    fi
}

# Function to create and push tag
create_and_push_tag() {
    local tag=$1
    local message=$2
    
    print_status "Creating tag: $tag"
    git tag -a "$tag" -m "$message"
    
    print_status "Pushing tag to remote..."
    git push origin "$tag"
    
    print_success "Tag created and pushed successfully!"
    print_success "GitHub Actions will now build and create a release automatically."
    print_success "Check: https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]//' | sed 's/.git$//')/actions"
}

# Main script
main() {
    echo ""
    echo "🚀 FinTrack Release Helper"
    echo "=========================="
    echo ""
    
    check_git_repo
    check_clean_working_dir
    
    current_version=$(get_current_version)
    print_status "Current version: $current_version"
    
    # Get current build number
    current_build=$(grep '^version:' pubspec.yaml | sed 's/.*+//')
    if [ -z "$current_build" ]; then
        current_build="1"
    fi
    
    echo ""
    echo "Release Options:"
    echo "1. Patch release (bug fixes)"
    echo "2. Minor release (new features)"
    echo "3. Major release (breaking changes)"
    echo "4. Pre-release (alpha/beta/rc)"
    echo "5. Custom version"
    echo ""
    
    read -p "Select release type (1-5): " choice
    
    case $choice in
        1)
            # Patch release
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$major.$minor.$((patch + 1))"
            ;;
        2)
            # Minor release
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$major.$((minor + 1)).0"
            ;;
        3)
            # Major release
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$((major + 1)).0.0"
            ;;
        4)
            # Pre-release
            echo ""
            echo "Pre-release types:"
            echo "- alpha: Early development"
            echo "- beta: Feature complete, testing"
            echo "- rc: Release candidate"
            echo ""
            read -p "Enter pre-release type (alpha/beta/rc): " prerelease_type
            read -p "Enter pre-release number (1, 2, 3...): " prerelease_num
            
            IFS='.' read -r major minor patch <<< "$current_version"
            new_version="$major.$minor.$patch-$prerelease_type.$prerelease_num"
            ;;
        5)
            # Custom version
            echo ""
            read -p "Enter custom version (e.g., 1.2.3): " new_version
            ;;
        *)
            print_error "Invalid choice!"
            exit 1
            ;;
    esac
    
    validate_version "$new_version"
    
    echo ""
    print_status "New version: $new_version"
    
    # Increment build number
    new_build=$((current_build + 1))
    print_status "New build number: $new_build"
    
    echo ""
    read -p "Update pubspec.yaml and create release? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Aborted by user"
        exit 1
    fi
    
    # Update pubspec.yaml
    print_status "Updating pubspec.yaml..."
    update_version "$new_version" "$new_build"
    
    # Commit version change
    print_status "Committing version change..."
    git add pubspec.yaml
    git commit -m "chore: bump version to $new_version+$new_build"
    
    # Push commit
    print_status "Pushing commit..."
    git push origin $(git branch --show-current)
    
    # Create and push tag
    tag="v$new_version"
    message="Release $new_version

This release includes:
- Bug fixes and improvements
- Enhanced performance
- Updated dependencies

Built with Flutter 3.24+ and optimized for Android devices."
    
    create_and_push_tag "$tag" "$message"
    
    echo ""
    print_success "🎉 Release process completed!"
    print_success "Version: $new_version"
    print_success "Build: $new_build"
    print_success "Tag: $tag"
    echo ""
    print_status "Next steps:"
    echo "1. Monitor the GitHub Actions workflow"
    echo "2. Test the generated APK"
    echo "3. Update release notes if needed"
    echo "4. Announce the release"
    echo ""
}

# Help function
show_help() {
    echo "FinTrack Release Helper"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "This script helps create tagged releases for automatic APK building."
    echo "It will:"
    echo "1. Update the version in pubspec.yaml"
    echo "2. Commit the version change"
    echo "3. Create and push a git tag"
    echo "4. Trigger GitHub Actions to build and release APK"
    echo ""
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0            Interactive release creation"
    echo "  $0 --help     Show help"
    echo ""
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    "")
        main
        ;;
    *)
        print_error "Unknown option: $1"
        show_help
        exit 1
        ;;
esac