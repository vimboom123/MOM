% =========================================================================
%         ANALYSE D'UNE ANTENNE DIPÔLE PAR LA MÉTHODE DES MOMENTS
% Utilisation de fonctions de base sinusoïdales et de fonctions test
% =========================================================================

%% --- 1. Définir les paramètres de l'antenne et de la simulation ---
clear; close all; clc;

fprintf('Lancement de la simulation de l''antenne...\n');

% Paramètres de base
f = 300e6;                     % Fréquence (Hz)
c = 3e8;                       % Vitesse de la lumière (m/s)
lambda = c / f;                % Longueur d'onde (m)
l = 0.47 * lambda;             % Longueur totale de l'antenne (m)
a = 0.005 * lambda;            % Rayon du fil de l'antenne (m)

% Constantes physiques
eps0 = 8.854e-12;              % Permittivité du vide (F/m)
k = 2 * pi / lambda;           % Nombre d'onde (rad/m)
omega = 2 * pi * f;            % Fréquence angulaire (rad/s)
Vs = 1;                        % Tension d'alimentation (V), définie à 1V

%% --- 2. Préparation de la boucle et du stockage des résultats ---

% Définir les valeurs de N (nombre de segments) à simuler
valeurs_N = [7, 17, 27];

% Initialiser des tableaux de cellules pour stocker les résultats de chaque simulation
% C'est ici que nous conservons les résultats demandés
Z_matrices = cell(1, length(valeurs_N));
I_vecteurs = cell(1, length(valeurs_N));
z_nodes_stockes = cell(1, length(valeurs_N));

% Créer une nouvelle figure pour tracer tous les résultats
figure('Name', 'Analyse de convergence de la distribution de courant');
hold on; % Permet de superposer plusieurs courbes sur le même graphique

% Définir les couleurs pour les différentes courbes
couleurs = {'r', 'b', 'k'}; % Rouge, Bleu, Noir

%% --- 3. Boucle principale : calcul et tracé pour chaque valeur de N ---
for i = 1:length(valeurs_N)
    N = valeurs_N(i);
    fprintf('\n--- Calcul en cours pour N = %d ---\n', N);

    % --- 3.1. Création du maillage de l'antenne pour N ---
    delta = l / N;
    z_nodes = linspace(-l/2, l/2, N+1);

    % --- 3.2. Calcul de la matrice d'impédance [Z] ---
    Z = zeros(N-1, N-1);
    % Définition de la fonction de Green G(R) = exp(-jkR) / (4*pi*R)
    Green = @(R) exp(-1j * k * R) ./ (4 * pi * R);

    fprintf('Calcul de la matrice d''impédance Z (N=%d)...\n', N);
    tic; % Démarrer le chronomètre
    for m = 1:(N-1)
        zm_centre = z_nodes(m+1);
        z_debut = zm_centre - delta/2;
        z_fin = zm_centre + delta/2;
        
        for n = 1:(N-1)
            zn_centre = z_nodes(n+1);
            zn_moins_1 = z_nodes(n);
            zn_plus_1 = z_nodes(n+2);
            
            integrande = @(z) Green(sqrt(a^2 + (z - zn_plus_1).^2)) + ...
                              Green(sqrt(a^2 + (z - zn_moins_1).^2)) - ...
                              2 * cos(k*delta) * Green(sqrt(a^2 + (z - zn_centre).^2));
            
            valeur_integrale = integral(integrande, z_debut, z_fin, 'ArrayValued', true);
            Z(m, n) = valeur_integrale;
        end
    end
    toc; % Arrêter le chronomètre
    
    facteur_const = (1j * k) / (omega * eps0 * sin(k*delta));
    Z_final = facteur_const * Z;

    % --- 3.3. Calcul du vecteur d'excitation [V] ---
    V = zeros(N-1, 1);
    % Pour un N impair, le point d'alimentation central est à l'indice (N+1)/2
    indice_central = (N+1)/2;
    V(indice_central) = Vs;

    % --- 3.4. Résolution pour la distribution de courant [I] ---
    fprintf('Résolution du système linéaire...\n');
    I_coeffs = Z_final \ V;
    I = [0; I_coeffs; 0]; % Ajouter les zéros aux extrémités (conditions aux limites)
    
    % --- 3.5. STOCKAGE DES RÉSULTATS ---
    Z_matrices{i} = Z_final;
    I_vecteurs{i} = I;
    z_nodes_stockes{i} = z_nodes;
    
    % --- 3.6. Tracé des résultats pour la valeur actuelle de N ---
    % Décalage de l'axe des x pour correspondre au PDF (commençant à 0)
    x_trace = z_nodes + l/2;
    
    % Tracer la courbe
    plot(x_trace, abs(I)*1000, '-o', ...
        'LineWidth', 1.5, ...
        'MarkerSize', 4, ...
        'Color', couleurs{i}, ...
        'DisplayName', sprintf('N = %d', N));
end

%% --- 4. Finalisation du graphique ---
hold off; % Désactiver la superposition des courbes
title('Distribution du courant sur une antenne dipôle (f=300MHz)', 'FontSize', 14);
xlabel('Position sur l''antenne (m)', 'FontSize', 12);
ylabel('Amplitude du courant |I(z)| (mA)', 'FontSize', 12);
grid on;
set(gca, 'FontSize', 12);
xlim([0, l]); % Définir les limites de l'axe des x de 0 à l
legend show; % Afficher la légende

fprintf('\nTous les calculs sont terminés. Le graphique a été généré !\n');