## Global signal bus for Fuseki-related events.
## Add this node as an AutoLoad singleton so signals can be emitted and
## connected from anywhere without needing a direct node reference.

extends Node

## Emitted after all Fuseki queries have completed and FusekiData has been populated.
signal fuseki_data_updated

## Emitted before a new round of Fuseki queries begins, so listeners can clear stale data.
signal fuseki_data_clear
