#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
Ether : adt
{
	rcvifc	: array of byte;
	dstifc	: array of byte;
	data	: array of byte;
	pktlen	: int;
};

XFmt : module
{
	BASEPATH: con "";
	ID	: string;
	fmt 	: fn(data : array of byte, args : list of string) : (int, string);
};
