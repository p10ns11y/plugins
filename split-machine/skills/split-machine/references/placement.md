# Placement

Expand only to pick one substrate. The skill file owns the emit.

## Substrates

| id | Put it here when | Act you may name |
|---|---|---|
| `earth-qpu` | a superconducting circuit near 10 mK, or an Earth-bound trapped-ion or neutral-atom processor, with shielding and a calibration window | evolve a state under Ĥ; estimate an observable; decode a syndrome |
| `orbit-link` | entanglement between two stations that will not share a low-loss quantum channel | distribute entanglement; hand a pair to two ground memories |
| `beam-switch` | one classical radio path must stay up while several LEO satellites are in view and the sky is partly blocked | keep one serving path; read the obstruction map; switch the beam |
| `orbit-screen` | two LEO objects may pass too close, and you have observations plus the owner's ephemeris | estimate the trajectory; screen the conjunction; reject a stale miss-distance |
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
| Call a LEO radio handover an entangled pair | `beam-switch` |
| Treat a star tracker as a deep-space telescope, or a quantum measurement | `orbit-screen`, and only inside LEO |
| Hold a conjunction on an hours-old miss-distance after another vehicle may have burned | `orbit-screen`; use the thrusting owner's ephemeris |
| Let a paragraph be the branch condition | `system-one` |
| Automate a closed decision at low confidence | stop; ask |
| Say the quantum computer computed the answer | name the state, the Hamiltonian, the time, and the observable |

## Wording

State = what is true now. Hamiltonian Ĥ = the generator of the state's motion. It may be a schedule Ĥ(t). Scheduling the generator is control. The state is what evolves.

You evolve a state under a Hamiltonian. You do not evolve the Hamiltonian.

Wrong: the quantum computer computed the ground state.

Right: we prepared a state, evolved it under the molecular Hamiltonian, and estimated ⟨Ĥ⟩.

Recipe, when the substrate is `earth-qpu` or `bqp-slice`: encode the problem as Ĥ, prepare the state, evolve for time t, measure. The answer is a statistic of shots, not the wavefunction. A time-dependent drive is part of Ĥ(t), not a second state.

BQP is the yes/no questions a quantum device can answer in polynomial time with a bounded chance of being wrong. P sits inside BQP. BQP sits inside PSPACE. Factoring is in BQP and not known to be in P. Dense linear algebra for a model is not a BQP pitch.

## LEO operations

These two rows are classical. They are not `orbit-link`. Stargaze is not an entanglement link.

`beam-switch` follows the public Starlink beam-switching note. A terminal keeps a live obstruction map and many satellites in view. The serving path changes many times a minute as the pass geometry moves, and the session stays up. A sudden blockage is a reactive switch, fast enough that the published bound is under a tenth of a second. One path is serving. The others are candidates, not a second answer.

`orbit-screen` follows Stargaze, SpaceX's space situational awareness system. Star trackers already used for attitude also record transits of nearby objects. Those observations are aggregated into a position and a velocity. Conjunction screening then runs in minutes, against an industry habit of hours. The published validation scope is low Earth orbit under 2,000 km and a closing rate over 70 m/s. When a vehicle is thrusting, the owner's own ephemeris is the trajectory. The optical track updates only after the burn is seen. A miss-distance from before that burn is not the current risk.

## System One card

The decision the program will branch on is a value from a set written down before the call. Attach `high`, `med`, or `low`.

`low` means do not take the branch. Ask. A later host may fill this card from a System One model. The card stays the interface either way.
