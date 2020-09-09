#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement SimpleHTTPD;

include "sys.m";
include "draw.m";

sys	: Sys;
Connection : import Sys;

SimpleHTTPD : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;

	#	First, announce the service. This creates a line directory
	#	and conn.cfd will be open on the ctl file
	(n, conn) := sys->announce("tcp!*!1984");
	if (n < 0)
	{
		sys->print("SimpleHTTPD - announce failed : %r\n");
		exit;
	}

	#	Now, listen for incoming connections, spawn new thread
	#	for each incoming connection.
	while (1)
	{
		listen(conn);
	}
}

listen(conn : Connection)
{
	buf := array [sys->ATOMICIO] of byte;
	
	(ok, c) := sys->listen(conn);
	if (ok < 0)
	{
		sys->print("SimpleHTTPD - listen failed : %r\n");
		exit;
	}

	#	Create a new thread to handle this connection
	rfd := sys->open(conn.dir + "/remote", Sys->OREAD);

	#	The client IP is not yet set at this point. The following will
	#	therefore show the client IP as 0.0.0.0!0:
	n := sys->read(rfd, buf, len buf);
	sys->print("SimpleHTTPD : Got new connection from (incomplete) %s\n",
			string buf[:n]);

	spawn hdlrthread(c);
}

hdlrthread(conn : Connection)
{
	buf := array [sys->ATOMICIO] of byte;

	#	The connections data file is not opened by default,
	#	must explicitly do so to accept the new connection
	rdfd := sys->open(conn.dir + "/data", Sys->OREAD);
	wdfd := sys->open(conn.dir + "/data", Sys->OWRITE);
	rfd := sys->open(conn.dir + "/remote", Sys->OREAD);

	#	The client IP is now available, once we have accepted connection.
	#	The following will print the actual client IP address:
	n := sys->read(rfd, buf, len buf);
	sys->print("SimpleHTTPD : Got new connection from %s\n",
			string buf[:n]);

	while (sys->read(rdfd, buf, len buf) >= 0)
	{
		sys->write(wdfd,
				array of byte "<HTML><BODY>Hello!</BODY></HTML>\n", 
				len "<HTML><BODY>Hello!</BODY></HTML>\n");

		return;
	}
}
