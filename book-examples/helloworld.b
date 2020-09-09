#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement HelloWorld;

include "sys.m";
include "draw.m";
include "helloworld.m";


init(ctxt : ref Draw->Context, args : list of string)
{
	sys : Sys;
                
	#	This is a comment
	sys = load Sys Sys->PATH;

	sys->print("Hello World !");
}
