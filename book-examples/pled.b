#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Pled;

include "sys.m";
include "draw.m";
include "bufio.m";
include "pled.m";

sys			: Sys;
bufio			: Bufio;
FD			: import sys;
Iobuf 			: import bufio;

cctlfd			: ref Sys->FD;
curlineidx, cursoridx	: int = 0;
numlines, mode		: int = 0;
stdin, stdout		: ref Sys->FD;


init (nil : ref Draw->Context, argv : list of string)
{
        sys = load Sys Sys->PATH;
	bufio = load Bufio Bufio->PATH;

        stdin = sys->fildes(0);
        stdout = sys->fildes(1);

        param := tl argv;
        while (param != nil)
        {
                (n, err) := pedit(hd param);
                if (n != 0)
                {
			sys->print("\nPled :: %s\n\n", err);
                }
                param = tl param;
        }

	cctlfd = sys->open("/dev/consctl", sys->OWRITE);
	sys->seek(cctlfd, 0, sys->SEEKSTART);
	sys->write(cctlfd, array of byte "rawoff", len "rawoff");
}

pedit (filename : string) : (int, string)
{
	buf			:= array[1] of byte;
	consfd 			: ref FD;
	key			: int = 0;
	lines			: array of Line;
 	tmpstr			: string;

	cctlfd = sys->open("/dev/consctl", sys->OWRITE);
	if (cctlfd == nil)
	{
		return (-1, sys->sprint("Could not open /dev/consctl : %r"));
	}
	sys->write(cctlfd, array of byte "rawon", len "rawon");

	consfd = sys->open("/dev/cons", sys->OREAD);
	if (consfd == nil)
	{
		return (-1, sys->sprint("Could not open /dev/cons : %r"));
	}

	filebuf := bufio->open(filename, sys->OREAD);
	if (filebuf == nil)
	{
		return (-1, sys->sprint("Could not open [%s] : %r", filename));
	}

	#	Determine number of lines in input file
	numlines = 0;
	while (filebuf.gets('\n') != nil)
	{
		numlines++;
	}

	filebuf = bufio->open(filename, sys->ORDWR);
	lines = array [numlines+1] of Line;
	numlines = 0;

	while ((tmpstr = filebuf.gets('\n')) != nil)
	{
		lines[numlines].str = cleanends(tmpstr);
		lines[numlines].ntabs = counttabs(tmpstr);
		numlines++;
	}

	#	Peruse mode by default
	mode = 'P';

	sys->fprint(stdout, "\n\nFile [%s], [%d] lines total\n\n",
				filename, numlines);
	sys->fprint(stdout, "[0][P]%s", lines[curlineidx].str);
	cursoridx = len lines[curlineidx].str;

	while (sys->read(consfd, buf, 1) == 1)
	{
		key = int buf[0];
		case (key | (mode << 8))
		{
			#	Ctrl-d : Exit
			KEY_CTRLD =>
			{
				sys->fprint(stdout, "\n\n");
				return (0, "");
			}

			#	"s" or ENTER in peruse mode : Next line	
			KEY_S or KEY_PNEWLINE =>
			{
				if (curlineidx < numlines-1)
				{
					tmp := "[" + string curlineidx + "][ ]";
					clear(len lines[curlineidx].str + len tmp +
						lines[curlineidx].ntabs*(TABLEN-1));

					curlineidx++;

					sys->fprint(stdout, "[%d][%c]%s",
						curlineidx, mode, lines[curlineidx].str);
				}
			}

			#	ENTER in edit mode
			KEY_ENEWLINE =>
			{
				if (curlineidx < numlines-1)
				{
					tmp := "[" + string curlineidx + "][ ]";
					clear(len lines[curlineidx].str + len tmp +
						lines[curlineidx].ntabs*(TABLEN-1));

					curlineidx++;

					sys->fprint(stdout, "[%d][%c]%s",
						curlineidx, mode, lines[curlineidx].str);
				}
				else
				{
					#insert_line(lines, cur_line_index);
				}
			}

			#	'a' : Previous line
			KEY_A =>
			{
				if ((curlineidx > 0) && mode != 'E' )
				{
					tmp := "[" + string curlineidx + "][ ]";
					clear(len lines[curlineidx].str + len tmp +
						lines[curlineidx].ntabs*(TABLEN-1));

					curlineidx--;

					sys->fprint(stdout,"[%d][%c]%s",
						curlineidx, mode, lines[curlineidx].str);
				}
			}

			#	ESC : Toggle edit mode
			KEY_PESC or KEY_EESC =>
			{
				if (mode == 'P')
				{
					mode = 'E';
				}
				else
				{
					mode = 'P';
				}

				tmp := "[" + string curlineidx + "][ ]";
                                clear(len lines[curlineidx].str + len tmp +
						lines[curlineidx].ntabs*(TABLEN-1));

				sys->fprint(stdout, "[%d][%c]%s",
					curlineidx, mode, lines[curlineidx].str);
				cursoridx = len lines[curlineidx].str;
			}

			#	Save
			KEY_DOT =>
			{
				save(filebuf, lines);
			}

			#	Backspace
			KEY_BACKSPACE =>
			{
				if (cursoridx >= 1)
				{
					sys->fprint(stdout,"\b");
					cursoridx--;
				}
			}

			#	Tabs
			KEY_TAB =>
			{
				sys->fprint(stdout, "%c", TABCHAR);
				lines[curlineidx].str[cursoridx] = key;
				cursoridx++;
			}
				
			#	List lines
			KEY_L =>
			{
				cctlfd = nil;
				cctlfd = sys->open("/dev/consctl", sys->OWRITE);

				sys->seek(cctlfd,0, sys->SEEKSTART);
				sys->write(cctlfd, array of byte "rawoff", len "rawoff");

				lbuf := array [Sys->ATOMICIO] of byte;

				sys->fprint(stdout,"\nLines to List: ");
				sys->read(stdin, lbuf, len lbuf);

				(n, llist) := sys->tokenize(string lbuf, " \n\r");

				if ( (int hd llist > numlines) || 
					(int hd llist < 0) || 
					(int hd tl tl llist > numlines) ||
					(int hd tl tl llist < int hd llist) ||
					(hd tl llist != "-") 
				   )
				{
					if (hd tl llist != "-")
					{	
						sys->fprint(stdout, "Wrong Format : \"%s\"\n",
							string lbuf);
					}
					else
					{
						sys->fprint(stdout,
							"Out of range. File Contains %d lines.\n",
							numlines);
						sys->fprint(stdout, "[%d][%c]%s",
							curlineidx, mode, lines[curlineidx].str);
					}
				}
				else
				{
					start := int hd llist;
					finish := int hd tl tl llist;

					sys->fprint(stdout,"\n\n");
					for (i := start; i <= finish; i++)
					{
						sys->fprint(stdout, "%s\n","|"+ string i +"> "+
							lines[i].str);
					}
					sys->fprint(stdout,"\n\n");
					sys->fprint(stdout,"[%d][%c]%s",
							curlineidx, mode, lines[curlineidx].str);
				}
				sys->seek(cctlfd,0, sys->SEEKSTART);
				sys->write(cctlfd, array of byte "rawon", len "rawon");
			}

			KEY_N =>
			{
				sys->fprint(stdout,
					"\n\nFile Contains %d lines total.\n\n",
					numlines);
				sys->fprint(stdout, "[%d][%c]%s",
					curlineidx, mode, lines[curlineidx].str);
			}

			* =>
			{
				if (mode == 'E')
				{
					if (cursoridx < len lines[curlineidx].str)
					{
						lines[curlineidx].str[cursoridx] = key;
					}
					else
					{
						lines[curlineidx].str[len lines[curlineidx].str]
							= key;
					}

					cursoridx++;
					sys->fprint(stdout,"%c", key);
				}
			}
		}
	}
	sys->fprint(stdout,"\n");

	return (0, "");
}

cleanends(tmpstr : string) : string
{
	CR := max(len tmpstr - 2, 0);
	LF := max(len tmpstr - 1, 0);

	if (tmpstr[CR] == '\r')
	{
		return tmpstr[: CR];
	}
	else if (tmpstr[LF] == '\n')
	{
		return tmpstr[: LF];
	}

	return tmpstr;
}

counttabs(line : string) : int
{
	ntabs := 0;

	for (i := 0; i < len line; i++)
	{
		if (line[i] == '\t') ntabs++;
	}

	return ntabs;
}

clear(delwidth : int)
{
	delete := string (array [delwidth] of {* => byte '\b'});
	blank := string (array [delwidth] of {* => byte ' '});
	sys->print("%s", delete);
	sys->print("%s", blank);
	sys->print("%s", delete);
}

save(filebuf : ref Iobuf, lines : array of Line)
{
	filebuf.seek(0, 0);
        for (i := 0; i < numlines; i++)
	{
		#	We had stripped the newlines of the ends
		if (lines[i].str == "\n")
		{
                	filebuf.puts(lines[i].str);
		}
		else
		{
			filebuf.puts(lines[i].str+"\n");
		}
        }
	filebuf.flush();

	tmp := "[" + string curlineidx + "][ ]";
	clear(len lines[curlineidx].str + len tmp +
		lines[curlineidx].ntabs*(TABLEN-1));

	sys->fprint(stdout, "[%d][%c]%s",
		curlineidx, 'S', lines[curlineidx].str);
}

max(a, b : int) : int
{
	if (a > b)
	{
		return a;
	}

	return b;
}

