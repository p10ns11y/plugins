# Placement

Expand only to pick one substrate. The skill file owns the emit.

## Substrates

| id | Put it here when | Act you may name |
|---|---|---|
| `earth-qpu` | 10 mK, heavy shielding, a circuit, a calibration window, local fiber to the cluster | evolve a state under Ĥ; estimate an observable; decode a syndrome |
| `orbit-link` | vacuum, line-of-sight, free-fall, or entanglement between stations that will never share low-loss fiber | distribute entanglement; hand a pair to two ground memories |
| `gpu-factory` | dense matmul, training, token serving, KV cache, or a millisecond loop with the cluster | train; serve; compile; decode classically |
| `bqp-slice` | chemistry or materials as quantum systems, factoring-class number theory, a quantum kernel, a QUBO/Ising inner loop, or structured sampling that can wait | decide a BQP instance; evolve under the problem Hamiltonian; sample |
| `system-one` | the consumer is code, the answers are a closed set, and many questions can be asked independently | emit a typed decision and a confidence |
| `system-two` | a person must read the words: a plan, code, or prose | write the string; a system-one check may score it afterwards |

## Where it does not go

| Temptation | Refuse |
|---|---|
| Train or serve a dense model on a QPU | `gpu-factory` |
| Call NISQ production inference | `gpu-factory` for the tokens; quantum stays a specialist coprocessor |
| Fly the dilution refrigerator | `earth-qpu` for the processor, `orbit-link` for the entanglement |
| Let a paragraph be the branch condition | `system-one` |
| Automate a closed decision at low confidence | stop; ask |
| Say the quantum computer computed the answer | name the state, the Hamiltonian, the time, and the observable |

## Wording

State = what is true now. Hamiltonian Ĥ = the energy law that generates the next instant.

You evolve a state under a Hamiltonian. You do not evolve the Hamiltonian.

Wrong: the quantum computer computed the ground state.

Right: we evolved the state under the molecular Hamiltonian and estimated ⟨Ĥ⟩.

Recipe, when the substrate is `earth-qpu` or `bqp-slice`: encode the problem as Ĥ, prepare the state, evolve for time t, measure. The answer is a statistic of shots, not the wavefunction.

BQP is the yes/no questions a quantum device can answer in polynomial time with a bounded chance of being wrong. P sits inside BQP. BQP sits inside PSPACE. Factoring is in BQP and not known to be in P. Dense linear algebra for a model is not a BQP pitch.

## System One card

The decision the program will branch on is a value from a set written down before the call. Attach `high`, `med`, or `low`.

`low` means do not take the branch. Ask. A later host may fill this card from a System One model. The card stays the interface either way.
