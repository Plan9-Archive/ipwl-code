#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Filter;

include "sys.m";
include "string.m";
include "styx.m";
include "filter.m";

sys : Sys;
styx : Styx;
str : String;
Smsg : import styx;

init(nil, nil : array of ref Sys->FD)
{
	sys = load Sys Sys->PATH;

	styx = load Styx Styx->PATH;
	if (styx == nil)
	{
		sys->raise(sys->sprint("fail:Could not load %s : %r",
				Styx->PATH));
	}

	str = load String String->PATH;
	if (styx == nil)
	{
		sys->raise(sys->sprint("fail:Could not load %s : %r",
				String->PATH));
	}

	filtername = "Canon Filter : Canonicalizes file names with whitespace.";
}

rewrite(fmsg : ref Filtermsg)
{
	newlist : list of ref Sys->Dir;

	if (fmsg.styxmsg.mtype == Styx->Rstat)
	{
		direntry := styx->convM2D(fmsg.styxmsg.stat);
		canondir(direntry);
		fmsg.styxmsg.stat = styx->convD2M(direntry);
	}

	if (fmsg.styxmsg.mtype == Styx->Twalk)
	{
		fmsg.styxmsg.name = decanon(fmsg.styxmsg.name);
	}

	if (fmsg.isdirread && (len fmsg.dirlist > 0))
	{
		while (fmsg.dirlist != nil)
		{
			item := hd fmsg.dirlist;
			canondir(item);
			newlist = item :: newlist;

			fmsg.dirlist = tl fmsg.dirlist;
		}

		fmsg.dirlist = newlist;
	}	
}

canondir(item : ref Sys->Dir)
{
	#	BUG : should also cater for long filenames,
	#	with possible identical stems
	for (i := 0; i < len (*item).name; i++)
	{
		if ((*item).name[i] == ' ')
		{
			(*item).name[i] = '?';
		}
	}
}

decanon(name : string) : string
{
	#	BUG : this reversion should only happen for
	#	files that we canonicalized in the first place
	for (i := 0; i < len name; i++)
	{
		if (name[i] == '?')
		{
			name[i] = ' ';
		}
	}

	return name;
}
