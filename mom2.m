

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

% ⚠️ 重要：N = 段（Segment）的数量
% N 表示将天线划分成的物理段（segment）的数量
% 例如：N=7 表示将天线分成 7 个物理段

% Définir les valeurs de N (nombre de segments) à simuler
valeurs_N = [7, 17, 27];  % 7段, 17段, 27段

% Initialiser des tableaux de cellules pour stocker les résultats de chaque simulation
% C'est ici que nous conservons les résultats demandés
Z_matrices = cell(1, length(valeurs_N));
I_vecteurs = cell(1, length(valeurs_N));
z_nodes_stockes = cell(1, length(valeurs_N));
Zin_resultats = cell(1, length(valeurs_N));

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
    % IMPORTANT: Index System for PWS
    % - N segments (物理段数)
    % - N+1 nodes (节点数): z_nodes(1) 到 z_nodes(N+1)
    % - N-1 basis functions (基函数数): 因为节点1和节点N+1的电流=0（边界条件）
    % - 节点索引 n 对应基函数索引 n-1 (节点2→基函数1, 节点3→基函数2, ...)
    delta = l / N;
    z_nodes = linspace(-l/2, l/2, N+1);  % N+1 个节点，索引 1 到 N+1

    % --- 3.2. Calcul de la matrice d'impédance [Z] ---
    % Z 是 (N-1) × (N-1) 矩阵，因为只有 N-1 个基函数
    Z = zeros(N-1, N-1);
    % Définition de la fonction de Green G(R) = exp(-jkR) / (4*pi*R)
    Green = @(R) exp(-1j * k * R) ./ (4 * pi * R);

    fprintf('Calcul de la matrice d''impédance Z (N=%d)...\n', N);

    % ⚠️ 关于 m 和 n 的说明（重要！）
    % m: 测试函数索引 = 矩阵行索引 (1 到 N-1)
    %    - 测试函数数量 = N-1（因为节点1和N+1没有测试函数）
    %    - 测试函数 m 对应节点 m+1（因为节点1没有测试函数）
    % n: 基函数索引 = 矩阵列索引 (1 到 N-1)
    %    - 基函数数量 = N-1（因为节点1和N+1的电流=0，边界条件）
    %    - 基函数 n 对应节点 n+1（因为节点1没有基函数）
    % 
    % 注意：节点数 = N+1，但 m 和 n 的范围是 1 到 N-1（基函数索引）
    
    for m = 1:(N-1)  % m: 行索引，测试函数索引（1 到 N-1）
        % 测试函数 m 对应节点 m+1（因为节点1没有测试函数）
        zm_centre = z_nodes(m+1);  % 节点索引 = m+1
        z_debut = zm_centre - delta/2;
        z_fin = zm_centre + delta/2;
        
        for n = 1:(N-1)  % n: 列索引，基函数索引（1 到 N-1）
            % 基函数 n 跨越节点 n, n+1, n+2
            zn_centre = z_nodes(n+1);    % 节点索引 = n+1（基函数峰值点）
            zn_moins_1 = z_nodes(n);     % 节点索引 = n（左端点）
            zn_plus_1 = z_nodes(n+2);    % 节点索引 = n+2（右端点）
            
            integrande = @(z) Green(sqrt(a^2 + (z - zn_plus_1).^2)) + ...
                              Green(sqrt(a^2 + (z - zn_moins_1).^2)) - ...
                              2 * cos(k*delta) * Green(sqrt(a^2 + (z - zn_centre).^2));
            
            valeur_integrale = integral(integrande, z_debut, z_fin);
            Z(m, n) = valeur_integrale;
        end
    end
    toc; % Arrêter le chronomètre
    
    facteur_const = (1j * k) / (omega * eps0 * sin(k*delta));
    Z_final = facteur_const * Z;

    % --- 3.3. Calcul du vecteur d'excitation [V] ---
    % V 是 (N-1) × 1 向量，对应 N-1 个基函数
    V = zeros(N-1, 1);
    
    % 索引转换说明（以 N=7 为例）：
    % - 节点索引：1, 2, 3, 4, 5, 6, 7, 8（共 8 个节点）
    % - 基函数索引：1, 2, 3, 4, 5, 6（共 6 个基函数）
    % - 中心节点 = (7+1)/2 = 4（节点索引）
    % - 对应基函数 = 4-1 = 3（基函数索引）
    % - 因此：V(3) = Vs（使用基函数索引）
    
    noeud_central = (N+1)/2;        % 中心节点索引 (1 到 N+1)
    indice_base = noeud_central - 1; % 转换为基函数索引 (1 到 N-1)
    V(indice_base) = Vs;             % 在对应的基函数上施加激励

    % --- 3.4. Résolution pour la distribution de courant [I] ---
    fprintf('Résolution du système linéaire...\n');
    I_coeffs = Z_final \ V;  % I_coeffs 是 (N-1) × 1，基函数系数
    
    % 将基函数系数转换为节点电流
    % I_coeffs(1..N-1) 对应节点 2..N 的电流
    % 节点 1 和节点 N+1 的电流 = 0（边界条件）
    I = [0; I_coeffs; 0];  % I 是 (N+1) × 1，节点电流（索引 1 到 N+1）
    
    % --- 3.5. Calcul de l'impédance d'entrée Zin ---
    % I 是节点电流向量，使用节点索引访问
    I_centre = I(noeud_central);  % 使用节点索引（不是基函数索引！）
    Zin = Vs / I_centre;          % Impédance d'entrée
    fprintf('  - Impédance d''entrée Zin = %.2f %+.2fj Ohm\n', real(Zin), imag(Zin));
    
    % --- 3.6. STOCKAGE DES RÉSULTATS ---
    Z_matrices{i} = Z_final;
    I_vecteurs{i} = I;
    z_nodes_stockes{i} = z_nodes;
    Zin_resultats{i} = Zin; % Stocker Zin pour comparaison
    
    % --- 3.7. Tracé des résultats pour la valeur actuelle de N ---
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

%% --- 5. Résumé : Comparaison de l'impédance d'entrée pour différents N ---
fprintf('\n====================================================\n');
fprintf('Résumé : Comparaison de l''impédance d''entrée Zin\n');
fprintf('====================================================\n');
fprintf(' N \t\t Impédance d''entrée Zin (Ohm) \n');
fprintf('----------------------------------------------------\n');
for i = 1:length(valeurs_N)
    N = valeurs_N(i);
    Zin = Zin_resultats{i};
    fprintf(' %-d\t\t %.2f %+.2fj\n', N, real(Zin), imag(Zin));
end
fprintf('====================================================\n');
fprintf('Observation : À mesure que le nombre de segments N augmente, l''impédance d''entrée tend à converger.\n');