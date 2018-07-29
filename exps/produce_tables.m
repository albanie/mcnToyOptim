function produce_tables(colNum)

  rng(0) ; % fix seed

  numIters = 5000 ;
  switch colNum
  case 1
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', true, 'addNoise', 0) ;
  %case 2
    %paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', 1000, 'tolerance', 0.0001, 'refreshGrid', true, 'addNoise', 1, 'randScale', 1) ;
  case 2
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 1) ;
  case 3
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 2) ;
  case 4
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 3) ;
  case 5
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 4) ;
  case 6 % produce figure
    paper_exp('setting', 'final', 'refreshRepeats', 0, 'numRepeats', 1, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 0, 'addNoise', 1, 'randScale', 3, 'x0noise', 0, 'repeatPlots', 1, 'finalFigure', 1) ;
  case 7 % produce figure
    paper_exp('setting', 'final', 'refreshRepeats', 0, 'numRepeats', 1, 'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 0, 'addNoise', 1, 'randScale', 1, 'x0noise', 0, 'repeatPlots', 1, 'finalFigure', 1) ;
  case 8
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', 1000, 'tolerance', 0.0001, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 1, 'x0noise', 0, 'dataset', 'rahimi-recht') ;
  case 9
    paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 100, 'numIters', 1000, 'tolerance', 0.0001, 'refreshGrid', 1, 'addNoise', 1, 'randScale', 1, 'x0noise', 0, 'dataset', 'rahimi-recht') ;

  case 10 % produce gifs (with noise)
    numIters = 100 ;
    for ii = 1:10
      x0noise = 0 + 0.2 * ii ;
      runId = ii ;
      paper_exp('setting', 'final', 'refreshRepeats', 1, 'numRepeats', 1, ...
                'numIters', numIters, 'tolerance', 0.0001, 'refreshGrid', 0, ...
                'addNoise', 1, 'randScale', 1, 'x0noise', x0noise, ...
                'repeatPlots', 1, 'finalFigure', 1, 'gifs', 1, ...
                'runId', runId, 'sharedX0', 1, 'logspaceXaxis', 0, 'fixedXaxis', 1) ;
    end
  end
