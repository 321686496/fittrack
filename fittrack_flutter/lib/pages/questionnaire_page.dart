import 'package:flutter/material.dart';
import '../themes/app_themes.dart';
import '../data/storage.dart';
import '../services/user_profile_generator.dart';
import '../widgets/common_widgets.dart';

class QuestionnairePage extends StatefulWidget {
  final void Function(Map<String, dynamic> profileData) onComplete;
  final VoidCallback onSkip;

  const QuestionnairePage({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int _currentStep = 0;
  final int _totalSteps = 6;

  String? _gender;
  String? _fitnessGoal;
  String? _fitnessLevel;
  String? _trainingFrequency;
  String _trainingTime = '';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<Map<String, dynamic>> _genderOptions = [
    {'value': '男', 'icon': Icons.male, 'label': '男'},
    {'value': '女', 'icon': Icons.female, 'label': '女'},
  ];

  final List<Map<String, dynamic>> _goalOptions = [
    {'value': '增肌', 'icon': Icons.fitness_center, 'label': '增肌'},
    {'value': '减脂', 'icon': Icons.local_fire_department, 'label': '减脂'},
    {'value': '塑形', 'icon': Icons.accessibility_new, 'label': '塑形'},
    {'value': '保持健康', 'icon': Icons.favorite, 'label': '保持健康'},
  ];

  final List<Map<String, dynamic>> _levelOptions = [
    {'value': '新手', 'icon': Icons.looks_one, 'label': '新手'},
    {'value': '初级', 'icon': Icons.looks_two, 'label': '初级'},
    {'value': '中级', 'icon': Icons.looks_3, 'label': '中级'},
    {'value': '高级', 'icon': Icons.looks_4, 'label': '高级'},
  ];

  final List<Map<String, dynamic>> _frequencyOptions = [
    {'value': '2天/周', 'label': '2天/周'},
    {'value': '3天/周', 'label': '3天/周'},
    {'value': '4天/周', 'label': '4天/周'},
    {'value': '5天/周', 'label': '5天/周'},
    {'value': '6天/周', 'label': '6天/周'},
  ];

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _gender != null;
      case 1:
        return _fitnessGoal != null;
      case 2:
        return _fitnessLevel != null;
      case 3:
        return _trainingFrequency != null;
      case 4:
        return _heightController.text.isNotEmpty && _weightController.text.isNotEmpty;
      case 5:
        return true; // 训练时间可选
      default:
        return false;
    }
  }

  void _selectOption(String value) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _gender = value;
          break;
        case 1:
          _fitnessGoal = value;
          break;
        case 2:
          _fitnessLevel = value;
          break;
        case 3:
          _trainingFrequency = value;
          break;
      }
    });
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _complete();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _complete() {
    final gender = _gender ?? '';
    final fitnessGoal = _fitnessGoal ?? '';
    final fitnessLevel = _fitnessLevel ?? '';

    // 根据问卷信息自动生成用户名和头像
    final userName = UserProfileGenerator.generateUserName(
      gender: gender,
      fitnessGoal: fitnessGoal,
      fitnessLevel: fitnessLevel,
    );
    final avatarConfig = UserProfileGenerator.generateAvatar(
      gender: gender,
      fitnessGoal: fitnessGoal,
      fitnessLevel: fitnessLevel,
    );

    final profileData = <String, dynamic>{
      'gender': gender,
      'fitnessGoal': fitnessGoal,
      'fitnessLevel': fitnessLevel,
      'trainingFrequency': _trainingFrequency ?? '',
      'height': double.tryParse(_heightController.text) ?? 0,
      'weight': double.tryParse(_weightController.text) ?? 0,
      'userName': userName,
      'avatarEmoji': avatarConfig['emoji'],
      'avatarBgColor': avatarConfig['bgColor'],
      'onboardingDone': true,
    };

    // Save to settings
    final settings = Storage.getSettings();
    settings['gender'] = profileData['gender'];
    settings['fitnessGoal'] = profileData['fitnessGoal'];
    settings['fitnessLevel'] = profileData['fitnessLevel'];
    settings['trainingFrequency'] = profileData['trainingFrequency'];
    settings['height'] = profileData['height'];
    settings['weight'] = profileData['weight'];
    settings['userName'] = profileData['userName'];
    settings['avatarEmoji'] = profileData['avatarEmoji'];
    settings['avatarBgColor'] = profileData['avatarBgColor'];
    settings['onboardingDone'] = true;
    settings['trainingTime'] = _trainingTime;
    Storage.saveSettings(settings);

    // Save body data if height/weight provided
    if (profileData['height'] != 0 || profileData['weight'] != 0) {
      final bodyData = Storage.getBodyData();
      if (profileData['height'] != 0) {
        bodyData['height'] = profileData['height'];
      }
      if (profileData['weight'] != 0) {
        bodyData['weight'] = profileData['weight'];
      }
      if (profileData['height'] != 0 && profileData['weight'] != 0) {
        final heightM = (profileData['height'] as double) / 100;
        if (heightM > 0) {
          bodyData['bmi'] = double.parse(
            ((profileData['weight'] as double) / (heightM * heightM)).toStringAsFixed(1),
          );
        }
      }
      Storage.saveBodyData(bodyData);
    }

    widget.onComplete(profileData);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<FitTrackColors>()!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      onPressed: _prevStep,
                      icon: Icon(
                        Icons.arrow_back_ios,
                        size: 20,
                        color: colors.textPrimary,
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      '${_currentStep + 1}/$_totalSteps',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onSkip,
                    child: Text(
                      '跳过',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ProgressBar(
                progress: (_currentStep + 1) / _totalSteps,
                fillColor: colors.accentGlow,
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildStepContent(colors),
              ),
            ),
            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canProceed ? _nextStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.accentGlow,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? colors.textPrimary
                        : Colors.white,
                    disabledBackgroundColor: colors.accentGlow.withOpacity(0.3),
                    disabledForegroundColor: colors.textMuted,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentStep < _totalSteps - 1 ? '下一步' : '完成',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(FitTrackColors colors) {
    switch (_currentStep) {
      case 0:
        return _buildSelectionStep(
          colors: colors,
          question: '你的性别是？',
          options: _genderOptions,
          selectedValue: _gender,
        );
      case 1:
        return _buildSelectionStep(
          colors: colors,
          question: '你的健身目标是什么？',
          options: _goalOptions,
          selectedValue: _fitnessGoal,
        );
      case 2:
        return _buildSelectionStep(
          colors: colors,
          question: '你的健身水平如何？',
          options: _levelOptions,
          selectedValue: _fitnessLevel,
        );
      case 3:
        return _buildSelectionStep(
          colors: colors,
          question: '你计划每周训练几天？',
          options: _frequencyOptions,
          selectedValue: _trainingFrequency,
        );
      case 4:
        return _buildBodyInfoStep(colors);
      case 5:
        return _buildTrainingTimeStep(colors);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelectionStep({
    required FitTrackColors colors,
    required String question,
    required List<Map<String, dynamic>> options,
    required String? selectedValue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          question,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: options.map((option) {
            final isSelected = selectedValue == option['value'];
            return GestureDetector(
              onTap: () => _selectOption(option['value'] as String),
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentGlow.withOpacity(0.12)
                      : colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? colors.accentGlow
                        : colors.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    if (option['icon'] != null)
                      Icon(
                        option['icon'] as IconData,
                        size: 28,
                        color: isSelected
                            ? colors.accentGlow
                            : colors.textSecondary,
                      ),
                    if (option['icon'] != null) const SizedBox(height: 8),
                    Text(
                      option['label'] as String,
                      style: TextStyle(
                        color: isSelected
                            ? colors.accentGlow
                            : colors.textPrimary,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBodyInfoStep(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          '你的身体数据',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '用于计算BMI和个性化推荐',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _heightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '身高 (cm)',
            hintText: '例如：175',
            suffixText: 'cm',
            suffixStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '体重 (kg)',
            hintText: '例如：72.5',
            suffixText: 'kg',
            suffixStyle: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
        if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.accentGlow.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.monitor_weight, color: colors.accentGlow, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BMI 指数',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _calculateBMI(),
                      style: TextStyle(
                        color: colors.accentGlow,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  _getBMICategory(),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _calculateBMI() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null || height <= 0) return '--';
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    return bmi.toStringAsFixed(1);
  }

  String _getBMICategory() {
    final height = double.tryParse(_heightController.text);
    final weight = double.tryParse(_weightController.text);
    if (height == null || weight == null || height <= 0) return '';
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    if (bmi < 18.5) return '偏瘦';
    if (bmi < 24) return '正常';
    if (bmi < 28) return '偏胖';
    return '肥胖';
  }

  Widget _buildTrainingTimeStep(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          '你想要什么时间训练？',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '设置后我们会在这个时间提醒你开始训练',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () async {
            final now = TimeOfDay.now();
            final initialTime = _trainingTime.isNotEmpty
                ? _parseTimeOfDay(_trainingTime)
                : const TimeOfDay(hour: 18, minute: 0);
            final picked = await showTimePicker(
              context: context,
              initialTime: initialTime,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    timePickerTheme: TimePickerThemeData(
                      backgroundColor: colors.bgCard,
                      hourMinuteTextColor: colors.textPrimary,
                      dialHandColor: colors.accentGlow,
                      dialBackgroundColor: colors.bgSecondary,
                      entryModeIconColor: colors.accentGlow,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _trainingTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _trainingTime.isNotEmpty ? colors.accentGlow : colors.borderColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _trainingTime.isNotEmpty ? _trainingTime : '点击选择时间',
                  style: TextStyle(
                    color: _trainingTime.isNotEmpty ? colors.accentGlow : colors.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.access_time, color: _trainingTime.isNotEmpty ? colors.accentGlow : colors.textMuted),
              ],
            ),
          ),
        ),
        if (_trainingTime.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton(
              onPressed: () => _nextStep(),
              child: Text(
                '跳过（可在个人中心设置）',
                style: TextStyle(color: colors.textMuted, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 18,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }
}
