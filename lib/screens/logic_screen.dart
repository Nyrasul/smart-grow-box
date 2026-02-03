import 'package:flutter/material.dart';

class LogicScreen extends StatefulWidget {
  const LogicScreen({super.key});

  @override
  State<LogicScreen> createState() => _LogicScreenState();
}

class _LogicScreenState extends State<LogicScreen> {
  // --- ВРЕМЕННОЕ СОСТОЯНИЕ ---
  String targetTemp = "26.0";
  String hysteresis = "1.0";
  
  TimeOfDay lightOnTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay lightOffTime = const TimeOfDay(hour: 22, minute: 0);

  String selectedSpectrum = 'Вегетация (Growth)';
  String selectedWaterInterval = '60 мин';
  String selectedWaterDuration = '15 сек';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Настройки Логики"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // --- 1. КЛИМАТ КОНТРОЛЬ ---
              _buildSectionTitle("АВТОМАТИКА ВЕНТИЛЯЦИИ"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildNumberInput("Целевая темп. (°C)", targetTemp, (val) => targetTemp = val),
                    const Divider(color: Colors.white10),
                    _buildNumberInput("Гистерезис (+/- °C)", hysteresis, (val) => hysteresis = val),
                    const SizedBox(height: 10),
                    const Text(
                      "Вентиляторы включатся на 100%, если Т > Цель + Гистерезис",
                      style: TextStyle(color: Colors.grey, fontSize: 10, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 2. РАСПИСАНИЕ СВЕТА ---
              _buildSectionTitle("РАСПИСАНИЕ СВЕТА"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTimePickerRow("Включение", lightOnTime, (t) => setState(() => lightOnTime = t)),
                    const Divider(color: Colors.white10),
                    _buildTimePickerRow("Выключение", lightOffTime, (t) => setState(() => lightOffTime = t)),
                    const SizedBox(height: 10),
                    // Дропдаун режима спектра
                    DropdownButtonFormField<String>(
                      value: selectedSpectrum,
                      dropdownColor: const Color(0xFF2C2C2C),
                      decoration: const InputDecoration(
                        labelText: "Режим Спектра",
                        labelStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      ),
                      items: ['Вегетация (Growth)', 'Цветение (Bloom)', 'Клонирование'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (newValue) => setState(() => selectedSpectrum = newValue!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- 3. ПОЛИВ ---
              _buildSectionTitle("АВТОМАТИКА ПОЛИВА"),
              Container(
                decoration: _cardDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDropdown("Интервал полива", selectedWaterInterval, ['30 мин', '60 мин', '2 часа', '4 часа', '12 часов'], (v) => setState(() => selectedWaterInterval = v!)),
                    const SizedBox(height: 15),
                    _buildDropdown("Длительность", selectedWaterDuration, ['5 сек', '10 сек', '15 сек', '30 сек', '1 мин'], (v) => setState(() => selectedWaterDuration = v!)),
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

  // --- UI HELPERS ---

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

  // Поле ввода цифр
  Widget _buildNumberInput(String label, String value, Function(String) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        SizedBox(
          width: 80,
          child: TextFormField(
            initialValue: value,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // Выбор времени
  Widget _buildTimePickerRow(String label, TimeOfDay time, Function(TimeOfDay) onTimeChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        TextButton(
          onPressed: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: time,
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFF00E676), // Цвет стрелок часов
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) onTimeChanged(picked);
          },
          child: Text(
            "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}",
            style: const TextStyle(fontSize: 18, color: Color(0xFF00E676), fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  // Выпадающий список
  Widget _buildDropdown(String label, String currentVal, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: currentVal,
      dropdownColor: const Color(0xFF2C2C2C),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      ),
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}