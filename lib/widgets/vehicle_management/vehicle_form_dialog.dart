import 'package:flutter/material.dart';

import '../../models/vehicle_management.dart';
import '../../services/vehicle_management_service.dart';
import '../../theme/app_theme.dart';

/// Opens the add / edit vehicle form. Resolves to true when a vehicle was
/// saved, so the caller knows to refresh.
Future<bool> showVehicleFormDialog({
  required BuildContext context,
  required VehicleManagementService service,
  required List<String> typeOptions,
  ManagedVehicle? vehicle,
}) async {
  final saved = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _VehicleFormDialog(
      service: service,
      typeOptions: typeOptions,
      vehicle: vehicle,
    ),
  );
  return saved ?? false;
}

class _VehicleFormDialog extends StatefulWidget {
  const _VehicleFormDialog({
    required this.service,
    required this.typeOptions,
    required this.vehicle,
  });

  final VehicleManagementService service;
  final List<String> typeOptions;

  /// Null creates a new vehicle; otherwise the form edits this one.
  final ManagedVehicle? vehicle;

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _plate;
  late final TextEditingController _vin;
  late final TextEditingController _driverId;
  late final TextEditingController _deviceId;
  late final TextEditingController _imei;
  late final TextEditingController _notes;

  String? _type;
  bool _isSaving = false;

  bool get _isEditing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final vehicle = widget.vehicle;
    _plate = TextEditingController(text: vehicle?.plateNumber ?? '');
    _vin = TextEditingController(text: vehicle?.vin ?? '');
    _driverId = TextEditingController(text: vehicle?.driverId ?? '');
    _deviceId = TextEditingController(text: vehicle?.deviceId ?? '');
    _imei = TextEditingController(text: vehicle?.imei ?? '');
    _notes = TextEditingController(text: vehicle?.notes ?? '');

    final type = vehicle?.vehicleType.trim() ?? '';
    _type = type.isEmpty ? null : type;
  }

  @override
  void dispose() {
    for (final controller in [
      _plate,
      _vin,
      _driverId,
      _deviceId,
      _imei,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await widget.service.updateVehicle(
          vehicleId: widget.vehicle!.vehicleId,
          plateNumber: _plate.text.trim(),
          vin: _vin.text.trim(),
          vehicleType: _type?.trim() ?? '',
          driverId: _driverId.text.trim(),
          deviceId: _deviceId.text.trim(),
          imei: _imei.text.trim(),
          notes: _notes.text.trim(),
        );
      } else {
        await widget.service.createVehicle(
          plateNumber: _plate.text.trim(),
          vin: _vin.text.trim(),
          vehicleType: _type?.trim() ?? '',
          driverId: _driverId.text.trim(),
          deviceId: _deviceId.text.trim(),
          imei: _imei.text.trim(),
          notes: _notes.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        _isEditing ? 'Edit Vehicle' : 'Add Vehicle',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(
                  label: 'Plate Number',
                  required: true,
                  child: TextFormField(
                    controller: _plate,
                    style: _inputStyle,
                    decoration: _decoration('e.g. B 1234 KZX'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Plate number is required'
                        : null,
                  ),
                ),
                _Field(
                  label: 'VIN (Chassis Number)',
                  required: true,
                  child: TextFormField(
                    controller: _vin,
                    style: _inputStyle,
                    decoration: _decoration('e.g. MHFG8JJ1XK1234567'),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'VIN is required'
                        : null,
                  ),
                ),
                _Field(
                  label: 'Vehicle Type',
                  child: DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: _decoration('Select vehicle type'),
                    dropdownColor: AppColors.surface,
                    style: _inputStyle,
                    items: widget.typeOptions
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _type = value),
                  ),
                ),
                _Field(
                  label: 'Driver ID',
                  // This is the only place a driver gets attached to a
                  // vehicle, so it has to say what it feeds rather than
                  // reading as one more optional box.
                  hint:
                      'Links the driver to this vehicle. Their vital signs '
                      'and safety events are grouped by it.',
                  child: TextFormField(
                    controller: _driverId,
                    style: _inputStyle,
                    decoration: _decoration('e.g. 11'),
                  ),
                ),
                _Field(
                  label: 'Device ID',
                  child: TextFormField(
                    controller: _deviceId,
                    style: _inputStyle,
                    decoration: _decoration('e.g. FS-DEVICE-0001'),
                  ),
                ),
                _Field(
                  label: 'SIM / IMEI',
                  child: TextFormField(
                    controller: _imei,
                    style: _inputStyle,
                    decoration: _decoration('e.g. 8962012345678901234'),
                  ),
                ),
                _Field(
                  label: 'Notes',
                  child: TextFormField(
                    controller: _notes,
                    maxLines: 4,
                    style: _inputStyle,
                    decoration: _decoration(
                      'Add notes or additional information...',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            _isSaving
                ? 'Saving...'
                : _isEditing
                ? 'Save Changes'
                : 'Save Vehicle',
          ),
        ),
      ],
    );
  }

  static const TextStyle _inputStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13,
  );

  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );

    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: AppColors.tileBackground,
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      enabledBorder: border(AppColors.cardBorder),
      focusedBorder: border(AppColors.blue),
      border: border(AppColors.cardBorder),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.required = false,
    this.hint,
  });

  final String label;
  final Widget child;
  final bool required;

  /// Small note under the field, for anything the label alone cannot say.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.red),
                  ),
              ],
            ),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          child,
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
