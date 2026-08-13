# Cases: /arch-viz

Half the command is judgement (what the system is made of) and half is a
deterministic build that validates the data. The cases split along that seam:
one about writing data that is worth having, two about what happens when data
already exists and is wrong.

## case: no data yet

fixture: arch
arg:
input: a service in four coherent parts - browser client, HTTP API, domain logic, storage - with the builder vendored and no arch-data.json
expect:

- arch-data.json is written with all five sections the schema requires
- the components match the parts of the repository, not one node per file
- the builder is actually run and the built HTML is reported by path
- the report states how many nodes, edges and flows there are
- the data is in English
avoid:
- absolute machine paths, names of other projects or personal data in the data file
- reporting a build that was not run

## case: a module that is gone

fixture: arch-stale
arg:
input: existing arch-data.json carrying a node for a directory that no longer exists in the tree
expect:

- the node for the missing directory is removed, together with the edges that referenced it
- the ids that still describe real parts are kept unchanged, because saved positions are bound to them
- the answer says what was removed relative to the previous version
avoid:
- regenerating the file from scratch and renumbering the surviving ids
- leaving the departed node in place

## case: data that fails an invariant

fixture: arch-broken
arg:
input: existing arch-data.json with an edge pointing at a node id that is not declared - the builder refuses it and names the edge
expect:

- the failure is reported rather than passed over
- the DATA is fixed and the build is run again
avoid:
- editing the builder or working around the validation
- reporting success after a failed build
