#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Bday;

include "sys.m";
include "draw.m";

#	ADT type definition. This cannot be placed
#	inside a function definition:
B: adt  
{  
	year: int;  
	month: string;  
	day: int;
	age : fn(me : B) : int;
};
Bday : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init (nil: ref Draw->Context, nil : list of string)
{
	#	ADT instance declaration:
	bdate : B;

	#	Assigning to the ADT instance members:
	bdate.year = 1928;
	bdate.month = "August";
	bdate.day = 6;

	#	The variable date is a tuple that can be
	#	assigned to the B ADT, as it has type
	#	(int, string, int) which matches data members
	#	of the ADT B:
	date := (0,"", 0);

	#	Thus the following assignment is valid; The
	#	age() member of bdate is ignored in the assignment:
	date = bdate;

	#	The age function takes its instance as an explicit argument:
	age := bdate.age(bdate);	
}

#	The definition of the ADT function age for ADT type B:
B.age(me : B) : int
{
	#	Body of ADT function implementation	

	return 0;
}
