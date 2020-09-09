#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Loader;

include "sys.m";
include "draw.m";

sys : Sys;

Loader : module
{
	init : fn (nil : ref Draw->Context, args : list of string);
};
 
S : module
{
	s : fn();
};
 
init (nil : ref Draw->Context, args : list of string)
{ 
	sys = load Sys Sys->PATH;
         
	if (len args != 2)
	{
		sys->print("Usage :: pump <file.dis>\n");
		exit;
	}
	path := hd tl args;
 
	pump := load S path;
         
	if (pump == nil)
	{ 
		sys->print("Loader :: %r\n");
		sys->print("Usage -- pump <file.dis>\n");

		exit;
	} 
         
	sys->print("Loading %s...\n", path);
	pump->s();
}
