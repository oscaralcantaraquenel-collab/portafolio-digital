import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'progreso_alumno.dart';
import 'pantalla_historial_retos.dart';
import 'pantalla_informacion.dart';

class DetalleClaseDocente extends StatelessWidget {
  final String claseId;
  final String nombreClase;

  const DetalleClaseDocente({super.key, required this.claseId, required this.nombreClase});

  Map<String, dynamic> _obtenerRecompensa(int completadas, Map<String, dynamic> config) {
    if (completadas >= 10) {
      return {'nombre': 'Guardián Verde', 'puntos': config['arbol'] ?? 0.0, 'bgColor': Colors.amber.shade100, 'iconColor': Colors.amber.shade700, 'borde': Colors.amber, 'icono': Icons.workspace_premium};
    } else if (completadas >= 6) {
      return {'nombre': 'Brote', 'puntos': config['brote'] ?? 0.0, 'bgColor': Colors.blueGrey.shade50, 'iconColor': Colors.blueGrey.shade600, 'borde': Colors.blueGrey.shade300, 'icono': Icons.military_tech};
    } else if (completadas >= 3) {
      return {'nombre': 'Semilla', 'puntos': config['semilla'] ?? 0.0, 'bgColor': Colors.brown.shade50, 'iconColor': Colors.brown.shade400, 'borde': Colors.brown.shade300, 'icono': Icons.emoji_events};
    }
    return {'nombre': 'Sin Insignia', 'puntos': 0.0, 'bgColor': Colors.white, 'iconColor': Colors.grey.shade400, 'borde': Colors.grey.shade200, 'icono': Icons.star_border};
  }

  void _mostrarDialogoConfiguracion(BuildContext context, Map<String, dynamic> actual) {
    final semillaController = TextEditingController(text: (actual['semilla'] ?? 0.0).toString());
    final broteController = TextEditingController(text: (actual['brote'] ?? 0.0).toString());
    final arbolController = TextEditingController(text: (actual['arbol'] ?? 0.0).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [Icon(Icons.settings, color: Colors.green.shade800), const SizedBox(width: 10), const Text('Décimas Extra', style: TextStyle(fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Define el valor de cada insignia para la calificación final:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(controller: semillaController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Semilla (3 retos)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.eco, color: Colors.brown))),
            const SizedBox(height: 10),
            TextField(controller: broteController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Brote (6 retos)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.grass, color: Colors.blueGrey))),
            const SizedBox(height: 10),
            TextField(controller: arbolController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Guardián (10 retos)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), prefixIcon: const Icon(Icons.forest, color: Colors.amber))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('clases').doc(claseId).update({
                'config_recompensas': {
                  'semilla': double.tryParse(semillaController.text) ?? 0.0,
                  'brote': double.tryParse(broteController.text) ?? 0.0,
                  'arbol': double.tryParse(arbolController.text) ?? 0.0,
                }
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configuración guardada'), backgroundColor: Colors.green));
            },
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  void _mostrarDialogoAsignarReto(BuildContext context) {
    final tituloController = TextEditingController();
    final descController = TextEditingController();

    final List<Map<String, dynamic>> iconosDisponibles = [
      {'codigo': 'eco', 'icono': Icons.eco, 'color': Colors.green},
      {'codigo': 'agua', 'icono': Icons.water_drop, 'color': Colors.blue},
      {'codigo': 'energia', 'icono': Icons.bolt, 'color': Colors.amber},
      {'codigo': 'reciclaje', 'icono': Icons.recycling, 'color': Colors.teal},
      {'codigo': 'hogar', 'icono': Icons.home, 'color': Colors.orange},
    ];
    String iconoSeleccionado = 'eco';
    bool esImportante = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [Icon(Icons.add_task, color: Colors.orange.shade700), const SizedBox(width: 10), const Text('Nuevo Reto', style: TextStyle(fontWeight: FontWeight.bold))]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: tituloController, decoration: InputDecoration(labelText: 'Título del reto', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 10),
                    TextField(controller: descController, maxLines: 2, decoration: InputDecoration(labelText: 'Descripción', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 15),

                    SwitchListTile(
                      title: const Text('Reto Importante', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: const Text('Obliga al alumno a subir una foto de evidencia.', style: TextStyle(fontSize: 11)),
                      activeColor: Colors.red,
                      value: esImportante,
                      onChanged: (value) => setStateDialog(() => esImportante = value),
                    ),
                    const SizedBox(height: 10),

                    const Text('Elige una categoría:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: iconosDisponibles.map((item) {
                        bool isSelected = iconoSeleccionado == item['codigo'];
                        return GestureDetector(
                          onTap: () => setStateDialog(() => iconoSeleccionado = item['codigo']),
                          child: CircleAvatar(
                            backgroundColor: isSelected ? item['color'].withOpacity(0.2) : Colors.grey.shade100,
                            radius: 20,
                            child: Icon(item['icono'], color: isSelected ? item['color'] : Colors.grey, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () async {
                    if (tituloController.text.isEmpty) return;

                    final alumnosSnapshot = await FirebaseFirestore.instance.collection('usuarios').where('clase_id', isEqualTo: claseId).get();
                    final batch = FirebaseFirestore.instance.batch();

                    for (var alumnoDoc in alumnosSnapshot.docs) {
                      final nuevaTareaRef = alumnoDoc.reference.collection('tareas').doc();
                      batch.set(nuevaTareaRef, {
                        'titulo': tituloController.text.trim(),
                        'descripcion': descController.text.trim(),
                        'icono': iconoSeleccionado,
                        'importante': esImportante,
                        'completada': false,
                        'fecha': FieldValue.serverTimestamp(),
                      });
                    }

                    await batch.commit();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reto asignado a toda la clase'), backgroundColor: Colors.green));
                  },
                  child: const Text('Asignar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
      ),
    );
  }

  void _mostrarDialogoSubirMaterial(BuildContext context) {
    final tituloController = TextEditingController();
    final descController = TextEditingController();
    final urlController = TextEditingController();
    final fuenteController = TextEditingController();

    File? archivoSeleccionado;
    String nombreArchivo = '';
    bool subiendoAStorage = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(children: [Icon(Icons.post_add, color: Colors.blue.shade700), const SizedBox(width: 10), const Text('Subir Material', style: TextStyle(fontWeight: FontWeight.bold))]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: tituloController, decoration: InputDecoration(labelText: 'Título del material', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 10),
                    TextField(controller: descController, maxLines: 2, decoration: InputDecoration(labelText: 'Descripción breve', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 15),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Seleccionar Archivo / Video'),
                            onPressed: () async {
                              FilePickerResult? result = await FilePicker.platform.pickFiles(
                                type: FileType.any,
                              );
                              if (result != null && result.files.single.path != null) {
                                setStateDialog(() {
                                  archivoSeleccionado = File(result.files.single.path!);
                                  nombreArchivo = result.files.single.name;
                                  urlController.text = '';
                                });
                              }
                            },
                          ),
                          if (nombreArchivo.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('📄 $nombreArchivo', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                            ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text('O agrega un enlace web manual:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),

                    TextField(
                      controller: urlController,
                      enabled: archivoSeleccionado == null,
                      decoration: InputDecoration(labelText: 'URL (Enlace web)', prefixIcon: const Icon(Icons.link), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      onChanged: (value) => setStateDialog(() {}),
                    ),
                    const SizedBox(height: 10),

                    if (archivoSeleccionado == null)
                      TextField(controller: fuenteController, decoration: InputDecoration(labelText: 'Fuente / Autor', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: subiendoAStorage ? null : () async {
                    if (tituloController.text.isEmpty || descController.text.isEmpty) return;

                    String urlFinal = urlController.text.trim();
                    String fuenteFinal = fuenteController.text.trim();

                    if (archivoSeleccionado != null) {
                      setStateDialog(() => subiendoAStorage = true);
                      try {
                        String pathStorage = 'materiales/$claseId/${DateTime.now().millisecondsSinceEpoch}_$nombreArchivo';
                        Reference ref = FirebaseStorage.instance.ref().child(pathStorage);
                        UploadTask uploadTask = ref.putFile(archivoSeleccionado!);
                        TaskSnapshot snapshot = await uploadTask;
                        urlFinal = await snapshot.ref.getDownloadURL();
                        fuenteFinal = 'Archivo de la materia';
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al subir archivo: $e')));
                        setStateDialog(() => subiendoAStorage = false);
                        return;
                      }
                    }

                    await FirebaseFirestore.instance.collection('clases').doc(claseId).collection('materiales').add({
                      'titulo': tituloController.text.trim(),
                      'descripcion': descController.text.trim(),
                      'url': urlFinal,
                      'fuente': fuenteFinal,
                      'es_archivo': archivoSeleccionado != null,
                      'fecha': FieldValue.serverTimestamp(),
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material publicado'), backgroundColor: Colors.blue));
                  },
                  child: subiendoAStorage
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          }
      ),
    );
  }

  // --- ELIMINAR MATERIAL ---
  void _eliminarMaterial(BuildContext context, String materialId, Map<String, dynamic> mat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Material'),
        content: const Text('¿Estás seguro de que deseas eliminar este material de la clase?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(ctx);

              // 1. Si el material era un archivo subido a Storage, lo borramos de la nube para liberar espacio
              if (mat['es_archivo'] == true && mat['url'] != null) {
                try {
                  await FirebaseStorage.instance.refFromURL(mat['url']).delete();
                } catch (e) {
                  debugPrint('Error al borrar de Storage: $e');
                }
              }

              // 2. Borramos el registro de la base de datos Firestore
              await FirebaseFirestore.instance.collection('clases').doc(claseId).collection('materiales').doc(materialId).delete();

              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material eliminado correctamente'), backgroundColor: Colors.red));
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(claseId).snapshots(),
      builder: (context, claseSnapshot) {

        final Map<String, dynamic> config = (claseSnapshot.hasData && claseSnapshot.data!.data() != null)
            ? (claseSnapshot.data!.data() as Map<String, dynamic>)['config_recompensas'] ?? {}
            : {};

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: Text(nombreClase, style: const TextStyle(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.green.shade800,
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.analytics_outlined),
                  tooltip: 'Historial de Retos',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PantallaHistorialRetos(claseId: claseId, nombreClase: nombreClase)));
                  },
                ),
              ],
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
                  Tab(icon: Icon(Icons.library_books), text: 'Materiales'),
                ],
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
              ),
            ),
            body: TabBarView(
              children: [
                // RANKING
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('usuarios').where('clase_id', isEqualTo: claseId).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Aún no hay alumnos inscritos.', style: TextStyle(color: Colors.grey)));

                    final alumnos = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alumnos.length,
                      itemBuilder: (context, index) {
                        final doc = alumnos[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return StreamBuilder<QuerySnapshot>(
                          stream: doc.reference.collection('tareas').snapshots(),
                          builder: (context, taskSnapshot) {
                            int completadas = 0;
                            if (taskSnapshot.hasData) completadas = taskSnapshot.data!.docs.where((t) => (t.data() as Map<String, dynamic>)['completada'] == true).length;

                            final recompensa = _obtenerRecompensa(completadas, config);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                  color: recompensa['bgColor'],
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: recompensa['borde'], width: 1.5),
                                  boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 5, offset: const Offset(0, 3))]
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(recompensa['icono'], color: recompensa['iconColor'], size: 24),
                                ),
                                title: Text(data['nombre'] ?? 'Sin nombre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey.shade800)),
                                subtitle: Text('Insignia: ${recompensa['nombre']} ($completadas retos)', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('+${recompensa['puntos']}', style: TextStyle(fontWeight: FontWeight.bold, color: recompensa['iconColor'], fontSize: 18)),
                                    const Text('décimas', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProgresoAlumno(alumnoId: doc.id, nombreAlumno: data['nombre'] ?? 'Alumno')));
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),

                // PESTAÑA 2: LISTA DE MATERIALES
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('clases').doc(claseId).collection('materiales').orderBy('fecha', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300), const SizedBox(height: 10), Text('No has subido material aún.', style: TextStyle(color: Colors.grey.shade600))]));

                    final docs = snapshot.data!.docs;

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final matId = docs[index].id; // <--- Recuperamos el ID del documento
                        final mat = docs[index].data() as Map<String, dynamic>;
                        bool esArchivo = mat['es_archivo'] == true;

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(15),
                            leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: esArchivo ? Colors.amber.shade50 : Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
                                child: Icon(esArchivo ? Icons.folder_zip_outlined : Icons.menu_book, color: esArchivo ? Colors.amber.shade800 : Colors.blue.shade700)
                            ),
                            title: Text(mat['titulo'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text('${mat['descripcion'] ?? ''}\n\nFuente: ${mat['fuente'] ?? 'Desconocida'}', style: TextStyle(color: Colors.grey.shade600, height: 1.3)),
                            ),

                            // --- BOTÓN DE ELIMINAR ---
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _eliminarMaterial(context, matId, mat),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: esArchivo ? Colors.amber.shade800 : Colors.blue),
                              ],
                            ),

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PantallaDetalleMaterial(material: mat),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            floatingActionButton: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'btnConfig',
                  onPressed: () => _mostrarDialogoConfiguracion(context, config),
                  backgroundColor: Colors.blueGrey,
                  child: const Icon(Icons.settings, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton(
                  heroTag: 'btnSubir',
                  onPressed: () => _mostrarDialogoSubirMaterial(context),
                  backgroundColor: Colors.blue.shade700,
                  child: const Icon(Icons.post_add, color: Colors.white),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'btnAsignar',
                  onPressed: () => _mostrarDialogoAsignarReto(context),
                  backgroundColor: Colors.orange.shade700,
                  icon: const Icon(Icons.add_task, color: Colors.white),
                  label: const Text('Asignar Reto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}