%% ITAT 2018 plots
% Script for making graphs showing the dependence of minimal function
% values on the number of function values of compared algorithms.
% 
% Created for ITAT 2018 workshop article.

%% load data

% checkout file containing all loaded data
tmpFName = fullfile('/tmp', 'itat2018_data.mat');
if (exist(tmpFName', 'file'))
  load(tmpFName);
else
  
% needed function and dimension settings
funcSet.BBfunc = 1:24;
funcSet.dims = [2, 3, 5, 10];
maxEvals = 250;
  
% folder for results
actualFolder = pwd;
articleFolder = fullfile(actualFolder(1:end - 1 - length('surrogate-cmaes')), 'latex_scmaes', 'itat2018paper');
plotResultsFolder = fullfile(articleFolder, 'images');
tableFolder = fullfile(articleFolder, 'tex');
if ~isdir(plotResultsFolder)
  mkdir(plotResultsFolder)
end
if ~isdir(tableFolder)
  mkdir(tableFolder)
end

% path settings
exppath = fullfile('exp', 'experiments');

% gen_path = fullfile(exppath, 'exp_geneEC_10');
% gen_path20D = fullfile(exppath, 'exp_geneEC_10_20D');
dts_path = fullfile(exppath, 'DTS-CMA-ES_05_2pop');
dts_rf_path = fullfile(exppath, 'exp_doubleEC_rf_s01');
% maes_path = fullfile(exppath, 'exp_maesEC_14_2_10_cmaes_20D');

cmaes_path = fullfile(exppath, 'CMA-ES');
% saacmes_path = fullfile(exppath, 'BIPOP-saACM-k');
lmm_path = fullfile(exppath, 'lmm-CMA-ES');

% load data
dataFolders = {dts_path; ...
               dts_rf_path; ...
               cmaes_path; ...
               lmm_path};
             
[evals, settings] = catEvalSet(dataFolders, funcSet);

% find ids in settings
clear findSet
findSet.modelType = 'gp';
findSet.evoControlModelGenerations = 5;
gp_Id = getStructIndex(settings, findSet);

findSet.modelType = 'forest';
% restrictedParam = 0.05
findSet.evoControlRestrictedParam = 0.05;
findSet.modelOpts.tree_splitFunc = @AxisSplit;
rf_05_axisId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @GaussianSplit;
rf_05_gaussId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @HillClimbingObliqueSplit;
rf_05_hcId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @PairObliqueSplit;
rf_05_pairId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @ResidualObliqueSplit ;
rf_05_resId = getStructIndex(settings, findSet);

% restrictedParam = 0.10
findSet.evoControlRestrictedParam = 0.10;
findSet.modelOpts.tree_splitFunc = @AxisSplit;
rf_10_axisId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @GaussianSplit;
rf_10_gaussId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @HillClimbingObliqueSplit;
rf_10_hcId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @PairObliqueSplit;
rf_10_pairId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @ResidualObliqueSplit ;
rf_10_resId = getStructIndex(settings, findSet);

% restrictedParam = 0.20
findSet.evoControlRestrictedParam = 0.20;
findSet.modelOpts.tree_splitFunc = @AxisSplit;
rf_20_axisId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @GaussianSplit;
rf_20_gaussId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @HillClimbingObliqueSplit;
rf_20_hcId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @PairObliqueSplit;
rf_20_pairId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @ResidualObliqueSplit ;
rf_20_resId = getStructIndex(settings, findSet);

% restrictedParam = 0.40
findSet.evoControlRestrictedParam = 0.40;
findSet.modelOpts.tree_splitFunc = @AxisSplit;
rf_40_axisId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @GaussianSplit;
rf_40_gaussId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @HillClimbingObliqueSplit;
rf_40_hcId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @PairObliqueSplit;
rf_40_pairId = getStructIndex(settings, findSet);
findSet.modelOpts.tree_splitFunc = @ResidualObliqueSplit ;
rf_40_resId = getStructIndex(settings, findSet);

% reference algorithms Ids
clear findSet
findSet.algName = 'CMA-ES';
cma_Id = getStructIndex(settings, findSet);
% findSet.algName = 'BIPOP-saACM-k';
% saacm_Id = getStructIndex(settings, findSet);
findSet.algName = 'lmm-CMA-ES';
lmm_Id = getStructIndex(settings, findSet);
findSet.algName = 'DTS-CMA-ES_05_2pop';
dts_Id = getStructIndex(settings, findSet);
             
% extract data
rf_05_axis_data = evals(:, :, rf_05_axisId);
rf_05_gauss_data = evals(:, :, rf_05_gaussId);
rf_05_hc_data = evals(:, :, rf_05_hcId);
rf_05_pair_data = evals(:, :, rf_05_pairId);
rf_05_res_data = evals(:, :, rf_05_resId);

rf_10_axis_data = evals(:, :, rf_10_axisId);
rf_10_gauss_data = evals(:, :, rf_10_gaussId);
rf_10_hc_data = evals(:, :, rf_10_hcId);
rf_10_pair_data = evals(:, :, rf_10_pairId);
rf_10_res_data = evals(:, :, rf_10_resId);

rf_20_axis_data = evals(:, :, rf_20_axisId);
rf_20_gauss_data = evals(:, :, rf_20_gaussId);
rf_20_hc_data = evals(:, :, rf_20_hcId);
rf_20_pair_data = evals(:, :, rf_20_pairId);
rf_20_res_data = evals(:, :, rf_20_resId);

rf_40_axis_data = evals(:, :, rf_40_axisId);
rf_40_gauss_data = evals(:, :, rf_40_gaussId);
rf_40_hc_data = evals(:, :, rf_40_hcId);
rf_40_pair_data = evals(:, :, rf_40_pairId);
rf_40_res_data = evals(:, :, rf_40_resId);

cmaes_data     = evals(:, :, cma_Id);
% saacmes_data   = evals(:, :, saacm_Id);
dtscmaes_data  = evals(:, :, dts_Id);
lmmcmaes_data  = evals(:, :, lmm_Id);

% color settings
rf_05_axisCol = getAlgColors(1);
rf_05_gaussCol = getAlgColors(2);
rf_05_hcCol = getAlgColors(3);
rf_05_pairCol = getAlgColors(4);
rf_05_resCol = getAlgColors(5);

rf_10_axisCol = getAlgColors(6);
rf_10_gaussCol = getAlgColors(7);
rf_10_hcCol = getAlgColors(8);
rf_10_pairCol = getAlgColors(9);
rf_10_resCol = getAlgColors(10);

rf_20_axisCol = getAlgColors(11);
rf_20_gaussCol = getAlgColors(12);
rf_20_hcCol = getAlgColors(13);
rf_20_pairCol = getAlgColors(14);
rf_20_resCol = getAlgColors(15);

rf_40_axisCol = getAlgColors(16);
rf_40_gaussCol = getAlgColors(17);
rf_40_hcCol = getAlgColors(18);
rf_40_pairCol = getAlgColors(19);
rf_40_resCol = getAlgColors(20);

cmaesCol     = getAlgColors('cmaes');
% saacmesCol   = getAlgColors('saacmes');
dtsCol       = getAlgColors('dtscmaes');
lmmCol       = getAlgColors('lmmcmaes');

if (~exist(tmpFName, 'file'))
  save(tmpFName);
end

end

%% Split function comparison: Axis, Gauss, HC, Pair, Residual, CMA-ES

%% Number of originally-evaluated points comparison

%% Algorithm comparison: DTS-RF-1, DTS-RF-2 (,DTS-RF-3), CMA-ES, DTS-CMA-ES (, lmm-CMA-ES?) 

%% final clearing
close all
