using webook.Droid;
using SQLite;
using System.IO;
using webook.Datos;
using Xamarin.Forms;
using webook.Tablas; // IMPORTANTE: Para que reconozca TablaAdeudos, TablaLibros, etc.
using System.Threading.Tasks;

[assembly: Dependency(typeof(BaseDatosLite))]
namespace webook.Droid
{
    public class BaseDatosLite : BaseDatos
    {
        public SQLiteAsyncConnection ObtenerConexion()
        {
            // 1. Definimos la ruta (usamos Personal para asegurar persistencia en Android)
            var direccion = System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal);
            var rutaBaseDatos = Path.Combine(direccion, "webookBD.db3");

            // 2. Creamos la conexión
            var conexion = new SQLiteAsyncConnection(rutaBaseDatos);

            // 3. Ejecutamos la creación de tablas de forma interna
            // Nota: SQLite ignora el comando si la tabla ya existe, por lo que no borra tus datos.
            CrearTablasIniciales(conexion);

            return conexion;
        }

        private async void CrearTablasIniciales(SQLiteAsyncConnection conexion)
        {
            try
            {
                // Creamos todas las tablas que veo en tu explorador de soluciones
                await conexion.CreateTableAsync<TablaAdeudos>();
                await conexion.CreateTableAsync<TablaEquipos>();
                await conexion.CreateTableAsync<TablaEspacios>();
                await conexion.CreateTableAsync<TablaLibros>();
                await conexion.CreateTableAsync<TablaPersonas>();
                await conexion.CreateTableAsync<TablaPrestamos>();
            }
            catch (System.Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"Error al inicializar tablas: {ex.Message}");
            }
        }
    }
}