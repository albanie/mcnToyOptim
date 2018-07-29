function launch_exp(varargin)
%LAUNCH_EXP - example script for launching solver comparisons
%  LAUNCH_EXP(VARARGIN) - launches a solver comparison on
%  toy problems

  oo.bestConfigs = {} ;
  oo.randScale = 1 ;
  oo.x0noise = 0.5 ;
  oo.sharedX0 = [] ; % can be used for direct comparison
  oo.numIters = 200 ;
  oo.numRepeats = 1 ;
  oo.addNoise = false ;
  oo.dataset = 'rahimiRecht' ; % can also be 'rosenbrock'
  oo.expType = 'blend' ;
  oo = vl_argparse(oo, varargin) ;

  % demo usage of interface
  compare_solvers('expType', oo.expType, ...
                  'addNoise', oo.addNoise, ...
                  'randScale', oo.randScale, ...
                  'bestConfigs', oo.bestConfigs, ...
                  'numIters', oo.numIters, ...
                  'sharedX0', oo.sharedX0, ...
                  'x0noise', oo.x0noise, ...
                  'numRepeats', oo.numRepeats, ...
                  'dataset', oo.dataset) ;
