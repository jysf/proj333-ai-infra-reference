# CLAUDE.md — AI Infra Reference

## What this repo is
A public reference architecture proving production-grade AI infrastructure: an LLM
workload on Kubernetes with infrastructure-as-code, GitOps, observability, and cost
discipline. It is also a consulting credibility asset — code and docs must be legible
to a seed-stage AI founder, not only to an SRE.

## Stack
- Cloud: AWS (EKS). Documented swap target: GKE Autopilot.
- Substrate IaC: OpenTofu — VPC, EKS, IAM/IRSA, node groups.
- Platform layer: formae (Pkl) — in-cluster add-ons, drift capture, AI-modifiable abstractions.
- GitOps: Argo CD (app-of-apps).
- Inference: vLLM behind a thin FastAPI `/chat` gateway.
- Observability: kube-prometheus-stack; cost via OpenCost.
- Specs: OpenSpec. Task runner: just.
- Pin every tool and chart version at first use; record the pins in `docs/architecture.md`.

## How we work
- Every milestone is exactly one OpenSpec change. Run `/openspec:proposal` to frame it
  before writing code; read the relevant `openspec/specs/` entry for context first.
- Cycle for each change: Frame → Design → Build → Verify → Ship. Do not skip Verify.
- Acceptance criteria are written as GIVEN/WHEN/THEN scenarios. A milestone is done only
  when its scenarios pass against real output (kubectl / curl / Argo UI / Grafana),
  never on assertion alone.
- One PR-sized commit per milestone; update README and docs inside the same change.

## Safety and cost (stated as preferences)
- Prefer proposing a plan (plan mode) before any `tofu apply`, `formae` apply, or
  `kubectl` mutation.
- Always set a teardown TTL on any provisioned cluster; default 4 hours.
- Prefer the CPU / small-model path unless `gpu=true` is explicitly set.
- Keep projected monthly cost under $[SET_CEILING]; flag any change that would exceed it.
- Never hardcode secrets; source them from [SECRET_STORE]. Never commit credentials,
  kubeconfigs, or `.tfstate`.

## Commands
- `just up` / `just down` — provision / tear down.
- `just status` — cluster and workload state.
- `just cost` — current OpenCost / estimated spend.

## Conventions
- OpenTofu modules under `substrate/`, one concern per module.
- formae Pkl under `platform/`.
- GitOps manifests under `gitops/`; nothing reaches the cluster except through Argo
  once M3 lands.
