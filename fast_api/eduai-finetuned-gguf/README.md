---
tags:
- gguf
- llama.cpp
- unsloth

---

# eduai-finetuned-gguf : GGUF

This model was finetuned and converted to GGUF format using [Unsloth](https://github.com/unslothai/unsloth).

**Example usage**:
- For text only LLMs:    `llama-cli -hf zahir011/eduai-finetuned-gguf --jinja`
- For multimodal models: `llama-mtmd-cli -hf zahir011/eduai-finetuned-gguf --jinja`

## Available Model files:
- `gemma-3-1b-it.Q4_K_M.gguf`

## Ollama
An Ollama Modelfile is included for easy deployment.

## Note
The model's BOS token behavior was adjusted for GGUF compatibility.
This was trained 2x faster with [Unsloth](https://github.com/unslothai/unsloth)
[<img src="https://raw.githubusercontent.com/unslothai/unsloth/main/images/unsloth%20made%20with%20love.png" width="200"/>](https://github.com/unslothai/unsloth)
