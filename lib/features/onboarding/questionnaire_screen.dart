import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/navigation.dart';
import 'package:habit_app/core/providers/supabase_provider.dart';

class QuestionnaireScreen extends ConsumerStatefulWidget {
  const QuestionnaireScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<QuestionnaireScreen> createState() =>
      _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends ConsumerState<QuestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _mainGoalOther = TextEditingController();
  final TextEditingController _whyOther = TextEditingController();

  bool _saving = false;

  // Paging
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 13; // 13 questions

  // Answer storage
  final Map<String, dynamic> _answers = {
    'main_goal': null,
    'main_goal_other': null,
    'how_many_habits': null,
    'experience_level': null,
    'most_energetic': null,
    'weekday_busyness': 3,
    'preferred_times': <String>[],
    'why_build': <String>[],
    'why_build_other': null,
    'what_stops': <String>[],
    'motivation_style': <String>[],
    'reminder_frequency': null,
    'areas_interest': <String>[],
    'habit_preference': null,
    'sensitivity_negative': null,
  };

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mainGoalOther.dispose();
    _whyOther.dispose();
    super.dispose();
  }

  /// Returns null if all questions are answered, otherwise an error message.
  String? _validateAllAnswers() {
    // Q1 – main goal
    if (_answers['main_goal'] == null) {
      return 'Please select your main goal.';
    }
    if (_answers['main_goal'] == 'Other' &&
        _mainGoalOther.text.trim().isEmpty) {
      return 'Please specify your main goal.';
    }

    // Q2 – how many habits
    if (_answers['how_many_habits'] == null) {
      return 'Please choose how many habits you want to focus on.';
    }

    // Q3 – experience level
    if (_answers['experience_level'] == null) {
      return 'Please select your experience level with habits.';
    }

    // Q4 – most energetic
    if (_answers['most_energetic'] == null) {
      return 'Please choose when you are usually most energetic.';
    }

    // Q5 – weekday busyness (always has default value 3, so considered answered)

    // Q6 – preferred times
    if ((_answers['preferred_times'] as List).isEmpty) {
      return 'Please select at least one preferred time for doing your habits.';
    }

    // Q7 – why build habits
    final whyList = _answers['why_build'] as List;
    if (whyList.isEmpty) {
      return 'Please select why you want to build habits right now.';
    }
    if (whyList.contains('Other') && _whyOther.text.trim().isEmpty) {
      return 'Please specify your reason in "Other" for why you want to build habits.';
    }

    // Q8 – what stops you
    if ((_answers['what_stops'] as List).isEmpty) {
      return 'Please select what usually stops you from keeping habits.';
    }

    // Q9 – motivation style
    if ((_answers['motivation_style'] as List).isEmpty) {
      return 'Please select at least one way you like to be motivated.';
    }

    // Q10 – reminder frequency
    if (_answers['reminder_frequency'] == null) {
      return 'Please choose how often you want reminders.';
    }

    // Q11 – areas of interest
    if ((_answers['areas_interest'] as List).isEmpty) {
      return 'Please choose at least one area you want to build habits in.';
    }

    // Q12 – habit preference
    if (_answers['habit_preference'] == null) {
      return 'Please choose whether you prefer big habits or many small ones.';
    }

    // Q13 – sensitivity to negative feedback
    if (_answers['sensitivity_negative'] == null) {
      return 'Please tell us how sensitive you are to negative feedback.';
    }

    return null; // all good
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No user logged in.')));
      return;
    }

    // FULL validation – user must answer all questions
    final validationError = _validateAllAnswers();
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }

    // sync text fields into map (after validation)
    _answers['main_goal_other'] =
        _mainGoalOther.text.trim().isEmpty ? null : _mainGoalOther.text.trim();
    _answers['why_build_other'] =
        _whyOther.text.trim().isEmpty ? null : _whyOther.text.trim();

    setState(() => _saving = true);
    final repo = ref.read(questionnaireRepoProvider);

    final responses = {
      'answers': _answers,
      'submitted_at': DateTime.now().toIso8601String(),
    };

    try {
      await repo.saveResponses(user.id, responses);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — questionnaire saved.')),
      );
      appNavigatorKey.currentState?.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));

      log(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _questionTitle({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.accentRed.withOpacity(0.95),

                AppColors.backgroundCream.withOpacity(0.85),
                AppColors.primaryBlue.withOpacity(0.70),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.flag_rounded, size: 16, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryBlue, size: 20),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _glassCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.55),
                width: 1.1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.26),
                  Colors.white.withOpacity(0.10),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  // --- PAGE BUILDERS (one question per page) -------------------

  // Page 1: Intro + Q1
  Widget _buildPage1() {
    final textSecondary = AppColors.textSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryBlueSoft,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Help us personalize your experience',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'A few quick questions — it only takes a minute.',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Q1
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.flag_rounded,
                  text: '1) What’s your main goal right now?',
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (final option in [
                      'Get healthier / fitter',
                      'Be more productive',
                      'Manage stress / feel better mentally',
                      'Build better study / learning habits',
                      'Improve finances',
                      'Other',
                    ])
                      RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          option,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: option,
                        groupValue: _answers['main_goal'] as String?,
                        onChanged:
                            (v) => setState(() => _answers['main_goal'] = v),
                      ),
                    if ((_answers['main_goal'] as String?) == 'Other')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: TextField(
                          controller: _mainGoalOther,
                          decoration: const InputDecoration(
                            hintText: 'Please specify',
                            isDense: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 2: Q2
  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.format_list_numbered_rounded,
                  text:
                      '2) How many habits do you want to focus on at the beginning?',
                ),
                const SizedBox(height: 10),
                for (final option in [
                  'Just 1',
                  '2–3',
                  '4+ (I like doing a lot)',
                ])
                  RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: _answers['how_many_habits'] as String?,
                    onChanged:
                        (v) => setState(() => _answers['how_many_habits'] = v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 3: Q3
  Widget _buildPage3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.school_rounded,
                  text: '3) What’s your experience level with habits?',
                ),
                const SizedBox(height: 10),
                for (final option in [
                  'I’m a complete beginner',
                  'I’ve tried a few times but couldn’t stay consistent',
                  'I already have some habits and want to optimize',
                ])
                  RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: _answers['experience_level'] as String?,
                    onChanged:
                        (v) => setState(() => _answers['experience_level'] = v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 4: Q4 + section "Daily routine & time preferences"
  Widget _buildPage4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.access_time_rounded,
            text: 'Daily routine & time preferences',
          ),
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.wb_sunny_rounded,
                  text: '4) When are you usually most energetic?',
                ),
                const SizedBox(height: 10),
                for (final option in [
                  'Morning',
                  'Afternoon',
                  'Evening',
                  'It changes day to day',
                ])
                  RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: _answers['most_energetic'] as String?,
                    onChanged:
                        (v) => setState(() => _answers['most_energetic'] = v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 5: Q5
  Widget _buildPage5() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.schedule_rounded,
                  text: '5) How busy are your weekdays?',
                ),
                const SizedBox(height: 8),
                Slider(
                  value: (_answers['weekday_busyness'] as int).toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '${_answers['weekday_busyness']}',
                  activeColor: AppColors.accentRed,
                  onChanged:
                      (v) => setState(
                        () => _answers['weekday_busyness'] = v.toInt(),
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Not busy', style: TextStyle(fontSize: 12)),
                    Text('Extremely busy', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 6: Q6
  Widget _buildPage6() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.alarm_rounded,
                  text: '6) When do you prefer to do most of your habits?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'Before work / school',
                  'During day breaks',
                  'After work / school',
                  'Before bed',
                ])
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: (_answers['preferred_times'] as List).contains(
                      option,
                    ),
                    onChanged: (v) {
                      final list = List<String>.from(
                        _answers['preferred_times'] as List,
                      );
                      if (v == true) {
                        list.add(option);
                      } else {
                        list.remove(option);
                      }
                      setState(() => _answers['preferred_times'] = list);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 7: Q7 + section "Motivation & personality"
  Widget _buildPage7() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.psychology_rounded,
            text: 'Motivation & personality',
          ),
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.lightbulb_rounded,
                  text: '7) Why do you want to build habits right now?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'I’m tired of procrastinating',
                  'I want to feel healthier',
                  'I want more discipline',
                  'I want more control over my life',
                  'I have a specific goal / deadline',
                  'Other',
                ])
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: (_answers['why_build'] as List).contains(option),
                    onChanged: (v) {
                      final list = List<String>.from(
                        _answers['why_build'] as List,
                      );
                      if (v == true) {
                        list.add(option);
                      } else {
                        list.remove(option);
                      }
                      setState(() => _answers['why_build'] = list);
                    },
                  ),
                if ((_answers['why_build'] as List).contains('Other'))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TextField(
                      controller: _whyOther,
                      decoration: const InputDecoration(
                        hintText: 'Please specify',
                        isDense: true,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 8: Q8
  Widget _buildPage8() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.block_rounded,
                  text: '8) What usually stops you from keeping habits?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'I forget',
                  'I lose motivation',
                  'I get too busy',
                  'I get bored',
                  'I set goals that are too big',
                  'I don’t see progress quickly',
                ])
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: (_answers['what_stops'] as List).contains(option),
                    onChanged: (v) {
                      final list = List<String>.from(
                        _answers['what_stops'] as List,
                      );
                      if (v == true) {
                        list.add(option);
                      } else {
                        list.remove(option);
                      }
                      setState(() => _answers['what_stops'] = list);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 9: Q9
  Widget _buildPage9() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.favorite_border_rounded,
                  text: '9) How do you like to be motivated?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'Gentle reminders, no pressure',
                  'Encouraging & positive feedback',
                  'Tough love, no excuses',
                  'Data and stats keep me going',
                  'Rewards and gamification (points, badges, etc.)',
                ])
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: (_answers['motivation_style'] as List).contains(
                      option,
                    ),
                    onChanged: (v) {
                      final list = List<String>.from(
                        _answers['motivation_style'] as List,
                      );
                      if (v == true) {
                        list.add(option);
                      } else {
                        list.remove(option);
                      }
                      setState(() => _answers['motivation_style'] = list);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 10: Q10 + section "Notifications & communication"
  Widget _buildPage10() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.notifications_active_rounded,
            text: 'Notifications & communication',
          ),
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.notifications_rounded,
                  text: '10) How often do you want reminders?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'Only when it’s time to do the habit',
                  'One summary per day',
                  'A few nudges during the day',
                  'No notifications, I’ll check the app myself',
                ])
                  RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: _answers['reminder_frequency'] as String?,
                    onChanged:
                        (v) =>
                            setState(() => _answers['reminder_frequency'] = v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 11: Q11 + section "Habit types & interests"
  Widget _buildPage11() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.dashboard_customize_rounded,
            text: 'Habit types & interests',
          ),
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.layers_rounded,
                  text:
                      '11) Which areas are you most interested in building habits in?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'Health & Fitness (exercise, steps, water)',
                  'Mind & Mood (meditation, journaling, gratitude)',
                  'Productivity (deep work, planning, reading)',
                  'Learning (languages, skills, courses)',
                  'Finances (saving, expense tracking)',
                  'Social / Relationships (messaging friends, calling family)',
                ])
                  CheckboxListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: (_answers['areas_interest'] as List).contains(
                      option,
                    ),
                    onChanged: (v) {
                      final list = List<String>.from(
                        _answers['areas_interest'] as List,
                      );
                      if (v == true) {
                        list.add(option);
                      } else {
                        list.remove(option);
                      }
                      setState(() => _answers['areas_interest'] = list);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 12: Q12
  Widget _buildPage12() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.compare_arrows_rounded,
                  text: '12) Do you prefer:',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'One or two “big” habits',
                  'Many small, easy habits',
                ])
                  RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: _answers['habit_preference'] as String?,
                    onChanged:
                        (v) => setState(() => _answers['habit_preference'] = v),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Page 13: Q13 + section "Emotional / UX preferences"
  Widget _buildPage13() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(
            icon: Icons.mood_rounded,
            text: 'Emotional / UX preferences',
          ),
          const SizedBox(height: 8),
          _glassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _questionTitle(
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  text: '13) How sensitive are you to negative feedback?',
                ),
                const SizedBox(height: 6),
                for (final option in [
                  'Very – I prefer only positive messages',
                  'A little – gentle corrections are fine',
                  'Not at all – I can handle direct feedback',
                ])
                  RadioListTile<String>(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    title: Text(option, style: const TextStyle(fontSize: 14)),
                    value: option,
                    groupValue: _answers['sensitivity_negative'] as String?,
                    onChanged:
                        (v) => setState(
                          () => _answers['sensitivity_negative'] = v,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPages() {
    return [
      _buildPage1(),
      _buildPage2(),
      _buildPage3(),
      _buildPage4(),
      _buildPage5(),
      _buildPage6(),
      _buildPage7(),
      _buildPage8(),
      _buildPage9(),
      _buildPage10(),
      _buildPage11(),
      _buildPage12(),
      _buildPage13(),
    ];
  }

  String? _validatePage(int pageIndex) {
    switch (pageIndex) {
      case 0: // Q1 – main goal
        if (_answers['main_goal'] == null) {
          return 'Please select your main goal.';
        }
        if (_answers['main_goal'] == 'Other' &&
            _mainGoalOther.text.trim().isEmpty) {
          return 'Please specify your main goal.';
        }
        break;

      case 1: // Q2 – how many habits
        if (_answers['how_many_habits'] == null) {
          return 'Please choose how many habits you want to focus on.';
        }
        break;

      case 2: // Q3 – experience level
        if (_answers['experience_level'] == null) {
          return 'Please select your experience level with habits.';
        }
        break;

      case 3: // Q4 – most energetic
        if (_answers['most_energetic'] == null) {
          return 'Please choose when you are usually most energetic.';
        }
        break;

      case 4: // Q5 – weekday busyness (always has a default, so always valid)
        // no validation needed here
        break;

      case 5: // Q6 – preferred times
        if ((_answers['preferred_times'] as List).isEmpty) {
          return 'Please select at least one preferred time for doing your habits.';
        }
        break;

      case 6: // Q7 – why build habits
        final whyList = _answers['why_build'] as List;
        if (whyList.isEmpty) {
          return 'Please select why you want to build habits right now.';
        }
        if (whyList.contains('Other') && _whyOther.text.trim().isEmpty) {
          return 'Please specify your reason in "Other" for why you want to build habits.';
        }
        break;

      case 7: // Q8 – what stops you
        if ((_answers['what_stops'] as List).isEmpty) {
          return 'Please select what usually stops you from keeping habits.';
        }
        break;

      case 8: // Q9 – motivation style
        if ((_answers['motivation_style'] as List).isEmpty) {
          return 'Please select at least one way you like to be motivated.';
        }
        break;

      case 9: // Q10 – reminder frequency
        if (_answers['reminder_frequency'] == null) {
          return 'Please choose how often you want reminders.';
        }
        break;

      case 10: // Q11 – areas of interest
        if ((_answers['areas_interest'] as List).isEmpty) {
          return 'Please choose at least one area you want to build habits in.';
        }
        break;

      case 11: // Q12 – habit preference
        if (_answers['habit_preference'] == null) {
          return 'Please choose whether you prefer big habits or many small ones.';
        }
        break;

      case 12: // Q13 – sensitivity to negative feedback
        if (_answers['sensitivity_negative'] == null) {
          return 'Please tell us how sensitive you are to negative feedback.';
        }
        break;
    }

    return null; // this page is OK
  }

  Widget _buildBottomNav() {
    final isFirst = _currentPage == 0;
    final isLast = _currentPage == _totalPages - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Question ${_currentPage + 1} of $_totalPages',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!isFirst)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _saving
                            ? null
                            : () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundCream,
                      shape: LinearBorder(),
                    ),
                    label: const Text('Back'),
                  ),
                ),
              if (!isFirst) const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  label: Text(
                    _saving ? 'Saving...' : (isLast ? 'Save & Finish' : 'Next'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  onPressed:
                      _saving
                          ? null
                          : () {
                            if (isLast) {
                              // On the last page, still run full validation + submit
                              _submit();
                            } else {
                              // Per-page validation
                              final error = _validatePage(_currentPage);
                              if (error != null) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text(error)));
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              }
                            }
                          },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.skip_next_rounded),
              onPressed:
                  _saving
                      ? null
                      : () => appNavigatorKey.currentState?.pop(false),
              label: const Text('Skip for now', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        leading: const CloseButton(),
        title: const Text(
          'Personalize',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: pages,
                  ),
                ),
                // Bottom nav
                _buildBottomNav(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
