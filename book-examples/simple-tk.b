#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement SimpleTk;

include "sys.m";
include "draw.m";
include "tk.m";

draw	: Draw;
sys	: Sys;
tk	: Tk;

SimpleTk : module
{
	init : fn(ctxt : ref Draw->Context, nil : list of string);
};

init(ctxt : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;
	draw = load Draw Draw->PATH;
	tk = load Tk Tk->PATH;
	
	#	Create a top level Tk widget:
	t := tk->toplevel(ctxt.screen, "");

	#	Create channel on which Tk events will be sent and
	#	associate the channel with the Tk event name 'cmd':
	cmdchan := chan of string;
	tk->namechan(t, cmdchan, "cmd");

	#	Send literal strings to Tk to create a button with the
	#	text 'Push Me'. Pushing it sends the string 'pressed'
	#	on the channel associated with Tk name 'cmd':
	tk->cmd(t, "button .b -text {Push Me} -command {send cmd pressed}");
	tk->cmd(t, "pack .b");
	tk->cmd(t, "update");

	#	Wait for events on the channel `cmdchan' and service them:
	for (;;)
	alt
	{
		c := <- cmdchan =>
		{
			if (c == "pressed")
			{
				sys->print("... catch you later!\n");
				exit;
			}
		}
	}
}
