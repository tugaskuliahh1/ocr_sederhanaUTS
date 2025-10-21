import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ocr_sederhana_uts/screens/result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        debugPrint("Tidak ada kamera tersedia");
        return;
      }

      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(backCamera, ResolutionPreset.medium);
      await _controller!.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Gagal inisialisasi kamera: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<String> _ocrFromFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    textRecognizer.close();
    return recognizedText.text;
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      if (_controller == null || !_controller!.value.isInitialized) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Kamera belum siap.")));
        return;
      }

      final XFile image = await _controller!.takePicture();
      final ocrText = await _ocrFromFile(File(image.path));

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(ocrText: ocrText)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Pemindaian Gagal! Periksa Izin Kamera atau coba lagi.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kamera OCR')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Custom Loading Screen
            return Scaffold(
              backgroundColor: Colors.grey[900],
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.yellow),
                    SizedBox(height: 20),
                    Text(
                      'Memuat Kamera... Harap tunggu.',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          } else if (_controller == null ||
              !_controller!.value.isInitialized ||
              snapshot.hasError) {
            return const Center(
              child: Text(
                "Gagal menginisialisasi kamera",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else {
            return Column(
              children: [
                Expanded(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _takePicture,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Ambil Foto & Scan'),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
