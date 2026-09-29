# cDigraphAnalysis Guide

`cDigraphAnalysis` analyzes the structure of a directed graph represented by an adjacency matrix. It is especially useful in TaesLab for studying process connectivity, identifying strongly connected components, and simplifying complex process networks into a condensed kernel representation.

The class is used when the productive structure of a plant is already encoded as a graph and the analysis needs to determine cycles, topological ordering, reachability, and kernel-level structure before downstream thermoeconomic computation.

## 1. Class purpose and objective

The class is focused on structural graph analysis rather than numerical simulation. Its main goals are:

- detect strongly connected components (SCCs) in a directed graph
- build a topological order of the graph
- analyze and simplify cyclic dependencies into an acyclic kernel graph
- recover graph tables for nodes and edges
- compute transitive reachability or closure information
- support process-system interpretation in the TaesLab productive topology layer

This is particularly relevant when a system contains feedback loops or interdependent process nodes. The class condenses those loops into SCCs and exposes the remaining dependency structure in a clearer representation.

### Typical use cases

- analyzing industrial process networks for circular dependencies
- identifying feedback loops in productive structures
- ordering the process graph before matrix-based calculations
- reducing large cyclic graphs into a smaller kernel representation
- building node and edge tables for visualization or diagnostics

## 2. Input parameters

The constructor signature is:

```matlab
obj = cDigraphAnalysis(tfp, names)
```

### Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `tfp` | matrix | Square adjacency matrix in FP (fuel-product) format. Represents directed edges between process nodes. |
| `names` | cell array or string array | Optional labels for the nodes. If omitted, default names are generated as `N1`, `N2`, ..., `Nn`. |

### Expected matrix format

- `tfp` is a square matrix of size `N x N`
- each entry indicates whether a directed relation exists from one node to another
- the matrix is expected to be non-negative and structurally valid

### Validation rules

The constructor validates:

- the matrix is not negative
- the node names are valid and match the matrix dimensions
- the graph can be converted into the internal SSR representation
- SCC detection succeeds
- kernel graph construction succeeds

If the data are invalid, the object reports an error through the inherited logging mechanism and stops initialization.

## 3. Internal representation and transformed graphs

The class internally converts the input FP matrix into a Source-Sink Representation (SSR) format by adding explicit source and sink nodes.

### Static conversion helpers

- `tfp2ssr(A)`
  - converts the FP matrix into SSR format with explicit `IN` and `OUT` nodes
- `ssr2tfp(G)`
  - converts the SSR matrix back into FP format

This allows the algorithm to handle graph boundaries consistently and later rebuild graph tables without losing the original process topology.

## 4. Output public properties

The class exposes the following public properties:

| Property | Description |
| --- | --- |
| `NrOfGroups` | Number of strongly connected components found in the graph. |
| `NrOfNodes` | Number of nodes in the graph representation used internally. |
| `TopologicalOrder` | Topological order array of the graph, excluding source and sink nodes. |
| `Groups` | Group assignment for each node in the graph, indicating SCC membership. |
| `GroupSize` | Number of nodes belonging to each SCC. |
| `GraphTable` | Reordered graph adjacency matrix in FP format. |
| `GraphNodes` | Ordered node labels for the full graph. |
| `KernelTable` | Kernel graph adjacency matrix (condensed SCC graph). |
| `KernelNodes` | Node labels of the kernel graph, including environment data. |

These properties are computed after graph reduction and topological ordering. They are intended to be read-only from outside the class and are used by higher-level tools that need a condensed or ordered view of the process network.

## 5. Main public methods

### Constructor

```matlab
obj = cDigraphAnalysis(tfp, names)
```

Creates the analysis object and performs the full structural analysis pipeline:

1. validate inputs
2. convert FP matrix into SSR format
3. detect strongly connected components
4. build the kernel graph
5. generate ordered graph and kernel tables

### `isDAG()`

Checks whether the graph is acyclic.

- returns `true` if every node is its own SCC and there are no self-loops
- otherwise returns `false`

### `isProductive()`

Evaluates whether the kernel graph represents a productive system.

- every internal kernel node must have at least one incoming edge and one outgoing edge
- used as a structural productivity check on the condensed system representation

### `getGroupsInfo()`

Returns a struct describing the mapping between each internal node and its SCC group.

### `getGroupIndex()`

Returns the starting index of each group in the ordered node list.

### `getTransitiveClosure(option)`

Computes transitive closure information for the graph.

- if `option` is `KERNEL`, the kernel graph is used
- if the graph is not a DAG, it can reconstruct the full transitive closure from the kernel representation
- result is a reachability matrix showing which nodes can reach which others

### `getNodesTable(option)`

Returns a table of nodes for:

- the full graph
- the kernel graph

The output is a struct with node names and their associated SCC/group values.

### `getEdgesTable(option)`

Returns a table of edges for:

- the full graph
- the kernel graph

The output includes the source node, target node, and edge value.

## 6. Graph analysis strategy

The class uses two complementary structural methods:

### 6.1 Strong component analysis

The internal method `getStrongComponents()` applies Kosaraju’s algorithm using the private helper `dfSC()`.

The process is:

1. compute a post-order traversal on the transpose graph
2. run a second DFS on the original graph using that ordering
3. identify SCCs and assign group membership
4. store the node ordering and group information

This yields a topological grouping of mutually reachable nodes, which is the basis for condensation.

### 6.2 Kernel graph construction

The private method `buildKernelGraph()` creates the condensation graph by collapsing each SCC into a single node.

- for DAGs, the graph is kept as-is and each node is its own group
- for cyclic graphs, a sparse condensation matrix is created
- the kernel graph represents the high-level system structure without internal cyclic detail

This enables the class to reason about process hierarchy while preserving the essential feedback structure.

## 7. Breadth-first reachability algorithm (`bfs`)

The static method `bfs(G, src)` is a multisource algebraic BFS used to compute graph reachability.

The logic is:

```matlab
visited = src;
current = src;
while any(current(:))
    current = (current * G) & ~visited;
    visited = visited | current;
end
res = full(visited);
```

### Meaning

- `src` contains the starting nodes
- `G` is the adjacency matrix
- `current * G` expands the frontier to all directly reachable nodes
- `visited` prevents revisiting already explored nodes
- the loop ends when no new nodes are found

This is a matrix-based way to compute reachability without an explicit queue-based BFS implementation. It is especially useful when working with sparse adjacency matrices and multiple starting nodes.

## 8. Error handling

`cDigraphAnalysis` follows the TaesLab validation style: it checks inputs early and uses the inherited message/error infrastructure instead of relying on ad hoc exceptions.

### Typical conditions that trigger errors

| Condition | Handling |
| --- | --- |
| non-negative matrix check fails | logs `NegativeMatrix` error |
| names are missing or malformed | logs `InvalidNodeNames` |
| SCC analysis fails | logs `InvalidDigraph` |
| graph cannot be ordered or condensed correctly | raises invalid-graph state |

The class uses `printError(...)` and `cMessages` to keep error reporting consistent with the rest of the toolbox.

## 9. Related classes and functions

### Directly related classes

| Class | Relationship |
| --- | --- |
| [../Classes/cProductiveStructure.m](../Classes/cProductiveStructure.m) | Produces the productive graph matrices used to analyze connectivity and reachability. |
| [../Classes/cDiagramFP.m](../Classes/cDiagramFP.m) | Works with FP-table process diagrams and graph visualization. |
| [../Classes/cThermoeconomicModel.m](../Classes/cThermoeconomicModel.m) | Uses structural analysis to underpin thermoeconomic modeling. |
| [../Classes/cTaesLab.m](../Classes/cTaesLab.m) | Base class providing common object behavior and validation. |

### Related helper functions

- `tfp2ssr` and `ssr2tfp` convert between graph representations
- `dfSC` performs one DFS pass for SCC detection
- `buildNodesTable` and `buildEdgesTable` generate human-readable graph summaries
- `tcdag` computes the transitive closure of an ordered DAG

## 10. Summary

`cDigraphAnalysis` is the structural analysis component of TaesLab’s graph layer. It provides a compact, matrix-based method for:

- identifying cycles and process interdependence
- organizing graph nodes by SCC and topological order
- reducing the graph to a kernel DAG for higher-level reasoning
- exposing node/edge tables and reachability information to the rest of the toolbox

The class is designed to be a reusable structural foundation for process analysis, especially in productive and thermoeconomic modeling workflows.
