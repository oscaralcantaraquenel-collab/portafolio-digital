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
    public partial class VistaEditarPersonas : ContentPage
    {
        public int idS, edadS;
        public string nombreS, apPS, apMS, generoS;
        private SQLiteAsyncConnection conexiondb;

        public VistaEditarPersonas(int id, string nom, string apP, string apM, int edad, string genero)
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            idS = id;
            nombreS = nom;
            apPS = apP;
            apMS = apM;
            edadS = edad;
            generoS = genero;
            btnActualizarP.Clicked += BtnActualizarP_Clicked;
            btnEliminarP.Clicked += BtnEliminarP_Clicked;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            Mid.Text = "ID: " + idS;
            nombre.Text = nombreS;
            apellidoM.Text = apMS;
            apellidoP.Text = apPS;
            edad.Text = edadS.ToString();
            genero.SelectedItem = generoS;
        }

        private async void BtnEliminarP_Clicked(object sender, EventArgs e)
        {
            try
            {
                var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var db = new SQLiteConnection(BD);
                db.Query<TablaPersonas>("DELETE FROM TablaPersonas WHERE id_persona = ?", idS);

                DisplayAlert("Completado", "La persona se ha eliminado con éxito.", "Aceptar");
                limpiarTP();
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                DisplayAlert("Error", "Ocurrió un error al eliminar: " + ex.Message, "Aceptar");
            }
        }

        private async void BtnActualizarP_Clicked(object sender, EventArgs e)
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

                var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var db = new SQLiteConnection(BD);
                db.Query<TablaPersonas>(
                    "UPDATE TablaPersonas SET Nombre_persona = ?, Apellido_paterno = ?, Apellido_materno = ?, Edad = ?, Genero = ? WHERE id_persona = ?",
                    nombreTrim, apellidoPTrim, apellidoMTrim, edadNumerica, generoSeleccionado, idS
                );

                DisplayAlert("Completado", "La persona se ha actualizado con éxito.", "Aceptar");
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                DisplayAlert("Error", "Ocurrió un error al actualizar: " + ex.Message, "Aceptar");
            }
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
