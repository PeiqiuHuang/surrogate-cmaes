function [x, ilaunch, y_evals, stopflag] = opt_xacmes(FUN, DIM, ftarget, maxfunevals, id)
% minimizes FUN in DIM dimensions by multistarts of fminsearch.
% ftarget and maxfunevals are additional external termination conditions,
% where at most 2 * maxfunevals function evaluations are conducted.
% fminsearch was modified to take as input variable usual_delta to
% generate the first simplex.
% set options, make sure we always terminate
% with restarts up to 2*maxfunevals are allowed

% Be aware: 'id' is an additional parameter!

xstart = 8 * rand(DIM, 1) - 4; % random start solution

fDelta = 1e-8;

cmOptions = struct( ...
  'MaxFunEvals', min(1e8*DIM, maxfunevals), ...
  'StopFitness', ftarget, ...
  'LBounds', -5, ...
  'UBounds',  5, ...
  'LogTime',  0, ...
  'SaveVariables', 'off', ...
  'DispModulo', '10');

y_evals = [];
stopflag = 0;

load('scmaes_params.mat', 'bbParamDef', 'sgParamDef', 'cmParamDef');
[~, sgParams, cmParams] = getParamsFromIndex(id, bbParamDef, sgParamDef, cmParamDef);
for fname = fieldnames(cmParams)'
  cmOptions.(fname{1}) = cmParams.(fname{1});
end

global settings;
% Default saACM-ES settings:
settings.BIPOP = 0; 
settings.newRestartRules = 0; 
settings.noisy = 0;
settings.CMAactive = 1;
settings.withFileDisp = 0;
settings.withSurr = 1;
settings.modelType = 1;
settings.withModelEnsembles = 0;
settings.withModelOptimization = 1;
settings.hyper_lambda = 20;
settings.iSTEPminForHyperOptimization = 1;
settings.MaxEvals = '1e6*dim';
settings.MaxEvalsWithSurrogate = '1e4*20';
settings.lambdaMult = 1;
settings.muMult = 1;
settings.largeLambdaMinIter = 4;

settings.withDisp = 0;
settings.maxStepts = 20;
settings.maxerr = 0.45;
settings.alpha = 0.20;
settings.iterstart = 10;

settings.iglobalrun = 0;

% rewrite the default settings with the settings from sgParams
for fname = fieldnames(sgParams)'
  settings.(fname{1}) = sgParams.(fname{1});
end
if (length(settings.lambdaMult) > 1)
  settings.lambdaMult = settings.lambdaMult(DIM);
end

% refining multistarts
for ilaunch = 1:1e4; % up to 1e4 times
  % % try fminsearch from Matlab, modified to take usual_delta as arg
  % x = fminsearch_mod(FUN, xstart, usual_delta, cmOptions);
  % standard fminsearch()
  settings.iglobalrun  = settings.iglobalrun + 1;
  maxeval_available = maxfunevals - fgeneric('evaluations');
  [x y_eval] = xacmes(FUN, DIM, maxeval_available);

  n_y_evals = size(y_eval,1);
  y_eval(:,1) = y_eval(:,1) - (ftarget - fDelta) * ones(n_y_evals,1);
  y_evals = [y_evals; y_eval zeros(n_y_evals, 2)];
  % terminate if ftarget or maxfunevals reached
  if (feval(FUN, 'fbest') < ftarget || ...
      feval(FUN, 'evaluations') >= maxfunevals)
    break;
  end
  % % terminate with some probability
  % if rand(1,1) > 0.98/sqrt(ilaunch)
  %   break;
  % end
  xstart = x; % try to improve found solution
  % % we do not use usual_delta :/
  % usual_delta = 0.1 * 0.1^rand(1,1); % with small "radius"
  % if useful, modify more options here for next launch
end

  function stop = callback(x, optimValues, state)
    stop = false;
    if optimValues.fval < ftarget
      stop = true;
    end
  end % function callback

end % function