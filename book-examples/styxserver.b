#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement StyxServer;

include "sys.m";
include "draw.m";
include "arg.m";
include "styx.m";
include	"styxlib.m";

sys	: Sys;
arg	: Arg;
styx	: Styx;
styxlib	: Styxlib;

Styxserver, Rmsg, Tmsg, Dirtab, Chan: import styxlib;

mntflg	:= Sys->MREPL;
mntpt	:= "/n/remote/";
Qpath	: con 1;
Qvers	: con 0;

dirtab := array [] of
	{
		Dirtab("dynamic.dis", (Qpath, Qvers), big 0, 8r755)
	};

StyxServer : module
{
	init : fn(nil : ref Draw->Context, args : list of string);
};

init(nil : ref Draw->Context, args : list of string)
{
	sys = load Sys Sys->PATH;
	styxlib = load Styxlib Styxlib->PATH;
	styx = load Styx Styx->PATH;
	arg = load Arg Arg->PATH;
	arg->init(args);

	while((c := arg->opt()) != 0)
	{
		case c
		{
			'b' => mntflg = Sys->MBEFORE;
			'a' => mntflg = Sys->MAFTER;
			'r' => mntflg = Sys->MREPL;
			'c' => mntflg |= Sys->MCREATE;
             		*   =>
			{
				sys->print("Usage : styxserver [-rabc] <mount point>\n");
				exit;
			}
		}
	}
	args = arg->argv();

	if (len args != 1)
	{
		sys->print("Usage : styxserver [-rabc] <mount point>\n");
		exit;
	}
	mntpt = hd args;

	styxpipe := array [2] of ref Sys->FD;
	sys->pipe(styxpipe);

	(tmsgchan, srv) := Styxserver.new(styxpipe[0]);

	sync := chan of int;
	spawn server(tmsgchan, srv, sync);
	<-sync;

	if (sys->mount(styxpipe[1], mntpt, mntflg, nil) < 0)
	{
		sys->raise(sys->sprint("fail:StyxServer mount failed : %r"));
	}
}

server(tmsgchan : chan of ref Styxlib->Tmsg, srv : ref Styxserver, 
	sync : chan of int)
{
	devgen := styxlib->dirgenmodule();
	
	sync <-= 0;

	while ()
	{
		msg := <-tmsgchan;
		if (msg == nil)
		{
			exit;
		}

		pick m := msg
		{
			Readerror =>	sys->raise(sys->sprint(
					"fail:Styxserver error reading Styx pipe : %r"));

			Nop =>		srv.reply(ref Rmsg.Nop(m.tag));

			Attach =>	srv.devattach(m);

			Clone =>	srv.devclone(m);

			Clunk =>	srv.devclunk(m);

			Create =>	srv.reply(ref Rmsg.Error(m.tag, Styxlib->Eperm));

			Flush =>	srv.devflush(m);

			Open =>		srv.devopen(m, devgen, dirtab);

			Read =>
			{
				c := srv.fidtochan(m.fid);
				if (c == nil)
				{
					srv.reply(ref Rmsg.Error(m.tag, Styxlib->Eperm));
					break;
				}

				if (c.isdir())
				{
					srv.devdirread(m, devgen, dirtab);
					break;
				}

				srv.reply(ref Rmsg.Error(m.tag, Styxlib->Eperm));

			}

			Remove =>	srv.reply(ref Rmsg.Error(m.tag, Styxlib->Eperm));

			Stat =>		srv.devstat(m, devgen, dirtab);

			Walk =>		srv.devwalk(m, devgen, dirtab);

			Write =>	srv.reply(ref Rmsg.Error(m.tag, Styxlib->Eperm));

			Wstat =>	srv.reply(ref Rmsg.Error(m.tag, Styxlib->Eperm));
		}
	}
}
