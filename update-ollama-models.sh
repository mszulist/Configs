#!/bin/bash
# Generates ollama model list for opencode.jsonc
# Run: bash update-ollama-models.sh

# Models with native tool/function-calling support.
export TOOL_CALL_MODELS="deepseek-r1 deepseek-coder-v2 deepseek-coder qwen3.5 kimi-k2.7-code qwen2.5-coder mistral qwen2.5"

MODELS=$(curl -s http://localhost:11434/api/tags | python3 -c "
import sys, json, os
data = json.load(sys.stdin)
ok = set(os.environ['TOOL_CALL_MODELS'].split())
models = {}
for m in data.get('models', []):
    full = m['name']
    base = full.split(':')[0]
    models[full] = {'name': base.replace('-', ' ').title(), 'tool_call': base in ok}
print(json.dumps(models, indent=2))
" 2>/dev/null)

if [ -z "$MODELS" ]; then
  echo "ERROR: no models fetched. Is ollama running? (curl http://localhost:11434/api/tags)" >&2
  exit 1
fi

cat > /tmp/ollama_models.json << EOF
{
  "ollama": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "Ollama (local)",
    "options": {
      "baseURL": "http://localhost:11434/v1",
      "apiKey": "ollama"
    },
    "models": $MODELS
  }
}
EOF

echo "Generated model list. Copy the 'models' section into opencode.jsonc"
cat /tmp/ollama_models.json