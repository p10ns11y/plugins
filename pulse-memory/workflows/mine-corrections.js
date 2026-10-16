export const meta = {
  name: 'mine-corrections',
  description: 'Mine repeated corrections and return proposed rules only.',
  phases: [
    { title: 'Mine', detail: 'one reader per path' },
    { title: 'Cluster', detail: 'group repeated corrections' },
    { title: 'Filter', detail: 'keep a rule that would have prevented a miss' },
  ],
}

const flowSpec = 'flows/specs/mine-corrections.md'

const noteSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['notes'],
  properties: {
    notes: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['path', 'correction'],
        properties: {
          path: { type: 'string' },
          correction: { type: 'string' },
        },
      },
    },
  },
}

const clusterSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['clusters'],
  properties: {
    clusters: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['label', 'count'],
        properties: {
          label: { type: 'string' },
          count: { type: 'number' },
        },
      },
    },
  },
}

const ruleSchema = {
  type: 'object',
  additionalProperties: false,
  required: ['rules'],
  properties: {
    rules: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['rule', 'prevented'],
        properties: {
          rule: { type: 'string' },
          prevented: { type: 'boolean' },
        },
      },
    },
  },
}

const since = args && typeof args.since === 'string' ? args.since : ''
const paths = args && Array.isArray(args.paths) ? args.paths.filter((item) => typeof item === 'string') : []

if (paths.length === 0) {
  log('mine-corrections needs args.paths')
  phase('Filter')
  await agent(
    `Follow ${flowSpec}. Fresh context. No paths were given. Do not edit any file. Return rules as an empty list.`,
    { schema: ruleSchema, label: 'filter', phase: 'Filter', model: 'opus', agentType: 'Explore' },
  )
  return { rules: [] }
}

phase('Mine')
const mined = (await parallel(paths.map((path) => () => agent(
  `Follow ${flowSpec}. Read ${path}. Since ${since}, list corrections a person repeated. Do not edit any file. Return the schema object.`,
  { schema: noteSchema, label: path, phase: 'Mine', agentType: 'Explore' },
)))).filter(Boolean)

phase('Cluster')
const clustered = await agent(
  `Follow ${flowSpec}. Group these corrections by the repeated miss. Drop one-off notes. Notes: ${JSON.stringify(mined)}. Do not edit any file. Return the schema object.`,
  { schema: clusterSchema, label: 'cluster', phase: 'Cluster', agentType: 'Explore' },
)

phase('Filter')
const filtered = await agent(
  `Follow ${flowSpec}. Fresh context. Keep a cluster only when a rule written from it would have prevented a real miss. Clusters: ${JSON.stringify(clustered)}. Set prevented true only for those. Do not edit any file. Return the schema object.`,
  { schema: ruleSchema, label: 'filter', phase: 'Filter', model: 'opus', agentType: 'Explore' },
)

const rules = filtered && Array.isArray(filtered.rules) ? filtered.rules : []
return { rules: rules.filter((item) => item.prevented).map((item) => item.rule) }
