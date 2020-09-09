#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement XFmt;

include "sys.m";
include "xsniff.m";

sys	: Sys;

Pkt : adt
{
	data	: array of byte;

	srcip	: array of byte;
	dstip	: array of byte;
	ipvers	: int;
	proto	: int;
	nexthdr	: int;
	ttl		: int;
};

PROTO_STRINGS 	:= array [] of 
{
	"",
	"ICMP", 
	"IGMP", 
	"","","",
	"TCP", 
	"","","","","","","","","","",
	"UDP"
};

IPv4	: con 4;
IPv6	: con 6;

fmt (data : array of byte, args : list of string) : (int, string)
{
	sys = load Sys Sys->PATH;

	#	If our module instance ID has not been set, do it
	if (ID == nil)
	{
		ID = "ether0800";
	}

	pktptr  := ref Pkt(data,
				array [16] of byte, 
				array [16] of byte, 
				0, 0, 0, 0);

	if (decode(pktptr) < 0)
	{
		return (-1, "Bad packet passed to Ether0800Fmt");
	}

	sys->print("\tIP version:	[%d]\n",
			pktptr.ipvers);
	sys->print("\tPROTO:		[%s]\n",
			PROTO_STRINGS[pktptr.proto%(len PROTO_STRINGS)]);
	sys->print("\tNEXTHDR:		[%d]\n",
			pktptr.nexthdr);
	sys->print("\tSource IP:	[%s]\n",
			addrbytes2string(pktptr.srcip, pktptr.ipvers));
	sys->print("\tDestination IP:	[%s]\n",
			addrbytes2string(pktptr.dstip, pktptr.ipvers));
	sys->print("\tTTL:		[%d]\n",
			pktptr.ttl);

	return (0, nil);
}

decode(pktptr : ref Pkt) : int
{
	pktptr.ipvers = int (pktptr.data[0] >> 4);

	case (pktptr.ipvers)
	{
		IPv4	=>
		{
			pktptr.proto = int pktptr.data[9];
			pktptr.srcip[12:] = pktptr.data[12:16];
			pktptr.dstip[12:] = pktptr.data[16:20];
			pktptr.ttl = int pktptr.data[8];

			return 0;
		}

		IPv6	=>
		{
			pktptr.nexthdr = int pktptr.data[6];

			return 0;
		}

		*	=>
		{
			#	Unknown IP version
		}
	}

	return -1;
}

addrbytes2string(addr : array of byte, ipvers : int) : string
{
	case (ipvers)
	{
		IPv4	=>
		{
			return (sys->sprint("%d.%d.%d.%d", int addr[12],
						int addr[13],
						int addr[14],
						int addr[15]));
		}
		
		IPv6	=>
		{
			return  (sys->sprint("%4x:%4x:%4x:%4x:%4x:%4x:%4x:%4x",
						int (addr[1] + addr[2] << 8),
						int (addr[3] + addr[4] << 8),
						int (addr[5] + addr[6] << 8),
						int (addr[7] + addr[8] << 8),
						int (addr[9] + addr[10] << 8),
						int (addr[11] + addr[12] << 8),
						int (addr[13] + addr[14] << 8),
						int (addr[15] + addr[16] << 8)));
		}

		*	=>
		{
			#	Unknown IP version
		}
	}

	return "Unknown IP Version";
}
