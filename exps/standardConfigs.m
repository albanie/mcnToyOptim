function solverConfigs = standardConfigs(problemName, expType, varargin)
%STANDARDCONFIGS - stores solver configurations for experiments
%   SOLVERCONFIGS = STANDARDCONFIGS(PROBLEMNAME, EXPTYPE, VARARGIN)
%   stores a collection of solver configurations. This is primarily
%   useful for producing comparisons bewtween solvers, since it takes
%   some effort to work out a reasonable set of parameters for each
%   solver on each particular problem.
%
%   SOLVERCONFIGS(..., 'option', value, ...) accepts the following
%   options:
%
%   `bestConfigs`:: {}
%    An array of custom experimental configurations. This option is
%    useful when the best configruations have already been found by
%    grid search and the goal is to use resulting hyperparameters
%    for an experiment.
%
%   `numRepeats` :: 1
%    The number of times to repeat an experiment.
%
%   `gridBeta1s` :: []
%    Range of Beta1 values to search over (used by Adam).
%
%   `gridBeta2s` :: []
%    Range of Beta2 values to search over (used by Adam).
%
%   `gridMomentums` :: []
%    Range of momentum values to search over (used by SGD).
%
%   `gridLearningRates` :: []
%    Range of learning rate values to search over (used by SGD & Adam).
%
%   `gridRhos` :: []
%    Range of rho (moving average window for variance update) values
%    to search over (used by RMSProp).
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  opts.bestConfigs = {} ;
  opts.numRepeats = 1 ;
  opts.gridRhos = [] ;
  opts.gridBeta1s = [] ;
  opts.gridBeta2s = [] ;
  opts.gridMomentums = [] ;
  opts.gridLearningRates = [] ;
  opts = vl_argparse(opts, varargin) ;

  % These options seem to work fine with Curveball, but there may
  % be better combinations. Documentation for the parameters can
  % be found via running `help CurveBall`.
  hyenalOpts = {'autoparam', true, ...
                'momentum', 0.95, ...
                'beta', 0.005, ...
                'autolambda', false} ; % only supported for classification

  switch problemName
    case 'rahimiRecht'
      hyenalOpts = [hyenalOpts {'lambda', 1, 'learningRate', 1}] ;
    case 'rosenbrock'
      hyenalOpts = [hyenalOpts {'lambda', 1E-1, 'learningRate', 5E-1}] ;
  end

  switch expType
    case 'blend'
      solverConfigs = { ...
        {'name', 'SGD', 'learningRate', 5e-3, 'momentum', 0.9}, ...
        {'name', 'Adam', 'learningRate', 1e-2}, ...
        {'name', 'LM'}, ...
        {'name', 'BFGS'}, ...
        [{'name', 'CurveBall'}, hyenalOpts], ...
      } ;
    case 'blend-lite'
      % the first order methods are quite sensitive to the learning rate
      solverConfigs = { ...
        {'name', 'SGD', 'learningRate', 1e-3, 'momentum', 0.9}, ...
        {'name', 'Adam', 'learningRate', 5e-1}, ...
        {'name', 'LM'}, ...
        {'name', 'BFGS'}, ...
        [{'name', 'CurveBall'}, hyenalOpts], ...
      } ;
    case 'sgd-only'
      solverConfigs = { ...
        {'name', 'SGD', 'learningRate', 1e-3, 'momentum', 0.9}, ...
      } ;
    case 'curveball-only'
      solverConfigs = { ...
        [{'name', 'CurveBall'}, hyenalOpts], ...
      } ;
    case 'builtin-check'
      solverConfigs = { ...
        {'name', 'LM'}, ...
        {'name', 'BFGS'}, ...
      } ;
    case 'grid-search'
      required = {'gridLearningRates', 'gridRhos', 'gridMomentums', ...
                  'gridBeta1s', 'gridBeta2s'} ;
      for ii = 1:numel(required)
        assert(~isempty(opts.(required{ii})), ...
                'grid search:%s  should be set explicityly', required{ii}) ;
      end
      solverConfigs = { ...
        {'name', 'SGD', 'learningRate', opts.gridLearningRates, ...
                        'momentum', opts.gridMomentums}, ...
        {'name', 'Adam', ...
         'learningRate', opts.gridLearningRates, ...
         'beta1'  opts.gridBeta1s, ...
         'beta2', opts.gridBeta2s}, ...
        {'name', 'LM'}, ...
        {'name', 'BFGS'}, ...
        [{'name', 'CurveBall'}, hyenalOpts], ...
      } ;
    case 'repeated-runs'
      assert(~isempty(opts.bestConfigs), 'bestConfigs must be specified') ;
      solverConfigs = cellfun(@(x) [x {'numRepeats', opts.numRepeats}], ...
                                       opts.bestConfigs, 'uni', 0) ;
    otherwise, error('unrecognised expType setting: %d\n', expType) ;
  end
