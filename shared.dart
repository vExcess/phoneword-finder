class WorkerConfig {
    String dictionaryFileName;
    int wordLengthThreshold;

    WorkerConfig({
        required this.dictionaryFileName,
        required this.wordLengthThreshold
    });
}

class WorkerMessage {
    int id;
    List<String>? requestData;
    String? responseData;
    WorkerMessage(this.id, {
        List<String>? this.requestData,
        String? this.responseData,
    });
}

String formatNumber(List<String> number) {
    late String first1;
    late String first3;
    try {
        first1 = number.sublist(0, 1).join("");
        first3 = number.sublist(number.length-4 - 3 - 3, number.length-4-3).join("");
    } catch (e) {
        // out of bounds
    }
    final last3 = number.sublist(number.length-4 - 3, number.length-4).join("");
    final last4 = number.sublist(number.length-4, number.length).join("");
    if (number.length == 11) {
        return "$first1-$first3-$last3-$last4";
    } else if (number.length == 10) {
        return "($first3) $last3-$last4";
    } else if (number.length == 7) {
        return "$last3-$last4";
    } else {
        throw "invalid phone number";
    }
}