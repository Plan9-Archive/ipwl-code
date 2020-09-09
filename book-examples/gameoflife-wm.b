#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement GameOfLife;

include "sys.m";
include "draw.m";
include "tk.m";
include "wmlib.m";
include "rand.m";
include "keyring.m";
include "security.m";

draw	: Draw;
rand	: Rand;
sys	: Sys;
tk	: Tk;
wmlib	: Wmlib;

BOXSIZE		:= 3;
CELLDENSITY	:= 5;
LDEPTH		:= 8;
GENERATIONS	:= 1000;
ZP		:= (0,0);
generation	:= 0;

Display, Screen, Image, Rect, Point, Font: import draw;

Cell : adt
{
	boxarray	: array of Point;
	boxrect		: Rect;
	image		: ref Draw->Image;
	oldstate, state : int;
};

ca 		: array of array of Cell;
gamewinbuf	: ref Image;
gamewinrect	: Rect;
toplevel	: ref Tk->Toplevel;

GameOfLife : module
{
	init : fn(ctxt : ref Draw->Context, nil : list of string);
};

init(ctxt : ref Draw->Context, nil : list of string)
{
	LDEPTH = ctxt.display.image.ldepth;
	menubutton := chan of string;

	sys = load Sys Sys->PATH;
	tk = load Tk Tk->PATH;
	draw = load Draw Draw->PATH;
	random := load Random Random->PATH;

	rand = load Rand Rand->PATH;
	rand->init(random->randomint(Random->ReallyRandom));

	wmlib = load Wmlib Wmlib->PATH;
	wmlib->init();

	(toplevel, menubutton) = wmlib->titlebar(ctxt.screen, "",
					"gameoflife", Wmlib->Hide);

	#	An off screen image to buffer the window updates
	gamewinrect = ((0, 0), (300, 300));
	gamewinbuf = ctxt.display.newimage(gamewinrect, LDEPTH,
				0, Draw->Black);

	dx := gamewinrect.dx();
	dy := gamewinrect.dy();

	tk->cmd(toplevel, sys->sprint(
		"canvas .c -height %d -width %d -background white", dx, dy));
	tk->cmd(toplevel, "image create bitmap gamewin");
	tk->cmd(toplevel, 
		".c create image 0 0 -image gamewin -anchor nw -tags gamewin");
	tk->cmd(toplevel, "pack .c -side bottom -fill both");
        tk->cmd(toplevel, "focus .c");
	tk->cmd(toplevel, "update");

	ca = array [dx/BOXSIZE + 1] of {* => array [dy/BOXSIZE + 1] of Cell};
	
	xi := 0;
	yi := 0;

	#	Allocate images for each grid location, draw offscreen
	for (y := 0; y < dy; y += BOXSIZE)
	{
		xi = 0;
		for (x := 0; x < dx; x += BOXSIZE)
		{
			#	Roll dice to set state
			ca[xi][yi].state = Draw->White;
			ca[xi][yi].oldstate = Draw->White;

			if (!rand->rand(CELLDENSITY))
			{
				ca[xi][yi].state = Draw->Red;
				ca[xi][yi].oldstate = Draw->Red;
			}

			#	Draw an off-screen bordered box
			ca[xi][yi].boxrect = Rect((x,y), (x+BOXSIZE,y+BOXSIZE));
			ca[xi][yi].boxarray = array [] of {(x,y), (x+BOXSIZE,y),
				(x+BOXSIZE,y+BOXSIZE), (x,y+BOXSIZE), (x,y)};
			ca[xi][yi].image = ctxt.display.newimage(ca[xi][yi].boxrect,
						LDEPTH, 0, ca[xi][yi].state);

			#	Could alternatively be done using the clipr
			ca[xi][yi].image.poly(ca[xi][yi].boxarray, Draw->Endsquare,
				Draw->Endsquare, 0, ctxt.display.color(Draw->Black), ZP);
			gamewinbuf.draw(gamewinrect, ca[xi][yi].image, nil, ZP);

			xi++;
		}
		yi++;
	}

	#	Draw the buffered offscreen image in one go onto the screen
	tk->imageput(toplevel, "gamewin", gamewinbuf, nil);
	tk->cmd(toplevel, ".c coords gamewin 0 0");
	tk->cmd(toplevel, "update");

	cmd := chan of string;
	spawn update(xi, yi, ctxt, cmd);

	for (;;)
	{
		case (menu := <-menubutton)
		{
			"exit" =>
				cmd <-= "quit";
				exit;

			* =>
				tk->cmd(toplevel, "focus .c");
				wmlib->titlectl(toplevel, menu);
		}
	}
}

update(xmax, ymax : int, ctxt : ref Draw->Context, quit : chan of string)
{
	x, y : int = 0;

	while ()
	alt
	{
		<-quit => exit;

		* =>
		if (generation++ == GENERATIONS)
		{
			reset(xmax, ymax, ctxt);
			generation = 0;
		}

		for (y = 0; y < ymax; y++)
		{
			for (x = 0; x < xmax; x++)
			{			
				neighbors := 0;

				xtop := x-1;
				ytop := y-1;
				xbottom := x+1;
				ybottom := y+1;

				if (x == 0)
					xtop = x+xmax-1;
				if (x == xmax-1)
					xbottom = 0;
				if (y == 0)
					ytop = y+ymax-1;
				if (y == ymax-1)
					ybottom = 0;

				neighbors += (ca[xtop][ytop].oldstate == Draw->Red);
				neighbors += (ca[x][ytop].oldstate == Draw->Red);
				neighbors += (ca[xbottom][ytop].oldstate == Draw->Red);
				neighbors += (ca[xbottom][y].oldstate == Draw->Red);
				neighbors += (ca[xbottom][ybottom].oldstate == Draw->Red);
				neighbors += (ca[x][ybottom].oldstate == Draw->Red);
				neighbors += (ca[xtop][ybottom].oldstate == Draw->Red);
				neighbors += (ca[xtop][y].oldstate == Draw->Red);


				if (ca[x][y].oldstate == Draw->Red)
				{
					if ((neighbors == 2)||(neighbors == 3))
						ca[x][y].state = Draw->Red;
					else
						ca[x][y].state = Draw->White;
				}
				else if (ca[x][y].oldstate == Draw->White)
				{
					if (neighbors == 3)
						ca[x][y].state = Draw->Red;
					else
						ca[x][y].state = Draw->White;
				}
		
				if (ca[x][y].oldstate == ca[x][y].state)
				{
					continue;
				}

				ca[x][y].image.draw(ca[x][y].boxrect,
					ctxt.display.color(ca[x][y].state), nil, ZP);

				#	Could alternatively be done using the clipr
				ca[x][y].image.poly(ca[x][y].boxarray, 
					Draw->Endsquare, Draw->Endsquare, 0,
					ctxt.display.color(Draw->Black),
					ca[x][y].boxrect.min);

				gamewinbuf.draw(gamewinrect, ca[x][y].image,
					nil, (0, 0));
			}		
		}

		for (y = 0; y < ymax; y++)
		{
			for (x = 0; x < xmax; x++)
			{
				ca[x][y].oldstate = ca[x][y].state;
			}
		}

		#	Draw the buffered offscreen image in one go
		tk->imageput(toplevel, "gamewin", gamewinbuf, nil);
		tk->cmd(toplevel, ".c coords gamewin 0 0");
		tk->cmd(toplevel, "update");
	}
}

reset(xmax, ymax : int, ctxt : ref Draw->Context)
{
	for (y := 0; y < ymax; y++)
	{
		for (x := 0; x < xmax; x++)
		{
			if (!rand->rand(CELLDENSITY))
			{
				ca[x][y].state = Draw->Red;
				ca[x][y].oldstate = Draw->Red;
			}
			else
			{
				ca[x][y].state = Draw->White;
				ca[x][y].oldstate = Draw->White;
			}

			ca[x][y].image.draw(ca[x][y].boxrect,
				ctxt.display.color(ca[x][y].state), nil, ZP);

			ca[x][y].image.poly(ca[x][y].boxarray, 
				Draw->Endsquare, Draw->Endsquare, 0,
				ctxt.display.color(Draw->Black), ca[x][y].boxrect.min);

			gamewinbuf.draw(gamewinrect, ca[x][y].image, nil, (0, 0));
		}
	}

	#	Draw the buffered offscreen image in one go onto the screen
	tk->imageput(toplevel, "gamewin", gamewinbuf, nil);
	tk->cmd(toplevel, ".c coords gamewin 0 0");
	tk->cmd(toplevel, "update");

	#	Wait two seconds before restarting
	sys->sleep(2000);
}
