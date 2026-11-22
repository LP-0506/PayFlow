# Security and owner setup

## Baseline

- Loopback-only local ports; no public Ingress or cloud resources.
- PostgreSQL and Grafana credentials are generated locally, not shared defaults.
- Kafka plaintext and single-node storage are explicitly development-only. A real environment requires private networking, TLS, authentication, topic ACLs and replicated durable storage chosen with the owner.
- Java containers run as UID/GID 10001, drop capabilities, disallow privilege escalation, use read-only root filesystems and have bounded `/tmp` and memory. No Kubernetes service-account token is mounted.
- Kubernetes example Deployments do not grant application API permissions. The disposable namespace enforces restricted Pod Security. That enforcement is tested by an actual denied privileged Pod request.
- Health endpoint details stay hidden. Only health and Prometheus are proposed for exposure, inside the platform network. Do not expose management/admin APIs directly to the internet.
- GitHub Actions defaults to read-only repository permissions. The platform tests need no repository secrets or existing cluster credentials. No deployment uses `pull_request_target` to execute PR code with secrets.
- Trivy scans filesystem dependencies and actual application images when builds exist. Gitleaks scans history. Dependency review guards PRs once the owner enables its prerequisite. CodeQL waits for real application Java, not the runtime fixture.

Images use explicit version tags in the development stack. Tags can move. Resolve and pin reviewed registry digests for releases, keep their provenance and scan the exact release images. A passing scan is a point-in-time check, not a guarantee against unknown vulnerabilities.

## Owner-only GitHub settings

Navin has collaborator push permission, not admin permission. These are not silently changed by commits:

1. Enable **Dependency graph** in repository security settings. Without it, Dependency review fails on PRs, including the existing Dependabot PRs. Do not bypass or weaken the check to merge them.
2. Protect `main` using a branch rule/ruleset, require agreed CI/security/platform checks and review, and disable force pushes. Existing planning docs describing protected main are a target until the owner applies the rule.
3. Select environment approval rules, registry/package ownership and deployment identity before connecting a real environment. Prefer short-lived workload identity where supported. No long-lived cloud key is required for the current local/disposable setup.
4. Revoke the temporary broad GitHub token after the agreed changes are finished. Do not revoke it mid-task unless access should stop immediately.

## What still needs a deployment choice

A production network policy depends on the actual database/broker addresses, DNS and observability destination. A blanket allow-all is not hardening; a speculative deny-all can break the application. Define egress allowlists, namespace isolation, ingress/TLS, broker ACLs, secret management, backups, storage class, availability requirements and resource budgets for the selected environment. None of those choices are falsely described as production-ready here.
