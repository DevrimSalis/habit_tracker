import 'package:flutter/material.dart';
import 'package:habit_tracker/services/notification_service.dart';
import '../models/habit.dart';
import '../services/database_helper.dart';

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  bool _isReminderEnabled = false;
  TimeOfDay? _reminderTime;

  final List<Map<String, String>> _habitTemplates = [
    {'name': 'Su İçmek', 'description': 'Günde 8 bardak su içmek', 'icon': '💧'},
    {'name': 'Spor Yapmak', 'description': '30 dakika egzersiz yapmak', 'icon': '🏃‍♂️'},
    {'name': 'Kitap Okumak', 'description': 'Günde 20 sayfa kitap okumak', 'icon': '📚'},
    {'name': 'Meditasyon', 'description': '10 dakika meditasyon yapmak', 'icon': '🧘‍♂️'},
    {'name': 'Erken Kalkmak', 'description': 'Sabah 7:00\'de kalkmak', 'icon': '⏰'},
    {'name': 'Dil Öğrenmek', 'description': '15 dakika yabancı dil çalışmak', 'icon': '🗣️'},
    {'name': 'Günlük Tutmak', 'description': 'Günün notlarını yazmak', 'icon': '📝'},
    {'name': 'Vitamin Almak', 'description': 'Günlük vitaminleri almak', 'icon': '💊'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectTemplate(Map<String, String> template) {
    setState(() {
      _nameController.text = template['name']!;
      _descriptionController.text = template['description']!;
    });
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF667eea),
                onPrimary: Colors.white,
                onSurface: Color(0xFF2D3748),
              ),
              timePickerTheme: const TimePickerThemeData(
                hourMinuteTextStyle: TextStyle(fontSize: 24),
                helpTextStyle: TextStyle(fontSize: 16),
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _reminderTime = picked;
        if (!_isReminderEnabled) {
          _isReminderEnabled = true;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool hasPermissions = true;
      
      if (_isReminderEnabled && _reminderTime != null) {
        hasPermissions = await NotificationService.checkAllPermissions();
        
        if (!hasPermissions) {
          if (!mounted) return;
          
          final shouldRequestPermissions = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.notifications_outlined, color: Color(0xFF667eea)),
                  SizedBox(width: 12),
                  Text('Bildirim İzni Gerekli'),
                ],
              ),
              content: const Text(
                'Hatırlatmalar için bildirim izinlerine ihtiyaç var. '
                'Şimdi izinleri verebilir veya hatırlatma olmadan devam edebilirsiniz.'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Hatırlatmasız Devam Et'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                  ),
                  child: const Text('İzinleri Ver', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
          
          if (shouldRequestPermissions == true) {
            hasPermissions = await NotificationService.requestAllPermissions();
            
            if (!hasPermissions) {
              if (!mounted) return;
              
              final shouldOpenSettings = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('İzin Gerekli'),
                  content: const Text(
                    'Bildirimler için manuel olarak izin vermeniz gerekiyor. '
                    'Ayarları açarak uygulamaya bildirim izni verebilirsiniz.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hatırlatmasız Devam Et'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                      ),
                      child: const Text('Ayarlara Git', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              
              if (shouldOpenSettings == true) {
                await NotificationService.openNotificationSettings();
                await Future.delayed(const Duration(seconds: 1));
                hasPermissions = await NotificationService.checkAllPermissions();
              }
            }
          } else {
            setState(() {
              _isReminderEnabled = false;
              _reminderTime = null;
            });
          }
        }
      }

      final habit = Habit(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        createdDate: DateTime.now(),
        completedDates: [],
        reminderTime: (_isReminderEnabled && hasPermissions) ? _reminderTime : null,
        isReminderEnabled: (_isReminderEnabled && hasPermissions),
      );

      await DatabaseHelper().insertHabit(habit);

      final savedHabits = await DatabaseHelper().getHabits();
      final savedHabit = savedHabits.lastWhere((h) => h.name == habit.name);

      if (savedHabit.isReminderEnabled && savedHabit.reminderTime != null) {
        await NotificationService.scheduleHabitReminder(savedHabit);
      }

      if (!mounted) return;

      _showSuccessSnackBar(
        savedHabit.isReminderEnabled 
          ? 'Alışkanlık ve hatırlatma başarıyla eklendi!'
          : 'Alışkanlık başarıyla eklendi!'
      );
      Navigator.pop(context, true);
      
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Alışkanlık eklenirken hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFFE53E3E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yeni Alışkanlık',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Yeni bir alışkanlık ekleyin',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isLoading)
                      GestureDetector(
                        onTap: _saveHabit,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Kaydet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                            ),
                          )
                        : _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hızlı Seçenekler',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _habitTemplates.length,
                itemBuilder: (context, index) {
                  final template = _habitTemplates[index];
                  return GestureDetector(
                    onTap: () => _selectTemplate(template),
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF667eea).withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            spreadRadius: 0,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667eea).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              template['icon']!,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template['name']!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            const Text(
              'Alışkanlık Detayları',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Alışkanlık Adı',
                  hintText: 'Örn: Su içmek, Spor yapmak',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Color(0xFF667eea),
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen alışkanlık adı girin';
                  }
                  if (value.trim().length < 2) {
                    return 'Alışkanlık adı en az 2 karakter olmalı';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Açıklama (İsteğe Bağlı)',
                  hintText: 'Hedeflerinizi ve detayları yazın',
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_rounded,
                      color: Color(0xFF667eea),
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  labelStyle: const TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    spreadRadius: 0,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667eea).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_rounded,
                            color: Color(0xFF667eea),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Hatırlatma',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Günlük Hatırlatma',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF4A5568),
                          ),
                        ),
                        Switch(
                          value: _isReminderEnabled,
                          onChanged: (value) {
                            setState(() {
                              _isReminderEnabled = value;
                              if (!value) {
                                _reminderTime = null;
                              }
                            });
                          },
                          activeColor: const Color(0xFF667eea),
                        ),
                      ],
                    ),
                    
                    if (_isReminderEnabled) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF667eea).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _selectTime,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF667eea),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _reminderTime != null
                                        ? 'Saat: ${_formatTimeOfDay(_reminderTime!)}'
                                        : 'Hatırlatma saati seç',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _reminderTime != null
                                          ? const Color(0xFF2D3748)
                                          : const Color(0xFF667eea),
                                      fontWeight: _reminderTime != null
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Color(0xFF667eea),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667eea).withValues(alpha: 0.3),
                    spreadRadius: 0,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveHabit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Alışkanlığı Kaydet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}