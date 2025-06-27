import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:water_readings_app/core/models/reading.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<OCRResult> extractTextFromImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // Extract potential numbers from the recognized text
      final numbers = _extractNumbers(recognizedText.text);
      final confidence = _calculateConfidence(recognizedText);
      
      return OCRResult(
        extractedValue: numbers.isNotEmpty ? numbers.first : null,
        confidence: confidence,
        rawText: recognizedText.text,
        alternativeValues: numbers.length > 1 ? numbers.sublist(1) : null,
      );
    } catch (e) {
      return OCRResult(
        extractedValue: null,
        confidence: 0.0,
        rawText: 'Error during OCR processing: $e',
      );
    }
  }

  List<double> _extractNumbers(String text) {
    final numbers = <double>[];
    
    // Remove common noise characters and normalize
    String cleanText = text
        .replaceAll(RegExp(r'[^\d\s\.,]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    // Pattern to match numbers with decimal points
    final numberPattern = RegExp(r'\b\d+(?:[.,]\d+)?\b');
    final matches = numberPattern.allMatches(cleanText);
    
    for (final match in matches) {
      final numberStr = match.group(0)!.replaceAll(',', '.');
      final number = double.tryParse(numberStr);
      
      if (number != null && _isValidMeterReading(number)) {
        numbers.add(number);
      }
    }
    
    // Sort by likelihood of being correct (prefer numbers in reasonable range)
    numbers.sort((a, b) => _calculateNumberScore(b).compareTo(_calculateNumberScore(a)));
    
    return numbers.take(5).toList(); // Return top 5 candidates
  }

  bool _isValidMeterReading(double value) {
    // Water meter readings typically range from 0 to 999999
    // Filter out obviously wrong values
    return value >= 0 && value <= 999999;
  }

  double _calculateNumberScore(double number) {
    // Prefer numbers in typical meter reading ranges
    if (number >= 1 && number <= 100000) {
      return 1.0;
    } else if (number >= 0.1 && number <= 500000) {
      return 0.8;
    } else if (number >= 0 && number <= 999999) {
      return 0.6;
    }
    return 0.0;
  }

  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;
    
    double totalConfidence = 0.0;
    int elementCount = 0;
    
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          if (element.text.contains(RegExp(r'\d'))) {
            // Give higher weight to text elements containing numbers
            totalConfidence += 1.0; // MLKit doesn't provide confidence scores in this version
            elementCount++;
          }
        }
      }
    }
    
    if (elementCount == 0) return 0.0;
    
    // Calculate confidence based on presence of numeric content
    double confidence = (totalConfidence / elementCount) * 0.8; // Base confidence of 80% for numeric content
    
    // Boost confidence if multiple numbers are found (indicating a proper meter display)
    final numbers = _extractNumbers(recognizedText.text);
    if (numbers.length > 1) {
      confidence = (confidence * 1.2).clamp(0.0, 1.0);
    }
    
    return confidence;
  }

  Future<OCRResult> processImageWithPreprocessing(String imagePath) async {
    // For future enhancement: add image preprocessing
    // - Resize image for optimal OCR
    // - Adjust contrast/brightness
    // - Apply filters to enhance text recognition
    
    return await extractTextFromImage(imagePath);
  }

  Future<List<OCRResult>> processBatch(List<String> imagePaths) async {
    final results = <OCRResult>[];
    
    for (final imagePath in imagePaths) {
      try {
        final result = await extractTextFromImage(imagePath);
        results.add(result);
      } catch (e) {
        results.add(OCRResult(
          extractedValue: null,
          confidence: 0.0,
          rawText: 'Failed to process image: $e',
        ));
      }
    }
    
    return results;
  }

  void dispose() {
    _textRecognizer.close();
  }
}

// Provider
final ocrServiceProvider = Provider<OCRService>((ref) {
  final service = OCRService();
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});