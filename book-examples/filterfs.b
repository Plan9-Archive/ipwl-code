#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement FilterFS;

include "sys.m";
include "draw.m";
include "styx.m";
include "filter.m";
include "cachelib.m";

sys : Sys;
styx : Styx;
filter : Filter;
cachelib : CacheLib;

Smsg : import styx;
Cache : import cachelib;
Filtermsg : import filter;

CACHESIZE : con 64;
fidcache : ref Cache;

FilterFS : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init(nil : ref Draw->Context, nil : list of string)
{
	sync := chan of int;
	filterpath := "printfilter.dis";


        sys = load Sys Sys->PATH;
	styx = load Styx Styx->PATH;
	cachelib = load CacheLib CacheLib->PATH;
	filter = load Filter filterpath;

	fidcache = Cache.allocate(CACHESIZE);

        sys->bind("#|", "/chan", sys->MBEFORE);
	export_pipe := array [2] of ref Sys->FD;
	mount_pipe := array [2] of ref Sys->FD;

	sys->pipe(export_pipe);
	sys->pipe(mount_pipe);

	filter->init(export_pipe, mount_pipe);

        spawn xfre2m(export_pipe, mount_pipe, sync);
        spawn xfrm2e(export_pipe, mount_pipe, sync);

	<- sync;
	<- sync;

	if (sys->export(export_pipe[0], sys->EXPASYNC))
	{
		sys->print("Error - Could not export : %r\n");
                exit;
	}

	if (sys->mount(mount_pipe[1], "/n/filterfs", sys->MREPL, nil) == -1)
	{
		sys->print("FilterFS : mount failed");
	}
}

xfre2m (export_pipe, mount_pipe : array of ref Sys->FD, sync : chan of int)
{
	sync <-= 1;

	buf := array [sys->ATOMICIO] of byte;
	while (1)
	{
		n := sys->read(export_pipe[1], buf, len buf);

		msg := data2fmsg(buf[:n]);
		filter->rewrite(msg);

		if (msg != nil)
		{
			sys->write(mount_pipe[0], fmsg2data(msg), n);
		}
	}
}

xfrm2e (export_pipe, mount_pipe : array of ref Sys->FD, sync : chan of int)
{
	sync <-= 1;

	buf := array [sys->ATOMICIO] of byte;
	while (1)
	{
		n := sys->read(mount_pipe[0], buf, len buf);

		msg := data2fmsg(buf[:n]);
		filter->rewrite(msg);

		if (msg != nil)
		{
			sys->write(export_pipe[1], fmsg2data(msg), n);
		}
	}
}

fmsg2data(fmsg : ref Filtermsg) : array of byte
{
	nentries := len fmsg.dirlist;
	for (i := 0; i < (Styx->DIRLEN*nentries); i += Styx->DIRLEN)
	{
		fmsg.styxmsg.data[i:] = styx->convD2M(hd fmsg.dirlist);
		fmsg.dirlist = tl fmsg.dirlist;
	}

	return fmsg.styxmsg.convS2M();
}

data2fmsg(buf : array of byte) : ref Filtermsg
{
	msg := ref Filtermsg;

	(n, styxmsg) := styx->convM2S(buf);
	if (n < 0)
	{
		return nil;
	}

	if ((styxmsg.mtype == Styx->Rattach)||
		(styxmsg.mtype == Styx->Rwalk)||
		(styxmsg.mtype == Styx->Ropen)||
		(styxmsg.mtype == Styx->Rcreate))
	{
		if (styxmsg.qid.path & Sys->CHDIR)
		{
			fidcache.addtocache(styxmsg.fid);
		}
	}

	if ((styxmsg.mtype == Styx->Tclone) &&
		fidcache.isincache(styxmsg.fid))
	{
		fidcache.addtocache(styxmsg.newfid);
	}

	if ((styxmsg.mtype == Styx->Tclunk) ||
		((styxmsg.mtype == Styx->Rwalk) && 
			!(styxmsg.qid.path & Sys->CHDIR)))
	{
		fidcache.delfromcache(styxmsg.fid);
	}

	msg.styxmsg = styxmsg;

	if (styxmsg.mtype == Styx->Rread)
	{
		if (fidcache.isincache(msg.styxmsg.fid))
		{
			msg.isdirread = 1;
			msg.dirlist = data2dirlist(styxmsg.data);
		}
	}

	return msg;
}

data2dirlist(buf : array of byte) : list of ref Sys->Dir
{
	dirlist : list of ref Sys->Dir;

	if (len buf % Styx->DIRLEN)
	{
		sys->print("Weird read from directory, data length [%d]\n",
				len buf);
		return nil;
	}

	for (i := 0; i < len buf; i += Styx->DIRLEN)
	{
		direntry := styx->convM2D(buf[i:i+116]);
		dirlist = direntry :: dirlist;
	}

	return dirlist;
}
