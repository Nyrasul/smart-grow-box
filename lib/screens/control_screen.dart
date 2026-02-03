import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/grow_box_provider.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Подключаемся к мозгу
    final state = context.watch<GrowBoxProvider>();
    final logic = context.read<GrowBoxProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Управление"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- 1. СЕКЦИЯ СВЕТА (LIGHTING) ---
              _buildSectionTitle("ОСВЕЩЕНИЕ (RGBW)"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Главный рубильник
                    SwitchListTile(
                      title: const Text("Питание панели", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        state.isLightOn ? "ВКЛЮЧЕНО" : "ВЫКЛЮЧЕНО", 
                        style: TextStyle(color: state.isLightOn ? const Color(0xFF00E676) : Colors.grey, fontSize: 12)
                      ),
                      value: state.isLightOn,
                      activeColor: const Color(0xFF00E676),
                      onChanged: (val) => logic.updateLightStatus(val),
                    ),
                    const Divider(color: Colors.white10),
                    
                    // Слайдеры с красивым дизайном
                    _buildFancySlider(context, "Яркость (Master)", state.brightness, Colors.amber, (v) => logic.updateLightColors(bright: v)),
                    _buildFancySlider(context, "Красный (Red)", state.colorR, Colors.redAccent, (v) => logic.updateLightColors(r: v)),
                    _buildFancySlider(context, "Зеленый (Green)", state.colorG, Colors.greenAccent, (v) => logic.updateLightColors(g: v)),
                    _buildFancySlider(context, "Синий (Blue)", state.colorB, Colors.blueAccent, (v) => logic.updateLightColors(b: v)),
                    _buildFancySlider(context, "Белый (White)", state.colorW, Colors.white, (v) => logic.updateLightColors(w: v)),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 2. ВЕНТИЛЯЦИЯ (CLIMATE) ---
              _buildSectionTitle("ВЕНТИЛЯЦИЯ"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Авто-режим (AI)", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Скорость зависит от температуры", style: TextStyle(fontSize: 10, color: Colors.grey)),
                      value: state.isFanAuto,
                      activeColor: Colors.blueAccent,
                      onChanged: (val) => logic.updateFanMode(val),
                    ),
                    const SizedBox(height: 10),
                    
                    // Слайдер блокируется (сереет), если включен Авто-режим
                    Opacity(
                      opacity: state.isFanAuto ? 0.5 : 1.0,
                      child: _buildFancySlider(
                        context, 
                        "Скорость кулеров", 
                        state.fanSpeed, 
                        Colors.blue, 
                        state.isFanAuto ? null : (v) => logic.updateFanSpeed(v) // Если авто - передаем null (блокируем)
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 3. ПОЛИВ (PUMP) ---
              _buildSectionTitle("ГИДРОПОНИКА"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Ручной полив", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Включить помпу принудительно", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    // Кнопка, которую можно зажать
                    GestureDetector(
                      onTapDown: (_) => logic.togglePump(true), // Нажал -> Помпа ВКЛ
                      onTapUp: (_) => logic.togglePump(false),   // Отпустил -> Помпа ВЫКЛ
                      onTapCancel: () => logic.togglePump(false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: state.isPumpActive ? Colors.blueAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.blueAccent),
                          boxShadow: state.isPumpActive 
                              ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] 
                              : [],
                        ),
                        child: Text(
                          state.isPumpActive ? "ПОЛИВ..." : "СТАРТ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: state.isPumpActive ? Colors.white : Colors.blueAccent
                          ),
                        ),
                      ),
                    )
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

  // --- Helpers для Красоты ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    );
  }

  // Тот самый красивый слайдер из Sprint 1
  Widget _buildFancySlider(BuildContext context, String label, double value, Color color, Function(double)? onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
            Text("${value.toInt()}", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        // SliderTheme делает полоску толстой, а кружок больше
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 4.0, // Жирная линия
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), // Большой палец
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}