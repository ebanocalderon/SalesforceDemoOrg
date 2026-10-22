# AGENTS.md

Instructions for AI coding agents working in this repository (OpenCode, Codex, Cursor, Copilot, Claude Code, etc.). Humans should read [CONTRIBUTING.md](CONTRIBUTING.md), which is the authoritative source for the change and deploy process.

## Repository at a glance

- Salesforce DX **source-format** repository. Git is the source of truth for the metadata of the Developer Edition org `ebanoconsulting`.
- One package directory, `force-app/`. `sfdx-project.json` sets `sourceApiVersion` to **68.0**. There is no namespace and no managed or unlocked package.
- `main` is the deployable branch. A push/merge to `main` triggers `.github/workflows/deploy.yml`, which deploys changed metadata to the org.
- The repository is a broad baseline retrieved from the org. It contains thousands of object, layout, profile, and settings files. Treat retrieved metadata as fragile: change only what the task requires.

## Golden rules

1. **Never deploy to the org from a feature branch.** `sf project deploy start ... --dry-run` is allowed for validation. A real deploy happens only from `main` after an approved, merged PR, or through the GitHub Actions workflow. Never push directly to `main`.
2. **Never commit secrets or credentials.** This includes `Jira.txt`, `.env`, `SFDX_AUTH_URL`, `force://...` auth URLs, tokens, and passwords. Use GitHub Actions secrets for CI. If a secret is exposed, stop and report it so it can be rotated.
3. **Never run destructive operations without explicit human approval.** This covers deleting or renaming metadata, `destructiveChanges.xml`, `--ignore-errors`, `sf org delete`, `git reset --hard`, and force pushes.
4. **Keep diffs scoped.** Do not re-retrieve or reformat unrelated metadata. A full-org retrieve or a repo-wide Prettier run can produce thousands of unrelated changes.
5. **Do not invent validation results.** If `sf`, Node, npm, or org authentication is unavailable, say so. Never claim a deploy, test, or lint run passed without command output.
6. **Ask before changing permissions or security.** Profiles (`Admin`, `Standard`, etc.), permission sets, sharing rules, and org-wide defaults require explicit approval and a least-privilege review.
7. **Do not treat legacy code as a template.** The `*Copy` Apex classes and the `MyContactList` Aura component are legacy. Do not duplicate them or create new `*Copy` classes. New UI should be LWC; new Apex should follow a service/handler pattern with tests.

## Prerequisites and setup

- Node.js 22+ and npm (CI uses Node 22).
- Salesforce CLI v2 (`sf`) with an authenticated connection to the `ebanoconsulting` org.
- Git, plus VS Code with the Salesforce Extensions pack (recommended).
- Install dev tooling with `npm install`. The `prepare` script installs the Husky pre-commit hook.

Verify the target org before running any org command:

```powershell
sf org list
sf org display --target-org ebanoconsulting
```

If a tool is not on `PATH`, locate the existing installation. Do not install global tooling or authenticate to another org without asking.

## Commands

| Task | Command |
| --- | --- |
| Format changed files | `npx prettier --write <files>` |
| Format the whole repo (avoid unless intended) | `npm run prettier` |
| Verify formatting | `npm run prettier:verify` |
| Lint Aura and LWC JavaScript | `npm run lint` |
| Run LWC unit tests | `npm test` |
| Watch or debug LWC tests | `npm run test:unit:watch` / `npm run test:unit:debug` |
| LWC coverage | `npm run test:unit:coverage` |
| Retrieve a specific component | `sf project retrieve start --metadata <Type>:<Name> --target-org ebanoconsulting` |
| Validate a deploy | `sf project deploy start --source-dir force-app --target-org ebanoconsulting --dry-run` |
| Run Apex tests | `sf apex run test --target-org ebanoconsulting --test-level RunLocalTests --wait 30` |
| Run specific Apex tests | `sf apex run test --target-org ebanoconsulting --tests <Class>Test --wait 30` |
| Deploy (from `main` only, after approval) | `sf project deploy start --source-dir force-app --target-org ebanoconsulting` |

Important caveats:

- CI validates and deploys only the **changed** metadata. PR validation uses `--test-level NoTestRun` (new fields are not visible in the validation schema). On deploy from `main`, if the diff includes Apex (`.cls`/`.trigger`), tests run: `RunSpecifiedTests` for `*Test` classes in the diff, otherwise `RunLocalTests`. If no Apex changed, it uses `NoTestRun`. A deploy fails if the selected tests fail.
- CI excludes deleted files from the diff. Metadata deletions always require a manual, approved `destructiveChanges.xml` deploy.
- The pre-commit hook (`.husky/pre-commit` -> `lint-staged`) formats staged files, lints Aura/LWC JS, and runs related LWC Jest tests when applicable.
- Scratch-org configuration exists in `config/project-scratch-def.json`, but the current workflow targets the Developer Edition org. Do not create scratch orgs unless asked.

## Repository layout

```text
force-app/main/default/
  classes/            Apex classes and their *-meta.xml
  triggers/           Apex triggers
  flows/              Flow definitions
  objects/            Custom and standard objects, fields, list views, ...
  aura/               Legacy Aura components
  lwc/                LWC components (none yet)
  permissionsets/     Permission sets
  profiles/           Profiles (high-risk, retrieved baseline)
  layouts/            Page layouts
  flexipages/         Lightning pages
  settings/           Org settings
manifest/package.xml   Full baseline manifest; CI generates a per-change manifest
config/                Scratch org definition
scripts/apex/          Ad-hoc anonymous Apex (not deployed)
scripts/soql/          Ad-hoc SOQL (not deployed)
.github/workflows/     Validate and deploy pipeline
.husky/                Pre-commit hook
```

Domain hotspots:

- `Workshop__c` -> `triggers/WorkshopTrigger.trigger` -> `classes/AccessibilityProjectBilling.cls` -> `classes/BillingServiceProxy.cls` (billing callout through a `@future` method).
- `Wellness_Journey__c` -> `classes/WellnessJourneyRewardsBatch.cls` -> `classes/RewardsCalloutService.cls` (named credential `IntegrationSB__BalancedLiving`), tested by `RewardsCalloutServiceTest` with `RewardsCalloutServiceMock`.
- `MyContactList` Aura component + `MyContactListController.cls` (legacy; do not use as a pattern).

Custom objects in this org: `Accessibility_Project__c`, `Engagement_Evaluation__c`, `Wellness_Journey__c`, and `Workshop__c`.

## Change workflow

1. Start from an up-to-date `main` and create a branch:
   - `feature/<JIRA-KEY>-<short-description>` for new functionality.
   - `fix/<JIRA-KEY>-<short-description>` for fixes.
   - `chore/<short-description>` for docs, scripts, and configuration.
2. Make the smallest change that satisfies the request.
3. Validate locally (see "Definition of done").
4. Commit with the repository convention:
   - `<JIRA-KEY>: <imperative summary>` (for example, `SCRUM-5: add follow-up flow for Proposal opportunities`).
   - `chore: <summary>` for maintenance.
5. Push the branch and open a PR against `main`, using `.github/pull_request_template.md`. Include the Jira ticket, affected metadata, and dry-run evidence.
6. Do not merge, deploy, or push to `main` unless the user explicitly asks and the approval process has been followed.

Repository documentation and the PR template are in Spanish. Keep new prose in the language of the file being edited; keep code identifiers and commit subjects in English.

## Apex conventions

- Use API version **68.0** for new metadata. Existing classes use 60.0 or 66.0; do not mass-upgrade them.
- One trigger per object, kept thin. Put logic in handler/service classes; do not add SOQL or DML directly in a trigger. Refactor `WorkshopTrigger` only when the task requires it.
- Bulkify everything. Never put SOQL or DML inside loops. Use maps, sets, and collections; assume up to 200 records per trigger/batch invocation.
- Default to `with sharing` or `inherited sharing`. Use `without sharing` only with a justification comment and explicit approval.
- Enforce CRUD/FLS for user-facing queries with `WITH SECURITY_ENFORCED`, `Security.stripInaccessible`, or explicit checks.
- No hardcoded IDs, URLs, org-specific values, or credentials. Use Named Credentials (`callout:<Name>`), Custom Metadata, or Custom Labels.
- Set callout timeouts, handle non-2xx responses, and never make callouts from a trigger synchronously. Use `@future(callout=true)`, Queueable, or Batch with `Database.AllowsCallouts`.
- Test classes: `@isTest private class <Class>Test`. Use `Test.startTest()`/`Test.stopTest()`, create your own data, and avoid `SeeAllData=true`. Mock callouts with `Test.setMock(HttpCalloutMock.class, new <Class>Mock())`. Cover bulk behavior, error paths, and permissions.
- Match the existing `System.assert*` style in existing tests. New tests may use the `Assert` class, but do not rewrite tests solely to change assertion style.
- Name classes and methods in English using PascalCase/camelCase. Use the `Test` and `Mock` suffixes. Do not add new `*Copy` classes.

## Flow conventions

- Use API version **68.0** for new flows.
- Follow the existing naming style: `Title_Case_With_Underscores` (for example, `Seguimiento_Opportunity_Proposal`).
- Give each flow one clear purpose and a description. Add fault paths for DML and callout elements; surface failures instead of silently ignoring them.
- Do not hardcode record IDs or URLs. Use `$Record`, `$Permission`, Custom Labels, or Custom Metadata.
- Review the `<status>` element before deploying. Deploying an active flow creates a new version; do not activate, deactivate, or delete existing flows without approval.
- Prefer declarative Flow for simple automation. Use Apex for complex bulk logic, integrations, or logic that is difficult to test and maintain in Flow.

## Metadata and org conventions

- Retrieve narrowly with `--metadata <Type>:<Name>` or a targeted `--source-dir`. Avoid full-org retrieves and avoid `sf project retrieve start` over local changes you have not reviewed.
- If a change originates in the org UI, retrieve the exact component into the repo before committing. Do not let the org and repository drift.
- Custom fields belong in `objects/<Object>/fields/<Field>.field-meta.xml`; add them to the appropriate permission sets separately. Do not modify standard fields unless the task requires it.
- Do not hand-edit profiles, permission sets, sharing rules, or org-wide defaults to grant broad access. Prefer permission sets and least privilege. Changes to `Admin`, `Standard`, or other profiles need explicit approval.
- Do not edit `settings/`, `installedPackages/`, `standardValueSets/`, `manifest/package.xml`, or `.forceignore` unless the task is explicitly about them. Never remove `.forceignore` entries just to deploy tests or local files.
- Preserve XML structure and element order. Format only the files you touched; do not reorder or reformat retrieved metadata.
- For deletions, create `destructiveChanges.xml` (with an empty `package.xml`), document it in the PR, and deploy manually after approval. CI will not deploy deletions.
- The `manifest/package.xml` is a full baseline. CI generates its own per-change manifest in a temporary directory; do not regenerate the baseline manifest unless asked.

## Aura, LWC, and frontend tests

- Do not add new Aura components. `MyContactList` is legacy; new UI should be LWC under `force-app/main/default/lwc/<camelCaseName>/`.
- In LWC, use `@api`, `@wire`, and template refs. Do not use DOM globals such as `window` or `document`, and do not manipulate the DOM outside the lifecycle hooks.
- Use SLDS and accessible markup: labels, alt text, keyboard support, and sufficient contrast. Use Custom Labels for user-visible text.
- Put Jest tests in `__tests__/`. `.forceignore` excludes `**/__tests__/**`, so tests are not deployed. Run `npm run lint` and `npm test` when touching Aura or LWC JavaScript.

## Security

- Follow least privilege. Do not weaken sharing, CRUD/FLS, or validation rules just to make code or tests pass.
- Validate and escape external input. Use bind variables or an allowlist for dynamic SOQL. Never concatenate untrusted strings into SOQL.
- Use Named Credentials for callouts; never store secrets, certificates, or tokens in metadata or source.
- Treat org data as real even though this is a demo org. Do not mass-delete records or run data scripts without approval.

## Definition of done

Before considering a task complete:

- [ ] The diff contains only the metadata and code needed for the request.
- [ ] Changed files are formatted (`npx prettier --write <files>`) when Prettier is available.
- [ ] `npm run lint` passes for Aura/LWC changes, and `npm test` passes for LWC changes.
- [ ] Relevant Apex tests pass locally for Apex changes.
- [ ] A dry-run deploy passes when metadata changed. If it cannot run, report why instead of claiming success.
- [ ] `git status` and `git diff` are reviewed; no secrets, credentials, `node_modules`, `.sf`, or `.sfdx` files are included.
- [ ] The commit uses the repository convention and the branch follows the naming scheme.
- [ ] The final response lists changed files, validation commands and results, and anything skipped.

## Stop and ask

Ask the user before:

- Deleting, renaming, or deactivating metadata, or making destructive/data-impacting changes (field type changes, record deletion).
- Changing profiles, permission sets, sharing rules, org-wide defaults, or login/security settings.
- Deploying anything other than a dry run, or authenticating to a different org.
- Editing outside `force-app/` when the request is not about tooling, CI, or docs.
- Handling secrets, credentials, or anything that may expose customer data.
