function plot_losses(names, losses, dataset, varargin)
%TODO(samuel) - clean up & docs

  opts.finalFigure = false ;
  opts.limitIters = inf ;
  opts.logspaceXaxis = false ;
  opts.colors = getColorPalette() ;
  opts = vl_argparse(opts, varargin) ;

  clf ; h = figure(1) ;
  set(0,'defaulttextinterpreter','latex') ;
  hold on ;
  for ii = 1:numel(names)
    color = opts.colors{ii} ;
    loss = losses{ii} ;
    loss = loss(1:min(opts.limitIters, numel(loss))) ;
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
  grid ;
  a = get(gca,'XTickLabel') ;
  set(gca,'XTickLabel',a,'fontsize', 18) ;
  set(groot, 'defaultAxesTickLabelInterpreter','latex') ;
  set(groot, 'defaultLegendInterpreter','latex') ;
  legend(names, 'Location', 'northeast') ;

  if opts.finalFigure
		set(h,'Units','Inches') ;
		pos = get(h,'Position') ;
		set(h,'PaperPositionMode','Auto','PaperUnits', ...
                  'Inches','PaperSize',[pos(3), pos(4)]) ;
    if ~exist('figs', 'dir'), mkdir('figs') ; end
		print('figs/loss-trajectories.pdf', '-dpdf','-r0') ;
	end

  if exist('zs_dispFig', 'file'), zs_dispFig ; end
