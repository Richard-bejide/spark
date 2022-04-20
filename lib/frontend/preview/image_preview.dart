import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pinch_zoom/pinch_zoom.dart';
import 'package:spark/global_uses/constants.dart';
import 'package:spark/global_uses/enum_generation.dart';

class ImageViewScreen extends StatefulWidget {
  final ImageProviderCategory imageProviderCategory;
  final String imagePath;

  const ImageViewScreen(
      {Key? key, required this.imageProviderCategory, required this.imagePath})
      : super(key: key);
  @override
  State<ImageViewScreen> createState() => _ImageViewScreenState();
}

class _ImageViewScreenState extends State<ImageViewScreen> {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: kBlack,
      body: SafeArea(
        child: SizedBox(
          width: _size.width,
          height: _size.height,
          child: PinchZoom(
            child: _getParticularImage(),
            resetDuration: const Duration(milliseconds: 100),
            maxScale: 3.0,
            onZoomStart: () {
              print('Start zooming');
            },
            onZoomEnd: () {
              print('Stop zooming');
            },
          ),
        ),
      ),
    );
  }

  Widget _getParticularImage() {
    switch (widget.imageProviderCategory) {
      case ImageProviderCategory.fileImage:
        return Image.file(File(widget.imagePath));

      case ImageProviderCategory.exactAssetImage:
        return Image.asset('${File(widget.imagePath)}');
      case ImageProviderCategory.networkImage:
        return Image.network(
          '${File(widget.imagePath)}',
          errorBuilder: (context, error, stackTrace) =>
              const Text('Some errors occurred!'),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;

            return const Center(
              child: LinearProgressIndicator(),
            );
            // You can use LinearProgressIndicator, CircularProgressIndicator, or a GIF instead
          },
        );
    }
  }
}
