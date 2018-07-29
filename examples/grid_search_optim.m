function [best,repeatData] = grid_search_optim(solverConfig, dataset, ...
                                                     data, oo, problemCfg)
% TODO(samuel) - cleanup & docs

  ss = parseCfg(solverConfig) ;
  solverName = ss.name ;
  expGrid = extractGrid(ss) ;
  gridLosses = cell(1, numel(expGrid)) ;
  gridXVals = cell(1, numel(expGrid)) ;
  for gg = 1:numel(expGrid)
    fprintf('(%d/%d): evaluating %s\n', gg, numel(expGrid), solverName) ;
    if strcmp(solverName, 'CurveBall')
      solver = CurveBall(expGrid{gg}{:}) ; % does not use the same parent structure
    else
      solver = solvers.(solverName)(expGrid{gg}{:}) ;
    end

    % track data for stochastic re-runs
    repeatDataLosses = zeros(oo.numRepeats, oo.numIters) ;
    repeatDataXvals = zeros(oo.numRepeats, oo.numIters+ 1, 2) ;

    for ii = 1:oo.numRepeats
      if oo.numRepeats > 1
        fprintf('running repeat %d/%d\n', ii, oo.numRepeats) ;
      end
      losses = zeros(1, oo.numIters) ;
      func = modelZoo(dataset, oo, solverName, problemCfg) ;

      if strcmp(oo.dataset, 'rosenbrock')
        %xVals = cell(1, oo.numIters, 2) ;
        xVals = cell(1, oo.numIters, 1) ;
        xVals{1} = func.getValue('w') ;
      end
      %losses(1) = 0.1 ; % use arbitrary first loss to correspond
      fprintf('optimising %s with %s (%s) \n', dataset, solverName, oo.expType) ;
      for iter = 1:oo.numIters
        losses(iter) = solverStep(solverName, solver, func, data, oo) ;
        if strcmp(oo.dataset, 'rosenbrock')
          xVals{iter+1} = func.getValue('w') ; % track stats
        end
      end
      repeatDataLosses(ii,:) = losses(1:end) ;
      if strcmp(oo.dataset, 'rosenbrock')
        repeatDataXvals(ii,:,:) = vertcat(xVals{1:end}) ;
      end
    end
    gridLosses{gg} = losses ;
    if strcmp(oo.dataset, 'rosenbrock')
      gridXVals{gg} = vertcat(xVals{:}) ;
    end
  end

  % select best configuration based on average of final ten iterations
  finishes = cellfun(@(x) mean(x(end-min(10, numel(x))+1+1:end)), gridLosses) ;
  [~,minIdx] = min(finishes) ;
  best.cfg = expGrid{minIdx} ;
  best.losses = gridLosses{minIdx} ;
  if strcmp(oo.dataset, 'rosenbrock')
    best.xVals = gridXVals{minIdx} ;
    repeatData.xVals = repeatDataXvals ;
  end
  best.name = solverName ;
  repeatData.name = solverName ;
  repeatData.losses = repeatDataLosses ;
end

% ----------------------------------------------------------------------
function grid = extractGrid(ss)
% ----------------------------------------------------------------------
%EXTRACTGRID - build cartesian product of options
% construct a cell array, each entry of which is a cell array containing
% name-value pairs describing a specific solver configuration. E.g.
% output might be
%
%    grid = {{'learningRate', 1, 'momentum', 0.9}, ...
%            {'learningRate', 0.1, 'momentum', 0.8}} ;

  base = rmfield(ss, 'name') ; % remove meta data
  if isfield(base, 'numRepeats')
    base = rmfield(base, 'numRepeats') ; % remove meta data
  end
  fnames = fieldnames(base) ;
  optSizes = cellfun(@(x) numel(base.(x)), fnames)' ;
  totalGridSize = prod(optSizes) ;
  grid = cell(1, totalGridSize) ;
  subs = cell(1,numel(fnames));
  for ii = 1:totalGridSize
    [subs{:}] = ind2sub(optSizes, ii) ;
    sel = cell(1, numel(fnames) * 2) ;
    for jj = 1:numel(fnames)
      sel{jj*2-1} = fnames{jj} ;
      sel{jj*2} = base.(fnames{jj})(subs{jj}) ;
    end
    grid{ii} = sel ;
  end
end

% -----------------------------------------------------------------
function lossValue = solverStep(solverName, solver, func, data, oo)
% -----------------------------------------------------------------
  switch solverName
    case 'CurveBall'
      eval_wrapper(func, oo, 'curveball', true) ;
      solver.net = func ;
      solver.labels = data.leastSq.vals{4} ; % least squares labels
      solver.loss = 'ls' ;
      solver.step(func) ;
    otherwise
      eval_wrapper(func, oo) ;
      solver.step(func) ;
  end

  if ~strcmp(solverName, 'CurveBall')
    lossValue = func.getValue('loss') ;
  else
    lossValue = solver.last_loss;
  end
end

% -----------------------------------------------------------------------
function eval_wrapper(func, oo, varargin)
% -----------------------------------------------------------------------
% Each Least Squares model produces predictions rather than a loss (labels
% are passed into the optimiser separately).  Therefore we only pass the
% first part of the data into the optimizer
  opts.curveball = false ;
  opts = vl_argparse(opts, varargin) ;

  switch oo.dataset
    case 'rosenbrock'
      if oo.addNoise
        sample = rand ;
        if oo.negCurvature
          sample = sample - 0.5 ;
        end
        images = single(sample * oo.randScale) ; % add noise from U[0,1] (scaled)
      else
        images = single(1) ;
      end
    case 'rahimiRecht'
      images = single(oo.data.vals{2}) ;
    otherwise, error('unrecognised dataset - %s\n', oo.dataset) ;
  end

  ins = {'images', images} ;

    % run forward pass only (backward pass will be handled by the network)
    extras = {} ;
    if opts.curveball, extras = [extras {'forward'}] ; end
    if strcmp(oo.dataset, 'rahimiRecht') && ~opts.curveball
      ins = [ins {'y', oo.data.vals{4}}] ;
    end
  func.eval(ins, extras{:}) ;
end

% -----------------------------------------------------------------------
function res = rahimiRecht(x, x_dim, h_dim, y)
% -----------------------------------------------------------------------
% TODO(samuel): fix docs
%RAHIMIRECHT - compute the Rahimi function
%  LOSS = RAHIMIRECHT(X, Y, X_DIM, H_DIM) compute the loss achieved by a
%  simple function (the simple two layer network described by Ali Rahimi
%  in his NIPS 2017 "Test-of-time" address). The function consists of two
%  matrix multiplies:
%       Y_HAT = W2 * W1 * x
%  where X is a X_DIM-dimensional vector, W2 is H_DIM x H_DIM and W1 is
%  H_DIM x X_DIM.  The output LOSS is the euclidean distance between Y_HAT
%  and Y.
%
%  For more details, see https://github.com/benjamin-recht/shallow-linear-net/blob/master/TwoLayerLinearNets.ipynb
%

  % 2-layer linear network model
  w1 = Param('value', 2/(h_dim + x_dim) * randn(1,1,x_dim, h_dim, 'single')) ;
  w2 = Param('value', 1/(h_dim) * randn(1,1,h_dim, h_dim, 'single')) ;

  % run linear layers
  first = vl_nnconv(x, w1, []) ;
  prediction = vl_nnconv(first, w2, []) ;
  %prediction = w2 * w1 * x ;

  if nargin == 4
    res = mean(sum((prediction - y).^2, 3), 4) ;
  else
    res = prediction ;
  end
end

% -----------------------------------------------------------------------
function y = rosenbrock(x)
% -----------------------------------------------------------------------
%ROSENBROCK - compute multidimensional Rosenbrock function
% Y = ROSENBROCK(W) computes the value of the multidimensaion generalisation
% of the Rosenbrock function.

  % transform to stochastic rosenbrock, as described in:
  % "Engineering Optimisation by Cuckoo Search", Yang and Deb, 2010
  epsilon = Input('images') ;

	dim = size(x, 2) ; % size can be used with autodiff (but not length)
  eps_sqrd = epsilon * epsilon ;
  summand = eps_sqrd * 100 *(x(2:dim) - x(1:dim-1).^2).^2 + (1 - x(1:dim -1)).^2 ;
  y = sum(summand, 2) ;
end

% -----------------------------------------------------------------------
function prediction = rosenbrock_least_sq(x, addNoise, randScale)
% -----------------------------------------------------------------------
%ROSENBROCK_LEAST_SQ - compute 2-dimensional Rosenbrock function (LS-form)
%  RES = ROSENBROCK_LEAST_SQ(X, Y) computes the loss of the least squares form
%  of the rosenbrock function. Essentially this amounts to to re-writing
%  the function in a Least-Squares form, such that the resulting loss takes the
%  same value as the Rosenbrock function. The second argument Y, corresponds
%  to the "targets" of this LS problem - they should be set to zero.

  % transform to stochastic rosenbrock, as described in:
  % "Engineering Optimisation by Cuckoo Search", Yang and Deb, 2010
  epsilon = Input('images') ;

  %sqrt_eps = (epsilon .^ 0.5) ;
	prediction = cat(3, epsilon * 10*(x(2) - x(1).^2),  1 - x(1)) ;

  % note that for compatibility with the CurveBall solver, we also pass
  % an unused input.

  % compute sum of squares loss
  %res = (prediction(1) - y(1)).^2 + (prediction(2) - y(2)).^2 ;

  %res = sum((prediction(:) - y(:)).^2, 1) ;
  %res = mean(sum((prediction - y).^2, 1), 2);
end

% -----------------------------------------------------------------------
function model = modelZoo(dataset, opts, methodName, problemCfg)
% -----------------------------------------------------------------------
  isLeastSquaresMethod = strcmp(methodName, 'CurveBall') ;
  if ~isempty(opts.sharedX0)
    rosenbrockX0 = single(opts.sharedX0) ;
  else
    rosenbrockX0 = single(problemCfg.x0) + (rand - 0.5) * opts.x0noise ;
  end
  fprintf('initialising from %g/%g\n', rosenbrockX0(:)) ;

  if isLeastSquaresMethod
      % under the least square formulation, we construct models that output
      % predictions, rather than the loss directly.  However, to keep a
      % consistent interface, we label the output of each model as "loss"
      switch dataset
        case 'rosenbrock'
          w = Param('value', rosenbrockX0) ;
          prediction = rosenbrock_least_sq(w) ;
        case 'rahimiRecht'
          images = Input() ;
          prediction = rahimiRecht(images, opts.x_dim, opts.y_dim) ;
        otherwise, error('unknown dataset: %s', dataset) ;
      end
      loss = prediction ;
  else % everything else (i.e. methods that do not require an LS formulation)
    switch dataset
      case 'rosenbrock' % NOTE: [1.5, 1.5] used in pytorch tests
        w = Param('value', rosenbrockX0) ;
        loss = rosenbrock(w) ;
      case 'rahimiRecht'
        images = Input() ; y = Input() ;
        loss = rahimiRecht(images, opts.x_dim, opts.y_dim, y) ;
      otherwise, error('unknown dataset: %s', dataset) ;
    end
  end
	Layer.workspaceNames() ;
	model = Net(loss) ;
end

% ----------------------------------------------------------------------
function solverStruct = parseCfg(cfg)
% ----------------------------------------------------------------------
  assert(mod(numel(cfg), 2) == 0, 'cfg should contain key-val pairs') ;
  for ii = 1:numel(cfg)/2
    solverStruct.(cfg{2 * ii - 1}) = cfg{2 * ii} ;
  end
end

