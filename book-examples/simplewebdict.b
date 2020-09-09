#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement WebDict;

include "sys.m";
include "draw.m";
include "url.m";
include "html.m";
include	"arg.m";
include "string.m";

ParsedUrl : import url;

sys	: Sys;
webgrab	: Webgrab;
url	: Url;
str	: String;
html	: HTML;
arg	: Arg;

verbose	: int;
FMTWIDTH: con 60;

WebDict : module
{
	init : fn(nil : ref Draw->Context, args : list of string);
};

Webgrab : module
{
	init : fn(ctxt : ref Draw->Context, args : list of string);
	httpget : fn(u: ref Url->ParsedUrl) : 
		(string, array of byte, ref Sys->FD, ref Url->ParsedUrl);
	readconfig : fn();
};

init(nil : ref Draw->Context, args : list of string)
{
	body : string;


	sys = load Sys Sys->PATH;

	(there, nil) := sys->stat("/net/cs");
	if (there == -1)
	{
		cs := load WebDict "/dis/lib/cs.dis";
		cs->init(nil, nil);
	}

	webgrab = load Webgrab "/dis/webgrab.dis";
	if (webgrab == nil)
	{
		sys->print("Could not load /dis/webgrab.dis : %r");
		exit;
	}

	webgrab->init(nil, "init"::nil);
	webgrab->readconfig();

	str = load String String->PATH;
	html = load HTML HTML->PATH;

	url = load Url Url->PATH;
	url->init();

	arg = load Arg Arg->PATH;
	arg->init(args);

	while((c := arg->opt()) != 0)
	{
		case c
		{
			'v' => verbose = 1;
             		*   =>
			{
				sys->print("Usage : webdict [-v] <list of words>\n");
				exit;
			}
		}
	}
	args = arg->argv();

	while (args != nil)
	{
		u := url->makeurl(
			"http://www.dictionary.com/cgi-bin/dict.pl?term="+
			hd args);

		(err, bytes, fd, realurl) := webgrab->httpget(u);

		if (fd != nil)
		{
			buf := array[Sys->ATOMICIO] of byte;
			while((n := sys->read(fd, buf, len buf)) > 0)
			{
				body = body + string buf[:n];
			}
		}

		munch((string bytes)+body);

		args = tl args;
		body = nil;
	}
}

munch(body : string)
{
	nrecords : int = 1;
	block : string;

	(nlines, lines) := sys->tokenize(sys->sprint("%s", body), "\n");

	while (lines != nil)
	{
		sys->print("\n");

		while ((lines != nil) && (hd lines != "<!-- resultItemStart -->"))
		{
			lines = tl lines;
		}

		if (lines != nil)
			lines = tl lines;

		while ((lines != nil) && (hd lines != "<!-- resultItemEnd -->"))
		{
			block = block + hd lines;
			lines = tl lines;
		}

		htmltxtprint(block);
		block = nil;

		if (!verbose)
			break;
	}

	sys->print("\n");
}

htmltxtprint(s : string)
{
	index 	:= 0;
	inli 	:= 0;

	tokens := html->lex(array of byte s, HTML->Latin1, 0);
	for (i := 0; i < len tokens; i++)
	{
		text := tokens[i].text;

		if (tokens[i].tag == HTML->Data)
		{
			strlen := len text;
			if ((index + strlen) >= FMTWIDTH)
			{
				(n, sl) := sys->tokenize(text, " \t");
				while (sl != nil)
				{
					index += len (hd sl);
					if (index >= FMTWIDTH)
					{
						sys->print("\n");
						if (inli)
							sys->print("\t");

						index = 0;
					}

					sys->print("%s ", hd sl);
					sl = tl sl;
				}

				sys->print("\n");
				if (inli)
					sys->print("\t");

				index = 0;
			}
			else
			{
				sys->print("%s ", text);

				index += len text;
				if (index >= FMTWIDTH)
				{
					sys->print("\n");
	
					if (inli)
						sys->print("\t");

					index = 0;
				}
			}
		}

		if (tokens[i].tag == HTML->Tli)
		{
			sys->print("\n\n\t");
			index = 0;
			inli = 1;
		}
		else if(tokens[i].tag == HTML->Tli+HTML->RBRA)
		{
			inli = 0;
		}
		else if (html->isbreak(tokens[i:i+1], 0))
		{
			sys->print("\n");
			index = 0;
		}
	}
}
