echo "
To run an air-gapped, offline environment combining Kilo Code, Headroom, Caveman, RTK, and Ponytail, you cannot rely on public npm registries, remote git clones, or external marketplace calls at runtime. Everything must be pre-bundled and pointed exclusively to local proxy bindings.
1. Pre-fetch and Package Dependencies (On an Online Machine)

Before moving files into your air-gapped network via secure transport media (USB, internal mirror, or internal artifact registry), pull and cache all required packages:

    Download Node/Python CLI tooling packages:
    Bash

    npm pack @kilocode/cli @caveman-ai/cli headroom-ai
    pip download "headroom-ai[all]"

    Clone the local agent skills and rule repositories:
    Bash

    git clone https://github.com/JuliusBrussee/caveman.git
    git clone https://github.com/DietrichGebert/ponytail.git
    git clone https://github.com/rtk-ai/rtk.git

2. Deploy Locally Inside the Air-Gapped Environment

Transfer the tarballs, wheels, and repository folders to your offline node and install them completely offline:

    Install CLI components locally:
    Bash

    npm install -g ./kilocode-cli-*.tgz ./caveman-ai-*.tgz
    pip install --no-index --find-links=./wheels headroom-ai

    Install RTK offline via Cargo or local binary:
    Bash

    cargo install --path ./rtk
    rtk init -g

3. Wire the Fully Local Air-Gapped Stack

Configure your local infrastructure to run entirely offline with zero external network calls:

    Start Headroom locally as an offline proxy daemon:
    Bash

    headroom proxy --port 8787 --offline

    Point Kilo Code's endpoint to the local Headroom instance in your editor/extension configuration file:
    JSON

    {
      "kilocode.endpoint": "http://127.0.0.1:8787/v1"
    }

    Inject Ponytail and Caveman rules directly into your project root:
    Instead of using dynamic marketplace downloads, copy the cloned rules/skills folders directly into your project directory or global agent configuration path:

        Copy ponytail/ rules into your project's local rules directory (e.g., .cursor/rules/, .claudecode/skills/, or project root as an AGENTS.md context file).

        Initialize Caveman locally within the workspace directory using its local package manifest rather than npx.



"
