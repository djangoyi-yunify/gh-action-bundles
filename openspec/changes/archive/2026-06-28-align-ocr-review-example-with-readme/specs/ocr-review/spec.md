## ADDED Requirements

### Requirement: Bundled example workflow matches the README-recommended default pattern
The bundled `examples/ocr-review.yml` SHALL use the same event model, access controls, and trigger phrase as the default workflow shown in `actions/ocr-review/README.md`.

#### Scenario: Example uses pull_request event for auto-review
- **WHEN** a consumer opens `examples/ocr-review.yml`
- **THEN** the workflow triggers on `pull_request`, not `pull_request_target`

#### Scenario: Example gates auto-review by author association
- **WHEN** the workflow is triggered by a `pull_request` event
- **THEN** it only runs when `github.event.pull_request.author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`

#### Scenario: Example uses the documented manual trigger phrase
- **WHEN** a consumer reads the example workflow
- **THEN** the `issue_comment` trigger only runs for comments starting with `/ocr review`

#### Scenario: Example gates manual trigger by author association
- **WHEN** the workflow is triggered by an `issue_comment` event
- **THEN** it only runs when `github.event.comment.author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`
