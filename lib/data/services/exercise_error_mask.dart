const supportedStoredExerciseErrorMask = (1 << 7) - 1;
const _legacyChoiceOfTwoBit = 1;
const _choiceOfFourToEnglishBit = 1 << 1;
const _supportedGeneratedExerciseMask =
    supportedStoredExerciseErrorMask & ~_legacyChoiceOfTwoBit;

/// Maps the legacy choice-of-two error to the four-choice English exercise.
int normalizeExerciseErrorMask(int storedMask) {
  final generatedMask = storedMask & _supportedGeneratedExerciseMask;
  if ((storedMask & _legacyChoiceOfTwoBit) == 0) return generatedMask;
  return generatedMask | _choiceOfFourToEnglishBit;
}

/// Solving the replacement four-choice exercise also heals choice-of-two.
int storedErrorClearMask(int solvedMask) {
  if ((solvedMask & _choiceOfFourToEnglishBit) == 0) return solvedMask;
  return solvedMask | _legacyChoiceOfTwoBit;
}
