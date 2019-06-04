#!C:/Perl/bin/perl.exe
#
#############################################################################################
#																							#
# Author: Jason McColl (+44 (0)75918 22700)													#
#																							#
# Desc:   Quick script to unfreeze tapes (contains a modifiable failsafe limit 'tapelimit') #
#																							#
# Requirements:	Wherever you store this script, you have to modify the $MYHOME parameter 	#
#																							#
# Thanks:	Thanks to Adrian Neville for the basis of this script							#
#																							#
# Usage: frozen_tape.pl																		#
#																							#
# License:	MIT License																		#
#																							#
# Copyright (c) 2018 J_McColl																#
#																							#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this 		#
# software and associated documentation files (the "Software"), to deal in the Software 	#
# without restriction, including without limitation the rights to use, copy, modify, merge, #
# publish, distribute, sublicense, and/or sell copies of the Software, and to permit 		#
# persons to whom the Software is furnished to do so, subject to the following conditions:  #
#																							#
# The above copyright notice and this permission notice shall be included in all copies or 	#
# substantial portions of the Software.														#
#																							#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 		#
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR 	#
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE #
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 		#
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 	#
# DEALINGS IN THE SOFTWARE.																	#
#																							#
# Change History:																			#
#																							#
# JMM		14/11/2015	Created for customer												#
# JMM		04/06/2019	Modified for Windows master environment								#
#																							#
#############################################################################################
#
### Modify variables here for your site

my $tapeLimit = 2;
my $MYHOME = "D:\\Scripts";

### Pre Cleanup time - Clearing temp file to start clean

if (-e "$MYHOME\\frozen_tapes_temp.txt") {
        system "rm $MYHOME\\frozen_tapes_temp.txt";
}

### Getting summary of all tapes in the silo

system "bpmedialist -summary > $MYHOME\\frozen_tapes_temp.txt";

### Getting the currently frozen tapes

open(CURRENT,"$MYHOME\\frozen_tapes_temp.txt") || die $!;

### Creating file to store the currently frozen tapes

open(CURRENTFROZEN,">>$MYHOME\\frozen_tapes_frozen.txt");

while ($line=<CURRENT>) {

        if ($line =~ /\(FROZEN\)/) {
                ($tapeid,$a) = split (' ',$line);
                chomp($tapeid);
                print CURRENTFROZEN "$tapeid\n";
        }
}

close(CURRENT);

### Delete the temporary information file now that we our data

system "rm $MYHOME\\frozen_tapes_temp.txt" || die $!;

close(CURRENTFROZEN);

### Checking for a discard file and if it exists, deleting it

if (-e "$MYHOME\\frozen_tapes_discardInfo.txt") {
        system "rm $MYHOME\\frozen_tapes_discardInfo.txt";
}

### Checking to see if there is a tape info file, if not create one

if (-e "$MYHOME\\frozen_tapes_tapeInfo.txt") {
        open(CURRENTFROZEN,"$MYHOME\\frozen_tapes_frozen.txt") || die $!;
        while ($line=<CURRENTFROZEN>) {
                ($tapeid) = split(' ',$line);
                chomp($tapeid);
                @currentFrozen = ($tapeid,@currentFrozen);
        }
                %test = @currentFrozen;
        close(CURRENTFROZEN);
        open(TAPEINFO,"$MYHOME\\frozen_tapes_tapeInfo.txt");
        open(TEMPINFO,">>$MYHOME\\frozen_tapes_tempInfo.txt");
        

        while ($line=<TAPEINFO>) {
                ($tapeid,$frozen,$issue) = split(' ',$line);
                chomp($tapeid,$frozen,$issue);
                if (exists($test{$tapeid})) {
                        if ($frozen < ($issue*$tapeLimit)) {
                                system "bpmedia -unfreeze -m $tapeid -h $test{$tapeid}";
                                $frozen = $frozen + 1;
                                print TEMPINFO "$tapeid $test{$tapeid} $frozen $issue\n";
                                delete $test{$tapeid};
                        }else{
				system "bpmedia -suspend -m $tapeid -h $test{$tapeid}";
                                open(DISCARDFILE,">>$MYHOME\\frozen_tapes_discardInfo.txt");
                                print TEMPINFO "$tapeid $test{$tapeid} $frozen $issue\n";
                                print DISCARDFILE $tapeid."\n";
                                delete $test{$tapeid};
                        }
                }else{
                        print TEMPINFO "$tapeid $frozen $issue\n";
                }
        }
        foreach $key (keys(%test)) {
                system "bpmedia -unfreeze -m $key -h $test{$key}";
                print TEMPINFO $key." ".$test{$key}." 1 1\n";
        }

}else{
        open(CURRENTFROZEN,"$MYHOME\\frozen_tapes_frozen.txt") || die $!;
        open(TAPEINFO,">$MYHOME\\frozen_tapes_tapeInfo.txt");
        while ($line=<CURRENTFROZEN>) {
                ($tapeid) = split (' ',$line);
                chomp($tapeid);
                system "bpmedia -unfreeze -m $tapeid";
                print TAPEINFO "$tapeid 1 1\n";
        }
        print "All tapes unfrozen\n";
}

close(CURRENTFROZEN);
close(TAPEINFO);
close(TEMPINFO);
close(DISCARDFILE);

### Post Cleanup time
### Checking for a currentfrozen file
if (-e "$MYHOME\\frozen_tapes_frozen.txt") {
        system "rm $MYHOME\\frozen_tapes_frozen.txt";
}

### Checking for a tempinfo file, if so deleting the old info file, then renaming the tempInfo to tapeInfo file

if (-e "$MYHOME\\frozen_tapes_tempInfo.txt") {
        system "rm $MYHOME\\frozen_tapes_tapeInfo.txt";
        rename ("$MYHOME\\frozen_tapes_tempInfo.txt","$MYHOME\\frozen_tapes_tapeInfo.txt");
}

### Checking to see if there is a discard file and if there is, printing the output to the screen with relevant instructions

if (-e "$MYHOME\\frozen_tapes_discardInfo.txt") {
        print "The following tapes have reached their unfreeze limit.\n";
        print "1. Advise tape-monkey to remove these tapes from the library.\n";
        print "2. Mark this job as successfull.\n";
        open(DISCARDINFO,"$MYHOME\\frozen_tapes_discardInfo.txt");
        while ($line=<DISCARDINFO>) {
                ($tapeid,$a) = split(' ',$line);
                chomp($tapeid);
                print $tapeid."\n";
        }
        exit 1;
}

