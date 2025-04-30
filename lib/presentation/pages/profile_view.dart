import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_profile_viewmodel.dart';
import '../../domain/entities/user_profile.dart';
import '../widgets/custom_app_bar.dart';
import '../../../core/constants/app_colors.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final profileVM = Provider.of<UserProfileViewModel>(context);
    final profile = profileVM.profile!;

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
                          const Text(
                            'Personal Information',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            Icons.person,
                            'Gender',
                            profile.gender,
                            onEdit: () => _showGenderDialog(context, profileVM),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.cake,
                            'Age',
                            '${profile.age} years',
                            onEdit: () => _showAgeDialog(context, profileVM),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.monitor_weight,
                            'Weight',
                            '${profileVM.displayWeight.toStringAsFixed(1)} ${profileVM.weightUnit}',
                            onEdit: () => _showWeightDialog(context, profileVM),
                          ),
                          const Divider(),
                          _buildInfoRow(
                            context,
                            Icons.height,
                            'Height',
                            '${profileVM.displayHeight.toStringAsFixed(1)} ${profileVM.heightUnit}',
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
                          const Text(
                            'Activity Level',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
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
                                    AppColors.primary, 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.directions_run,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      profile.activityLevel.displayName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.edit,
                                    color: AppColors.primary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.primary,
            ),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }

  void _showGenderDialog(BuildContext context, UserProfileViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Gender'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Male'),
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
              title: const Text('Female'),
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
    final controller = TextEditingController(text: vm.profile!.age.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Age'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            hintText: 'Enter your age',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final age = int.tryParse(controller.text) ?? vm.profile!.age;
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: age,
                weight: vm.displayWeight,
                weightUnit: vm.weightUnit,
                height: vm.displayHeight,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showWeightDialog(BuildContext context, UserProfileViewModel vm) {
    final controller = TextEditingController(text: vm.displayWeight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Weight'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weight',
                hintText: 'Enter your weight',
                suffixText: vm.weightUnit,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unit: ${vm.weightUnit}'),
                const SizedBox(width: 8),
                Switch(
                  value: vm.isMetric,
                  onChanged: (value) {
                    vm.saveProfile(
                      gender: vm.profile!.gender,
                      age: vm.profile!.age,
                      weight: vm.displayWeight,
                      weightUnit: value ? 'kg' : 'lbs',
                      height: vm.displayHeight,
                      heightUnit: vm.heightUnit,
                      activityLevel: vm.profile!.activityLevel,
                      isMetric: value,
                    );
                  },
                ),
                Text(vm.isMetric ? 'kg' : 'lbs'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showHeightDialog(BuildContext context, UserProfileViewModel vm) {
    final controller = TextEditingController(text: vm.displayHeight.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Height'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Height',
                hintText: 'Enter your height',
                suffixText: vm.heightUnit,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Unit: ${vm.heightUnit}'),
                const SizedBox(width: 8),
                Switch(
                  value: vm.isMetric,
                  onChanged: (value) {
                    vm.saveProfile(
                      gender: vm.profile!.gender,
                      age: vm.profile!.age,
                      weight: vm.displayWeight,
                      weightUnit: vm.weightUnit,
                      height: vm.displayHeight,
                      heightUnit: value ? 'cm' : 'inch',
                      activityLevel: vm.profile!.activityLevel,
                      isMetric: value,
                    );
                  },
                ),
                Text(vm.isMetric ? 'cm' : 'inch'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final height =
                  double.tryParse(controller.text) ?? vm.displayHeight;
              vm.saveProfile(
                gender: vm.profile!.gender,
                age: vm.profile!.age,
                weight: vm.displayWeight,
                weightUnit: vm.weightUnit,
                height: height,
                heightUnit: vm.heightUnit,
                activityLevel: vm.profile!.activityLevel,
                isMetric: vm.isMetric,
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showActivityLevelDialog(BuildContext context, UserProfileViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Activity Level'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ActivityLevel.values.map((level) {
            return ListTile(
              title: Text(level.displayName),
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
}
