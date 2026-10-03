import Base

type State is Data:
  Queued{}
  Finished{}

def cancel(state: State) -> State:
  match state:
    case Queued{}: Finished{}
    case Finished{}: Finished{}
