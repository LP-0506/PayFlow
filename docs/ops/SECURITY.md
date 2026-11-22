# Security and owner setup

## Baseline

- Loopback-only local ports; no public Ingress or cloud resources.
- PostgreSQL application, administration and monitoring roles have separate generated credentials. The application role is not a superuser. Grafana also gets its own generated credential.
- Kafka plaintext and single-node storage are explicitly development-only. A real environment requires private networking, TLS, authentication, topic ACLs and replicated durable storage chosen with the owner.
- Java containers run as UID/GID 10001, drop capabilities, disallow privilege escalation, use read-only root filesystems and have bounded `/tmp` and memory. No Kubernetes service-account token is mounted.
- Kubernetes example Deployments do not grant application API permissions. The disposable namespace enforces restricted Pod Security. That enforcement is tested by an actual denied privileged Pod request.
- Health endpoint details stay hidden. Only health and Prometheus are proposed for exposure, inside the platform network. Do not expose management/admin APIs directly to the internet.
- GitHub Actions defaults to read-only repository permissions. The platform tests need no repository secrets or existing cluster credentials. No deployment uses `pull_request_target` to execute PR code with secrets.
- Trivy scans filesystem dependencies and actual application images when builds exist. Gitleaks scans history. Dependency review guards PRs once the owner enables its prerequisite. CodeQL waits for real application Java, not the runtime fixture.

Development infrastructure uses reviewed explicit tags plus registry digests, recorded in `ops/compose/images-lock.json`. Security CI scans those exact references. The Java runtime base follows its Java 21 patch tag and its built image is scanned in acceptance; real service releases must resolve and record their final image digests. A passing scan is a point-in-time check, not a guarantee against unknown vulnerabilities.

## Owner-only GitHub settings

Navin has collaborator push permission, not admin permission. These are not silently changed by commits:

1. Enable **Dependency graph** in repository security settings. Without it, Dependency review fails on PRs, including the existing Dependabot PRs. Do not bypass or weaken the check to merge them.
2. Protect `main` using a branch rule/ruleset, require agreed CI/security/platform checks and review, and disable force pushes. Existing planning docs describing protected main are a target until the owner applies the rule.
3. Select environment approval rules, registry/package ownership and deployment identity before connecting a real environment. Prefer short-lived workload identity where supported. No long-lived cloud key is required for the current local/disposable setup.
4. Revoke the temporary broad GitHub token after the agreed changes are finished. Do not revoke it mid-task unless access should stop immediately.

## What still needs a deployment choice

A production network policy depends on the actual database/broker addresses, DNS and observability destination. A blanket allow-all is not hardening; a speculative deny-all can break the application. Define egress allowlists, namespace isolation, ingress/TLS, broker ACLs, secret management, backups, storage class, availability requirements and resource budgets for the selected environment. None of those choices are falsely described as production-ready here.

## Dependency update policy

Updates are grouped weekly per active ecosystem, capped at one open version-update PR per ecosystem. Docker major upgrades are excluded: Java stays on the agreed 21 LTS runtime and PostgreSQL/Kafka/Grafana major migrations require their own compatibility and data-migration review. Security alerts still need review; do not assume version-update grouping is an incident response process. Maven/Gradle update entries must be added for the actual build directories when her code lands. Empty manifest entries were removed to stop predictable failed update jobs while no application exists. Dependency review and image scanning remain in place.

The Debian PostgreSQL image initially failed the strict scan because its bundled privilege helper carried old Go standard-library findings and a stock test certificate. The Alpine variant still contains the old helper, so switching variants did not clear the findings. This remains a tracked upstream finding; no ignore was added. Broker and dashboard versions are selected and tested independently, not merged as a blind major-upgrade batch.

See [current upstream image findings](SECURITY_FINDINGS.md). Functional acceptance, strict first-party security gates and third-party vulnerability reporting are separate results. A successful runtime test does not override a failed application or first-party image gate. Third-party infrastructure findings are report-only for this local development stack, as Navin selected on 2026-11-22; their reports remain visible and production acceptance is not implied.
