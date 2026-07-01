import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PantallaMicroTareas extends StatefulWidget {
  final List<Map<String, dynamic>> tareas;
  final Function(int, bool) onTareaCambiada;
  final String claseId;
  final VoidCallback onAgregarTarea;
  final Function(int, Map<String, dynamic>) onEditarTarea;
  final Function(int) onEliminarTarea;
  final Future<void> Function() onRefresh;

  const PantallaMicroTareas({
    super.key,
    required this.tareas,
    required this.onTareaCambiada,
    required this.claseId,
    required this.onAgregarTarea,
    required this.onEditarTarea,
    required this.onEliminarTarea,
    required this.onRefresh,
  });

  @override
  State<PantallaMicroTareas> createState() => _PantallaMicroTareasState();
}

class _PantallaMicroTareasState extends State<PantallaMicroTareas> {
  bool _subiendoEvidencia = false;
  int _indiceSubiendo = -1;

  double get _progreso {
    if (widget.tareas.isEmpty) return 0.0;
    int completadas = widget.tareas.where((t) => t["completada"] == true).length;
    return completadas / widget.tareas.length;
  }

  IconData _obtenerIcono(String? codigo) {
    switch (codigo) {
      case 'agua': return Icons.water_drop;
      case 'energia': return Icons.bolt;
      case 'reciclaje': return Icons.recycling;
      case 'hogar': return Icons.home;
      case 'eco':
      default: return Icons.eco;
    }
  }

  Color _obtenerColorIcono(String? codigo) {
    switch (codigo) {
      case 'agua': return Colors.blue;
      case 'energia': return Colors.amber;
      case 'reciclaje': return Colors.teal;
      case 'hogar': return Colors.orange;
      case 'eco':
      default: return Colors.green;
    }
  }

  // --- FUNCIÓN TOMAR FOTO Y SUBIR A FIREBASE STORAGE ---
  Future<void> _procesarRetoImportante(BuildContext context, int index, Map<String, dynamic> tarea) async {
    final ImagePicker picker = ImagePicker();

    // 1. Preguntamos de dónde sacar la foto
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700), const SizedBox(width: 8), const Text('Reto Importante')]),
        content: const Text('Tu profesor requiere una evidencia fotográfica para validar este reto. ¿De dónde quieres obtener la imagen?'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.photo_library, color: Colors.blue),
            label: const Text('Galería', style: TextStyle(color: Colors.blue)),
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            label: const Text('Cámara', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    );

    if (source == null) return; // Si canceló el cuadro

    // 2. Abrimos cámara o galería
    final XFile? image = await picker.pickImage(source: source, imageQuality: 50);
    if (image == null) return;

    // ruedita de carga
    setState(() {
      _subiendoEvidencia = true;
      _indiceSubiendo = index;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Error de sesión");

      File file = File(image.path);

      // 3. Subimos al disco duro de Firebase Storage
      String pathStorage = 'evidencias/${user.uid}/${tarea['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(pathStorage);
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();

      // 4. Guardamos el link en la Base de Datos
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('tareas')
          .doc(tarea['id'])
          .update({'evidencia_url': downloadUrl});

      // 5. Marcamos el reto como completado
      widget.onTareaCambiada(index, true);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidencia subida. ¡Reto completado!'), backgroundColor: Colors.green));

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _subiendoEvidencia = false;
          _indiceSubiendo = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // --- CABECERA DE PROGRESO ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 25),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 5))]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.claseId.isNotEmpty)
                  StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('clases').doc(widget.claseId).snapshots(),
                      builder: (context, snapshot) {
                        String nombreClase = 'Cargando clase...';
                        if (snapshot.hasData && snapshot.data!.data() != null) {
                          nombreClase = (snapshot.data!.data() as Map<String, dynamic>)['nombre_clase'] ?? 'Clase sin nombre';
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade200)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.school, size: 16, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(nombreClase, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }
                  ),

                const Text('Progreso de tus Retos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _progreso,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${(_progreso * 100).toInt()}% completado', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                    Text('${widget.tareas.where((t) => t["completada"] == true).length} de ${widget.tareas.length} retos', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // --- LISTA DE RETOS ---
          Expanded(
            child: widget.tareas.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.assignment_outlined, size: 60, color: Colors.grey.shade300), const SizedBox(height: 15), Text('Tu profesor aún no ha asignado retos.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]))
                : RefreshIndicator(
              color: Colors.green,
              onRefresh: widget.onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: widget.tareas.length,
                itemBuilder: (context, index) {
                  final tarea = widget.tareas[index];
                  bool estaCompletada = tarea["completada"] == true;
                  bool esImportante = tarea["importante"] == true;

                  String codigoIcono = tarea["icono"] ?? 'eco';
                  IconData iconData = _obtenerIcono(codigoIcono);
                  Color colorIcono = _obtenerColorIcono(codigoIcono);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    decoration: BoxDecoration(
                        color: estaCompletada ? Colors.green.shade50.withOpacity(0.3) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: estaCompletada ? Colors.green.shade200 : Colors.grey.shade200, width: estaCompletada ? 1.5 : 1),
                        boxShadow: estaCompletada ? [] : [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 3))]
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: estaCompletada ? Colors.grey.shade100 : colorIcono.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                        child: Icon(iconData, color: estaCompletada ? Colors.grey.shade400 : colorIcono, size: 26),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              tarea["titulo"] ?? '',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: estaCompletada ? Colors.grey.shade500 : Colors.black87, decoration: estaCompletada ? TextDecoration.lineThrough : TextDecoration.none),
                            ),
                          ),
                          // Etiqueta visual de reto IMPORTANTE
                          if (esImportante && !estaCompletada)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.red.shade100)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, size: 10, color: Colors.red.shade700),
                                  const SizedBox(width: 3),
                                  Text('EVIDENCIA', style: TextStyle(color: Colors.red.shade800, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                ],
                              ),
                            )
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(tarea["descripcion"] ?? '', style: TextStyle(color: estaCompletada ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.3)),
                      ),

                      // --- BOTÓN DE COMPLETAR ---
                      trailing: (_subiendoEvidencia && _indiceSubiendo == index)
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                          : InkWell(
                        onTap: () {
                          if (!estaCompletada && esImportante) {
                            // Si es importante y no está terminada, obligamos a subir foto
                            _procesarRetoImportante(context, index, tarea);
                          } else {
                            // Si es normal o ya estaba completada (y quiere desmarcarla)
                            widget.onTareaCambiada(index, !estaCompletada);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: estaCompletada ? Colors.green : Colors.transparent,
                            border: Border.all(color: estaCompletada ? Colors.green : Colors.grey.shade400, width: 2),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(Icons.check, size: 18, color: estaCompletada ? Colors.white : Colors.transparent),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}