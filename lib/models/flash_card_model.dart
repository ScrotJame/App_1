// ─────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────



import '../commons/enums.dart';

extension DifficultyRatingX on DifficultyRating {
  String get label {
    switch (this) {
      case DifficultyRating.again:
        return 'Again';
      case DifficultyRating.hard:
        return 'Hard';
      case DifficultyRating.good:
        return 'Good';
      case DifficultyRating.easy:
        return 'Easy';
    }
  }

  String get emoji {
    switch (this) {
      case DifficultyRating.again:
        return '😞';
      case DifficultyRating.hard:
        return '😐';
      case DifficultyRating.good:
        return '🙂';
      case DifficultyRating.easy:
        return '😊';
    }
  }
}

class FlashcardModel {
  final String id;
  final String category;
  final String frontText;
  final String pronunciation;
  final String backText;
  final String backDescription;

  const FlashcardModel({
    required this.id,
    required this.category,
    required this.frontText,
    required this.pronunciation,
    required this.backText,
    required this.backDescription,
  });
}

class FlashcardResult {
  final FlashcardModel card;
  final DifficultyRating rating;

  const FlashcardResult({required this.card, required this.rating});
}

// ─────────────────────────────────────────────
// Mock Data
// ─────────────────────────────────────────────

abstract class FlashcardMockData {
  static const List<FlashcardModel> cards = [
    FlashcardModel(
      id: '1',
      category: 'NATURE',
      frontText: 'Árbol',
      pronunciation: '/ˈar.bol/',
      backText: 'Tree',
      backDescription:
      'A woody perennial plant, typically having a single stem growing to a considerable height.',
    ),
    FlashcardModel(
      id: '2',
      category: 'NATURE',
      frontText: 'Flor',
      pronunciation: '/flor/',
      backText: 'Flower',
      backDescription:
      'The seed-bearing part of a plant, consisting of reproductive organs surrounded by petals.',
    ),
    FlashcardModel(
      id: '3',
      category: 'ANIMALS',
      frontText: 'Perro',
      pronunciation: '/ˈpe.ro/',
      backText: 'Dog',
      backDescription:
      'A domesticated carnivorous mammal that typically has a long snout and an acute sense of smell.',
    ),
    FlashcardModel(
      id: '4',
      category: 'ANIMALS',
      frontText: 'Gato',
      pronunciation: '/ˈɡa.to/',
      backText: 'Cat',
      backDescription:
      'A small domesticated carnivorous mammal with soft fur, a short snout, and retractable claws.',
    ),
    FlashcardModel(
      id: '5',
      category: 'FOOD',
      frontText: 'Manzana',
      pronunciation: '/manˈθa.na/',
      backText: 'Apple',
      backDescription:
      'A round fruit with red, yellow, or green skin and crisp white flesh.',
    ),
    FlashcardModel(
      id: '6',
      category: 'FOOD',
      frontText: 'Pan',
      pronunciation: '/pan/',
      backText: 'Bread',
      backDescription: 'A staple food prepared from a dough of flour and water.',
    ),
    FlashcardModel(
      id: '7',
      category: 'COLORS',
      frontText: 'Rojo',
      pronunciation: '/ˈro.xo/',
      backText: 'Red',
      backDescription:
      'The color at the end of the visible spectrum of light, next to orange.',
    ),
    FlashcardModel(
      id: '8',
      category: 'COLORS',
      frontText: 'Azul',
      pronunciation: '/aˈθul/',
      backText: 'Blue',
      backDescription:
      'The color between green and violet in the visible spectrum.',
    ),
    FlashcardModel(
      id: '9',
      category: 'BODY',
      frontText: 'Cabeza',
      pronunciation: '/kaˈβe.θa/',
      backText: 'Head',
      backDescription:
      'The upper part of the human body, containing the brain, eyes, ears, nose, and mouth.',
    ),
    FlashcardModel(
      id: '10',
      category: 'BODY',
      frontText: 'Mano',
      pronunciation: '/ˈma.no/',
      backText: 'Hand',
      backDescription:
      'The end part of a person\'s arm beyond the wrist, including the palm, fingers, and thumb.',
    ),
    FlashcardModel(
      id: '11',
      category: 'TRAVEL',
      frontText: 'Avión',
      pronunciation: '/aˈβjon/',
      backText: 'Airplane',
      backDescription:
      'A powered flying vehicle with fixed wings and weight greater than that of the air it displaces.',
    ),
    FlashcardModel(
      id: '12',
      category: 'TRAVEL',
      frontText: 'Hotel',
      pronunciation: '/oˈtel/',
      backText: 'Hotel',
      backDescription:
      'An establishment providing accommodation, meals, and other services for travelers.',
    ),
    FlashcardModel(
      id: '13',
      category: 'WEATHER',
      frontText: 'Lluvia',
      pronunciation: '/ˈʎu.βja/',
      backText: 'Rain',
      backDescription:
      'Moisture condensed from the atmosphere that falls visibly in separate drops.',
    ),
    FlashcardModel(
      id: '14',
      category: 'WEATHER',
      frontText: 'Sol',
      pronunciation: '/sol/',
      backText: 'Sun',
      backDescription:
      'The star around which the earth orbits, providing light and warmth to our planet.',
    ),
    FlashcardModel(
      id: '15',
      category: 'FAMILY',
      frontText: 'Madre',
      pronunciation: '/ˈma.ðɾe/',
      backText: 'Mother',
      backDescription: 'A woman in relation to her child or children.',
    ),
    FlashcardModel(
      id: '16',
      category: 'FAMILY',
      frontText: 'Padre',
      pronunciation: '/ˈpa.ðɾe/',
      backText: 'Father',
      backDescription:
      'A man in relation to his natural child or children.',
    ),
    FlashcardModel(
      id: '17',
      category: 'NUMBERS',
      frontText: 'Uno',
      pronunciation: '/ˈu.no/',
      backText: 'One',
      backDescription: 'The lowest cardinal number; half of two.',
    ),
    FlashcardModel(
      id: '18',
      category: 'NUMBERS',
      frontText: 'Cien',
      pronunciation: '/ˈθjen/',
      backText: 'One Hundred',
      backDescription:
      'The number equivalent to the product of ten and ten; 10².',
    ),
    FlashcardModel(
      id: '19',
      category: 'TIME',
      frontText: 'Mañana',
      pronunciation: '/maˈɲa.na/',
      backText: 'Tomorrow / Morning',
      backDescription: 'The day after today; or the early part of the day.',
    ),
    FlashcardModel(
      id: '20',
      category: 'TIME',
      frontText: 'Noche',
      pronunciation: '/ˈno.tʃe/',
      backText: 'Night',
      backDescription:
      'The period from sunset to sunrise in each twenty-four hours.',
    ),
  ];

  static const Map<String, int> categoryColor = {
    'NATURE':  0xFF4CAF50,
    'ANIMALS': 0xFFFF9800,
    'FOOD':    0xFFF44336,
    'COLORS':  0xFF9C27B0,
    'BODY':    0xFF2196F3,
    'TRAVEL':  0xFF00BCD4,
    'WEATHER': 0xFF607D8B,
    'FAMILY':  0xFFE91E63,
    'NUMBERS': 0xFF3F51B5,
    'TIME':    0xFF795548,
  };
}