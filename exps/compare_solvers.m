function [bestConfigs,repeatedData] = compare_solvers(varargin)

  oo.dev = 1 ;
  oo.expType = 1 ;
  oo.refresh = 0 ;
  oo.x0noise = 0 ;
  oo.sharedX0 = [] ;
  oo.numIters = 100 ;
  oo.randScale = 1 ;
  oo.numRepeats = 1 ;
  oo.nullValue = NaN ;
  oo.negCurvature = 0 ;
  oo.addNoise = false ;
  oo.plotNoisyFunc = 1 ;
  oo.rosenbrockDebug = 0 ;
  oo.builtinStepTol = 1e-20 ;
  oo.builtinOptimalityTol = 1e-8 ;
  oo.produceIntermediateFig = false ;

  % grid search params if desired
  oo.gridLearningRates = [] ;
  oo.gridMomentums = [] ;
  oo.gridRhos = [] ;
  oo.gridBeta1s = [] ;
  oo.gridBeta2s = [] ;
  oo.bestConfigs = [] ;
  oo.experiment = 'rosenbrock' ;
	oo = vl_argparse(oo, varargin) ;

  switch oo.experiment
    case 'rahimi-recht'
      dataset = 'rahimi-recht' ;
      modelName = 'rahimiRecht' ;
    case 'rosenbrock'
      modelName = 'rosenbrock' ;
      dataset = 'rosenbrock' ;
  end

  switch dataset
    case 'rosenbrock'
      oo.numDims = 2 ;
      data.name = 'Rosenbrock' ;
      data.vals = {} ;
      % data must be passed in a slightly unusual layout to work with
      % CurveBall interface (i.e. we pass the spatial dims as batch elements)
      data.leastSq.vals = {'images', zeros(1,'single'), ...
               'labels', reshape(single([0 0]), 1, 1, 2)} ; % special form

			problemCfg.name = data.name ;
      % Selecting the initialisation value for the optimisation is somewhat
      % arbitrary
      problemCfg.x0 = [-0.25 -0.25] ;
			problemCfg.levels = linspace(1, 300, 20) ;
			problemCfg.resolution = 100 ;
			problemCfg.xmin = -0.75 ;
			problemCfg.xmax = 1.5 ;
			problemCfg.ymin = -0.75 ;
			problemCfg.ymax = 1.5 ;
			problemCfg.target = [1, 1] ;

    case 'rosenbrock-ndim'
      oo.numDims = 20 ;
      data.vals = {} ;
      data.name = sprintf('%d-Dimensional Rosenbrock', oo.numDims) ;

    case 'rahimi-recht' % a la Joao
      % from: https://github.com/benjamin-recht/shallow-linear-net/blob/master/TwoLayerLinearNets.ipynb
      num_samples = 1000 ;
      oo.x_dim = 6 ;  % input size
      oo.y_dim = 10 ;  % output size
      data_x = randn(oo.x_dim, num_samples) ;
      % set degrexpType of degenerate-ness for rahimi-recht dataset
      dataset_epsilon = 1e-5 ;
      A = linspace(1, dataset_epsilon, oo.y_dim)' .* rand(oo.y_dim, oo.x_dim) ;

      % reshape into tensors
      data_y = reshape(A * data_x, 1, 1, size(A*data_x, 1), []) ;
      data_x = reshape(data_x, 1, 1, size(data_x, 1), []) ;

      data.vals = {'x', data_x, 'y', data_y} ;
      data.name = 'Rahimi-Recht testcase' ;
      oo.data = data ;
			problemCfg.name = data.name ;
      problemCfg.x0 =  [0 0] ; % not used in this method

      data.leastSq.vals = data.vals ; % special form
    otherwise, error('unknown dataset: %s', dataset) ;
  end

  % select a set of solvers for this experiment
  solverConfigs = standardConfigs(oo.experiment, oo.expType, ...
                                  'bestConfigs', oo.bestConfigs) ;

  [solverNames, losses] = runSolvers(solverConfigs, problemCfg, data, oo) ;

  plot_losses(solverNames, losses, data.name) ;
  if strcmp(oo.experiment, 'rosenbrock') && oo.produceIntermediateFig
    plot_trajectories(solverNames, xVals, problemCfg, oo) ;
  end
end

% ----------------------------------------------------------------------------
function [solverNames,losses,bestConfig] = runSolvers(solverConfigs, data, oo)
% ----------------------------------------------------------------------------
%RUNSOLVERS - run a given collection of solvers on a particular problem
%    [SOLVERNAMES, LOSSES, BESTCONFIG] = RUNSOLVERS(SOLVERCONFIGS, DATA, OO)
%    runs an optimisation algorithm for each of the solvers specified in the
%    cell array SOLVERCONFIGS on the problem specified by PROBLEMCFG

  % run optimization
  losses = cell(1, numel(solverConfigs)) ;
  xVals = cell(1, numel(solverConfigs)) ;
  solverNames = cell(1, numel(solverConfigs)) ;
  bestConfigs = cell(1, numel(solverConfigs)) ;
  repeatedData = cell(1, numel(solverConfigs)) ;

  % this is only used for visualisations, since it adds limited value when there
  % are many samples
  if ~isempty(oo.sharedX0)
    oo.sharedX0 = problemCfg.x0 + (rand - 0.5) * oo.x0noise ;
  end

	for ii = 1:numel(solverConfigs)
		%func.setValue(w, w0) ; % reset for each solver
		solverCfg = solverConfigs{ii} ;
    solverName = solverCfg{2} ;
    switch solverName
      case {'BFGS', 'DFP', 'LM'} % use built-in MATLAB solver
        [best,repeatData] = builtin_solvers(solverName, problemCfg.x0, oo) ;
        bestConfig = {'name', solverName} ;
      otherwise
        [best,repeatData] = grid_search_optim(solverCfg, modelName, ...
                                              data, oo, problemCfg) ;
        bestConfig = [{'name', solverName}, best.cfg] ;
    end
    if strcmp(oo.experiment, 'rosenbrock')
      xVals{ii} = best.xVals ;
    end
		losses{ii} = best.losses ;
		solverNames{ii} = solverName ;
    bestConfigs{ii} = bestConfig ;
    repeatedData{ii} = repeatData ;
	end
end