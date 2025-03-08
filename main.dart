/*

    english-9070
        https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/English/Wikipedia_(2016)

    english-146212
        some list I compiled years ago from multiple sources

    87% of runtime is spent in filterPermutations.
    The hashmap method is 52x faster than naively using String.contains,
    however I might be able to go even faster using a Trie

*/

import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'dart:math' as Math;

import './worker.dart';
import './shared.dart';

// -------- SETTINGS --------

final DICTIONARY_FILE_NAME = "english-9070.csv";
final WORD_LENGTH_THRESHOLD = 3;

// --------------------------

Future<void> wait(int milliseconds) {
    return Future.delayed(Duration(milliseconds: milliseconds));
}

final random = Math.Random();


// id, response
Map<int, String?> pending = {};

class FilterWorker {
    late SendPort sendPort;
    final Completer<void> _isolateReady = Completer.sync();
    final Completer<void> _isolateConfigured = Completer.sync();
    final Completer<void> _isolateCollected = Completer.sync();
    late Set<String> allWords;
    late Isolate isolate;

    Future<void> spawn() async {
        final receivePort = ReceivePort();
        receivePort.listen(responseFromIsolateListener);
        isolate = await Isolate.spawn(isolate_main, receivePort.sendPort);
    }

    void responseFromIsolateListener(dynamic message) {
        if (message is SendPort) {
            sendPort = message;
            _isolateReady.complete();
        } else if (message is WorkerMessage) {
            if (message.responseData == null) {
                _isolateConfigured.complete();
            } else {
                pending[message.id] = message.responseData!;
            }
        } else if (message is Set<String>) {
            allWords = message;
            _isolateCollected.complete();
        }
    }

    Future<void> configure(String dictionaryFileName, int wordLengthThreshold) async {
        await _isolateReady.future;
        sendPort.send(WorkerConfig(
            dictionaryFileName: dictionaryFileName,
            wordLengthThreshold: wordLengthThreshold
        ));
        await _isolateConfigured.future;
    }

    Future<void> processNumber(List<String> number) async {
        await _isolateReady.future;
        await _isolateConfigured.future;
        final id = random.nextInt(Math.pow(2, 32).toInt());
        pending[id] = null;
        sendPort.send(WorkerMessage(id, requestData: number));
    }

    Future<Set<String>> collectAllWords() async {
        await _isolateReady.future;
        await _isolateConfigured.future;
        sendPort.send(0);
        await _isolateCollected.future;
        return allWords;
    }

    void kill() {
        isolate.kill();
    }
}

Future<void> findPhonewords({
    required String inputFileName,
    required String outputFileName,
    required String dictionaryFileName,
    int wordLengthThreshold=3
}) async {
    // compute permutations
    final phoneNumbers = File(inputFileName)
        .readAsLinesSync()
        .map((String number) {
            List<String> onlyNumbers = [];
            
            for (int i = 0; i < number.length; i++) {
                int chCode = number.codeUnitAt(i);
                if (chCode >= 48 && chCode <= 57) {
                    onlyNumbers.add(String.fromCharCode(chCode));
                }
            }

            return onlyNumbers;
        })
        .toList();

    File output = File(outputFileName);
    output.writeAsStringSync("Scroll to end to find list of all words discovered.\n\n");

    // spawn workers
    List<FilterWorker> workers = [];
    int coreCount = (Platform.numberOfProcessors / 2).round(); // 1:19, 2:12, 4:9, 6:8, 8:8
    for (int i = 0; i < coreCount; i++) {
        final worker = FilterWorker();
        await worker.spawn();
        await worker.configure(dictionaryFileName, wordLengthThreshold);
        workers.add(worker);
    }

    // filter permutations and write to output
    int i = 0;
    for (int i = 0; i < phoneNumbers.length; i++) {
        final number = phoneNumbers[i];
        workers[i % coreCount].processNumber(number);
    }

    while (true) {
        // print("Polling... ${pending.values.length}");
        await wait(4);
        bool foundResponse = true;
        while (foundResponse) {
            foundResponse = false;
            for (int id in pending.keys) {
                if (pending[id] != null) {
                    String chunk = pending[id]!;

                    if (chunk.length > 0) {
                        output.writeAsStringSync(chunk, mode: FileMode.append);
                    }

                    stdout.write("\r\x1b[K");
                    stdout.write("${(++i / phoneNumbers.length * 100).toStringAsFixed(1)}% Complete");

                    pending.remove(id);

                    if (i == phoneNumbers.length) {
                        // combine all found words
                        Set<String> allWordsFound = Set();
                        for (FilterWorker worker in workers) {
                            Set<String> wordsFound = await worker.collectAllWords();
                            for (String word in wordsFound) {
                                allWordsFound.add(word);
                            }
                        }

                        // print all words found
                        output.writeAsStringSync("All Words Found:\n", mode: FileMode.append);
                        String row = "";
                        for (String word in allWordsFound) {
                            if (row.length < 80) {
                                row += word + ", ";
                            } else {
                                output.writeAsStringSync(row + "\n", mode: FileMode.append);
                                row = "";
                            }
                        }

                        // kill child processes
                        for (FilterWorker worker in workers) {
                            worker.kill();
                        }
                        
                        return;
                    }

                    foundResponse = true;
                    break;
                }
            }
        }
    }    
}

void main(List<String> args) async {
    int startTime = DateTime.now().millisecondsSinceEpoch;

    await findPhonewords(
        dictionaryFileName: DICTIONARY_FILE_NAME,
        inputFileName: args[0],
        outputFileName: args[1],
        wordLengthThreshold: WORD_LENGTH_THRESHOLD
    );

    int endTime = DateTime.now().millisecondsSinceEpoch;
    print("\nFinished in ${(endTime - startTime) / 1000}s");

    exit(0);
}