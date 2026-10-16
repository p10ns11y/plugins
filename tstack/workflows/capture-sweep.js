export const meta = {
  name: 'capture-sweep',
  description: 'Read-only capture, then one actor writes tstack-state.',
  phases: [
    { title: 'Read', detail: 'mail, calendar, chat, and pull requests' },
    { title: 'Act', detail: 'the only writer of tstack-state' },
  ],
}

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
  `Follow ${source.skill}. Source id ${source.id}. Read only and return summary cards. Kind is none, money, post, or sign. Return the schema object.`,
  { schema: cardSchema, label: source.id, phase: 'Read', agentType: 'tstack:capture-reader' },
)))).filter(Boolean)

phase('Act')
const acted = await agent(
  `You are the only writer. Store kind none through tstack-state. Hold kind money, post, or sign for a person. Do not post, pay, or sign. Cards: ${JSON.stringify(reads)}. Return the schema object.`,
  { schema: actSchema, label: 'act', phase: 'Act', agentType: 'tstack:capture-actor' },
)

return { cards: reads, stored: acted ? acted.stored : 0, held: acted ? acted.held : 0 }
