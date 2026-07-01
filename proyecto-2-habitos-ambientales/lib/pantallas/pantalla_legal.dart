import 'package:flutter/material.dart';

class PantallaLegal extends StatelessWidget {
  const PantallaLegal({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Fondo moderno sincronizado con la app
      appBar: AppBar(
        title: const Text('Legal y Privacidad', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CABECERA ---
            Center(
              child: Icon(Icons.gavel_rounded, size: 60, color: Colors.green.shade800),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Términos, Condiciones y\nDeslinde de Responsabilidad',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text('Última actualización: Mayo 2026', style: TextStyle(color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 20),
            const Divider(height: 40, thickness: 1),

            // --- SECCIÓN 1: TÉRMINOS Y CONDICIONES ---
            _crearTituloSeccion('1. Aceptación de los Términos'),
            _crearParrafo(
                'Al descargar, instalar y utilizar la plataforma "Reto Verde", el usuario acepta los presentes Términos y Condiciones. Esta aplicación es un prototipo académico desarrollado con fines educativos y de evaluación escolar.'
            ),

            // --- SECCIÓN 2: PRIVACIDAD Y FIREBASE ---
            _crearTituloSeccion('2. Privacidad y Manejo de Datos (Firebase Cloud)'),
            _crearParrafo(
                'Para ofrecer la experiencia de un entorno virtual de aprendizaje (LMS), la información del usuario (nombre, correo, nombre de usuario, fotografías de perfil y progreso de tareas) se almacena de forma segura en la nube utilizando la infraestructura de Google Firebase.'
            ),
            _crearParrafo(
                'Al unirte a una clase mediante un código de acceso, otorgas consentimiento explícito para que el profesor administrador de dicho grupo pueda visualizar tus datos de perfil y métricas de progreso para fines estrictamente de evaluación académica.'
            ),

            // --- SECCIÓN 3: DESLINDE LEGAL ---
            _crearTituloSeccion('3. Deslinde Legal de la Información'),
            _crearParrafo(
                'PROPÓSITO INFORMATIVO: Los consejos, guías y micro-tareas ecológicas proporcionadas en "Reto Verde" tienen un fin estrictamente educativo y de concientización ambiental. No constituyen asesoría profesional, técnica ni legal.'
            ),
            _crearParrafo(
                'LIBERACIÓN DE RESPONSABILIDAD: Los desarrolladores de la aplicación no asumen ninguna responsabilidad directa, indirecta o incidental por acciones, accidentes, daños o perjuicios que el usuario pueda sufrir al intentar cumplir los retos o seguir las guías mostradas en la plataforma.'
            ),

            // --- SECCIÓN 4: SERVICIOS DE TERCEROS ---
            _crearTituloSeccion('4. Servicios y Enlaces de Terceros'),
            _crearParrafo(
                'La función de "Encuentra dónde reciclar" utiliza enlaces externos para redirigir al usuario a plataformas de terceros (Google Maps). "Reto Verde" no controla, avala, ni garantiza la exactitud de los horarios, ubicaciones o la existencia real de dichos centros de acopio. El uso de la navegación externa es bajo el propio riesgo del usuario.'
            ),

            // --- SECCIÓN 5: PROPIEDAD INTELECTUAL ---
            _crearTituloSeccion('5. Propiedad Intelectual'),
            _crearParrafo(
                'El diseño, logotipos, código fuente y estructura de "Reto Verde" son propiedad intelectual de sus desarrolladores. Queda prohibida su reproducción o distribución con fines de lucro sin autorización previa.'
            ),

            const SizedBox(height: 40),

            // --- BOTÓN DE REGRESO ---
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Text('He leído y entiendo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- FUNCIONES DE DISEÑO ---
  Widget _crearTituloSeccion(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0, bottom: 12.0),
      child: Text(
        titulo,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
      ),
    );
  }

  Widget _crearParrafo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        texto,
        style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.6), // Aumenté el height para mejor lectura
        textAlign: TextAlign.justify,
      ),
    );
  }
}