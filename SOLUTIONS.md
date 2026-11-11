# 🔑 Answer key (for you, keep it off screen)

| Glitch | Symptom | Root cause | Correct fix |
|---|---|---|---|
| 1. Bad config | Site down · pod `CrashLoopBackOff` · log: `FATAL: APP_PORT environment variable is not set` | Env var renamed to `APP_PROT` (typo) | `kubectl set env deployment/coffee-shop -n coffee APP_PORT=8080 APP_PROT-` → site back, showing **v2** |
| 2. Bad image | Site down · pod `ImagePullBackOff` / `ErrImagePull` | Image tag typo `python:3.12-alpne` | `kubectl set image deployment/coffee-shop -n coffee web=python:3.12-alpine` |
| 3. Memory | Site down · `OOMKilled` → `CrashLoopBackOff` · log stops at `Warming menu cache: 300 MB` | 300 MB cache, 128Mi memory limit | `kubectl set resources deployment/coffee-shop -n coffee -c web --limits=memory=512Mi` |

A rollback (`kubectl rollout undo deployment/coffee-shop -n coffee`) also brings the site back,
but on the **old** version. That's fine; it's what you'd do in a real outage if the fix isn't obvious.

Reset to healthy v1 at any time: `./scripts/reset.sh`
