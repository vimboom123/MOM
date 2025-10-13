# Méthode des Moments (MoM) pour l'Analyse d'Antennes Dipôles

Ce dépôt contient des implémentations MATLAB de la **Méthode des Moments (Method of Moments, MoM)** pour l'analyse électromagnétique d'antennes dipôles filaires minces (thin-wire dipole antennas).

## 📋 Vue d'ensemble

La Méthode des Moments est une technique numérique puissante pour résoudre les équations intégrales qui décrivent le comportement électromagnétique des antennes. Ce projet fournit deux implémentations différentes de la MoM avec des documentations détaillées en français.

### Principe de base

Pour analyser une antenne dipôle, nous devons résoudre l'équation intégrale de Pocklington qui relie le courant inconnu sur l'antenne au champ électrique excitateur. La MoM transforme cette équation complexe en un système d'équations linéaires :

$$[Z][I] = [V]$$

où :
- $[Z]$ est la matrice d'impédance (décrit les interactions entre segments)
- $[I]$ est le vecteur de courant inconnu (ce que nous cherchons)
- $[V]$ est le vecteur d'excitation (la source d'alimentation)

Le processus se décompose en trois étapes :
1. **Discrétisation** : Diviser l'antenne en $N$ segments
2. **Calcul de la matrice** : Calculer les éléments $Z_{mn}$ de la matrice d'impédance
3. **Résolution** : Résoudre le système linéaire pour obtenir la distribution de courant

## 📁 Structure du Projet

### Codes MATLAB

| Fichier | Description |
|---------|-------------|
| [`mom1_fr.m`](mom1_fr.m) | **Implémentation avec fonctions de base impulsionnelles (pulse basis functions)**<br>- Utilise des fonctions de base rectangulaires simples<br>- Intégration numérique directe du noyau de Green<br>- Idéal pour comprendre les bases de la MoM |
| [`mom2.m`](mom2.m) | **Implémentation avec fonctions de base sinusoïdales par morceaux (piecewise sinusoidal basis functions)**<br>- Fonctions de base plus sophistiquées<br>- Meilleure convergence et stabilité numérique<br>- Utilise l'intégration par parties pour simplifier les calculs |

### Documentation

| Fichier | Description |
|---------|-------------|
| [`READMEmom1.md`](READMEmom1.md) | **Documentation détaillée de `mom1_fr.m`**<br>- Explication ligne par ligne du code<br>- Correspondance avec la théorie électromagnétique<br>- Explication de la syntaxe MATLAB pour débutants |
| [`READMEmom2.md`](READMEmom2.md) | **Documentation détaillée de `mom2.m`**<br>- Explication de l'approche avec fonctions sinusoïdales<br>- Dérivation des formules d'impédance<br>- Guide d'implémentation numérique |

## 🚀 Utilisation

### Prérequis

- MATLAB (R2016b ou plus récent recommandé)
- Aucune toolbox spécifique requise

### Exécution rapide

1. Clonez ce dépôt :
```bash
git clone https://github.com/vimboom123/MOM.git
cd MOM
```

2. Ouvrez MATLAB et lancez l'un des scripts :
```matlab
% Pour l'implémentation avec fonctions impulsionnelles
run('mom1_fr.m')

% Pour l'implémentation avec fonctions sinusoïdales
run('mom2.m')
```

3. Les scripts génèrent automatiquement :
   - Distribution du courant le long de l'antenne
   - Impédance d'entrée pour différentes discrétisations
   - Graphiques de convergence

## 📊 Exemples de Résultats

Les deux implémentations calculent la distribution de courant pour différents niveaux de discrétisation (N=7, 17, 27 segments) afin de vérifier la convergence numérique.

### Paramètres typiques
- Fréquence : 300 MHz (λ = 1 m)
- Longueur de l'antenne : 0.47λ (proche de la résonance demi-onde)
- Rayon du fil : 0.005λ (condition thin-wire)
- Tension d'alimentation : 1V (modèle delta-gap)

## 📚 Concepts théoriques

### Équation de Pocklington

L'équation intégrale à résoudre :

$$\int_{-l/2}^{l/2} I_z(z') \left( k^2 + \frac{\partial^2}{\partial z^2} \right) G(R) dz' = -j\omega\epsilon E_z^a(\rho=a)$$

où :
- $G(R) = \frac{e^{-jkR}}{4\pi R}$ est la fonction de Green
- $R = \sqrt{a^2 + (z-z')^2}$ est la distance source-observation
- $k = 2\pi/\lambda$ est le nombre d'onde

### Méthode des Moments

1. **Décomposition du courant** :
   $$I_z(z') \approx \sum_{n=1}^{N} I_n f_n(z')$$

2. **Projection de Galerkin** ou **Point-Matching** :
   - `mom1_fr.m` : Point-matching avec fonctions test de Dirac
   - `mom2.m` : Fonctions test rectangulaires avec base sinusoïdale

3. **Calcul des éléments de matrice** :
   - Intégration numérique pour chaque paire de segments
   - Traitement spécial pour l'auto-impédance (m=n)

## 🔧 Différences entre les deux implémentations

| Aspect | mom1_fr.m | mom2.m |
|--------|-----------|--------|
| **Fonctions de base** | Impulsionnelles (rectangulaires) | Sinusoïdales par morceaux |
| **Complexité** | Plus simple à comprendre | Plus sophistiqué |
| **Convergence** | Standard | Meilleure convergence |
| **Calcul** | Intégration directe | Intégration par parties |
| **Taille matrice** | N × N | (N-1) × (N-1) |
| **Conditions limites** | Implicites | Explicites (I=0 aux extrémités) |

## 🎓 Ressources pédagogiques

Ces codes ont été développés dans un contexte pédagogique pour :
- Comprendre les fondements de la MoM
- Apprendre la programmation numérique en électromagnétisme
- Visualiser la convergence des méthodes numériques
- Comparer différentes approches de discrétisation

## 📖 Pour aller plus loin

Consultez les fichiers de documentation détaillés :
- [`READMEmom1.md`](READMEmom1.md) pour une introduction complète avec explications ligne par ligne
- [`READMEmom2.md`](READMEmom2.md) pour comprendre l'approche avancée avec fonctions sinusoïdales

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
- Signaler des bugs
- Proposer des améliorations
- Ajouter de nouvelles fonctionnalités
- Améliorer la documentation

## 📝 Licence

Ce projet est fourni à des fins éducatives.

## 👤 Auteur

Développé dans le cadre d'un projet académique sur les méthodes numériques en électromagnétisme.

---

**Note** : Pour une compréhension complète, il est recommandé de commencer par `mom1_fr.m` et sa documentation [`READMEmom1.md`](READMEmom1.md), puis de progresser vers `mom2.m` une fois les concepts de base maîtrisés.
