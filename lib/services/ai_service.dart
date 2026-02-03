import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img; // Пакет для обработки фото
import 'package:tflite_flutter/tflite_flutter.dart';

class LocalAIService {
  Interpreter? _interpreter;
  List<String>? _labels;

  // Загрузка модели и меток
  Future<void> loadModel() async {
    try {
      // 1. Грузим модель
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      print('✅ TFLite Модель загружена');

      // 2. Грузим метки (Labels)
      final labelData = await rootBundle.loadString('assets/model/labels.txt');
      _labels = labelData.split('\n');
      print('✅ Метки загружены: ${_labels?.length}');
    } catch (e) {
      print('❌ Ошибка загрузки TFLite: $e');
    }
  }

  // Анализ фото
  Future<Map<String, dynamic>?> analyzeImage(String imagePath) async {
    if (_interpreter == null) await loadModel();
    if (_interpreter == null) return null;

    try {
      // 1. Читаем файл и готовим его (Resize)
      // ВНИМАНИЕ: Большинство моделей обучены на картинках 224x224. 
      // Если твоя модель другая (например 300x300), поменяй цифры ниже.
      final imageData = File(imagePath).readAsBytesSync();
      final image = img.decodeImage(imageData);
      final resizedImage = img.copyResize(image!, width: 224, height: 224);

      // 2. Превращаем картинку в байты (Input Tensor)
      // TFLite требует определенный формат [1, 224, 224, 3]
      final input = _imageToByteListFloat32(resizedImage, 224, 127.5, 127.5);

      // 3. Готовим буфер для ответа (Output Tensor)
      // Размер буфера = количеству классов (болезней)
      final output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

      // 4. ЗАПУСК!
      _interpreter!.run(input, output);

      // 5. Разбираем ответ (ищем самый высокий процент)
      final result = output[0] as List<double>;
      int maxIndex = 0;
      double maxScore = 0.0;

      for (int i = 0; i < result.length; i++) {
        if (result[i] > maxScore) {
          maxScore = result[i];
          maxIndex = i;
        }
      }

      // Возвращаем лучшую догадку
      return {
        'label': _labels!.length > maxIndex ? _labels![maxIndex] : "Неизвестно",
        'confidence': maxScore
      };

    } catch (e) {
      print('❌ Ошибка анализа: $e');
      return null;
    }
  }

  // Хелпер: Конвертация картинки в формат для TFLite (Float32)
  Uint8List _imageToByteListFloat32(img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}