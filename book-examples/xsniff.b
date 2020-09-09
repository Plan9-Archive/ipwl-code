#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Xsniff;

include "sys.m";
include "draw.m";
include "arg.m";
include "xsniff.m";

Xsniff : module
{
	DUMPBYTES : con 32;

	init : fn(nil : ref Draw->Context, args : list of string);
};

sys		: Sys;
arg		: Arg;
verbose		:= 0;
etherdump	:= 0;
dumpbytes	:= DUMPBYTES;

init(nil : ref Draw->Context, args : list of string)
{
	n	: int;
	buf 	:= array [Sys->ATOMICIO] of byte;

	sys = load Sys Sys->PATH;
	arg = load Arg Arg->PATH;
	
	dev := "/net/ether0";
	arg->init(args);
	while((c := arg->opt()) != 0)
	{
		case c
		{
			'v' => verbose = 1;
			'e' => etherdump = 1;
			'b' => dumpbytes = int arg->arg();
			'd' => dev = arg->arg();
			* =>   usage();
		}
	}
	args = arg->argv();

	tmpfd := sys->open(dev+"/clone", sys->OREAD);
	if ((n = sys->read(tmpfd, buf, len buf)) < 1)
	{
		fatal("Could not read "+dev+"/clone : "+
			sys->sprint("[%r]"));
	}

	(nil, dirstr) := sys->tokenize(string buf[:n], " \t");
	channel := int (hd dirstr);

	infd := sys->open(dev+sys->sprint("/%d/data", channel),
			sys->ORDWR);
	if (infd == nil)
	{
		fatal(dev+sys->sprint("/%d/data : [%r]", channel));
	}

	sys->print("Sniffing on %s/%d...\n", dev, channel);
	tmpfd = sys->open(dev+sys->sprint("/%d/ctl", channel), 
		sys->ORDWR);
	if (tmpfd == nil)
	{
		fatal(dev+sys->sprint("/%d/ctl : [%r]", channel));
	}
	
	#	Get all packet types
	if (sys->fprint(tmpfd, "connect -1") < 0)
	{
		fatal("setting interface for all packet types : "+
			sys->sprint("%r"));
	}

	if (sys->fprint(tmpfd, "promiscuous") < 0)
	{
		fatal("setting interface promiscuous failed : "+
			sys->sprint("%r"));
	}

	spawn reader(infd, args);
}

reader(infd : ref Sys->FD, args : list of string)
{
	n 	: int;	
	ethptr 	: ref Ether;
	fmtmod	: XFmt;


	ethptr = ref Ether(array [6] of byte,
			array [6] of byte,
			array [Sys->ATOMICIO] of byte,
			0);

	while (1)
	{
		n  = sys->read(infd, ethptr.data, len ethptr.data);
		if (n < 0)
		{
			fatal("error reading from fd : "+sys->sprint("%r"));
		}

		ethptr.pktlen = n - len ethptr.rcvifc;
		ethptr.rcvifc = ethptr.data[0:6];
		ethptr.dstifc = ethptr.data[6:12];

		#	Construct a new module name based on payload type
		#	This 'computed' module name will then be used to
		#	load an appropriate formatting module:
		nextproto := "ether"+sys->sprint("%4.4X", 
				(int ethptr.data[12] << 8) | 
				(int ethptr.data[13]));

		#	We only load new format module if it is not already
		#	loaded. We use the module data item fmtmod->ID to
		#	keep state within the loaded instance
		if ((fmtmod == nil) || (fmtmod->ID != nextproto))
		{
			fmtmod = load XFmt XFmt->BASEPATH + 
					nextproto + ".dis";

			if (fmtmod == nil)
			{
				continue;
			}
		}

		#	Call the loaded format module's formatter:
		(err, nil) := fmtmod->fmt(ethptr.data[14:], args);
	}

	return;
}

b2s(a : array of byte, n : int) : string
{
	tmp, s : string;

	#	Convert an n-byte array to a 2n Hex character string
	for (i := 0; i < n; i++)
	{
		tmp = sys->sprint("%2.2X", int a[i]);

		#	Grow by pushing the ceiling
		s[len s] = tmp[0];
		s[len s] = tmp[1];
	}

	return s;
}

usage()
{
	sys->print(
		"sniff [-e][-v][-d device][-b <# of Ethernet bytes to dump>]\n");
}

fatal(s : string)
{
	sys->print("Sniff FATAL :: %s\n", s);

	kill(sys->pctl(0, nil));
}

kill(pid: int)
{
	fd := sys->open("#p/"+string pid+"/ctl", sys->OWRITE);

	if (fd != nil)
	{
		sys->fprint(fd, "kill");
	}
}
