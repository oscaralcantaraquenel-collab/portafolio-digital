import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProgresoAlumno extends StatelessWidget {
  final String alumnoId;
  final String nombreAlumno;

  const ProgresoAlumno({super.key, required this.alumnoId, required this.nombreAlumno});

  // Función para mostrar la foto en pantalla grande
  void _mostrarEvidencia(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                url,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white),
              label: const Text('Cerrar Evidencia', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Progreso de $nombreAlumno', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Usamos StreamBuilder para que el maestro vea los cambios en tiempo real
        stream: FirebaseFirestore.instance.collection('usuarios').doc(alumnoId).collection('tareas').orderBy('fecha').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Este alumno no tiene retos asignados.'));

          final tareas = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tareas.length,
            itemBuilder: (context, index) {
              final tarea = tareas[index].data() as Map<String, dynamic>;
              bool completada = tarea['completada'] == true;
              bool tieneEvidencia = tarea['evidencia_url'] != null && tarea['evidencia_url'].toString().isNotEmpty;

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: Icon(
                    completada ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: completada ? Colors.green : Colors.grey,
                    size: 30,
                  ),
                  title: Text(tarea['titulo'] ?? 'Sin título', style: TextStyle(decoration: completada ? TextDecoration.lineThrough : null, fontWeight: FontWeight.bold)),
                  subtitle: Text(tarea['descripcion'] ?? ''),
                  // Si tiene evidencia, mostramos un botón para verla
                  trailing: tieneEvidencia
                      ? IconButton(
                    icon: const Icon(Icons.image, color: Colors.blue, size: 28),
                    tooltip: 'Ver Evidencia',
                    onPressed: () => _mostrarEvidencia(context, tarea['evidencia_url']),
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}