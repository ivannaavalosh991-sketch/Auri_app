// Importamos los paquetes necesarios
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:auri_app/widgets/auri_visual.dart';

// Importamos servicios y modelos
import 'package:auri_app/models/weather_model.dart';
import 'package:auri_app/services/notification_service.dart';
import 'package:auri_app/services/weather_service.dart';
import 'package:auri_app/models/reminder_model.dart';
import 'package:auri_app/services/auto_reminder_service.dart';

// Importamos Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// Importamos las páginas y widgets
import 'package:auri_app/pages/weather_page.dart';
import 'package:auri_app/pages/reminders_page.dart';
import 'package:auri_app/widgets/weather_display.dart';
import 'package:auri_app/widgets/outfit_recommendation.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 🔧 Handler para notificaciones en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Mensaje recibido en segundo plano: ${message.messageId}");
}

// Instancia global del servicio de notificaciones
final NotificationService notificationService = NotificationService();

// Punto de entrada principal de la app
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializamos tz desde el inicio
  tz.initializeTimeZones();

  final String localTz = tz.local.name;

  // fallback si el nombre no existe
  final safeTz = tz.timeZoneDatabase.locations.containsKey(localTz)
      ? localTz
      : "UTC";

  tz.setLocalLocation(tz.getLocation(safeTz));

  // Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Env
  await dotenv.load(fileName: ".env");

  // Notificaciones (solo UNA VEZ)
  await notificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final isSurveyCompleted = prefs.getBool('isSurveyCompleted') ?? false;

  runApp(MyApp(isSurveyCompleted: isSurveyCompleted));
}

// El Widget raíz de la aplicación
class MyApp extends StatelessWidget {
  final bool isSurveyCompleted;

  const MyApp({super.key, required this.isSurveyCompleted});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auri Asistente',
      theme: ThemeData(
        // Tema Oscuro Estético para Auri
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212), // Fondo muy oscuro
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // AppBar transparente
          elevation: 0,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9C27B0), // Púrpura vibrante
          secondary: Color(0xFF00BCD4), // Cian/Teal
          surface: Color(0xFF1E1E1E), // Superficie ligeramente más clara
          onSurface: Colors.white,
        ),
        // Estilos de botones elevados (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF9C27B0), // Usar color primario
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // Estilos de campos de texto (InputDecoration)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      debugShowCheckedModeBanner: false,
      // Decidimos qué pantalla mostrar basado en el flag
      home: isSurveyCompleted ? const HomeScreen() : const WelcomeScreen(),
    );
  }
}

// 1. Pantalla de Bienvenida (Para usuarios nuevos)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mascota Visual de Auri
            const SizedBox(width: 200, height: 200, child: AuriVisual()),
            const SizedBox(height: 30),
            const Text(
              'AURI ASISTENTE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu asistente de vida personal y estilo.',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 18,
                ),
                elevation: 5,
              ),
              child: const Text(
                'Empezar mi día',
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () {
                // Navegamos a la encuesta
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) =>
                        const SurveyScreen(isInitialSetup: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 2. Pantalla de la Encuesta (Ahora también usada para Edición)
// 2. Pantalla de la Encuesta (Ahora también usada para Edición)
class SurveyScreen extends StatefulWidget {
  final bool isInitialSetup; // Determina si es la primera vez o si es edición

  const SurveyScreen({super.key, required this.isInitialSetup});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  // --- Controladores para campos de texto ---

  // Perfil Básico (Existentes)
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _cityController = TextEditingController();

  // Fase 1: Rutina y Clases
  final _wakeUpController = TextEditingController();
  final _sleepController = TextEditingController();
  final _classesInfoController = TextEditingController();
  final _examsInfoController = TextEditingController();
  final _extracurricularInfoController = TextEditingController();

  // Fase 1: Pagos y Finanzas
  final _waterPaymentController = TextEditingController();
  final _electricPaymentController = TextEditingController();
  final _internetPaymentController = TextEditingController();
  final _phonePaymentController = TextEditingController();
  final _rentPaymentController = TextEditingController();
  final _creditCardPaymentController = TextEditingController();
  final _otherPaymentsController = TextEditingController();

  // Fase 1: Cumpleaños
  final _partnerBirthdayController = TextEditingController();
  final _familyBirthdaysController = TextEditingController();
  final _friendBirthdaysController = TextEditingController();

  // Fase 1: Preferencias
  final _reminderAdvanceTimeController = TextEditingController();

  // --- Variables de estado para Switches (Sí/No) ---

  // Rutina
  bool _hasClasses = false;
  bool _hasExams = false;
  bool _hasExtracurricular = false;

  // Finanzas
  bool _wantsPaymentReminders = false;
  bool _hasCreditCard = false;

  // Cumpleaños
  bool _hasPartner = false;
  bool _wantsFriendBirthdays = false;

  // Preferencias
  bool _wantsWeeklyAgenda = false;

  // Estado de carga
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Siempre cargamos datos. Si es setup inicial, estarán vacíos.
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Perfil Básico
      _nameController.text = prefs.getString('userName') ?? '';
      _occupationController.text = prefs.getString('userOccupation') ?? '';
      _cityController.text = prefs.getString('userCity') ?? '';

      // Rutina
      _wakeUpController.text = prefs.getString('userWakeUp') ?? '';
      _sleepController.text = prefs.getString('userSleep') ?? '';
      _hasClasses = prefs.getBool('userHasClasses') ?? false;
      _classesInfoController.text = prefs.getString('userClassesInfo') ?? '';
      _hasExams = prefs.getBool('userHasExams') ?? false;
      _examsInfoController.text = prefs.getString('userExamsInfo') ?? '';
      _hasExtracurricular = prefs.getBool('userHasExtracurricular') ?? false;
      _extracurricularInfoController.text =
          prefs.getString('userExtracurricularInfo') ?? '';

      // Finanzas
      _wantsPaymentReminders =
          prefs.getBool('userWantsPaymentReminders') ?? false;
      _waterPaymentController.text = prefs.getString('userWaterPayment') ?? '';
      _electricPaymentController.text =
          prefs.getString('userElectricPayment') ?? '';
      _internetPaymentController.text =
          prefs.getString('userInternetPayment') ?? '';
      _phonePaymentController.text = prefs.getString('userPhonePayment') ?? '';
      _rentPaymentController.text = prefs.getString('userRentPayment') ?? '';
      _hasCreditCard = prefs.getBool('userHasCreditCard') ?? false;
      _creditCardPaymentController.text =
          prefs.getString('userCreditCardPayment') ?? '';
      _otherPaymentsController.text =
          prefs.getString('userOtherPayments') ?? '';

      // Cumpleaños
      _hasPartner = prefs.getBool('userHasPartner') ?? false;
      _partnerBirthdayController.text =
          prefs.getString('userPartnerBirthday') ?? '';
      _familyBirthdaysController.text =
          prefs.getString('userFamilyBirthdays') ?? '';
      _wantsFriendBirthdays =
          prefs.getBool('userWantsFriendBirthdays') ?? false;
      _friendBirthdaysController.text =
          prefs.getString('userFriendBirthdays') ?? '';

      // Preferencias
      _reminderAdvanceTimeController.text =
          prefs.getString('userReminderAdvance') ?? '1 día antes';
      _wantsWeeklyAgenda = prefs.getBool('userWantsWeeklyAgenda') ?? false;

      _isLoading = false;
    });
  }

  // Función para guardar los datos y marcar la encuesta como completada
  Future<void> _saveSurvey() async {
    final prefs = await SharedPreferences.getInstance();

    // Perfil Básico
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userOccupation', _occupationController.text);
    await prefs.setString('userCity', _cityController.text);

    // Rutina
    await prefs.setString('userWakeUp', _wakeUpController.text);
    await prefs.setString('userSleep', _sleepController.text);
    await prefs.setBool('userHasClasses', _hasClasses);
    await prefs.setString('userClassesInfo', _classesInfoController.text);
    await prefs.setBool('userHasExams', _hasExams);
    await prefs.setString('userExamsInfo', _examsInfoController.text);
    await prefs.setBool('userHasExtracurricular', _hasExtracurricular);
    await prefs.setString(
      'userExtracurricularInfo',
      _extracurricularInfoController.text,
    );

    // Finanzas
    await prefs.setBool('userWantsPaymentReminders', _wantsPaymentReminders);
    await prefs.setString('userWaterPayment', _waterPaymentController.text);
    await prefs.setString(
      'userElectricPayment',
      _electricPaymentController.text,
    );
    await prefs.setString(
      'userInternetPayment',
      _internetPaymentController.text,
    );
    await prefs.setString('userPhonePayment', _phonePaymentController.text);
    await prefs.setString('userRentPayment', _rentPaymentController.text);
    await prefs.setBool('userHasCreditCard', _hasCreditCard);
    await prefs.setString(
      'userCreditCardPayment',
      _creditCardPaymentController.text,
    );
    await prefs.setString('userOtherPayments', _otherPaymentsController.text);

    // Cumpleaños
    await prefs.setBool('userHasPartner', _hasPartner);
    await prefs.setString(
      'userPartnerBirthday',
      _partnerBirthdayController.text,
    );
    await prefs.setString(
      'userFamilyBirthdays',
      _familyBirthdaysController.text,
    );
    await prefs.setBool('userWantsFriendBirthdays', _wantsFriendBirthdays);
    await prefs.setString(
      'userFriendBirthdays',
      _friendBirthdaysController.text,
    );

    // Preferencias
    await prefs.setString(
      'userReminderAdvance',
      _reminderAdvanceTimeController.text,
    );
    await prefs.setBool('userWantsWeeklyAgenda', _wantsWeeklyAgenda);

    // --- ¡Paso Clave! ---
    // Marcar la encuesta como completada (solo la primera vez)
    if (widget.isInitialSetup) {
      await prefs.setBool('isSurveyCompleted', true);
    }

    // --- ¡Paso Clave! ---
    // Aquí llamamos al servicio para generar los recordatorios
    // basados en las respuestas de la encuesta.
    try {
      if (widget.isInitialSetup) {
        final reminderService = AutoReminderService(notificationService);
        await reminderService.generateAutoReminders();
      }
    } catch (e) {
      // Si algo falla al generar recordatorios, no bloqueamos al usuario.
      // Simplemente imprimimos el error en la consola para depuración.
      print('--- ERROR AL GENERAR RECORDATORIOS AUTOMÁTICOS ---');
      print(e.toString());
      print('---------------------------------------------------');
    }
    if (context.mounted) {
      // Si es setup inicial, vamos al HomeScreen.
      // Si es edición (desde Settings), simplemente cerramos esta pantalla.
      if (widget.isInitialSetup) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      } else {
        // Estamos en modo edición, así que volvemos a la pantalla anterior (Settings)
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    // Limpiamos todos los controladores
    _nameController.dispose();
    _occupationController.dispose();
    _cityController.dispose();
    _wakeUpController.dispose();
    _sleepController.dispose();
    _classesInfoController.dispose();
    _examsInfoController.dispose();
    _extracurricularInfoController.dispose();
    _waterPaymentController.dispose();
    _electricPaymentController.dispose();
    _internetPaymentController.dispose();
    _phonePaymentController.dispose();
    _rentPaymentController.dispose();
    _creditCardPaymentController.dispose();
    _otherPaymentsController.dispose();
    _partnerBirthdayController.dispose();
    _familyBirthdaysController.dispose();
    _friendBirthdaysController.dispose();
    _reminderAdvanceTimeController.dispose();
    super.dispose();
  }

  // --- Widgets de UI ---

  // Widget auxiliar para los encabezados de sección
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  // Widget auxiliar para los campos de texto
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    String hint = '',
    bool isMultiline = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint),
        maxLines: isMultiline ? null : 1,
      ),
    );
  }

  // Widget auxiliar para los Switches
  Widget _buildSwitch(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      activeColor: Theme.of(context).colorScheme.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup
              ? 'Configuración Inicial'
              : 'Editar Información',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.isInitialSetup
                  ? 'Cuéntanos sobre ti para personalizar a Auri'
                  : 'Actualiza tu perfil',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // --- SECCIÓN: PERFIL BÁSICO ---
            _buildSectionHeader('Tu Perfil'),
            _buildTextField(_nameController, '¿Cómo te llamas?'),
            _buildTextField(
              _occupationController,
              '¿A qué te dedicas?',
              hint: 'Ej. Estudiante, Diseñador',
            ),
            _buildTextField(
              _cityController,
              '¿En qué ciudad vives?',
              hint: 'Ej. San José, Madrid',
            ),

            // --- SECCIÓN: RUTINA Y CLASES ---
            _buildSectionHeader('Rutina y Clases'),
            _buildTextField(
              _wakeUpController,
              '¿A qué hora sueles despertarte?',
            ),
            _buildTextField(
              _sleepController,
              '¿A qué hora sueles irte a dormir?',
            ),
            _buildSwitch('¿Tienes clases actualmente?', _hasClasses, (val) {
              setState(() => _hasClasses = val);
            }),
            if (_hasClasses)
              _buildTextField(
                _classesInfoController,
                'Indica tus clases',
                hint: 'Ej. Cálculo (Lunes 9am), Inglés (Martes 2pm)',
                isMultiline: true,
              ),
            _buildSwitch('¿Tienes exámenes programados?', _hasExams, (val) {
              setState(() => _hasExams = val);
            }),
            if (_hasExams)
              _buildTextField(
                _examsInfoController,
                'Indica tus exámenes',
                hint: 'Ej. Examen de Cálculo (15/Nov 10am)',
                isMultiline: true,
              ),
            _buildSwitch(
              '¿Tienes actividades extracurriculares?',
              _hasExtracurricular,
              (val) {
                setState(() => _hasExtracurricular = val);
              },
            ),
            if (_hasExtracurricular)
              _buildTextField(
                _extracurricularInfoController,
                'Indica tus actividades',
                hint: 'Ej. Gym (Lunes, Miércoles 6pm)',
                isMultiline: true,
              ),

            // --- SECCIÓN: PAGOS Y FINANZAS ---
            _buildSectionHeader('Pagos y Finanzas'),
            _buildSwitch(
              '¿Deseas que Auri te recuerde tus pagos mensuales?',
              _wantsPaymentReminders,
              (val) {
                setState(() => _wantsPaymentReminders = val);
              },
            ),
            if (_wantsPaymentReminders) ...[
              _buildTextField(
                _waterPaymentController,
                'Fecha de pago del agua',
                hint: 'Ej. 15 de cada mes',
              ),
              _buildTextField(
                _electricPaymentController,
                'Fecha de pago de la luz',
                hint: 'Ej. 10 de cada mes',
              ),
              _buildTextField(
                _internetPaymentController,
                'Fecha de pago del internet',
              ),
              _buildTextField(
                _phonePaymentController,
                'Fecha de pago del teléfono/celular',
              ),
              _buildTextField(
                _rentPaymentController,
                'Fecha de pago de renta/vivienda',
              ),
              _buildSwitch('¿Tienes tarjeta de crédito?', _hasCreditCard, (
                val,
              ) {
                setState(() => _hasCreditCard = val);
              }),
              if (_hasCreditCard)
                _buildTextField(
                  _creditCardPaymentController,
                  'Fecha límite de pago de tarjeta',
                ),
              _buildTextField(
                _otherPaymentsController,
                'Otros pagos o suscripciones',
                hint: 'Ej. Netflix (día 5), Spotify (día 12)',
                isMultiline: true,
              ),
            ],

            // --- SECCIÓN: CUMPLEAÑOS ---
            _buildSectionHeader('Cumpleaños y Fechas'),
            _buildSwitch('¿Tienes pareja actualmente?', _hasPartner, (val) {
              setState(() => _hasPartner = val);
            }),
            if (_hasPartner)
              _buildTextField(
                _partnerBirthdayController,
                'Fecha de cumpleaños de tu pareja',
              ),
            _buildTextField(
              _familyBirthdaysController,
              'Cumpleaños de familiares (opcional)',
              hint: 'Ej. Mamá (10/Ene), Papá (20/Feb)',
              isMultiline: true,
            ),
            _buildSwitch(
              '¿Recordar cumpleaños de amigos?',
              _wantsFriendBirthdays,
              (val) {
                setState(() => _wantsFriendBirthdays = val);
              },
            ),
            if (_wantsFriendBirthdays)
              _buildTextField(
                _friendBirthdaysController,
                'Amigos importantes',
                hint: 'Ej. Juan (5/Marzo), María (12/Abril)',
                isMultiline: true,
              ),

            // --- SECCIÓN: PREFERENCIAS ---
            _buildSectionHeader('Preferencias de Avisos'),
            _buildTextField(
              _reminderAdvanceTimeController,
              '¿Con cuánta anticipación avisarte?',
              hint: 'Ej. 10 min, 1 hora, 1 día antes',
            ),
            _buildSwitch(
              '¿Generar agenda semanal automática?',
              _wantsWeeklyAgenda,
              (val) {
                setState(() => _wantsWeeklyAgenda = val);
              },
            ),

            // --- BOTÓN DE GUARDAR ---
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed:
                  _saveSurvey, // Cambiado de _completeSurvey a _saveSurvey
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: Text(
                widget.isInitialSetup ? 'Guardar y Entrar' : 'Guardar Cambios',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 3. Pantalla de Configuración
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // Función para reiniciar la configuración y reiniciar la app
  Future<void> _resetSetup(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // limpia todo (más simple)
    await notificationService.cancelAllNotifications();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MyApp(isSurveyCompleted: false),
        ),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Auri')),
      body: ListView(
        children: [
          // Opción 1: Editar Perfil
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF00BCD4)),
            title: const Text('Editar mi Información Personal'),
            subtitle: const Text('Nombre, ciudad y ocupación'),
            onTap: () {
              // Navegar a SurveyScreen en modo edición
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      const SurveyScreen(isInitialSetup: false),
                ),
              );
            },
          ),

          // Opción 2: Reiniciar Configuración
          ListTile(
            leading: const Icon(Icons.refresh, color: Colors.redAccent),
            title: const Text('Reiniciar Configuración Inicial'),
            subtitle: const Text(
              'Volverás a la pantalla de bienvenida y se perderán todos los datos.',
            ),
            onTap: () => _showResetDialog(context),
          ),
        ],
      ),
    );
  }

  // Diálogo de confirmación para reiniciar
  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('¿Estás seguro?'),
          content: const Text(
            'Esto borrará todos tus datos guardados y te llevará a la pantalla de bienvenida.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text(
                'Reiniciar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cierra el diálogo
                _resetSetup(context); // Ejecuta el reinicio
              },
            ),
          ],
        );
      },
    );
  }
}

// 4. Pantalla Principal (El "Dashboard" de Auri)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userCity = '';
  List<Reminder> _upcomingReminders = [];

  // Variables para el clima
  final WeatherService _weatherService = WeatherService();

  WeatherModel? _weatherData;
  bool _isWeatherLoading = true;
  String _weatherError = '';

  @override
  void initState() {
    super.initState();
    // Usamos WidgetsBinding.instance.addPostFrameCallback para asegurar que el contexto esté listo
    // antes de llamar a la carga de datos.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  // Función para cargar datos del usuario, clima y recordatorios
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final city = prefs.getString('userCity') ?? '';
    final name = prefs.getString('userName') ?? 'Usuario';

    setState(() {
      _userName = name;
      _userCity = city;
    });

    // 1. Cargar Clima
    await _fetchWeather(city);

    // 2. Cargar Recordatorios
    await _loadUpcomingReminders();
  }

  // Carga y filtra los próximos recordatorios (solo los pendientes)
  Future<void> _loadUpcomingReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? remindersJsonList = prefs.getStringList(
      'remindersList',
    );

    List<Reminder> loadedReminders = [];

    if (remindersJsonList != null) {
      loadedReminders = remindersJsonList
          .map((jsonStr) => Reminder.fromJson(json.decode(jsonStr)))
          .toList();
    }

    // Convertimos a LISTA antes de ordenar
    final List<Reminder> upcoming =
        loadedReminders
            .where((r) => !r.isCompleted && r.dateTime.isAfter(DateTime.now()))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    // Programamos SOLO si no estaba ya programado
    for (final reminder in upcoming) {
      if (!reminder.isScheduled) {
        await notificationService.scheduleReminderNotification(reminder);
        reminder.isScheduled = true;
      }
    }

    setState(() {
      _upcomingReminders = upcoming;
    });
  }

  // Obtiene los datos del clima de la ciudad del usuario
  Future<void> _fetchWeather(String city) async {
    if (city.isEmpty) {
      setState(() {
        _isWeatherLoading = false;
        _weatherError = 'Por favor, configura tu ciudad en los ajustes.';
      });
      return;
    }

    try {
      setState(() {
        _isWeatherLoading = true;
      });
      // ASUMIMOS que getWeather(city) devuelve un WeatherModel
      final weather = await _weatherService.getWeather(city);
      setState(() {
        _weatherData = weather;
        _isWeatherLoading = false;
        _weatherError = '';
      });
    } catch (e) {
      setState(() {
        _isWeatherLoading = false;
        _weatherError = 'No se pudo cargar el clima para $city.';
        _weatherData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Usamos WillPopScope para recargar datos cuando se regresa de Settings o Reminders
    return PopScope(
      canPop: false, // Evita que se cierre la app con el botón de atrás
      onPopInvoked: (didPop) {
        if (!didPop) {
          _loadUserData(); // Recarga los datos al volver
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Auri: Dashboard'),
          backgroundColor: Colors.transparent,
          actions: [
            // Botón de Configuración
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    )
                    .then((_) => _loadUserData());
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. BIENVENIDA ---
              Text(
                'Hola, $_userName',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Tu asistente Auri tiene tu día bajo control.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 25),

              // --- 2. WIDGET DEL CLIMA ---
              if (_isWeatherLoading)
                const Center(child: CircularProgressIndicator())
              else if (_weatherError.isNotEmpty)
                _ErrorCard(message: _weatherError)
              else if (_weatherData != null)
                WeatherDisplay(cityName: _userCity),

              const SizedBox(height: 20),

              // --- 3. WIDGET DE OUTFIT (Depende del clima) ---
              if (_weatherData != null)
                OutfitRecommendationWidget(
                  temperature: _weatherData!.temperature,
                  condition: _weatherData!.mainCondition,
                  // Permite navegar a la página completa de outfits
                  onTap: () {
                    // Navegamos a la página completa de outfits
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => OutfitPage(
                          temperature: _weatherData!.temperature,
                          condition: _weatherData!.mainCondition,
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 25),

              // --- 4. RESUMEN DE RECORDATORIOS ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Próximos Recordatorios',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // ← Previene desbordes
                    ),
                  ),
                  // Botón para ir a la página completa de recordatorios
                  TextButton.icon(
                    icon: const Icon(Icons.alarm),
                    label: const Text('Ver Todos'),
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => const RemindersPage(),
                            ),
                          )
                          .then(
                            (_) => _loadUserData(),
                          ); // Recarga datos al volver
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Mostrar la lista de recordatorios
              if (_upcomingReminders.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30.0),
                    child: Text(
                      '¡No tienes recordatorios pendientes! ✨',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                )
              else
                ..._upcomingReminders.take(3).map((reminder) {
                  return _ReminderTile(
                    reminder: reminder,
                    colorScheme: colorScheme,
                  );
                }).toList(),

              const SizedBox(height: 40),

              // --- 5. MASCOTA AURI Y LLAMADA A LA ACCIÓN ---
              Center(
                child: Column(
                  children: [
                    const SizedBox(
                      width: 100,
                      height: 100,
                      child: AuriVisual(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Auri está lista para ayudarte.',
                      style: TextStyle(
                        color: colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar para mostrar un recordatorio en la lista
class _ReminderTile extends StatelessWidget {
  final Reminder reminder;
  final ColorScheme colorScheme;

  const _ReminderTile({required this.reminder, required this.colorScheme});

  // Convertido a getter para acceder a la fecha/hora sin pasar argumentos.
  String get _formattedDateTime {
    final dt = reminder.dateTime;
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: colorScheme.surface.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.alarm, color: Colors.purpleAccent),
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
          // ⬅️ CORRECCIÓN DE OVERFLOW
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Text(
          // ⬅️ USANDO EL GETTER CORREGIDO
          'Vence: $_formattedDateTime',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white38,
        ),
        onTap: () {
          // Opcional: Navegar a editar o ver detalle del recordatorio
          // ...
        },
      ),
    );
  }
}

// Widget auxiliar para mostrar mensajes de error
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Error: $message',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Widget de Outfit (FALTA CREAR EL ARCHIVO lib/pages/outfit_page.dart)
// Definición temporal de OutfitPage para evitar errores de referencia
class OutfitPage extends StatelessWidget {
  final double temperature;
  final String condition;

  const OutfitPage({
    super.key,
    required this.temperature,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recomendación de Outfit Completa')),
      body: Center(
        child: Text(
          'Outfit para $condition a ${temperature.toStringAsFixed(1)}°C. (Página OutfitPage pendiente)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
    );
  }
}
