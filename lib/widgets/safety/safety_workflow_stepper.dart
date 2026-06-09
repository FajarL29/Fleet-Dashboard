import 'package:flutter/material.dart';

import '../report/report_styles.dart';

class SafetyWorkflowStepper extends StatelessWidget {
  const SafetyWorkflowStepper({super.key});

  static const _steps = [
    _WorkflowStep(
      title: 'Monitoring',
      subtitle: 'Continuous driver monitoring',
      icon: Icons.visibility_outlined,
      color: Color(0xFF3BA55D),
    ),
    _WorkflowStep(
      title: 'Event Detected',
      subtitle: 'Potential safety risk identified',
      icon: Icons.warning_amber_rounded,
      color: ReportStyles.orange,
    ),
    _WorkflowStep(
      title: 'Review',
      subtitle: 'Safety officer reviews event',
      icon: Icons.search_rounded,
      color: ReportStyles.blue,
      isActive: true,
    ),
    _WorkflowStep(
      title: 'Action',
      subtitle: 'Action workflow coming soon',
      icon: Icons.person_outline_rounded,
      color: ReportStyles.purple,
    ),
    _WorkflowStep(
      title: 'Reporting',
      subtitle: 'Event logged and reported',
      icon: Icons.assignment_outlined,
      color: Color(0xFF28A9B2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.65)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1100;
          if (isCompact) {
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _steps
                  .asMap()
                  .entries
                  .map(
                    (entry) => SizedBox(
                      width: constraints.maxWidth > 540
                          ? (constraints.maxWidth - 12) / 2
                          : constraints.maxWidth,
                      child: _WorkflowStepTile(
                        index: entry.key + 1,
                        step: entry.value,
                      ),
                    ),
                  )
                  .toList(),
            );
          }

          return Row(
            children: _steps.asMap().entries.expand((entry) sync* {
              yield Expanded(
                child: _WorkflowStepTile(
                  index: entry.key + 1,
                  step: entry.value,
                ),
              );
              if (entry.key != _steps.length - 1) {
                yield const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: ReportStyles.textMuted,
                  ),
                );
              }
            }).toList(),
          );
        },
      ),
    );
  }
}

class _WorkflowStepTile extends StatelessWidget {
  const _WorkflowStepTile({required this.index, required this.step});

  final int index;
  final _WorkflowStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: step.isActive
            ? ReportStyles.surfaceBackground
            : ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: step.isActive
              ? step.color.withValues(alpha: 0.8)
              : ReportStyles.border.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(step.icon, color: step.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$index  ${step.title}',
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStep {
  const _WorkflowStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isActive;
}
