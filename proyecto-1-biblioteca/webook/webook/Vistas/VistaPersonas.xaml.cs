using System;
using System.IO;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using SQLite;
using webook.Tablas;
using webook.Datos;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VistaPersonas : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;

        public VistaPersonas()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            btnRestablecerP.Clicked += BtnRestablecerP_Clicked;
            btnRegistrarP.Clicked += BtnRegistrarP_Clicked;
            btnMostrarP.Clicked += BtnMostrarP_Clicked;
        }

        private void BtnMostrarP_Clicked(object sender, EventArgs e)
        {
            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaPersonas>();
            Navigation.PushAsync(new VistaMostrarPersonas());
        }

        private void BtnRegistrarP_Clicked(object sender, EventArgs e)
        {
            try
            {
                var nombreTrim = nombre.Text != null ? nombre.Text.Trim() : string.Empty;
                var apellidoPTrim = apellidoP.Text != null ? apellidoP.Text.Trim() : string.Empty;
                var apellidoMTrim = apellidoM.Text != null ? apellidoM.Text.Trim() : string.Empty;
                var edadTrim = edad.Text != null ? edad.Text.Trim() : string.Empty;
                var generoSeleccionado = genero.SelectedItem != null ? genero.SelectedItem.ToString() : string.Empty;

                if (string.IsNullOrWhiteSpace(nombreTrim) ||
                    string.IsNullOrWhiteSpace(apellidoPTrim) ||
                    string.IsNullOrWhiteSpace(apellidoMTrim) ||
                    string.IsNullOrWhiteSpace(edadTrim) ||
                    string.IsNullOrWhiteSpace(generoSeleccionado))
                {
                    DisplayAlert("Error", "Todos los campos deben estar llenos.", "Aceptar");
                    return;
                }

                int edadNumerica;
                if (!int.TryParse(edadTrim, out edadNumerica) || edadNumerica <= 0)
                {
                    DisplayAlert("Error", "La edad debe ser un número válido mayor a 0.", "Aceptar");
                    return;
                }

                var datosPersonas = new TablaPersonas
                {
                    Nombre_persona = nombreTrim,
                    Apellido_paterno = apellidoPTrim,
                    Apellido_materno = apellidoMTrim,
                    Edad = edadNumerica,
                    Genero = generoSeleccionado
                };

                conexiondb.InsertAsync(datosPersonas);
                limpiarTP();
                DisplayAlert("Completado", "La persona se ha registrado con éxito.", "Aceptar");
            }
            catch (Exception ex)
            {
                DisplayAlert("Error", "Ocurrió un error al registrar: " + ex.Message, "Aceptar");
            }
        }

        private void BtnRestablecerP_Clicked(object sender, EventArgs e)
        {
            limpiarTP();
        }

        private void limpiarTP()
        {
            nombre.Text = "";
            apellidoP.Text = "";
            apellidoM.Text = "";
            edad.Text = "";
            genero.SelectedItem = null;
        }
    }
}
