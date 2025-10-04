# n8n Execution Modes

This document explains how the `N8N_EXECUTION_TYPE` environment variable affects n8n startup behavior, queue mode, and the web UI.

## Environment Variable

- `N8N_EXECUTION_TYPE`
  - Determines how n8n will run.
  - Acceptable values: `worker`, `webhook`, or unset (default).

---

## Behavior by Execution Type

| N8N_EXECUTION_TYPE | Command Executed | EXECUTIONS_MODE | N8N_DISABLE_UI | Description                                                                                                                                   |
| ------------------ | ---------------- | --------------- | -------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `worker`           | `n8n worker`     | `queue`         | `true`         | Runs n8n as a **worker** node. Workflows are processed via Redis queue. UI is disabled because this instance only processes jobs.             |
| `webhook`          | `n8n webhook`    | `queue`         | `true`         | Runs n8n as a **webhook** node. Receives incoming webhook calls and adds them to the queue. UI is disabled.                                   |
| unset (default)    | `n8n`            | unset           | `false`        | Runs n8n in **default single-instance mode**. Workflows execute in-process and the UI is enabled. Suitable for local or single-server setups. |

---

## Notes

- `EXECUTIONS_MODE=queue` is automatically set for `worker` and `webhook` modes.
  - Enables scaling using Redis-based queue processing.
- `N8N_DISABLE_UI` is automatically set to `true` in `worker` or `webhook` mode to disable the web interface.
- If `N8N_EXECUTION_TYPE` is not set, n8n runs normally with the web UI enabled and no queue.
- You can log or check the effective mode at startup using the startup script, which prints:

# Important

There are more settings and requirements if execution type is set as worker or webhook refer: https://docs.n8n.io/hosting/scaling/queue-mode/
