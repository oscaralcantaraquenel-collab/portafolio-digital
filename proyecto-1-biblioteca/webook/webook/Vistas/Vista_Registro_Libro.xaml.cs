using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using SQLite;
using webook.Tablas;
using webook.Datos;
using System.IO;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class Vista_Registro_Libro : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;
        public Vista_Registro_Libro()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            Boton_Guardar.Clicked += Boton_Guardar_Clicked;
            Boton_Limpiar.Clicked += LimpiarFormulario_Boton;
            Boton_Consultar.Clicked += Boton_Consultar_Clicked;
        }
        private async void Boton_Guardar_Clicked(object sender, EventArgs e)
        {
            // Validar que ningún campo esté vacío
            if (string.IsNullOrWhiteSpace(isbn.Text) ||
                string.IsNullOrWhiteSpace(titulo.Text) ||
                string.IsNullOrWhiteSpace(autor.Text) ||
                string.IsNullOrWhiteSpace(editorial.Text) ||
                string.IsNullOrWhiteSpace(publicacion.Text) ||
                string.IsNullOrWhiteSpace(clasificacion.Text) ||
                string.IsNullOrWhiteSpace(ejemplares.Text) ||
                string.IsNullOrWhiteSpace(estado.Text) ||
                string.IsNullOrWhiteSpace(seccion.Text))
            {
                await DisplayAlert("Error", "No debe de haber campos vacios al registrar un nuevo libro", "Aceptar");
                return;
            }

            // Registrar el libro
            var Libro = new TablaLibros
            {
                Isbn = int.Parse(isbn.Text),
                Titulo = titulo.Text,
                Autores = autor.Text,
                Editorial = editorial.Text,
                Año_publicacion = publicacion.Text,
                Clasificacion = clasificacion.Text,
                cantidad = int.Parse(ejemplares.Text),
                Estado_libro = estado.Text,
                Seccion_ubicacion = seccion.Text
            };
            await conexiondb.InsertAsync(Libro);
            LimpiarFormulario();
            await DisplayAlert("Registro exitoso", "El libro se ha registrado correctamente", "Aceptar");

        }
        private void LimpiarFormulario_Boton(object sender, EventArgs e)
        {
            LimpiarFormulario();
        }
        private void LimpiarFormulario()
        {
            isbn.Text = string.Empty;
            titulo.Text = string.Empty;
            autor.Text = string.Empty;
            editorial.Text = string.Empty;
            publicacion.Text = string.Empty;
            clasificacion.Text = string.Empty;
            ejemplares.Text = string.Empty;
            estado.Text = string.Empty;
            seccion.Text = string.Empty;
        }
        private void Boton_Consultar_Clicked(object sender, EventArgs e)
        {
            var BD = Path.Combine(Environment.GetFolderPath(System.Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaLibros>();
            Navigation.PushAsync(new Vista_Lista_Libros());
        }
    }
}