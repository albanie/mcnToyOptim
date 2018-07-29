function plot_loss_gifs(names, losses, dataset, varargin)
%PLOT_LOSS_GIFS generate gif visualisations of the solvers

  opts.finalFigure = false ;
  opts.limitIters = inf ;
  opts.logspaceXaxis = false ;
  opts.zsDisp = false ;
  opts.figRoot = fullfile(vl_rootnn, 'data/mcnOptim') ;
  opts.fixedXaxis = false ;
  opts.runId = 1 ;
  opts.format = 'png' ;
  opts.colors = getColorPalette() ;
  opts = vl_argparse(opts, varargin) ;

  path = fullfile(opts.figRoot, ...
            sprintf('figs/gif_frames/loss-trajectory-%d-%%03d.%s', opts.runId, opts.format)) ;

  clf ; h = figure(1) ;
  set(0,'defaulttextinterpreter','latex') ;
  hold on ;

  numIters = min(cellfun(@numel, losses)) ;

  for ii = 1:numIters

    figPath = sprintf(path, ii) ;

    for jj = 1:numel(names)
      color = opts.colors{jj} ;
      loss = losses{jj} ;
      numIterShow = min(numel(loss), ii) ;
      loss = loss(1:numIterShow) ;
      plot(loss, 'color', color, 'LineWidth', 2) ;
    end
    ylim([1E-10 1E3]) ;
    set(gca, 'YScale', 'log') ;
    xlabel('Num. Iterations') ;
    ylabel('Loss') ;
    title(dataset, 'fontsize', 24) ;
    if opts.logspaceXaxis
      set(gca, 'XScale', 'log') ;
    end
    if opts.fixedXaxis
      xlim([0, numIters]) ;
    end
    grid on ;
    a = get(gca,'XTickLabel') ;
    set(gca,'XTickLabel', a, 'fontsize', 18) ;
    set(groot, 'defaultAxesTickLabelInterpreter','latex') ;
    set(groot, 'defaultLegendInterpreter','latex') ;
    %legend(names, 'Location', 'southwest') ;

    set(h,'Units','Inches') ;
    pos = get(h,'Position') ;
    set(h,'PaperPositionMode', 'Auto', 'PaperUnits', ...
        'Inches', 'PaperSize', [pos(3), pos(4)]) ;
    figDir = fileparts(figPath) ;
    if ~exist(figDir, 'dir'), mkdir(figDir) ; end
    if mod(ii, 10) == 0
      fprintf('saving gif %d/%d figure to %s\n', ii, numIters, figPath) ;
    end
    print(figPath, sprintf('-d%s', opts.format),'-r0') ;

    if opts.zsDisp
      if exist('zs_dispFig', 'file'), zs_dispFig ; end
    end
  end
