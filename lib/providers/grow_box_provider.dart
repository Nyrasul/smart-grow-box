import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:typed_data'; // Для работы с байтами картинки
import 'package:google_generative_ai/google_generative_ai.dart';

class GrowBoxProvider with ChangeNotifier {
  // Ссылка на базу данных
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ==========================================
  // 1. ДАННЫЕ (СОСТОЯНИЕ)
  // ==========================================

  // --- ДАТЧИКИ (Слушаем из базы) ---
  double airTemp = 0.0;
  double humidity = 0.0;
  double waterPh = 0.0;
  double waterTds = 0;
  bool isSystemHealthy = true;

  // --- УПРАВЛЕНИЕ СВЕТОМ ---
  bool isLightOn = false;
  double brightness = 100;
  double colorR = 255;
  double colorG = 255;
  double colorB = 255;
  double colorW = 255;

  // --- КЛИМАТ И ВЕНТИЛЯЦИЯ ---
  bool isFanAuto = true;
  double fanSpeed = 0;

  // --- ПОЛИВ ---
  bool isPumpActive = false;

  String cameraStreamUrl = "";

  List<Content> chatHistory = []; // История диалога для Google
  bool isChatLoading = false;

  final String _geminiKey = "AIzaSyC0QxWx48SEzHPDVFJK6iZWvqeJYv9fEGo";

  // ==========================================
  // 2. ИНИЦИАЛИЗАЦИЯ (СЛУШАЕМ БАЗУ)
  // ==========================================
  GrowBoxProvider() {
    _initListeners();
  }

  void _initListeners() {
    // Подписываемся на изменения в папке 'sensors'
    _db.child('sensors').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        // Если данные пришли - обновляем переменные
        // (tryNum нужен, чтобы не упало, если придет строка вместо числа)
        airTemp = _tryNum(data['temp_air']);
        humidity = _tryNum(data['humidity']);
        waterPh = _tryNum(data['ph']);
        waterTds = _tryNum(data['tds']);
        notifyListeners(); // Обновляем экран
      }
    });

    // Подписываемся на статус системы (для Predictive Maintenance)
    _db.child('system/health').onValue.listen((event) {
      final status = event.snapshot.value as bool?;
      if (status != null) {
        isSystemHealthy = status;
        notifyListeners();
      }
    });

    // Подписываемся на состояние исполнителей (чтобы синхронизировать ползунки)
    // Например, если ESP32 сама изменила скорость вентилятора
    _db.child('control').onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        // Свет
        if (data['light'] != null) {
          isLightOn = data['light']['power'] ?? false;
          brightness = _tryNum(data['light']['brightness']);
          colorR = _tryNum(data['light']['r']);
          colorG = _tryNum(data['light']['g']);
          colorB = _tryNum(data['light']['b']);
          colorW = _tryNum(data['light']['w']);
        }
        // Вентиляция
        if (data['fan'] != null) {
          isFanAuto = data['fan']['auto'] ?? true;
          fanSpeed = _tryNum(data['fan']['speed']);
        }
        // Камера
        if (data['camera'] != null) {
          cameraStreamUrl = data['camera']['stream_url'] ?? "";
        }
        // Помпа
        if (data['pump'] != null) {
          isPumpActive = data['pump']['state'] ?? false;
        }
        notifyListeners();
      }
    });
  }

  // Хелпер: Безопасное преобразование в double
  double _tryNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  // ==========================================
  // 3. МЕТОДЫ (ОТПРАВЛЯЕМ КОМАНДЫ)
  // ==========================================

  // Свет
  void updateLightStatus(bool isOn) {
    isLightOn = isOn;
    notifyListeners(); // Сразу меняем UI для отзывчивости
    _db.child('control/light/power').set(isOn); // Отправляем в облако
  }

  void updateLightColors({
    double? r,
    double? g,
    double? b,
    double? w,
    double? bright,
  }) {
    // Обновляем локально
    if (r != null) colorR = r;
    if (g != null) colorG = g;
    if (b != null) colorB = b;
    if (w != null) colorW = w;
    if (bright != null) brightness = bright;
    notifyListeners();

    // Отправляем в облако (Map для обновления сразу нескольких полей)
    _db.child('control/light').update({
      if (r != null) 'r': r.toInt(),
      if (g != null) 'g': g.toInt(),
      if (b != null) 'b': b.toInt(),
      if (w != null) 'w': w.toInt(),
      if (bright != null) 'brightness': bright.toInt(),
    });
  }

  // Вентиляция
  void updateFanMode(bool isAuto) {
    isFanAuto = isAuto;
    notifyListeners();
    _db.child('control/fan/auto').set(isAuto);
  }

  void updateFanSpeed(double speed) {
    fanSpeed = speed;
    notifyListeners();
    // Отправляем только если ручной режим (на всякий случай)
    if (!isFanAuto) {
      _db.child('control/fan/speed').set(speed.toInt());
    }
  }

  // Помпа
  void togglePump(bool isActive) {
    isPumpActive = isActive;
    notifyListeners();
    _db.child('control/pump/state').set(isActive);
  }

  // Метод анализа фото
  // Метод для общения в чате
  Future<String> chatWithGemini(String userMessage) async {
    try {
      isChatLoading = true;
      notifyListeners();

      // 1. Инициализируем модель (если еще нет)
      final model = GenerativeModel(  
        model: 'gemma-3-4b-it',
        apiKey: _geminiKey, // Твой ключ уже там есть
      );

      // 2. Создаем чат-сессию с историей
      final chat = model.startChat(history: chatHistory);

      // 3. Отправляем сообщение
      final content = Content.text(userMessage);
      final response = await chat.sendMessage(content);

      // 4. Сохраняем ответ в историю (Google SDK делает это сам внутри startChat,
      // но нам нужно сохранить локально, если мы пересоздаем объект)
      chatHistory.add(content);
      if (response.text != null) {
        chatHistory.add(Content.model([TextPart(response.text!)]));
      }

      isChatLoading = false;
      notifyListeners();

      return response.text ?? "Агроном задумался...";
    } catch (e) {
      isChatLoading = false;
      notifyListeners();
      return "Ошибка связи: $e";
    }
  }

  // Очистить историю (если нужно)
  void clearChat() {
    chatHistory.clear();
    notifyListeners();
  }
}
