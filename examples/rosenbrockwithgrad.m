function [f, g, h] = rosenbrockwithgrad(x, varargin)

  opts.leastSquares = false ;
  opts.addNoise = false ;
  opts.negCurvature = false ;
  opts.randScale = 1 ; % this is the scale recommended by Yang and Deb
  opts.returnHessian = false;
  opts = vl_argparse(opts, varargin) ;

  if nargout > 1, returnGradient = true ; else, returnGradient = true ; end

  % transform to stochastic rosenbrock, as described in:
  % "Engineering Optimisation by Cuckoo Search", Yang and Deb, 2010
  if opts.addNoise
    epsilon = opts.randScale * rand ; % uniform noise U[0,1] (optionally scaled)
  else
    epsilon = 1 ; % produces deterministic (i.e. standard) rosenbrock
  end

  if opts.leastSquares
    % compute the vector of predictions that would be passed to the
    % least squares loss
    %sqrt_eps = (epsilon .^ 0.5) ;
    %assert(sqrt_eps == sqrt(epsilon), 'uh oh') ;
    f = [epsilon * 10*(x(2) - x(1)^2), 1 - x(1)] ;
    if returnGradient
      g = 2*[epsilon * -20*x(1), epsilon * 10 ; -1, 0]; % Jacobian
    end
  else
    eps_sqrd = epsilon ^ 2 ;
    f = eps_sqrd*100*(x(2) - x(1)^2)^2 + (1-x(1))^2; % Calculate objective f
    if returnGradient
      g = [-eps_sqrd * 400*(x(2)-x(1)^2)*x(1)-2*(1-x(1)) ; ...
           eps_sqrd * 200*(x(2)-x(1)^2)];
    end
    if opts.returnHessian
      h = [-eps_sqrd*400*(x(2)-3*x(1)^2)+2, -eps_sqrd*400*x(1) ; ...
            -eps_sqrd*400*x(1), eps_sqrd*200];
    else
      return;
    end
  end

end
