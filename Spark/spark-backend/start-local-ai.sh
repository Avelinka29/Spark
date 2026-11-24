#!/bin/sh
set -eu

# Run in a separate terminal; stop with Ctrl-C. CPU mode also works when Metal is unavailable.
ollama_binary="${OLLAMA_BINARY:-$HOME/Applications/Ollama.app/Contents/Resources/ollama}"
if [ ! -x "$ollama_binary" ]; then
    echo "Ollama is not installed at $ollama_binary. Set OLLAMA_BINARY to its executable." >&2
    exit 1
fi
if curl -fsS --max-time 2 http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    echo "Ollama is already running on port 11434."
    exit 0
fi
export LLAMA_ARG_DEVICE=none
export LLAMA_ARG_N_GPU_LAYERS=0
exec "$ollama_binary" serve
