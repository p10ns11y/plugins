#!/usr/bin/env node
// Each shared flow has a spec plus Claude, Rhai, and portable variants.

import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const flows = [
  {
    spec: 'flows/specs/craft-run.md',
    js: 'craft/workflows/craft-run.js',
    rhai: 'craft/.grok/workflows/craft-run.rhai',
    portable: 'flows/portable/craft-run.md',
    phases: ['Spec', 'Code', 'Clean', 'Harden', 'QA'],
  },
  {
    spec: 'flows/specs/rule-review.md',
    js: 'trust-stack/workflows/rule-review.js',
    rhai: 'trust-stack/.grok/workflows/rule-review.rhai',
    portable: 'flows/portable/rule-review.md',
    phases: ['Split', 'Verify', 'Skeptic'],
  },
  {
    spec: 'flows/specs/eva.md',
    js: 'eva-emptiness/workflows/eva.js',
    rhai: 'eva-emptiness/.grok/workflows/eva.rhai',
    portable: 'flows/portable/eva.md',
    phases: ['Prior', 'Refute'],
  },
  {
    spec: 'flows/specs/mine-corrections.md',
    js: 'pulse-memory/workflows/mine-corrections.js',
    rhai: 'pulse-memory/.grok/workflows/mine-corrections.rhai',
    portable: 'flows/portable/mine-corrections.md',
    phases: ['Mine', 'Cluster', 'Filter'],
  },
  {
    spec: 'flows/specs/capture-sweep.md',
    js: 'tstack/workflows/capture-sweep.js',
    rhai: 'tstack/.grok/workflows/capture-sweep.rhai',
    portable: 'flows/portable/capture-sweep.md',
    phases: ['Read', 'Verify', 'Act'],
  },
]

const failures = []

function read(rel) {
  try {
    return readFileSync(join(root, rel), 'utf8')
  } catch {
    failures.push(`missing ${rel}`)
    return ''
  }
}

function need(text, needle, where) {
  if (!text.includes(needle)) failures.push(`${where} does not name ${needle}`)
}

for (const flow of flows) {
  const spec = read(flow.spec)
  const js = read(flow.js)
  const rhai = read(flow.rhai)
  const portable = read(flow.portable)
  need(js, flow.spec, flow.js)
  need(rhai, flow.spec, flow.rhai)
  need(portable, flow.spec, flow.portable)
  need(spec, flow.js, flow.spec)
  need(spec, flow.rhai, flow.spec)
  need(spec, flow.portable, flow.spec)
  need(portable, 'fresh', flow.portable)
  need(portable, 'card', flow.portable)
  need(portable, 'Sign-off', flow.portable)
  for (const phase of flow.phases) {
    need(spec, phase, flow.spec)
    need(js, phase, flow.js)
    need(rhai, phase, flow.rhai)
  }
}

if (failures.length) {
  for (const failure of failures) console.error(failure)
  console.error(`${failures.length} flow variant check(s) failed`)
  process.exit(1)
}
console.log(`${flows.length} flow(s) have a spec, Claude, Rhai, and portable variant`)
