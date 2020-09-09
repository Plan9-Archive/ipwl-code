#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement StyxHTTPtunnel;

include "sys.m";
include "draw.m";
include "string.m";
include "shtun.m";

sys		: Sys;
str 		: String;

Connection 	: import Sys;
export_pipe	: array of ref Sys->FD;
StyxMAX		: con 29;


init(nil : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;
	str = load String String->PATH;

        sys->bind("#|", "/chan", sys->MBEFORE);
	export_pipe = array [2] of ref Sys->FD;
	sys->pipe(export_pipe);

	if (sys->export(export_pipe[0], sys->EXPASYNC))
	{
		sys->print("Error - Could not export : %r\n");
                exit;
	}

	(n, conn) := sys->announce("tcp!*!"+SRVPORT);
	if (n < 0)
	{
		sys->print("StyxHTTPtunnel - announce failed : %r\n");
		exit;
	}

	while (1)
	{
		listen(conn);
	}
}

listen(conn : Connection)
{
	(ok, c) := sys->listen(conn);
	if (ok < 0)
	{
		sys->print("StyxHTTPtunnel - listen failed : %r\n");
		exit;
	}

	spawn hdlrthread(c);
}

hdlrthread(conn : Connection)
{
	#	At most, we have a full Styx message encap. in padding HTML
	buf := array [2*Sys->ATOMICIO] of byte;
	n : int = 0;


	#	The connections data file is not opened by default,
	#	must explicitly do so to accept the new connection
	rdfd := sys->open(conn.dir + "/data", Sys->OREAD);
	wdfd := sys->open(conn.dir + "/data", Sys->OWRITE);
	rfd := sys->open(conn.dir + "/remote", Sys->OREAD);

	n = sys->read(rfd, buf, len buf);
	sys->print("\nStyxHTTPtunnel : Got new connection from %s",
			string buf[:n]);

	n = sys->read(rdfd, buf, len buf);
	if (n < 1)
	{
		sys->print("Received empty request, discarding...\n");
		return;
	}

	#	Get the request from the client and deliver it to the Export
	(clientdatalen, clientdata) := requestdecode(buf[:n]);
	if (int clientdata[0] > StyxMAX)
	{
		sys->print("Bad msgtype [%d] from client", int clientdata[0]);
		return;
	}

	if (sys->write(export_pipe[1], clientdata, clientdatalen) !=
		clientdatalen)
	{
		sys->print("Could not write to export_pipe : %r");
	}

	#	Get the response from the Export and deliver it to the client
	n = sys->read(export_pipe[1], buf, len buf);
	if (n < 1)
	{
		sys->print("Empty read from export pipe\n");
		return;
	}

	if (int buf[0] > StyxMAX)
	{
		sys->raise(sys->sprint(
			"fail:Bad msgtype [%d] from Export",int buf[0]));
	}

	(n, buf) = clientfmt(buf, n);

	if (sys->write(wdfd, buf[:n], n) != n)
	{
		sys->raise(sys->sprint("fail:Could not write to wfd : %r"));
	}
}

clientfmt(buf : array of byte, size : int) : (int, array of byte)
{
	a := StyxHTTPtunnel->REPLYHDPAD;
	b := StyxHTTPtunnel->REPLYTLPAD;

	bytes := array [size+a+b] of byte;
	numbytes := len bytes;

	bytes[0:] = array of byte "<HTML><!";
	bytes[a-2] = byte (numbytes & 16rFF);
	bytes[a-1] = byte ((numbytes >> 8) & 16rFF);
	bytes[a:] = buf[:size];
	bytes[a+size:] = array of byte "></HTML>\r\n";

	return (numbytes, bytes);
}

requestdecode(body : array of byte) : (int, array of byte)
{
	a := StyxHTTPtunnel->QUERYHDPAD;
	b := StyxHTTPtunnel->QUERYTLPAD;

	return (len body - (a+b), body[a: len body - b]);
}
