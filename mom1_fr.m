clear;
close all;
clc;

%% 1. Définition des constantes et paramètres du problème

f = 300e6;                      % Fréquence de travail (Hz)
c = 3e8;                        % Vitesse de la lumière (m/s)
lambda = c/f;                   % Longueur d'onde (m)
k = 2*pi/lambda;                % Nombre d'onde (rad/m)
omega = 2*pi*f;                 % Fréquence angulaire (rad/s)
eps0 = 8.854187817e-12;         % Permittivité du vide (F/m)

l = 0.47*lambda;                % Longueur totale du dipôle (m)
a = 0.005*lambda;               % Rayon du fil (m)
Va = 1;                         % Tension d'alimentation (V)

% Définir différents nombres de segments pour comparaison
N_list = [7, 17, 27];
colors = {'r', 'b', [1 0.5 0]}; % Couleurs pour le tracé

fprintf('====================================================\n');
fprintf('Configuration des paramètres physiques :\n');
fprintf('  - Fréquence f = %.0f MHz\n', f/1e6);
fprintf('  - Longueur d''onde lambda = %.3f m\n', lambda);
fprintf('  - Longueur du dipôle l = %.3f m (%.2f * lambda)\n', l, l/lambda);
fprintf('  - Rayon du fil a = %.6f m (%.4f * lambda)\n', a, a/lambda);
fprintf('====================================================\n\n');

%% 2. Préparer un conteneur pour stocker les résultats de chaque calcul

tous_les_resultats = cell(length(N_list), 1);

%% 3. Boucle principale, calcul de différents nombres de segments N

for idx = 1:length(N_list)
    N = N_list(idx);
    Delta = l/N; % Calculer la longueur de chaque segment

    fprintf('\n####################################################\n');
    fprintf('Début du calcul pour N = %d\n', N);
    fprintf('####################################################\n');

    % Étape A : Segmentation de l'antenne (discrétisation)
    z_bords = linspace(-l/2, l/2, N+1).';  % Coordonnées des points limites de chaque segment (N+1 points)
    zc = (z_bords(1:end-1) + z_bords(2:end))/2; % Coordonnées des points centraux de chaque segment (N points)

    % Étape B : Déterminer la position de l'alimentation centrale
    segment_alimentation = (N+1)/2;
    fprintf('  - L''antenne est divisée en %d segments, longueur de chaque segment Delta = %.6f m\n', N, Delta);
    fprintf('  - Point d''alimentation situé au centre du segment %d\n', segment_alimentation);

    % Étape C : Construction de la matrice d'impédance Z (utilisant une double boucle for)
    fprintf('  - Construction de la matrice d''impédance Z de taille %d x %d ...\n', N, N);
    Z = zeros(N, N); % Création d'une matrice de zéros

    for m = 1:N  % m contrôle la ligne, représentant le point d'observation (point de champ)
        zm = zc(m); % Coordonnée du point d'observation actuel

        for n = 1:N  % n contrôle la colonne, représentant le segment d'intégration (point source)
            zn0 = z_bords(n);     % Point de départ du n-ième segment
            zn1 = z_bords(n+1);   % Point de fin du n-ième segment

            % Définir la fonction intégrande, zp est la variable d'intégration
            integrande = @(zp) derivee(zp, zm, a, k);

            % Utiliser la fonction d'intégration intégrée de MATLAB pour l'intégration numérique
            valeur_integrale = integral(integrande, zn0, zn1);

            % Calculer l'élément Z(m,n) de la matrice Z
            Z(m,n) = (1j / (omega * eps0)) * valeur_integrale;
        end
    end
    fprintf('  - Construction de la matrice d''impédance Z terminée.\n');

    % Étape D : Construction du vecteur de tension d'excitation V
    V = zeros(N, 1);
    V(segment_alimentation) = Va / Delta;

    % Étape E : Résolution du système d'équations linéaires Z * I = V, obtenir la distribution de courant I
    fprintf('  - Résolution du système d''équations linéaires Z*I=V ...\n');
    I = Z \ V;
    fprintf('  - Distribution de courant I calculée.\n');

    % Étape F : Calcul de l'impédance d'entrée
    Zin = Va / (I(segment_alimentation) * Delta);
    fprintf('  - Impédance d''entrée Zin = %.2f %+.2fj Ohm\n', real(Zin), imag(Zin));

    % Étape G : Sauvegarder tous les résultats importants de cette itération
    tous_les_resultats{idx}.N = N;
    tous_les_resultats{idx}.zc = zc;
    tous_les_resultats{idx}.I = I;
    tous_les_resultats{idx}.Z = Z;
    tous_les_resultats{idx}.V = V;
    tous_les_resultats{idx}.Zin = Zin;
end

%% 4. Tracé : Comparaison de la distribution de courant pour différents N
%--------------------------------------------------------------------------
figure('Name', 'Distribution de courant du dipôle', 'Position', [100 100 700 550]);
hold on;
grid on;
box on;

for idx = 1:length(N_list)
    N = tous_les_resultats{idx}.N;
    % Déplacer les coordonnées vers l'intervalle [0, l] pour faciliter le tracé
    z_trace = tous_les_resultats{idx}.zc + l/2;
    % Calculer l'amplitude du courant et convertir en mA/m
    I_amplitude = abs(tous_les_resultats{idx}.I) * 1e3;

    plot(z_trace, I_amplitude, 'LineWidth', 2, 'Color', colors{idx}, 'DisplayName', sprintf('N = %d', N));
end

xlabel('Position sur l''antenne z (m)', 'FontSize', 12);
ylabel('Amplitude de la densité de courant |I''(z)| (mA/m)', 'FontSize', 12);
title(sprintf('Distribution de courant de l''antenne dipôle (f = %.0f MHz)', f/1e6), 'FontSize', 14);
legend('show', 'Location', 'south');
xlim([0, l]);
set(gca, 'FontSize', 11);

%% 5. Résumé sous forme de tableau : Comparaison de l'impédance d'entrée pour différents N
%--------------------------------------------------------------------------
fprintf('\n\n====================================================\n');
fprintf('Résumé et comparaison des résultats de calcul\n');
fprintf('====================================================\n');
fprintf(' N \t\t Impédance d''entrée Zin (Ohm) \n');
fprintf('----------------------------------------------------\n');
for idx = 1:length(N_list)
    N = tous_les_resultats{idx}.N;
    Zin = tous_les_resultats{idx}.Zin;
    fprintf(' %-d\t\t %.2f %+.2fj\n', N, real(Zin), imag(Zin));
end
fprintf('====================================================\n');
fprintf('Observation : À mesure que le nombre de segments N augmente, le résultat de l''impédance d''entrée tend à converger.\n');


%% Annexe : Définition de la fonction noyau du problème
%--------------------------------------------------------------------------
function val = derivee(zp, zm, a, k)
    % zp : point source
    % zm : point de champ/point d'observation
    % a  : rayon du fil
    % k  : nombre d'onde
    h = zm - zp;
    R = sqrt(a.^2 + h.^2);

    G = exp(-1j*k*R) ./ (4*pi*R);

    % D'abord, nous construisons le contenu des accolades { ... }
    
    % Premier terme principal : -R^2 * (1 + jkR)
    term1 = -R.^2 .* (1 + 1j*k*R);
    
    % Première partie à l'intérieur des crochets [...] : jkR(z-z')^2
    inner_term_A = 1j*k*R .* h.^2;
    
    % Seconde partie à l'intérieur des crochets [...] : (1+jkR)(3+jkR)(z-z')^2
    inner_term_B = (1 + 1j*k*R) .* (3 + 1j*k*R) .* h.^2;
    
    % On combine pour former le contenu des crochets [...] = A - B
    inner_bracket = inner_term_A - inner_term_B;
    
    % On combine pour former le contenu des accolades {...} = term1 - [...]
    curly_braces_content = term1 - inner_bracket;
    
    % On calcule d2G/dz2 en multipliant par le facteur pré-accolades
    d2G_dz2 = (exp(-1j*k*R) ./ (4*pi*R.^5)) .* curly_braces_content;

    val = k^2 * G + d2G_dz2;
end
