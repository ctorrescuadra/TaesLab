# Kernel & SSR digraphs

Voy paso a paso, conectándolo con **Source–Sink Reachable (SSR)** y con las propiedades espectrales que suelen interesar.

---

## 1. Recordatorio: Source–Sink Reachable (SSR)

Un grafo dirigido (G=(V,E)) es **Source–Sink Reachable** si:

* Existe al menos un **source** (vértice con indegree 0).
* Existe al menos un **sink** (vértice con outdegree 0).
* Para **todo vértice (v)**:

  * existe un camino desde algún source hasta (v), y
  * existe un camino desde (v) hasta algún sink.

Equivalente matricial (muy usado en IO / exergía / (M)-matrices):
[
I - A \text{ es no singular y } (I-A)^{-1} \ge 0
]
cuando (A) es la matriz de adyacencia ponderada.

---

## 2. Definición del **Kernel Graph**

Sea (G=(V,E)) dirigido. Definimos una relación de equivalencia:

[
u \sim v \iff
\begin{cases}
u \leadsto v \
v \leadsto u
\end{cases}
]

Es decir: **mutua alcanzabilidad**.

Las clases de equivalencia inducidas son las **componentes fuertemente conexas (SCCs)**.

### 👉 Kernel Graph (o Condensation Graph)

El **Kernel Graph** (G_K = (V_K, E_K)) se define como:

* (V_K): el conjunto de SCCs de (G)
* Existe una arista dirigida
  [
  C_i \to C_j \quad (i \neq j)
  ]
  si existe al menos una arista (u \to v) en (G) con:
  [
  u \in C_i,\quad v \in C_j
  ]

📌 En teoría de grafos estándar también se llama:

* **condensation graph**
* **quotient graph by SCCs**

---

## 3. Propiedades fundamentales del Kernel Graph

### (P1) Es un DAG

El Kernel Graph **no tiene ciclos dirigidos**.

> Si hubiera un ciclo entre SCCs, entonces todas formarían una SCC mayor.

---

### (P2) Preserva la estructura Source–Sink

Si (G) es **SSR**, entonces el Kernel Graph (G_K):

* Tiene **al menos un source SCC**
* Tiene **al menos un sink SCC**
* Para toda SCC (C):

  * existe un camino desde algún source SCC hasta (C)
  * existe un camino desde (C) hasta algún sink SCC

📌 Es decir:
[
G \text{ es SSR } \iff G_K \text{ es SSR}
]

---

### (P3) Estructura triangular de la matriz

Ordenando las SCCs topológicamente, la matriz de adyacencia queda:

[
A \sim
\begin{pmatrix}
A_{11} & A_{12} & \cdots & A_{1k} \
0      & A_{22} & \cdots & A_{2k} \
\vdots & 0      & \ddots & \vdots \
0      & \cdots & 0      & A_{kk}
\end{pmatrix}
]

* Cada bloque (A_{ii}) es **irreducible**
* El Kernel Graph es el patrón de ceros/no-ceros entre bloques

Esto es clave para:

* (M)-matrices
* positividad de ((I-A)^{-1})
* interpretación económica (subsistemas acoplados en cascada)

---

### (P4) Propiedad espectral

Sea (A) la matriz de adyacencia ponderada.

Entonces:
[
\rho(A) = \max_i \rho(A_{ii})
]

y si (G) es SSR y (\rho(A) < 1), entonces:

* (I - A) es una **(M)-matrix no singular**
* ((I-A)^{-1} > 0)

El Kernel Graph permite **localizar** qué SCC controla el radio espectral.

---

### (P5) Interpretación como “esqueleto causal”

El Kernel Graph es el **esqueleto causal mínimo** del sistema:

* Cada nodo = subsistema internamente realimentado
* Las aristas = dependencias irreversibles entre subsistemas
* No hay feedback global, solo local (dentro de SCCs)

En input–output o exergía:

* los ciclos internos representan reciclaje
* el Kernel Graph representa la cadena de transformación neta

## 4. Definición compacta (lista para un paper)

> **Definition (Kernel Graph).**
> Let G=(V,E) be a directed graph. The Kernel Graph (G_K) is the directed acyclic graph obtained by contracting each strongly connected component of (G) into a single vertex, with edges induced by the original adjacency relation.

> If (G) is Source–Sink Reachable, then \(G_K\) is a Source–Sink Reachable DAG.

[condensated graph](https://cp-algorithms.com/graph/strongly-connected-components.html)


---

## Proposición

Sea (G) un **DAG finito** y sea (A) su **matriz de adyacencia** (ponderada o no).
Entonces:
[
\boxed{\rho(A)=0}
]

---

## Prueba (estructural)

1. Como (G) es un DAG, existe un **orden topológico** de los vértices.
2. En ese orden, la matriz de adyacencia es **estrictamente triangular superior**:
   [
   A =
   \begin{pmatrix}
   0 & * & * & \cdots & * \
   0 & 0 & * & \cdots & * \
   \vdots & \vdots & \ddots & \ddots & \vdots \
   0 & 0 & \cdots & 0 & * \
   0 & 0 & \cdots & 0 & 0
   \end{pmatrix}
   ]
3. Toda matriz estrictamente triangular es **nilpotente**:
   [
   A^k = 0 \quad \text{para algún } k \le |V|
   ]
4. Por tanto, todos los autovalores de (A) son cero, y en consecuencia:
   [
   \rho(A)=0
   ]

✔ Independiente de los pesos
✔ Válido para cualquier DAG finito

---

## Corolario útil (muy en tu línea de trabajo)

Si (G) es un DAG, entonces:
[
(I-A)^{-1} = I + A + A^2 + \cdots + A^{k-1}
]
(con suma finita).

Interpretación:

* no hay realimentación
* no hay amplificación espectral
* solo propagación causal finita

## Conexión con SSR y Kernel Graph

Si (G) es SSR y (G_K) es su **Kernel Graph** (condensación):

* (G_K) es un DAG
* su matriz de adyacencia tiene radio espectral cero
* todo el “riesgo espectral” está en los bloques SCC

---

### Frase lista para paper

> The adjacency matrix of a finite directed acyclic graph is nilpotent and therefore has spectral radius zero.

---
Perfecto — entonces la afirmación es **limpia y totalmente cierta**.

---

## Proposición (caso 1)

Sea (G) un **DAG finito** y sea (A) su **matriz de adyacencia** (ponderada o no).
Entonces:
[
\boxed{\rho(A)=0}
]

---

## Prueba (estructural)

1. Como (G) es un DAG, existe un **orden topológico** de los vértices.
2. En ese orden, la matriz de adyacencia es **estrictamente triangular superior**:
   [
   A =
   \begin{pmatrix}
   0 & * & * & \cdots & * \
   0 & 0 & * & \cdots & * \
   \vdots & \vdots & \ddots & \ddots & \vdots \
   0 & 0 & \cdots & 0 & * \
   0 & 0 & \cdots & 0 & 0
   \end{pmatrix}
   ]
3. Toda matriz estrictamente triangular es **nilpotente**:
   [
   A^k = 0 \quad \text{para algún } k \le |V|
   ]
4. Por tanto, todos los autovalores de (A) son cero, y en consecuencia:
   [
   \rho(A)=0
   ]

✔ Independiente de los pesos
✔ Válido para cualquier DAG finito

---

## Corolario útil (muy en tu línea de trabajo)

Si (G) es un DAG, entonces:
[
(I-A)^{-1} = I + A + A^2 + \cdots + A^{k-1}
]
(con suma finita).

Interpretación:

* no hay realimentación
* no hay amplificación espectral
* solo propagación causal finita

---

## Conexión con SSR y Kernel Graph

Si (G) es SSR y (G_K) es su **Kernel Graph** (condensación):

* (G_K) es un DAG
* su matriz de adyacencia tiene radio espectral cero
* todo el “riesgo espectral” está en los bloques SCC

---

### Frase lista para paper

> The adjacency matrix of a finite directed acyclic graph is nilpotent and therefore has spectral radius zero.

---

Si dispongo de la matriz de incidencia (no ponderada) del cerramiento transitivo de G (Algoritmo de Warsall) como puedo obtener el grafo de condensación.

Premisas:

* (G=(V,E)) dirigido, finito
* Dispones de la **matriz de alcanzabilidad**
  [
  R \in {0,1}^{n\times n}
  ]
  donde
  (R_{ij}=1 \iff i \leadsto j)
  (resultado del algoritmo de Warshall / Floyd–Warshall booleano)
* Incluye la reflexividad: (R_{ii}=1)

(Esto es lo estándar; si no incluye la diagonal, basta añadir (I)).

---

## 1. Paso clave: extraer las SCCs desde (R)

Dos nodos (i,j) están en la **misma componente fuertemente conexa** si y solo si:

[
\boxed{
i \sim j \iff R_{ij}=1 ;\land; R_{ji}=1
}
]

Define la matriz:

[
S = R \land R^\top
]

* (S_{ij}=1) ⇔ (i) y (j) son mutuamente alcanzables
* (S) es la matriz de una **relación de equivalencia**

### Construcción práctica de las SCCs

* Cada **clase de equivalencia** de (S) es una SCC
* Se puede obtener por:

  * búsqueda de componentes conexas en el grafo no dirigido inducido por (S)
  * o unión–búsqueda (Union–Find)

---

## 2. Construcción del grafo de condensación

Sea:

* ({C_1,\dots,C_k}) el conjunto de SCCs
* Queremos el grafo (G_K) cuyos nodos son los (C_i)

### Regla de adyacencia

Existe una arista:
[
C_p \to C_q \quad (p\neq q)
]
si y solo si:
[
\exists, i\in C_p,; j\in C_q
\quad \text{tal que} \quad
R_{ij}=1
]

Es decir: **alcanzabilidad estricta entre clases**.

---

## 3. Forma matricial elegante (sin bucles)

Define una matriz de pertenencia:
[
M \in {0,1}^{n\times k},
\qquad
M_{ic}=1 \iff i\in C_c
]

Entonces la matriz de adyacencia del grafo de condensación es:

[
\boxed{
A_K
===

\operatorname{sgn}!\bigl(
M^\top R M
\bigr)
------

I_k
}
]

donde:

* (\operatorname{sgn}(x)=1) si (x>0), 0 si no
* (I_k) elimina los auto-bucles (alcanzabilidad interna)

✔ Resultado: matriz (0\text{-}1)
✔ El grafo es un DAG automáticamente

---

## 4. Verificación estructural (sanity check)

El resultado debe cumplir:

* (A_K) es **estrictamente triangularizable**
* No hay ciclos:
  [
  A_K^m = 0 \quad \text{para algún } m
  ]
* Las fuentes y sumideros del DAG corresponden a:

  * SCCs sin predecesores
  * SCCs sin sucesores

---

## 5. Observación importante (eficiencia)

* Warshall es (O(n^3))
* Una vez tienes (R):

  * SCCs: (O(n^2))
  * Condensación: (O(n^2))

Así que tu enfoque es **óptimo a posteriori**.

---

## 6. Interpretación conceptual (muy en tu línea)

* (R): clausura causal completa
* (S = R \land R^\top): bucles de reciclaje
* (G_K): esqueleto irreversible del sistema

Todo encaja perfecto con SSR, (M)-matrices y Leontief.

---

## 7. Frase lista para paper

> Given the transitive closure of a directed graph, the condensation graph can be constructed by identifying equivalence classes under mutual reachability and inducing a DAG on these classes via strict reachability.






