import 'dart:io';
import 'dart:isolate';
import 'dart:collection';

import './shared.dart';

void isolate_main(SendPort port) {
    final receivePort = ReceivePort();
    port.send(receivePort.sendPort);

    final numberMap = {
        "0": ["0"],
        "1": ["1"],
        "2": "ABC".split(""),
        "3": "DEF".split(""),
        "4": "GHI".split(""),
        "5": "JKL".split(""),
        "6": "MNO".split(""),
        "7": "PQRS".split(""),
        "8": "TUV".split(""),
        "9": "WXYZ".split(""),
    };

    final letterMap = {};
    // initialize letter map
    for (String key in numberMap.keys) {
        List<String> possibilities = numberMap[key]!;
        for (String possibility in possibilities) {
            letterMap[possibility] = key;
        }
    }

    Iterable<String>? englishWords;
    Map<String, void>? englishWordsHashMap;

    String formatPermutation(String prefix, String word, String postFix) {
        prefix = prefix.split("").map((String ch) {
            return letterMap[ch] ?? ch;
        }).join("");
        postFix = postFix.split("").map((String ch) {
            return letterMap[ch] ?? ch;
        }).join("");
        return "${prefix}-$word-${postFix}";
    }

    List<String>? permuteNumber(List<String> number, [int index=0, List<String>? results]) {
        results ??= [];

        if (index == number.length) {
            return null;
        }

        final possibilities = numberMap[number[index]]!;
        for (int i = 0; i < possibilities.length; i++) {
            List<String> clone = number.sublist(0);
            clone[index] = possibilities[i];
            results.add(clone.join(""));
            permuteNumber(clone, index+1, results);
        }

        return results;
    }

    List<String> filterPermutations(List<String> permutations, int wordLengthThreshold, Set<String> wordsFound) {
        List<String> filtered = [];
        Map<String, void> filteredHasMap = {};

        for (String permutation in permutations) {
            // hashmap method (52x faster than naive method)
            for (int start = 0; start <= permutation.length - wordLengthThreshold; start++) {
                for (int end = start + wordLengthThreshold; end <= permutation.length; end++) {
                    String slice = permutation.substring(start, end);
                    if (englishWordsHashMap!.containsKey(slice)) {
                        String hasKey = "$slice $start";
                        if (!filteredHasMap.containsKey(hasKey)) {
                            filteredHasMap[hasKey] = true;
                            filtered.add(formatPermutation(permutation.substring(0, start), slice, permutation.substring(end)));
                            wordsFound.add(slice);
                        }
                    }
                }
            }
        }
        return filtered;
    }

    late WorkerConfig config;

    Set<String> wordsFound = Set();

    receivePort.listen((dynamic message) async {
        if (message is WorkerConfig) {
            config = message;

            // load dictionary
            englishWords = File(config.dictionaryFileName)
                .readAsLinesSync()
                .where((word) {
                    return word.length > 1 && word.length <= 10;
                })
                .map((word) {
                    return word.toUpperCase();
                });
            englishWordsHashMap = HashMap.fromIterable(englishWords!);
            // print("Configuring Worker");

            port.send(WorkerMessage(0, responseData: null));
        } else if (message is WorkerMessage) {
            List<String> number = message.requestData!;
            final permutations = permuteNumber(number)!;
            final filtered = filterPermutations(permutations, config.wordLengthThreshold, wordsFound);

            if (filtered.length > 0) {
                port.send(WorkerMessage(message.id, responseData: "----- ${formatNumber(number)} -----\n${filtered.join("\n")}\n\n"));
            } else {
                port.send(WorkerMessage(message.id, responseData: ""));
            }
        } else if (message is int) {
            port.send(wordsFound);
        }
    });
}