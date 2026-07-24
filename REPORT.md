# REPORT

## Environment setup

**Email out** — I use `msmtp` with `s-nail` configured to a test mailbox.

**A backup target** — I use a second VM reachable over SSH by key. The VM is configured with `PermitRootLogin no`, `PubkeyAuthentication yes`, `PasswordAuthentication no`.

**A Git repository** https://github.com/LeNgocBao145/bash-scripting-and-ops-automation-lab.git.

---

## Task 1 — Health-check with email alerting

**From Lab 1.** Write `health-check.sh` that inspects `web01` and emails **one** alert when — and only when — something is wrong.

**Acceptance criteria**

- On a healthy host the script prints nothing and sends no email.

  ![alt text](screenshots/task1-1.png)

- After you **lower one threshold** (e.g. `DISK_THRESHOLD=1`) **or kill the `python3` web endpoint**, the next run sends exactly **one** email naming the host and the offending metric(s).

  ![alt text](screenshots/task1-2.png)


- With the endpoint stopped, the other checks still run — the email lists all current problems, not just the first.

  ![alt text](screenshots/task1-3.png)

  ![alt text](screenshots/task1-4.png)
  
  As you can see the other checks like `check web-endpoint liveness` still run although the service that I monitor `myweb` which stops. And the email lists all current problems which are services and web endpoint.

---
