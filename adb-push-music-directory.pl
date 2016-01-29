#!/usr/bin/perl
use strict;

#Vars
my $device_music_dir = "/storage/emulated/legacy/Music/";
my $regex_included_file_formats = /\.flac|\.mp3|\.ogg/;
my $temp_dir = "./temp/";

# There must be exactly one command line arg
my $count = @ARGV;
if($count == 0 || $count > 1)
{
    print "Usage: push_dir.pl <directory>\n";
    exit;

}

# Confirm
my $dir = @ARGV[0];

# Confirm directory exists
if (!(-e $dir and -d $dir)) {
    print "Please enter a valid directory\n";
    exit;
}

# Confirm action
print "Push \"$dir\" to Android device musuc storage (Y/n): ";
chomp(my $input = <STDIN>);
if (!($input =~ /^[Y]?$/i)) { 
    print "Fair enough\n";
    exit;
}


# Create the directory on the device
# For now simply remove forward slashes from full path dirs
my $cleansed_dir = $dir;
$cleansed_dir =~ s/(\/|\s)//g;
my $dir_to_create = $device_music_dir . $cleansed_dir;
#my $cmd = "adb shell mkdir $dir_to_create";
my $res = '';
$res = `adb shell mkdir $dir_to_create`;
#my $res = system($cmd);
if($res =~ /failed|error/)
{
    "Print unable to create directory: $dir_to_create\n";
    print "res = $res\n";
    exit;
}

# Create the temp directory
`mkdir $temp_dir`;

opendir(DH, $dir);
my @files = readdir(DH);
closedir(DH);

# Iterate through the specified directory
# 1. Skip any files that are not in the specified format list
# 2. Strip the filename of 'adb illegal characters'
# 3. Copy the file data to a temp file with the cleansed filename
# 4. push the file to the Android device
foreach my $file (@files)
{
    # skip . and ..
    next if($file =~ /^\.$/);
    next if($file =~ /^\.\.$/);

    # Only include specified file formats
    next if(!($file =~ $regex_included_file_formats));
    print "\nFilename: $file\n";

    my $buffer = "";
    my $outfile = $file;
    my $infile = $dir . $file; 

    # Strip 'adb illegal characters'
    $outfile =~ s/(\s|\(|\)|\[|\]|\{|\}|\-|\&|\'|\")/_/g;

    # Replace all but the last occurance of '.'
    $outfile =~ s/\.(?=.*\.)//g;
    $outfile = $temp_dir . $outfile;

    # Copy the file with a cleansed name
    print "Writing Filename $outfile...\n";
    open (INFILE, "<", $infile) or die "Not able to open the file. \n";
    open (OUTFILE, ">", $outfile) or die "Not able to open the file for writing. \n";
    binmode (INFILE);
    binmode (OUTFILE);
    
    #Read file in 64K blocks
    while ( (read (INFILE, $buffer, 65536)) != 0 ) {
        print OUTFILE $buffer;
    }  
    
    close (INFILE) or die "Not able to close the file: $infile \n";
    close (OUTFILE) or die "Not able to close the file: $outfile \n";

    # Push the file to the Android device
    my $final_destination = $device_music_dir . $cleansed_dir . '/';
    print "Device Path: $final_destination\n";
    print "Pushing $outfile...\n";
    `adb push $outfile $final_destination`; 

}

# Remove the temp directory
`rm -rf $temp_dir`;
