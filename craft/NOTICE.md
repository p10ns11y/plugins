# NOTICE

Copyright (c) 2026 p10ns11y. MIT. See `LICENSE`.

Craft adapts ideas from Robert C. Martin's clean-code and craftsmanship work, especially his agent chain described as a work in progress: acceptance tests from a human spec, then coder, cleaner with the CRAP score (change risk anti-patterns: cyclomatic complexity weighed against automated test coverage), then hardener with mutation testing, then QA from a written procedure. This plugin does not copy his books or claim the chain is finished.

The CRAP formula follows the public definition by Robert C. Martin and Alberto Savoia: `CRAP(m) = comp(m)^2 * (1 - cov(m))^3 + comp(m)` where `comp` is cyclomatic complexity and `cov` is line coverage from automated tests.

Mutation testing here is a small Python runner for this plugin's fixtures and for touched Python modules in a diff. It is not a full production mutator.

For playbook routing and the house TDD row, use installed pstack or `pstack-map`. For which layer should hold an invariant, use `trust-stack`. Craft owns the measured cleaner and hardener steps, not machine placement or corroboration.
