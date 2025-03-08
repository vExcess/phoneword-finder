# Phoneword Finder
Efficient multithreaded program that finds words in phone numbers

## Input Format
Create a file of phone numbers separated by newlines e.g.
```
1-800-356-9377
(800) 266-8228
800-463-3339
465-4329
```

## Running the program
Run `dart run main.dart INPUT.txt OUTPUT.txt` where `INPUT.txt` is the name
of your input file and `OUTPUT.txt` is the name of file to output to. Wait for the program to 
finish and then open the output file in a text editor to view the words found.

## Additional Settings
You can also change the dictionary that the program uses and the minimum word length in the `main.dart` file near the top of the code with the following variables
```dart
final DICTIONARY_FILE_NAME = "english-9070.csv";
final WORD_LENGTH_THRESHOLD = 3;
```

## Output
The output file should look something like this
```
Scroll to end to find list of all words discovered.

----- 465-4329 -----
4654-DAY-
46-LIE-29
-HOLIDAY-
-INK-4329

...

----- 1-800-356-9377 -----
18003569-ERS-
1800356-YES-7
18003-JOY-377
18003-LOW-377
18003-LOWER-7
1800-FLOW-377
1800-FLOWER-7
1800-FLOWERS-

All Words Found:
ERS, YES, JOY, LOW, LOWER, FLOW, FLOWER, FLOWERS, ABU, ACT, BAT, CAT, ANN, NOT, 
CONTACT, FEW, FED, FEE, FEED, NEED, GOD, ODD, OFF, IMF, INDEED, DAY, LIE, HOLIDAY, 
```