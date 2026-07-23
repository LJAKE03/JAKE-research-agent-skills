# Project Research Skills Model Routing

This project uses one unified research workflow. Users do not choose a mode, model,
or Agent.

| Internal role | Model | Reasoning | Responsibility |
|---|---|---|---|
| strategic | GPT-5.6 Sol | xhigh | Requirements, planning, methods, evidence synthesis, key scientific judgement, final response |
| support | GPT-5.6 Terra | medium | Bounded literature search, web verification, file scanning, extraction, evidence tables, provenance checks |
| economy | GPT-5.6 Luna | low | Prose, language, and formatting from a complete locked writing package |

Sol sends compact task cards rather than full history. Terra returns evidence packs;
Luna returns writing drafts. Workers do not delegate or contact one another.

Terra does not decide research direction, method, parameters, source reliability, or
final conclusions. Luna does not introduce facts, citations, formulas, causal claims,
or scientific judgement. Sol owns every key research decision and performs compact
semantic acceptance for publication, key parameters or methods, safety/high-cost
decisions, and final scientific conclusions.

The canonical machine-readable snapshot is `MODEL_ROUTING.json`. If
`routing-version.json` is not ready, run the project routing preflight before using
the workers.
