# How to run the staged refit

Written for someone who has not done this before. Nothing here requires you to
write code. You are doing three things: checking your setup works, granting the
authorization, and handing Codex the instructions. Codex writes and runs the
analysis.

Expect the whole thing to take a few minutes of your time and then a long time
of the computer's time.

---

## What each piece is

**PowerShell** is the Windows command line. You type a line, press Enter, and it
does something.

**R** is the statistics language your models are written in. `Rscript` is the
part that runs R code from the command line.

**renv** is a folder inside your repository holding the exact package versions
this project needs. It is already built, so there is nothing to install.

**Codex** is the AI in VS Code. It reads the prompt, writes new R scripts, runs
them, and pushes the results to GitHub.

**The authorization variable** is a note you leave in the command line saying "I,
a human, have decided to run this." Your own code checks for it and refuses to
run production without it.

---

## Step 1: Open a terminal in the right folder

In VS Code, open the repository folder if it is not already open:
**File → Open Folder →** `C:\Users\dingw\OneDrive\Documents\GitHub\herring-x-ebird-version-2`

Then open a terminal: **Terminal → New Terminal**, or press `Ctrl` + `` ` ``
(the backtick key, top-left of most keyboards).

A panel appears at the bottom. The prompt should end with
`herring-x-ebird-version-2>`. If it does not, you are in the wrong folder.

**Use this same terminal for everything below.** That matters, and Step 3
explains why.

---

## Step 2: Check R is working

Type this and press Enter:

```powershell
Rscript --version
```

**If you see** something like `Rscript (R) version 4.5.1` you are fine, go to
Step 3.

**If you see** `Rscript is not recognized...` then R is installed but Windows
cannot find it. Try this instead:

```powershell
& "C:\Program Files\R\R-4.5.1\bin\Rscript.exe" --version
```

If that works, R is installed but not on your PATH. Tell Codex, and it can work
around it. If it does not work, R may not be installed on this machine and the
version that built `renv/` was elsewhere. Stop and tell me.

---

## Step 3: Grant the authorization

This is the line that says a human decided to run this:

```powershell
$env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED = "through_2025_post_result_refinement_v1"
```

Nothing visible happens. Check it took:

```powershell
$env:POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED
```

It should print `through_2025_post_result_refinement_v1`.

**The thing to understand about this line.** It lives only in the terminal window
you typed it into. Close that window, or open a second terminal, and it is gone.
This is deliberate: it makes the authorization a decision you make for one
session rather than a permanent setting you forget about.

It also means **Codex must run in this same terminal session**, or it will not
see the variable and will correctly refuse to run. If Codex reports the gate is
unset, that is what happened; type the line again in whichever terminal Codex is
using.

---

## Step 4: Smoke-test the setup

Run the existing analysis in fixture mode. This does not touch your real results.
It runs a tiny synthetic version to prove R, the packages and the file paths all
work:

```powershell
.\scripts\run_post_stage4a_sog_event_study_v1.ps1 -Mode fixture
```

**If it completes** without an error in red, your setup is sound. Move on.

**If you see** a red message about "running scripts is disabled on this system",
Windows is blocking PowerShell scripts by default. Fix it for this session only:

```powershell
Set-ExecutionPolicy -Scope Process -Bypass
```

Then run the fixture line again.

**If you see** errors about missing files, check OneDrive. Files stored in
OneDrive can be "online only", showing a cloud icon in File Explorer rather than
a green tick. R cannot read those. Right-click the repository folder → **Always
keep on this device**, wait for it to finish downloading, then try again. This
is a common and confusing failure and it is worth checking first.

---

## Step 5: Hand the job to Codex

In the Codex chat panel in VS Code, paste this:

```
Read handoff/claude_session_2026-07-26/prompts/codex_staged_refit_prompt.md
and execute it in full.

The author has authorized this run. The scientific decision is recorded in
metadata/post_stage4a_staged_refit_authorization_v1.yml. Verify
POST_STAGE4A_SOG_EVENT_STUDY_AUTHORIZED in the current shell before production
and stop if it is absent. Do not set it yourself.

Work through the three stages in order and do not combine them. Report back
after Stage 1 before continuing to Stage 2.
```

That last sentence is the important one. It gives you a checkpoint after the
anchor change, which is the stage most likely to alter your headline numbers,
before another two stages of compute run on top of it.

---

## Step 6: What to expect, and what to watch for

This is a long run. The original analysis could not fit a single species within
an hour under the slower method, which is why a faster approximation is used.
You are now running three full sweeps of 49 species by two outcomes.

**Leave the machine on.** Closing VS Code or letting the laptop sleep will
interrupt it.

**Things that are normal and not errors:**

- Warnings about singular fits. The original run had these too and they are
  reported, not hidden.
- Warnings about convergence. Same.
- Long silences. Model fitting produces no output while it works.

**Things that mean stop and ask:**

- Codex says it is modifying anything in `outputs/post_stage4a_sog_event_study_v1/`.
  That folder holds the numbers behind your current manuscript and must stay
  untouched.
- Codex offers to set the authorization variable itself.
- Codex says it is dropping species that failed to converge.
- Any mention of 2026 records.

---

## Step 7: When it finishes

Codex pushes a branch and opens a pull request on GitHub. Do not merge it.

It also writes `STAGED_REFIT_REVIEW.md` at the top level of the repository. Open
that and read the first three sentences, which say whether your headline results
survived.

Then send it to me. Section 2 of that document lists every sentence in the
manuscript that the new numbers make wrong, and I will work through them against
v42.

**Authorizing the run does not authorize changing the paper.** v42 stays the
current draft until you have read the review and decided. That is your own rule,
from `docs/15_POST_STAGE4A_SOG_EVENT_STUDY.md`, and it is a good one.

---

## If something goes wrong

Copy the red error text and send it to me. Do not let Codex "fix" a failing
authorization check, a missing file, or a convergence failure by changing the
check. Those failures are usually telling you something true.
