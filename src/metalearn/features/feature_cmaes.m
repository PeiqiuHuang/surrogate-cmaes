function ft = feature_cmaes(X, ~, settings)
% ft = FEATURE_CMAES(X, y, settings) returns features based on CMA-ES state
% variables for dataset [X, y].
%
% settings:
%   cma_cov        - covariance matrix of CMA-ES
%   cma_evopath_c  - CMA-ES covariance matrix evolution path vector
%   cma_evopath_s  - CMA-ES step-size evolution path vector
%   cma_generation - generation number of CMA-ES algorithm
%   cma_mean       - CMA-ES mean value
%   cma_restart    - number of CMA-ES restarts
%   cma_step_size  - CMA-ES step-size value
%
% Features:
%   cma_generation - generation number of CMA-ES algorithm
%   cma_step_size  - CMA-ES step-size value
%   cma_restart    - number of CMA-ES restarts
%   cma_mean_dist  - mahalanobis distance of the CMA mean to dataset
%   cma_evopath_c_norm - eigenvalue of rank-one update
%   cma_evopath_s_norm - length of the evolution path p_\sigma compared to
%                        the expected length of random steps
%   cma_lik            - log-likelihood of dataset being from CMA
%                        distribution

  if nargin < 3
    if nargin < 2
      help feature_cmaes
      if nargout > 0
        ft = struct();
      end
      return
    end
    settings = struct();
  end
  
  [N, dim] = size(X);
  
  % parse settings
  ccov = defopts(settings, 'cma_cov', NaN(dim));
  evopath_c = defopts(settings, 'cma_evopath_c', NaN(1, dim));
  evopath_s = defopts(settings, 'cma_evopath_s', NaN(1, dim));
  generation = defopts(settings, 'cma_generation', NaN);
  cmean = defopts(settings, 'cma_mean', NaN(1, dim));
  restart = defopts(settings, 'cma_restart', NaN);
  step_size = defopts(settings, 'cma_step_size', NaN);
  
  % calculate features
  ft.cma_generation = generation;
  ft.cma_step_size = step_size;
  ft.cma_restart = restart;
  % mahalanobis distance of the CMA mean to dataset
  if isempty(X)
    ft.cma_mean_dist = NaN;
  else
    ft.cma_mean_dist = sqrt(mahal(cmean, X));
  end
    
  % norm of evolution path (used to update covariance matrix)
  %   covariance matrix p_c*p_c’ has rank one, 
  %   i.e. only one eigenvalue ||p_c||^2
  ft.cma_evopath_c_norm = norm(evopath_c)^2;
  % step-size evolution path
  %   length of the evolution path p_\sigma compared to the expected length
  %   of random steps: ||p_\sigma|| / E (|| N(0, I) ||)
  %   E (|| N(0, I) ||) = \sqrt(2)*\gamma((D+1)/2) / \gamma(D/2)) 
  ft.cma_evopath_s_norm = norm(evopath_s) / ...
                      (sqrt(2) * gamma( (dim+1) / 2 ) / gamma( dim / 2 ));
  % log-likelihood of dataset being from CMA distribution
  if isempty(X)
    ft.cma_lik = NaN;
  else
    Xcmean = (X - repmat(cmean, N, 1)) / step_size;
    ft.cma_lik = - ( N * ( ...
                           dim * ( ...
                                   log (2*pi) + ...
                                   2 * log(step_size) ...
                                 ) + ...
                           log(det(ccov)) ...
                         ) + ...
                     sum( diag(Xcmean*(ccov\Xcmean')) ) ...
                   ) ...
                 / 2;
  end
end