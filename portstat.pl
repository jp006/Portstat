#! /usr/bin/perl
# -- perl --
# author : JP Drascek
# add option "no_entete"
# add variable hp_ux to take in account separator "." instead of ":" between IP and PORT (netstat command) SAME ON AIX
# bug tested on AIX 6.1 perl 5.8.8, last char of fields read in portstat.tab is removed, so on AIX you must add a blank after remote port in portstat.tab
$hp_ux = 0; 

my $option = $ARGV[0];

my $no_entete = 0;

if ($option eq "no_entete")
{
 $no_entete = 1;
}

$fileSource = 'portstat.tab'; # port;entete;IP Locale;Port Local;IP Remote;Port Remote
(@returned_lines)=`netstat -an`;

if ($no_entete == 0)
{
 print "Date/Time           |";
 open (MYFILE, $fileSource) || die ("Erreur d'ouverture de $fileSource");
 while (<MYFILE>) {
 	chomp;
  next if $_ =~ /^\#.*$/; # skip comment
 	@params = split(";");
 	$entete = @params[1];
 	$length = 9 - length($entete); 
  print substr "$entete", 0, 10;
  for (my $j=0;$j<=$length;$j++)
  {
   print " ";
  }
  print ("|");
  
 }
 close (MYFILE); 
 print "\n";

}
  
  ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime(time);
printf ("%4d-%02d-%02d %02d:%02d:%02d |",$year+1900,$mon+1,$mday,$hour,$min,$sec);  

 open (MYFILE, $fileSource) || die ("Erreur d'ouverture de $fileSource");
 while (<MYFILE>) {
 	chomp;
        chop;

  next if $_ =~ /^\#.*$/; # skip comment

 	@params = split(";");
 	$entete = @params[1];
 	$IPlocal = @params[2];
 	$PORTlocal = @params[3];
 	$IPremote = @params[4];
 	$PORTremote = @params[5];
 	$valeurIP = "";
 	$valeurPORT = "";
 	
 	if ($IPlocal ne "")
 	{
 	  $type="local";

    $indice = -2; 
    $valeurIP = @params[2];
  }
 	if ($PORTlocal ne "")
 	{
 	  $type="local";
 	  # -1 is last in array
    $indice = -1; 
    $valeurPORT = @params[3];
  }
  if ($IPremote ne "")
 	{
 	  $type="remote";
    $indice = -2; 
    $valeurIP = @params[4];
  }
  if ($PORTremote ne "")
 	{
 	  $type="remote";
    $indice = -1; 
    $valeurPORT = @params[5];
  }
  $result="-1";
 	$listening = 0;
 	
#print "|".$IPremote.$PORTremote."|\n";

  &trouve();
 	
   if ($result == -1)
   {
     if ($listening)
     {
        $result="--";
     }
     else
     {
        $result="??";
     }
   }
   else
   {
    $result++; # pour compenser le demarrage a -1
   } 
  #print "$result ";
  $length = 9 - length($result); 
 	# TODO : tenir compte d'une chaine superieur a 9
  print "$result";
  for (my $j=0;$j<=$length;$j++)
  {
   print " ";
  }
  print ("|");
  
  
 }
 print "\n";
 close (MYFILE); 



sub trouve {


foreach $line (@returned_lines){
chomp $line;

next if $line =~ /^\s*$/; # skip empty lines
next if $line !~ /^.*ESTABLISHED.*$/ && $line !~ /^.*LISTEN.*$/; # skip empty lines
#print $line; #do needed checking and filtering
my @paramsNetstat = split(" +", $line);


#Local
if ($type eq "local")     # si local, IP or PORT has at least a value different from ""
{
#my @local = split(":", @paramsNetstat[-3]);

my $iplocal = @paramsNetstat[-3];
if ($hp_ux == 1)
{
 $iplocal =~ s/.*\.[0-9]+$// ;
}
else
{
$iplocal =~ s/.*\:[0-9]+$// ;
}
my $portlocal = @paramsNetstat[-3];

if ($hp_ux == 1)
{
 $portlocal =~ s/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.//;
}
else
{
 $portlocal =~ s/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\://;
} 

if ($valeurPORT eq "" || $portlocal eq $valeurPORT)
{

   if ($valeurIP eq "" || $iplocal eq $valeurIP)
   {
        if ($line =~ /^.*LISTEN.*$/)
        {
          $listening = 1;
        }
        else
        {
          $result++;
        } 
   }
        
}  
}

#Remote
if ($type eq "remote")
{
#my @local = split(":", @paramsNetstat[-2]);
my $ipremote = @paramsNetstat[-2];
if ($hp_ux == 1)
{
 $ipremote =~ s/\.[0-9]+$// ;
}
else
{
 $ipremote =~ s/:[0-9]+$// ;
}
my $portremote =   @paramsNetstat[-2];
if ($hp_ux == 1)
{
 $portremote =~ s/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.//;
}
else
{
 $portremote =~ s/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\://;     
}                              
if ($valeurPORT eq "" || $portremote eq $valeurPORT)
{

   if ($valeurIP eq "" || $ipremote eq $valeurIP)
   {
          $result++;
 
   }
        
}  
 
}  

}

}
