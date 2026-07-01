import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PantallaLogros extends StatefulWidget {
  final int tareasCompletadas;
  final String claseId;

  const PantallaLogros({
    super.key,
    required this.tareasCompletadas,
    required this.claseId,
  });

  @override
  State<PantallaLogros> createState() => _PantallaLogrosState();
}

class _PantallaLogrosState extends State<PantallaLogros> {
  // --- LÓGICA DE DATOS (Mantenemos la misma lógica inteligente de ayer) ---
  Map<String, dynamic> _infoInsignia(int index, Map<String, dynamic> config) {
    const nombres = ['Semilla', 'Brote', 'Guardián Verde'];
    const llaves = ['semilla', 'brote', 'arbol'];
    const metas = [3, 6, 10]; // Retos necesarios

    const colores = [Color(0xFF8D6E63), Color(0xFF66BB6A), Color(0xFF2E7D32)];

    // Íconos temáticos para que se vea ecológico
    const iconData = [Icons.eco, Icons.grass, Icons.forest_outlined];

    String nombre = nombres[index];
    int meta = metas[index];
    Color colorBase = colores[index];
    double decimas = (config[llaves[index]] ?? 0.0).toDouble();

    // Verificamos si el alumno ya alcanzó la meta
    bool bloqueada = widget.tareasCompletadas < meta;

    return {
      'bloqueada': bloqueada,
      'nombre': nombre,
      'meta': meta,
      'color': colorBase,
      'icon': iconData[index],
      'decimas': decimas,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Si el alumno no tiene clase, mostramos mensaje
    if (widget.claseId.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB), // Gris muy muy claro
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'Únete a una clase desde el menú lateral para ver tus logros universitarios y décimas extra.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ),
      );
    }

    // --- FIRESTORE ---
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('clases').doc(widget.claseId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.green));
        }

        final Map<String, dynamic> config = (snapshot.hasData && snapshot.data!.data() != null)
            ? (snapshot.data!.data() as Map<String, dynamic>)['config_recompensas'] ?? {}
            : {};

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- TARJETA DE RESUMEN ---
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Tu Impacto Ambiental Total',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.check_circle_outline, color: Colors.green, size: 40),
                            ),
                            const SizedBox(width: 15),
                            Text(
                              '${widget.tareasCompletadas}',
                              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black87, letterSpacing: -2),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Retos\nLogrados',
                              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.2, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        Text(
                          'Sigue completando retos ecológicos para desbloquear insignias y ganar décimas extra en tu calificación parcial.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // --- TÍTULO SECCIÓN ---
                const Text(
                  'Tus Insignias Escolares',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 15),

                // --- GRILLA DE INSIGNIAS ---
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columnas
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    final info = _infoInsignia(index, config);
                    bool bloqueada = info['bloqueada'];
                    Color levelColor = info['color'];

                    return Card(
                      elevation: bloqueada ? 0 : 3,
                      color: Colors.white,
                      shadowColor: levelColor.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color: bloqueada ? Colors.grey.shade200 : levelColor.withOpacity(0.5),
                            width: bloqueada ? 1 : 2
                        ),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    // Color tenue de fondo
                                    color: bloqueada ? Colors.grey.shade100 : levelColor.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  // Ícono Temático
                                  child: Icon(info['icon'], size: 50, color: bloqueada ? Colors.grey.shade400 : levelColor),
                                ),
                                const SizedBox(height: 12),
                                // Nombre Insignia
                                Text(
                                  info['nombre'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: bloqueada ? Colors.grey.shade700 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Meta retos
                                Text(
                                  'Meta: ${info['meta']} retos',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1),
                                const SizedBox(height: 10),
                                // Valor Décimas
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: bloqueada ? Colors.grey.shade100 : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(10)
                                  ),
                                  child: Text(
                                    bloqueada ? 'Bloqueada' : '+${info['decimas']} décimas',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: bloqueada ? FontWeight.normal : FontWeight.bold,
                                      color: bloqueada ? Colors.grey.shade600 : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Candado
                          if (bloqueada)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 16)
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}