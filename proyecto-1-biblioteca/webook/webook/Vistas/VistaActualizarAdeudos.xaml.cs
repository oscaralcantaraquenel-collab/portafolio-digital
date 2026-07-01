using System;
using System.Collections.Generic;
using System.IO;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using SQLite;
using webook.Tablas;
using webook.Datos;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VistaActualizarAdeudos : ContentPage
    {
        public int idS;
        public string tipoS, sanS, descS;
        public double valS;
        public DateTime fechS;
        private SQLiteAsyncConnection conexiondb;
        IEnumerable<TablaAdeudos> BorrarR;
        IEnumerable<TablaAdeudos> ActualizarR;

        public VistaActualizarAdeudos(int id, string tipo, string san, string desc, DateTime fech, double val)
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            idS = id;
            tipoS = tipo;
            sanS = san;
            descS = desc;
            fechS = fech;
            valS = val;

            btnActualizarA.Clicked += BtnActualizarA_Clicked;
            btnEliminarA.Clicked += BtnEliminarA_Clicked;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            // Verificar que los valores estén correctos antes de asignarlos a los campos
            Console.WriteLine($"Cargando datos de adeudo - ID: {idS}, Tipo: {tipoS}, Sanción: {sanS}, Descripción: {descS}, Fecha: {fechS}, Valor: {valS}");

            Mid.Text = idS.ToString();
            adeudo.Text = tipoS;
            sancion.Text = sanS;
            descripcion.Text = descS;
            fecha.Date = fechS;
            valor.Text = valS.ToString();
        }

        private async void BtnEliminarA_Clicked(object sender, EventArgs e)
        {
            try
            {
                var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var db = new SQLiteConnection(BD);
                BorrarR = Borrar(db, idS);
                DisplayAlert("Completado", "El adeudo se ha eliminado con éxito.", "Aceptar");
                limpiarTA();
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                DisplayAlert("Error", $"Ocurrió un error al eliminar: {ex.Message}", "Aceptar");
            }
        }

        private IEnumerable<TablaAdeudos> Borrar(SQLiteConnection db, int idS)
        {
            return db.Query<TablaAdeudos>("DELETE FROM TablaAdeudos WHERE id_prestamo = ?", idS);
        }

        private async void BtnActualizarA_Clicked(object sender, EventArgs e)
        {
            // Validar campos vacíos
            if (string.IsNullOrWhiteSpace(Mid.Text) || string.IsNullOrWhiteSpace(adeudo.Text) ||
                string.IsNullOrWhiteSpace(sancion.Text) || string.IsNullOrWhiteSpace(descripcion.Text) ||
                string.IsNullOrWhiteSpace(valor.Text))
            {
                DisplayAlert("Error", "Todos los campos deben estar llenos.", "Aceptar");
                return;
            }

            // Validar datos numéricos
            if (!int.TryParse(Mid.Text, out int nuevoId))
            {
                DisplayAlert("Error", "El ID debe ser un número válido.", "Aceptar");
                return;
            }

            if (!double.TryParse(valor.Text, out double nuevoValor))
            {
                DisplayAlert("Error", "El valor debe ser un número válido.", "Aceptar");
                return;
            }

            // Verificar si el ID préstamo existe
            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var dbExistencia = new SQLiteConnection(BD);

            // Consulta para verificar si el ID préstamo existe en la base de datos
            var consultaExistencia = dbExistencia.Query<TablaPrestamos>("SELECT * FROM TablaPrestamos WHERE id_prestamo = ?", nuevoId);

            if (consultaExistencia.Count == 0)
            {
                DisplayAlert("Error", "El ID del préstamo no existe en la base de datos.", "Aceptar");
                return; // No se permite la actualización si el ID no existe
            }

            try
            {
                var db = new SQLiteConnection(BD);
                ActualizarR = Actualizar(db, nuevoId, adeudo.Text, sancion.Text, descripcion.Text, fecha.Date, nuevoValor, idS);
                DisplayAlert("Completado", "El adeudo se ha actualizado con éxito.", "Aceptar");
                idS = nuevoId; // Actualizar el ID actual
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                DisplayAlert("Error", $"Ocurrió un error al actualizar: {ex.Message}", "Aceptar");
            }
        }

        private IEnumerable<TablaAdeudos> Actualizar(SQLiteConnection db, int nuevoId, string adeudo, string sancion, string descripcion, DateTime fecha, double valor, int idS)
        {
            return db.Query<TablaAdeudos>(
                "UPDATE TablaAdeudos SET id_prestamo = ?, Tipo_adeudo = ?, Sancion = ?, Descripcion_adeudo = ?, Fecha_adeudo = ?, Valor = ? WHERE id_prestamo = ?",
                nuevoId, adeudo, sancion, descripcion, fecha, valor, idS
            );
        }

        private void limpiarTA()
        {
            adeudo.Text = "";
            sancion.Text = "";
            descripcion.Text = "";
            fecha.Date = DateTime.Now;
            valor.Text = "";
            Mid.Text = "";
        }
    }
}
