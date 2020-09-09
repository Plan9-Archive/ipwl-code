#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Fibonacci;

include "sys.m";
include "draw.m";

sys : Sys;
MAX : con 50;
x : chan of int;

Fibonacci : module
{
	init	: fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;

	x = chan of int;
	sys->print("0  .\n1  ..\n");
	spawn f(0, 1);

	<-x;
	sys->print("Spawned thread completed.\n");
}
       
f(a, b : int)
{
	sys->print("%-3d", a + b);
	for (i := 0; i <= a+b; i++)
	{
		sys->print(".");
	}
	sys->print("\n");

	if (a+b < MAX)
	{
		f(b, a+b);
	}

	x <-= 0;
}
