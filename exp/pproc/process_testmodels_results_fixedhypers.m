% Parameters

expid = 'exp_DTSmodels_02';
snapshotGroups = { [5,6,7], [18,19,20] };
errorCol = 'rde2'; % 'rdeM1_M2WReplace'; % 'rdeValid';
nTrainedCol = 'nTrained2';
plotImages = 'mean';  % 'off', 'rank'
aggFcn = @nanmean; % @(x) quantile(x, 0.75);
rankTol = 0.01;   % tolerance for considering the RDE equal
nModelpoolModels = 5; % # of models to choose into ModelPool

% Loading the data
if (~exist('resultTableAgg', 'var'))
  load(['exp/experiments/' expid '/modelStatistics.mat']);
end
run(['exp/experiments/' expid '.m']);

% % Clear-out the non-interesting settings:
% %   trainRange == 1.5 OR trainsetSizeMax == 5*dim
% modelOptions.trainRange = {2, 4};
% modelOptions.trainsetSizeMax = {'10*dim', '15*dim', '20*dim'};
% modelOptions.trainsetType = {'recent', 'nearest', 'clustering', 'nearestToPopulation'};
% modelOptions.covFcn = {'{@covSEiso}'  '{@covMaterniso, 5}'  '{@covMaterniso, 3}'};
disp('Using only this restricted set of modelOpts:');
printStructure(modelOptions);

% Processing model options
nSnapshotGroups = length(snapshotGroups);
multiFieldNames = getFieldsWithMultiValues(modelOptions);
modelOptions_fullfact = combineFieldValues(modelOptions);
hashes = cellfun(@(x) modelHash(x), modelOptions_fullfact, 'UniformOutput', false);

% Model settings differences
modelsSettings = cell(length(hashes), length(multiFieldNames));
for mi = 1:length(hashes)
  modelsSettings(mi, 1:2) = {mi, hashes{mi}};
  for mf = 1:length(multiFieldNames)
    modelsSettings{mi, 2+mf} = modelOptions_fullfact{mi}.(multiFieldNames{mf});
  end
end

% Column names
modelErrorsColNames = cell(length(functions)*nSnapshotGroups, 1);
for fi = 1:length(functions)
  fun = functions(fi);
  for si = 1:nSnapshotGroups
    iCol = (fi-1)*nSnapshotGroups + si;
    modelErrorsColNames{iCol} = ['f' num2str(fun) '_S' num2str(si)];
  end
end

% Loading errors from the table
if (~exist('modelErrorsPerFS', 'var') || ~exist('modelsSettingsFSI', 'var'))
  modelErrorsPerFS = cell(length(dimensions), 1);

  for di = 1:length(dimensions)
    dim = dimensions(di);
    fprintf('%dD: ', dim);
    modelErrorsPerFS{di} = zeros(length(hashes), length(functions) * nSnapshotGroups);
    modelErrorsDivSuccessFSI{di} = [];
    modelsSettingsFSI{di} = cell(0, size(modelsSettings, 2));
    funDimSngFSI{di}   = zeros(0, 3);
    rowFSI = 0;

    for mi = 1:length(hashes)
      hash = hashes{mi};
      fprintf('model %s ', hash);

      for fi = 1:length(functions)
        fun = functions(fi);
        % fprintf('f%d ', fun);

        for si = 1:nSnapshotGroups

          iCol = (fi-1)*nSnapshotGroups + si;
          % modelErrorsPerFS{di}(mi, iCol) = resultTableAgg{ ...
          %     strcmpi(resultTableAgg.hash, hash) ...
          %     &  resultTableAgg.dim == dim ...
          %     &  resultTableAgg.fun == fun ...
          %     &  resultTableAgg.snpGroup == si, errorCol};
          thisErrors = resultTableAll{ ...
              strcmpi(resultTableAll.hash, hash) ...
              &  ismember(resultTableAll.snapshot, snapshotGroups{si}) ...
              &  resultTableAll.dim == dim ...
              &  resultTableAll.fun == fun, errorCol};
          nErrors = sum(~isnan(thisErrors));

          modelErrorsPerFS{di}(mi, iCol) = aggFcn(thisErrors);
          modelErrorsDivSuccessFSI{di}(rowFSI + (1:nErrors), 1) = ...
              thisErrors(~isnan(thisErrors)) ...
              * ((length(snapshotGroups{si})*length(instances)) / nErrors);
          [~, thisSettingsIdx] = ismember(hash, hashes);
          modelsSettingsFSI{di}(rowFSI + (1:nErrors), :) = ...
              repmat(modelsSettings(thisSettingsIdx, :), nErrors, 1);
          funDimSngFSI{di}(rowFSI + (1:nErrors), :) = ...
              repmat([fun, dim, si], nErrors, 1);
          rowFSI = rowFSI + nErrors;
        end  % for snapshotGroups

      end  % for functions

      fprintf('\n');
    end  % for models
  end
end

% Loading # of successful trains from the table
if (~exist('trainSuccessPerFS', 'var'))
  trainSuccessPerFS = cell(length(dimensions), 1);

  for di = 1:length(dimensions)
    dim = dimensions(di);
    fprintf('%dD: ', dim);
    trainSuccessPerFS{di} = zeros(length(hashes), length(functions) * nSnapshotGroups);

    for mi = 1:length(hashes)
      hash = hashes{mi};
      fprintf('model %s ', hash);

      for fi = 1:length(functions)
        fun = functions(fi);
        % fprintf('f%d ', fun);

        for si = 1:nSnapshotGroups

          iCol = (fi-1)*nSnapshotGroups + si;
          thisNTrained = resultTableAgg{ ...
              strcmpi(resultTableAgg.hash, hash) ...
              &  resultTableAgg.dim == dim ...
              &  resultTableAgg.fun == fun ...
              &  resultTableAgg.snpGroup == si, nTrainedCol};
          if (~isempty(thisNTrained))
            trainSuccessPerFS{di}(mi, iCol) = thisNTrained ...
                / (length(snapshotGroups{si})*length(instances));
          else
            trainSuccessPerFS{di}(mi, iCol) = 0.0;
          end
        end  % for snapshotGroups
      end  % for functions
      fprintf('\n');
    end  % for models
  end
end


%% Summarizing results
% Initialization
modelErrorRanks = zeros(length(hashes), length(dimensions)*nSnapshotGroups);
modelErrors     = zeros(length(hashes), length(dimensions*nSnapshotGroups));
bestModelNumbers = zeros(length(hashes), length(dimensions)*nSnapshotGroups);
bestModelRankNumbers = zeros(length(hashes), length(dimensions)*nSnapshotGroups);
modelErrorsDivSuccess = zeros(length(hashes), length(dimensions)*nSnapshotGroups);
modelErrorDivSuccessRanks = zeros(length(hashes), length(dimensions)*nSnapshotGroups);
modelErrorRanksPerFS = cell(length(dimensions), 1);
for di = 1:length(dimensions)
  modelErrorRanksPerFS{di} = zeros(length(hashes), length(functions) * nSnapshotGroups);  
end

for di = 1:length(dimensions)
  for si = 1:nSnapshotGroups
    idx = ((di - 1) * nSnapshotGroups) + si;

    woF5 = ((setdiff(functions, 5) - 1) * nSnapshotGroups) + si;
    for col = woF5
      modelErrorRanksPerFS{di}(:, col) = preciseRank(modelErrorsPerFS{di}(:, col), rankTol);
    end
    modelErrors(:, idx) = nansum(modelErrorsPerFS{di}(:, woF5), 2) ./ (length(woF5));
    modelErrorRanks(:, idx) = nansum(modelErrorRanksPerFS{di}(:, woF5), 2) ./ (length(woF5));
    modelErrorsDivSuccess(:, idx) = nansum( modelErrorsPerFS{di}(:, woF5) ...
        ./ trainSuccessPerFS{di}(:, woF5), 2 ) ./ (length(woF5));
    modelErrorDivSuccessRanks(:, idx) = nansum( modelErrorRanksPerFS{di}(:, woF5) ...
        ./ trainSuccessPerFS{di}(:, woF5), 2 ) ./ (length(woF5));  
    % Normlize to (0, 1)
    % modelErrors(:, idx) = (modelErrors(:, idx) - min(modelErrors(:, idx))) ./ (max(modelErrors(:, idx)) - min(modelErrors(:, idx)));
    [~, bestModelNumbers(:, idx)] = sort(modelErrorsDivSuccess(:, idx));
    [~, bestModelRankNumbers(:, idx)] = sort(modelErrorDivSuccessRanks(:, idx));
  end
end  % for dimensions


%% Plot images
woF5 = repelem((setdiff(functions, 5) - 1) * nSnapshotGroups, 1, nSnapshotGroups) ...
       +  repmat(1:nSnapshotGroups, 1, length(setdiff(functions, 5)));
if (~strcmpi(plotImages, 'off'))
  for di = 1:length(dimensions)
    dim = dimensions(di);
    figure();
    switch lower(plotImages)
      case 'mean'
        image(modelErrorsPerFS{di}(:, woF5) ./ trainSuccessPerFS{di}(:, woF5), 'CDataMapping', 'scaled');
      case 'rank'
        image(modelErrorRanksPerFS{di}(:, woF5) ./ trainSuccessPerFS{di}(:, woF5), 'CDataMapping', 'scaled');
      otherwise
        warning('plot style not known: %s', plotImages)
    end
    colorbar;
    ax = gca();
    ax.XTick = 1:nSnapshotGroups:size(modelErrorsPerFS{di}, 2);
    ax.XTickLabel = setdiff(functions, 5); % ceil(woF5(1:2:end) ./ nSnapshotGroups);
    % ax.XTickLabel = cellfun(@(x) regexprep(x, '_.*', ''), modelErrorsColNames(woF5), 'UniformOutput', false);
    title([num2str(dim) 'D']);
    xlabel('functions and snapshot groups');
    ylabel('model settings');
  end
  
  figure();
  switch lower(plotImages)
    case 'mean'
      image(modelErrorsDivSuccess, 'CDataMapping', 'scaled');
    case 'rank'
      image(modelErrorDivSuccessRanks, 'CDataMapping', 'scaled');
  end
  colorbar;
  ax = gca();
  ax.XTick = 1:2:size(modelErrorsDivSuccess, 2);
  ax.XTickLabel = dimensions;
  title('RDE averaged across functions');
  xlabel('dimension, snapshot group');
  ylabel('model settings');
end

%% Anova-n
p = {};
stats = {};
snapshotGroupCol = 3;
for di = 1:length(dimensions)
  for si = 1:nSnapshotGroups
    idx = ((di - 1) * nSnapshotGroups) + si;
    if (exist('modelsSettingsFSI', 'var'))
      % Prepare Anova-n y's and categorical predictors
      thisSNG = funDimSngFSI{di}(:,snapshotGroupCol) == si;
      categorical = { modelsSettingsFSI{di}(thisSNG, 3), ...
          modelsSettingsFSI{di}(thisSNG, 4), ...
          cellfun(@(x) x(1,1), modelsSettingsFSI{di}(thisSNG, 5)) };
      y = modelErrorsDivSuccessFSI{di}(thisSNG, 1);
    else
      % Prepare Anova-n y's and categorical predictors
      categorical = { modelsSettings(:, 3), cell2mat(modelsSettings(:, 4)), ...
          cellfun(@(x) x(1,1), modelsSettings(:, 5)) };
      y = modelErrorsDivSuccess(:, idx);
    end
    % Anova-n itself:
    [p{idx},tbl,stats{idx},terms] = anovan(y, categorical, 'model', 1, 'varnames', multiFieldNames, 'display', 'off');
  end
end

%% Multcompare
cellBestValues = cell(0, 2+length(multiFieldNames));
mstd = {};
mltc = {};
for di = 1:length(dimensions)
  for si = 1:nSnapshotGroups
    idx = ((di - 1) * nSnapshotGroups) + si;

    fprintf('==== %d D, snapshotG: %d ====\n', dimensions(di), si);
    rowStart = size(cellBestValues, 1);

    for i = 1:length(multiFieldNames)
      fprintf('==   predictor: %s   ==\n', multiFieldNames{i});

      % Do the multi-comparison
      [c,mstd{idx, i},h,nms] = multcompare(stats{idx}, 'Dimension', i, 'display', 'off');
      nValues = size(nms, 1);
      mltc{idx, i} = c;

      % Identify the lowest estimated mean (and sort them, too)
      [~, sortedMeansId] = sort(mstd{idx, i}(:, 1));
      iMinMean = sortedMeansId(1);
      fprintf('Lowest mean f-value for this predictor is for %s.\n', nms{iMinMean});

      % Find other values which are not statistically different from the
      % lowest
      otherLowRows = (c(:,6) >= 0.05) & (ismember(c(:,1), iMinMean) | ismember(c(:,2), iMinMean));
      otherLowMat = c(otherLowRows, 1:2);
      otherLowBool = false(nValues, 1);
      for j = 1:size(otherLowMat,1)
        otherLowBool(otherLowMat(j, ~ismember(otherLowMat(j,:), iMinMean))) = true;
      end
      otherLowIdx = find(otherLowBool);
      isOtherInSorted = ismember(sortedMeansId, otherLowIdx);
      otherLowSorted = sortedMeansId(isOtherInSorted);

      bestValues = cellfun(@(x) regexprep(x, '^.*=', ''), ...
          nms([iMinMean; otherLowSorted]), 'UniformOutput', false);
      cellBestValues(rowStart + (1:length(bestValues)), 2+i) = bestValues;

      if (any(otherLowBool))
        fprintf('Other statistically also low are:\n\n');
        disp(nms(otherLowSorted));
      else
        fprintf('No other statistically lowest values.\n\n');
      end
    end
    cellBestValues(end+1, :) = [{[], []}, num2cell(p{idx}')];
    cellBestValues((rowStart+1):end, 1:2) = repmat({dimensions(di), si}, ...
        size(cellBestValues,1)-rowStart, 1);
  end
end
tBestValues = cell2table(cellBestValues, ...
    'VariableNames', [{'dim', 'snG' }, multiFieldNames]);
disp(tBestValues)

%% CSV table which should go into the article

covCol  = regexprep(modelsSettings(:,3), '([{,@} ]|cov|iso)', '');
covCol  = strrep(covCol, 'Matern5', '$\covMatern{5/2}$');
covCol  = strrep(covCol, 'SE',      '$\covSE$');
meanCol = strrep(modelsSettings(:,4), 'meanConst', '$m_\mu$');
meanCol = strrep(meanCol, 'meanZero', '$\mathbf{0}$');
ellCol  = cellfun(@(x) num2str(x(1,1)), modelsSettings(:,end), 'UniformOutput', false);
ellCol  = strrep(ellCol, '-2', 'ML estimate');
ellCol  = strrep(ellCol, '0',  '$\ell = 1$');

rdePerDim = zeros(size(modelErrorsDivSuccess,1), size(modelErrorsDivSuccess,2)/2);
for j = 1:size(modelErrorsDivSuccess,1)
  for i = 1:(size(modelErrorsDivSuccess,2)/2)
    rdePerDim(j, i) = mean(modelErrorsDivSuccess(j, ((i-1)*2+1):(2*i)));
    fprintf('  %.2f', mean(modelErrorsDivSuccess(j, i:(i+1))));
  end;
  fprintf('\n');
end
meanRDE = mean(modelErrorsDivSuccess, 2);
meanRDECol = num2cell(meanRDE);

header = {'covf', 'meanf', 'ell', 'D2', 'D3', 'D5', 'D10', 'D20', 'average'};
data   = [covCol, meanCol, ellCol, num2cell(rdePerDim), meanRDECol];

fixedHypersTable = cell2table(data, 'VariableNames', header);
writetable(fixedHypersTable, '../latex_scmaes/ec2016paper/data/fixedHypers.csv');

lt = LatexTable(fixedHypersTable);
lt.headerRow = {'covariance f.', '$m_\mu$', '$\ell$', '$2D$', '$3D$', '$5D$', '$10D$', '$20D$', '\textbf{average}'}';
lt.opts.tableColumnAlignment = num2cell('lcccccccc');
lt.opts.numericFormat = '$%.2f$';
lt.opts.booktabs = 1;
lt.opts.latexHeader = 0;
% identify minimas and set them bold
[~, minRows] = min([rdePerDim, meanRDE]);
for j = 1:size([rdePerDim, meanRDE], 2)
  lt.setFormatXY(minRows(j), 3+j, '$\\bf %.2f$');
end
latexRows = lt.toStringRows(lt.toStringTable);
% delete the lines \begin{tabular}{...} \toprule
% and              \bottomrule  \end{tabular}
latexRows([1,2,end-1,end]) = [];
% save the result in the file
fid = fopen('../latex_scmaes/ec2016paper/data/fixedHypers.tex', 'w');
for i = 1:length(latexRows)
  fprintf(fid, '%s\n', latexRows{i});
end
fclose(fid);

%% Models for ModelPool
% nModels = length(hashes);
% nCombs = nchoosek(nModels, nModelpoolModels);
% worstBestRanks = cell(length(dimensions), 1);
% maxMinRank = zeros(length(dimensions), 1);
% bestCombinations = cell(length(dimensions), 1);
% theBestCombs = cell(length(dimensions), 1);
% selectedFcnsErrors = cell(length(dimensions), 1);
% 
% selectedFcns = [1 2 3 6 8 12 17 21];
% cols = repelem((selectedFcns - 1) * nSnapshotGroups, 1, nSnapshotGroups) ...
%     +  repmat(1:nSnapshotGroups, 1, length(selectedFcns));
% 
% if (nCombs <= 1e6)
%   combs = combnk(1:nModels, nModelpoolModels);
% 
%   % DEBUG
%   % nCombs = 200;
%   % combs = combs(1:nCombs, :);
% 
%   for di = 1:length(dimensions)
%     worstBestRanks{di} = zeros(nCombs, 1);
%     for iComb = 1:nCombs
%       thisComb = combs(iComb, :);
%       worstBestRanks{di}(iComb) = max( min( ...
%           modelErrorRanksPerFS{di}(thisComb, :) ./ trainSuccessPerFS{di}(thisComb, :) ...
%           ) );
%     end
%     maxMinRank(di) = min(worstBestRanks{di});
%     bestCombinations{di} = find(worstBestRanks{di} == maxMinRank(di));
%     fprintf('%d D: There are %d combinations with rank <= %d.\n', ...
%         dimensions(di), length(bestCombinations{di}), maxMinRank(di));
% 
%     selectedFcnsErrors{di} = zeros(length(bestCombinations{di}), ...
%         nSnapshotGroups * length(selectedFcns));
%     for ci = 1:length(bestCombinations{di})
%       thisComb = combs(bestCombinations{di}(ci), :);
%       selectedFcnsErrors{di}(ci, :) = min(modelErrorsPerFS{di}(thisComb, cols));
%     end
% 
%     % Display one of the best settings with the lowest mean RDE
%     % on selected functions
%     [~, iBestBestCombination] = min(mean(selectedFcnsErrors{di}, 2));
%     theBestCombs{di} = combs(bestCombinations{di}(iBestBestCombination), :);
%     disp([repelem(selectedFcns, nSnapshotGroups); ...
%         modelErrorRanksPerFS{di}(theBestCombs{di}, cols) ./ trainSuccessPerFS{di}(theBestCombs{di}, cols) ...
%         ]);
%     disp(modelsSettings(theBestCombs{di}, :));
%     
%     % % Display all best settings
%     % disp(combs(bestCombinations{di}, :));
%     % disp([0 repelem(selectedFcns, nSnapshotGroups); ...
%     %     mean(selectedFcnsErrors{di}, 2), selectedFcnsErrors{di}]);
%     disp('--------------------------------');
%   end  
% else
%   fprintf('There''s too many combinations of settings: %d\n', nCombs);
% 
% end
