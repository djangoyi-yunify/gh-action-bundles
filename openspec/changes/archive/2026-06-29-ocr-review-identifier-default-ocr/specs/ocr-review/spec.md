## MODIFIED Requirements

### Requirement: Action accepts an identifier input
The action SHALL accept an `identifier` input that labels the source of each review comment. If the input is omitted or empty, the action SHALL use `OCR` as the identifier.

#### Scenario: Identifier provided
- **WHEN** the action is invoked with `identifier: OCR`
- **THEN** each review comment body is prefixed with `[OCR] `

#### Scenario: Identifier omitted
- **WHEN** the action is invoked without an identifier
- **THEN** the action uses `OCR` as the identifier
- **AND** each review comment body is prefixed with `[OCR] `

#### Scenario: Identifier explicitly empty
- **WHEN** the action is invoked with `identifier: ''`
- **THEN** the action uses `OCR` as the identifier
- **AND** each review comment body is prefixed with `[OCR] `

### Requirement: Identifier distinguishes multiple review actions
The action's example workflow SHALL demonstrate how to use different trigger keywords and identifiers for different review actions.

#### Scenario: Two review actions coexist
- **WHEN** one workflow uses `/ocr review` with `identifier: OCR` and another uses `/security review` with `identifier: Security`
- **THEN** comments from the first workflow are prefixed with `[OCR] ` and comments from the second are prefixed with `[Security] `
