function paper_exp(varargin)

  oo.runId = 1 ;
  oo.gifs = false ;
  oo.sharedX0 = [] ; % can be used for direct comparison
  oo.randScale = 1 ;
  oo.x0noise = 0.5 ;
  oo.numIters = 100 ;
  oo.setting = 'dev' ;
  oo.numRepeats = 10 ;
  oo.addNoise = false ;
  oo.refreshGrid = false ;
  oo.fixedXaxis = false ;
  oo.repeatPlots = false ;
  oo.logspaceXaxis = true ;
  oo.tolerance = 1e-4 ;
  oo.finalFigure = false ;
  oo.refreshRepeats = false ;
  oo.dataset = 'rosenbrock' ;
  oo.ourMethod = 'CurveBall' ;
  oo.finalResultDir = fullfile(vl_rootnn, 'data/pathological/results') ;
  oo.bestConfigCacheDir = fullfile(vl_rootnn, 'data/pathological/configCache') ;
  oo = vl_argparse(oo, varargin) ;

  switch oo.setting
    case 'dev'
      gridLearningRates = 1E-3 ;
      gridMomentums = 0.95 ;
      gridRhos = 0.9 ;
      gridBeta1s = 0.9 ;
      gridBeta2s = 0.999 ;
    case 'no-grid' % do not provide grid params
    case 'final' % try to give every solver a fair shot
      gridLearningRates = [1E-1, 5E-2, 1E-2, 5E-3, 1E-3, 5E-4, 1E-4, 5E-5] ;
      gridMomentums = [0.9, 0.95, 0.99] ;
      gridRhos = [0.9, 0.95, 0.99, 1] ;
      gridBeta1s = [0.9,0.99] ;
      gridBeta2s = [0.99,0.999] ;
  end

  if ~exist(oo.bestConfigCacheDir, 'dir')
    mkdir(oo.bestConfigCacheDir) ;
  end
  if ~exist(oo.finalResultDir, 'dir')
    mkdir(oo.finalResultDir) ;
  end
  problemName = sprintf('%s-%s-%d-reps%d', ...
                       oo.dataset, oo.setting, oo.numIters, oo.numRepeats) ;
  if oo.addNoise
    problemName = sprintf('%s-noiseScale-%d', problemName, oo.randScale) ;
  end
  configCachePath = fullfile(oo.bestConfigCacheDir, ...
                              sprintf('%s.mat', problemName)) ;
  finalResultPath = fullfile(oo.finalResultDir, ...
                              sprintf('%s.mat', problemName)) ;

  if strcmp(oo.setting, 'no-grid')
    % USED TO WIN WITH AUTOPARAM - NOTE: Not used in final version
    hyenalOptsAutoParam = {'lambda', 1E-1, ...
                  'scale_H', false, ...
                  'diag_H', 0, ...
                  'autoparam', true, ...
                  'momentum', 0.95, ...
                  'beta', 0.05, ...
                  'learningRate', 5E-1, ...
                  'fisher', false} ;

    bestConfigs = {...
      {'name', 'SGD', 'learningRate', 1e-03, 'momentum', 0.9500}, ...
      {'name', 'Adam', 'learningRate', 0.1, 'beta1', 0.9, 'beta2', 0.999}, ...
      {'name', 'LM', 'maxFuncEvals', inf}, ...
      {'name', 'BFGS', 'maxFuncEvals', inf}, ...
      {'name', 'CurveBall', hyenalOptsAutoParam{:}}, ...
    } ;
  else
    if ~exist(configCachePath, 'file') || oo.refreshGrid
      fprintf('refreshing grid search for problem\n') ; tic ;
      bestConfigs = compare_solvers('expType', 'grid-search', ...
                      'addNoise', oo.addNoise, ...
                      'randScale', oo.randScale, ...
                      'gridLearningRates', gridLearningRates, ...
                      'gridMomentums', gridMomentums, ...
                      'gridRhos', gridRhos, ...
                      'gridBeta1s', gridBeta1s, ...
                      'gridBeta2s', gridBeta2s, ...
                      'numIters', oo.numIters, ...
                      'dataset', oo.dataset ...
                      ) ;
      save(configCachePath, 'bestConfigs') ;
      fprintf('saving configs to %s, done in %g s\n', configCachePath, toc) ;
    else
      fprintf('loading configs from %s\n', configCachePath) ; tic ;
      tmp = load(configCachePath) ;
      bestConfigs = tmp.bestConfigs ;
      fprintf('done in %g s\n', toc) ;
    end
  end

  if ~exist(finalResultPath, 'file') || oo.refreshRepeats
		% run with best parameters
    fprintf('refreshing repeated runs for problem\n') ; tic ;
		[~,repeatedData] = compare_solvers('expType', 'repeated-runs', ...
																			 'addNoise', oo.addNoise, ...
																			 'randScale', oo.randScale, ...
																			 'bestConfigs', bestConfigs, ...
																			 'numIters', oo.numIters, ...
																			 'sharedX0', oo.sharedX0, ...
																			 'x0noise', oo.x0noise, ...
																			 'numRepeats', oo.numRepeats, ...
                                       'dataset', oo.dataset ...
																			 ) ;
	  save(finalResultPath, 'repeatedData') ;
	  fprintf('saving results to %s, done in %g s\n', finalResultPath, toc) ;
  else
    fprintf('loading results from %s\n', finalResultPath) ; tic ;
    tmp = load(finalResultPath) ;
    repeatedData = tmp.repeatedData ;
    fprintf('done in %g s\n', toc) ;
	end

  if oo.repeatPlots

    % modify
    std_colors = get(gca, 'colorOrder') ;
    colors = arrayfun(@(x) {std_colors(x,:)}, 1:5) ;
    solverNames = cellfun(@(x) {strrep(x.name, 'CurveBall', oo.ourMethod)}, ...
                              repeatedData) ;
    losses = cellfun(@(x) {x.losses}, repeatedData) ;
    xVals = cellfun(@(x) {x.xVals}, repeatedData) ;
    dataset = 'Rosenbrock-$\mathcal{U}[0,1]$' ;
    if oo.gifs
      plot_loss_gifs(solverNames, losses, dataset, ...
                  'colors', colors, ...
                  'limitIters', inf, 'logspaceXaxis', oo.logspaceXaxis, ...
                  'fixedXaxis', oo.fixedXaxis, 'runId', oo.runId) ;
    else
      plot_losses(solverNames, losses, dataset, ...
                  'colors', colors, ...
                  'finalFigure', oo.finalFigure, ...
                  'limitIters', inf, ...
                  'logspaceXaxis', oo.logspaceXaxis) ;
    end

    % hard code settings
    problemCfg.x0 = [-0.25 -0.25] ;
    %problemCfg.x0 = [0 -0.25] ;
    %problemCfg.x0 = [0 0] ;
    %problemCfg.x0 = [0.25 0.25] ;
		problemCfg.levels = linspace(1, 300, 20) ;
		problemCfg.resolution = 100 ;
		problemCfg.xmin = -0.75 ;
		problemCfg.xmax = 1.5 ;
		problemCfg.ymin = -0.75 ;
		problemCfg.ymax = 1.5 ;
		problemCfg.target = [1, 1] ;
    problemCfg.name = dataset ;
    oo.plotNoisyFunc = 1 ;

    if oo.gifs
      plot_gif_trajectories(solverNames, xVals, problemCfg, oo, ...
                            'runId', oo.runId) ;
    else
      plot_trajectories(solverNames, xVals, problemCfg, oo, ...
                        'finalFigure', oo.finalFigure) ;
    end
  end

  displaySummary(repeatedData, problemName, oo) ;
end

% ---------------------------------------------------------
function displaySummary(repeatedData, problemName, oo)
% ---------------------------------------------------------
% Use NaNs to denote divergence
  fprintf('-------------------------------------------\n') ;
  fprintf('computing stats for %s with tolerance %g\n', ...
                                problemName, oo.tolerance) ;
  fprintf('-------------------------------------------\n') ;
  for ii = 1:numel(repeatedData)
    data = repeatedData{ii} ;
    numSteps = arrayfun(@(ii) find((data.losses(ii,:) < oo.tolerance),1), 1:oo.numRepeats, 'uni', 0) ;
    convergedRuns = numSteps(~cellfun(@isempty, numSteps)) ;
    convergeRatio = numel(convergedRuns) / oo.numRepeats ;
    avgIterates = mean([convergedRuns{:}]) ;
    stdIterates = std([convergedRuns{:}]) ;
    fprintf('%10s: convergence perc %.0f%% - iterates (mean/std) %g/%.3f \n', ...
              data.name, convergeRatio * 100, avgIterates, stdIterates) ;
  end
end

