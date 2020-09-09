#
#       Software from the book "Inferno Programming with Limbo"
#       published by John Wiley & Sons, January 2003.
#
#       p. Stanley-Marbell <pip@gemusehaken.org>
#
implement Clinic;

include "sys.m";
include "draw.m";

sys : Sys;
print : import sys;

PatientRecord : adt
{
	name : string;
	age : int;
};

Clinic : module
{
	init : fn(nil : ref Draw->Context, nil : list of string);
};

init (nil : ref Draw->Context, nil : list of string)
{
	np, p, newpatient : ref PatientRecord;
	patient : PatientRecord;

	sys = load Sys Sys->PATH;

	newpatient = ref patient;
	patient.name = "John Doe";
	patient.age = 46;
                         
	print("Patient Name = %s\n", newpatient.name);
	print("Patient Age = %d\n", newpatient.age);

	np = p = ref PatientRecord("John Doe", 46);
	print("Patient Name = %s\n", p.name);
	print("Patient Age = %d\n", p.age);
	np.age = 120;
	print("Patient Name = %s\n", p.name);
	print("Patient Age = %d\n", p.age);
}
