import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PantallaInformacion extends StatelessWidget {
  final String claseId;

  const PantallaInformacion({super.key, required this.claseId});

  // --- 1. FUNCIÓN PARA ABRIR GOOGLE MAPS ---
  void _abrirMapaReciclaje(BuildContext context) async {
    // Busca centros de reciclaje cercanos en la app de mapas
    final Uri url = Uri.parse('https://www.google.com/maps/search/centros+de+reciclaje');

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el mapa. Verifica tu conexión.'))
        );
      }
    }
  }

  // --- 2. PANTALLA COMPLETA DEL MATERIAL ---
  void _mostrarDetalleMaterial(BuildContext context, Map<String, dynamic> material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaDetalleMaterial(material: material),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- TARJETA DE MAPAS ---
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: InkWell(
              onTap: () => _abrirMapaReciclaje(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.map_outlined, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 15),
                    const Text('Centros de Reciclaje', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('Encuentra lugares cercanos para llevar tus residuos y contribuir al medio ambiente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.green.shade50, fontSize: 14, height: 1.4)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Abrir Google Maps', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Icon(Icons.open_in_new, size: 16, color: Colors.green.shade800),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),

          // --- TÍTULO DE LISTA ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
            child: Row(
              children: [
                Icon(Icons.library_books_outlined, color: Colors.grey.shade700, size: 22),
                const SizedBox(width: 10),
                Text('Materiales de Clase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              ],
            ),
          ),

          // --- LISTA DE MATERIALES ---
          Expanded(
            child: claseId.isEmpty
                ? Center(child: Text('Únete a una clase para ver los materiales.', style: TextStyle(color: Colors.grey.shade600)))
                : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('clases').doc(claseId).collection('materiales').orderBy('fecha', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.green));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Tu profesor no ha subido material aún.'));

                final materiales = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: materiales.length,
                  itemBuilder: (context, index) {
                    final mat = materiales[index].data() as Map<String, dynamic>;

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.article_outlined, color: Colors.green.shade700, size: 28),
                        ),
                        title: Text(mat['titulo'] ?? 'Material', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text('Fuente: ${mat['fuente'] ?? 'Desconocida'}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        onTap: () => _mostrarDetalleMaterial(context, mat), // <--- CABLE CONECTADO A LA PANTALLA
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- PANTALLA DE DETALLE DE MATERIAL ---
class PantallaDetalleMaterial extends StatelessWidget {
  final Map<String, dynamic> material;

  const PantallaDetalleMaterial({super.key, required this.material});

  void _abrirUrlWeb(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;

    // Aseguramos que el link tenga el formato correcto (http/https)
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Artículo Educativo', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono decorativo
            Center(
              child: Icon(Icons.menu_book_rounded, size: 80, color: Colors.green.shade600),
            ),
            const SizedBox(height: 30),

            // Título
            Text(
              material['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
            ),
            const SizedBox(height: 15),
            const Divider(thickness: 1.5),
            const SizedBox(height: 15),

            // Descripción completa
            Text(
              material['descripcion'] ?? 'Sin descripción.',
              style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 40),

            // Tarjeta de Créditos y Botón de Enlace
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 5, offset: const Offset(0, 3))]
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.copyright, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text('Créditos y Fuente', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Autor/Medio: ${material['fuente'] ?? 'Desconocida'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),

                  const SizedBox(height: 20),

                  // Botón para abrir el Link original
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Colors.green.shade700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                      ),
                      icon: Icon(Icons.open_in_new, color: Colors.green.shade700),
                      label: Text('Ver contenido original', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () => _abrirUrlWeb(context, material['url'] ?? ''),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}