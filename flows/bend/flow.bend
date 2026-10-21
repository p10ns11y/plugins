import Base

# Shared flow model. Specs in flows/specs reference flows/bend/LAWS.bend.
# any_bad: Send, Pay, and Sign are irreversible.
# card_ok: Emit Yes is legal only after a Verify that counts for the trace tier.
# merge_ok: Merge is legal only after a Verify that counts for the trace tier.
# Critical tier: only Fresh counts. Normal tier: Fresh or Variant. Same never.
# writes_ok: in capture-sweep a Write is legal only as the last step. It is not
# part of clean(): craft-run legitimately writes before its verify.
# A Write makes any earlier Verify stale: card_ok and merge_ok reset seen to 0n.
# Laws in LAWS.bend are checked on the named example traces, not for all traces.

# Verifier kind on a step. Same: the acting agent itself (never counts).
# Variant: same model family, a separate subagent or local run (same model,
# an earlier version, or another effort level). Fresh: an independent verifier.
type Ctx is Data:
  Same{}
  Variant{}
  Fresh{}

# Trace tier. Critical: irreversible Send/Pay/Sign, merges to protected or
# frozen repos, anything tagged critical. Only Fresh counts there.
# Normal: Fresh or Variant counts.
type Tier is Data:
  Normal{}
  Critical{}

type Act is Data:
  Read{}
  Write{}
  Merge{}
  Send{}
  Pay{}
  Sign{}
  Verify{}

type Emit is Data:
  No{}
  Yes{}

type Step is Data:
  Step{ctx: Ctx, act: Act, emit: Emit}

type Steps is Data:
  End{}
  Cons{step: Step, rest: Steps}

def any_bad(steps: Steps) -> Nat:
  match steps:
    case End{}:
      0n
    case Cons{+step, +rest}:
      match step:
        case Step{+ctx, +act, +emit}:
          match act:
            case Send{}:
              1n
            case Pay{}:
              1n
            case Sign{}:
              1n
            case Read{}:
              any_bad(rest)
            case Write{}:
              any_bad(rest)
            case Merge{}:
              any_bad(rest)
            case Verify{}:
              any_bad(rest)

def counts(ctx: Ctx, tier: Tier) -> Nat:
  match ctx:
    case Same{}:
      0n
    case Variant{}:
      match tier:
        case Normal{}:
          1n
        case Critical{}:
          0n
    case Fresh{}:
      1n

def bump(seen: Nat, got: Nat) -> Nat:
  match got:
    case 0n:
      seen
    case 1n+p:
      1n

def next_seen(act: Act, ctx: Ctx, +tier: Tier, +seen: Nat) -> Nat:
  match act:
    case Verify{}:
      bump(seen, counts(ctx, tier))
    case Write{}:
      0n
    case Read{}:
      seen
    case Merge{}:
      seen
    case Send{}:
      seen
    case Pay{}:
      seen
    case Sign{}:
      seen

def card_ok(steps: Steps, +seen: Nat, +tier: Tier) -> Nat:
  match steps:
    case End{}:
      1n
    case Cons{+step, +rest}:
      match step:
        case Step{+ctx, +act, +emit}:
          match emit:
            case No{}:
              card_ok(rest, next_seen(act, ctx, tier, seen), tier)
            case Yes{}:
              match seen:
                case 0n:
                  0n
                case 1n+p:
                  card_ok(rest, next_seen(act, ctx, tier, 1n), tier)

def merge_ok(steps: Steps, +seen: Nat, +tier: Tier) -> Nat:
  match steps:
    case End{}:
      1n
    case Cons{+step, +rest}:
      match step:
        case Step{+ctx, +act, +emit}:
          match act:
            case Merge{}:
              match seen:
                case 0n:
                  0n
                case 1n+p:
                  merge_ok(rest, 1n, tier)
            case Verify{}:
              merge_ok(rest, bump(seen, counts(ctx, tier)), tier)
            case Write{}:
              merge_ok(rest, 0n, tier)
            case Read{}:
              merge_ok(rest, seen, tier)
            case Send{}:
              merge_ok(rest, seen, tier)
            case Pay{}:
              merge_ok(rest, seen, tier)
            case Sign{}:
              merge_ok(rest, seen, tier)

def writes_ok(steps: Steps) -> Nat:
  match steps:
    case End{}:
      1n
    case Cons{+step, +rest}:
      match step:
        case Step{+ctx, +act, +emit}:
          match act:
            case Read{}:
              writes_ok(rest)
            case Write{}:
              match rest:
                case End{}:
                  1n
                case Cons{+later, +tail}:
                  0n
            case Merge{}:
              writes_ok(rest)
            case Send{}:
              writes_ok(rest)
            case Pay{}:
              writes_ok(rest)
            case Sign{}:
              writes_ok(rest)
            case Verify{}:
              writes_ok(rest)

def hold(bad: Nat, card: Nat, merge: Nat) -> Nat:
  match bad:
    case 0n:
      match card:
        case 0n:
          0n
        case 1n+p:
          match merge:
            case 0n:
              0n
            case 1n+q:
              1n
    case 1n+p:
      0n

def clean(+steps: Steps, +tier: Tier) -> Nat:
  bad = any_bad(steps)
  card = card_ok(steps, 0n, tier)
  merge = merge_ok(steps, 0n, tier)
  hold(bad, card, merge)

def read(rest: Steps) -> Steps:
  Cons{Step{Same{}, Read{}, No{}}, rest}

def write(rest: Steps) -> Steps:
  Cons{Step{Same{}, Write{}, No{}}, rest}

def fresh(rest: Steps) -> Steps:
  Cons{Step{Fresh{}, Verify{}, No{}}, rest}

def variant(rest: Steps) -> Steps:
  Cons{Step{Variant{}, Verify{}, No{}}, rest}

def self_check(rest: Steps) -> Steps:
  Cons{Step{Same{}, Verify{}, No{}}, rest}

def card() -> Steps:
  Cons{Step{Same{}, Read{}, Yes{}}, End{}}

def craft() -> Steps:
  read(write(write(write(fresh(card())))))

def rule() -> Steps:
  read(fresh(fresh(card())))

def eva() -> Steps:
  read(fresh(card()))

def mine() -> Steps:
  read(read(fresh(card())))

def capture() -> Steps:
  read(fresh(Cons{Step{Same{}, Write{}, Yes{}}, End{}}))

def bare_merge() -> Steps:
  Cons{Step{Same{}, Merge{}, No{}}, End{}}

def reviewed_merge() -> Steps:
  fresh(Cons{Step{Same{}, Merge{}, No{}}, End{}})

def with_send() -> Steps:
  Cons{Step{Same{}, Send{}, No{}}, End{}}

def with_pay() -> Steps:
  Cons{Step{Same{}, Pay{}, No{}}, End{}}

def with_sign() -> Steps:
  Cons{Step{Same{}, Sign{}, No{}}, End{}}

def early_card() -> Steps:
  card()

def stale_card() -> Steps:
  fresh(write(card()))

def stale_merge() -> Steps:
  fresh(write(Cons{Step{Same{}, Merge{}, No{}}, End{}}))

def stale_pair() -> Nat & Nat:
  a b = card_ok(stale_card(), 0n, Normal{}) merge_ok(stale_merge(), 0n, Normal{})
  (a, b)

def irreversible_clean() -> (Nat & Nat) & (Nat & Nat):
  a b = clean(with_send(), Critical{}) clean(with_pay(), Critical{})
  c d = clean(with_sign(), Critical{}) clean(fresh(Cons{Step{Same{}, Send{}, No{}}, Cons{Step{Same{}, Merge{}, No{}}, End{}}}), Critical{})
  ((a, b), (c, d))

def variant_merge() -> Steps:
  variant(Cons{Step{Same{}, Merge{}, No{}}, End{}})

def variant_card() -> Steps:
  read(variant(card()))

def self_merge() -> Steps:
  self_check(Cons{Step{Same{}, Merge{}, No{}}, End{}})

def self_card() -> Steps:
  read(self_check(card()))

# Two tiers: a Variant verify passes a Normal trace and fails a Critical one.
def tiers() -> (Nat & Nat) & (Nat & Nat):
  a b = merge_ok(variant_merge(), 0n, Normal{}) merge_ok(variant_merge(), 0n, Critical{})
  c d = card_ok(variant_card(), 0n, Normal{}) card_ok(variant_card(), 0n, Critical{})
  ((a, b), (c, d))

# A self check (Same) never counts, in either tier.
def self_never() -> (Nat & Nat) & (Nat & Nat):
  a b = merge_ok(self_merge(), 0n, Normal{}) merge_ok(self_merge(), 0n, Critical{})
  c d = card_ok(self_card(), 0n, Normal{}) card_ok(self_card(), 0n, Critical{})
  ((a, b), (c, d))

# A Fresh verify counts in the Critical tier.
def fresh_critical() -> Nat & Nat:
  a b = merge_ok(reviewed_merge(), 0n, Critical{}) clean(read(fresh(card())), Critical{})
  (a, b)

def early_write() -> Steps:
  write(read(End{}))

def pair(x: Steps, y: Steps) -> Nat & Nat:
  a b = clean(x, Normal{}) clean(y, Normal{})
  (a, b)

def bundle() -> (Nat & Nat) & (Nat & Nat):
  left right = pair(craft(), rule()) pair(eva(), mine())
  (left, right)

def capture_pair() -> Nat & Nat:
  a b = clean(capture(), Normal{}) writes_ok(capture())
  (a, b)

def merge_pair() -> Nat & Nat:
  a b = merge_ok(bare_merge(), 0n, Critical{}) merge_ok(reviewed_merge(), 0n, Critical{})
  (a, b)

def harm_pair(x: Steps, y: Steps) -> Nat & Nat:
  a b = any_bad(x) any_bad(y)
  (a, b)

def sign_and_card() -> Nat & Nat:
  a b = any_bad(with_sign()) card_ok(early_card(), 0n, Normal{})
  (a, b)

def harm() -> (Nat & Nat) & (Nat & Nat):
  left right = harm_pair(with_send(), with_pay()) sign_and_card()
  (left, right)

def main() -> (Nat & Nat) & (Nat & Nat):
  bundle()
