-- migration 1
CREATE TABLE IF NOT EXISTS schema_migrations (
  version INTEGER PRIMARY KEY,
  applied_at TEXT NOT NULL
);

-- ARCHIVE: residue. Full fidelity. Never injected whole.
CREATE TABLE IF NOT EXISTS archive_events (
  id INTEGER PRIMARY KEY,
  ts TEXT NOT NULL,
  source TEXT NOT NULL,
  payload TEXT NOT NULL,
  correlation_id TEXT
);

-- MEMORY: admitted traces only. Dedup by natural key.
CREATE TABLE IF NOT EXISTS memory_traces (
  id INTEGER PRIMARY KEY,
  nat_key TEXT NOT NULL UNIQUE,  -- e.g. apply/sitting/cap
  snippet TEXT NOT NULL,         -- ≤ ~120 tokens
  source TEXT NOT NULL,
  time TEXT NOT NULL,            -- ISO-8601 or 'unknown'
  status TEXT NOT NULL CHECK (status IN
    ('user-stated','tool-verified','inferred','unknown')),
  kind TEXT NOT NULL CHECK (kind IN
    ('data','context','fact','memory')),
  lock TEXT NOT NULL DEFAULT 'open' CHECK (lock IN ('open','locked')),
  verify_hash TEXT,
  prefetch_key TEXT,
  seen_count INTEGER NOT NULL DEFAULT 1,
  superseded_by TEXT,            -- nat_key of later trace, or NULL
  first_seen TEXT NOT NULL,
  last_seen TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS memory_fts USING fts5(
  nat_key, snippet, source, content='memory_traces', content_rowid='id'
);

CREATE TABLE IF NOT EXISTS conflicts (
  id INTEGER PRIMARY KEY,
  subject TEXT NOT NULL,
  left_id INTEGER NOT NULL REFERENCES memory_traces(id),
  right_id INTEGER NOT NULL REFERENCES memory_traces(id),
  resolution TEXT NOT NULL,      -- winner nat_key or 'not in the evidence'
  ts TEXT NOT NULL
);

-- migration 2
CREATE TABLE IF NOT EXISTS maps (
  id TEXT PRIMARY KEY CHECK (
    length(id) BETWEEN 1 AND 64
    AND id NOT LIKE '%/%'
    AND id NOT LIKE '%@%'
  ),
  g TEXT NOT NULL,
  effort_cap REAL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS stages (
  map_id TEXT NOT NULL REFERENCES maps(id),
  stage_id TEXT NOT NULL,
  label TEXT NOT NULL CHECK (length(label) BETWEEN 1 AND 120),
  class TEXT NOT NULL CHECK (class IN ('Do','Risk','Wait','Park','Done')),
  a REAL NOT NULL,
  m REAL NOT NULL,
  b REAL NOT NULL,
  depends_on TEXT NOT NULL DEFAULT '[]',
  critical INTEGER NOT NULL DEFAULT 0 CHECK (critical IN (0, 1)),
  next_do INTEGER NOT NULL DEFAULT 0 CHECK (next_do IN (0, 1)),
  PRIMARY KEY (map_id, stage_id),
  CHECK (
    length(stage_id) BETWEEN 1 AND 64
    AND stage_id NOT LIKE '%/%'
    AND stage_id NOT LIKE '%@%'
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS one_next_do
  ON stages(map_id) WHERE next_do = 1;

CREATE TABLE IF NOT EXISTS blocks (
  id INTEGER PRIMARY KEY,
  map_id TEXT NOT NULL,
  stage_id TEXT NOT NULL,
  energy TEXT NOT NULL CHECK (energy IN ('high','mid','low')),
  plan TEXT,
  status TEXT NOT NULL CHECK (status IN ('open','closed')),
  started_at TEXT NOT NULL,
  closed_at TEXT,
  FOREIGN KEY (map_id, stage_id) REFERENCES stages(map_id, stage_id)
);

CREATE UNIQUE INDEX IF NOT EXISTS one_open_block
  ON blocks(map_id) WHERE status = 'open';

CREATE TABLE IF NOT EXISTS harvest_rows (
  id INTEGER PRIMARY KEY,
  ts TEXT NOT NULL,
  map_id TEXT NOT NULL,
  stage_id TEXT NOT NULL,
  result TEXT NOT NULL CHECK (length(trim(result)) > 0),
  evidence TEXT NOT NULL CHECK (length(trim(evidence)) > 0),
  FOREIGN KEY (map_id, stage_id) REFERENCES stages(map_id, stage_id)
);
