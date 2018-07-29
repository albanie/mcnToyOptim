function exp_runs(expId, varargin)
% for dev experiments, keep most things hardcoded

  rng(0) ; % fix seed
  numIters = 5000 ;

  commonArgs = {'setting', 'final', 'tolerance', 0.0001} ;

  switch expId
    % experiment with different noise levels - these will take a while to run
    case 1
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'refreshGrid', 1, 'addNoise', 0) ;
    case 2
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 1) ;
    case 3
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 2) ;
    case 4
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 3) ;
    case 5
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 4) ;

    % produce figures
    case 6
      paper_exp(commonArgs{:}, 'refreshRepeats', 0, 'numRepeats', 1, 'numIters', numIters, 'refreshGrid', 0, 'addNoise', 1, 'randScale', 3, 'x0noise', 0, 'repeatPlots', 1, 'finalFigure', 1) ;
    case 7
      paper_exp(commonArgs{:}, 'refreshRepeats', 0, 'numRepeats', 1, 'numIters', numIters, 'refreshGrid', 0, 'addNoise', 1, 'randScale', 1, 'x0noise', 0, 'repeatPlots', 1, 'finalFigure', 1) ;

    % run long sanity checks with many repeats for comparison
    case 8
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', 1000, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 1, 'x0noise', 0, 'dataset', 'rahimiRecht') ;
    case 9
      paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', 1000, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 1, 'x0noise', 0, 'dataset', 'rahimiRecht') ;

    case 10 % produce gifs for visualisation (with noise)
      numIters = 100 ;
      for ii = 1:10
        x0noise = 0 + 0.2 * ii ;
        runId = ii ;
        paper_exp(commonArgs{:}, 'refreshRepeats', 1, 'numRepeats', 1, ...
                  'numIters', numIters, 'refreshGrid', 0, ...
                  'addNoise', 1, 'randScale', 1, 'x0noise', x0noise, ...
                  'repeatPlots', 1, 'finalFigure', 1, 'gifs', 1, ...
                  'runId', runId, 'sharedX0', 1, 'logspaceXaxis', 0, 'fixedXaxis', 1) ;
      end
  end
