import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class UnitSwitchButton extends StatelessWidget {
  final bool isMetric;
  final ValueChanged<bool> onChanged;

  const UnitSwitchButton({
    super.key,
    required this.isMetric,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(colorScheme.primary, 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Imperial',
            style: TextStyle(
              fontSize: 12,
              color: !isMetric
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: isMetric,
              onChanged: onChanged,
            ),
          ),
          Text(
            'Metric',
            style: TextStyle(
              fontSize: 12,
              color: isMetric
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class AgeInput extends StatelessWidget {
  final int age;
  final ValueChanged<int> onChanged;

  const AgeInput({
    super.key,
    required this.age,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scrollController = FixedExtentScrollController(
      initialItem: age - 1,
    );

    return SizedBox(
      height: 100,
      child: Stack(
        children: [
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
          Stack(
            children: [
              ListWheelScrollView.useDelegate(
                controller: scrollController,
                itemExtent: 50,
                perspective: 0.005,
                diameterRatio: 1.2,
                physics: const FixedExtentScrollPhysics(),
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 100,
                  builder: (context, index) {
                    final currentAge = index + 1;
                    return Center(
                      child: Text(
                        currentAge.toString(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: age == currentAge
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: age == currentAge
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  },
                ),
                onSelectedItemChanged: (index) {
                  onChanged(index + 1);
                },
              ),
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
    );
  }
}

class WeightInput extends StatefulWidget {
  final double weight;
  final String unit;
  final ValueChanged<double> onChanged;

  const WeightInput({
    super.key,
    required this.weight,
    required this.unit,
    required this.onChanged,
  });

  @override
  State<WeightInput> createState() => _WeightInputState();
}

class _WeightInputState extends State<WeightInput> {
  late TextEditingController controller;
  late double currentWeight;

  @override
  void initState() {
    super.initState();
    currentWeight = widget.weight;
    controller = TextEditingController(
      text: currentWeight.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void updateWeight(double newWeight) {
    setState(() {
      currentWeight = newWeight;
      controller.text = newWeight.toStringAsFixed(1);
    });
    widget.onChanged(newWeight);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(colorScheme.primary, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              final newWeight =
                  double.parse((currentWeight - 0.5).toStringAsFixed(1));
              updateWeight(newWeight);
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
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final newWeight = double.tryParse(value) ?? currentWeight;
                      updateWeight(newWeight);
                    }
                  },
                ),
              ),
              const SizedBox(width: 4),
              Text(
                widget.unit,
                style: TextStyle(
                  fontSize: 20,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () {
              final newWeight =
                  double.parse((currentWeight + 0.5).toStringAsFixed(1));
              updateWeight(newWeight);
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
    );
  }
}

class HeightInput extends StatefulWidget {
  final double height;
  final bool isMetric;
  final ValueChanged<double> onChanged;

  const HeightInput({
    super.key,
    required this.height,
    required this.isMetric,
    required this.onChanged,
  });

  @override
  State<HeightInput> createState() => _HeightInputState();
}

class _HeightInputState extends State<HeightInput> {
  late TextEditingController metricController;
  late double currentHeight;
  late int feet;
  late int inches;

  @override
  void initState() {
    super.initState();
    currentHeight = widget.height;
    metricController = TextEditingController(
      text: widget.isMetric ? currentHeight.toStringAsFixed(1) : '0',
    );
    if (!widget.isMetric) {
      updateMetricToImperial();
    }
  }

  @override
  void dispose() {
    metricController.dispose();
    super.dispose();
  }

  void updateImperialToMetric() {
    final totalInches = (feet * 12 + inches).toDouble();
    final newHeight = totalInches * 2.54; // Convert to cm
    setState(() {
      currentHeight = newHeight;
      metricController.text = newHeight.toStringAsFixed(1);
    });
    widget.onChanged(newHeight);
  }

  void updateMetricToImperial() {
    final totalInches = currentHeight / 2.54; // Convert to inches
    feet = (totalInches / 12).floor();
    inches = (totalInches % 12).round();
    if (inches == 12) {
      feet += 1;
      inches = 0;
    }
  }

  void updateHeight(double newHeight) {
    setState(() {
      currentHeight = newHeight;
      metricController.text = newHeight.toStringAsFixed(1);
    });
    widget.onChanged(newHeight);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(colorScheme.primary, 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.isMetric
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () {
                    final newHeight =
                        double.parse((currentHeight - 0.5).toStringAsFixed(1));
                    updateHeight(newHeight);
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: metricController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            final newHeight =
                                double.tryParse(value) ?? currentHeight;
                            updateHeight(newHeight);
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
                InkWell(
                  onTap: () {
                    final newHeight =
                        double.parse((currentHeight + 0.5).toStringAsFixed(1));
                    updateHeight(newHeight);
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_up,
                          color: colorScheme.primary),
                      onPressed: () {
                        if (feet < 8) {
                          setState(() {
                            feet++;
                            updateImperialToMetric();
                          });
                        }
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
                        if (feet > 0) {
                          setState(() {
                            feet--;
                            updateImperialToMetric();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(width: 16),
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
  }
}
