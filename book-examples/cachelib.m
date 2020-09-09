#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
CacheLib : module
{
	PATH : con "cachelib.dis";

	Cache : adt
	{
		cachesize	: int;
		cache 		: array of list of int;

		isincache	: fn(cache : self ref Cache, fid : int) : int;
		addtocache	: fn(cache : self ref Cache, fid : int);
		delfromcache	: fn(cache : self ref Cache, fid : int);
		hash		: fn(cache : self ref Cache, fid : int) : int;

		allocate 	: fn(cachesize : int) : ref Cache;
	};
};
