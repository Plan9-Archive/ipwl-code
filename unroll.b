#
#	Unroll: unrolls a text file into characters, one per line
#	(C) 2003 p. Stanley-Marbell
#
#	TODO: read stdin by default
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

	if (len args != 2)
	{
		usage();
		exit;
	}

	fd := sys->open(hd tl args, Sys->OREAD);
	if (fd == nil)
	{
		sys->raise(sys->sprint("fatal: could not open [%s] : %r",
			hd tl args));
	}

	i := 0;
	n := 0;
	buf := array [1] of byte;
	while (sys->read(fd, buf, len buf) > 0)
	{
		sys->print("%c\n", int buf[0]);
	}

	return;
}

usage()
{
	sys->print("Usage: unroll <filename>\n");
}
