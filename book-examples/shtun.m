#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
SRVPORT		: con "8080";
SRVADDR		: con "localhost";

StyxHTTPtunnel : module
{
	init : fn(ctxt : ref Draw->Context, args : list of string);

	REPLYHDPAD	: con 10;
	REPLYTLPAD	: con 10;

	QUERYHDPAD	: con 37;
	QUERYTLPAD	: con 4;
};
