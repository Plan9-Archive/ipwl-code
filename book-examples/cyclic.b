#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Cyclic;

include "sys.m";
include "draw.m";

Cyclic : module
{
	init : fn (nil : ref Draw->Context, nil : list of string);
};

Tree : adt
{
	child : cyclic ref Leaf;
};

Leaf : adt
{
	parent : ref Tree;
};	

init (nil : ref Draw->Context, nil : list of string)
{
	tree : Tree;
	leaf : Leaf;

	tree.child = ref leaf;
}
