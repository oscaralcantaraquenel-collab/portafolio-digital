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
    public partial class VistaEquipos : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;

        public VistaEquipos()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            btnRegistrarE.Clicked += BtnRegistrarE_Clicked;
            btnRestablecerE.Clicked += BtnRestablecerE_Clicked;
            btnMostrarE.Clicked += BtnMostrarE_Clicked;
        }

        private void BtnMostrarE_Clicked(object sender, EventArgs e)
        {
            var BD = Path.Combine(Environment.GetFolderPath(System.Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaEquipos>();
            Navigation.PushAsync(new VistaMostrarEquipos());
        }

        private void BtnRestablecerE_Clicked(object sender, EventArgs e)
        {
            limpiarT();
        }

        private async void BtnRegistrarE_Clicked(object sender, EventArgs e)
        {
            try
            {
                // Validar campos vacíos
                if (string.IsNullOrWhiteSpace(marca.Text) ||
                    string.IsNullOrWhiteSpace(modelo.Text) ||
                    string.IsNullOrWhiteSpace(numEquipo.Text) ||
                    string.IsNullOrWhiteSpace(estado.Text) ||
                    string.IsNullOrWhiteSpace(descripcion.Text) ||
                    string.IsNullOrWhiteSpace(existencia.Text))
                {
                    await DisplayAlert("Error", "Todos los campos deben estar llenos.", "Aceptar");
                    return;
                }

                // Eliminar espacios no deseados
                string marcaLimpia = marca.Text.Trim();
                string modeloLimpio = modelo.Text.Trim();
                string estadoLimpio = estado.Text.Trim();
                string descripcionLimpia = descripcion.Text.Trim();

                // Validar datos numéricos
                if (!int.TryParse(numEquipo.Text, out int numeroEquipo) ||
                    !int.TryParse(existencia.Text, out int existenciaEquipo))
                {
                    await DisplayAlert("Error", "Los campos 'Número del equipo' y 'Existencias' deben contener valores numéricos válidos.", "Aceptar");
                    return;
                }

                // Registrar datos en la base de datos
                var datosEquipos = new TablaEquipos
                {
                    Marca = marcaLimpia,
                    Modelo = modeloLimpio,
                    Numero_equipo = numeroEquipo,
                    Estado_equipo = estadoLimpio,
                    Descripcion_equipo = descripcionLimpia,
                    Existencia = existenciaEquipo
                };

                await conexiondb.InsertAsync(datosEquipos);
                limpiarT();
                await DisplayAlert("Completado", "El equipo se ha registrado con éxito.", "Aceptar");
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error al registrar el equipo: {ex.Message}", "Aceptar");
            }
        }

        private void limpiarT()
        {
            marca.Text = "";
            modelo.Text = "";
            numEquipo.Text = "";
            estado.Text = "";
            descripcion.Text = "";
            existencia.Text = "";
        }
    }
}
