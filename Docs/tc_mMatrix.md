# M-Matrices y Grafos Dirigidos

## Transitive Closure

A path of graph $G=(V,E)$ is a sequence of vertex $\left(v_1,v_2,...,v_k\right)$ such that $\left(v_i,v_{i+1}\right) \in E,\; i=1,\dots,k-1$, and it's represented as $i \leadsto j$

The transitive closure of a directed graph $G=(V,E)$ is a graph $TC(G)=(V,F)$ that represents all reachability relationships, where an edge $(v,w)$ exists in $F$ if and only if there is a path from $v$ to $w$ in $G$. It converts all reachable nodes into direct successors, often represented as a boolean matrix where $TC(i,j)=1$ indicates a path from $i$ to $j$

### Key Aspects of Transitive Closure

* Definition: If node $A$ can reach $B$, and $B$ can reach $C$, the transitive closure adds an edge directly from $A$ to $C$.
* Reachability Matrix: For a graph with $n$ vertices, the closure is an $n\times n$ matrix $T$, where $T(i,j)=1$ if a path of length $\ge 0$ exists from vertex $i$ to vertex $j$.

* Algorithms: The standard approach is Warshall's Algorithm, which uses dynamic programming to construct the closure in $O(V^{3})$ time.

## Warshall's Algorithm

The Warshall Algorithm in MATLAB is:

```matlab
n = size(A,1)
TC = A;
for k = 1:size(A,1)
    % Update reachability: can reach j from i if either:
    % - Direct path i→j exists, OR
    % - Path i→k exists AND path k→j exists
    TC = res | (TC(:, k) & TC(k, :));
end
TC = eye(size(A)) + TC;  
```

## M-Matrices

Sea $A$ una matriz asociada a un grafo dirigido que verifica:

* $A \ge 0$,
* $\rho(A) < 1$,
  
Entonces:

* $I-A$ es una *M-matriz no singular* y su inversa es no-negativa.
* $L\equiv(I-A)^{-1} \ge 0$,

entonces se cumple:

$$
(I-A)^{-1} = \sum_{k=0}^{\infty} A^k
\quad\text{(convergencia monótona)}
$$

## Relación con el cerramiento transitivo

El cerramiento transitivo de un grafo $G(V,E)$ es otro grafo $TC(G)=G(V,E')$ donde el conjunto de sus aristas $E'=\lbrace(i,j)\;|\; i \leadsto j \rbrace$.
Utilizando la definición de matriz de incidencia: $i \leadsto j \Longleftrightarrow \exists\,k \ge 0 : \tilde{A}^k_{ij} > 0$, donde $A^k$ representa a los paths de longitud $k$ en el grafo.

En ese caso, si existe un camino entre dos nodos del grafo $i$ y $j$, entonces la entrada $l_{ij}$ de la matriz $L$ es positiva.

$$l_{ij} > 0 \quad\Longleftrightarrow\quad i \leadsto j$$

> El soporte o patrón de positividad de $(I-A)^{-1}$ coincide exactamente con el cerramiento transitivo del grafo dirigido asociado a $A$, incluyendo la reflexividad, ya que $k=0$ aporta la identidad.

---

## Modelo Productivo

Sea $A \ge 0$ la matriz de consumos de un modelo productivo, entonces:

1. I-A es una M-matriz no singular
2. $\rho(A)<1$
3. $(I-A)^{-1} \ge 0$

De esta relacción solo podemos deducir que, para un vector de demanda $w\ge0$:
$$
x = (I-A)^{-1}\,w \ge 0.
$$

Para tener *positividad estricta* $(x>0)$, necesitarías en general:

* $b>0$,
* $(I-A)^{-1}$ estrictamente positiva,

y ninguna de las dos está garantizada *a priori*.

Ahora bien, la hipótesis de que el grafo es (SSR) *Source–Sink Reachable* implica:

Para todo nodo $i$, existe al menos un nodo $j$ con $deg^{-}(j)=0$, es decir un nodo de demanda final (sumidero) tal que:

> * $w_j > 0$ (demanda final),
> * Existe un camino $i \leadsto j$,
> * $l_{ij}>0$

Por lo tanto:
$$
  x_i = l_{ij}\, w_j \;>\; 0, \forall i
$$

---

### Interpretación económica

* El grafo SSR garantiza que *toda actividad productiva está conectada*, directa o indirectamente, con una fuente de demanda final o un sumidero.
* No existen *circuitos cerrados improductivos* capaces de sostener producción sin demanda.
* La positividad estricta de $x$ no es un artefacto algebraico:
  es la traducción de que *todo sector participa en al menos una cadena productiva viable*.
