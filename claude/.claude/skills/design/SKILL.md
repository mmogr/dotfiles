---
name: design
description: Investigate one numbered issue with its owner, agree a solution, and post it on the issue once approved.
argument-hint: <issue number>
disable-model-invocation: true
---

Investigate issue $ARGUMENTS in this repository and agree a solution with me. Change no code. If no issue number was given, ask which issue and stop.

Read the repository's contributing guide first (`CONTRIBUTING.md`, or whatever the repository has in its place). What it says a change must look like shapes the solution.

## Investigate

1. Read the issue, its comments, and the issues and pull requests it names. An issue describes the code as it was on the day it was written: check each thing it says against the current default branch, and say what has moved.
2. Find out what the code does today: where it is, how each surface reaches it, what tests cover it, and what the history says about why it is that way.
3. Size the reading to the issue. A small one you read yourself. One that reaches across several parts of the code is split into independent questions and researched in parallel, as a workflow of research agents, and their answers are checked against the code before they are relied on.
4. Stay read-only: no edits, no branch, no worktree. Running the existing tests and other read-only commands is fine. Never touch the owner's real data or a service already running on the machine.

## Decide with me

- Bring each real choice to me as a question: what the code does, the options, what each costs, and a recommendation. Ask as the choices come up, not all at the end.
- Do not ask what the code or the contributing guide already answers.
- Say plainly what could not be settled by reading, and what would settle it.

## The solution

When the choices are made, show me the solution in full, here and not on the issue: the cause, the change, what done means, the test that will fail first, the pull requests in order, what is left out, and what could go wrong.

## What is posted

Nothing is posted until I have read the exact text and said yes.

The posted text is a comment on the issue, under my account, and it is short: a few plain paragraphs saying what is wrong or missing, what will change, and the pull requests in order. Ordinary sentences. No headings, no lists of files, no labels or tags, nothing about how it was worked out, and no credits of any kind. The detail stays here.

When the note is posted, offer the labels the repository requires of an issue and this one still lacks, a size and a priority among them, and set each one I agree to.

Do not edit the issue's description or state, or any other label.
