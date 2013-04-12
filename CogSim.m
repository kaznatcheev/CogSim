function [stCount, rhoCount, intCount] = ...
	CogSim( epMax, latSize, benefit, cost, tagNum, mutRate, neighSize, ...
        defPTR, death, seedSize, cogCost)

%[stCount, rhoCount, intCount] = CogSim( N, l, b, c, t, m, n, r, d, s, g)
%	CogSim runs a modified version of the Hammond and Axelrod simulation
%	in particular, the modifications are:
%		[1] Immigration is a one time batch at the start of the simulation
%		with 4*s*t agents distributed uniformly across the 4 strategies and
%		m tags. These agents are placed randomly in the l-by-l toroidal
%		lattice. If the total population reaches zero, then the world is
%		reseeded. This is in contrast to Hammond and Axelrod's use of one
%		randomly generated agent per cycle.
%		[2] The reproduction and death rate(d) act on the same population
%		and thus correspond (avgPTR - d) corresponds to the average growth
%		rate of the population. This is contrast by Hammond and Axelrod's
%		use of d. They let reproduction happen first, added the children to
%		the lattice and only then let death happen: this caused d to act on
%		a larger population that avgPTR.
%		[3] Neighbourhood size is variable and controlled by the n 
%		parameter. Although agents always interact with their 4 adjacent
%		neighbours, they can place children in a circle of radius n around
%		them. In a lattice, a circle of radius n means all cells that are
%		within Manhattan distance n or lower. The Hammond and Axelrod
%		simulation corresponds to n = 1, and the inviscid environment to
%		n = l - 1.
%		[4] Instead of trying all 4 adjacent cells, to see if one of them
%		is empty, this code will select just one cell at random inside the
%		circle of radius n around the parent and place the child there if
%		empty.
%		[5] A cost to ptr will be associated with being one of the
%		strategies that makes decisions (i.e. ethnocentric or traitorous)
%	If you want some parameter to be set to the default value, simply enter
%	[] in its place or (if it is a trailing parameter) leave it out of. The
%	parameters of the simulation are (their default value is listen in
%	brackets):
%		N - the number of epochs to simulate for. (1000)
%		l - the size of the lattice. (50)
%		b - the benefit of cooperating. (0.03)
%		c - the cost of cooperating. (0.01)
%		t - the number of tags in the simulation. (4)
%		m - the mutation rate. (0.005)
%		n - the size of the child placement neighbourhood. (1)
%		r - the default probability to reproduce. (0.11)
%		d - the death rate (probability to expire). (0.10)
%		s - the seed size (refer to point [1]). (5)
%		g - the cost of cognition
%	The output is formatted as follows:
%		stCount[e,s,t]	- contains the number of agents of strategy s and
%			tag t at epoch e in the lattice.
%		rhoCount[e,s,b]	- contains the total number of interactions
%			agents of strategy s had with same strain (if b = 1) or with
%			other strains (if b = 2) on epoch e.
%		intCount[e,b]	- contains the number of cooperative (if b = 1) or
%			defective (if b = 2) interactions during epoch e.
%
%Implemented and designed by Artem Kaznatcheev (October 7-8, 2009).
%Modified slightly on March 28, 2013.

%----------------------------
% Check and set patameters
%----------------------------

if (nargin < 10) || isempty(seedSize),
	seedSize = 5;
end;
if (nargin < 9) || isempty(death),
	death = 0.10;
end;
if (nargin < 8) || isempty(defPTR),
	defPTR = 0.11;
end;
if (nargin < 7) || isempty(neighSize),
	neighSize = 1;
end;
if (nargin < 6) || isempty(mutRate),
	mutRate = 0.005;
end;
if (nargin < 5) || isempty(tagNum),
	tagNum = 4;
end;
if (nargin < 4) || isempty(cost),
	cost = 0.01;
end;
if (nargin < 3) || isempty(benefit),
	benefit = 0.03;
end;
if (nargin < 2) || isempty(latSize),
	latSize = 50;
end;
if (nargin < 1) || isempty(epMax),
	epMax = 1000;
end;

%--------------------------------
% Initialize useful parameters
%--------------------------------

%stratNum and pMat are in case we want to include other games later
pMat = [(benefit - cost),(0 - cost);benefit, 0]; %the game matrix
stratNum = length(pMat);
%xDim and yDim are just in case we want to modify this later
xDim = latSize;
yDim = latSize;


stCount = zeros(epMax,stratNum^2,tagNum);
rhoCount = zeros(epMax,stratNum^2,2);
intCount = zeros(epMax,stratNum);

%Create the empty world
torStratIn = zeros(latSize,yDim);
%in torStratIn, values mean the following
% 0 - empty
% 1 - in-group cooperator
% 2 - in-group defector

torStratOut = zeros(xDim,yDim);
%in torStratOut, values mean the following
% 0 - empty
% 1 - out-group cooperator
% 2 - out-group defector

torTag = zeros(xDim,yDim);
%in torTag, values mean the following
% 0 - empty
% n - tag n

seedCount = 0;

%----------------------
% Start the main loop
%----------------------

for epoch = 1:epMax,
	%---------------------
	% Seed world if empty
	%---------------------
	
	if ~sum(sum(torTag)),
		torStratIn = zeros(xDim,yDim);
		torStratOut = zeros(xDim,yDim);
		torTag = zeros(xDim,yDim);
		for seed = 1:seedSize,
			for tag = randperm(tagNum),
				for in = randperm(stratNum),
					for out = randperm(stratNum),
						x = ceil(xDim*rand);
						y = ceil(yDim*rand);
						torTag(x,y) = tag;
						torStratIn(x,y) = in;
						torStratOut(x,y) = out;
					end;
				end;
			end;
		end;
		seedCount = seedCount + 1
	end;
	
	%-----------------------------------------------
	% Start the interaction/check reproduction loop
	%-----------------------------------------------
	
	repList = [];
	%repList will have the following values for each dim:
	% [x y in out tag] where 
	%   (x, y) are the coordinates
	%   (in, out) is the strategy, and
	%   tag the tag; all of the parent
	repSize = 0;
	
	for x = 1:xDim,
		for y = 1:yDim,
			if torTag(x,y), %does an agent live here?
				ptr = defPTR; %reset PTR to default
				
				%check if agent is an ethnocentric or traitorous agent
				if torStratIn(x,y) ~= torStratOut(x,y),
					ptr = ptr - cogCost;
				end;
				
				%--------------------------
				% Interact with neighbours
				%--------------------------
				
				%intSize is included in case we want to modify the
				%interaction neighbourhoods later. Plus, it simplifies the
				%code a little bit.
				intSite = [...
					x, mod(y - 2,yDim) + 1;
					x, mod(y,yDim) + 1;
					mod(x - 2,xDim) + 1, y;
					mod(x ,xDim) + 1, y];
				
				for i = 1:length(intSite),
					%write down the partner
					xx = intSite(i,1);
					yy = intSite(i,2);
					
					if torTag(xx,yy) == torTag(x,y),
						ptr = ptr + pMat(torStratIn(x,y),torStratIn(xx,yy));
						
						intCount(epoch,torStratIn(x,y)) = ...
							intCount(epoch,torStratIn(x,y)) + 1;
						
						%check if same strain
						sIndex = ... 
							stratNum*(torStratIn(x,y)-1)+torStratOut(x,y);
						if ((torStratIn(x,y) == torStratIn(xx,yy)) & ...
							(torStratOut(x,y) == torStratOut(xx,yy))),
							rhoCount(epoch,sIndex,1) = ...
								rhoCount(epoch,sIndex,1) + 1;
						else %different strain
							rhoCount(epoch,sIndex,2) = ...
								rhoCount(epoch,sIndex,2) + 1;
						end;
						
					elseif torTag(xx,yy) > 0,
						ptr = ...
							ptr + pMat(torStratOut(x,y),torStratOut(xx,yy));
						
						intCount(epoch,torStratOut(x,y)) = ...
							intCount(epoch,torStratOut(x,y)) + 1;
						
						sIndex = ...
							stratNum*(torStratIn(x,y) - 1) + torStratOut(x,y);
						%we know they are not the same strain
						rhoCount(epoch,sIndex,2) = ...
								rhoCount(epoch,sIndex,2) + 1;
					end;
				end;
				
				%-----------
				% Reproduce
				%-----------
				
				if (rand < ptr), %enough ptr to reproduce?
					repSize = repSize + 1;
					
					repList(repSize,1) = x;
					repList(repSize,2) = y;
					repList(repSize,3) = torStratIn(x,y);
					repList(repSize,4) = torStratOut(x,y);
					repList(repSize,5) = torTag(x,y);
				end;
			end;
		end;
	end;
	
	%-------------
	% Kill agents
	%-------------
	
	liveSites = (death*ones(xDim,yDim) < rand(xDim,yDim));
	torTag = torTag.*liveSites;
	torStratIn = torStratIn.*liveSites;
	torStratOut = torStratOut.*liveSites;
	
	%----------------
	% Place children
	%----------------
	
	for i = randperm(repSize),
		[xO,yO] = RNOGen(neighSize); %generate a random placement offset
		
		x = repList(i,1);
		y = repList(i,2);
		
		%figure out where in lattice offset places us
		xx = mod(x + xO - 1,xDim) + 1;
		yy = mod(y + yO - 1,yDim) + 1;
		
		reTries = 5;
		
		while torTag(xx,yy)&reTries,
			[xO,yO] = RNOGen(neighSize); %generate a random placement offset
			
			%figure out where in lattice offset places us
			xx = mod(x + xO - 1,xDim) + 1;
			yy = mod(y + yO - 1,yDim) + 1;
			
			reTries = reTries - 1;
		end;
		
		if ~torTag(xx,yy), %is the site empty?
			if (rand > mutRate),
				torStratIn(xx,yy) = repList(i,3);
				torStratOut(xx,yy) = repList(i,4);
				torTag(xx,yy) = repList(i,5);
			else %if mutation, then change strain
				torStratIn(xx,yy) = ...
					mod(ceil((stratNum - 1)*rand) + repList(i,3) - 1,stratNum) + 1;
				torStratOut(xx,yy) = ...
					mod(ceil((stratNum - 1)*rand) + repList(i,4) - 1,stratNum) + 1;
				torTag(xx,yy) = ...
					mod(ceil((tagNum - 1)*rand) + repList(i,5) - 1,tagNum) + 1;
			end;
		end;
	end;
	
	%------------------------------
	% Record strategy distribution
	%------------------------------
	
	for i = 1:stratNum,
		for j = 1:stratNum,
			for t = 1:tagNum,
				stCount(epoch,stratNum*(i-1) + j,t) = ...
					sum(sum((torStratIn==i).*(torStratOut==j).*(torTag==t)));
			end;
		end;
	end;
end;