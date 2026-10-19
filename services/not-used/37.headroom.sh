headroom proxy --port 8787  >& $RUST_AGENT_INFRA_LOG_DIR/headroom.log &


echo "

Configure Kilo Code to Route Through Headroom

Point Kilo Code's API base endpoint to your running Headroom proxy instead of hitting the raw provider directly:

    Open your Kilo Code configuration/settings.

    Set the custom Base URL (or endpoint) to:
    Plaintext

    http://127.0.0.1:8787/v1

    HEALTH : http://localhost:8787/health

3. Layer Caveman into Your Kilo Code Session

With your traffic now flowing through Headroom's compression engine, initialize Caveman inside your active Kilo Code project or prompt scope to trim output bloat (dropping pleasantries and restated code):
Bash

npx skills add JuliusBrussee/caveman

Alternatively, if you are using Caveman's command wrapper alongside Kilo, activate its mode so that output-side tokens are shrunk simultaneously alongside Headroom's input-side compression:
Bash

caveman kilo

This architecture ensures tool outputs, files, and RAG chunks are shrunk by Headroom before hitting the model, while Caveman ensures the assistant responds back with maximum terseness.:

"
