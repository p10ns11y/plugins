export const meta = {
  name: 'rule-review',
  description: 'One verifier per rule, then a skeptic. Returns flags with evidence lines.',
  phases: [
    { title: 'Split', detail: 'read the rules file' },
    { title: 'Verify', detail: 'one SI per rule' },
    { title: 'Skeptic', detail: 'keep a flag only when it holds' },
  ],
}

const rulesSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['rules'],
  properties: {
    rules: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'text'],
        properties: {
          id: { type: 'string' },
          text: { type: 'string' },
        },
      },
    },
  },
}

const hitSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['hit', 'ruleId', 'evidence'],
  properties: {
    hit: { type: 'boolean' },
    ruleId: { type: 'string' },
    evidence: { type: 'string' },
  },
}

const verdictSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['keep', 'ruleId', 'evidence'],
  properties: {
    keep: { type: 'boolean' },
    ruleId: { type: 'string' },
    evidence: { type: 'string' },
  },
}

const diff = args && typeof args.diff === 'string' ? args.diff : ''
const rulesFile = args && typeof args.rulesFile === 'string' ? args.rulesFile : ''

if (!diff || !rulesFile) {
  log('rule-review needs args.diff and args.rulesFile')
  return { flags: [] }
}

phase('Split')
const split = await agent(
  `Read ${rulesFile}. List each hard rule as id and text. Do not review the diff yet. Return the schema object.`,
  { schema: rulesSchema, label: 'split', phase: 'Split', agentType: 'Explore' },
)

const rules = split && Array.isArray(split.rules) ? split.rules : []

phase('Verify')
const hits = rules.length === 0
  ? []
  : (await parallel(rules.map((rule) => () => agent(
      `Diff:\n${diff}\nRule ${rule.id}: ${rule.text}\nSet hit true only when a diff line breaks the rule. evidence is that line. Return the schema object.`,
      { schema: hitSchema, label: rule.id, phase: 'Verify', agentType: 'Explore' },
    )))).filter(Boolean)

const flagged = hits.filter((hit) => hit.hit)

phase('Skeptic')
const verdicts = flagged.length === 0
  ? []
  : (await parallel(flagged.map((flag) => () => agent(
      `Try to refute this flag. Diff:\n${diff}\nRule ${flag.ruleId}. Evidence: ${flag.evidence}\nSet keep true when that evidence line is in the diff and the rule covers it. Do not drop a flag only because the wording is sharp. Return the schema object.`,
      { schema: verdictSchema, label: flag.ruleId, phase: 'Skeptic', model: 'opus', agentType: 'Explore' },
    )))).filter(Boolean)

return {
  flags: verdicts.filter((verdict) => verdict.keep).map((verdict) => ({
    ruleId: verdict.ruleId,
    evidence: verdict.evidence,
  })),
}
