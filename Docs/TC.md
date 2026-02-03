# Transitive closure and M-matrices

Let $A \in \mathbb{R}^{n \times n}$ an non negative matrix such that $\rho(A) < 1$, then I-A is non singular and $L\equiv(I-A)^{-1} is non negative.

Let $G(A)$ the directed graph induced by $A$, defined as $G=(V,E)$ with $V=\{ 1\dots n \}$ and $E=\{ (i,j) : a_{ij}>0 \}$.

Let $TC(A)$ the transitive closure of $G(A)$ defined as $TC(A)=(V,\tilde{E})$ with $\tilde{E}=\{(i,j : i\rightarrow^* j \}$

> **Theorem**
$G(L)$ is equal to the transitive closure of $A$. Or equivalenty $l_{ij} > 0 \quad\Longleftrightarrow\quad i \rightarrow^* j$

*Proof:*

We need to prove that $l_{ij} > 0 \Leftrightarrow i \rightarrow^* j$ in $G(A)$.

Since $L = (I-A)^{-1}$ and $\rho(A) < 1$, we can use the Neumann series expansion:
$$L = (I-A)^{-1} = \sum_{k=0}^{\infty} A^k = I + A + A^2 + A^3 + \cdots$$

Therefore:
$$l_{ij} = \delta_{ij} + a_{ij} + (A^2)_{ij} + (A^3)_{ij} + \cdots$$

where $\delta_{ij}$ is the Kronecker delta.

**($\Rightarrow$)** Suppose $l_{ij} > 0$.

From the series expansion, this means either:

- $i = j$ (from the $\delta_{ij}$ term), which gives $i \rightarrow^* i$ trivially, or
- There exists some $k \geq 1$ such that $(A^k)_{ij} > 0$

If $(A^k)_{ij} > 0$ for some $k \geq 1$, then there exists a path of length $k$ from vertex $i$ to vertex $j$ in $G(A)$. This means $i \rightarrow^* j$.

**($\Leftarrow$)** Suppose $i \rightarrow^* j$ in $G(A)$.

If $i = j$, then $l_{ij} \geq \delta_{ij} = 1 > 0$.

If $i \neq j$, then there exists a path from $i$ to $j$ of some length $k \geq 1$. This means $(A^k)_{ij} > 0$ for this particular $k$. Since all terms in the Neumann series are non-negative, we have:
$$l_{ij} = \delta_{ij} + a_{ij} + (A^2)_{ij} + \cdots + (A^k)_{ij} + \cdots \geq (A^k)_{ij} > 0$$

Therefore, $l_{ij} > 0 \Leftrightarrow i \rightarrow^* j$, which proves that the graph induced by $L$ is exactly the transitive closure of $G(A)$. $\square$

Let $A\in\mathbb{R}^{n \times n}$ a non negative matrix
