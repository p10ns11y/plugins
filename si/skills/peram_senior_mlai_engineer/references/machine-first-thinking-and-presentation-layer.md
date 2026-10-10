# Machine First Thinking & Presentation Layer (p10ns11y standards)

## Machine First Thinking

From *thepulimaangani* experience, this is the preferred pattern:

- Early prototypes should be used **only** to deepen understanding of the problem.
- Do **not** extend the prototype into production code.
- Throw away the prototype and rebuild from a clean, strong core architecture ("Machine First").
- This leads to **effortless iteration**, stronger features, and cleaner code.

**Warning signs that the foundation is weak:**
- Small change touches many files → missing modularity and abstraction.
- Core logic is not terse, strong, and clean.
- Human-friendly poetic rules translated directly into code in a way that makes the algorithm hard to read for non-native programmers.
- Poor state management, weak type generation, or unclear separation of concerns.

In prosody specifically, human-friendly rules (used by poets) did not translate effectively to machines, even with cultural background. This realisation came from personal struggle with the prototype.

## Presentation / Display Layer

Important separation:

- **Machine core** (data structures, traversal, algorithms): Optimize for efficiency, speed, and accuracy. How the machine interprets the data does **not** need to be human-friendly.
- **Presentation/Display Layer**: Maps the machine's internal representation to user-friendly, natural, and predictable output.
  - Should feel natural even to naive users.
  - Should lead users away from making accidental mistakes.
  - Frontend should prefer native web APIs, minimize bloat and dependencies.

This separation was introduced in *thepulimaangani* to keep the Rust prosody processor clean and efficient while providing good UX.

**Frontend preferences:**
- Use native/existing web platform features where possible.
- Minimize dependencies and bloat.
- Clean UI/UX that is predictable.
- Design so the right action is the natural one.

This pattern is part of the `peram_senior_mlai_engineer` spine.

Where it lands in a product:

- Machine core for stored facts: `peram_data_workflows`
- Presentation of drafts and commits: `peram_si_native_workflows`
- Replaceable model behind the service path: `peram_si_service_harness`
- Transitions that must replay the same way: `peram_deterministic_saas`
- A service only the product needs, with cost and security that scale: `peram_infra`
- The documented builder path: `peram_devex`

Source: refactoring triggers and the machine/presentation split from *thepulimaangani*.
