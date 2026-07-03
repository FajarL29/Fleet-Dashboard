import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/vehicle_management.dart';
import '../models/vehicle_status.dart';
import '../services/vehicle_management_service.dart';
import '../services/vehicle_status_service.dart';
import '../theme/app_theme.dart';
import '../widgets/report/report_styles.dart';
import '../widgets/vehicles/vehicles_screen_skeleton.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final VehicleManagementService _vehicleService =
      const VehicleManagementService();
  final VehicleStatusService _vehicleStatusService =
      const VehicleStatusService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isDialogSaving = false;
  bool _isExporting = false;
  String? _loadError;
  String? _statusWarning;
  VehicleRegistryData? _registryData;
  List<ManagedVehicle> _vehicles = const [];
  String _statusFilter = 'All Status';
  String _typeFilter = 'All Types';
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleFiltersChanged);
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkNavy,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _vehicles.isEmpty && _registryData == null) {
      return const VehiclesScreenSkeleton();
    }

    if (_loadError != null && _vehicles.isEmpty && _registryData == null) {
      return _buildErrorState();
    }

    final filteredVehicles = _filteredVehicles;
    final selectedVehicle = _selectedVehicle;
    final summary = _registryData?.summary;
    final offlineVehicles = _vehicles
        .where(
          (vehicle) => vehicle.mergedStatusLabel.toLowerCase() == 'offline',
        )
        .length;
    final devicesLinked = _vehicles
        .where((vehicle) => vehicle.isActive && vehicle.hasLinkedDevice)
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 1120;
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            _buildKpiRow(
              totalVehicles: summary?.totalVehicles ?? _vehicles.length,
              activeVehicles:
                  summary?.activeVehicles ??
                  _vehicles.where((vehicle) => vehicle.isActive).length,
              offlineVehicles: offlineVehicles,
              devicesLinked: devicesLinked,
            ),
            const SizedBox(height: 18),
            Expanded(
              child: stacked
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildVehicleListCard(filteredVehicles, height: 460),
                          const SizedBox(height: 16),
                          _buildRightColumn(selectedVehicle),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, bodyConstraints) {
                        final paneHeight = bodyConstraints.maxHeight;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 55,
                              child: _buildVehicleListCard(
                                filteredVehicles,
                                height: paneHeight,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 45,
                              child: _buildRightColumn(
                                selectedVehicle,
                                height: paneHeight,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        );

        if (!_isLoading) {
          return content;
        }

        return Stack(
          children: [
            AbsorbPointer(
              absorbing: true,
              child: AnimatedOpacity(
                opacity: 0.62,
                duration: const Duration(milliseconds: 180),
                child: content,
              ),
            ),
            const IgnorePointer(child: VehiclesScreenSkeleton(overlay: true)),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vehicle Management',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Monitor fleet units, vehicle identity, device status, and trip history.',
                style: TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ActionButton(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              onPressed: _isLoading ? null : _loadVehicles,
            ),
            _ActionButton(
              icon: Icons.file_download_outlined,
              label: _isExporting ? 'Exporting...' : 'Export CSV',
              onPressed: _isExporting ? null : _exportCsv,
            ),
            _PrimaryActionButton(
              icon: Icons.add_rounded,
              label: 'Add Vehicle',
              onPressed: () => _showVehicleDialog(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiRow({
    required int totalVehicles,
    required int activeVehicles,
    required int offlineVehicles,
    required int devicesLinked,
  }) {
    final cards = [
      _VehicleKpiData(
        title: 'Total Vehicles',
        value: '$totalVehicles',
        subtitle: 'Fleet registry',
        icon: Icons.local_shipping_outlined,
        color: ReportStyles.blue,
      ),
      _VehicleKpiData(
        title: 'Active Vehicles',
        value: '$activeVehicles',
        subtitle: 'Currently active',
        icon: Icons.wifi_tethering_rounded,
        color: ReportStyles.green,
      ),
      _VehicleKpiData(
        title: 'Offline Vehicles',
        value: '$offlineVehicles',
        subtitle: 'Need telemetry check',
        icon: Icons.portable_wifi_off_rounded,
        color: ReportStyles.orange,
      ),
      _VehicleKpiData(
        title: 'Devices Linked',
        value: '$devicesLinked',
        subtitle: 'Active units with device',
        icon: Icons.memory_rounded,
        color: ReportStyles.purple,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((item) => _VehicleKpiCard(data: item)).toList(),
    );
  }

  Widget _buildVehicleListCard(
    List<ManagedVehicle> vehicles, {
    double? height,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vehicle List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${vehicles.length} of ${_vehicles.length} vehicles',
                style: const TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFilterRow(),
          if (_statusWarning != null) ...[
            const SizedBox(height: 12),
            _InlineInfoBanner(
              message: _statusWarning!,
              color: ReportStyles.orange,
              icon: Icons.info_outline,
            ),
          ],
          if (_loadError != null) ...[
            const SizedBox(height: 12),
            _InlineInfoBanner(
              message: _loadError!,
              color: ReportStyles.red,
              icon: Icons.error_outline,
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: vehicles.isEmpty
                ? _buildEmptyListState()
                : ListView.separated(
                    itemCount: vehicles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _buildVehicleListRow(vehicles[index]),
                  ),
          ),
        ],
      ),
    );

    if (height != null) {
      return SizedBox(height: height, child: card);
    }
    return card;
  }

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: _SearchField(controller: _searchController),
        ),
        SizedBox(
          width: 160,
          child: _FilterDropdown(
            value: _statusFilter,
            items: _statusOptions,
            onChanged: (value) => setState(() => _statusFilter = value),
          ),
        ),
        SizedBox(
          width: 160,
          child: _FilterDropdown(
            value: _typeFilter,
            items: _typeOptions,
            onChanged: (value) => setState(() => _typeFilter = value),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleListRow(ManagedVehicle vehicle) {
    final isSelected = vehicle.vehicleId == _selectedVehicleId;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectVehicle(vehicle),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.05)
                : ReportStyles.surfaceBackground.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? ReportStyles.blue.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(vehicle).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _vehicleIcon(vehicle.vehicleType),
                  color: _statusColor(vehicle),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber.isEmpty ? '-' : vehicle.plateNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.vin.isEmpty ? 'VIN unavailable' : vehicle.vin,
                      style: const TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicle.vehicleType.isEmpty
                          ? 'Unknown type'
                          : vehicle.vehicleType,
                      style: const TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 100, maxWidth: 140),
                child: _StatusChip(vehicle: vehicle),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 90,
                child: Text(
                  _lastSeenLabel(vehicle),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightColumn(ManagedVehicle? vehicle, {double? height}) {
    final rightColumn = LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = height ?? constraints.maxHeight;
        final detailHeight = maxHeight.isFinite ? maxHeight * 0.62 : null;
        final tripHeight = maxHeight.isFinite ? maxHeight * 0.38 - 16 : null;

        return Column(
          children: [
            _buildSelectedVehicleDetailCard(vehicle, height: detailHeight),
            const SizedBox(height: 16),
            if (tripHeight != null && tripHeight > 0)
              SizedBox(
                height: tripHeight,
                child: _buildTripHistoryCard(vehicle),
              )
            else
              Expanded(child: _buildTripHistoryCard(vehicle)),
          ],
        );
      },
    );

    if (height != null) {
      return SizedBox(height: height, child: rightColumn);
    }
    return rightColumn;
  }

  Widget _buildSelectedVehicleDetailCard(
    ManagedVehicle? vehicle, {
    double? height,
  }) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: vehicle == null
          ? const _SectionEmptyState(
              title: 'No vehicle selected',
              subtitle:
                  'Choose a vehicle from the list to inspect live status and details.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Vehicle Detail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailHero(vehicle),
                        const SizedBox(height: 18),
                        _buildDetailGrid(vehicle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );

    if (height != null) {
      return SizedBox(height: height, child: card);
    }
    return card;
  }

  Widget _buildDetailGrid(ManagedVehicle vehicle) {
    final coreDetails = [
      _VehicleDetailItem(label: 'VIN', value: vehicle.vinOrPlaceholder),
      _VehicleDetailItem(
        label: 'Vehicle Type',
        value: vehicle.vehicleTypeOrPlaceholder,
      ),
      _VehicleDetailItem(
        label: 'Assigned Driver',
        value: vehicle.assignedDriverLabel,
      ),
      _VehicleDetailItem(
        label: 'Device Status',
        value: vehicle.deviceStatusLabel,
      ),
      _VehicleDetailItem(
        label: 'Movement Status',
        value: vehicle.movementStatusLabel,
      ),
      _VehicleDetailItem(label: 'Last Seen', value: _lastSeenLabel(vehicle)),
      _VehicleDetailItem(label: 'Speed', value: vehicle.speedLabel),
      _VehicleDetailItem(label: 'Location', value: vehicle.locationLabel),
    ];
    final optionalDetails = [
      _VehicleDetailItem(
        label: 'Device ID',
        value: vehicle.deviceIdOrPlaceholder,
      ),
      _VehicleDetailItem(label: 'IMEI', value: vehicle.imeiOrPlaceholder),
      _VehicleDetailItem(label: 'Notes', value: vehicle.notesOrPlaceholder),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailWrap(coreDetails),
        const SizedBox(height: 14),
        Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: ReportStyles.surfaceBackground.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 2,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              title: const Text(
                'Optional Device & Notes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Device ID, IMEI, and notes',
                style: TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 12,
                ),
              ),
              children: [_buildDetailWrap(optionalDetails)],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailHero(ManagedVehicle vehicle) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 620;

        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _statusColor(vehicle).withValues(alpha: 0.28),
                    ReportStyles.surfaceBackgroundSoft,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _statusColor(vehicle).withValues(alpha: 0.35),
                ),
              ),
              child: Icon(
                _vehicleIcon(vehicle.vehicleType),
                color: Colors.white,
                size: 52,
              ),
            ),
            SizedBox(width: stacked ? 0 : 18, height: stacked ? 18 : 0),
            if (stacked)
              _buildDetailHeroMeta(vehicle)
            else
              Expanded(child: _buildDetailHeroMeta(vehicle)),
          ],
        );
      },
    );
  }

  Widget _buildDetailHeroMeta(ManagedVehicle vehicle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          vehicle.plateNumber.isEmpty ? '-' : vehicle.plateNumber,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StatusChip(vehicle: vehicle),
            _MiniInfoPill(
              icon: Icons.access_time_rounded,
              label: _lastSeenLabel(vehicle),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionButton(
              icon: Icons.edit_outlined,
              label: 'Edit Vehicle',
              onPressed: () => _showVehicleDialog(vehicle: vehicle),
            ),
            _ActionButton(
              icon: Icons.person_add_alt_1_outlined,
              label: 'Assign Driver',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Driver assignment is not wired into this screen yet.',
                    ),
                  ),
                );
              },
            ),
            _ActionButton(
              icon: Icons.block_outlined,
              label: 'Deactivate',
              color: ReportStyles.red,
              onPressed: vehicle.isActive
                  ? () => _confirmDeactivate(vehicle)
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailWrap(List<_VehicleDetailItem> details) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 750 ? 2 : 1;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 14) / 2;

        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: details.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _DetailTile(item: item),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTripHistoryCard(ManagedVehicle? vehicle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 170;
                final emptyState = vehicle == null
                    ? _SectionEmptyState(
                        title: 'No vehicle selected',
                        subtitle: 'Select a vehicle to view trip history.',
                        compact: compact,
                      )
                    : _SectionEmptyState(
                        title: 'No trip history available for this vehicle.',
                        subtitle:
                            'Trip history is not available from the current backend data.',
                        compact: compact,
                      );

                return compact
                    ? SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: emptyState,
                        ),
                      )
                    : emptyState;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyListState() {
    final isFiltering =
        _searchController.text.trim().isNotEmpty ||
        _statusFilter != 'All Status' ||
        _typeFilter != 'All Types';

    return _SectionEmptyState(
      title: isFiltering ? 'No matching vehicles' : 'No vehicles found',
      subtitle: isFiltering
          ? 'Adjust the current search or filters to show more fleet units.'
          : 'Register a vehicle to start monitoring it here.',
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        decoration: _cardDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: ReportStyles.red),
            const SizedBox(height: 12),
            const Text(
              'Vehicle page unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Failed to load vehicles.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            _PrimaryActionButton(
              icon: Icons.refresh_rounded,
              label: 'Retry',
              onPressed: _loadVehicles,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
      _statusWarning = null;
    });

    try {
      final registryData = await _vehicleService.getVehicles();
      VehicleStatusData? vehicleStatusData;
      String? statusWarning;

      try {
        vehicleStatusData = await _vehicleStatusService.getVehicleStatus();
      } catch (_) {
        statusWarning =
            'Live device status is temporarily unavailable. Showing registry data only.';
      }

      final mergedVehicles = _mergeVehicles(
        registryData.vehicles,
        vehicleStatusData?.vehicles ?? const <VehicleStatusItem>[],
      );

      setState(() {
        _registryData = registryData;
        _vehicles = mergedVehicles;
        _statusWarning = statusWarning;
        _selectedVehicleId = _resolveSelectedVehicleId(mergedVehicles);
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _loadError = 'Failed to load vehicles. $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _showVehicleDialog({ManagedVehicle? vehicle}) async {
    final isEditing = vehicle != null;
    final formKey = GlobalKey<FormState>();
    final plateController = TextEditingController(
      text: vehicle?.plateNumber ?? '',
    );
    final vinController = TextEditingController(text: vehicle?.vin ?? '');
    final driverIdController = TextEditingController(
      text: vehicle?.driverId ?? '',
    );
    final deviceIdController = TextEditingController(
      text: vehicle?.deviceId ?? '',
    );
    final imeiController = TextEditingController(text: vehicle?.imei ?? '');
    final notesController = TextEditingController(text: vehicle?.notes ?? '');
    var selectedType = vehicle?.vehicleType.trim().isEmpty ?? true
        ? null
        : vehicle!.vehicleType;

    await showDialog<void>(
      context: context,
      barrierDismissible: !_isDialogSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) {
                return;
              }

              setDialogState(() {
                _isDialogSaving = true;
              });

              final draftRegistry = _buildDraftRegistryItem(
                vehicleId: vehicle?.vehicleId,
                plateNumber: plateController.text.trim(),
                vin: vinController.text.trim(),
                vehicleType: selectedType?.trim() ?? '',
                driverId: driverIdController.text.trim(),
                deviceId: deviceIdController.text.trim(),
                imei: imeiController.text.trim(),
                notes: notesController.text.trim(),
                preserveCreatedAt: vehicle?.registry.createdDt,
                previousRegistry: vehicle?.registry,
                isActive: vehicle?.isActive ?? true,
              );

              try {
                if (isEditing) {
                  await _vehicleService.updateVehicle(
                    vehicleId: draftRegistry.vehicleId,
                    plateNumber: draftRegistry.plateNumber,
                    vin: draftRegistry.vehicleIdentificationNumber,
                    vehicleType: draftRegistry.vehicleType,
                    driverId: draftRegistry.driverId,
                    deviceId: draftRegistry.deviceId,
                    imei: draftRegistry.imei,
                    notes: draftRegistry.notes,
                  );
                } else {
                  await _vehicleService.createVehicle(
                    plateNumber: draftRegistry.plateNumber,
                    vin: draftRegistry.vehicleIdentificationNumber,
                    vehicleType: draftRegistry.vehicleType,
                    driverId: draftRegistry.driverId,
                    deviceId: draftRegistry.deviceId,
                    imei: draftRegistry.imei,
                    notes: draftRegistry.notes,
                  );
                }

                if (!mounted) {
                  return;
                }

                if (isEditing) {
                  _applyUpdatedVehicle(draftRegistry);
                } else {
                  _applyCreatedVehicle(draftRegistry);
                }

                Navigator.of(this.context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'Vehicle updated successfully'
                          : 'Vehicle created successfully',
                    ),
                  ),
                );
                _loadVehicles();
              } catch (error) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  this.context,
                ).showSnackBar(SnackBar(content: Text('Save failed: $error')));
              } finally {
                if (mounted) {
                  setDialogState(() {
                    _isDialogSaving = false;
                  });
                }
              }
            }

            return AlertDialog(
              backgroundColor: ReportStyles.surfaceBackground,
              title: Text(
                isEditing ? 'Edit Vehicle' : 'Add Vehicle',
                style: const TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: 460,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DialogField(
                          label: 'Plate Number',
                          required: true,
                          child: TextFormField(
                            controller: plateController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('e.g. B 1234 KZX'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Plate number is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        _DialogField(
                          label: 'VIN (Chassis Number)',
                          required: true,
                          child: TextFormField(
                            controller: vinController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'e.g. MHFG8JJ1XK1234567',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'VIN is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        _DialogField(
                          label: 'Vehicle Type',
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedType,
                            decoration: _inputDecoration('Select vehicle type'),
                            dropdownColor: ReportStyles.surfaceBackground,
                            style: const TextStyle(color: Colors.white),
                            items: _vehicleTypeOptions
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedType = value;
                              });
                            },
                          ),
                        ),
                        _DialogField(
                          label: 'Driver ID',
                          child: TextFormField(
                            controller: driverIdController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('Optional driver ID'),
                          ),
                        ),
                        _DialogField(
                          label: 'Device ID',
                          child: TextFormField(
                            controller: deviceIdController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration('e.g. FS-DEVICE-0001'),
                          ),
                        ),
                        _DialogField(
                          label: 'SIM / IMEI',
                          child: TextFormField(
                            controller: imeiController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                              'e.g. 8962012345678901234',
                            ),
                          ),
                        ),
                        _DialogField(
                          label: 'Notes',
                          child: TextFormField(
                            controller: notesController,
                            maxLines: 4,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
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
                  onPressed: _isDialogSaving
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: _isDialogSaving ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ReportStyles.blue,
                  ),
                  child: Text(
                    _isDialogSaving
                        ? 'Saving...'
                        : isEditing
                        ? 'Save Changes'
                        : 'Save Vehicle',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeactivate(ManagedVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ReportStyles.surfaceBackground,
        title: const Text(
          'Deactivate Vehicle',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Deactivate ${vehicle.plateNumber}? This keeps the registry record but removes it from active use.',
          style: const TextStyle(color: ReportStyles.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ReportStyles.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _vehicleService.deactivateVehicle(vehicle.vehicleId);
      if (!mounted) return;
      _applyDeactivatedVehicle(vehicle);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle deactivated successfully')),
      );
      _loadVehicles();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Deactivate failed: $error')));
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final path = await _vehicleService.exportVehiclesCsv(
        _filteredVehicles,
        searchQuery: _searchController.text.trim(),
        statusFilter: _statusFilter == 'All Status' ? null : _statusFilter,
        typeFilter: _typeFilter == 'All Types' ? null : _typeFilter,
      );
      if (!mounted) return;
      final savedToDownloads =
          path.contains(r'\Downloads\') || path.contains('/Downloads/');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedToDownloads
                ? 'Export successful. Saved to Downloads'
                : 'Export successful. Saved to $path',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV export failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _handleFiltersChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectVehicle(ManagedVehicle vehicle) {
    setState(() {
      _selectedVehicleId = vehicle.vehicleId;
    });
  }

  VehicleRegistryItem _buildDraftRegistryItem({
    String? vehicleId,
    required String plateNumber,
    required String vin,
    required String vehicleType,
    required String driverId,
    required String deviceId,
    required String imei,
    required String notes,
    DateTime? preserveCreatedAt,
    VehicleRegistryItem? previousRegistry,
    bool isActive = true,
  }) {
    final now = DateTime.now();
    return VehicleRegistryItem(
      vehicleId: vehicleId ?? 'temp-${DateTime.now().microsecondsSinceEpoch}',
      vehicleIdentificationNumber: vin,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      driverId: driverId,
      driverName:
          previousRegistry != null && previousRegistry.driverId == driverId
          ? previousRegistry.driverName
          : '',
      deviceId: deviceId,
      imei: imei,
      isActive: isActive,
      notes: notes,
      createdDt: preserveCreatedAt ?? now,
      updatedDt: now,
    );
  }

  void _applyCreatedVehicle(VehicleRegistryItem registry) {
    final created = ManagedVehicle(registry: registry);
    final updatedVehicles = [created, ..._vehicles];
    setState(() {
      _vehicles = updatedVehicles;
      _registryData = _registryData?.copyWith(
        summary: _updatedSummaryFromVehicles(updatedVehicles),
        vehicles: [registry, ...?_registryData?.vehicles],
      );
      _selectedVehicleId = created.vehicleId;
    });
  }

  void _applyUpdatedVehicle(VehicleRegistryItem registry) {
    final updatedVehicles = _vehicles.map((vehicle) {
      if (vehicle.vehicleId != registry.vehicleId) {
        return vehicle;
      }
      return vehicle.copyWith(registry: registry);
    }).toList();

    final updatedRegistryVehicles = (_registryData?.vehicles ?? const [])
        .map(
          (vehicle) =>
              vehicle.vehicleId == registry.vehicleId ? registry : vehicle,
        )
        .toList();

    setState(() {
      _vehicles = updatedVehicles;
      _registryData = _registryData?.copyWith(
        summary: _updatedSummaryFromVehicles(updatedVehicles),
        vehicles: updatedRegistryVehicles,
      );
      _selectedVehicleId = registry.vehicleId;
    });
  }

  void _applyDeactivatedVehicle(ManagedVehicle vehicle) {
    final updatedRegistry = vehicle.registry.copyWith(
      isActive: false,
      updatedDt: DateTime.now(),
    );
    final updatedVehicles = _vehicles.map((item) {
      if (item.vehicleId != vehicle.vehicleId) {
        return item;
      }
      return item.copyWith(registry: updatedRegistry);
    }).toList();

    final updatedRegistryVehicles = (_registryData?.vehicles ?? const [])
        .map(
          (item) =>
              item.vehicleId == vehicle.vehicleId ? updatedRegistry : item,
        )
        .toList();

    setState(() {
      _vehicles = updatedVehicles;
      _registryData = _registryData?.copyWith(
        summary: _updatedSummaryFromVehicles(updatedVehicles),
        vehicles: updatedRegistryVehicles,
      );
      _selectedVehicleId = vehicle.vehicleId;
    });
  }

  VehicleRegistrySummary _updatedSummaryFromVehicles(
    List<ManagedVehicle> vehicles,
  ) {
    final total = vehicles.length;
    final active = vehicles.where((vehicle) => vehicle.isActive).length;
    return VehicleRegistrySummary(
      totalVehicles: total,
      activeVehicles: active,
      inactiveVehicles: total - active,
    );
  }

  List<ManagedVehicle> _mergeVehicles(
    List<VehicleRegistryItem> registryItems,
    List<VehicleStatusItem> statusItems,
  ) {
    final statusByKey = _buildStatusKeyMap(statusItems);

    return registryItems.map((registry) {
      final status =
          statusByKey[registry.vehicleId] ??
          statusByKey[registry.vehicleIdentificationNumber];
      return ManagedVehicle(registry: registry, status: status);
    }).toList();
  }

  Map<String, VehicleStatusItem> _buildStatusKeyMap(
    List<VehicleStatusItem> items,
  ) {
    final map = <String, VehicleStatusItem>{};

    for (final item in items) {
      if (item.vehicleId.trim().isNotEmpty) {
        map[item.vehicleId.trim()] = item;
      }
      if (item.vehicleIdentificationNumber.trim().isNotEmpty) {
        map[item.vehicleIdentificationNumber.trim()] = item;
      }
    }

    return map;
  }

  List<ManagedVehicle> get _filteredVehicles {
    final query = _searchController.text.trim().toLowerCase();
    return _vehicles.where((vehicle) {
      if (query.isNotEmpty &&
          ![
            vehicle.plateNumber,
            vehicle.vin,
            vehicle.deviceId,
            vehicle.vehicleType,
          ].join(' ').toLowerCase().contains(query)) {
        return false;
      }

      if (_statusFilter != 'All Status' &&
          vehicle.mergedStatusLabel.toLowerCase() !=
              _statusFilter.toLowerCase()) {
        return false;
      }

      if (_typeFilter != 'All Types' && vehicle.vehicleType != _typeFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  ManagedVehicle? get _selectedVehicle {
    for (final vehicle in _vehicles) {
      if (vehicle.vehicleId == _selectedVehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  List<String> get _statusOptions => const [
    'All Status',
    'Active',
    'Inactive',
    'Moving',
    'Idle',
    'Online',
    'Offline',
    'Warning',
    'Alert',
    'Unknown',
  ];

  List<String> get _typeOptions {
    final values = <String>{'All Types'};
    for (final vehicle in _vehicles) {
      if (vehicle.vehicleType.trim().isNotEmpty) {
        values.add(vehicle.vehicleType);
      }
    }
    return values.toList();
  }

  List<String> get _vehicleTypeOptions {
    final values = <String>{'Truck', 'Van', 'Bus', 'Pickup', 'SUV', 'Sedan'};
    for (final vehicle in _vehicles) {
      if (vehicle.vehicleType.trim().isNotEmpty) {
        values.add(vehicle.vehicleType);
      }
    }
    return values.toList();
  }

  String? _resolveSelectedVehicleId(List<ManagedVehicle> vehicles) {
    if (vehicles.isEmpty) {
      return null;
    }

    for (final vehicle in vehicles) {
      if (vehicle.vehicleId == _selectedVehicleId) {
        return _selectedVehicleId;
      }
    }

    return vehicles.first.vehicleId;
  }

  String _lastSeenLabel(ManagedVehicle vehicle) {
    if (vehicle.lastSeenMinutes != null) {
      final minutes = vehicle.lastSeenMinutes!;
      if (minutes < 60) return '$minutes min ago';
      if (minutes < 1440) return '${(minutes / 60).floor()} hr ago';
      return '${(minutes / 1440).floor()} day ago';
    }

    if (vehicle.lastUpdatedAt != null) {
      return DateFormat(
        'MMM d, HH:mm',
      ).format(vehicle.lastUpdatedAt!.toLocal());
    }

    return 'Unavailable';
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: ReportStyles.textFaint, fontSize: 13),
      filled: true,
      fillColor: const Color(0xFF0F1926),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ReportStyles.blue),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: ReportStyles.cardBackground,
      gradient: ReportStyles.cardGradient,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: ReportStyles.border.withValues(alpha: 0.82)),
      boxShadow: ReportStyles.cardShadow,
    );
  }

  Color _statusColor(ManagedVehicle vehicle) {
    switch (vehicle.mergedStatusLabel.toLowerCase()) {
      case 'alert':
      case 'inactive':
        return ReportStyles.red;
      case 'warning':
      case 'offline':
        return ReportStyles.orange;
      case 'idle':
        return ReportStyles.blue;
      case 'moving':
      case 'online':
      case 'active':
        return ReportStyles.green;
      default:
        return ReportStyles.textMuted;
    }
  }

  IconData _vehicleIcon(String vehicleType) {
    final normalized = vehicleType.toLowerCase();
    if (normalized.contains('bus')) return Icons.directions_bus_rounded;
    if (normalized.contains('van')) return Icons.airport_shuttle_rounded;
    if (normalized.contains('pickup')) return Icons.fire_truck_rounded;
    if (normalized.contains('suv') || normalized.contains('sedan')) {
      return Icons.directions_car_filled_rounded;
    }
    return Icons.local_shipping_rounded;
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Search by plate, VIN, or device',
        hintStyle: const TextStyle(color: ReportStyles.textFaint, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: ReportStyles.textSecondary),
        filled: true,
        fillColor: const Color(0xFF0F1926),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReportStyles.blue),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : items.first,
      dropdownColor: ReportStyles.surfaceBackground,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFF0F1926),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      iconEnabledColor: Colors.white,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _VehicleKpiData {
  const _VehicleKpiData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _VehicleKpiCard extends StatelessWidget {
  const _VehicleKpiCard({required this.data});

  final _VehicleKpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.82)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: data.color.withValues(alpha: 0.45)),
            ),
            child: Icon(data.icon, color: data.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: TextStyle(color: data.color, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.vehicle});

  final ManagedVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(vehicle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              vehicle.mergedStatusLabel,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(ManagedVehicle vehicle) {
    switch (vehicle.mergedStatusLabel.toLowerCase()) {
      case 'alert':
      case 'inactive':
        return ReportStyles.red;
      case 'warning':
      case 'offline':
        return ReportStyles.orange;
      case 'idle':
        return ReportStyles.blue;
      case 'moving':
      case 'online':
      case 'active':
        return ReportStyles.green;
      default:
        return ReportStyles.textMuted;
    }
  }
}

class _MiniInfoPill extends StatelessWidget {
  const _MiniInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ReportStyles.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VehicleDetailItem {
  const _VehicleDetailItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.item});

  final _VehicleDetailItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = ReportStyles.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: onPressed == null
            ? ReportStyles.textMuted
            : Colors.white,
        side: BorderSide(
          color: onPressed == null
              ? Colors.white.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.45),
        ),
        backgroundColor: onPressed == null
            ? Colors.white.withValues(alpha: 0.02)
            : color.withValues(alpha: 0.06),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: ReportStyles.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              children: [
                TextSpan(text: label),
                if (required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: ReportStyles.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SectionEmptyState extends StatelessWidget {
  const _SectionEmptyState({
    required this.title,
    required this.subtitle,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 48.0 : 72.0;
    final glyphSize = compact ? 22.0 : 32.0;
    final titleSize = compact ? 13.0 : 14.0;
    final titleGap = compact ? 8.0 : 12.0;
    final subtitleGap = compact ? 4.0 : 6.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
              ),
              child: Icon(
                Icons.route_outlined,
                color: ReportStyles.textSecondary,
                size: glyphSize,
              ),
            ),
            SizedBox(height: titleGap),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: TextStyle(
                color: Colors.white,
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: subtitleGap),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : TextOverflow.visible,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineInfoBanner extends StatelessWidget {
  const _InlineInfoBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

extension on ManagedVehicle {
  String get vinOrPlaceholder => vin.trim().isEmpty ? '-' : vin;
  String get vehicleTypeOrPlaceholder =>
      vehicleType.trim().isEmpty ? '-' : vehicleType;
  String get deviceIdOrPlaceholder => deviceId.trim().isEmpty ? '-' : deviceId;
  String get imeiOrPlaceholder => imei.trim().isEmpty ? '-' : imei;
  String get notesOrPlaceholder => notes.trim().isEmpty ? '-' : notes;
  String get deviceStatusLabel => status?.deviceStatus.trim().isNotEmpty == true
      ? status!.deviceStatus
      : 'Unavailable';
  String get movementStatusLabel =>
      status?.movementStatus.trim().isNotEmpty == true
      ? status!.movementStatus
      : 'Unavailable';
  String get speedLabel {
    final speed = status?.speed;
    if (speed == null) return 'Unavailable';
    return '${speed.toStringAsFixed(1)} km/h';
  }

  String get locationLabel {
    final latitude = status?.latitude;
    final longitude = status?.longitude;
    if (latitude == null || longitude == null) return 'Unavailable';
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }
}
