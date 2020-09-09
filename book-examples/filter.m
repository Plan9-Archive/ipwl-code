#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
Filter : module
{
	filtername : string;

	Filtermsg : adt
	{
		styxmsg		: ref Styx->Smsg;
		isdirread	: int;
		dirlist		: list of ref Sys->Dir;
	};

	rewrite	: fn(msg : ref Filtermsg);
	init	: fn(exportfd, mountfd : array of ref Sys->FD);
};
