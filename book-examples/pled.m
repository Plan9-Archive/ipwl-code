#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
TABCHAR			: con 16r88;
TABLEN			: con 8;

KEY_A			: con ('a'	| 'P' << 8);
KEY_BACKSPACE		: con ('\b'	| 'E' << 8);
KEY_CTRLD		: con (4	| 'P' << 8);
KEY_DOT			: con ('.'	| 'P' << 8);
KEY_EESC		: con (27	| 'E' << 8);
KEY_ENEWLINE		: con ('\n'	| 'E' << 8);
KEY_L			: con ('l'	| 'P' << 8);
KEY_N			: con ('n'	| 'P' << 8);
KEY_PESC		: con (27	| 'P' << 8);
KEY_PNEWLINE		: con ('\n'	| 'P' << 8);
KEY_S			: con ('s'	| 'P' << 8);
KEY_TAB			: con ('\t'	| 'E' << 8);

Line : adt
{
	str	: string;
	ntabs	: int;
};

Pled : module
{
	init : fn (nil : ref Draw->Context, argv : list of string);
};

