---
description: Simplify the code I just wrote
---

Use the Task tool to invoke the `code-simplifier:code-simplifier` agent to simplify my recent code changes.

The agent should focus on recently modified code (unstaged git changes) unless I specify particular files.

Pass this context to the agent:
- Target: $ARGUMENTS (if provided) or recent unstaged changes
- Be aggressive about simplification while preserving functionality
