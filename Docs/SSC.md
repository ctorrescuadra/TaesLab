# Strongly connected components and the condensation graph

**Definitions**

Let $G=(V,E)$  be a directed graph with vertices  
$V$  and edges  
$E \subseteq V \times V$ . We denote with  
$n=|V|$  the number of vertices and with  
$m=|E|$  the number of edges in  
$G$ . It is easy to extend all definitions in this article to multigraphs, but we will not focus on that.

A subset of vertices  
$C \subseteq V$  is called a strongly connected component if the following conditions hold:

* $\forall u,v\in C$ , if  
$u \neq v$  there exists a path from  
$u$  to  
$v$  and a path from  
$v$  to  
$u$ , and 
* $C$  is maximal, in the sense that no vertex can be added without violating the above condition.
  
We denote with  
$\text{SCC}(G)$  the set of strongly connected components of  
$G$. These strongly connected components do not intersect with each other, and cover all vertices in the graph. Thus, the set  
$\text{SCC}(G)$  is a partition of  
$V$.

We define the condensation graph  
$G^{\text{SCC}}=(V^{\text{SCC}}, E^{\text{SCC}})$  as follows:

* the vertices of  
$G^{\text{SCC}}$  are the strongly connected components of  
$G$ ; i.e.,  $V^{\text{SCC}} = \text{SCC}(G)$ , and
* for all vertices  
$C_i,C_j$  of the condensation graph, there is an edge from  
$C_i$  to  
$C_j$  if and only if  
$C_i \neq C_j$  and there exist  
$a\in C_i$  and  
$b\in C_j$  such that there is an edge from  
$a$  to  
$b$  in  
$G$.

The most important property of the condensation graph is that it is acyclic. Indeed, there are no 'self-loops' in the condensation graph by definition, and if there were a cycle going through two or more vertices (strongly connected components) in the condensation graph, then due to reachability, the union of these strongly connected components would have to be one strongly connected component itself: contradiction.
