# CHANGELOG

## 2.0.2 (2026-01-28)

- **Chore** updated fp_logger dependency to latest version

## 2.0.1 (2026-01-26)

- **Chore** updated fp_logger dependency to latest version

## 2.0.0 (2026-01-25)

- **Client**:
  - Added AwsClientProvider to provide aws request among all image widgets
  - Added support for get upload url and upload to aws
  - Updated Request and Transformers to support upload and preview url
  - Improved error handling and reporting for upload failures
- **Loading Widget**:
  - Replaced `CircularProgressIndicator` with modern shimmer skeleton effect
  - Smooth gradient animation for better visual feedback
  - Respects shape and borderRadius properties
  - Properly handles parent constraints and default sizing
- **Image Loading**:
  - Enhanced performance and reliability
  - Improved caching mechanisms
- **Error Widget**:
  - Rewritten for consistency with loading widget
  - Same constraint-based sizing logic as loader
  - Respects shape and borderRadius properties
  - Consistent background styling

## 1.0.0 (2025-05-19)

- Initial release
