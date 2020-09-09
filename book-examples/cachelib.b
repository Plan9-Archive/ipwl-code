#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement CacheLib;
include "cachelib.m";

Cache.hash(c : self ref Cache, n : int) : int
{
	return n % c.cachesize;
}

Cache.isincache(c : self ref Cache, id : int) : int
{
	bucket := c.hash(id);
	
	tmp := c.cache[bucket];
	while (tmp != nil)
	{
		if (hd tmp == id)
		{
			return 1;
		}

		tmp = tl tmp;
	}

	return 0;
}

Cache.addtocache(c : self ref Cache, id : int)
{
	if (!c.isincache(id))
	{
		bucket := c.hash(id);
		c.cache[bucket] = id :: c.cache[bucket];
	}
}

Cache.delfromcache(c : self ref Cache, id : int)
{
	newbucket : list of int;

	bucket := c.hash(id);
	tmp := c.cache[bucket];

	while (tmp != nil)
	{
		if (hd tmp != id)
		{
			newbucket = (hd tmp) :: newbucket;
		}

		tmp = tl tmp;
	}

	c.cache[bucket] = newbucket;
}

Cache.allocate(cachesize : int) : ref Cache
{
	cache := ref Cache (cachesize, array [cachesize] of list of int);

	return cache;
}
