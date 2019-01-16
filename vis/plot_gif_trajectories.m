function plot_gif_trajectories(names, xVals, cfg, varargin)
  opts.zsDisp = false ;
  opts.runId = 1 ;
  opts.format = 'png' ;
  opts.figRoot = fullfile(vl_rootnn, 'data/mcnOptim') ;
  opts.plotNoisyFunc = true;
  opts.ourMethod ='CurveBall';
  opts.colors = getColorPalette() ;
  opts = vl_argparse(opts, varargin) ;

  path = fullfile(opts.figRoot, ...
   sprintf('figs/gif_frames/sol-trajectory-%d-%%03d.%s', opts.runId, opts.format)) ;

  %res = struct() ;
  %styles = {'o-', '+--', '+-', '+-', '+-', '+-', '+-', '+-'} ;
  styles = {'+-', '+-', '+-', '+-', '+-', '+-', '+-', '+-'} ;
  %for ii = 1:numel(solvers)
    %res(ii).name = solvers{ii} ;
    %res(ii).history = rosenbrocker(x0, solvers{ii}, maxIter) ;
	%end

  %reasonable
  %xmin = -1.5 ; xmax = 1.5 ;
  %ymin = -1 ; ymax = 3 ;
	x = linspace(cfg.xmin, cfg.xmax, cfg.resolution) ;
  y = linspace(cfg.ymin, cfg.ymax, cfg.resolution) ;
	[xx,yy] = meshgrid(x,y) ;
  ins = [xx(:) yy(:)] ;
  ff = zeros(1, numel(xx)) ;

  numIters = min(cellfun(@numel, xVals)) / 2 ; % includes x,y values

  for iterIdx = 1:numIters

    figPath = sprintf(path, iterIdx) ;

    for ii = 1:size(ins, 1)
      if opts.plotNoisyFunc
        ff(ii) = rosenbrockwithgrad(ins(ii, :), ...
                                    'addNoise', opts.addNoise, ...
                                    'randScale', opts.randScale ...
                                    ) ;
      else
        ff(ii) = rosenbrockwithgrad(ins(ii, :)) ;
      end
    end
    ff = reshape(ff, size(xx)) ;

    clf ; h = figure(1) ;
    %contour(x, y, ff, cfg.levels, 'linewidth', 1.1) ;
    contourf(x, y, ff, cfg.levels, 'LineColor', [0.5 0.5 0.5]) ;
    %colorbar ;
    axis([cfg.xmin cfg.xmax cfg.ymin cfg.ymax]) ;
    axis square ;
    hold on ;
    cyan = [66, 244, 235]/255 ;
    originColor = 'red' ;
    solverPlots = cell(1, numel(names)) ;
    for ii = 1:numel(solverPlots)
      %history = res(ii).history ;
      history = squeeze(xVals{ii}) ;
      %if strcmp(names{ii}, opts.ourMethod)
        %history = [cfg.x0 ; history] ; % add missing x0
      %end
      switch names{ii}
      case {opts.ourMethod, 'BFGS', 'LM'}
        lineWidth = 4 ;
      otherwise
        lineWidth = 4 ;
      end
      % note, we skip the first step which stores default loss value
      solverPlots{ii} = plot(history(1:iterIdx,1), history(1:iterIdx,2), ...
                            styles{ii}, 'LineWidth', lineWidth, 'color', opts.colors{ii}) ;
    end
    destColor = [183, 106, 183]/255 ;
    destColor = 'red' ;
    %h1 = plot(cfg.x0(1), cfg.x0(2), ...
              %'o', ...
              %'color', originColor, ...
              %'markersize', 15, 'linewidth', 2.5) ; hold on ;
    h2 = plot(cfg.target(1), cfg.target(2), ...
              'o', ...
              'color', destColor, ...
              'markersize', 10, 'linewidth', 3) ; hold on ;
    %handles = [h1 h2 solverPlots{:}] ;
    handles = [h2 solverPlots{:}] ;
    legendNames = [{'Minimum'} names] ;
    legend(handles, legendNames, 'Location','northwest') ;
    set(0,'defaulttextinterpreter','latex') ;
    a = get(gca,'XTickLabel') ;
    set(gca,'XTickLabel',a,'fontsize', 18) ;
    set(groot, 'defaultAxesTickLabelInterpreter','latex') ;
    set(groot, 'defaultLegendInterpreter','latex') ;
    title(cfg.name, 'fontsize', 20) ; grid on ;

    %out = min(1, flipud(gray) *  100) ;
    colormap(flipud(pink)) ;

    set(h,'Units','Inches') ;
    pos = get(h,'Position') ;
    set(h,'PaperPositionMode','Auto','PaperUnits','Inches','PaperSize',[pos(3), pos(4)]) ;
    if ~exist('figs', 'dir'), mkdir('figs') ; end
    xlabel('u') ;
    ylabel('v') ;

    if mod(ii, 10) == 0
      fprintf('saving gif %d/%d frame to %s\n', iterIdx, numIters, figPath) ;
    end
    print(figPath, sprintf('-d%s', opts.format),'-r0') ;

    if opts.zsDisp
      if exist('zs_dispFig', 'file'), zs_dispFig ; end
    end
  end
end
