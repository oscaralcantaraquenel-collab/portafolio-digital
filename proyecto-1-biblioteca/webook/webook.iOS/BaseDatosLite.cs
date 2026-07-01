using SQLite;
using webook.iOS;
using webook.Datos;
using Xamarin.Forms;
using System.IO;

[assembly: Dependency(typeof(BaseDatosLite))]

namespace webook.iOS
{
    public class BaseDatosLite : BaseDatos
    {
        public SQLiteAsyncConnection ObtenerConexion()
        {
            var direccion = System.Environment.GetFolderPath(System.Environment.SpecialFolder.MyDocuments);
            var rutaBaseDatos = Path.Combine(direccion, "webookBD.db3");
            return new SQLiteAsyncConnection(rutaBaseDatos);
        }
    }
}