# Upstream image findings

Status: **known upstream findings, report-only for local development**. Navin selected this policy on 2026-11-22. Application code, repository secrets/dependencies and our own built images remain strictly gated. Do not describe the platform as production-ready or the upstream images as vulnerability-free.

The functional Compose and disposable Kubernetes gates pass. Trivy scans of the exact locked upstream images also find fixed HIGH/CRITICAL issues. Digest pinning makes the evidence repeatable; it does not make an image vulnerability-free.

| Image | Findings in the checked digest | Next safe step |
|---|---|---|
| PostgreSQL 17.12 Alpine | `libxml2` patch available; bundled `gosu` built with old Go standard library | A reviewed patched derivative or a corrected upstream image. Switching from Debian to Alpine alone did not remove gosu. |
| Kafka 4.4.0 | Alpine packages and lz4/snappy Java compression dependencies have fixes | Apply reviewed OS/library patch versions and re-run real Kafka round trips with each compression codec, or consume a patched upstream release. |
| Prometheus 3.16.0 | `golang.org/x/net` 0.61.0 is flagged; 0.62.0 fixes CVE-2026-78661 | Updated upstream build or an explicitly maintained rebuild with the patched dependency. |
| Grafana 12.4.15 | Embedded Tempo module triggers CVE-2026-21728 and CVE-2026-28377 | Review applicability before proposing any narrow exception. These advisories concern Tempo server query/config behavior, not a demonstrated Grafana exploit. No exception is currently applied. |
| Postgres exporter 0.21.1 | No fixed HIGH/CRITICAL or secret findings in this scan | Keep scanning the digest as the advisory database changes. |

The report-only job scans every locked third-party reference and keeps a sanitized JSON findings artifact. Known vulnerabilities and stock-image secret findings do not fail the workflow. A scanner/download error still fails collection rather than being presented as a clean scan. It does not stop reporting after the first image. Raw secret matches and image file contents are not included in that artifact.

Vendor sources for the two Tempo findings:

- https://grafana.com/security/security-advisories/cve-2026-21728/
- https://grafana.com/security/security-advisories/cve-2026-28377/

The full image references and their registry provenance are in `ops/compose/images-lock.json`. Current per-commit results and package/fix versions are in the Security workflow's sanitized artifact. Scanner results are a point-in-time report, not proof every flagged code path is reachable. No blanket ignore, skipped vulnerability class or reduced severity threshold hides these findings. The accepted difference is explicit reporting instead of blocking on third-party infrastructure images.

A real deployment remains blocked on a fresh security review, external environment setup and the actual Java service contracts. This local-only development policy is not production approval. Do not carry report-only acceptance into a real release without the owner reviewing the deployment and risk.
