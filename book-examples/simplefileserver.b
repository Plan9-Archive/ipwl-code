#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement FileServer;

include "sys.m";
include "draw.m";

FileServer : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

sys	: Sys;

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
	data    : array of byte;
	index   : int = 0;
	count   : int = 1;

	while (1)
	alt
	{
		(off, nbytes, fid, rc) := <-chanref.read =>
		{
			if (rc == nil) break;

			#	If this is a new read, generate a new data
			if (index == 0)
			{
				data = array of byte ("File read "+
					string count+" times.\n");
			}

			if (index < len data)
			{
				end := min(index+nbytes, len data);

				#	Serve the reader with data that's left
				rc <-= (data[index:end], "");
				index = end;
			}
			else
			{
				#	Finished serving contents of data[]
				rc <-= (nil, "");

				#	So next read of data will start afresh
				index = 0;
				count++;
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
