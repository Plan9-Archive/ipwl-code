#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement StyxHTTPtunnelClient;

include "sys.m";
include "draw.m";
include "arg.m";
include "shtun.m";

arg	: Arg;
sys	: Sys;
	
srvaddr, srvport, mntdir	: string;
INITSYNC			: con 1;

StyxHTTPtunnelClient : module
{
	init : fn(nil : ref Draw->Context, args : list of string);
};

init(nil : ref Draw->Context, args : list of string)
{
	sys = load Sys Sys->PATH;
	arg = load Arg Arg->PATH;
	arg->init(args);

	#	Defaults
	mntdir = "/n/remote";
	srvport = SRVPORT;
	srvaddr = SRVADDR;
	while((c := arg->opt()) != 0)
	{
		case c
		{
			's' => srvaddr = arg->arg();
			'p' => srvport = arg->arg();
			'm' => mntdir = arg->arg();
			*   =>
			{
				usage();
				exit;
			}
		}
	}
	if (arg->argv() != nil)
	{
		usage();
		exit;
	}

	(there, nil) := sys->stat("/net/cs");
	if (there == -1)
	{
		cs := load StyxHTTPtunnelClient "/dis/lib/cs.dis";
		if (cs == nil)
		{
			sys->raise(sys->sprint(
				"fail:Could not load /dis/lib/cs.dis : %r"));
		}
		cs->init(nil, nil);
	}

	sys->bind("#|", "/chan", sys->MBEFORE);
	mount_pipe := array [2] of ref Sys->FD;
	sys->pipe(mount_pipe);

	#	Mount will block if it can't send Tattach
	sync := chan of int;
	spawn xfrm2web(mount_pipe[0], sync);

	<- sync;

	spawn mountthread(mount_pipe[1]);
}

usage()
{
	sys->print(
		"Usage: shtunclient [-s <server addr>][-p port][-m mountpoint]\n");
}

mountthread(mountfd : ref Sys->FD)
{
	if (sys->mount(mountfd, mntdir, sys->MREPL, nil) == -1)
	{
		sys->print("Shtunclient : mount failed : [%r]\n");
		exit;
	}

	sys->print("ShtunClient : Remote end of tunnel mounted in %s\n", mntdir);
}

xfrm2web(mountfd : ref Sys->FD, sync : chan of int)
{
	#	We must fork namespace so that if after running, 
	#	say, user binds /n/remote/net to /net, we can 
	#	still maintain tunnel.
	sys->pctl(Sys->FORKNS, nil);

	sync <-= INITSYNC;

	dialaddr := "tcp!" + srvaddr + "!" + srvport;

	#	We could be reading Sys->ATOMICIO + Styx headers + HTML headers
	buf := array [2*Sys->ATOMICIO] of byte;
	while (1)
	{
		n := sys->read(mountfd, buf, len buf);
		if (n < 1)
		{
			sys->print(
				"mount->web: Empty read from rdfd: %r.\n");

			return;
		}

		(ok, net) := sys->dial(dialaddr, nil);
		if (ok < 0)
		{
			sys->print("Could not dial %s: %r\n", dialaddr);
			exit;
		}

		(requestlen, request) := webfmt(buf[:n], n);
		if (sys->write(net.dfd, request, requestlen) != requestlen)
		{
			sys->print("Could not write to net.dfd : %r\n");
			exit;
		}

		n = sys->read(net.dfd, buf, len buf);

		#	We need at least the header, which encodes the length
		#	that must be read. Yuck : implement a mechanism to
		#	recover from such a runt read.
		if (n < StyxHTTPtunnel->REPLYHDPAD)
		{
			sys->sprint("xfrweb2m : could short read from webfd : %r\n");

			#	Yuck : we shouldnt just bail out like this:
			exit;
		}

		encodedlen := int buf[StyxHTTPtunnel->REPLYHDPAD-2] +
				((int buf[StyxHTTPtunnel->REPLYHDPAD-1]) << 8);

		while (n < encodedlen)
		{
			n += sys->read(net.dfd, buf[n:], len buf);
		}

		(styxlen, styxdata) := webdecode(buf[:n], n);

		if (sys->write(mountfd, styxdata, styxlen) != styxlen)
		{
			sys->print("xfrweb2m : could not write to mountfd : %r\n");
		}
	}
}

webfmt(buf : array of byte, nbytes : int) : (int, array of byte)
{
	a := StyxHTTPtunnel->QUERYHDPAD;
	b := StyxHTTPtunnel->QUERYTLPAD;

	query := array [nbytes + a + b] of byte;

	query[0:] = array of byte 
		("GET / HTTP/1.0\r\nHost: none\r\nAccept: ");

	query[a:] = buf[:nbytes];
	query[a+nbytes:] = array of byte "\r\n\r\n";

	return (len query, query);
}

webdecode(buf : array of byte, nbytes : int) : (int, array of byte)
{
	a := StyxHTTPtunnel->REPLYHDPAD;
	c := StyxHTTPtunnel->REPLYTLPAD;

	return (nbytes - (a+c), buf[a: nbytes - c]);
}
