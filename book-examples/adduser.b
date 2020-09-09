#
#       Software from the book "Inferno Programming with Limbo"
#	published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Adduser;

include "sys.m";
include "draw.m";
include "arg.m";

sys : Sys;
arg : Arg;

Adduser : module
{
	init : fn(nil : ref Draw->Context, args : list of string);
};

init(nil : ref Draw->Context, args : list of string)
{
	sys = load Sys Sys->PATH;
	arg = load Arg Arg->PATH;
	arg->init(args);

	#	Defaults
	username	:= "";
	homedir		:= "/usr/";
	namespace	:= "";
	error		:= "";

	while((c := arg->opt()) != 0)
	{
		case c
		{
			'u' => username = arg->arg();
			'h' => homedir = arg->arg();
			'n' => namespace = arg->arg();
			*   =>
			{
				usage();
				exit;
			}
		}
	}
	if (arg->argv() != nil)
	{
		usage();
		exit;
	}

	if (homedir[(len homedir) - 1] != '/')
	{
		homedir += "/";
	}

	if (username == nil)
	{
		(username, homedir, namespace) = prompt();
	}
	
	error = createdirs(username, homedir, namespace);
	if (error != nil)
	{
		sys->print("%s\n", error);
	}
}

createdirs(username, homedir, namespace : string) : string
{
	#	Create home directory. Omode for create must be OREAD:
	if (sys->create(homedir+username, 
		Sys->OREAD, 8r755|Sys->CHDIR) == nil)
	{
		return sys->sprint(
			"Could not create user home directory (%s) : %r",
			homedir+username);
	}

	#	Create keyring/ directory. Omode for create must be OREAD:
	if (sys->create(homedir+username+"/keyring",
		Sys->OREAD, 8r755|Sys->CHDIR) == nil)
	{
		return sys->sprint(
			"Could not create user's keyring directory (%s) : %r",
			homedir+username+"/keyring");
	}

	#	Create lib/ directory. Omode for create must be OREAD:
	if (sys->create(homedir+username+"/lib",
		Sys->OREAD, 8r755|Sys->CHDIR) == nil)
	{
		return sys->sprint(
			"Could not create user's lib directory (%s) : %r",
			homedir+username+"/lib");
	}

	#	Create namespace file. Omode for create here is ORDWR
	#	since we'll write:
	if ((fd := sys->create(homedir+username+"/namespace",
			Sys->ORDWR, 8r644)) == nil)
	{
		return sys->sprint(
			"Could not create user's lib directory (%s) : %r",
			homedir+username+"/namespace");
	}

	sys->fprint(fd, "%s\n", namespace);
	fd = nil;

	return nil;
}

usage()
{
	sys->print("adduser -u <username> [-h homedir][-n namespace string]\n");
}

prompt() : (string, string, string)
{
	buf := array [Sys->ATOMICIO] of byte;
	stdin := sys->fildes(0);

	sys->print("User name: ");
	n := sys->read(stdin, buf, len buf);
	username := string buf[:n-1];

	sys->print("Home directory: ");
	n = sys->read(stdin, buf, len buf);
	homedir := string buf[:n-1];
	if (homedir[(len homedir) - 1] != '/')
	{
		homedir += "/";
	}

	sys->print("Namespace config string: ");
	n = sys->read(stdin, buf, len buf);
	namespace := string buf[:n-1];


	return (username, homedir, namespace);
}
