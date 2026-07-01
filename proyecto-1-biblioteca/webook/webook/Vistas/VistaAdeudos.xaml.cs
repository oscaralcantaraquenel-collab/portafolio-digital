using System;
using System.Linq;
using System.IO;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using SQLite;
using webook.Tablas;
using webook.Datos;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VistaAdeudos : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;

        public VistaAdeudos()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            btnRegistrarA.Clicked += BtnRegistrarE_Clicked;
            btnRestablecerA.Clicked += BtnRestablecerE_Clicked;
            btnMostrarA.Clicked += BtnMostrarE_Clicked;
        }

        private void BtnMostrarE_Clicked(object sender, EventArgs e)
        {
            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaAdeudos>();
            Navigation.PushAsync(new VistaMostrarAdeudos());
        }

        private void BtnRestablecerE_Clicked(object sender, EventArgs e)
        {
            limpiarTA();
        }

        private async void BtnRegistrarE_Clicked(object sender, EventArgs e)
        {
            // Validaciones
            if (string.IsNullOrWhiteSpace(id.Text) || string.IsNullOrWhiteSpace(adeudo.Text) ||
                string.IsNullOrWhiteSpace(sancion.Text) || string.IsNullOrWhiteSpace(descripcion.Text) ||
                string.IsNullOrWhiteSpace(valor.Text))
            {
                await DisplayAlert("Error", "Todos los campos deben estar llenos.", "Aceptar");
                return;
            }

            if (!int.TryParse(id.Text, out int idNumerico))
            {
                await DisplayAlert("Error", "El ID debe ser un número válido.", "Aceptar");
                return;
            }

            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaPrestamos>();

            // Validar existencia del ID en la tabla préstamos
            var existePrestamo = db.Table<TablaPrestamos>().FirstOrDefault(p => p.id_prestamo == idNumerico);
            if (existePrestamo == null)
            {
                await DisplayAlert("Error", "El ID de préstamo no existe.", "Aceptar");
                return;
            }

            try
            {
                // Crear objeto TablaAdeudos con todos los campos necesarios
                var nuevoAdeudo = new TablaAdeudos
                {
                    id_prestamo = idNumerico,
                    Tipo_adeudo = adeudo.Text,
                    Sancion = sancion.Text, // Agregar sanción
                    Descripcion_adeudo = descripcion.Text, // Agregar descripción
                    Fecha_adeudo = fecha.Date, // Agregar fecha
                    Valor = double.TryParse(valor.Text, out double val) ? val : 0 // Validar el valor numérico
                };

                // Guardar el nuevo adeudo en la base de datos
                await conexiondb.InsertAsync(nuevoAdeudo);
                limpiarTA();
                await DisplayAlert("Completado", "Adeudo registrado con éxito.", "Aceptar");
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error al registrar el adeudo: {ex.Message}", "Aceptar");
            }
        }

        private void limpiarTA()
        {
            id.Text = "";
            adeudo.Text = "";
            sancion.Text = ""; // Limpiar campo sancion
            descripcion.Text = ""; // Limpiar campo descripcion
            fecha.Date = DateTime.Now; // Resetear fecha
            valor.Text = ""; // Limpiar campo valor
        }
    }
}
