export const meta = {
  name: 'capture-sweep',
  description: 'Read-only capture, a fresh verifier, then one actor writes tstack-state.',
  phases: [
    { title: 'Read', detail: 'mail, calendar, chat, and pull requests' },
    { title: 'Verify', detail: 'fresh context before the card' },
    { title: 'Act', detail: 'the only writer of tstack-state' },
  ],
}

const flowSpec = 'flows/specs/capture-sweep.md'

const cardSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['source', 'cards'],
  properties: {
    source: { type: 'string' },
    cards: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['title', 'kind'],
        properties: {
          title: { type: 'string' },
          kind: { type: 'string' },
        },
      },
    },
  },
}

const verdictSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['ok'],
  properties: {
    ok: { type: 'boolean' },
    because: { type: 'string' },
  },
}

const actSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['stored', 'held'],
  properties: {
    stored: { type: 'number' },
    held: { type: 'number' },
  },
}

const sources = [
  { id: 'mail', skill: 'capture-mail' },
  { id: 'calendar', skill: 'capture-calendar' },
  { id: 'chat', skill: 'capture-chat' },
  { id: 'pr', skill: 'capture-pr' },
]

phase('Read')
const reads = (await parallel(sources.map((source) => () => agent(
  `Follow ${flowSpec} and ${source.skill}. Source id ${source.id}. Read only and return summary cards. Kind is none, money, post, or sign. Return the schema object.`,
  { schema: cardSchema, label: source.id, phase: 'Read', agentType: 'tstack:capture-reader' },
)))).filter(Boolean)

phase('Verify')
const verdict = await agent(
  `Follow ${flowSpec}. Fresh context. Check these cards. Read only. Set ok true when every card has a source and a kind. Do not write. Cards: ${JSON.stringify(reads)}. Return the schema object.`,
  { schema: verdictSchema, label: 'verify', phase: 'Verify', model: 'opus', agentType: 'Explore' },
)

phase('Act')
const acted = await agent(
  `Follow ${flowSpec}. You are the only writer. Store kind none through tstack-state. Hold kind money, post, or sign for a person. Do not post, pay, or sign. Verdict: ${JSON.stringify(verdict)}. Cards: ${JSON.stringify(reads)}. Return the schema object.`,
  { schema: actSchema, label: 'act', phase: 'Act', agentType: 'tstack:capture-actor' },
)

return {
  cards: reads,
  ok: verdict ? verdict.ok === true : false,
  stored: acted ? acted.stored : 0,
  held: acted ? acted.held : 0,
}
