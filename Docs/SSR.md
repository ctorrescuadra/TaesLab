
# Productive Digraphs

## Digraph Definitions

> **Definition (Directed Graph)**
> A *directed graph* is a pair $G=(V,E)$ consisting of a non-empty set of vertices $V$ and a set of directed edges with $E\subseteq V \times V$.

> **Definition (in-degree)**
> The *in-degree* of a vertex $v$ in a directed graph $G=(V,E)$ is the number of edges that have $v$ as their terminal vertex. Formally, $\deg^{-}(v) = |\{u \in V : (u,v) \in E\}|$.

> **Definition (out-degree)**
> The *out-degree* of a vertex $v$ in a directed graph $G=(V,E)$ is the number of edges that have $v$ as their initial vertex. Formally, $\deg^{+}(v) = |\{u \in V : (v,u) \in E\}|$.

> **Definition (sources set)**
The *sources set* of a graph is the set of vertex has no input edges. Formally, $S=\lbrace s\in V : deg^{+}(s)=0\rbrace$

> **Definition (sinks set)**
The *sinks set* of a graph is the set of the vertex has not output edges. Formally, $T=\lbrace s\in V : deg^{-}(s)=0\rbrace$

> **Definition (Path)**
> A *path* in a directed graph $G=(V,E)$ is a sequence of vertices $v_1, v_2, \ldots, v_k$ where $(v_i, v_{i+1}) \in E$ for all $i = 1, 2, \ldots, k-1$. The length of the path is $k-1$ (the number of edges).

> **Definition (Directed Path)**
> A *directed path* from vertex $u$ to vertex $v$ in a directed graph $G=(V,E)$ is a path that starts at $u$ and ends at $v$. We denote this as $u \rightarrow^* v$. Then we says $u$ reaches $v$.

> **Definition (Simple Path)**
> A *simple path* is a path in which all vertices are distinct (no vertex is visited more than once).

## Source-Sink Reachable directed graph (SSR)

> **Definition (Source-Sink-Reachable graph)**
> A directed graph $G=(V,E)$ is called *source-sink reacheble* if it satisfies:
> 
> * For every \(v \in V\), there exists at least one $s \in S$ such that there is a directed path from $s$ to  $v$ (i.e., \(s \rightarrow^* v\)).
> * For every \( v \in V \), there exists at least one \( t \in T \) such that there is a directed path from $v$ to $t$ (i.e., \( v \rightarrow^* t \)).

### Input-Output Analysis Application

Let consider a Input-Output model, which is represented by a directed graph, $G = (V, E)$ where the *source* nodes are the system resources and the *sink* nodes are the final demand,
and $A$ its non-negative production matrix.

> If the direct graph of an input-output model is **source-sink reachable**, then its production matrix $A$ satisfies:
>
>* \( \rho(A) < 1 \),
>* \( I - A \) is nonsingular,
>* \( (I - A)^{-1} > 0 \).

This guarantees that:

* Every unit of external demand $d \geq 0$ generates a *finite, well-distributed total output* $$x = (I - A)^{-1} d  > 0$$
* The system is *economically feasible* and *stable*.