#!/usr/bin/env node
// A PR that changes code must commit a test-only change before its first code commit.
// Usage: node scripts/ci/check-red-first.mjs <base-sha> [head-sha]

import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'

const TEST = [/(^|\/)(test|tests|__tests__|testdata|fixtures)\//, /\.(test|spec)\.[a-z]+$/, /(^|\/)test[-_][^/]*$/, /_test\.[a-z]+$/]
const CODE = /\.(m?js|cjs|ts|tsx|py|sh|rs|c|h|rhai|bend|go)$/

export function classify(path) {
  if (TEST.some((re) => re.test(path))) return 'test'
  return CODE.test(path) ? 'code' : 'other'
}

export function checkRedFirst(commits) {
  let red = false
  for (const { sha, files } of commits) {
    const kinds = new Set(files.map(classify))
    if (kinds.has('code')) {
      if (red) return { ok: true }
      return { ok: false, reason: `commit ${sha} changes code before any test-only commit` }
    }
    if (kinds.has('test')) red = true
  }
  return { ok: true }
}

function gitCommits(base, head) {
  const git = (...args) => execFileSync('git', args, { encoding: 'utf8' }).trim()
  const shas = git('rev-list', '--reverse', '--no-merges', `${base}..${head}`).split('\n').filter(Boolean)
  return shas.map((sha) => ({ sha, files: git('show', '--name-only', '--format=', sha).split('\n').filter(Boolean) }))
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const [base, head = 'HEAD'] = process.argv.slice(2)
  if (!base) {
    console.log('check-red-first: no base sha, skipped')
    process.exit(0)
  }
  const result = checkRedFirst(gitCommits(base, head))
  console.log(result.ok ? 'check-red-first: ok' : `check-red-first: ${result.reason}`)
  process.exit(result.ok ? 0 : 1)
}
