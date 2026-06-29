## MODIFIED Requirements

### Requirement: Action accepts an identifier input
The action SHALL accept an `identifier` input that labels the source of each review comment. If the input is omitted or empty, the action SHALL use `OCR` as the identifier. Every review comment body SHALL start with the line `Reviewer ID: [{identifier}]` followed by a newline and the OCR-generated content.

#### Scenario: Identifier provided
- **WHEN** the action is invoked with `identifier: OCR`
- **THEN** each review comment body starts with `Reviewer ID: [OCR]` on its own line
- **AND** the OCR-generated content begins on the next line

#### Scenario: Identifier omitted
- **WHEN** the action is invoked without an identifier
- **THEN** the action uses `OCR` as the identifier
- **AND** each review comment body starts with `Reviewer ID: [OCR]` on its own line
- **AND** the OCR-generated content begins on the next line

#### Scenario: Identifier explicitly empty
- **WHEN** the action is invoked with `identifier: ''`
- **THEN** the action uses `OCR` as the identifier
- **AND** each review comment body starts with `Reviewer ID: [OCR]` on its own line
- **AND** the OCR-generated content begins on the next line
