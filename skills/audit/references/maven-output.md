# Maven output volume

Read this when a project's builds or tests produce hundreds or thousands of
console lines, especially when the same build runs repeatedly in a session. The
general rule — redirect, then extract, preserving the exit status — is in
`SKILL.md` section 8; this file is for working out *why* a build is noisy and
what to change.

## 1. Establish a baseline

Do not run a full-project build to measure output. Pick one representative
module and one routine test command:

```bash
./mvnw -pl MODULE test > "$LOG" 2>&1
status=$?
wc -l "$LOG"
du -h "$LOG"
exit $status
```

Record total lines, approximate size, whether the output is mostly
informational or diagnostic, whether it repeats per module, and whether it
contains test detail, application logs or plugin diagnostics.

Do not copy sensitive log contents into the report.

## 2. Find the source

Don't assume Maven itself is responsible. Candidates, roughly in order of how
often they dominate:

- Application logging configuration (test profile)
- Spring Boot startup output, repeated per test context
- Hibernate SQL and bind-parameter logging
- Testcontainers diagnostics
- Surefire / Failsafe per-test output
- Compiler diagnostics and warnings
- Checkstyle, SpotBugs, JaCoCo reporting
- Maven lifecycle and plugin banners
- Custom plugins and shell scripts invoked during the build

Identify which one produces the largest share before recommending anything.

## 3. Judge quiet mode

```bash
./mvnw -q test
./mvnw -q -pl MODULE test
```

Check whether `-q` is actually enough. It silences Maven's own lifecycle
chatter, not application logging or plugin output. When most of the volume comes
from logging or plugins, say so rather than presenting `-q` as the fix.

## 4. Plugin verbosity

Review plugin configuration in the root and module POMs for verbose or debug
options, excessive compiler diagnostics, repeated banners, full test execution
detail, unnecessary or duplicated reporting, and repeated warnings.

Recommend configuration changes only where they keep the diagnostics useful.
Never recommend disabling test execution, coverage verification or static
analysis to reduce output.

## 5. Test logging levels

Inspect the test-scoped logging configuration (`src/test/resources/`) for a root
level of `DEBUG` or `TRACE`, verbose Spring framework logging, Hibernate SQL and
parameter logging, HTTP request/response dumps, Testcontainers messages, and
repeated startup banners.

Recommend targeted levels per logger. Keep `ERROR` and meaningful `WARN`
visible. Never suppress exceptions or failure diagnostics.

## 6. A wrapper script, if the noise is routine

Only when the same noisy command runs often enough to justify it. Example, not
an instruction to create it:

```bash
#!/usr/bin/env bash
set -u

MODULE="${1:?Module required}"
shift

LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/maven-build.XXXXXX.log")"

./mvnw -q -pl "$MODULE" "$@" > "$LOG_FILE" 2>&1
STATUS=$?

echo "Maven exit status: $STATUS"
echo "Log file: $LOG_FILE"

if [ "$STATUS" -eq 0 ]; then
  grep -E "Tests run:|BUILD SUCCESS" "$LOG_FILE" | tail -20
else
  echo "Build failed. Relevant diagnostics:"
  grep -n -E "ERROR|FAILURE|BUILD FAILURE|Tests run:" "$LOG_FILE" | tail -60
fi

exit "$STATUS"
```

Check that the exit status survives, failure detail stays reachable, temporary
logs are not committed, and test reports are still produced.

## 7. Compare before and after

| Metric | Before | After |
| :- | :- | :- |
| Output lines | measured | measured |
| Output size | measured | measured |
| Test results | measured | measured |
| Build exit status | recorded | recorded |
| Important warnings visible | yes/no | yes/no |
| Failure diagnostics available | yes/no | yes/no |

Fewer output lines is not the same as proportionally fewer model tokens. Measure
tokens where the assistant exposes them, and report only what was measured.

## Reporting a finding here

Output source, evidence, approximate volume, recommended change, expected
benefit, diagnostic risk, effort, and how to verify. Prioritize what reduces
*repeated* output without hurting troubleshooting.

## Never

- Run full reactor builds during the audit.
- Modify POM files or logging configuration.
- Suppress build failures, tests or quality checks.
- Discard logs before extracting the diagnostics.
- Claim token savings that were not measured.
