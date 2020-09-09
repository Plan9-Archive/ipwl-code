#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement FileServer;

include "sys.m";
include "draw.m";

sys : Sys;

FileServer : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

Reader : adt
{
	index, fid : int;
	data : array of byte;
};

MAXREADERS : con 1024;

init(nil : ref Draw->Context, nil : list of string)
{
	sys = load Sys Sys->PATH;

	sys->bind("#s", "/usr/pip", sys->MBEFORE);
	chanref := sys->file2chan("/usr/pip", "synthetic.file");

	if (chanref == nil)
	{
		sys->print("Error - Could not create chan file : %r\n");
		exit;
	}

	spawn worker(chanref);
}

worker(chanref : ref sys->FileIO)
{
	readers := array [MAXREADERS] of Reader;
	i, nfids, count	: int = 0;

wlabel:
	while (1)
	alt
	{
		(off, nbytes, fid, rc) := <-chanref.read =>
		{
			if (rc == nil)
			{
				break;
			}
			for (i = 0; i < nfids; i++)
			{
				if (readers[i].fid == fid)
				{
					if (readers[i].index < len readers[i].data)
					{
						end := min(readers[i].index+nbytes,
							len readers[i].data);

						#	Serve the reader with data that's left
						rc <-=(readers[i].data[readers[i].index:end],
							"");
						readers[i].index = end;
					}
					else
					{
						#	Finished serving contents of data[]
						rc <-= (nil, "");

						#	So next read of data will start afresh:
						readers[i].index = 0;
						readers[i].fid = -1;
						readers[i].data = nil;

						#	Recycle entry
						if (i == (nfids-1))
						{
							nfids--;
						}
						count++;
					}
					continue wlabel;
				}
			}

			if (i == nfids)
			{
				readers[nfids].fid = fid;
				readers[nfids].index = 0;
				nfids++;

				#	This is a new read, generate new data
				readers[i].data = array of byte 
					("File read "+string count+" times.\n");

				end := min(readers[i].index+nbytes, len readers[i].data);

				#	Serve the reader with data
				rc <-= (readers[i].data[readers[i].index:end], "");

				readers[i].index = end;
			}
		}

		(offset, writedata, fid, wc) := <-chanref.write =>
		{
			if (wc == nil)
			{
				break;
			}

			wc <-= (len writedata, "");
		}
	}
}

min (a, b : int) : int
{
	if (a < b)
		return a;
	return b;
}
