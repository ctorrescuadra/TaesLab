
# M-Matrix Characterization

## Preliminars

### Matrix Norms

>**Definition (Matrix Norm)**
>Let $A \in \mathbb{R}^{n \times n}$ be a matrix. A **matrix norm** is a function $\|\cdot\|: \mathbb{R}^{n \times n} \to \mathbb{R}$ that satisfies:
>
>1. **Non-negativity**: $\|A\| \geq 0$ for all $A$, and $\|A\| = 0$ if and only if $A = 0$
>2. **Homogeneity**: $\|\alpha A\| = |\alpha| \|A\|$ for all scalars $\alpha$
>3. **Triangle inequality**: $\|A + B\| \leq \|A\| + \|B\|$ for all matrices $A, B$
>4. **Submultiplicativity**: $\|AB\| \leq \|A\| \|B\|$ for all matrices $A, B$

Common matrix norms include:

- **Frobenius norm**: $\|A\|_F = \sqrt{\sum_{i,j} |a_{ij}|^2}$
- **Spectral norm**: $\|A\|_2 = \sigma_{\max}(A)$ (largest singular value)
- **1-norm**: $\|A\|_1 = \max_j \sum_i |a_{ij}|$ (maximum column sum)
- **∞-norm**: $\|A\|_\infty = \max_i \sum_j |a_{ij}|$ (maximum row sum)

For non-negative matrices $A \geq 0$, the spectral radius $\rho(A)$ (largest eigenvalue in absolute value) satisfies $\rho(A) \leq \|A\|$ for any matrix norm.

### Eigenvalues and Eigenvectors

>**Definition (Eigenvalues and Eigenvectors)**
>Let $A \in \mathbb{R}^{n \times n}$ be a matrix. A scalar $\lambda$ is called an **eigenvalue** of $A$ if there exists a non-zero vector $v \in \mathbb{R}^n$ such that:
>$$Av = \lambda v$$
>
>The vector $v$ is called an **eigenvector** corresponding to eigenvalue $\lambda$.
>
>The set of all eigenvalues of $A$ is called the **spectrum** of $A$, denoted $\sigma(A)$.
>
>The **spectral radius** of $A$ is defined as:
>$$\rho(A) = \max\{|\lambda| : \lambda \in \sigma(A)\}$$

**Key Properties:**

- The eigenvalues are the roots of the **characteristic polynomial** $\det(A - \lambda I) = 0$
- For a real matrix $A$, complex eigenvalues occur in conjugate pairs
- The spectral radius satisfies $\rho(A) \leq \|A\|$ for any matrix norm $\|\cdot\|$
- For non-negative matrices $A \geq 0$, the Perron-Frobenius theorem guarantees that $\rho(A)$ is an eigenvalue with a corresponding non-negative eigenvector

### Matrix Convergence

>**Definition (Matrix Convergence)**
>Let $\{A_n\}_{n=1}^{\infty}$ be a sequence of matrices in $\mathbb{R}^{m \times p}$. We say that the sequence **converges** to a matrix $A \in \mathbb{R}^{m \times p}$, denoted $\lim_{n \to \infty} A_n = A$ or $A_n \to A$, if:
>$$\lim_{n \to \infty} \|A_n - A\| = 0$$
>
>for some matrix norm $\|\cdot\|$.

**Equivalent characterizations:**

- **Componentwise convergence**: $A_n \to A$ if and only if $(A_n)_{ij} \to A_{ij}$ for all $i,j$
- **Any matrix norm**: Convergence in one matrix norm implies convergence in any other matrix norm (since all matrix norms are equivalent in finite dimensions)

>**Definition (Matrix Series Convergence)**
>An infinite series of matrices $\sum_{k=0}^{\infty} A_k$ **converges** if the sequence of partial sums $S_n = \sum_{k=0}^{n} A_k$ converges to some matrix $S$.

**Key Properties:**

- If $\|A\| < 1$ for some matrix norm, then $\sum_{k=0}^{\infty} A^k$ converges
- The **spectral radius condition**: $\sum_{k=0}^{\infty} A^k$ converges if and only if $\rho(A) < 1$
- **Absolute convergence**: If $\sum_{k=0}^{\infty} \|A_k\|$ converges, then $\sum_{k=0}^{\infty} A_k$ converges

>**Definition (Similar Matrices)**
>Two matrices $A, B \in \mathbb{R}^{n \times n}$ are called **similar** if there exists an invertible matrix $P \in \mathbb{R}^{n \times n}$ such that:
>$$B = P^{-1}AP$$
>
>The transformation $A \mapsto P^{-1}AP$ is called a **similarity transformation**.

**Key Properties:**

- **Eigenvalue preservation**: Similar matrices have identical eigenvalues (same characteristic polynomial)
- **Spectral radius preservation**: $\rho(A) = \rho(B)$ for similar matrices $A$ and $B$
- **Trace preservation**: $\text{tr}(A) = \text{tr}(B)$
- **Determinant preservation**: $\det(A) = \det(B)$
- **Rank preservation**: $\text{rank}(A) = \text{rank}(B)$

**Equivalence relation**: Similarity is an equivalence relation on the set of $n \times n$ matrices:

- **Reflexive**: $A \sim A$ (take $P = I$)
- **Symmetric**: If $A \sim B$, then $B \sim A$
- **Transitive**: If $A \sim B$ and $B \sim C$, then $A \sim C$

**Diagonal similarity**: When $P = \hat{x}$ is a diagonal matrix with positive diagonal entries $x_i > 0$, we have:
$$B = \hat{x}^{-1}A\hat{x}$$
Then both matrices has the same diagonal values. This is particularly important for preserving non-negativity properties when $A \geq 0$.

### Diagonal Dominant Matrices

A diagonal dominant matrix is a square matrix where the absolute value of each diagonal element is greater than or equal to the sum of the absolute values of the other elements in the same row. Formally, a matrix $A \in \mathbb{R}^{n \times n}$ is diagonally dominant if:
$$ |a_{ii}| \ge \sum_{j\neq i} |a_{ij}| \quad \forall i=1,\dots,n$$

There are two types:

- **Strictly diagonally dominant**: The inequality is strict (>) for all rows
- **Weakly diagonally dominant**: The inequality allows equality (≥) for some rows

Diagonal dominance is important in numerical analysis as it guarantees convergence for iterative methods like Jacobi and Gauss-Seidel, and ensures the matrix is non-singular.

## Non-Singular M-Matrix

>**Definition (M-Matrix)**
>A matrix $M \in \mathbb{R}^{n \times n}$ is called an **M-matrix** if it can be written as:
>$$M = sI - A$$
>where $s > 0$ is a positive scalar, $I$ is the identity matrix, and $A \geq 0$ is a non-negative matrix with $\rho(B) \leq s$.

**Equivalent characterizations:**

An $n \times n$ matrix $M$ is an M-matrix if and only if any of the following equivalent conditions hold:

1. **Canonical form**: $M = sI - B$ where $s \geq \rho(B) \geq 0$ and $B \geq 0$
2. **Off-diagonal structure**: $M$ has non-positive off-diagonal entries ($m_{ij} \leq 0$ for $i \neq j$) and all principal minors are positive
3. **Inverse positivity**: $M$ is non-singular and $M^{-1} \geq 0$
4. **Comparison property**: For any $x \geq 0$, if $Mx \geq 0$ then $x \geq 0$

**Types of M-matrices:**

- **Non-singular M-matrix**: When $s > \rho(B)$, ensuring $M$ is invertible
- **Singular M-matrix**: When $s = \rho(B)$, making $M$ singular but still preserving many useful properties
- **Irreducible M-matrix**: When the matrix $B$ in the canonical form is irreducible

**Connection to the previous analysis:**

In the context of our previous theorems, if $A \geq 0$ is a non-negative matrix with $\rho(A) < 1$, then $I - A$ is a non-singular M-matrix. This connects the diagonal dominance and connectivity conditions to the broader theory of M-matrices.

>**Theorem**
>
>If $I-A$ is strictly diagonally dominant, then $I-A$ is non-singular.

*Proof:*

Suppose, for contradiction, that $I-A$ is singular. Then there exists a non-zero vector $x \in \mathbb{R}^n$ such that $(I-A)x = 0$, which gives us $x = Ax$.

Let $j \in \{1, \ldots, n\}$ be an index such that $|x_j| = \max_{1 \leq i \leq n} |x_i| > 0$.

From $x = Ax$, we have:
$$x_j = \sum_{k=1}^n a_{jk} x_k$$

Taking absolute values:
$$|x_j| = \left|\sum_{k=1}^n a_{jk} x_k\right| \leq \sum_{k=1}^n a_{jk} |x_k| \leq \sum_{k=1}^n a_{jk} |x_j| = |x_j| \sum_{k=1}^n a_{jk}$$

Since $|x_j| > 0$, we can divide both sides by $|x_j|$:
$$1 \leq \sum_{k=1}^n a_{jk}$$

However, since $I-A$ is strictly diagonally dominant, we have:
$$\sum_{k=1}^n a_{jk} < 1$$

This gives us the contradiction $1 \leq \sum_{k=1}^n a_{jk} < 1$.

Therefore, $I-A$ must be non-singular. $\square$

Let define $J=\lbrace j : \sum_{k=1}^n a_{jk} < 1\rbrace$ as the set of row index the matrix $I-A$ is strictly diagonally dominant

>**Definition (Weakly Chained Diagonal Dominant Matrix)**
>A matrix $I - A$ where $A \geq 0$ is called a **weakly chained diagonal matrix** if:
>
>1. The set $J = \{j : \sum_{k=1}^n a_{jk} < 1\}$ is non-empty (at least one row is strictly diagonally dominant)
>2. For every index $i_0 \notin J$, there exists a sequence of indices $i_1, i_2, \ldots, i_r$ such that:
>
> - $a_{i_{k-1}, i_k} > 0$ for $k = 1, 2, \ldots, r$ (positive connectivity path)
> - $i_r \in J$ (the path terminates at a strictly diagonally dominant row)

In other words, every row that is not strictly diagonally dominant can be "chained" to a strictly diagonally dominant row through a sequence of positive matrix entries. These matrices are denoted as WCDD

**Intuitive interpretation:**

- Some rows must have strict diagonal dominance ($\sum_{k=1}^n a_{jk} < 1$)
- Rows without strict diagonal dominance must be "reachable" from strictly dominant rows via positive connections
- This creates a weak form of overall stability through local strict dominance and connectivity

**Connection to M-matrices:**
The subsequent theorem shows that weakly chained diagonal matrices of the form $I - A$ are non-singular M-matrices, extending the classical result for strictly diagonally dominant matrices.

**Theorem (Non-singular M-Matrix characterization)**
If $I-A$ is a *weakly chained diagonal dominant matrix* then $I-A$ is not singular.

*Proof:*
We prove this by extending the previous lemma using the connectivity condition.

Suppose, for contradiction, that $I-A$ is singular. Then there exists a non-zero vector $x \in \mathbb{R}^n$ such that $(I-A)x = 0$, giving us $x = Ax$.

Let $j^* \in \{1, \ldots, n\}$ be an index such that $|x_{j^*}| = \max_i |x_i| > 0$.

**Case 1:** If $j^* \in J$, then by the previous lemma's argument, we immediately get a contradiction since $\sum_{k=1}^n a_{j^*k} < 1$ but we need $1 \leq \sum_{k=1}^n a_{j^*k}$.

**Case 2:** If $j^* \notin J$, then $\sum_{k=1}^n a_{j^*k} = 1$.

By the connectivity condition, there exists a sequence of indices $i_1, i_2, \ldots, i_r$ such that:

- $a_{j^*,i_1} > 0$, $a_{i_1,i_2} > 0$, $\ldots$, $a_{i_{r-1},i_r} > 0$
- $i_r \in J$

From $x = Ax$ and the equality case analysis in the previous lemma, for the maximum to be achieved at $j^*$, we need $x_k$ to have the same sign as $x_{j^*}$ whenever $a_{j^*k} > 0$.

Since $a_{j^*,i_1} > 0$, we have $|x_{i_1}| = |x_{j^*}|$ (otherwise the maximum wouldn't be achieved at $j^*$).

Continuing this argument along the path: since $a_{i_1,i_2} > 0$ and $|x_{i_1}| = |x_{j^*}|$ is maximal, we get $|x_{i_2}| = |x_{j^*}|$.

By induction, $|x_{i_r}| = |x_{j^*}|$, so $i_r$ also achieves the maximum.

But now we can apply the argument from Case 1 to $i_r \in J$: since $i_r$ achieves the maximum and $i_r \in J$, we have $\sum_{k=1}^n a_{i_r,k} < 1$, which contradicts the requirement $1 \leq \sum_{k=1}^n a_{i_r,k}$.

Therefore, $I-A$ is non-singular. $\square$

>**Lemma (Neumann Series)**
>
> If $\rho(A) < 1$, then $(I-A)^{-1} = I + A + A^2 + A^3 + \cdots$
>
*Proof:*

Since $\rho(A) < 1$, the spectral radius of $A$ is less than 1, which means all eigenvalues of $A$ have absolute value less than 1. This ensures that the Neumann series converges.

Let $S_n = \sum_{k=0}^{n} A^k = I + A + A^2 + \cdots + A^n$ be the partial sum.

We can verify that:
$$(I-A)S_n = (I-A)(I + A + A^2 + \cdots + A^n) = I - A^{n+1}$$

Similarly:
$$S_n(I-A) = (I + A + A^2 + \cdots + A^n)(I-A) = I - A^{n+1}$$

Since $\rho(A) < 1$, we have $\lim_{n \to \infty} A^{n+1} = 0$. Therefore:
$$\lim_{n \to \infty} (I-A)S_n = \lim_{n \to \infty} (I - A^{n+1}) = I$$
$$\lim_{n \to \infty} S_n(I-A) = \lim_{n \to \infty} (I - A^{n+1}) = I$$

Let $S = \lim_{n \to \infty} S_n = \sum_{k=0}^{\infty} A^k$.

Taking the limit in both equations:
$$(I-A)S = I \quad \text{and} \quad S(I-A) = I$$

This shows that $S = (I-A)^{-1}$, and therefore:
$$(I-A)^{-1} = \sum_{k=0}^{\infty} A^k = I + A + A^2 + A^3 + \cdots \quad \square$$

>**Definition (Monotone Matrix)**
>A matrix $M \in \mathbb{R}^{n \times n}$ is called **monotone** if for all vectors $x, y \in \mathbb{R}^n$:
>$$x \leq y \text{ and } Mx \geq My \implies x = y$$
>
>where the inequalities are understood componentwise.

**Equivalent characterizations:**

A matrix $M$ is monotone if and only if any of the following equivalent conditions hold:

1. **Comparison property**: $M$ is non-singular and $M^{-1} \geq 0$
2. **Sign preservation**: For any $x \in \mathbb{R}^n$, if $Mx \geq 0$ then $x \geq 0$
3. **Order preservation**: $M^{-1}$ preserves the natural partial order, i.e., if $u \leq v$ then $M^{-1}u \leq M^{-1}v$

**Connection to M-matrices:**

Every non-singular M-matrix is monotone. Specifically, if $M = I - A$ and $A \geq 0$, then:
$$ L\equiv(I - A)^{-1} = \sum_{k=0}^{\infty}A^k\geq 0$$

Therefore, $I-A$ satisfies the comparison property and is monotone.

**Applications:**

Monotone matrices are fundamental in:

- Finite difference schemes for partial differential equations
- Comparison theorems for differential equations
- Optimization problems with order constraints
- Economic equilibrium models

>**Corollary (M-Matrix Caracterization)**
>The following properties are equivalent:
>
>- $\rho(A) < 1$
>- $I-A$ is a M-Matrix non-singular and monotone.
>- Exist a vector $x > 0$ and a non-negative matrix $B$ such that $I-B$ is WCDD and $A=\hat{x}\,B\,\hat{x}^{-1}$

*Proof:*

Since $A = \hat{x}B\hat{x}^{-1}$, matrices $A$ and $B$ are similar, which means they have the same eigenvalues:
$$\sigma(A) = \sigma(B) \implies \rho(A) = \rho(B)$$

Since $I-B$ is weakly chained diagonally dominant (WCDD), by the previous theorem, $I-B$ is non-singular. This means $1 \notin \sigma(B)$, so $\det(I-B) \neq 0$.
Since $I-B$ is WCDD and hence non-singular, we must have $\rho(B) < 1$, and conclude that $\rho(A) < 1$**

Since $\rho(A) < 1$ and $A = \hat{x}B\hat{x}^{-1}$ with $B \geq 0$, then $A \geq 0$, therefore $I-A$ a non-singular M-matrix, and $(I-A)^{-1}=\hat{x} (I-B)^{-1} \hat{x}^{-1}$

To check monotonocity of I-A, by the Neumann series lemma:
$$(I-A)^{-1} = \sum_{k=0}^{\infty} A^k$$

Since each $A^k \geq 0$ (as $A \geq 0$), we have $(I-A)^{-1} \geq 0$, which means $I-A$ is monotone.

Therefore, $I-A$ is a non-singular M-matrix that is monotone, and $\rho(A) < 1$. $\square$
