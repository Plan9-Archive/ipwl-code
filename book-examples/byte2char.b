#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Byte2char;

include "sys.m";
include "draw.m";

sys : Sys;

Byte2char : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, nil : list of string)
{
	unistring: string;
	sys = load Sys Sys->PATH;

	mu := array [] of {byte 16rce, byte 16rbc};
	(unichar, utflen, status) := sys->byte2char(mu, 0);
	unistring[len unistring] = unichar;

	if (status == 0)
	{
		sys->print("byte2char failed, invalid UTF-8 sequence\n");
	}
	else
	{
		sys->print("[%d] bytes used to create Unicode character [%s]\n",
				utflen, unistring);
	}
}
