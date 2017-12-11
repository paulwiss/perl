#!/usr/bin/perl -w
# Convert scanned route data to CSV suitable for Google My Maps

# To do: 
# Reactivate commented out code to run iconv.
# Add code to run iconv against each page and feed parsing loop.

# 1. get route listing on paper
# 2. scan each page and save as pdf files, i.e. 1.pdf, 2.pdf, etc.
# 3. use http://www.onlineocr.net/ to convert PDF files to text, i.e. 1.txt, 2.txt, etc.
#     one page at a time
#     time limit on number of pages
#     Use multiple browsers to defeat repetition limit.
# 4. run this script, which will:
#     a. Read the text files, allowing for UTF-16 encoding.
#        can also use iconv to convert each page from UTF-16 to ascii
#        syntax: iconv -f UTF-16 -t ascii 1.txt >out.txt
#     b. parse the text and emit 2 CSV files, probe.csv and radio.csv.
# 5. Import to 2 CSV files into Google My Maps as separate layers.

use strict;
use warnings;
use 5.010;
use File::Temp qw/ :POSIX /;

use constant {
   DEBUG => 0,
};

if (DEBUG) {
   use Data::Dumper;
}

sub write_csv {
   my $route = shift;
   my $name = shift;
   my $address = shift;
   my $location = shift;
   state @existing_files;
   my $csv_file = $route;
# If location contains "RADIO" or is blank, it's a radio read. 
   if ($location =~ /RADIO/ || $location eq '') {
      $csv_file = $route . "radio.csv";
   }
   else {
      $csv_file = $route . "probe.csv";
   }
#   my $new_file = 0;
#   if (-f $csv_file) {
#      my $new_file = 1;
#   }
   open (CSV, '>>', $csv_file)
      or die("Can't open $csv_file: $!");
   if ($csv_file ~~ @existing_files) {
      open (CSV, '>>', $csv_file) or die "Cannot open $csv_file for append";
   }
   else {
      open (CSV, '>', $csv_file) or die "Cannot open $csv_file for create";
      push @existing_files, $csv_file;
      print CSV "name, address\n";
   }
   my $label = "$address \* $name";
   if (DEBUG) {
      say "writing \"$label, $address\" to ", $csv_file;
   }
   print CSV "\"$label\",\"$address, Glen Ellyn, IL\"\n";
   close CSV;
} 

my $pagenum = 1;
my $route_col;
my $name_col;
my $address_col;
my $location_col;
my $heading = 0;
   
while (-f "$pagenum" . '.txt') {
   my $filename = "$pagenum" . '.txt';

# The files produced by onlineocr.net are UTF-16 encoded.
   open (TXT, '< :encoding(UTF-16)', $filename)
      or die("Can't open $filename: $!");

   while (<TXT>) {
      if (DEBUG) {
         print "$_\n";
      }
      my $line = $_;
#      say "$heading   $line";
   
      # Filter out short lines and validate headers/footers.
      if (index($line, "Route List Report") != -1) {
         if ($heading != 0) {
            die("$filename, first heading line out of sequence.");
         }
         ++$heading;
         next;
      }
      if (index($line, "Village of Glen Ellyn") != -1) {
         if ($heading != 1) {
            die("$filename, second heading line out of sequence.");
         }
         ++$heading;
         next;
      }
      if (index($line, "Route  ") != -1) {
         if ($heading != 2) {
            die("$filename, third heading line out of sequence.");
         }

         # save and validate data locations from heading line
         $route_col = index($line, "Route  ");
         $name_col = index($line, "Name  ");
         $address_col = index($line, "Address  ");
         $location_col = index($line, "Location  ");
         say "$route_col, $name_col, $address_col, $location_col";
         if ($route_col < 0 || $name_col < 0 || $address_col < 0 || $location_col < 0) {
            die("$filename, invalid heading line:\n$line");
         }

         ++$heading;
         next;
      }
      if (index($line, "Neptune Technology Group") != -1) {
         if ($heading != 3) {
            die("$filename, page footer out of sequence.");
         }
         $heading = 0;
         next;
      }
      next if (length($line) < 50);

      my $route = substr($line, $route_col, 5);
      my $name = substr($line, $name_col, 23);
      my $address = substr($line, $address_col, 23);
      my $location = substr($line, $location_col, 23);

      # Number of intervening spaces may vary due to OCR error.
      # Truncate fields at first occurrence of two consecutive spaces.
      my $i;
      $i = index $route, "  ";
      if ($i != -1) {
         $route = substr($route, 0, $i);
      }
      $i = index $name, "  ";
      if ($i != -1) {
         $name = substr($name, 0, $i);
      }
      $i = index $address, "  ";
      if ($i != -1) {
         $address = substr($address, 0, $i);
      }
      $i = index $location, "  ";
      if ($i != -1) {
         $location = substr($location, 0, $i);
      }

      # strip any remaining trailing whitespace
      $name =~ s/\s+$//;
      $address =~ s/\s+$//;
      $location =~ s/\s+$//;

      # write a line to a CSV file
      if ($address ne "") {
         write_csv($route, $name, $address, $location);
      }
   }
   close TXT;
   ++$pagenum;
}
--$pagenum;
say "finished, $pagenum pages";

