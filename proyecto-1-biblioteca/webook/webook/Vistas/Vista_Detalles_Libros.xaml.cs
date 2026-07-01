using SQLite;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using webook.Tablas;
using webook.Datos;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using System.IO;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class Vista_Detalles_Libros : ContentPage
    {
        public int ISBN;
        public string Titulo, Autores, Editorial, Publicacion, Clasificacion;
        public int Cantidad;
        public string Seccion, Estado;
        private SQLiteAsyncConnection enlace;
        IEnumerable<TablaLibros> ResultadoDelete;
        IEnumerable<TablaLibros> ResultadoUpdate;

        public Vista_Detalles_Libros(int id, string titulo, string autores,
            string editorial, string publicacion, string clasificacion,
            int cant, string seccion, string estado)
        {
            InitializeComponent();
            enlace = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ISBN = id;
            Titulo = titulo;
            Autores = autores;
            Editorial = editorial;
            Publicacion = publicacion;
            Clasificacion = clasificacion;
            Cantidad = cant;
            Seccion = seccion;
            Estado = estado;
            Actualizar.Clicked += BotonActualizar;
            Eliminar.Clicked += BotonEliminar;
        }

        protected override void OnAppearing()
        {
            isbn.Text = ISBN.ToString();
            titulo.Text = Titulo;
            autor.Text = Autores;
            editorial.Text = Editorial;
            publicacion.Text = Publicacion;
            clasificacion.Text = Clasificacion;
            cantidad.Text = Cantidad.ToString();
            estado.Text = Estado;
            ubicacion.Text = Seccion;
        }

        private void BotonEliminar(object sender, EventArgs e)
        {
            var Ruta_Base = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var Base_Datos = new SQLiteConnection(Ruta_Base);
            ResultadoDelete = Delete(Base_Datos, ISBN);
            DisplayAlert("Borrar libro", "El libro fue borrado correctamente", "Aceptar");
            Limpiar();
        }

        private void BotonActualizar(object sender, EventArgs e)
        {
            // Verificar que ningún campo esté vacío
            if (string.IsNullOrWhiteSpace(isbn.Text) ||
                string.IsNullOrWhiteSpace(titulo.Text) ||
                string.IsNullOrWhiteSpace(autor.Text) ||
                string.IsNullOrWhiteSpace(editorial.Text) ||
                string.IsNullOrWhiteSpace(publicacion.Text) ||
                string.IsNullOrWhiteSpace(clasificacion.Text) ||
                string.IsNullOrWhiteSpace(this.cantidad.Text) || // Solución al conflicto
                string.IsNullOrWhiteSpace(estado.Text) ||
                string.IsNullOrWhiteSpace(ubicacion.Text))
            {
                DisplayAlert("Error", "Por favor, completa todos los campos antes de actualizar.", "Aceptar");
                return;
            }

            try
            {
                // Convertir los campos al formato requerido
                int currentIsbn = ISBN; // ISBN actual antes de modificar
                int newIsbn = int.Parse(isbn.Text.Replace("ISBN: ", "").Trim());
                int cantidad = int.Parse(this.cantidad.Text); // Aquí también se usa this.cantidad

                // Ruta de la base de datos
                var Ruta_Base = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var Base_Datos = new SQLiteConnection(Ruta_Base);

                // Actualizar los datos
                ResultadoUpdate = Update(Base_Datos, currentIsbn, newIsbn, titulo.Text, autor.Text, editorial.Text, publicacion.Text, clasificacion.Text, cantidad, estado.Text, ubicacion.Text);

                // Actualizar el ISBN en la instancia actual
                ISBN = newIsbn;

                DisplayAlert("Actualizar libro", "El libro se ha actualizado correctamente", "Aceptar");

                
            }
            catch (Exception ex)
            {
                DisplayAlert("Error", $"Ocurrió un error al actualizar el libro: {ex.Message}", "Aceptar");
            }
        }




        public static IEnumerable<TablaLibros> Delete(SQLiteConnection db, int id)
        {
            return db.Query<TablaLibros>("DELETE FROM TablaLibros WHERE Isbn = ?", id);
        }

        public static IEnumerable<TablaLibros> Update(SQLiteConnection db, int currentIsbn, int newIsbn, string titulo, string autores, string editorial, string publicacion, string clasificacion, int cant, string estado, string seccion)
        {
            return db.Query<TablaLibros>(
                "UPDATE TablaLibros SET Isbn = ?, Titulo = ?, Autores = ?, Editorial = ?, Año_publicacion = ?, Clasificacion = ?, Cantidad = ?, Estado_libro = ?, Seccion_ubicacion = ? WHERE Isbn = ?",
                newIsbn, titulo, autores, editorial, publicacion, clasificacion, cant, estado, seccion, currentIsbn);
        }

        public void Limpiar()
        {
            isbn.Text = "";
            titulo.Text = "";
            autor.Text = "";
            editorial.Text = "";
            publicacion.Text = "";
            clasificacion.Text = "";
            cantidad.Text = "";
            estado.Text = "";
            ubicacion.Text = "";
        }
    }
}