import 'package:flutter/material.dart';

class GuideStep {
  const GuideStep(this.title, this.body);
  final String title;
  final String body;
}

class Guide {
  const Guide({
    required this.tag,
    required this.meta,
    required this.title,
    required this.summary,
    required this.icon,
    required this.intro,
    required this.steps,
  });

  final String tag;
  final String meta;
  final String title;
  final String summary;
  final IconData icon;
  final String intro;
  final List<GuideStep> steps;
}

class QuizQuestion {
  const QuizQuestion(
    this.question,
    this.options,
    this.answer,
    this.explanation,
  );
  final String question;
  final List<String> options;
  final int answer; // index of the correct option
  final String explanation;
}

class EducationData {
  EducationData._();

  static const kitchenGuide = Guide(
    tag: 'Essential',
    meta: '2 min read',
    title: 'Kitchen Emergencies',
    summary: 'What to do when cooking goes wrong.',
    icon: Icons.local_fire_department_outlined,
    intro:
        'Cooking is the most common cause of home fires. '
        'Know these steps before a flare-up happens.',
    steps: [
      GuideStep(
        'Turn off the heat',
        'If it is safe to reach, switch off the burner straight away. '
            'Never leave cooking unattended.',
      ),
      GuideStep(
        'Smother the flames',
        'Slide a metal lid or baking tray over the pan, then leave it in '
            'place until the pan is completely cool.',
      ),
      GuideStep(
        'Never use water',
        'Water makes burning oil splash and spread. Do not use flour or '
            'sugar either. Baking soda can help on a very small flame.',
      ),
      GuideStep(
        'Do not move the pan',
        'Carrying a burning pan can spill flaming oil on you and spread '
            'the fire.',
      ),
      GuideStep(
        'Oven fires',
        'Keep the oven door shut and switch the oven off. The fire will '
            'use up its oxygen.',
      ),
      GuideStep(
        'Leave if it spreads',
        'If the fire grows or you are unsure, get everyone out, close the '
            'door behind you and call your local emergency number from '
            'outside.',
      ),
    ],
  );

  static const library = [
    Guide(
      tag: 'Foundations',
      meta: '4 Articles',
      title: 'Home Fire Safety Basics',
      summary:
          'Smoke detector testing schedules, electrical safety and '
          'everyday habits.',
      icon: Icons.shield_outlined,
      intro: 'A few habits, repeated, prevent most home fires.',
      steps: [
        GuideStep(
          'Test detectors monthly',
          'Press the test button on every smoke detector once a month. '
              'Replace batteries when they chirp and replace the whole '
              'unit about every 10 years.',
        ),
        GuideStep(
          'Keep exits clear',
          'Doors, hallways and windows must open freely. Never block or '
              'lock the way out.',
        ),
        GuideStep(
          'Watch heat sources',
          'Keep curtains, paper and clothing well away from cookers, '
              'heaters and candles.',
        ),
        GuideStep(
          'Check electrics',
          'Unplug damaged cords and avoid overloading sockets or '
              'extension leads.',
        ),
      ],
    ),
    Guide(
      tag: 'Emergency Drill',
      meta: '3 Action Steps',
      title: 'What To Do During an Active Fire',
      summary:
          'Staying low beneath smoke clouds, testing doors and '
          'getting out fast.',
      icon: Icons.exit_to_app,
      intro: 'In a real fire, seconds matter. Follow these three steps.',
      steps: [
        GuideStep(
          'Alert and get out',
          'Shout "Fire!" to wake everyone and leave straight away. Do not '
              'stop to collect belongings.',
        ),
        GuideStep(
          'Stay low and test doors',
          'Smoke rises, so the cleanest air is near the floor. Feel a '
              'door with the back of your hand before opening it. If it '
              'is hot, keep it closed and use another exit.',
        ),
        GuideStep(
          'Stay out and call',
          'Once outside, go to your meeting point and call emergency '
              'services. Never go back inside.',
        ),
      ],
    ),
    Guide(
      tag: 'Planning',
      meta: 'Dual Route Checklist',
      title: 'Building a Household Escape Plan',
      summary: 'Mapping two exits per sleeping area and a meeting point.',
      icon: Icons.explore_outlined,
      intro: 'A plan everyone has practised is far more likely to work.',
      steps: [
        GuideStep(
          'Draw your floor plan',
          'Sketch every room, door and window of your home.',
        ),
        GuideStep(
          'Find two ways out',
          'Plan two exits from every room, usually a door and a window, '
              'and make sure both open easily.',
        ),
        GuideStep(
          'Pick a meeting point',
          'Choose a spot outside, such as a tree or a neighbour\'s gate, '
              'where everyone gathers.',
        ),
        GuideStep(
          'Practise twice a year',
          'Run a drill with the whole household, including at night, so '
              'the route becomes automatic.',
        ),
        GuideStep(
          'Plan for extra help',
          'Decide who will help young children, older relatives or '
              'anyone who needs assistance.',
        ),
      ],
    ),
    Guide(
      tag: 'Extinguishers',
      meta: '5 Classes',
      title: 'Choosing the Right Extinguisher',
      summary: 'Which extinguisher class suits which type of fire.',
      icon: Icons.build_circle_outlined,
      intro:
          'Using the wrong extinguisher can make a fire worse. '
          'Always read the label.',
      steps: [
        GuideStep(
          'Class A',
          'Ordinary combustibles such as wood, paper and cloth.',
        ),
        GuideStep('Class B', 'Flammable liquids such as petrol and paint.'),
        GuideStep(
          'Class C',
          'Fires involving live electrical equipment. Never use water on '
              'live electrics.',
        ),
        GuideStep(
          'Class D',
          'Combustible metals, mostly found in industrial settings.',
        ),
        GuideStep(
          'Class K or F',
          'Cooking oils and fats. The letter depends on the country.',
        ),
      ],
    ),
  ];

  static const quiz = [
    QuizQuestion(
      'What does the "S" in P.A.S.S. stand for after Pull and Aim?',
      [
        'Spray and Stop',
        'Squeeze and Sweep',
        'Switch and Seal',
        'Step back and Stand',
      ],
      1,
      'P.A.S.S. means Pull the pin, Aim at the base, Squeeze the lever, '
          'Sweep side to side.',
    ),
    QuizQuestion(
      'A pan of oil catches fire on the stove. What should you do first?',
      [
        'Pour water on it',
        'Carry it outside',
        'Switch off the heat and slide a lid over it',
        'Fan the flames with a towel',
      ],
      2,
      'Smothering cuts off the oxygen. Water or moving the pan spreads '
          'burning oil.',
    ),
    QuizQuestion(
      'How often should you test your smoke detectors?',
      [
        'Once a year',
        'Every month',
        'Only when the battery chirps',
        'Every five years',
      ],
      1,
      'Test every detector monthly, and replace the whole unit about every '
          '10 years.',
    ),
    QuizQuestion(
      'A room fills with smoke. How should you move?',
      [
        'Walk upright and fast',
        'Open the windows and wait',
        'Stay low, where the air is cleaner',
        'Use the lift',
      ],
      2,
      'Smoke rises, so the cleanest air is near the floor. Never use a lift '
          'in a fire.',
    ),
    QuizQuestion(
      'How many ways out should your escape plan have for each room?',
      ['One', 'Two', 'Three', 'It does not matter'],
      1,
      'Plan two exits from every room in case one is blocked by fire or '
          'smoke.',
    ),
  ];
}
