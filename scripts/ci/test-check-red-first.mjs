#!/usr/bin/env node
// Behaviour of check-red-first: a PR that changes code must commit a test-only change first.

import { test } from 'node:test'
import assert from 'node:assert/strict'
import { classify, checkRedFirst } from './check-red-first.mjs'

test('classify tells tests, code and other files apart', () => {
  assert.equal(classify('craft/test/check-scores.sh'), 'test')
  assert.equal(classify('scripts/ci/test-check-red-first.mjs'), 'test')
  assert.equal(classify('si/src/route.spec.ts'), 'test')
  assert.equal(classify('intelli-route/tests/test_layout.py'), 'test')
  assert.equal(classify('scripts/ci/check-red-first.mjs'), 'code')
  assert.equal(classify('mission-map/rust/src/main.rs'), 'code')
  assert.equal(classify('README.md'), 'other')
  assert.equal(classify('.github/workflows/plugins.yml'), 'other')
})

test('passes when a test-only commit comes before the first code commit', () => {
  const r = checkRedFirst([
    { sha: 'a1', files: ['craft/test/check-new.sh'] },
    { sha: 'b2', files: ['craft/bin/new.sh', 'craft/README.md'] },
  ])
  assert.equal(r.ok, true)
})

test('fails when code lands before any test-only commit', () => {
  const r = checkRedFirst([
    { sha: 'a1', files: ['craft/bin/new.sh'] },
    { sha: 'b2', files: ['craft/test/check-new.sh'] },
  ])
  assert.equal(r.ok, false)
  assert.match(r.reason, /a1/)
})

test('a commit mixing test and code is not a red commit', () => {
  const r = checkRedFirst([{ sha: 'a1', files: ['craft/test/t.sh', 'craft/bin/new.sh'] }])
  assert.equal(r.ok, false)
})

test('passes when the PR changes no code at all', () => {
  const r = checkRedFirst([{ sha: 'a1', files: ['docs/workflows.md', '.github/workflows/plugins.yml'] }])
  assert.equal(r.ok, true)
})
