## 1. Create Test Repository

- [x] 1.1 Create a public repository named `gh-action-test-01` under the personal GitHub account
- [x] 1.2 Clone the repository locally

## 2. Initialize Main Branch

- [x] 2.1 Create `main.py` with a basic Python Hello World program
- [x] 2.2 Commit and push `main.py` to the `main` branch

## 3. Prepare Test Branches

- [x] 3.1 Create and push `test01` branch with problematic code (hardcoded password, unsafe `os.system`)
- [x] 3.2 Create and push `test02` branch with clean, type-annotated code

## 4. Configure Workflow

- [x] 4.1 Create `.github/workflows/ocr-review.yml` on `main`
- [x] 4.2 Commit and push the workflow file

## 5. Configure Secrets

- [x] 5.1 Add `OCR_LLM_URL` secret with value `https://openapi.coreshub.cn/v1`
- [x] 5.2 Add `OCR_LLM_AUTH_TOKEN` secret with the API key
- [x] 5.3 Add `OCR_LLM_MODEL` secret with value `DeepSeek-V4-Flash`
- [x] 5.4 Ensure workflow permissions allow reading secrets

## 6. Open Pull Requests

- [x] 6.1 Open a Pull Request from `test01` to `main`
- [x] 6.2 Open a Pull Request from `test02` to `main`

## 7. Verify Results

- [x] 7.1 Check that the workflow runs on `test01` PR and produces inline review comments
- [x] 7.2 Check that the workflow runs on `test02` PR and produces a summary comment
- [x] 7.3 Record any failures or unexpected behavior
- [x] 7.4 Update `add-ocr-review-action` tasks if the test reveals needed fixes
