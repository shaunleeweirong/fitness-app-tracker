import 'dart:convert';
import 'lib/models/exercise.dart';

void main() {
  // Test with actual API response structure
  final apiResponse = '''
{
  "exerciseId": "VPPtusI",
  "name": "inverted row bent knees",
  "gifUrl": "https://static.exercisedb.dev/media/VPPtusI.gif",
  "targetMuscles": ["upper back"],
  "bodyParts": ["back"],
  "equipments": ["body weight"],
  "secondaryMuscles": ["biceps", "forearms"],
  "instructions": [
    "Step:1 Set up a bar at waist height and lie underneath it.",
    "Step:2 Grab the bar with an overhand grip, slightly wider than shoulder-width apart."
  ]
}
''';

  try {
    final json = jsonDecode(apiResponse);
    final exercise = Exercise.fromJson(json);
    print('✅ Successfully parsed exercise: ${exercise.name}');
    print('   - ID: ${exercise.exerciseId}');
    print('   - Body Parts: ${exercise.bodyParts}');
    print('   - Equipment: ${exercise.equipments}');
    print('   - Target Muscles: ${exercise.targetMuscles}');
  } catch (e) {
    print('❌ Failed to parse exercise: $e');
  }
}