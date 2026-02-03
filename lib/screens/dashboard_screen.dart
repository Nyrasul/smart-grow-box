import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/grow_box_provider.dart';
import 'package:image_picker/image_picker.dart'; // Выбор фото
import 'dart:typed_data';
import 'chat_screen.dart';
import 'analysis_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Подключаем "Глаза" к "Мозгу"
    // watch() заставляет экран перерисовываться, когда меняются данные
    final state = context.watch<GrowBoxProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. ВИДЕОПОТОК (С Живым статусом) ---
              // --- 1. ВИДЕОПОТОК (ТЕПЕРЬ РЕАЛЬНЫЙ) ---
              Container(
                height: 220,
                width: double.infinity,
                clipBehavior: Clip
                    .antiAlias, // Чтобы видео не вылезало за скругленные углы
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ЛОГИКА: Если ссылка есть - показываем видео. Если нет - заглушку.
                    state.cameraStreamUrl.isNotEmpty
                        ? Image.network(
                            state.cameraStreamUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            // Чтобы не падало при ошибке загрузки
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                    Text(
                                      "Нет связи с камерой",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.videocam_off,
                                color: Colors.white24,
                                size: 50,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Камера отключена",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),

                    // Бейджик статуса (LIVE меняется в зависимости от наличия ссылки)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: state.cameraStreamUrl.isNotEmpty
                              ? Colors.redAccent
                              : Colors.grey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              state.cameraStreamUrl.isNotEmpty
                                  ? "LIVE"
                                  : "OFFLINE",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- 2. СЕТКА ДАТЧИКОВ (ЖИВЫЕ ДАННЫЕ) ---
              _buildSectionHeader("КЛИМАТ И ВОДА"),

              Row(
                children: [
                  // Используем toStringAsFixed(1), чтобы было 25.0, а не 25.000001
                  Expanded(
                    child: _buildSensorCard(
                      Icons.thermostat,
                      "Воздух",
                      "${state.airTemp.toStringAsFixed(1)}°C",
                      Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSensorCard(
                      Icons.water_drop,
                      "Влажность",
                      "${state.humidity.toStringAsFixed(0)}%",
                      Colors.blueAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildSensorCard(
                      FontAwesomeIcons.flask,
                      "pH Воды",
                      state.waterPh.toStringAsFixed(1),
                      Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSensorCard(
                      FontAwesomeIcons.searchengin,
                      "TDS",
                      "${state.waterTds.toInt()} ppm",
                      Colors.greenAccent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // --- 3. ИИ АГРОНОМ ---
              _buildSectionHeader("SMART AGRONOMIST"),

              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.camera_alt_outlined,
                      title: "Анализ Фото",
                      subtitle: "Локальный TFLite",
                      color: const Color(0xFF00E676),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AnalysisScreen()),
                        );
                      },
                    ), // <--- ЗДЕСЬ БЫЛА ОШИБКА, ТЕПЕРЬ ВСЁ ЧИСТО
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionCard(
                      icon: FontAwesomeIcons.robot,
                      title: "Чат с ИИ",
                      subtitle: "Gemini Vision",
                      color: Colors.tealAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChatScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),

              // --- 4. ЗДОРОВЬЕ СИСТЕМЫ (Динамическое) ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: state.isSystemHealthy
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: state.isSystemHealthy
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        state.isSystemHealthy
                            ? Icons.check_circle
                            : Icons.warning,
                        color: state.isSystemHealthy
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isSystemHealthy
                              ? "Система в норме"
                              : "ВНИМАНИЕ!",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          state.isSystemHealthy
                              ? "Все показатели стабильны"
                              : "Проверьте вентиляцию",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSensorCard(
    IconData icon,
    String title,
    String value,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        // Легкая тень для объема
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: color.withOpacity(0.7), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
