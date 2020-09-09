#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement PromelaLimbo;

include "sys.m";
include "draw.m";

PromelaLimbo : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

sys 		: Sys;

NUMCHANS	: con 6;
NUMSLAVES	: con 5;
SAMPLEDCHAN	: con 5;
SAMPLE, SAMPLED : con 1 << iota;

#	Synchronous Communication Medium:
netseg := array [NUMCHANS] of chan of int;

slave(my_id : int)
{
	got_sample := 0;
	sys->print("Node %d startup\n", my_id);

	while ()
	alt
	{
		#	Wait for message type 'SAMPLE'
		msg := <-netseg[my_id] =>
		{
			if (msg == SAMPLE)
				got_sample = 1;
		}
		
		* =>
		{
			if (got_sample)
			{
				#	Send a 'SAMPLED' message
				netseg[SAMPLEDCHAN] <-= SAMPLED;
				got_sample = 0;
			}
		}
	}
}

master()
{
	nreceipts, nsent, nperiods : int = 0;

	sys->print("Master started up\n");

	while ()
	alt
	{
		* =>
		if ((nreceipts % NUMSLAVES) == 0)
		{
			nreceipts = 0;
			nsent = 0;

			while ()
			{
				if (nsent < NUMSLAVES)
				{
					netseg[nsent] <-= SAMPLE;
					nsent++;
				}
				if (nsent == NUMSLAVES)
				{
					nperiods++;
					break;
				}
			}
		}

		msg := <-netseg[SAMPLEDCHAN] =>
		{
			if (msg == SAMPLED)
				nreceipts++;
		}
	}
}

#		Initial process creates processes
init (nil : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;

	for (i := 0; i <= SAMPLEDCHAN; i++)
	{
		netseg[i] = chan of int;
	}

	spawn slave(0);
	spawn slave(1);
	spawn slave(2);
	spawn slave(3);
	spawn slave(4);

	spawn master();
}
