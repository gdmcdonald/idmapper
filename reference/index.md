# Package index

## Setup

Initialise (or reset) an identity graph for one or more entity types
(e.g. “person”, “project”).

- [`init_id_envs()`](https://gdmcdonald.github.io/idmapper/reference/init_id_envs.md)
  : Initialise identity graph environments

## Building the identity graph

Tag identifier columns, then add each dataset’s identifiers - and their
co-occurrences - to the graph.

- [`mark_id()`](https://gdmcdonald.github.io/idmapper/reference/mark_id.md)
  : Mark identity columns for entity resolution
- [`add_to_identity_graph()`](https://gdmcdonald.github.io/idmapper/reference/add_to_identity_graph.md)
  : Add a marked dataset to its identity graph(s)

## Resolving identities

Collapse the graph’s connected components into master identities, and
retrieve the resulting table.

- [`generate_master_identity_table()`](https://gdmcdonald.github.io/idmapper/reference/generate_master_identity_table.md)
  : Collapse an identity graph into a master identity table
- [`get_master_table()`](https://gdmcdonald.github.io/idmapper/reference/get_master_table.md)
  : Retrieve a previously generated master identity table

## Using resolved identities

Attach a resolved master ID to any marked dataset, or restrict a new
dataset to identities already known to the graph.

- [`join_master_ids()`](https://gdmcdonald.github.io/idmapper/reference/join_master_ids.md)
  : Attach resolved master IDs onto a dataset
- [`filter_by_existing_identities()`](https://gdmcdonald.github.io/idmapper/reference/filter_by_existing_identities.md)
  : Restrict a dataset to rows matching an existing identity graph
