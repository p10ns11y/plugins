export const meta = {
  name: 'eva',
  description: 'Prior-diverse hypotheses, then refuters, for at most three rounds.',
  phases: [
    { title: 'Prior', detail: 'conservative, generative, and causal' },
    { title: 'Refute', detail: 'one refuter per live hypothesis' },
  ],
}

const flowSpec = 'flows/specs/eva.md'

const hypSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'kind', 'claim'],
  properties: {
    id: { type: 'string' },
    kind: { type: 'string' },
    claim: { type: 'string' },
    evidence: { type: 'string' },
  },
}

const refSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['id', 'refuted'],
  properties: {
    id: { type: 'string' },
    refuted: { type: 'boolean' },
    because: { type: 'string' },
  },
}

const kinds = ['conservative', 'generative', 'causal']
const goal = args && typeof args.goal === 'string' ? args.goal : ''

if (!goal) {
  log('eva needs args.goal')
  phase('Refute')
  await agent(
    `Follow ${flowSpec}. Fresh context. No goal was given. Read only. Return id none and refuted true.`,
    { schema: refSchema, label: 'refute', phase: 'Refute', model: 'opus', agentType: 'Explore' },
  )
  return { survivor: null, rounds: 0, ask: true, standing: [] }
}

phase('Prior')
const priors = (await parallel(kinds.map((kind) => () => agent(
  `Follow ${flowSpec} and eva-emptiness. Goal: ${goal}. Take the ${kind} prior and state one hypothesis. Set id to ${kind}. Read only. Return the schema object.`,
  { schema: hypSchema, label: kind, phase: 'Prior', agentType: 'Explore' },
)))).filter(Boolean)

let live = priors
let round = 0
while (round < 3 && live.length > 0) {
  phase('Refute')
  const votes = (await parallel(live.map((hyp) => () => agent(
    `Follow ${flowSpec}. Fresh context. Try to refute this hypothesis for the goal: ${goal}. Hypothesis: ${JSON.stringify(hyp)}. Echo id ${hyp.id}. Set refuted true when the claim does not hold. Read only. Return the schema object.`,
    { schema: refSchema, label: hyp.id, phase: 'Refute', model: 'opus', agentType: 'Explore' },
  )))).filter(Boolean)
  const kept = []
  for (const hyp of live) {
    const vote = votes.find((item) => item.id === hyp.id)
    if (vote && vote.refuted === false) kept.push(hyp)
  }
  live = kept
  round += 1
  if (live.length <= 1) break
}

if (round === 0) {
  phase('Refute')
  await agent(
    `Follow ${flowSpec}. Fresh context. No hypothesis is live. Read only. Return id none and refuted true.`,
    { schema: refSchema, label: 'refute', phase: 'Refute', model: 'opus', agentType: 'Explore' },
  )
}

return {
  survivor: live.length === 1 ? live[0] : null,
  rounds: round,
  ask: live.length !== 1,
  standing: live,
}
