import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_service.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  XFile? _image;
  bool _isAnalyzing = false;
  String? _result;

  // Функция выбора фото
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _image = image;
        _result = null; // Сброс результата
      });
    }
  }

  // Функция запуска "Твоего ИИ"
  void _runLocalAI() async {
    setState(() => _isAnalyzing = true);

    // ПРОВЕРКА ПЛАТФОРМЫ
    if (kIsWeb) {
      // 🌐 WEB: TFLite тут сложен, поэтому покажем имитацию или предупреждение
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _isAnalyzing = false;
        _result =
            "⚠️ TFLite работает только на Android/iOS.\n(В браузере используйте Gemini в Dashboard)";
      });
      return;
    }

    // 📱 ANDROID/IOS: Реальный запуск
    try {
      final service = LocalAIService();
      // Запускаем анализ файла
      final result = await service.analyzeImage(_image!.path);

      setState(() {
        _isAnalyzing = false;
        if (result != null) {
          // Форматируем красивый ответ
          final percent = (result['confidence']! * 100).toStringAsFixed(1);
          _result =
              "Диагноз: ${result['label']}\nВероятность: $percent%"; // Исправил опечатку label
        } else {
          _result = "Не удалось распознать растение.";
        }
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _result = "Ошибка запуска модели: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Анализ (Твой ИИ)"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ОБЛАСТЬ ФОТО
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: _image == null
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.center_focus_weak,
                          color: Colors.grey,
                          size: 60,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Загрузите фото для анализа",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: kIsWeb
                          ? Image.network(_image!.path, fit: BoxFit.cover)
                          : Image.file(File(_image!.path), fit: BoxFit.cover),
                    ),
            ),
          ),

          // РЕЗУЛЬТАТЫ
          if (_isAnalyzing)
            const CircularProgressIndicator(color: Color(0xFF00E676))
          else if (_result != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF00E676)),
              ),
              child: Column(
                children: [
                  const Text(
                    "Результат Local TFLite:",
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _result!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // КНОПКИ УПРАВЛЕНИЯ
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRoundButton(
                  Icons.photo_library,
                  () => _pickImage(ImageSource.gallery),
                ),

                // Главная кнопка "Анализ"
                GestureDetector(
                  onTap: _image != null ? _runLocalAI : null,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: _image != null
                          ? const Color(0xFF00E676)
                          : Colors.grey[800],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 30,
                      color: Colors.black,
                    ),
                  ),
                ),

                _buildRoundButton(
                  Icons.camera_alt,
                  () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
