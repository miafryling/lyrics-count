#!/bin/bash
# Please read myScript.sh before this one.
# This script is heavily based on a tutorial found at this link: https://www.linuxjournal.com/content/work-shell-all-you-need-love
# This script is given a url to search and a file name to output to. This script uses curl to grab the list of songs from 
# the given url, paging through each page to get the first 300 songs. Then from that list, it takes each song url and uses
# curl again to grab the song lyrics from that page and save them to a file called bandname.song_number.txt. These text files
# will be used in myScript.sh and deleted at the end of that script.

# creates a function saveLyrics that takes in a songnumber and a url for the song lyrics
function savelyrics
{
   songnum="$1" # sets the songnum to the first input given to this function
   fullurl="$2" # sets the fullurl to the second input given to this function

   # Curl is used to transfer data. In this case curl is being used to grab the HTML from the given url. The -s flag mutes curl so that it
   # doesn't print it's progress as output.
   # sed is used modify the text in the file. In this case the HTML output frm the curl. In the first use case of sed below -n is used to stop its 
   # usual behavior of echoing everything seen and /start/,/end/p to print just the lines between those two patterns.
   # In the second use case of sed below, sed is used to further modify the output. The format s/old/new/g is used 
   # here to convert every closing angle bracket into a new line.
   # Next,  grep is used to search through the file, returing the text the matches the expression given. the -E is used to signal that the following string to search by is a regular expression.
   # The third usage of sed below  removes the fragmentary remnant HTML code. It uses the same s/old/new/g pattern, including a ; which just allows two sequences on the same line for convenience.
   # Finally, the uniq minimizes the blank lines and the final output is saved to a textfile titled bandname.songnumber.txt 
   
   curl -s "$fullurl" | sed -n '/songtext/,/\/table/p' | \
     sed 's/>/\
/g;s/\<\/p>//g' | grep -E "(<br|</p)" | \
     sed 's/\<br \///g;s/\<\/p//g' | uniq > $output$songnum.txt

   return 0
}

url=${1-"http://www.mldb.org/search?mq=adele&mm=2&si=1&from=0"} # sets the url to the given url or to a default url with adele as the artist if none is given
output=${2-"song."} # sets the output string to the given string or 'song.' if none is given
start=0   # song number in the list (only 30 per page)
max=300 # only take the first 300 songs
tempfile="tempfile" # the name for the temporary file used to store the links to the song links

echo "Fetching song lyrics from $url" # echo is used to output text to the user, in this case outputting the url given so that the user can check that url if no results are found (this can happen if the site doesnt have the artist on file

while [ $start -lt $max ] # This while loop goes through goes until start is greater than the max number 
do
  # curl is used to transfer data from the given url in the form of HTML. The -s siles any output it may have on its progress. This curl grabs the list of songs from the current page.
  curl -s "$url&from=$start" | 
    sed 's/</\
</g' | # sed is used to modify the text in the file, in this case the HTML output from the curl. This line uses the s/old/new/g format. It finds any instances of < and replaces tham with a new line
    grep 'href="song-' > $tempfile # grep is used to search  through the file, trutning the text that matches the expression given– in this case returning any line that contain the given tag that signifies that there is a link to a song's lyrics on that line. It then saves it to the temporary file.
    
  # this if statment count the number of lines in the tempfile containing the song list. If the word count for the lines (wc -l) is equal to 0, there are no more lyrics to find. If that is the case the tempfile is deleted and the while loop is broken
  if [ $(wc -l < $tempfile) -eq 0 ] ; then 
    # zero results page. let's stop, but let's remove it first
    rm $tempfile # rm is used to remove or delete files, in this case the temporary file containing the song lyric urls
    break # breaks out of the upp while loop
  fi # ends the if statement
  
  # this while loop goes through the output file in the tempfile and makes line by line calls to the saveLyrics function.
  while read lineofdata
    do
      songnum=$(echo $lineofdata | cut -d\" -f2 | cut -d- -f2) # saves a songnumber that is unique to eachs song making for simplier file output names. In this case the song number is obtained from the lineofdata currently being looked at in the tempfil
      # reads the necessary information from the lineofdata and creates a url that will lead to a page containing that song's lyrics
      fullurl="http://www.mldb.org/$(echo $lineofdata | \
          cut -d\" -f2)"
      echo "$lineofdata ($songnum)" | cut -d\> -f2 # outputs the song name and song number to the console so that the user can see what's happening
      savelyrics "$songnum" "$fullurl" # calls the savelyrics function, passing in the song number and the url generated from the tempfile
  done < $tempfile

  start=$(( $start + 30 ))      # increment the start count 30 before beginning the while loop again.
done

