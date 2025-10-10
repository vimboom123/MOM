# Méthode des Moments (MoM) pour Résoudre l'Antenne Dipôle - Analyse Approfondie du Code MATLAB

## Introduction : Quel est notre objectif ?

Le problème que nous devons résoudre est le suivant : étant donné un fil métallique (antenne dipôle) d'une longueur et d'un rayon spécifiques, avec une tension appliquée au centre, quel sera le courant le long du fil ?

Ce problème peut être exprimé par une **équation intégrale** en utilisant la théorie électromagnétique classique (équation de Pocklington à la page 10 du PPT). Cependant, cette équation est très complexe et ne peut pas être résolue directement avec un crayon et du papier.

C'est pourquoi nous utilisons un ordinateur avec la **Méthode des Moments (Method of Moments, MoM)**. L'idée de base est très simple :

1. **"Découper" (discrétisation)** : Diviser l'antenne continue en `N` segments.
2. **"Calculer" (remplissage de matrice)** : Calculer l'interaction entre chaque petit segment (impédance $Z_{mn}$).
3. **"Résoudre" (système d'équations linéaires)** : Simplifier le problème en un système d'équations linéaires `[Z][I] = [V]` (appris au collège), puis résoudre pour le courant `[I]` dans chaque segment.

Notre code MATLAB est l'outil qui réalise ces trois étapes : "découper, calculer, résoudre".

---

## Première Partie : Préparation (lignes 1-32 du code)

Cette partie du code prépare le calcul principal en définissant tous les paramètres physiques et géométriques nécessaires.

### 1. Nettoyage de l'espace de travail

```matlab
%% CM5 - MoM thin-wire dipole - Version avec syntaxe de base claire
clear;
close all;
clc;
```

- **`Fonction du code`** : C'est le "nettoyage" avant chaque exécution du script.
- **`Explication de la syntaxe`** :
  - `clear;` : Efface toutes les variables précédemment calculées dans l'espace de travail MATLAB (Workspace), comme effacer un tableau noir.
  - `close all;` : Ferme toutes les fenêtres pop-up, comme les graphiques précédents.
  - `clc;` : Efface le texte dans la fenêtre de commande (Command Window).

### 2. Définition des constantes physiques

```matlab
%% 1. Définir les constantes et les paramètres du problème
f = 300e6;                      % Fréquence de travail (Hz)
c = 3e8;                        % Vitesse de la lumière (m/s)
lambda = c/f;                   % Longueur d'onde (m)
k = 2*pi/lambda;                % Nombre d'onde (rad/m)
omega = 2*pi*f;                 % Fréquence angulaire (rad/s)
eps0 = 8.854187817e-12;         % Permittivité du vide (F/m)
```

- **`Fonction du code`** : Définir les constantes physiques de base des ondes électromagnétiques.
- **`Signification physique/mathématique`** :
  - `f` : Fréquence, nous étudions un signal sinusoïdal à 300MHz.
  - `lambda` : Longueur d'onde, `λ = c/f`, la distance parcourue par l'onde électromagnétique pendant une période.
  - `k` : **Nombre d'onde**, un paramètre très important, défini comme $k=2\pi/\lambda$. Il représente la variation de phase (en radians) par mètre de distance. Il apparaît dans toutes les équations d'onde, par exemple l'équation de Helmholtz à la page 5 du PPT $\Delta A_z + k^2 A_z = -\mu j_z$ et la formule du champ électrique à la page 7.
  - `omega` : Fréquence angulaire, $\omega = 2\pi f$. Elle décrit la vitesse de variation de phase dans le temps. À la page 4 du PPT, elle est utilisée pour passer du domaine temporel au domaine fréquentiel (état sinusoïdal permanent).
  - `eps0` : Permittivité du vide $\epsilon_0$, constante physique décrivant les propriétés du champ électrique dans le vide.

### 3. Définition des paramètres de l'antenne

```matlab
l = 0.47*lambda;                % Longueur totale du dipôle (m)
a = 0.005*lambda;               % Rayon du fil (m)
Va = 1;                         % Tension d'alimentation (V)
```

- **`Fonction du code`** : Définir la géométrie de l'antenne étudiée et la source d'excitation.
- **`Signification physique/mathématique`** :
  - `l` : Longueur totale de l'antenne. Nous choisissons une longueur de 0,47 fois la longueur d'onde, une taille typique proche de la résonance à demi-longueur d'onde. Ce `l` correspond à la longueur totale dans tous les schémas d'antenne du PPT.
  - `a` : Rayon du fil. Nous supposons que le fil est "mince" (thin-wire), c'est-à-dire que le rayon `a` est beaucoup plus petit que la longueur d'onde `lambda`. Ce `a` correspond au rayon dans les schémas du PPT.
  - `Va` : Tension appliquée au point d'alimentation au centre de l'antenne, $V_S$.

### 4. Définition des paramètres numériques

```matlab
N_list = [7, 17, 27];
colors = {'r', 'b', [1 0.5 0]};
```

- **`Fonction du code`** : Définir les paramètres du calcul numérique.
- **`Signification physique/mathématique`** :
  - `N_list` : Le cœur de la méthode des moments est de diviser l'antenne en `N` segments. Plus `N` est grand, plus la division est fine, et plus le résultat devrait être précis. Nous utilisons une liste `[7, 17, 27]` pour stocker différentes valeurs de `N`, afin d'effectuer trois calculs, puis de comparer les résultats pour voir si les résultats tendent à se stabiliser à mesure que `N` augmente (ce processus s'appelle **vérification de convergence**). Cela correspond au `N` de la page 11 du PPT et aux paramètres expérimentaux de la page 15.

### 5. Création du conteneur de résultats

```matlab
%% 2. Préparer un conteneur...
all_results = cell(length(N_list), 1);
```

- **`Fonction du code`** : Créer un "meuble" pour stocker les résultats des trois calculs suivants (N=7, 17, 27).
- **`Explication de la syntaxe`** :
  - `length(N_list)` : Calcule la longueur de la liste `N_list`, ici 3.
  - `cell(3, 1)` : Crée un tableau de cellules (Cell Array) de 3 lignes et 1 colonne. C'est comme un meuble avec 3 tiroirs, chaque tiroir `all_results{i}` peut stocker différents types de données (nombres, matrices, vecteurs, etc.).

---

## Deuxième Partie : Boucle de Calcul Principal (lignes 35-85 du code)

C'est le corps du programme, il boucle trois fois, pour chaque valeur de `N`, complétant le processus complet de "découper, calculer, résoudre".

```matlab
for idx = 1:length(N_list)
    % ... corps de la boucle ...
end
```

- **`Fonction du code`** : C'est une boucle `for`, elle fait exécuter le bloc de code interne 3 fois.
- **`Explication de la syntaxe`** : Le compteur de boucle `idx` vaut successivement 1, 2, 3. À l'intérieur de la boucle, nous pouvons accéder aux éléments correspondants de `N_list` et `all_results` via `idx`.

### À l'intérieur de la boucle : Étape A - "Découper" (discrétisation)

```matlab
    N = N_list(idx);
    Delta = l/N;

    z_edges = linspace(-l/2, l/2, N+1).';
    zc = (z_edges(1:end-1) + z_edges(2:end))/2;
```

- **`Fonction du code`** : Réaliser la première étape de la méthode des moments : diviser l'antenne le long de l'axe z en `N` segments de longueur égale.
- **`Explication de la syntaxe`** :
  - `N = N_list(idx)` : Dans la première boucle, `idx=1`, donc `N=N_list(1)`, c'est-à-dire `N=7`. Deuxième fois `N=17`, troisième fois `N=27`.
  - `Delta = l/N` : Calcule la longueur de chaque petit segment $\Delta$.
  - `linspace(start, end, num_points)` : Cette fonction génère `num_points` points équidistants de `start` à `end`.
    - **Exemple** : Si `N=3`, `linspace(-l/2, l/2, 4)` génère 4 points, par exemple `[-0.25, -0.083, 0.083, 0.25]`. Ces 4 points définissent les **frontières** de 3 segments. Cela correspond à $z_0, z_1, ..., z_N$ de la page 17 du PPT.
  - `zc = ...` : Calcule le **point central** de chaque segment. Par exemple, le centre du premier segment est `(z_edges(1) + z_edges(2))/2`.
- **`Signification physique/mathématique`** : Nous transformons une antenne continue en `N` unités discrètes. Nous supposons que le courant sur chaque unité est constant (c'est la **fonction de base impulsionnelle** la plus simple). Nous vérifierons la condition aux limites du champ électrique au point central `zc` (aussi appelé **point de correspondance**) de chaque unité, c'est la **méthode de correspondance ponctuelle (Point-Matching)**.

### À l'intérieur de la boucle : Étape C - "Calculer" (construire la matrice d'impédance Z)

C'est l'étape la plus critique, calculer l'interaction entre tous les petits segments.

```matlab
    Z = zeros(N, N);

    for m = 1:N
        zm = zc(m);
        for n = 1:N
            % ... calcul interne ...
            Z(m,n) = ...;
        end
    end
```

- **`Fonction du code`** : Créer une matrice de zéros N x N `Z`, puis à travers une double boucle `for`, calculer et remplir chaque élément de la matrice $Z_{mn}$ un par un.
- **`Signification physique/mathématique`** :
  - La matrice `Z` est aussi appelée **matrice d'impédance**.
  - `m` : Représente le **numéro de ligne**, correspondant au **point de champ (Field Point)**, c'est-à-dire où nous mesurons le champ électrique au centre de quel segment. `zm = zc(m)` est la coordonnée centrale du `m`-ième segment.
  - `n` : Représente le **numéro de colonne**, correspondant au **point source (Source Point)**, c'est-à-dire quel segment de courant produit l'influence.
  - **Signification physique de $Z_{mn}$** : Représente le champ électrique produit au point central `zm` du `m`-ième segment lorsqu'un courant unitaire circule dans le `n`-ième segment (multiplié par certaines constantes).
    - **Exemple** :
      - **`Z(1,1)`** (`m=1, n=1`) : Calcule l'influence du courant du 1er segment sur le champ électrique au centre du 1er segment. C'est appelé **auto-impédance (Self-Impedance)**.
      - **`Z(1,2)`** (`m=1, n=2`) : Calcule l'influence du courant du 2ème segment sur le champ électrique au centre du 1er segment. C'est appelé **impédance mutuelle (Mutual-Impedance)**.

Maintenant, regardons la couche la plus interne de la boucle :

```matlab
            zn0 = z_edges(n);
            zn1 = z_edges(n+1);

            integrand = @(zp) kernel_p15(zp, zm, a, k);
            integral_value = integral(integrand, zn0, zn1, 'RelTol',1e-8, 'AbsTol',1e-11);

            Z(m,n) = (1j / (omega * eps0)) * integral_value;
```

- **`Fonction du code`** : Ces lignes de code sont l'implémentation programmatique complète de la formule de la page 15 du PPT.
  $$Z_{mn}=\frac{j}{\omega\epsilon}\int_{(n-1)\Delta}^{n\Delta}(k^{2}+\frac{\partial^{2}}{\partial z^{2}})G(R)dz^{\prime}$$
- **`Correspondance entre explication de syntaxe et signification mathématique`** :
  - `zn0` et `zn1` : Définissent les limites inférieure et supérieure de l'intégrale, c'est-à-dire la plage du `n`-ième segment.
  - `integrand = @(zp) kernel_p15(zp, zm, a, k);`
    - `@(zp)` définit une fonction avec `zp` comme variable. `zp` correspond à la variable d'intégration $z'$ dans la formule.
    - `kernel_p15(...)` Cette fonction (nous l'expliquerons en détail plus tard) calcule la partie complexe de la formule $(k^{2}+\frac{\partial^{2}}{\partial z^{2}})G(R)$.
  - `integral_value = integral(...)` :
    - Appelle la fonction `integral` de MATLAB pour intégrer numériquement la fonction `integrand` que nous venons de définir sur l'intervalle `[zn0, zn1]`.
    - `integral_value` est le résultat de $\int ... dz'$ dans la formule.
  - `Z(m,n) = (1j / (omega * eps0)) * integral_value;`
    - Multiplie le résultat de l'intégrale `integral_value` par le facteur constant devant la formule $\frac{j}{\omega\epsilon_0}$.
    - `1j` en MATLAB est l'unité imaginaire $j$.
    - À ce stade, un élément $Z_{mn}$ est calculé et placé à la position `(m,n)` de la matrice `Z`.

### À l'intérieur de la boucle : Étapes D/E/F/G - "Résoudre"

```matlab
    V = zeros(N, 1);
    V(feed_seg) = Va / Delta;

    I = Z \ V;

    Zin = Va / (I(feed_seg) * Delta);

    all_results{idx}.Z = Z; % etc.
```

- **`Fonction du code`** : Construire le vecteur d'excitation `V`, résoudre le courant `I`, calculer l'impédance d'entrée `Zin`, et sauvegarder tous les résultats.
- **`Signification physique/mathématique`** :
  - **Construire le vecteur V** : `V` est le terme connu du côté droit de l'équation `Z*I=V`, représentant l'excitation externe. Selon le modèle "delta-gap" de la page 9 du PPT, l'excitation du champ électrique $E^a_z = V_s/\Delta$ existe seulement à la fente d'alimentation centrale. Notre code `V(feed_seg) = Va/Delta` place cette excitation sur le segment central, les autres segments ayant une excitation de 0.
  - **Résoudre le vecteur I** : `I = Z \ V`. C'est l'une des fonctionnalités de calcul numérique les plus importantes de MATLAB. Il utilise des algorithmes efficaces et stables (comme la décomposition LU) pour résoudre le système d'équations linéaires `Z*I=V`. **Après cette étape, nous avons réussi à obtenir la valeur du courant dans chaque segment de l'antenne !** `I` est un vecteur contenant N éléments, `I(i)` est la valeur de densité de courant sur le `i`-ième segment.
  - **Calculer Zin** : `Zin` est l'un des paramètres les plus importants de l'antenne, l'impédance d'entrée. Elle est égale à la tension d'entrée `Va` divisée par le courant d'entrée. Le courant d'entrée est approximativement égal à la densité de courant du segment central `I(feed_seg)` multipliée par la longueur du segment `Delta`.
  - **Sauvegarder** : Stocker tous les résultats de ce calcul (matrice `Z`, vecteur `V`, vecteur `I`, etc.) dans le `idx`-ième tiroir du "meuble".

---

## Troisième Partie : Annexe - Fonction Noyau `kernel_p15`

```matlab
function val = kernel_p15(zp, zm, a, k)
    h = zm - zp;
    R = sqrt(a.^2 + h.^2);

    G = exp(-1j*k*R) ./ (4*pi*R);
    d2G_dz2 = G .* ( ... );
    val = k^2 * G + d2G_dz2;
end
```

- **`Fonction du code`** : Cette fonction est le "cœur physique" de tout le calcul. Elle calcule la valeur de l'expression complexe $(k^{2}+\frac{\partial^{2}}{\partial z^{2}})G(R)$ à l'intérieur de l'intégrale de $Z_{mn}$.
- **`Signification physique/mathématique`** :
  - `zp` ($z'$) est la position du point source, `zm` ($z$) est la position du point de champ.
  - `R = sqrt(a.^2 + h.^2);` : Calcule la **distance exacte** du point source au point de champ. Notez qu'ici c'est `a^2` et non 0. C'est parce que le point de champ `zm` est à la **surface** de l'antenne (rayon a), tandis que le point source `zp` est approximativement considéré sur l'**axe** de l'antenne. Cela correspond complètement à la figure et à la formule de la page 7 du PPT.
  - `G = ...` : Calcule la valeur de la **fonction de Green**, complètement cohérente avec la formule de la page 5 du PPT. La fonction de Green décrit l'influence d'une source ponctuelle dans l'espace.
  - `val = k^2*G + d2G_dz2;` : Ici, nous n'effectuons pas de différenciation numérique directe, mais utilisons une expression analytique équivalente pré-dérivée pour calculer $(k^{2}G + \frac{\partial^{2}G}{\partial z^{2}})$. Cette approche est plus précise et plus stable que la dérivation directe.

---

## Résumé

J'espère que cette explication est suffisamment approfondie. Nous avons commencé par la syntaxe MATLAB la plus basique et établi un lien clair entre chaque ligne de code et les concepts physiques, les formules mathématiques et les schémas du PPT.

L'ensemble du processus peut être résumé comme suit :

1. **Configurer les paramètres** (fréquence, dimensions de l'antenne).
2. **Entrer dans la boucle** (calculer séparément pour N=7, 17, 27).
3. **Discrétiser** (`linspace`), diviser l'antenne en `N` segments.
4. **Construire la matrice Z** (avec une double boucle `for` et la fonction `integral`), calculer l'interaction entre chaque segment.
5. **Construire le vecteur V** (appliquer l'excitation au point d'alimentation central).
6. **Résoudre `I = Z \ V`**, obtenir la distribution de courant finale `I`.
7. **Sauvegarder les résultats et passer à la boucle suivante**.
8. **Après la fin de la boucle, tracer les graphiques et résumer tous les résultats**.

Si vous avez encore des questions sur une fonction ou un concept spécifique, n'hésitez pas à le signaler, nous pouvons continuer à explorer en profondeur.
