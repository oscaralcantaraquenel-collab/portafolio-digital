import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PantallaHistorialRetos extends StatefulWidget {
  final String claseId;
  final String nombreClase;

  const PantallaHistorialRetos({super.key, required this.claseId, required this.nombreClase});

  @override
  State<PantallaHistorialRetos> createState() => _PantallaHistorialRetosState();
}

class _PantallaHistorialRetosState extends State<PantallaHistorialRetos> {

  Future<List<Map<String, dynamic>>> _obtenerHistorialAgrupado() async {
    final alumnosSnap = await FirebaseFirestore.instance.collection('usuarios').where('clase_id', isEqualTo: widget.claseId).get();
    Map<String, Map<String, dynamic>> mapaRetos = {};

    for (var alumnoDoc in alumnosSnap.docs) {
      final datosAlumno = alumnoDoc.data();
      final nombreAlumno = datosAlumno['nombre'] ?? 'Alumno sin nombre';
      final tareasSnap = await alumnoDoc.reference.collection('tareas').get();

      for (var tareaDoc in tareasSnap.docs) {
        final tarea = tareaDoc.data();
        final titulo = tarea['titulo'] ?? 'Sin título';
        final completada = tarea['completada'] == true;

        if (!mapaRetos.containsKey(titulo)) {
          mapaRetos[titulo] = {
            'titulo': titulo,
            'descripcion': tarea['descripcion'] ?? '',
            'icono': tarea['icono'] ?? 'eco',
            'total_asignados': 0,
            'total_completados': 0,
            'alumnos_listos': <String>[],
            'alumnos_pendientes': <String>[],
          };
        }

        mapaRetos[titulo]!['total_asignados'] += 1;

        if (completada) {
          mapaRetos[titulo]!['total_completados'] += 1;
          mapaRetos[titulo]!['alumnos_listos'].add(nombreAlumno);
        } else {
          mapaRetos[titulo]!['alumnos_pendientes'].add(nombreAlumno);
        }
      }
    }
    return mapaRetos.values.toList();
  }

  // --- ELIMINAR RETO GLOBAL ---
  void _eliminarRetoGlobal(String tituloReto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Reto', style: TextStyle(color: Colors.red)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Text('¿Deseas eliminar el reto "$tituloReto" de todos los alumnos?\n\nEsta acción no se puede deshacer y borrará permanentemente todas las evidencias fotográficas asociadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () async {
              Navigator.pop(ctx);

              // Mostramos un mensaje de carga
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Eliminando reto y liberando espacio...')));

              // 1. Buscamos a todos los alumnos
              final alumnosSnap = await FirebaseFirestore.instance.collection('usuarios').where('clase_id', isEqualTo: widget.claseId).get();

              // 2. Por cada alumno, buscamos las tareas que tengan este título
              for (var alumnoDoc in alumnosSnap.docs) {
                final tareasSnap = await alumnoDoc.reference.collection('tareas').where('titulo', isEqualTo: tituloReto).get();

                for (var tareaDoc in tareasSnap.docs) {
                  final dataTarea = tareaDoc.data();

                  // 3. Si el alumno subió una foto de evidencia, la borramos del disco duro
                  if (dataTarea['evidencia_url'] != null && dataTarea['evidencia_url'].toString().isNotEmpty) {
                    try {
                      await FirebaseStorage.instance.refFromURL(dataTarea['evidencia_url']).delete();
                    } catch (e) {
                      debugPrint('Error borrando evidencia: $e');
                    }
                  }
                  // 4. Borramos la tarea de la base de datos
                  await tareaDoc.reference.delete();
                }
              }

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reto eliminado exitosamente.'), backgroundColor: Colors.red));

              // Refrescamos la pantalla
              setState(() {});
            },
            child: const Text('Sí, Eliminar', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  IconData _obtenerIcono(String? codigo) {
    switch (codigo) {
      case 'agua': return Icons.water_drop;
      case 'energia': return Icons.bolt;
      case 'reciclaje': return Icons.recycling;
      case 'hogar': return Icons.home;
      default: return Icons.eco;
    }
  }

  Color _obtenerColorIcono(String? codigo) {
    switch (codigo) {
      case 'agua': return Colors.blue;
      case 'energia': return Colors.amber;
      case 'reciclaje': return Colors.teal;
      case 'hogar': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historial de Retos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(widget.nombreClase, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal)),
          ],
        ),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerHistorialAgrupado(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.analytics_outlined, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 15),
                  Text('No hay retos asignados en esta clase aún.', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          final listaRetos = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: listaRetos.length,
            itemBuilder: (context, index) {
              final reto = listaRetos[index];
              final total = reto['total_asignados'] as int;
              final completados = reto['total_completados'] as int;
              final progreso = total > 0 ? (completados / total) : 0.0;
              final colorTema = _obtenerColorIcono(reto['icono']);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: colorTema.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: Icon(_obtenerIcono(reto['icono']), color: colorTema),
                    ),
                    title: Text(reto['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text('$completados de $total alumnos completaron', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 5),
                        LinearProgressIndicator(
                          value: progreso,
                          backgroundColor: Colors.grey.shade200,
                          color: progreso == 1.0 ? Colors.green : colorTema,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ],
                    ),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Alumnos que ya cumplieron
                            Row(children: [Icon(Icons.check_circle, color: Colors.green.shade600, size: 18), const SizedBox(width: 5), Text('Cumplieron:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800))]),
                            const SizedBox(height: 5),
                            ...List.generate(
                              (reto['alumnos_listos'] as List).length,
                                  (i) => Text('• ${reto['alumnos_listos'][i]}', style: TextStyle(color: Colors.grey.shade700)),
                            ),
                            if ((reto['alumnos_listos'] as List).isEmpty) Text('Nadie ha completado este reto.', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),

                            const SizedBox(height: 15),

                            // Alumnos pendientes
                            Row(children: [Icon(Icons.pending, color: Colors.orange.shade600, size: 18), const SizedBox(width: 5), Text('Pendientes:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800))]),
                            const SizedBox(height: 5),
                            ...List.generate(
                              (reto['alumnos_pendientes'] as List).length,
                                  (i) => Text('• ${reto['alumnos_pendientes'][i]}', style: TextStyle(color: Colors.grey.shade700)),
                            ),
                            if ((reto['alumnos_pendientes'] as List).isEmpty) Text('¡Todos han completado este reto!', style: TextStyle(color: Colors.green.shade600, fontWeight: FontWeight.bold)),

                            const SizedBox(height: 20),

                            // --- BOTÓN PARA ELIMINAR EL RETO ---
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    side: BorderSide(color: Colors.red.shade400),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                                ),
                                icon: Icon(Icons.delete_forever, color: Colors.red.shade600, size: 20),
                                label: Text('Eliminar este Reto', style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                                onPressed: () => _eliminarRetoGlobal(reto['titulo']),
                              ),
                            )

                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}