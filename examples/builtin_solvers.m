function [res,repeatData] = builtin_solvers(solverName, x0, oo, varargin)
%BUILTIN_SOLVERS - Run builtin MATLAB solver on a given optimisation problem
%  [RES, REPEATDATA] = BUILTIN_SOLVERS(SOLVERNAME, X0, OO, VARARGIN) runs
%  builtin solvers on
%
%   BUILTIN_SOLVERS(..., 'option', value, ...) accepts the following
%   options:
%
%   `maxFuncEvals`:: 1000
%    The maximum number of function evaluations to be used by the solver.
%    This corresponds directly to the `MaxFunctionEvaluations` value used
%    by the optimoptions builtin (run help optimoptions for more information).
%
% Copyright (C) 2018 Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  builtinOpts.maxFuncEvals = 1000 ;
  builtinOpts = vl_argparse(builtinOpts, varargin) ;

  repeatDataLosses = ones(oo.numRepeats, oo.numIters) * oo.nullValue ;
  repeatDataXvals = ones(oo.numRepeats, oo.numIters, 2) * oo.nullValue ;

  for ii = 1:oo.numRepeats
    fprintf('(%s) running repeat %d/%d\n', solverName, ii, oo.numRepeats) ;
    if ~isempty(oo.sharedX0)
      x0_rand = oo.sharedX0 ; % modify x0 if required
    else
      x0_rand = double(x0) + (rand - 0.5) * oo.x0noise ;
    end

    [xVals, fVals, exitFlag] = rosenbrocker(x0_rand, solverName, ...
                                            builtinOpts.maxFuncEvals, oo) ;

    if exitFlag > 1 % restart while there are still iterations remaining
      storedXVals = {xVals} ; storedFVals = {fVals} ; totalIters = size(xVals,1) ;
      while totalIters < oo.numIters && exitFlag > 1
        fprintf('restarting builtin solver from [%g,%g]\n', xVals(end,:)) ;
        [xVals, fVals, exitFlag] = rosenbrocker(xVals(end,:), solverName, ...
                                               builtinOpts.maxFuncEvals, oo) ;
        storedXVals{end+1} = xVals ;
        storedFVals{end+1} = fVals ;
      end
      xVals = vertcat(storedXVals{:}) ;
      fVals = vertcat(storedFVals{:}) ;
    end
    repeatDataXvals(ii,1:size(xVals,1),:) = xVals ;
    repeatDataLosses(ii,1:numel(fVals)) = fVals ;
  end

  % only use last one (since grid search is not required for builtins)
  res.xVals = xVals ; res.losses = fVals ;

  repeatData.name = solverName ;
  repeatData.losses = repeatDataLosses ;
  repeatData.xVals = repeatDataXvals ;
end

% ---------------------------------------------------------------------------
function [xVals,fVals,exitFlag] = rosenbrocker(x0, method, maxFuncEvals, oo)
% ---------------------------------------------------------------------------
%ROSENBROCKER - wrapper for the rosenbrock function.
  xVals = [] ; fVals = [] ;
  objectiveArgs = {'addNoise', oo.addNoise,  'randScale', oo.randScale} ;
  switch method
    case 'BFGS'
      args = {'Algorithm', 'quasi-newton', 'HessUpdate', 'bfgs'} ;
      solver = @fminunc ;
    case 'DFP'
      args = {'Algorithm', 'quasi-newton', 'HessUpdate', 'dfp'} ;
      solver = @fminunc ;
    case 'steepdesc'
      args = {'Algorithm', 'quasi-newton', 'HessUpdate', 'steepdesc'} ;
      solver = @fminunc ;
    case 'LM'
      args = {'Algorithm', 'levenberg-marquardt'} ;
      solver = @lsqnonlin ;
      objectiveArgs = [objectiveArgs {'leastSquares', true}] ;
  end

  % configure the solver
  solverName = func2str(solver) ;
  objective = @(x) rosenbrockwithgrad(x, objectiveArgs{:}) ;
  opts = optimoptions(solver, ...
                      'Display', 'iter', ...
                      'OutputFcn', @valsTracker, ...
                      'SpecifyObjectiveGradient', true, ...
                      'MaxFunctionEvaluations', maxFuncEvals, ...
                      'MaxIterations', oo.numIters, ...
                      args{:}) ;
  problem.x0 = x0 ;
  problem.options = opts ;
  problem.solver = solverName ;
  problem.objective = objective ;

  % Different matlab solvers unfortunately return exitflags in
  % differing output positions, so we handle that here:
  [~,~,out3,out4] = solver(problem) ;
  switch solverName
    case 'lsqnonlin', exitFlag = out4 ;
    case 'fminunc', exitFlag = out3 ;
  end

  % NOTE: we use a nested function here to gain access to the internal
  % state of the solver (allowing us to track xVals)
  % -------------------------------------------------------
	function stop = valsTracker(x, optimvalues, state)
  % -------------------------------------------------------
	  stop = false ;
		if isequal(state, 'iter')
			xVals = [xVals ; x] ;
      if isfield(optimvalues, 'fval')
        fval = optimvalues.fval ;
      else
        fval = norm(optimvalues.residual)^ 2 ; % sum of squares
      end
			fVals = [fVals ; fval] ;
		end
	end
end
