import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- FIREBASE ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Importaciones de tus pantallas y base de datos
import 'pantallas/pantalla_informacion.dart';
import 'pantallas/pantalla_micro_tareas.dart';
import 'pantallas/pantalla_logros.dart';
import 'pantallas/pantalla_login.dart';
import 'pantallas/pantalla_perfil.dart';
import 'bd/database.dart';
import 'servicios/notificaciones.dart';
import 'pantallas/pantalla_legal.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- INICIALIZAMOS FIREBASE ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- APAGAMOS EL CACHÉ LOCAL PARA EVITAR CONGELAMIENTOS ---
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );

  await NotificacionesHelper.inicializar();

  runApp(const RetoVerdeApp());
}

class RetoVerdeApp extends StatelessWidget {
  const RetoVerdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reto Verde',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const PantallaLogin(),
    );
  }
}

// --- PANTALLA PRINCIPAL CON NAVEGACIÓN ---
class PantallaNavegacion extends StatefulWidget {
  final Map<String, dynamic> usuarioLogueado;

  const PantallaNavegacion({super.key, required this.usuarioLogueado});

  @override
  State<PantallaNavegacion> createState() => _PantallaNavegacionState();
}

class _PantallaNavegacionState extends State<PantallaNavegacion> {
  int _indiceActual = 0;
  late Map<String, dynamic> _usuarioActual;

  // Lo iniciamos vacío
  List<Map<String, dynamic>> _tareas = [];
  bool _cargando = true; // Pantalla de carga mientras lee Firestore

  @override
  void initState() {
    super.initState();
    _usuarioActual = Map<String, dynamic>.from(widget.usuarioLogueado);
    _cargarTareasDesdeFirestore();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAvisoLegal();
    });
  }

  // --- VERIFICAR LA MEMORIA DEL CELULAR ---
  Future<void> _verificarAvisoLegal() async {
    final prefs = await SharedPreferences.getInstance();
    bool yaAcepto = prefs.getBool('acepto_terminos_reto_verde') ?? false;

    if (!yaAcepto && mounted) {
      _mostrarPopUpLegal(prefs);
    }
  }

  // --- AVISO LEGAL CON CHECKBOX ---
  void _mostrarPopUpLegal(SharedPreferences prefs) {
    bool checkboxValue = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFFF9FAFB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(Icons.gavel, color: Colors.green.shade800),
                    const SizedBox(width: 10),
                    const Text('Aviso Legal', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Al continuar, aceptas que "Reto Verde" es un prototipo académico. Tus datos ahora se guardan de forma segura en la nube (Firebase) para tu cuenta.\n\nAl unirte a una clase, el profesor podrá evaluar tu progreso. Los desarrolladores no se hacen responsables por el uso que se le dé a la plataforma.',
                        textAlign: TextAlign.justify,
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Checkbox(
                            value: checkboxValue,
                            activeColor: Colors.green.shade700,
                            onChanged: (value) {
                              setStateDialog(() => checkboxValue = value!);
                            },
                          ),
                          const Expanded(
                            child: Text('He leído y acepto los términos y condiciones.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: checkboxValue ? Colors.green.shade700 : Colors.grey.shade400,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: checkboxValue
                          ? () async {
                        await prefs.setBool('acepto_terminos_reto_verde', true);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                      }
                          : null,
                      child: const Text('Continuar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // --- LÓGICA DE FIRESTORE PARA TAREAS ---
  Future<void> _cargarTareasDesdeFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('tareas')
          .get()
          .timeout(const Duration(seconds: 10));

      if (snapshot.docs.isEmpty) {
        await _crearTareasIniciales(user.uid);
        return;
      }

      setState(() {
        _tareas = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'titulo': data['titulo'] ?? 'Sin título',
            'descripcion': data['descripcion'] ?? '',
            'completada': data['completada'] ?? false,
            'icono': data['icono'] ?? 'eco',
            'importante': data['importante'] ?? false,
            'evidencia_url': data['evidencia_url'] ?? '',
          };
        }).toList();
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() { _cargando = false; });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar retos: $e'), backgroundColor: Colors.orange)
        );
      }
    }
  }

  // Función auxiliar para las tareas de bienvenida
  Future<void> _crearTareasIniciales(String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance.collection('usuarios').doc(uid).collection('tareas');

    List<Map<String, dynamic>> iniciales = [
      {'titulo': 'Separar residuos', 'descripcion': 'Separa tu basura orgánica e inorgánica.', 'icono': 'reciclaje', 'importante': false, 'completada': false, 'fecha': FieldValue.serverTimestamp()},
      {'titulo': 'Ahorrar agua', 'descripcion': 'Toma una ducha de máximo 5 minutos.', 'icono': 'agua', 'importante': false, 'completada': false, 'fecha': FieldValue.serverTimestamp()},
      {'titulo': 'Reducir plásticos', 'descripcion': 'Lleva una bolsa de tela para tus compras.', 'icono': 'eco', 'importante': false, 'completada': false, 'fecha': FieldValue.serverTimestamp()},
    ];

    for (var tarea in iniciales) {
      batch.set(colRef.doc(), tarea);
    }

    await batch.commit();
    _cargarTareasDesdeFirestore();
  }

  int get _tareasCompletadas => _tareas.where((t) => t["completada"] == true).length;
  final List<String> _titulos = ['Tus Retos Escolares', 'Guías y Reciclaje', 'Tus Logros'];

  // Cambiar estado (Checkbox)
  void _marcarTarea(int index, bool valor) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String idTarea = _tareas[index]['id'];

    setState(() {
      _tareas[index]["completada"] = valor;
    });

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('tareas')
          .doc(idTarea)
          .update({'completada': valor})
          .timeout(const Duration(seconds: 10));

      if (valor == true && _tareasCompletadas == _tareas.length && _tareas.isNotEmpty) {
        _mostrarCelebracionProfesional();
      }
    } catch (e) {
      setState(() {
        _tareas[index]["completada"] = !valor;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error de conexión al marcar reto.')));
      }
    }
  }

  void _mostrarDialogoAgregarTarea() {}
  void _mostrarDialogoEditarTarea(int index, Map<String, dynamic> tarea) {}
  void _eliminarTarea(int index) {}

  // --- FUNCIÓN EMERGENTE: TÉRMINOS Y CONDICIONES ---
  void _mostrarDialogoTerminos() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        bool terminosAceptados = false;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.green.shade700),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('Aviso Legal', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        'Al continuar, aceptas que "Reto Verde" es un prototipo académico. '
                            'Tus datos se guardan en la nube para tu cuenta.\n\n'
                            'La información mostrada tiene fines educativos. Los desarrolladores no se hacen responsables por el uso que se le dé a las guías ni por la exactitud del mapa de reciclaje de terceros.',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  CheckboxListTile(
                    activeColor: Colors.green.shade700,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('He leído y acepto los términos y condiciones.', style: TextStyle(fontSize: 14)),
                    value: terminosAceptados,
                    onChanged: (bool? valor) {
                      setStateDialog(() {
                        terminosAceptados = valor ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: terminosAceptados
                        ? () => Navigator.pop(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12)
                    ),
                    child: Text(
                        'Continuar',
                        style: TextStyle(color: terminosAceptados ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- FUNCIÓN PARA UNIRSE A UNA CLASE (ACTUALIZADA CON CLONACIÓN INTELIGENTE) ---
  void _mostrarDialogoUnirseClase() {
    final codigoController = TextEditingController();
    bool buscando = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Unirse a una Clase'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ingresa el código proporcionado por tu profesor (Ej. VERDE-1234):', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Código de clase',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade600),
                  onPressed: buscando ? null : () async {
                    if (codigoController.text.trim().isEmpty) return;

                    setStateDialog(() => buscando = true);

                    try {
                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('clases')
                          .where('codigo', isEqualTo: codigoController.text.trim().toUpperCase())
                          .get();

                      if (querySnapshot.docs.isEmpty) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código inválido o clase no encontrada.'), backgroundColor: Colors.red)
                        );
                        setStateDialog(() => buscando = false);
                        return;
                      }

                      final claseId = querySnapshot.docs.first.id;
                      final nombreClase = querySnapshot.docs.first.data()['nombre_clase'];

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        final miTareasRef = FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(user.uid)
                            .collection('tareas');

                        // 1. Limpieza absoluta de las tareas base por defecto
                        final misTareasViejas = await miTareasRef.get();
                        final batchLimpieza = FirebaseFirestore.instance.batch();
                        for (var doc in misTareasViejas.docs) {
                          batchLimpieza.delete(doc.reference);
                        }
                        await batchLimpieza.commit();

                        // 2. BUSCADOR DE RETOS EXISTENTES: Validamos si ya hay alumnos inscritos en esa aula virtual
                        final otrosAlumnos = await FirebaseFirestore.instance
                            .collection('usuarios')
                            .where('clase_id', isEqualTo: claseId)
                            .limit(1)
                            .get();

                        if (otrosAlumnos.docs.isNotEmpty) {
                          // Si hay otro alumno, clonamos la lista exacta de retos que el profesor ya asignó
                          final otroAlumnoId = otrosAlumnos.docs.first.id;
                          final tareasDelOtro = await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(otroAlumnoId)
                              .collection('tareas')
                              .get();

                          final batchClonacion = FirebaseFirestore.instance.batch();
                          for (var docTarea in tareasDelOtro.docs) {
                            final dataTarea = docTarea.data();

                            // Regla de oro: El nuevo alumno arranca limpio (sin completar y sin fotos viejas)
                            dataTarea['completada'] = false;
                            dataTarea['evidencia_url'] = '';
                            dataTarea['fecha'] = FieldValue.serverTimestamp();

                            batchClonacion.set(miTareasRef.doc(), dataTarea);
                          }
                          await batchClonacion.commit();
                        } else {
                          // Si es el primer alumno en entrar a la clase, le cargamos el set inicial base
                          final batchInicial = FirebaseFirestore.instance.batch();
                          List<Map<String, dynamic>> iniciales = [
                            {'titulo': 'Separar residuos', 'descripcion': 'Separa tu basura orgánica e inorgánica.', 'icono': 'reciclaje', 'importante': false, 'completada': false, 'fecha': FieldValue.serverTimestamp()},
                            {'titulo': 'Ahorrar agua', 'descripcion': 'Toma una ducha de máximo 5 minutos.', 'icono': 'agua', 'importante': false, 'completada': false, 'fecha': FieldValue.serverTimestamp()},
                            {'titulo': 'Reducir plásticos', 'descripcion': 'Lleva una bolsa de tela para tus compras.', 'icono': 'eco', 'importante': false, 'completada': false, 'fecha': FieldValue.serverTimestamp()},
                          ];
                          for (var tarea in iniciales) {
                            batchInicial.set(miTareasRef.doc(), tarea);
                          }
                          await batchInicial.commit();
                        }

                        // 3. Vinculación oficial del alumno con el Aula
                        await FirebaseFirestore.instance
                            .collection('usuarios')
                            .doc(user.uid)
                            .update({'clase_id': claseId});

                        setState(() {
                          _usuarioActual['clase_id'] = claseId;
                        });

                        // 4. Forzamos la actualización inmediata del muro de tareas sin desloguear
                        await _cargarTareasDesdeFirestore();
                      }

                      if (!context.mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('¡Te has unido a $nombreClase!'), backgroundColor: Colors.green)
                      );

                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.orange)
                      );
                      setStateDialog(() => buscando = false);
                    }
                  },
                  child: buscando
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Unirme', style: TextStyle(color: Colors.white)),
                )
              ],
            );
          }
      ),
    );
  }

  // Notificación de celebración
  void _mostrarCelebracionProfesional() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.green.shade800,
      elevation: 6,
      duration: const Duration(seconds: 4),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events, color: Colors.orange, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¡Retos Completados!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text('Desbloqueaste la insignia Semilla.', style: TextStyle(fontSize: 13, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'VER LOGRO',
        textColor: Colors.greenAccent,
        onPressed: () { setState(() { _indiceActual = 2; }); },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // --- FUNCIÓN PARA VER EL ARTÍCULO EDUCATIVO ---
  void _mostrarDetalleMaterial(Map<String, dynamic> material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Artículo Educativo'),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Icon(Icons.delete_outline, size: 80, color: Colors.green)),
                const SizedBox(height: 20),
                Text(
                  material['titulo'] ?? 'Sin título',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  material['descripcion'] ?? 'Sin descripción.',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.justify,
                ),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.copyright, size: 18, color: Colors.grey),
                          const SizedBox(width: 8),
                          const Text('Créditos y Fuente', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text('Autor/Medio: ${material['fuente'] ?? 'Desconocido'}'),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final String link = material['url'] ?? '';

                            if (link.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Este material no tiene un enlace válido.'),
                                    backgroundColor: Colors.orange,
                                  )
                              );
                              return;
                            }

                            try {
                              final Uri url = Uri.parse(link);
                              if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                throw Exception('No se pudo abrir $link');
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error al abrir el enlace. Verifica que empiece con http:// o https://'),
                                    backgroundColor: Colors.red,
                                  )
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Ver contenido original'),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirMapaReciclaje() async {
    const String query = "centros de reciclaje";
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    try {
      if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo abrir el mapa');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps.'), backgroundColor: Colors.red)
      );
    }
  }

  // --- FUNCIÓN PARA SALIR DE LA CLASE ---
  void _salirDeClase(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.red.shade700),
            const SizedBox(width: 10),
            const Text('Salir de la clase', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: const Text('¿Estás seguro de que quieres salir? Perderás tu progreso y los retos asignados de esta clase actual.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(ctx);

              try {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Saliendo de la clase...'))
                );

                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final tareasSnap = await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.uid)
                    .collection('tareas')
                    .get();

                for (var doc in tareasSnap.docs) {
                  await doc.reference.delete();
                }

                await FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(user.uid)
                    .update({'clase_id': ''});

                if (mounted) {
                  setState(() {
                    _usuarioActual['clase_id'] = '';
                  });
                  _cargarTareasDesdeFirestore();
                }

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Has salido de la clase exitosamente.'), backgroundColor: Colors.orange)
                );
              } catch (e) {
                debugPrint('Error al salir: $e');
              }
            },
            child: const Text('Sí, Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- FUNCIÓN: ALERTA PARA NO SALIR POR ACCIDENTE ---
  Future<bool?> _mostrarAlertaDeSalida() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.exit_to_app, color: Colors.green.shade700),
            const SizedBox(width: 10),
            const Text('¿Salir de la App?'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas salir de Reto Verde? Tu sesión seguirá activa para la próxima vez.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cierra la alerta, no la app
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () => Navigator.of(context).pop(true), // Confirma la salida
            child: const Text('Salir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.green)),
      );
    }

    final List<Widget> pantallas = [
      // --- 1. PANTALLA DE TAREAS ---
      PantallaMicroTareas(
        tareas: _tareas,
        onTareaCambiada: _marcarTarea,
        claseId: _usuarioActual['clase_id'] ?? '',
        onAgregarTarea: () {},
        onEditarTarea: (index, tarea) {},
        onEliminarTarea: (index) {},
        onRefresh: _cargarTareasDesdeFirestore,
      ),

      // --- 2. PANTALLA DE INFORMACIÓN ---
      PantallaInformacion(
        claseId: _usuarioActual['clase_id'] ?? '',
      ),

      // --- 3. PANTALLA DE LOGROS ---
      PantallaLogros(
        tareasCompletadas: _tareasCompletadas,
        claseId: _usuarioActual['clase_id'] ?? '',
      ),
    ];

    // --- ENVOLVEMOS EL SCAFFOLD EN UN POPSCOPE ---
    return PopScope(
      canPop: false, // Bloquea el botón de "atrás"
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        // Mostramos la alerta
        final bool? quiereSalir = await _mostrarAlertaDeSalida();

        if (quiereSalir == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titulos[_indiceActual], style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          elevation: 2,
        ),

        // --- MENÚ LATERAL (DRAWER) ---
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: Colors.green.shade700),
                accountName: Text(
                    _usuarioActual['name'] ?? 'Usuario',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)
                ),
                accountEmail: Text(
                    _usuarioActual['username'] != null
                        ? '@${_usuarioActual['username']}'
                        : (_usuarioActual['user'] ?? '')
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (_usuarioActual['foto_base64'] != null && _usuarioActual['foto_base64'].toString().isNotEmpty)
                      ? MemoryImage(base64Decode(_usuarioActual['foto_base64']))
                      : null,
                  child: (_usuarioActual['foto_base64'] == null || _usuarioActual['foto_base64'].toString().isEmpty)
                      ? Icon(Icons.person, size: 40, color: Colors.green.shade700)
                      : null,
                ),
              ),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Mi Perfil y Foto'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PantallaPerfil(
                          usuario: _usuarioActual,
                          onPerfilActualizado: (usuarioActualizado) {
                            setState(() {
                              _usuarioActual = usuarioActualizado;
                            });
                          },
                        )
                    ),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.group_add, color: Colors.green),
                title: const Text('Unirme a una clase'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoUnirseClase();
                },
              ),

              ListTile(
                leading: const Icon(Icons.gavel_rounded, color: Colors.grey),
                title: const Text('Legal y Privacidad'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PantallaLegal()),
                  );
                },
              ),

              // --- EL BOTÓN DE SALIR DE CLASE ---
              if (_usuarioActual['clase_id'] != null && _usuarioActual['clase_id'].toString().isNotEmpty) ...[
                const Divider(),
                ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.logout, color: Colors.red.shade600),
                    ),
                    title: Text('Salir de la Clase', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      _salirDeClase(context);
                    }
                ),
              ],

              const Divider(),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const PantallaLogin())
                  );
                },
              ),
            ],
          ),
        ),

        body: pantallas[_indiceActual],

        // --- MENÚ INFERIOR ---
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _indiceActual,
          onTap: (index) {
            setState(() { _indiceActual = index; });
          },
          selectedItemColor: Colors.green.shade700,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), activeIcon: Icon(Icons.check_circle), label: 'Tareas'),
            BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Información'),
            BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Logros'),
          ],
        ),
      ),
    );
  }
}