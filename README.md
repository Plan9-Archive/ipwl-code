# IPWL Code

Code from the (now defunct) IPWL site previously at `www.gemusehaken.org/ipwl/`.

Examples are presumably written for the 4th edition of Inferno in Limbo.

Credit goes to the *Inferno Programming with Limbo* authors.

## Index

Transcribed from the original site.

### esdaudiodev

A client for the Enlightenment Sound Daemon (ESD, JEsd), serves /dev/audio and /dev/audioctl.

- [esdaudiodev.b](./esdaudiodev.b)
- [esd.m](./esd.m)

### esd server

A clone of Enlightenment Sound Daemon (ESD, JEsd); The implementation is almost complete, but i don't feel like finishing it yet (07/28/2003), so i'm posting the source anyway.

- <./esd.b>
- <./esd.m>  (p. stanley-marbell, contact)

### postscanner

A port scanner

- <./portscanner.b>  (p. stanley-marbell, contact)

### banner

A semi-clone of the Unix banner(1); Works well with cb (see below)

- <./banner.b>  (p. stanley-marbell, contact)

### cb

Turn any text, images, program, audio, etc., into an image; Works well with banner (see above)

- <./cb.b>  (p. stanley-marbell, contact)

### unroll

Unrolls a text file into characters, one per line

- <./unroll.b>  (p. stanley-marbell, contact)

### transprob

Reads in a file containing numbers, and outputs a table of the transition probabilities of going from one value to another.

Example:

     transprob -c 2 -s '0,1,2,3,4,5,6,7,8' -f q.data

This will output the transition probability matrix for values in the second column of the file q.data going from all combinations of 0..8 to 0..8.

- <./transprob.b>  (p. stanley-marbell, contact)

### webview

Pull down a URL, and make a quick attempt at rendering it as plain text

- <./webview.b>  (p. stanley-marbell, contact)

### match

Match prints number of occurrences of each character in supplied string argument. It is useful for debugging files in, e.g. LaTeX when you're missing some matching parens :-)

e.g.:

	; match '{}' /tmp/chapter.tex
	[{]     218 occurences
	[}]     218 occurences


- <./match.b>  (p. stanley-marbell, contact)
