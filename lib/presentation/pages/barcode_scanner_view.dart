import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../data/services/open_food_facts_service.dart';
import '../../data/models/product.dart';
import '../viewmodels/image_analysis_viewmodel.dart';
import '../widgets/food_analysis_shimmer.dart';
import '../../../core/constants/app_colors.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  late MobileScannerController controller;
  final OpenFoodFactsService _service = OpenFoodFactsService();
  Product? _scannedProduct;
  bool _isLoading = false;
  String? _error;
  final double _scanFrameSize = 240.0;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _fetchProductDetails(String barcode) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productData = await _service.getProductByBarcode(barcode);
      if (productData != null) {
        setState(() {
          _scannedProduct = Product.fromOpenFoodFacts(productData);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Product not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error fetching product details';
        _isLoading = false;
      });
    }
  }

  Future<void> _addToFoodAnalysis(BuildContext context) async {
    if (_scannedProduct == null) return;

    final analysisVM = Provider.of<ImageAnalysisViewModel>(context, listen: false);

    if (context.mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_scannedProduct!.name} added to your analysis!',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      // Navigate back to home FIRST - so the shimmer effect is visible
      Navigator.pop(context);

      // Add barcode analysis with automatic download + upload
      await analysisVM.addBarcodeAnalysis(
        productName: _scannedProduct!.name,
        calories: _scannedProduct!.calories ?? 0,
        protein: _scannedProduct!.protein ?? 0,
        carbs: _scannedProduct!.carbs ?? 0,
        fat: _scannedProduct!.fat ?? 0,
        healthScore: _calculateHealthScore(_scannedProduct!),
        imageUrl: _scannedProduct!.imageUrl ?? '',
      );
    }
  }

  double _calculateHealthScore(Product product) {
    double score = 7.0; // Start with average score

    // Adjust based on protein (higher is better)
    if (product.protein != null) {
      if (product.protein! > 20) {
        score += 1.0;
      } else if (product.protein! > 10) {
        score += 0.5;
      }
    }

    // Adjust based on calories (lower is better for health)
    if (product.calories != null) {
      if (product.calories! > 500) {
        score -= 1.5;
      } else if (product.calories! > 300) {
        score -= 0.5;
      }
    }

    // Adjust based on fat (lower is better)
    if (product.fat != null) {
      if (product.fat! > 20) {
        score -= 1.0;
      } else if (product.fat! > 10) {
        score -= 0.5;
      }
    }

    return score.clamp(0.0, 10.0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: _scanFrameSize,
      height: _scanFrameSize,
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.white.withOpacity(0.5),
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.white.withOpacity(0.8),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: FaIcon(
                    FontAwesomeIcons.arrowLeft,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              title: Text(
                'Scan Barcode',
                style: TextStyle(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Camera Scanner
          MobileScanner(
            controller: controller,
            scanWindow: scanArea,
            onDetect: (capture) {
              // Only scan if no product detail is currently shown
              if (_scannedProduct == null && !_isLoading) {
                final List<Barcode> barcodes = capture.barcodes;
                for (final barcode in barcodes) {
                  if (barcode.rawValue != null) {
                    _fetchProductDetails(barcode.rawValue!);
                  }
                }
              }
            },
          ),

          // Dark overlay outside scan area
          if (!_isLoading && _scannedProduct == null && _error == null)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Scan frame with corner brackets and buttons
                    Container(
                      width: _scanFrameSize,
                      height: _scanFrameSize,
                      child: Stack(
                        children: [
                          // Corner brackets - Top Left
                          Positioned(
                            top: 0,
                            left: 0,
                            child: _buildCornerBracket(true, true),
                          ),
                          // Corner brackets - Top Right
                          Positioned(
                            top: 0,
                            right: 0,
                            child: _buildCornerBracket(true, false),
                          ),
                          // Corner brackets - Bottom Left
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: _buildCornerBracket(false, true),
                          ),
                          // Corner brackets - Bottom Right
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: _buildCornerBracket(false, false),
                          ),
                          // Bottom control buttons inside frame - Glassmorphic
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(24),
                                bottomRight: Radius.circular(24),
                              ),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  height: 55,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withOpacity(0.15),
                                        Colors.white.withOpacity(0.08),
                                      ],
                                    ),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.white.withOpacity(0.25),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: _buildInFrameButton(
                                          icon: FontAwesomeIcons.keyboard,
                                          onTap: () => _showManualBarcodeInput(context),
                                        ),
                                      ),
                                      Container(
                                        width: 1.5,
                                        height: 35,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.white.withOpacity(0.0),
                                              Colors.white.withOpacity(0.35),
                                              Colors.white.withOpacity(0.0),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ValueListenableBuilder(
                                          valueListenable: controller.torchState,
                                          builder: (context, state, child) {
                                            return _buildInFrameButton(
                                              icon: FontAwesomeIcons.bolt,
                                              onTap: () => controller.toggleTorch(),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Instruction text
                    Text(
                      'Position barcode within the frame',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading Indicator
          if (_isLoading)
            const BarcodeScannerShimmer(),

          // Error Message
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.error.withOpacity(0.15),
                            AppColors.error.withOpacity(0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.error.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: FaIcon(
                              FontAwesomeIcons.triangleExclamation,
                              color: AppColors.error,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Error',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : AppColors.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: FaIcon(
                              FontAwesomeIcons.xmark,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              size: 16,
                            ),
                            onPressed: () {
                              setState(() {
                                _error = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Product Result Card - Modal style overlay
          if (_scannedProduct != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Product Image
                      if (_scannedProduct!.imageUrl != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 140,
                              width: 140,
                              decoration: BoxDecoration(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Image.network(
                                _scannedProduct!.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.imagePortrait,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // Product Name
                      Text(
                        _scannedProduct!.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Brand
                      if (_scannedProduct!.brand != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.tag,
                              size: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _scannedProduct!.brand!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Nutrition Title
                      Text(
                        'Nutritional Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Nutrient Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassNutrientCard(
                              context,
                              'Calories',
                              _scannedProduct!.calories?.toStringAsFixed(0) ?? 'N/A',
                              'kcal',
                              AppColors.orange,
                              FontAwesomeIcons.fire,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildGlassNutrientCard(
                              context,
                              'Protein',
                              _scannedProduct!.protein?.toStringAsFixed(1) ?? 'N/A',
                              'g',
                              AppColors.blue,
                              FontAwesomeIcons.dumbbell,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassNutrientCard(
                              context,
                              'Carbs',
                              _scannedProduct!.carbs?.toStringAsFixed(1) ?? 'N/A',
                              'g',
                              AppColors.green,
                              FontAwesomeIcons.carrot,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _buildGlassNutrientCard(
                              context,
                              'Fat',
                              _scannedProduct!.fat?.toStringAsFixed(1) ?? 'N/A',
                              'g',
                              AppColors.orange,
                              FontAwesomeIcons.droplet,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildGlassButton(
                              context,
                              'Rescan',
                              FontAwesomeIcons.arrowsRotate,
                              onPressed: () {
                                setState(() {
                                  _scannedProduct = null;
                                  _error = null;
                                });
                              },
                              isPrimary: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _buildGlassButton(
                              context,
                              'Add to Analysis',
                              FontAwesomeIcons.plus,
                              onPressed: () => _addToFoodAnalysis(context),
                              isPrimary: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(bool isTop, bool isLeft) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(24) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(24) : Radius.zero,
          bottomLeft: !isTop && isLeft ? const Radius.circular(24) : Radius.zero,
          bottomRight: !isTop && !isLeft ? const Radius.circular(24) : Radius.zero,
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
            width: isTop ? 4 : 0,
          ),
          bottom: BorderSide(
            color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
            width: !isTop ? 4 : 0,
          ),
          left: BorderSide(
            color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
            width: isLeft ? 4 : 0,
          ),
          right: BorderSide(
            color: isDark ? Colors.white : Colors.white.withOpacity(0.9),
            width: !isLeft ? 4 : 0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNutrientCard(
    BuildContext context,
    String label,
    String value,
    String unit,
    Color accentColor,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: 16,
                color: accentColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton(
    BuildContext context,
    String label,
    IconData icon, {
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isPrimary
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPressed,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(
                        icon,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FaIcon(
                          icon,
                          size: 12,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
