# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-12-26

Initial release.

### Added

- Form DSL for defining OpenRosa forms with metadata (`form_id`, `version`, `name`, `description_text`, `download_url`, `manifest_url`)
- Field types: `input`, `select1`, `select`, `boolean`, `range`, `upload`, `trigger`, `group`, `repeat`
- XForm XML generation from form definitions
- Form List API for listing available forms
- Manifest support for media files
- Submission parsing with support for XML data and file attachments
- Rack middleware for serving OpenRosa endpoints (`/formList`, `/forms/:id`, `/submission`)
- Per-form and global submission handlers
- Authentication hook support
- Ruby 3.2+ compatibility
