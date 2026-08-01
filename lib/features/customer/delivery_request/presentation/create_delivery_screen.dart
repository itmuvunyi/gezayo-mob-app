import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/simulated_map_widget.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../rider/domain/transaction_model.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../presentation/delivery_notifier.dart';


class CreateDeliveryScreen extends ConsumerStatefulWidget {
  final String? initialPackageType;

  const CreateDeliveryScreen({super.key, this.initialPackageType});

  @override
  ConsumerState<CreateDeliveryScreen> createState() =>
      _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends ConsumerState<CreateDeliveryScreen> {
  final _pickupController = TextEditingController(text: '');
  final _dropoffController = TextEditingController(text: '');
  final _instructionsController = TextEditingController();
  final _fareController = TextEditingController(text: '');

  String _selectedPackageType = 'Parcel';
  String _selectedWeightClass = 'Light (<5kg)';

  @override
  void initState() {
    super.initState();
    if (widget.initialPackageType != null &&
        widget.initialPackageType!.isNotEmpty) {
      final raw = widget.initialPackageType!;
      _selectedPackageType =
          raw[0].toUpperCase() + raw.substring(1).toLowerCase();
    }
  }

  Future<String> _reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json');
      final response = await http.get(uri, headers: {
        'User-Agent': 'GezaYoApp/1.0'
      }).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final parts = displayName.split(',');
          if (parts.length >= 3) {
            return '${parts[0].trim()}, ${parts[1].trim()}, ${parts[2].trim()}';
          }
          return displayName;
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Location services are disabled on this device.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied.')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Location permissions are permanently denied.')),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final address = await _reverseGeocode(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _pickupController.text = address;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('GPS Location detected: $address'),
            backgroundColor: AppColors.statusSuccess,
          ),
        );
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching GPS location: $e')),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    final authState = ref.read(authNotifierProvider);
    final customerUid = authState.user?.uid ?? 'usr-customer-101';
    final customerPhone = authState.user?.phoneNumber ?? '';
    final offerFare = double.tryParse(_fareController.text.trim()) ?? 2500.0;

    if (_pickupController.text.trim().isEmpty ||
        _dropoffController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter pickup and drop-off addresses.')),
      );
      return;
    }

    final notifier = ref.read(deliveryNotifierProvider.notifier);
    await notifier.createDeliveryRequest(
      pickupAddress: _pickupController.text.trim(),
      dropoffAddress: _dropoffController.text.trim(),
      packageType: _selectedPackageType,
      weightClass: _selectedWeightClass,
      instructions: _instructionsController.text.trim(),
      estimatedFare: offerFare,
      customerUid: customerUid,
      customerPhone: customerPhone,
    );

    ref.read(notificationNotifierProvider.notifier).notifyNewDelivery(
          packageType: _selectedPackageType,
          pickupAddress: _pickupController.text.trim(),
        );

    if (mounted) {
      context.push('/rider-matching');
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('New Delivery',
            style: AppTypography.headlineMedium(
                color: theme.colorScheme.onSurface)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryMint,
              child: Icon(Icons.person, size: 20, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map Preview Card
                  SizedBox(
                    height: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: const SimulatedMapWidget(
                        showRoute: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Customer Wallet Balance & Deposit Card
                  Builder(
                    builder: (context) {
                      final authState = ref.watch(authNotifierProvider);
                      final firestoreService = ref.watch(firestoreServiceProvider);
                      final uid = authState.user?.uid ?? '';

                      return StreamBuilder<List<TransactionModel>>(
                        stream: uid.isNotEmpty
                            ? firestoreService.getTransactionsStream(uid)
                            : Stream.value([]),
                        builder: (context, txSnap) {
                          double customerBalance = 0.0;
                          final txs = txSnap.data ?? [];
                          for (final tx in txs) {
                            if (tx.isPositive) {
                              customerBalance += tx.amountRwf;
                            } else {
                              customerBalance -= tx.amountRwf;
                            }
                          }
                          if (customerBalance < 0) customerBalance = 0.0;

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF046A38), Color(0xFF10B981)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x29046A38),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AVAILABLE WALLET BALANCE',
                                        style: AppTypography.labelMedium(
                                            color: Colors.white70),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'RWF ${customerBalance.toStringAsFixed(0)}',
                                        style: AppTypography.headlineLarge(
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () => context.push('/deposit'),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.add_circle_outline,
                                            color: AppColors.primary, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Deposit',
                                          style: AppTypography.labelLarge(
                                              color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),


                  // Locations Input Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        // Pickup Location Row
                        Row(
                          children: [
                            const Icon(Icons.radio_button_checked,
                                color: AppColors.statusSuccess, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Pickup Location',
                                hintText: '24 KN 59 St, Kigali',
                                controller: _pickupController,
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.my_location,
                                      color: AppColors.primary),
                                  onPressed: _fetchCurrentLocation,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              height: 20,
                              child: VerticalDivider(
                                color: AppColors.cardBorder,
                                thickness: 2,
                              ),
                            ),
                          ),
                        ),

                        // Dropoff Location Row
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.accentOrange, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: AppTextField(
                                label: 'Drop-off Location',
                                hintText: 'Kimironko, Zindiro',
                                controller: _dropoffController,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Package Type Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Package Type',
                          style: AppTypography.headlineMedium(
                              color: theme.colorScheme.onSurface)),
                      Text('Required',
                          style: AppTypography.labelMedium(
                              color: AppColors.statusSuccess)),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Package Type Selection Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _PackageOptionCard(
                        title: 'Food',
                        icon: Icons.restaurant,
                        isSelected: _selectedPackageType == 'Food',
                        onTap: () =>
                            setState(() => _selectedPackageType = 'Food'),
                      ),
                      _PackageOptionCard(
                        title: 'Parcel',
                        icon: Icons.inventory_2,
                        isSelected: _selectedPackageType == 'Parcel',
                        onTap: () =>
                            setState(() => _selectedPackageType = 'Parcel'),
                      ),
                      _PackageOptionCard(
                        title: 'Grocery',
                        icon: Icons.shopping_basket,
                        isSelected: _selectedPackageType == 'Grocery',
                        onTap: () =>
                            setState(() => _selectedPackageType = 'Grocery'),
                      ),
                      _PackageOptionCard(
                        title: 'Other',
                        icon: Icons.more_horiz,
                        isSelected: _selectedPackageType == 'Other',
                        onTap: () =>
                            setState(() => _selectedPackageType = 'Other'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Weight Class Section
                  Text('Weight Class',
                      style: AppTypography.headlineMedium(
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Light (<5kg)',
                        'Medium (5-15kg)',
                        'Heavy (>15kg)'
                      ].map((w) {
                        final isSelected = _selectedWeightClass == w;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(w),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedWeightClass = w);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Custom Fare Offer Input Section
                  Text('Offer Your Price (RWF)',
                      style: AppTypography.headlineMedium(
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text('Enter the fare you are offering for this delivery:',
                      style: AppTypography.bodySmall(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 10),

                  AppTextField(
                    label: 'Offered Delivery Fare (RWF)',
                    hintText: 'e.g. 2500',
                    controller: _fareController,
                    keyboardType: TextInputType.number,
                    onChanged: (val) => setState(() {}),
                  ),

                  const SizedBox(height: 24),

                  // Delivery Instructions Input Card
                  Text('Delivery Instructions (Optional)',
                      style: AppTypography.headlineMedium(
                          color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 12),

                  AppTextField(
                    label: 'Special Instructions',
                    hintText:
                        'e.g. Leave with security guard, fragile package...',
                    controller: _instructionsController,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Fare & Confirm Action Bar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                  top: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.3))),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Offered Price',
                            style: AppTypography.bodySmall(
                                color: theme.colorScheme.onSurfaceVariant)),
                        Text(
                          'RWF ${_fareController.text.trim().isEmpty ? '0' : _fareController.text.trim()}',
                          style: AppTypography.headlineLarge(
                              color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.bolt,
                            color: AppColors.statusSuccess, size: 18),
                        Text('Fastest',
                            style: AppTypography.titleMedium(
                                color: AppColors.statusSuccess)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: 'Request Rider',
                  icon: Icons.arrow_forward_ios,
                  onPressed: _submitRequest,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackageOptionCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySubtle : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color:
                  isSelected ? AppColors.primary : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTypography.titleMedium(
                color: isSelected
                    ? AppColors.primary
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
