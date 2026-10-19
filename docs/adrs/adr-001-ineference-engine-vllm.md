ADR: Selection of vLLM as the Standardized Production LLM Inference Engine
Context and Problem Statement

Our organization is scaling a production-grade infrastructure platform to serve Large Language Models (LLMs) across enterprise workloads. The target environment requires handling high concurrent multi-tenant request loads, ensuring predictable tail latencies (P99), and sustaining strict performance SLAs.

Concurrently, our product and engineering roadmaps demand unrestricted model diversity and rapid iteration, requiring day-zero access to newly released open-source architectures directly from the community without enduring compilation bottlenecks or hardware lock-in.

We must select a single primary inference engine across our production environment from the primary industry alternatives: Ollama, llama.cpp, vLLM, and TensorRT-LLM.
Decision Drivers

    Model Diversity & Agility: Immediate, day-one ingestion of cutting-edge open-source models (Safetensors, AWQ, GPTQ, FP8) straight from Hugging Face without awaiting vendor-specific operator compilation.

    Throughput & Concurrency Efficiency: Ability to scale multi-tenant request loads effectively under production traffic via continuous batching and low-fragmentation memory architectures.

    Operational Velocity & TCO: Elimination of lengthy Ahead-Of-Time (AOT) binary compilation pipelines to streamline CI/CD workflows, automated deployments, and weight hot-swapping.

    Hardware Interoperability: Viability across enterprise GPU accelerators (NVIDIA and AMD) without being locked into proprietary static compilation runtimes.

Considered Options
1. Ollama

    Pros: Unmatched local developer UX and zero-friction packaging via Modelfiles.

    Cons: Designed for local workstations and developer experimentation; lacks the enterprise-grade queue schedulers, telemetry, and multi-tenant scaling required for production.

2. llama.cpp (llama-server)

    Pros: Unrivaled hardware portability across CPUs, Apple Silicon, and edge environments using GGUF quantization.

    Cons: Concurrency management relies on fixed execution slots (-np), making it inefficient for dynamic auto-scaling under erratic enterprise cloud traffic.

3. vLLM

    Pros:

        Unrivaled Model Diversity: Direct ingestion of standard HuggingFace Safetensors, AWQ, GPTQ, and FP8 models across 400+ architectures with zero compilation delay.

        Production-Grade Architecture: Features PagedAttention (reducing KV-cache fragmentation waste to under 4%) and continuous batching to maximize GPU core saturation.

        Native OpenAI-compatible API servers, distributed tensor parallelism, and rich Prometheus telemetry.

    Cons:

        Yields a slightly lower raw throughput ceiling (roughly 8–15% lower) compared to heavily hyper-tuned, statically compiled NVIDIA engines under extreme, high-concurrency hyper-scale benchmarks.

4. TensorRT-LLM

    Pros: Delivers absolute peak raw throughput and lowest latency on NVIDIA hardware via aggressive kernel fusion.

    Cons:

        Rigid Compilation Pipeline: Requires generating pre-compiled binary engine files (.engine), introducing lengthy deployment lead times (often 30+ minutes per build).

        Severely restricted model agility: non-standard or newly announced architectures are blocked until NVIDIA updates operator support.

        Locked strictly to the NVIDIA hardware ecosystem.

Decision Outcome

Adopt vLLM as the sole standardized production inference engine across our enterprise LLM infrastructure.
Rationale:

    Model Diversity is a Core Strategic Imperative: Our product requirements dictate immediate adoption of novel models as they are released by the open-source community. vLLM eliminates the architectural lag imposed by compilation-dependent frameworks like TensorRT-LLM.

    Production Scalability: vLLM’s combination of PagedAttention and continuous batching easily satisfies our enterprise concurrency and throughput SLAs without sacrificing operational velocity.

    Operational Simplicity: Eliminating AOT compilation steps streamlines CI/CD pipelines, enabling instant weight hot-swapping, rapid evaluation of quantized variants (AWQ/FP8/INT8), and seamless blue-green deployments.

Consequences

    Positive:

        Engineering teams can pull, validate, and serve any standard HuggingFace model architecture within minutes of its public release.

        Simplified deployment manifests and reduced operational overhead by completely removing artifact compilation steps.

        Maintained flexibility to run across diverse GPU clusters (NVIDIA/AMD) without proprietary code lock-in.

    Negative / Trade-offs:

        Forfeiting the marginal 10–15% raw throughput and latency edge that heavily optimized, statically compiled TensorRT-LLM runtimes provide at massive scale.


