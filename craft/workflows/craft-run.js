export const meta = {
  name: 'run',
  description: 'Spec, code, clean, harden, then a fresh QA card.',
  phases: [
    { title: 'Spec', detail: 'acceptance before code' },
    { title: 'Code', detail: 'tests and the implementation' },
    { title: 'Clean', detail: 'CRAP on touched functions' },
    { title: 'Harden', detail: 'mutation score' },
    { title: 'QA', detail: 'fresh context card' },
  ],
}

const flowSpec = 'flows/specs/craft-run.md'

const report = {
  type: 'object',
  additionalProperties: false,
  required: ['notes'],
  properties: {
    notes: { type: 'string' },
    next: { type: 'string' },
  },
}

const card = {
  type: 'object',
  additionalProperties: false,
  required: ['spec', 'acceptance', 'step', 'touched', 'crap_max', 'mutation', 'scout', 'next'],
  properties: {
    spec: { type: 'string' },
    acceptance: { type: 'string' },
    step: { type: 'string' },
    touched: { type: 'string' },
    crap_max: { type: 'string' },
    mutation: { type: 'string' },
    scout: { type: 'string' },
    next: { type: 'string' },
  },
}

const change = args && typeof args.change === 'string' ? args.change : ''

phase('Spec')
const spec = await agent(
  `Follow ${flowSpec} and the craft skill. Write the spec and the acceptance for this change before any implementation: ${change}. Read only. Return the schema object.`,
  { schema: report, label: 'spec', phase: 'Spec', agentType: 'Explore' },
)

phase('Code')
const code = await agent(
  `Follow ${flowSpec} and the craft skill. Implement the change and its tests from this spec: ${JSON.stringify(spec)}. Change: ${change}. Return the schema object.`,
  { schema: report, label: 'code', phase: 'Code' },
)

phase('Clean')
const clean = await agent(
  `Follow ${flowSpec} and the craft skill. Run CRAP on functions this change touched. Stay inside those files. Spec: ${JSON.stringify(spec)}. Code: ${JSON.stringify(code)}. Return the schema object.`,
  { schema: report, label: 'clean', phase: 'Clean' },
)

phase('Harden')
const harden = await agent(
  `Follow ${flowSpec} and the craft skill. Run the mutation score on non-Bend code this change touched. Clean: ${JSON.stringify(clean)}. Return the schema object.`,
  { schema: report, label: 'harden', phase: 'Harden' },
)

phase('QA')
const qa = await agent(
  `Follow ${flowSpec} and the craft skill as QA in a fresh context. Do not implement. Fill the card from these notes. Spec: ${JSON.stringify(spec)}. Code: ${JSON.stringify(code)}. Clean: ${JSON.stringify(clean)}. Harden: ${JSON.stringify(harden)}. Return the schema object.`,
  { schema: card, label: 'qa', phase: 'QA', model: 'opus', agentType: 'Explore' },
)

return qa || {
  spec: '',
  acceptance: 'no',
  step: 'qa',
  touched: '',
  crap_max: '',
  mutation: '',
  scout: '',
  next: 'QA returned nothing',
}
