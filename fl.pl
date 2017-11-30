#!/usr/bin/perl -w

# Make sure we have at least one arg.
if ($#ARGV < 0) {
   die("No argument(s) specified.\n");
}

my $filename;        # name of filelist file
my $firstpart = '';  # part of command before file name
my $lastpart = '';   # part of command after file name

for (my $i = 0; $i <= $#ARGV; $i++) {
#   print "$ARGV[$i]\n";

   # If first char of arg is '@', it is a filelist file name.
   # Don't allow multiple '@' arguments.
   if (substr($ARGV[$i], 0, 1) eq '@') {
      if (defined($filename)) { 
         die("Only one '\@' arg is allowed.");
      }
      else {
         $filename = substr($ARGV[$i], 1);

         # If the filelist file name doesen't end with ".fl", append it.
         if (length($filename) < 4 ||
            substr($filename, length($filename) - 3, 3) ne '.fl') {
            $filename = $filename . '.fl';
         }
#         print "File list file name is $filename\n";
      }
   }
   else {
      if (defined($filename)) { 
         $lastpart = $lastpart . ' ' . $ARGV[$i];
      }
      else {
         $firstpart = $firstpart . $ARGV[$i] . ' ';
      }
   }
}

if (!defined($filename)) { 
   die("No '\@' arg was found.");
}

# We should now have a filelist file name to open.
open FL, "<$filename" or die("Can't open $filename: $!");

# Read each filename and execute the command against it.
while (<FL>) {

   # Remove leading whitespace, if any.
   $_ =~ s/^\s*//;

   # Remove trailing whitespace, if any.
   $_ =~ s/\s*$//;

   # If first char of arg is ';', it is a comment line.
   if (substr($_, 0, 1) eq ';') {
      next;
   }

   # Ignore null lines.
   if ($_ eq "") {
      next;
   }

# Build and run the command.
   my $command = "$firstpart\"$_\"$lastpart\n";
   print  "$command";
   system "$command";
}

close FL;

