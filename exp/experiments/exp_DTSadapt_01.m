modelOptions.useShift      = 0;
modelOptions.predictionType = 'poi';
modelOptions.trainAlgorithm = 'fmincon';
modelOptions.covFcn        = '{@covMaterniso, 5}';
modelOptions.hyp           = struct('lik', log(0.01), 'cov', log([0.5; 2]));
modelOptions.normalizeY    = 1;

opts.trySecondModel = true;
opts.statistics = { 'mse', 'mzoe', 'kendall', 'rankmse', 'rankmzoe', 'rde' };
opts.testOrigRatio = 0.25;
opts.dataset    = 'DTS_005_25_models';
opts.saveModels = true;
opts.scratch = '/tmp/bajeluk';
[~, ~] = mkdir(opts.scratch);
