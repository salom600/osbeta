---
title: 🚧 Build failure on `{{ commit_sha }}`
assignees: [salom600]
labels: [build-failure, auto-fix, automated]
---

## Build failure

The **Build NexoraOS ISO** workflow failed.

| Field | Value |
|-------|-------|
| Commit | `{{ commit_sha }}` |
| Message | `{{ commit_msg }}` |
| Run URL | [{{ run_id }}]({{ run_url }}) |

## What happens next

The `auto-fix` workflow will pick up this issue automatically, parse the build log, and attempt a patch. If it can't fix the issue automatically it will post a comment with the root-cause analysis and a suggested fix.

If you want to retry the build now, click here:
[Re-run failed jobs]({{ run_url }})
