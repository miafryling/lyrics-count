#!/bin/bash

# Purpose:
# This script can be used by inputing the name of an artist/band. The output is the top 100 most used words in all of their
# songs, ignoring 'stopwords' such as 'a', 'it', 'the', etc. While this is clearly not a script for every use, I do find it 
# to be something interesting to explore. And, as a fun fact, love is said 399 times across all Beatles songs. Unfortunately 
# the site used in the getLyrics script does not contain all artists so if no results are found, try switching artists. For
# testing purposes I suggest using 'adele'. I know the site to contain all of her music, and her limited number 
# of songs keeps the program running quickly (rather than going through all 240 beatles songs!). If the program does not work with
# adele and/or it suddenly stops producing output it is likely that you have been blocked by the webpage for making too many requests.
# The output is put to the terminal as well as being saved to a clearly labeled file for future reference.

# Usage:
# $~ sh myScript.sh
# Please input an artist (ex. the who)
# the who

echo "Please input an artist (ex. the who)" # echo is used to to output text to the console. This is a prompt to have the user input the artist name
read input # read is used to read input from the user, saving it to the given variable name (in this case 'input')
bandname=${input/ /+} # saves the input to the variable 'bandname', replacing any spaces with a +. (ex. input='the who' -> bandname='the+who')
url="http://www.mldb.org/search?mq=$bandname&si=1&mm=2&ob=1" # inserts the bandname into the url
output="${input/ /.}." # saves the input to the variable 'output', replacing the spaces with a . (ex. input='the who' -> bandname='the.who.')

sh getLyrics.sh $url $output # calls out to the shell script getLyrics.sh passing in the url and the output strings as arguments
# getLyrics results in the creation of files that contain the lyrics to each song created by the given artist. These files will have the format
# of $output.number.txt In the example of 'the who', the files will look like 'the.who.12345.txt'. the number is unique to each song and can be ignored
# in this script.

# concatenates all of the text in the files that begin with the string saves to output. The file name must begin with the output string and end in .txt
# tr is used to translate the text in the file. This first tr is used to translate all of the spaces between words into new lines. This way all of the words will be on
# their own line and can be easily sorted and counted.
cat $output*.txt  | tr ' ' '\
' | tr '[[:upper:]]' '[[:lower:]]' | # tr is used to translate the concatanated lyrics. This line takes all of the upper case letters and translates them into lowercase
  tr -d '[:punct:]' | # tr is used to translate the concatonated lyrics. This line deletes all of the punctuation from the text. The -d flag indicates that the punctuation should be deleted.
  grep -F -v -f stopwords.txt | # grep is used to search through text. The -F flag forces the grep to interpret the pattern (stopwords) as fixed string. The -v flag tells the grep to get everything that does not match the given pattern. The -f flag is what indicates that the pattern matching comes from the attaches file stopwords.txt. 
  sort | # sorts all of the words alphabetically
  uniq -c | # counts the unique words. uniq filters out repeated lines in a file and the -c flag adds the count of the number of times the line occurred in the input 
  sort -rn | # sorts the counted words. The -r flag sorts the output in reverse – greatest to smallest. The -n is used to signal to indicate that they should be sorted by the numerical count
  head -100 > "${output}word.count" # limits the output to the top 100 words and saves the output to a file titles [output].word.count

find . -name "$output*.txt" -exec rm {} \; # removes (deletes) all of the lyrics files as they are no longer needed

cat "${output}word.count" # this line is used to output the contents of the results to the user
