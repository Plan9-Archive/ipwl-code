#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement RGBSliders;

include "sys.m";
include "draw.m";
include "tk.m";
include	"wmlib.m";

sys	: Sys;
draw	: Draw;
tk	: Tk;
wmlib	: Wmlib;

RGBSliders: module
{
	init : fn(ctxt: ref Draw->Context, nil: list of string);
};

sliders_cfg := array[] of
{
	"frame .f2",
	"frame .f2.c -bg black -width 100 -height 100",
	"label .f2.l -text {#000000}",
	"frame .f",
	"scale .f.r -from 0 -to 255 -height 100 -orient vertical "+
		"-showvalue 1 -command {send cmd r}",
	"scale .f.g -from 0 -to 255 -height 100 -orient vertical "+
		"-showvalue 1 -command {send cmd g}",
	"scale .f.b -from 0 -to 255 -height 100 -orient vertical "+
		"-showvalue 1 -command {send cmd b}",
	".f.r set 0",
	".f.g set 0",
	".f.b set 0",
	"pack .f.r .f.g .f.b -side left",
	"pack .f2.l .f2.c -side top",
	"pack .f .f2 -side left",
	"pack propagate . 0",
	"focus .f2",
	"update",
};

init(ctxt: ref Draw->Context, nil: list of string)
{
	red	:= 0;
	green	:= 0;
	blue	:= 0;

	sys = load Sys Sys->PATH;
	draw = load Draw Draw->PATH;
	tk = load Tk Tk->PATH;
	wmlib = load Wmlib Wmlib->PATH;

	wmlib->init();
	(toplevel, menubut) := wmlib->titlebar(ctxt.screen, "", 
				"RGB Sliders", Wmlib->Hide);

	cmd := chan of string;
	tk->namechan(toplevel, cmd, "cmd");
	wmlib->tkcmds(toplevel, sliders_cfg);

	for(;;)
	alt
	{
		s := <- menubut =>
			if (s == "exit")
			{
				return;
			}
			wmlib->titlectl(toplevel, s);

		s := <- cmd =>
			c : string;
			(n, word) := sys->tokenize(s, " \t");
			case (hd word)
			{
				"r" => red = int hd tl word;
				"g" => green = int hd tl word;
				"b" => blue = int hd tl word;
			}

			c = sys->sprint("%2x%2x%2x", red, green, blue);
			for (i := 0; i < len c; i++)
			{
				if (c[i] == ' ')
				{
					c[i] = '0';
				}
			}

	 		tk->cmd(toplevel, ".f2.l configure -text {#" + c + "}");
			tk->cmd(toplevel, ".f2.c configure -bg #" + c);
			tk->cmd(toplevel, "focus .f2");
 			tk->cmd(toplevel, "update");
	}
}
