import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/services/open_food_facts_service.dart';
import '../../data/models/product.dart';
import '../widgets/food_analysis_shimmer.dart';

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
  final double _scanFrameSize = 250.0;

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: _scanFrameSize,
      height: _scanFrameSize,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  scanWindow: scanArea,
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcode in barcodes) {
                      if (barcode.rawValue != null) {
                        _fetchProductDetails(barcode.rawValue!);
                      }
                    }
                  },
                ),
                // Scanning Guide Overlay
                if (!_isLoading && _scannedProduct == null)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: _scanFrameSize,
                          height: _scanFrameSize,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              // Corner markers
                              Positioned(
                                top: 0,
                                left: 0,
                                child: _buildCornerMarker(true, true),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: _buildCornerMarker(true, false),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: _buildCornerMarker(false, true),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: _buildCornerMarker(false, false),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Position the barcode within the frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isLoading)
                  const Center(
                    child: FoodAnalysisShimmer(),
                  ),
              ],
            ),
          ),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.shade100,
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          if (_scannedProduct != null)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_scannedProduct!.imageUrl != null)
                    Center(
                      child: Image.network(
                        _scannedProduct!.imageUrl!,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            width: 200,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _scannedProduct!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_scannedProduct!.brand != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Brand: ${_scannedProduct!.brand}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNutrientCard(
                        'Calories',
                        _scannedProduct!.calories?.toStringAsFixed(1) ?? 'N/A',
                        'kcal',
                      ),
                      _buildNutrientCard(
                        'Protein',
                        _scannedProduct!.protein?.toStringAsFixed(1) ?? 'N/A',
                        'g',
                      ),
                      _buildNutrientCard(
                        'Carbs',
                        _scannedProduct!.carbs?.toStringAsFixed(1) ?? 'N/A',
                        'g',
                      ),
                      _buildNutrientCard(
                        'Fat',
                        _scannedProduct!.fat?.toStringAsFixed(1) ?? 'N/A',
                        'g',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, _scannedProduct);
                      },
                      child: const Text('Add to Food List'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCornerMarker(bool isTop, bool isLeft) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white,
            width: isTop ? 4 : 0,
          ),
          bottom: BorderSide(
            color: Colors.white,
            width: !isTop ? 4 : 0,
          ),
          left: BorderSide(
            color: Colors.white,
            width: isLeft ? 4 : 0,
          ),
          right: BorderSide(
            color: Colors.white,
            width: !isLeft ? 4 : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, String value, String unit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
