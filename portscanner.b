#
#	PortScanner, (C) 2003 p. Stanley-Marbell
#	pip@gemusehaken.org
#
implement PortScanner;

include "sys.m";
include "draw.m";
include "arg.m";
include "rfc1700.m";

arg	: Arg;
sys	: Sys;


PortScanner : module
{
	init : fn(nil : ref Draw->Context, args : list of string);
};

init(nil : ref Draw->Context, args : list of string)
{
        sys = load Sys Sys->PATH;
	arg = load Arg Arg->PATH;
	if (arg == nil)
	{
		sys->raise(sys->sprint("Could not load %s : %r", Arg->PATH));
	}
	arg->init(args);

	#	Defaults
	begin := 1;
	end := 65535;
	delay := 10;

	while((c := arg->opt()) != 0)
	{
		case c
		{
			'b' => begin = int arg->arg();
			'e' => end = int arg->arg();
			'd' => delay = int arg->arg();
             		*   =>
			{
				usage();
				exit;
			}
		}
	}

	if (len (args = arg->argv()) != 1)
	{
		usage();
		exit;
	}
	hostname := hd args;

	spawn tcpscan(begin, end, delay, hostname);



	return;
}

tcpscan(begin, end, delay : int, hostname : string)
{
	ok := -1;
	addr := "";
	for (i := begin; i < end; i++)
	{
		addr = "tcp!"+hostname+"!"+(string i);
		(ok, nil) = sys->dial(addr, nil);
		if (ok >= 0)
		{
			sys->print("TCP:%d\n", i);
		}

		sys->sleep(delay);
	}

}

usage()
{
	sys->print("portscanner [-b start port] [-e end port] hostname\n");

	return;
}
