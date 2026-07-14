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
  final int _totalSteps = 8;

  String? _gender;
  String? _fitnessGoal;
  String? _fitnessLevel;
  String? _trainingFrequency;
  String? _channelSource;
  String _trainingTime = '';
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  // 身体数据详细字段（可选）
  final TextEditingController _bodyFatController = TextEditingController();
  final TextEditingController _chestController = TextEditingController();
  final TextEditingController _waistController = TextEditingController();
  final TextEditingController _hipController = TextEditingController();
  final TextEditingController _armCircumferenceController = TextEditingController();
  final TextEditingController _thighCircumferenceController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _restingHeartRateController = TextEditingController();

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

  final List<Map<String, String>> _channelOptions = [
    {'label': '应用商店搜索', 'value': 'store'},
    {'label': '小红书', 'value': 'xiaohongshu'},
    {'label': '抖音', 'value': 'douyin'},
    {'label': '朋友推荐', 'value': 'friend'},
    {'label': '健身房', 'value': 'gym'},
    {'label': '其他', 'value': 'other'},
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
        return true; // 身体数据详细字段均为可选，可跳过
      case 6:
        return true; // 训练时间可选
      case 7:
        return true; // 渠道来源可选，可跳过
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

    // 解析身体数据详细字段（均为可选）
    final bodyFat = double.tryParse(_bodyFatController.text);
    final chest = double.tryParse(_chestController.text);
    final waist = double.tryParse(_waistController.text);
    final hip = double.tryParse(_hipController.text);
    final armCircumference = double.tryParse(_armCircumferenceController.text);
    final thighCircumference = double.tryParse(_thighCircumferenceController.text);
    final targetWeight = double.tryParse(_targetWeightController.text);
    final restingHeartRate = double.tryParse(_restingHeartRateController.text);

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
      // 身体数据详细字段（仅在用户填写时存入，否则不写入 key）
      if (bodyFat != null) 'bodyFat': bodyFat,
      if (chest != null) 'chest': chest,
      if (waist != null) 'waist': waist,
      if (hip != null) 'hip': hip,
      if (armCircumference != null) 'armCircumference': armCircumference,
      if (thighCircumference != null) 'thighCircumference': thighCircumference,
      if (targetWeight != null) 'targetWeight': targetWeight,
      if (restingHeartRate != null) 'restingHeartRate': restingHeartRate,
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
    settings['channelSource'] = _channelSource ?? '';
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
      // 合并身体数据详细字段（仅当用户填写时才更新）
      if (bodyFat != null) bodyData['bodyFat'] = bodyFat;
      if (chest != null) bodyData['chest'] = chest;
      if (waist != null) bodyData['waist'] = waist;
      if (hip != null) bodyData['hip'] = hip;
      if (armCircumference != null) bodyData['armCircumference'] = armCircumference;
      if (thighCircumference != null) bodyData['thighCircumference'] = thighCircumference;
      if (targetWeight != null) bodyData['targetWeight'] = targetWeight;
      if (restingHeartRate != null) bodyData['restingHeartRate'] = restingHeartRate;
      bodyData['lastUpdate'] = '刚刚';
      Storage.saveBodyData(bodyData);
    }

    widget.onComplete(profileData);
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipController.dispose();
    _armCircumferenceController.dispose();
    _thighCircumferenceController.dispose();
    _targetWeightController.dispose();
    _restingHeartRateController.dispose();
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
        return _buildBodyDetailsStep(colors);
      case 6:
        return _buildTrainingTimeStep(colors);
      case 7:
        return _buildChannelStep(colors);
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

  /// 身体数据详细步骤：体脂率、围度、目标体重、静息心率（均可选）
  Widget _buildBodyDetailsStep(FitTrackColors colors) {
    // 字段配置：[label, controller, hintText]
    final fields = <List<dynamic>>[
      ['体脂率 (%)', _bodyFatController, '5 - 50'],
      ['胸围 (cm)', _chestController, '50 - 150'],
      ['腰围 (cm)', _waistController, '40 - 130'],
      ['臀围 (cm)', _hipController, '50 - 150'],
      ['上臂围 (cm)', _armCircumferenceController, '15 - 60'],
      ['大腿围 (cm)', _thighCircumferenceController, '30 - 80'],
      ['目标体重 (kg)', _targetWeightController, '30 - 200'],
      ['静息心率 (bpm)', _restingHeartRateController, '40 - 120'],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          '更多身体数据',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '可选填写，用于更精准的训练推荐',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        // 2 列网格布局
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          // 单元格高度比例，保证标签 + 输入框能正常显示
          childAspectRatio: 1.85,
          children: fields.map((f) {
            return FitTextField(
              controller: f[1] as TextEditingController,
              label: f[0] as String,
              hint: f[2] as String,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // 跳过提示
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: colors.textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '以上字段均为可选，可直接点击"下一步"跳过',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
    // 自定义时间段选项
    final timeSlots = [
      {'label': '清晨', 'time': '06:00', 'icon': Icons.wb_sunny_outlined, 'desc': '06:00 - 08:00'},
      {'label': '上午', 'time': '09:00', 'icon': Icons.wb_sunny, 'desc': '09:00 - 11:00'},
      {'label': '中午', 'time': '12:00', 'icon': Icons.light_mode_outlined, 'desc': '12:00 - 14:00'},
      {'label': '下午', 'time': '15:00', 'icon': Icons.wb_twilight, 'desc': '15:00 - 17:00'},
      {'label': '傍晚', 'time': '18:00', 'icon': Icons.brightness_3_outlined, 'desc': '18:00 - 20:00'},
      {'label': '夜间', 'time': '20:00', 'icon': Icons.nights_stay_outlined, 'desc': '20:00 - 22:00'},
    ];

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
        // 时间段选择
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: timeSlots.map((slot) {
            final isSelected = _trainingTime == slot['time'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _trainingTime = slot['time'] as String;
                });
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentGlow.withOpacity(0.12)
                      : colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? colors.accentGlow : colors.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      slot['icon'] as IconData,
                      size: 24,
                      color: isSelected ? colors.accentGlow : colors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      slot['label'] as String,
                      style: TextStyle(
                        color: isSelected ? colors.accentGlow : colors.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      slot['desc'] as String,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // 自定义时间输入
        if (_trainingTime.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentGlow.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accentGlow.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_active, color: colors.accentGlow, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '将在每天 $_trainingTime 提醒你训练',
                    style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        if (_trainingTime.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
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

  Widget _buildChannelStep(FitTrackColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          '你从哪里找到 FitTrack？',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '帮助我们了解用户来源（可选）',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _channelOptions.map((option) {
            final isSelected = _channelSource == option['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _channelSource = option['value'];
                });
              },
              child: Container(
                width: (MediaQuery.of(context).size.width - 60) / 2,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.accentGlow.withOpacity(0.12)
                      : colors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? colors.accentGlow : colors.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Text(
                  option['label']!,
                  style: TextStyle(
                    color: isSelected ? colors.accentGlow : colors.textPrimary,
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

}
