#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Interloper;

include "sys.m";
include "draw.m";

sys : Sys;

Interloper : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

msgtype := array [] of
	{
		"Tnop", "Rnop", "Terror", "Rerror",
		"Tflush", "Rflush", "Tclone", "Rclone",
		"Twalk", "Rwalk", "Topen", "Ropen",
		"Tcreate", "Rcreate", "Tread", "Rread",
		"Twrite", "Rwrite", "Tclunk", "Rclunk",
		"Tremove", "Rremove", "Tstat", "Rstat",
		"Twstat", "Rwstat", "Tsession", "Rsession",
		"Tattach", "Rattach"
	};

init(nil : ref Draw->Context, nil : list of string)
{
	sync := chan of int;


	sys = load Sys Sys->PATH;
	sys->bind("#|", "/chan", sys->MBEFORE);

	export_pipe := array [2] of ref Sys->FD;
	mount_pipe := array [2] of ref Sys->FD;

	sys->pipe(export_pipe);
	sys->pipe(mount_pipe);

	spawn xfre2m(export_pipe, mount_pipe, sync);
	spawn xfrm2e(export_pipe, mount_pipe, sync);

	<- sync;
	<- sync;

	if (sys->export(export_pipe[0], sys->EXPASYNC))
	{
		sys->print("Error - Could not export : %r\n");
		exit;
	}

	if (sys->mount(mount_pipe[1], "/n/remote", sys->MREPL, nil) == -1)
	{
		sys->print("Interloper : mount failed");
	}
}

xfre2m (export_pipe, mount_pipe : array of ref Sys->FD, sync : chan of int)
{
	sync <-= 1;

	buf := array [sys->ATOMICIO] of byte;

	while (1)
	{
		n := sys->read(export_pipe[1], buf, len buf);
		sys->write(mount_pipe[0], buf, n);
		sys->print("Message type [%s] length [%d] from EXPORT --> MOUNT\n",
			msgtype[int buf[0]], n);
	}
}

xfrm2e (export_pipe, mount_pipe : array of ref Sys->FD, sync : chan of int)
{
	sync <-= 1;

	buf := array [sys->ATOMICIO] of byte;

	while (1)
	{
		n := sys->read(mount_pipe[0], buf, len buf);
		sys->write(export_pipe[1], buf, n);
		sys->print("Message type [%s] length [%d] from MOUNT --> EXPORT\n",
			msgtype[int buf[0]], n);
	}
}
