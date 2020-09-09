#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement SHA;

include "sys.m";
include "draw.m";
include "keyring.m";

sys : Sys;
keyring : Keyring;

stdin, stderr	: ref Sys->FD;

SHA : module
{
	init : fn(nil : ref Draw->Context, args : list of string);
};

init (nil : ref Draw->Context, args : list of string)
{
	sys = load Sys Sys->PATH;
	keyring = load Keyring Keyring->PATH;

	stdin = sys->fildes(0);
	stderr = sys->fildes(2);

	args = tl args;
	if (args == nil)
	{
		sha(nil);
	}
	else while (args != nil)
	{
		sha(hd args);

		args = tl args;
	}
}

sha(filename : string)
{
	cksum	 	: string;
	n		: int;
	nbytes		: big;
	fd		: ref Sys->FD;
	digeststate 	: ref Keyring->DigestState;


	if (filename == nil)
	{
		fd = stdin;
		filename = "stdin";
	}
	else
	{
		fd = sys->open(filename, Sys->OREAD);
	}

	if (fd == nil)
	{
		sys->fprint(stderr, "SHA : Could not open input stream : %r\n");
		exit;
	}

	buf := array [Sys->ATOMICIO] of byte;
	while ((n = sys->read(fd, buf, len buf)) > 0)
	{
		digeststate = keyring->sha(buf[:n], n, nil, digeststate);
		nbytes += big n;
	}
	if (n < 0)
	{
		sys->fprint(stderr, "SHA : Could not read input stream : %r\n");
		exit;
	}

	digest := array[Keyring->SHAdlen] of byte;
	keyring->sha(buf[:n], n, digest, digeststate);

	cksum += sys->sprint("SHA (%s) = ", filename);
	for (i := 0; i < Keyring->SHAdlen; i++)
	{
		cksum += sys->sprint("%2.2ux", int digest[i]);
	}

	sys->print("%s\n", cksum);
}
