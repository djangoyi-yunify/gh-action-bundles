## ADDED Requirements

### Requirement: Action silently ignores empty or unparseable OCR output

The action SHALL NOT post any PR comment when the OCR CLI succeeds but produces no parseable output, and the action step SHALL succeed.

#### Scenario: OCR result file is empty
- **WHEN** the OCR CLI exits successfully and `/tmp/ocr-result.json` is empty or missing
- **THEN** the action does not post any PR comment
- **AND** the action outputs `review-count`, `inline-count`, `summary-count`, and `failed-count` as `0`
- **AND** the action step succeeds

#### Scenario: OCR result file is unparseable
- **WHEN** the OCR CLI exits successfully and `/tmp/ocr-result.json` contains content that cannot be parsed as OCR JSON output
- **THEN** the action does not post any PR comment
- **AND** the action outputs `review-count`, `inline-count`, `summary-count`, and `failed-count` as `0`
- **AND** the action step succeeds
