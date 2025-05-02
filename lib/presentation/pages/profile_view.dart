import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../viewmodels/theme_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/custom_app_bar.dart';
import '../../../core/constants/app_colors.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        icon: Icons.person,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              // Unit system toggle
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.withOpacity(
                                      colorScheme.primary, 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Imperial',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: !profileVM.isMetric
                                            ? colorScheme.primary
                                            : colorScheme.onSurface
                                                .withOpacity(0.5),
                                      ),
                                    ),
                                    Transform.scale(
                                      scale: 0.8,
                                      child: Switch(
                                        value: profileVM.isMetric,
                                        onChanged: (value) {
                                          final newWeight = value
                                              ? profileVM.displayWeight *
                                                  0.453592 // lbs to kg
                                              : profileVM.displayWeight *
                                                  2.20462; // kg to lbs
                                          final newHeight = value
                                              ? profileVM.displayHeight *
                                                  2.54 // inch to cm
                                              : profileVM.displayHeight /
                                                  2.54; // cm to inch
                                          profileVM.saveProfile(
                                            gender: profileVM.profile!.gender,
                                            age: profileVM.profile!.age,
                                            weight: newWeight,
                                            weightUnit: value ? 'kg' : 'lbs',
                                            height: newHeight,
                                            heightUnit: value ? 'cm' : 'inch',
                                            activityLevel: profileVM
                                                .profile!.activityLevel,
                                            isMetric: value,
                                          );
                                        },
                                      ),
                                    ),
                                    Text(
                                      'Metric',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: profileVM.isMetric
                                            ? colorScheme.primary
                                            : colorScheme.onSurface
                                                .withOpacity(0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            Icons.person,
                            'Gender',
                            profile.gender,
                            onEdit: () => _showGenderDialog(context, profileVM),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.cake,
                            'Age',
                            '${profile.age} years',
                            onEdit: () => _showAgeDialog(context, profileVM),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.monitor_weight,
                            'Weight',
                            '${profileVM.displayWeight.toStringAsFixed(1)} ${profileVM.weightUnit}',
                            onEdit: () => _showWeightDialog(context, profileVM),
                          ),
                          _buildInfoRow(
                            context,
                            Icons.height,
                            'Height',
                            profileVM.isMetric
                                ? '${profileVM.displayHeight.toStringAsFixed(1)} cm'
                                : '${(profileVM.displayHeight / 12).floor()}′${(profileVM.displayHeight % 12).round()}″',
                            onEdit: () => _showHeightDialog(context, profileVM),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Activity Level Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Activity Level',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          InkWell(
                            onTap: () =>
                                _showActivityLevelDialog(context, profileVM),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.withOpacity(
                                    colorScheme.primary, 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.directions_run,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Activity Level',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          profile.activityLevel.displayName,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Theme Selection Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Appearance',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Consumer<ThemeViewModel>(
                            builder: (context, themeVM, _) {
                              final isDark = Theme.of(context).brightness ==
                                  Brightness.dark;
                              String themeText;
                              IconData themeIcon;

                              switch (themeVM.themeMode) {
                                case ThemeMode.light:
                                  themeText = 'Light';
                                  themeIcon = Icons.light_mode;
                                  break;
                                case ThemeMode.dark:
                                  themeText = 'Dark';
                                  themeIcon = Icons.dark_mode;
                                  break;
                                case ThemeMode.system:
                                  themeText = 'System';
                                  themeIcon = isDark
                                      ? Icons.dark_mode
                                      : Icons.light_mode;
                                  break;
                              }

                              return InkWell(
                                onTap: () => _showThemeDialog(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.withOpacity(
                                        colorScheme.primary, 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        themeIcon,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Theme',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              themeText,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: colorScheme.onSurface
                                                    .withOpacity(0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.edit,
                                        color: colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    required VoidCallback onEdit,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(colorScheme.primary, 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenderDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Gender',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.male,
                color: colorScheme.primary,
              ),
              title: Text(
                'Male',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                vm.profile!.gender == 'Male'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: vm.profile!.gender == 'Male'
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                vm.saveProfile(
                  gender: 'Male',
                  age: vm.profile!.age,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: vm.profile!.activityLevel,
                  isMetric: vm.isMetric,
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.female,
                color: colorScheme.primary,
              ),
              title: Text(
                'Female',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                vm.profile!.gender == 'Female'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: vm.profile!.gender == 'Female'
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                vm.saveProfile(
                  gender: 'Female',
                  age: vm.profile!.age,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: vm.profile!.activityLevel,
                  isMetric: vm.isMetric,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAgeDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    int selectedAge = vm.profile!.age;
    final FixedExtentScrollController scrollController =
        FixedExtentScrollController(
      initialItem: selectedAge - 1, // Subtract 1 since age starts from 1
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Age',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: SizedBox(
          height: 100,
          child: Stack(
            children: [
              // Center indicator
              Positioned.fill(
                child: Center(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.withOpacity(colorScheme.primary, 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              // Age picker
              Stack(
                children: [
                  ListWheelScrollView.useDelegate(
                    controller: scrollController,
                    itemExtent: 50,
                    perspective: 0.005,
                    diameterRatio: 1.2,
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      childCount: 100, // Ages 1-100
                      builder: (context, index) {
                        final age = index + 1;
                        return Center(
                          child: Text(
                            age.toString(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: selectedAge == age
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: selectedAge == age
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        );
                      },
                    ),
                    onSelectedItemChanged: (index) {
                      selectedAge = index + 1;
                    },
                  ),
                  // Static "years" text
                  Positioned(
                    right: 16,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        'years',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: selectedAge,
                weight: vm.displayWeight,
                weightUnit: vm.weightUnit,
                height: vm.displayHeight,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    double selectedWeight = vm.displayWeight;
    final controller = TextEditingController(
      text: selectedWeight.toStringAsFixed(1),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Weight',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.withOpacity(colorScheme.primary, 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Decrement button
              InkWell(
                onTap: () {
                  selectedWeight =
                      double.parse((selectedWeight - 0.5).toStringAsFixed(1));
                  controller.text = selectedWeight.toStringAsFixed(1);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              // Weight input
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          selectedWeight =
                              double.tryParse(value) ?? selectedWeight;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    vm.weightUnit,
                    style: TextStyle(
                      fontSize: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              // Increment button
              InkWell(
                onTap: () {
                  selectedWeight =
                      double.parse((selectedWeight + 0.5).toStringAsFixed(1));
                  controller.text = selectedWeight.toStringAsFixed(1);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final weight =
                  double.tryParse(controller.text) ?? vm.displayWeight;
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: vm.profile!.age,
                weight: weight,
                weightUnit: vm.weightUnit,
                height: vm.displayHeight,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHeightDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    double selectedHeight = vm.displayHeight;

    // For imperial measurements
    int feet = vm.isMetric ? 0 : (selectedHeight / 12).floor();
    int inches = vm.isMetric ? 0 : (selectedHeight % 12).round();

    // Controllers for different unit systems
    final metricController = TextEditingController(
      text: vm.isMetric ? selectedHeight.toStringAsFixed(1) : '0',
    );

    void updateImperialToMetric() {
      final totalInches = (feet * 12 + inches).toDouble();
      selectedHeight = totalInches * 2.54; // Convert to cm
      metricController.text = selectedHeight.toStringAsFixed(1);
    }

    void updateMetricToImperial() {
      final totalInches = selectedHeight / 2.54; // Convert to inches
      feet = (totalInches / 12).floor();
      inches = (totalInches % 12).round();
      if (inches == 12) {
        feet += 1;
        inches = 0;
      }
    }

    if (!vm.isMetric) {
      updateMetricToImperial();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Height',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.withOpacity(colorScheme.primary, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: vm.isMetric
                  ? // Metric (cm) input
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Decrement button
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedHeight = double.parse(
                                  (selectedHeight - 0.5).toStringAsFixed(1));
                              metricController.text =
                                  selectedHeight.toStringAsFixed(1);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.remove,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        // Height input
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: metricController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                  isDense: true,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      selectedHeight = double.tryParse(value) ??
                                          selectedHeight;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'cm',
                              style: TextStyle(
                                fontSize: 20,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        // Increment button
                        InkWell(
                          onTap: () {
                            setState(() {
                              selectedHeight = double.parse(
                                  (selectedHeight + 0.5).toStringAsFixed(1));
                              metricController.text =
                                  selectedHeight.toStringAsFixed(1);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.add,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : // Imperial (feet/inches) input
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Feet picker
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.keyboard_arrow_up,
                                  color: colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  if (feet < 8) {
                                    feet++;
                                    updateImperialToMetric();
                                  }
                                });
                              },
                            ),
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$feet′',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  if (feet > 0) {
                                    feet--;
                                    updateImperialToMetric();
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Inches picker
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.keyboard_arrow_up,
                                  color: colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  if (inches < 11) {
                                    inches++;
                                  } else {
                                    inches = 0;
                                    if (feet < 8) feet++;
                                  }
                                  updateImperialToMetric();
                                });
                              },
                            ),
                            Container(
                              width: 60,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '$inches″',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: colorScheme.primary),
                              onPressed: () {
                                setState(() {
                                  if (inches > 0) {
                                    inches--;
                                  } else if (feet > 0) {
                                    inches = 11;
                                    feet--;
                                  }
                                  updateImperialToMetric();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: vm.profile!.age,
                weight: vm.displayWeight,
                weightUnit: vm.weightUnit,
                height: selectedHeight,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
              );
              Navigator.pop(context);
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActivityLevelDialog(BuildContext context, UserProfileViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;

    IconData getActivityIcon(ActivityLevel level) {
      switch (level) {
        case ActivityLevel.sedentary:
          return Icons.weekend;
        case ActivityLevel.lightlyActive:
          return Icons.directions_walk;
        case ActivityLevel.moderatelyActive:
          return Icons.directions_run;
        case ActivityLevel.veryActive:
          return Icons.fitness_center;
        case ActivityLevel.extraActive:
          return Icons.sports_gymnastics;
        default:
          return Icons.directions_run;
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Activity Level',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActivityLevel.values.map((level) {
            return ListTile(
              leading: Icon(
                getActivityIcon(level),
                color: colorScheme.primary,
              ),
              title: Text(
                level.displayName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                vm.profile!.activityLevel == level
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: vm.profile!.activityLevel == level
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                vm.saveProfile(
                  gender: vm.profile!.gender,
                  age: vm.profile!.age,
                  weight: vm.displayWeight,
                  weightUnit: vm.weightUnit,
                  height: vm.displayHeight,
                  heightUnit: vm.heightUnit,
                  activityLevel: level,
                  isMetric: vm.isMetric,
                );
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {

    final colorScheme = Theme.of(context).colorScheme;
    final themeVM = Provider.of<ThemeViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Select Theme',
          style: TextStyle(
            color: colorScheme.onSurface,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.light_mode,
                color: colorScheme.primary,
              ),
              title: Text(
                'Light',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                themeVM.themeMode == ThemeMode.light
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: themeVM.themeMode == ThemeMode.light
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                themeVM.setThemeMode(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.dark_mode,
                color: colorScheme.primary,
              ),
              title: Text(
                'Dark',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                themeVM.themeMode == ThemeMode.dark
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: themeVM.themeMode == ThemeMode.dark
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                themeVM.setThemeMode(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.brightness_auto,
                color: colorScheme.primary,
              ),
              title: Text(
                'System',
                style: TextStyle(
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Icon(
                themeVM.themeMode == ThemeMode.system
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: themeVM.themeMode == ThemeMode.system
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              onTap: () {
                themeVM.setThemeMode(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
