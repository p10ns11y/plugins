#!/usr/bin/env node
// Static checks for plugin/workflows/*.js. Does not execute the scripts.

import { spawnSync } from 'node:child_process'
import { mkdtempSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { dirname, join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..')
const fixture = join(root, 'scripts/ci/fixtures/bad-workflow.js')
const banned = /git push|gh pr merge|send/
const calls = [
  [/Date\s*\.\s*now\s*\(/, 'Date.now'],
  [/Math\s*\.\s*random\s*\(/, 'Math.random'],
  [/new\s+Date\s*\(/, 'new Date()'],
  [/import\s*\(/, 'import()'],
]

function pluginWorkflows() {
  const found = []
  for (const name of readdirSync(root)) {
    const dir = join(root, name, 'workflows')
    let info
    try {
      info = statSync(dir)
    } catch {
      continue
    }
    if (!info.isDirectory()) continue
    for (const file of readdirSync(dir)) {
      if (file.endsWith('.js')) found.push(join(dir, file))
    }
  }
  return found.sort()
}

function fail(errors, message) {
  errors.push(message)
}

function skipString(source, i) {
  const quote = source[i]
  i += 1
  while (i < source.length) {
    if (source[i] === '\\') {
      i += 2
      continue
    }
    if (source[i] === quote) return i + 1
    i += 1
  }
  return i
}

function extractMeta(source, errors) {
  const body = source.replace(/^\uFEFF/, '')
  if (!/^\s*export const meta\b/.test(body)) {
    fail(errors, 'export const meta is not the first statement')
    return null
  }
  const eq = body.indexOf('=', body.indexOf('export const meta'))
  let i = eq + 1
  while (i < body.length && /\s/.test(body[i])) i += 1
  if (body[i] !== '{') {
    fail(errors, 'meta is not an object literal')
    return null
  }
  const start = i
  let depth = 0
  while (i < body.length) {
    const ch = body[i]
    if (ch === '"' || ch === "'") {
      i = skipString(body, i)
      continue
    }
    if (ch === '`') {
      fail(errors, 'meta uses a template literal')
      return null
    }
    if (ch === '{') depth += 1
    if (ch === '}') {
      depth -= 1
      if (depth === 0) {
        return { text: body.slice(start, i + 1), rest: body.slice(i + 1), end: i + 1 }
      }
    }
    i += 1
  }
  fail(errors, 'meta object does not close')
  return null
}

function parseLiteral(text, errors) {
  let i = 0
  function peek() {
    while (i < text.length && /\s/.test(text[i])) i += 1
    return text[i]
  }
  function parseValue() {
    const ch = peek()
    if (ch === '{') return parseObject()
    if (ch === '[') return parseArray()
    if (ch === '"' || ch === "'") return parseString()
    if (ch === '-' || (ch >= '0' && ch <= '9')) return parseNumber()
    if (text.startsWith('true', i)) {
      i += 4
      return true
    }
    if (text.startsWith('false', i)) {
      i += 5
      return false
    }
    if (text.startsWith('null', i)) {
      i += 4
      return null
    }
    fail(errors, 'meta contains a non-literal')
    throw new Error('non-literal')
  }
  function parseString() {
    const quote = text[i]
    i += 1
    let out = ''
    while (i < text.length) {
      if (text[i] === '\\') {
        const n = text[i + 1]
        const map = { n: '\n', t: '\t', r: '\r', '\\': '\\', "'": "'", '"': '"' }
        out += map[n] ?? n ?? ''
        i += 2
        continue
      }
      if (text[i] === quote) {
        i += 1
        return out
      }
      out += text[i]
      i += 1
    }
    fail(errors, 'meta string does not close')
    throw new Error('string')
  }
  function parseNumber() {
    const start = i
    if (text[i] === '-') i += 1
    while (i < text.length && /[0-9.]/.test(text[i])) i += 1
    const value = Number(text.slice(start, i))
    if (!Number.isFinite(value)) {
      fail(errors, 'meta number is not finite')
      throw new Error('number')
    }
    return value
  }
  function parseObject() {
    const obj = {}
    i += 1
    if (peek() === '}') {
      i += 1
      return obj
    }
    while (i < text.length) {
      peek()
      let key
      if (text[i] === '"' || text[i] === "'") key = parseString()
      else {
        const start = i
        while (i < text.length && /[A-Za-z0-9_]/.test(text[i])) i += 1
        key = text.slice(start, i)
        if (!key) {
          fail(errors, 'meta has an empty key')
          throw new Error('key')
        }
      }
      peek()
      if (text[i] !== ':') {
        fail(errors, 'meta is missing a colon')
        throw new Error('colon')
      }
      i += 1
      obj[key] = parseValue()
      peek()
      if (text[i] === ',') {
        i += 1
        if (peek() === '}') {
          i += 1
          return obj
        }
        continue
      }
      if (text[i] === '}') {
        i += 1
        return obj
      }
      fail(errors, 'meta object has unexpected text')
      throw new Error('object')
    }
    fail(errors, 'meta object does not close')
    throw new Error('object-end')
  }
  function parseArray() {
    const arr = []
    i += 1
    if (peek() === ']') {
      i += 1
      return arr
    }
    while (i < text.length) {
      arr.push(parseValue())
      peek()
      if (text[i] === ',') {
        i += 1
        if (peek() === ']') {
          i += 1
          return arr
        }
        continue
      }
      if (text[i] === ']') {
        i += 1
        return arr
      }
      fail(errors, 'meta array has unexpected text')
      throw new Error('array')
    }
    fail(errors, 'meta array does not close')
    throw new Error('array-end')
  }
  try {
    const value = parseValue()
    peek()
    if (i !== text.length) fail(errors, 'meta has trailing text')
    return value
  } catch {
    return null
  }
}

function phaseTitles(meta, errors) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return []
  if (!Array.isArray(meta.phases)) return []
  const titles = []
  for (const phase of meta.phases) {
    if (typeof phase === 'string') titles.push(phase)
    else if (phase && typeof phase === 'object' && typeof phase.title === 'string') titles.push(phase.title)
    else fail(errors, 'meta.phases entry is not a title')
  }
  return titles
}

function moduleCheck(source, end, errors) {
  // The workflow host runs the body in an async function, so top-level await and
  // return are legal there. Node modules reject a bare return, so the check wraps
  // the body the same way.
  const body = source.replace(/^\uFEFF/, '')
  const program = end === null
    ? body
    : `${body.slice(0, end)}\nasync function __workflowSyntaxCheck() {\n${body.slice(end)}\n}\n`
  const dir = mkdtempSync(join(tmpdir(), 'wf-'))
  const file = join(dir, 'workflow.mjs')
  writeFileSync(file, program)
  const result = spawnSync(process.execPath, ['--check', file], { encoding: 'utf8' })
  rmSync(dir, { recursive: true, force: true })
  if (result.status !== 0) fail(errors, `does not parse as a module: ${(result.stderr || '').trim()}`)
}

function lint(source) {
  const errors = []
  const meta = extractMeta(source, errors)
  moduleCheck(source, meta && meta.end !== undefined ? meta.end : null, errors)
  let titles = []
  let rest = source
  if (meta) {
    const value = parseLiteral(meta.text, errors)
    rest = meta.rest
    if (value) {
      if (typeof value.name !== 'string' || value.name.length === 0) fail(errors, 'meta.name is not a literal string')
      if (typeof value.description !== 'string' || value.description.length === 0) {
        fail(errors, 'meta.description is not a literal string')
      }
      titles = phaseTitles(value, errors)
    }
  }
  for (const [pattern, label] of calls) {
    if (pattern.test(source)) fail(errors, `banned call ${label}`)
  }
  if (banned.test(source)) fail(errors, 'banned irreversible text')
  const seen = new Set()
  const phaseCall = /phase\(\s*(['"])((?:\\.|(?!\1).)*)\1\s*\)/g
  let match
  while ((match = phaseCall.exec(rest))) {
    seen.add(match[2])
    if (!titles.includes(match[2])) fail(errors, `phase ${match[2]} is missing from meta.phases`)
  }
  const bare = rest.replace(phaseCall, '')
  if (/phase\s*\(/.test(bare)) fail(errors, 'phase() title is not a string literal')
  return errors
}

function report(file, errors) {
  for (const error of errors) console.error(`${file}: ${error}`)
}

const failures = []
for (const file of pluginWorkflows()) {
  const errors = lint(readFileSync(file, 'utf8'))
  if (errors.length) {
    report(relative(root, file), errors)
    failures.push(file)
  }
}

const good = `export const meta = { name: 'ok', description: 'ok', phases: [{ title: 'One', detail: 'one' }] }\nphase('One')\nconst value = await Promise.resolve(1)\nreturn [value].filter(Boolean)\n`
const goodErrors = lint(good)
if (goodErrors.length) {
  report('in-memory good script', goodErrors)
  failures.push('good')
}

const fixtureErrors = lint(readFileSync(fixture, 'utf8'))
if (fixtureErrors.length === 0 || !fixtureErrors.some((error) => error.includes('Date.now'))) {
  console.error('negative fixture was accepted')
  failures.push(fixture)
} else {
  console.log(`negative fixture rejected (${fixtureErrors.length})`)
}

if (failures.length) {
  console.error(`${failures.length} workflow check(s) failed`)
  process.exit(1)
}
console.log(`${pluginWorkflows().length} workflow script(s) ok`)
