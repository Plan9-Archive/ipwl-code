#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Test;

include "sys.m";
include "draw.m";

Test : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, nil : list of string)
{
	channel := chan of int;

	spawn write(channel);
	spawn write(channel);

	spawn read(channel);
	spawn read(channel);
}

write(channel : chan of int)
{
	while ()
	alt
	{
		channel <-= 1 =>
			;
	}
}

read(channel : chan of int)
{
	while ()
	alt
	{
		<-channel =>
			;
	}
}
