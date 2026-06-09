import 'package:flutter/material.dart';

import '../report/report_styles.dart';

class SafetyFilterBar extends StatelessWidget {
  const SafetyFilterBar({
    super.key,
    required this.dateRangeLabel,
    required this.severityFilter,
    required this.eventTypeFilter,
    required this.searchQuery,
    required this.eventCount,
    required this.vehicleOptions,
    required this.selectedVehicleVin,
    required this.selectedVehicleLabel,
    required this.onDateRangeTap,
    required this.onRefresh,
    required this.onVehicleChanged,
    required this.onSeverityChanged,
    required this.onEventTypeChanged,
    required this.onSearchChanged,
    this.isLoading = false,
    this.isVehicleLoading = false,
    this.emptyVehicleLabel = 'No registered vehicles available.',
  });

  final String dateRangeLabel;
  final String severityFilter;
  final String eventTypeFilter;
  final String searchQuery;
  final int eventCount;
  final List<SafetyVehicleOption> vehicleOptions;
  final String? selectedVehicleVin;
  final String selectedVehicleLabel;
  final VoidCallback onDateRangeTap;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onVehicleChanged;
  final ValueChanged<String> onSeverityChanged;
  final ValueChanged<String> onEventTypeChanged;
  final ValueChanged<String> onSearchChanged;
  final bool isLoading;
  final bool isVehicleLoading;
  final String emptyVehicleLabel;

  static const List<String> severityOptions = ['All', 'High', 'Medium', 'Low'];

  static const List<String> eventTypeOptions = [
    'All',
    'Drowsy',
    'Yawn',
    'Distraction',
    'Drowsiness Episode',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withOpacity(0.65)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _ActionChip(
            icon: Icons.calendar_month_rounded,
            label: dateRangeLabel,
            onTap: onDateRangeTap,
          ),
          _LabeledDropdown(
            label: 'Severity',
            value: severityFilter,
            options: severityOptions,
            onChanged: onSeverityChanged,
          ),
          _LabeledDropdown(
            label: 'Event Type',
            value: eventTypeFilter,
            options: eventTypeOptions,
            onChanged: onEventTypeChanged,
          ),
          SizedBox(
            width: 280,
            child: _SearchField(value: searchQuery, onChanged: onSearchChanged),
          ),
          _VehicleDropdown(
            options: vehicleOptions,
            value: selectedVehicleVin,
            selectedLabel: selectedVehicleLabel,
            emptyLabel: emptyVehicleLabel,
            isLoading: isVehicleLoading,
            onChanged: onVehicleChanged,
          ),
          _CountBadge(label: isLoading ? 'Loading...' : '$eventCount events'),
          _IconActionButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Refresh',
            onTap: onRefresh,
          ),
        ],
      ),
    );
  }
}

class SafetyVehicleOption {
  const SafetyVehicleOption({required this.vin, required this.label});

  final String vin;
  final String label;
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: ReportStyles.surfaceBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ReportStyles.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: ReportStyles.textSecondary, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: ReportStyles.surfaceBackground,
          borderRadius: BorderRadius.circular(12),
          iconEnabledColor: ReportStyles.textSecondary,
          style: const TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(option),
                ],
              ),
            );
          }).toList(),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey(value),
      initialValue: value,
      onChanged: onChanged,
      style: const TextStyle(color: ReportStyles.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search vehicle, user, or status',
        hintStyle: const TextStyle(color: ReportStyles.textMuted),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ReportStyles.textSecondary,
          size: 20,
        ),
        filled: true,
        fillColor: ReportStyles.surfaceBackground,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReportStyles.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReportStyles.blue),
        ),
      ),
    );
  }
}

class _VehicleDropdown extends StatelessWidget {
  const _VehicleDropdown({
    required this.options,
    required this.value,
    required this.selectedLabel,
    required this.emptyLabel,
    required this.isLoading,
    required this.onChanged,
  });

  final List<SafetyVehicleOption> options;
  final String? value;
  final String selectedLabel;
  final String emptyLabel;
  final bool isLoading;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF162033),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.any((option) => option.vin == value) ? value : null,
          isExpanded: true,
          hint: Row(
            children: [
              const Icon(Icons.local_shipping_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLoading ? 'Loading vehicles...' : emptyLabel,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          dropdownColor: ReportStyles.surfaceBackground,
          borderRadius: BorderRadius.circular(12),
          iconEnabledColor: ReportStyles.textSecondary,
          style: const TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          selectedItemBuilder: (context) {
            return options.map((option) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ReportStyles.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList();
          },
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option.vin,
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: isLoading || options.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFF111C31),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: ReportStyles.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ReportStyles.surfaceBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReportStyles.border),
          ),
          child: Icon(icon, color: ReportStyles.textPrimary),
        ),
      ),
    );
  }
}
