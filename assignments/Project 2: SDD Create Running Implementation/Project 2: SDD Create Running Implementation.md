# Objective: Practice the implementation portion of test-first development.

In this part, we will finally use AI to develop the implementation. Ideally, this assignment needs a coding agent (Claude Code, Codex, Cursor, etc.).

## Tasks

### Task 1: Generate an Implementation Plan

The implementation work will be divided up by slices. A slice refers to a chunk of code across front and back end that implements a particular feature(s) in the spec. The implementation plan (plan.md) identifies the slices and provides a sequencing for implementation.

Read spec.md, architecture.md, contracts.md and test_plan.md. Then look at the test files and the code skeleton, but do not implement anything.

Run the test suite and show me the output. Group the failing tests by acceptance criterion ID.

Propose plan.md: an ordered list of implementation slices. For each slice give:

- Name: a short label.
- Goal: one sentence on the behavior it adds.
- Spec sources: the section numbers it covers.
- Criteria: the acceptance criterion IDs it completes.
- Tests that should turn green: the test names from the suite, exactly as written.
- Depends on: earlier slices it needs.
- Done when: the listed tests pass and no previously passing test fails.
- Status: not started.

Rules:

- Every acceptance criterion and every failing test appears in exactly one slice. At the end, list any criterion or test that fits no slice, and any function or route that no slice fills.
- Make slice 1 a thin path that works end to end: one route, one rule, the full request flow, even if it does almost nothing.
- Order by dependency.
- Put rules that interact in adjacent slices. Put the rules that are easiest to get subtly wrong in their own slices, so a failure points at one cause.
- Use only the modules, functions and routes in architecture.md and contracts.md. If a slice seems to need something new, list it under "Design questions" instead of adding it.
- If a test seems wrong, contradicts the spec, or is unclear, list it under "Test issues". Do not change any test.
- Do not write implementation code.

Finish with a one-line "Next action" naming the first slice and the first test to make pass.
If your project is not web-based, remove the parts pertaining to routes and 501 HTML code.

Review plan.md and check that the proposed slices actually make sense, i.e., can represent a task you'd put on the project backlog.

Make sure the slices cover every acceptance criterion and that no slice depends on a later slice.

### Task 2: Implement each slice

Before starting on a slice, create a new git branch for the slice. (In case you need to start over, you just need to delete the branch.) If multiple team members, each one create your own branch and implement your own slices.

Implement slice <N>, "<name>", from plan.md. Only this slice.

Make these tests pass: <test names from the slice>.

Rules:

- Fill in only the skeleton functions and routes listed for this slice. Follow the signatures in contracts.md exactly.
- Do not edit, delete, skip or loosen any test. If a test seems wrong, stop and tell me which test, what it expects, and which spec requirement disagrees. Do not work around it.
- Do not add modules, files, endpoints, fields, options or dependencies that spec.md, architecture.md and contracts.md do not list.
- If the spec is silent or ambiguous about something this slice needs, stop and ask. Give two options and the consequence of each. Do not guess.
- Do not hard-code values from the tests. Implement the general rule.
- Do not start the next slice.
- Do not run git commands that change history or switch branches. Tell me when a commit would be useful.

When you are done: list every file you changed, run the full test suite, and show me the output. State which tests of this slice still fail, and which tests that passed before now fail.
Fix the test failures. If manual debugging is not working, here's a prompt you can try:

> The test <name> fails: expected <X>, got <Y>.
> Explain the cause first, in a few sentences, referring to the spec requirement or acceptance criterion. Then propose the smallest change that fixes it. Do not edit the test. Do not change any other behavior.

The above prompt will generate a diff indicating what code to change. Perform a code review of the diff to check that it fixes the failure. Optionally, try this:

> Read spec.md, contracts.md, slice <N> of plan.md, and this diff: <paste the diff, or run git diff>.
>
> List:
> 1. Every behavior in the diff that the spec does not mention, including defaults, limits, and status codes.
> 2. Every rule in this slice that the diff does not enforce.
> 3. Any inputs where you would expect a different result from the one the code gives.
> 4. Any test changed, skipped or loosened.
> 5. Any special-casing of values that appear in the tests.
> 6. Anything that violates the dependency directions in architecture.md.
>
> Do not fix anything.

Triage the code review findings and filter out the ones you will not change.

Make the recommended changes. If you prefer, try the following prompt:

> A review of slice <N> found these problems. Fix only these, one at a time:
> 1. <finding, with the spec rule it breaks>
> 2. ...
>
> Rules:
> - Do not change any test. If a fix seems to need a test change, stop and tell me.
> - Do not change anything else, and do not start the next slice.
> - After each fix, run the full test suite and show me the output.
> Iterate until the tests pass.

When done, commit the code to the slice branch, push to the repository and do a pull request to merge.

Move on to the next slice.

## Minimum deliverable

For the scope of Project 2, implement at least 2 slices. Implementation completeness is not the target, just the experience of directing AI to create code from specs.

If your team has multiple members, implement 2 slices from each of your own version of spec.md and other md files.

## Submission

In your GitHub repo, update the existing md files as needed. Add plan.md at the top folder. The code should follow the folder structure expected by your chosen framework.

In the textbox, include:

- a link to the GitHub repository
- the output of running the tests (copy and paste from the actual runs),
- a short (1-5 minutes) video (use Yuja) demonstrating the running implementation, and
- a short writeup that describes:
  - additional changes and deviations from the Project 1 submission and why they were taken, and
  - (as applicable) additional ways that you used AI to help beyond the instructions given here.
