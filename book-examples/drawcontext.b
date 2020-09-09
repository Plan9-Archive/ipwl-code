#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement DrawContext;

include "sys.m";
include "draw.m";

sys : Sys;
draw : Draw;
Screen, Display : import draw;

DrawContext : module
{
	init : fn(ctxt : ref Draw->Context, args : list of string);
};

init (ctxt : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;
	draw = load Draw Draw->PATH;

	if (ctxt == nil)
	{
		sys->print("No valid graphics Context, allocating a new one...\n");

		#	First, allocate a new Display, then allocate a screen to 
		#	manage windows on that Display. We set the screen fill
		#	to grey (RGB 99 99 99):
		display := Display.allocate(nil);
		screen := Screen.allocate(display.image, display.rgb(99,99,99), 1);

		#	We may now also want to allocate the appropriate event
		#	channels for I/O devices such as mice, keyboards, etc.,
		#	then construct a new ctxt:

		#	...

		ctxt = ref (screen, display, nil, nil, nil, nil, nil);
	}
}
