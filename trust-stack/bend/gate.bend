import Base

type Layer is Data:
  Shape{}
  Check{}
  Watch{}
  Skill{}
  Guide{}

type Verdict is Data:
  Hold{}
  Ask{}

def gate(layer: Layer) -> Verdict:
  match layer:
    case Shape{}:
      Hold{}
    case Check{}:
      Hold{}
    case Watch{}:
      Hold{}
    case Skill{}:
      Hold{}
    case Guide{}:
      Ask{}

def cap4(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      match p:
        case 0n:
          1n
        case 1n+q:
          match q:
            case 0n:
              2n
            case 1n+r:
              match r:
                case 0n:
                  3n
                case 1n+_:
                  4n
