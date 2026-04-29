%% MACROECONOMIC TRANSMISSION: EURO AREA VS USA
% WORK IN PROGRESS
% Focus: Inflation (HICP) response to Fiscal (FISC) and Monetary (EGM, IRT3M) Shocks
% Variables: OIL, GDPreal, UR, HICP, FISC, EGM, IRT3M

clear all; close all; clc;
addpath(genpath(pwd));

%% 1. PARAMETERS & SETTINGS
p = 2;              % Lags
H = 20;             % Horizon
c = 1;              % Constant
MaxBoot = 1000;     % Number of bootstrap iterations
confidence = [16 84]; % Confidence bands percentiles (1 standard deviation)

idx_cumulated = [4]; % Index of variables to cumulate (e.g., HICP to level)
idx_cumulated_destructive = 1; % 1: alters actual output IRF, 0: only visual
labels = ["OIL", "GDPreal", "UR", "HICP", "FISC", "EGM", "IRT3M"];
opt = 0; % Set to 0 to suppress individual function plots, custom plots later

%% 2. DATA LOAD & PREP: EURO AREA
% Read Euro Area data (2002q2 -> 2025q3)
X_eu_raw = readmatrix("dataset_eu_BEAR_nodummy.xlsx", "Range", "B2:G95");
gdp_real_eu = readmatrix("dataset_eu.xlsx", "Range", "F90:F184");
t_raw_eu = datetime(2002,6,30) : calmonths(3) : datetime(2025,9,30);

% Assemble EU matrix: OIL, diff(log(GDPreal))*100, UR, HICP, FISC, EGM, IRT3M
X_eu = [X_eu_raw(:,1), diff(log(gdp_real_eu))*100, X_eu_raw(:,[2,3,4,5,6])];

%% 3. DATA LOAD & PREP: USA
% Read USA data
X_usa_raw = readmatrix("dataset_usa.xlsx", "Range", "B130:H318"); % 1979q1 -> 2025q3
t_raw_usa_full = datetime(1979,3,31) : calmonths(3) : datetime(2025,9,30);

% Assemble USA Full Matrix
% FISC is a ratio, converted via diff(log)*100
X_usa_full = [X_usa_raw(2:end, 1:4), diff(log(X_usa_raw(:,5)))*100, X_usa_raw(2:end, 6:7)];

% Subset USA Matrix to match EU timeframe (2002q2 -> 2025q3)
% Ensure indices match your specific dates in the Excel file
idx_usa_start = find(year(t_raw_usa_full)==2002 & month(t_raw_usa_full)==6);
X_usa_match = X_usa_full(idx_usa_start:end, :);

%% 3.5 DIAGNOSTICA DEI MODELLI (Radici e Significatività)
% disp('--- ESECUZIONE DIAGNOSTICA PRE-STIMA ---');
% 
% VAR_Diagnostics(X_eu(1:71,:), p, labels, 'EURO AREA: Pre-2020');
% VAR_Diagnostics(X_eu, p, labels, 'EURO AREA: Full Sample (2002-2025)');
% 
% VAR_Diagnostics(X_usa_match(1:71,:), p, labels, 'USA: Pre-2020 (Matched Window)');
% VAR_Diagnostics(X_usa_match, p, labels, 'USA: Full Sample (Matched Window)');
% 
% % Questo spiegherà l'esplosione che vedevamo nei vecchi grafici!
% VAR_Diagnostics(X_usa_full, p, labels, 'USA: LONG SAMPLE (1979-2025)');

%% 4. VAR ESTIMATION & CHOLESKY IDENTIFICATION
disp('Estimating Euro Area models...');
[irf_eu_pre2020,~,irfboot_eu_pre2020,~,~,~] = CholeskyIdentification(X_eu(1:71,:), p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);
[irf_eu_full,~,irfboot_eu_full,~,~,~]    = CholeskyIdentification(X_eu, p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);

disp('Estimating USA models...');
[irf_usa_pre2020,~,irfboot_usa_pre2020,~,~,~] = CholeskyIdentification(X_usa_match(1:71,:), p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);
[irf_usa_full,~,irfboot_usa_full,~,~,~]    = CholeskyIdentification(X_usa_match, p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);

% Warning: This model might be explosive (check eigenvalues in function)
[irf_usa_long,~,irfboot_usa_long,~,~,~]    = CholeskyIdentification(X_usa_full, p, H, c, MaxBoot, idx_cumulated, idx_cumulated_destructive, labels, opt, '', confidence);

%% 5. PLOTTING: MULTI-REGIME COMPARISON (HICP FOCUS)
figure('Name', 'HICP Response Comparison', 'Position', [100, 100, 1400, 600]);
sgtitle('Responses of HICP to Structural Shocks: Euro Area vs USA', 'FontSize', 16, 'FontWeight', 'bold');

idx_hicp = 4;
shock_indices = 4:7; % Shocks: HICP, FISC, EGM, IRT3M
colors = {'k:', 'k-', 'r:', 'r-', 'r-.'};

for k = 1:length(shock_indices)
    jj = shock_indices(k);
    subplot(1, 4, k);
    
    plot(1:H, squeeze(irf_eu_pre2020(idx_hicp, jj, :)), colors{1}, 'LineWidth', 1.5); hold on;
    plot(1:H, squeeze(irf_eu_full(idx_hicp, jj, :)),    colors{2}, 'LineWidth', 1.5);
    plot(1:H, squeeze(irf_usa_pre2020(idx_hicp, jj, :)),colors{3}, 'LineWidth', 1.5);
    plot(1:H, squeeze(irf_usa_full(idx_hicp, jj, :)),   colors{4}, 'LineWidth', 1.5);
    plot(1:H, squeeze(irf_usa_long(idx_hicp, jj, :)),   colors{5}, 'LineWidth', 1);
    
    yline(0, 'b-', 'LineWidth', 0.5); % Zero line
    axis tight; grid on;
    
    title(['Shock: ', char(labels(jj))]);
    if k == 1
        ylabel(labels(idx_hicp), 'FontWeight', 'bold'); 
    end
end

% Add a single legend at the bottom of the figure
L = legend({"EA: Pre-2020", "EA: 2002-2025", "USA: Pre-2020", "USA: 2002-2025", "USA: 1979-2025"}, ...
    'Orientation', 'horizontal', 'Position', [0.3 0.02 0.4 0.05]);

%% 5.5 VARIANCE DECOMPOSITION (FEVD) - IL TEST PER LE PROXY
disp('--- ESECUZIONE FEVD (Variance Decomposition) ---');
hor_fevd = 1:H; % Vogliamo analizzare tutti i trimestri (da 1 a H)

% Per non far impazzire MATLAB con 100 grafici, testiamo le due finestre 
% più importanti per la tua tesi: L'Eurozona recente e gli USA recenti.

% FEVD per Euro Area (2002-2025)
disp('Calcolo FEVD: Euro Area (2002-2025)');
[vd_eu, vdk_eu] = fevd(irf_eu_full, hor_fevd, irf_eu_full, labels, labels, 1, "EU");

% FEVD per USA (2002-2025)
disp('Calcolo FEVD: USA (2002-2025)');
[vd_usa, vdk_usa] = fevd(irf_usa_full, hor_fevd, irf_usa_full, labels, labels, 1, "USA");

% (Nota: Passiamo "labels" anche per "shocklabels" perché con Cholesky 
% lo shock ha lo stesso nome della variabile originaria).