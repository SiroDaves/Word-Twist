abstract class WordsRepository {
  Future<List<String>> getBuildableWords(String sortedInput);

  Future<bool> wordExists(String w);

  Future<String> getRandomWord([int len = 6]);
}
