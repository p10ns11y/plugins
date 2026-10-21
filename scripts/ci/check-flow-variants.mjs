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
  need(spec, 'flows/bend/LAWS.bend', flow.spec)
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

const laws = read('flows/bend/LAWS.bend')
const proof = read('flows/bend/PROOF.bend')
const model = read('flows/bend/flow.bend')
const critical = read('flows/test/bend-critical.sh')
need(proof, 'import ./LAWS.bend', 'flows/bend/PROOF.bend')
need(laws, 'import ./flow.bend', 'flows/bend/LAWS.bend')
for (const [name, text] of [
  ['flows/bend/LAWS.bend', laws],
  ['flows/bend/PROOF.bend', proof],
  ['flows/bend/flow.bend', model],
]) {
  if (/\bF32\b|@unsafe/.test(text)) failures.push(`${name} uses F32 or @unsafe`)
}
const notRun = critical.indexOf('formal proof not run')
const proved = critical.indexOf('ALL PROOFS CHECK')
if (notRun < 0) failures.push('flows/test/bend-critical.sh does not report an absent bend')
if (proved < 0 || !critical.includes('BEND_REQUIRED')) {
  failures.push('flows/test/bend-critical.sh treats an absent bend as a pass')
}
if (!critical.includes('--verdict PROOF.bend')) {
  failures.push('flows/test/bend-critical.sh does not run bend --verdict')
}
if (critical.includes('All terms check')) {
  failures.push('flows/test/bend-critical.sh accepts the forgeable "All terms check." banner')
}
if (!/BEND_REQUIRED=1 bash flows\/test\/bend-critical\.sh/.test(read('.github/workflows/plugins.yml'))) {
  failures.push('CI proof job does not run bend-critical.sh with BEND_REQUIRED=1')
}

if (failures.length) {
  for (const failure of failures) console.error(failure)
  console.error(`${failures.length} flow variant check(s) failed`)
  process.exit(1)
}
console.log(`${flows.length} flow(s) have a spec, Claude, Rhai, and portable variant`)
