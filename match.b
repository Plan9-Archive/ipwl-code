#
#	Match: prints number of occurrences of each character in
#	supplied string argument. It is useful for debugging files
#	in, e.g. LaTeX when you're missing some matching parens.
# 
#	(C) 2003 p. Stanley-Marbell
#
#	TODO: read stdin
#
implement Unroll;

include "sys.m";
include "draw.m";

sys	: Sys;
draw	: Draw;

Unroll : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, args : list of string)
{
	sys = load Sys Sys->PATH;

	if (len args != 3)
	{
		usage();
		exit;
	}

	matches := hd tl args;
	indeces := array [len matches] of int;

	fd := sys->open(hd tl tl args, Sys->OREAD);
	if (fd == nil)
	{
		sys->raise(sys->sprint("fatal: could not open [%s] : %r",
			hd tl tl args));
	}

	buf := array [1] of byte;
	while (sys->read(fd, buf, len buf) > 0)
	{
		for (i := 0; i < len matches; i++)
		{
			if (matches[i] == int buf[0])
			{
				indeces[i]++;
			}	
		}
	}

	for (i := 0; i < len matches; i++)
	{
		sys->print("[%c]\t%d occurences\n", matches[i], indeces[i]);
	}

	return;
}

usage()
{
	sys->print("Usage: matches <string> filename\n");
}
