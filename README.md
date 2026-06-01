# AI Infrastructure Reference

Reference architecture for production AI infrastructure on Kubernetes, built around OpenTofu, formae, Argo CD, vLLM, and an OpenTelemetry-native observability pipeline.

> Status: under construction. See `phase0-spec.md` for the build plan.

## A real LLM workload on Kubernetes — not a toy

Proven in M4: vLLM behind a FastAPI /chat gateway serving real inference traffic on EKS.

## Infrastructure as code with no drift — the repo is reality

Proven in M1 (OpenTofu substrate) and M2 (formae drift capture): every cloud resource is declared in code and continuously reconciled.

## GitOps — every change is reviewable and reversible

Proven in M3: Argo CD app-of-apps pattern; nothing reaches the cluster except through a reviewed, version-controlled manifest.

## Instrumented for cost and performance, not just uptime

Proven in M5: OTel-native telemetry pipeline (kube-prometheus-stack) plus OpenCost for per-workload spend attribution.

## Cost discipline — spin up, prove it, tear down

Enforced throughout: TTL teardown on every cluster, CPU/small-model default path, and a hard $50/mo monthly ceiling.

## What this demonstrates / what I can do for you

Full narrative to be completed in M5 once all milestones are verified end-to-end.
