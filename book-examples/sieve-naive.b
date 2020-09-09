#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Eratosthenes;

include "sys.m";
include "draw.m";

sys : Sys;

Eratosthenes : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;

	i := 2;
	sourcechan := chan of int;
	spawn sieve(i, sourcechan);

	while ()
	{
		sourcechan <-= i++;
	}
}

sieve(ourprime : int, inchan : chan of int)
{
	n : int;

	sys->print("%d ", ourprime);
	newchan := chan of int;

	while (!((n = <-inchan) % ourprime))
	{
	}

	spawn sieve(n, newchan);

	while ()
	{
		if ((n = <-inchan) % ourprime)
		{
			newchan <-= n;
		}
	}
}
