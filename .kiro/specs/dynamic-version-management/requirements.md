# Requirements Document

## Introduction

The current Docker build system has hardcoded version numbers in Dockerfile.base that become outdated when versions.env is updated. This creates version inconsistencies and requires manual synchronization between files. We need a dynamic version management system that automatically reads version numbers from versions.env during the Docker build process, ensuring consistency and eliminating manual version updates in Docker files.

## Requirements

### Requirement 1

**User Story:** As a developer, I want Docker builds to automatically use the latest version numbers from versions.env, so that I don't have to manually update multiple files when versions change.

#### Acceptance Criteria

1. WHEN a Docker build is initiated THEN the system SHALL read version numbers from versions.env file
2. WHEN versions.env is updated THEN subsequent Docker builds SHALL automatically use the new version numbers without manual Dockerfile changes
3. WHEN NODE_VERSION is changed in versions.env THEN Docker builds SHALL use the updated Node.js version
4. WHEN CLAUDE_CODE_VERSION is changed in versions.env THEN Docker builds SHALL use the updated Claude Code package version
5. WHEN CLAUDE_ROUTER_VERSION is changed in versions.env THEN Docker builds SHALL use the updated Claude Router package version

### Requirement 2

**User Story:** As a developer, I want the build system to validate that all required version variables exist in versions.env, so that builds fail early with clear error messages if configuration is incomplete.

#### Acceptance Criteria

1. WHEN versions.env is missing required version variables THEN the build SHALL fail with a descriptive error message
2. WHEN versions.env file is not found THEN the build SHALL fail with a clear error indicating the missing file
3. WHEN a version variable has an invalid format THEN the build SHALL fail with validation error details
4. IF versions.env contains all required variables THEN the build SHALL proceed normally

### Requirement 3

**User Story:** As a developer, I want the version management system to work with existing build scripts, so that current build workflows continue to function without breaking changes.

#### Acceptance Criteria

1. WHEN existing build scripts (build.sh, build-base.sh, build-full.sh) are executed THEN they SHALL continue to work with the new version management system
2. WHEN Docker Compose is used THEN it SHALL properly integrate with the dynamic version system
3. IF build scripts need modification THEN changes SHALL be minimal and backward compatible
4. WHEN the system is deployed THEN existing container orchestration SHALL work without modification

### Requirement 4

**User Story:** As a developer, I want clear documentation and examples of how the dynamic version system works, so that team members can understand and maintain the system.

#### Acceptance Criteria

1. WHEN the system is implemented THEN documentation SHALL explain how version management works
2. WHEN new team members join THEN they SHALL be able to understand the version system from documentation
3. WHEN troubleshooting version issues THEN documentation SHALL provide debugging guidance
4. IF version format changes are needed THEN documentation SHALL specify the required format