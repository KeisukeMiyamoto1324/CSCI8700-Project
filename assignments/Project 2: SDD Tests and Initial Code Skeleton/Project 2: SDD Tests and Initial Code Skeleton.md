# Project 2: SDD Tests and Initial Code Skeleton

**15 Points Possible**

**Due:** Mon Nov 9, 2026 11:59pm

**Unlimited Attempts Allowed**

## Details

**Objective:** Practice test-first development.

The next document we will develop is the test plan document, `test_plan.md`. The test plan is a refinement of the acceptance criteria into actual scenarios for testing.

## Tasks

### Task 1: Generate the APIs/contracts

Before we can define tests, we need the tests to know what they are testing against. Tests need something to call within the program under test, whether REST APIs or function interfaces. And so our first step here is to generate what is commonly called contracts, basically agreed upon calling interfaces. As a byproduct, we also create the initial skeleton of your implementation code.

```text
Read spec.md and architecture.md. Write no business logic.

Create a runnable skeleton in <language/framework>:
1. For each module in architecture.md, create the module with the public functions and classes, using the exact names, parameters and types you propose. Every body raises NotImplementedError (or the equivalent). Add a contracts.md that lists, for each function: signature, success result, how it fails, the spec rule it serves, and what is injected (such as the clock).
4. Add nothing the architecture does not list.

Show me the commands to start the application.
```

Review `contracts.md` and make sure every requirement that needs it has an entry point in the code. Remove unnecessary public functions and APIs. Update the skeleton to be consistent with `contracts.md`.

### Task 2: Generate a test plan

(Task 1 and Task 2 can be done in any order.)

Let's refine the Acceptance Criteria in `spec.md` into a test plan.

```text
Read spec.md and architecture.md. Do not read any implementation code, and do not write any logic yet.

Produce test_plan.md: a table with one row per acceptance criterion, with the columns:
- ID (the criterion's ID from the spec)
- Requirement (the spec section it tests)
- Cases (each case as: request or call, expected status, expected body fields, expected side effects)
- Inside/outside (for every limit in the requirements: the case just inside it and the case just outside it)
- Control (for every rejection: a valid request of the same shape that is accepted, so the rejection can only be due to this requirement)

Rules:
- Every rejected request must be wrong in exactly one way.
- Compute expected values by hand from the spec.
- For every rejection, include a check that nothing was created.
- Walk the gap checklist (boundaries, time, identity, state, concurrency, input types, errors and precedence, listing, what is returned) and add a case for any category the criteria miss. Mark these "extra" and name the requirement they probe.
- List any requirement with no acceptance criterion, and any acceptance criterion with no requirement, under "Spec gaps". Do not resolve them yourself.
```

Review `test_plan.md` before moving on. Do the expected values match the spec? Are there any spec gaps?

### Task 2 (BDD alternative): Generate BDD acceptance tests

We can also build on the BDD scenarios already defined in the Acceptance Criteria:

```text
Read spec.md and architecture.md. Do not read any implementation code, and do not write any logic yet.

Produce test_plan.md: a refinement of the BDD scenarios in the Acceptance Criteria:
- Add actual test input values and expected output values to each criterion.
- Add a unique ID to each test.

Add more scenarios to test_plan.md. For every test above, check that the following tests are also added:
- Inside/outside (for every limit in the requirements: the case just inside it and the case just outside it)
- Control (for every rejection: a valid request of the same shape that is accepted, so the rejection can only be due to this requirement)

Rules:
- Every rejected request must be wrong in exactly one way.
- Compute expected values by hand from the spec.
- For every rejection, include a check that nothing was created.
- Walk the gap checklist (boundaries, time, identity, state, concurrency, input types, errors and precedence, listing, what is returned) and add a case for any category the criteria miss. Mark these "extra" and name the requirement they probe.
- List any requirement with no acceptance criterion, and any acceptance criterion with no requirement, under "Spec gaps". Do not resolve them yourself.
```

### Task 3: Write the tests

We now have the parts needed to write the tests.

```text
Read spec.md, architecture.md, contracts.md and test_plan.md. Still do not read the implementation.

Write the tests for the rows I name below, using <your test framework>. For each case:
- Name the test with its criterion ID, e.g. test_AT01.
- Assert everything the plan lists: status, body fields, error code, and that nothing was created after a rejection.
- Put each control next to its rejection, in the same test or an adjacent one.
- Use the correct contract to invoke the functionality of the module under test

Rows to write now: <AT-01, AT-03, AT-04, ...>

Rules:
- Do not write the implementation.
- Run the tests and show me the output. For each failing test, state in one line whether it failed on an assertion about behavior. If any failed for another reason, fix the test or the skeleton, not the behavior.
- Call only the functions in the contract. If a test needs something it does not list, stop and ask me; do not invent it.
```

Before submitting, make sure the tests are only failing because of the missing implementation, not because of some syntax error or because it cannot call the module under test.

For multiple member teams, consider trying different implementation and testing frameworks.

## Submission:

In your GitHub repo, update the existing md files as needed. Add `contracts.md` and `test_plan.md` at the top folder. The code skeleton and the test code should follow the folder structure expected by your chosen framework. If there are multiple team members, update the separate branches.

In the textbox, include:

1. a link to the GitHub repository
2. the output of running the tests (copy and paste from the actual runs), and
3. a short writeup that describes:
   - additional changes and deviations from the Project 1 submission and why they were taken, and
   - (as applicable) additional ways that you used AI to help beyond the instructions given here.

> Keep in mind, this submission will count for everyone in your Project Groups group.
