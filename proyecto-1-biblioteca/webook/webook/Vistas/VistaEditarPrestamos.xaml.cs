using System;
using System.IO;
using Xamarin.Forms;
using SQLite;
using webook.Tablas;
using webook.Datos;
using Xamarin.Forms.Xaml;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VistaEditarPrestamos : ContentPage
    {
        public int idS, idPS;
        public string estadoS, tipoS, idRS;
        public DateTime fecPS, fechMRS;
        private SQLiteAsyncConnection conexiondb;

        public VistaEditarPrestamos(int id, int idP, DateTime fecP, DateTime fechMR, string estado, string tipo, string idR)
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            idS = id;
            idPS = idP;
            fecPS = fecP;
            fechMRS = fechMR;
            estadoS = estado;
            tipoS = tipo;
            idRS = idR;

            btnActualizarPre.Clicked += BtnActualizarPre_Clicked;
            btnEliminarPre.Clicked += BtnEliminarPre_Clicked;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();
            // Rellenar los campos con los valores actuales
            Mid.Text = $"ID: {idS}";
            idPerson.Text = idPS.ToString();
            fechaprest.Date = fecPS;
            fechamaxregreso.Date = fechMRS;
            estado.SelectedItem = estadoS;
            tipo.SelectedItem = tipoS;
            idrecurso.Text = idRS;
        }

        private async void BtnEliminarPre_Clicked(object sender, EventArgs args)
        {
            var confirm = await DisplayAlert("Confirmar", "¿Seguro que deseas eliminar este préstamo?", "Sí", "No");
            if (!confirm) return;

            try
            {
                var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var db = new SQLiteConnection(BD);
                db.Execute("DELETE FROM TablaPrestamos WHERE id_prestamo = ?", idS);

                await DisplayAlert("Completado", "El préstamo se ha eliminado con éxito.", "Aceptar");
                LimpiarTPre();
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error al eliminar el préstamo: {ex.Message}", "Aceptar");
            }
        }

        private async void BtnActualizarPre_Clicked(object sender, EventArgs args)
        {
            // Validaciones antes de actualizar
            if (string.IsNullOrWhiteSpace(idPerson.Text) || estado.SelectedItem == null ||
                tipo.SelectedItem == null || string.IsNullOrWhiteSpace(idrecurso.Text))
            {
                await DisplayAlert("Error", "Todos los campos deben estar completos.", "Aceptar");
                return;
            }

            if (!int.TryParse(idPerson.Text, out int idPersona))
            {
                await DisplayAlert("Error", "El ID de la persona debe ser un número válido.", "Aceptar");
                return;
            }

            if (fechamaxregreso.Date < fechaprest.Date)
            {
                await DisplayAlert("Error", "La fecha de devolución no puede ser anterior a la fecha del préstamo.", "Aceptar");
                return;
            }

            // Validación del ID de recurso y su existencia en la tabla correspondiente
            if (string.IsNullOrWhiteSpace(idrecurso.Text))
            {
                await DisplayAlert("Error", "El ID de recurso es obligatorio.", "Aceptar");
                return;
            }

            if (!int.TryParse(idrecurso.Text, out int idRecursoValor))
            {
                await DisplayAlert("Error", "El ID de recurso debe ser un número válido.", "Aceptar");
                return;
            }

            // Crear la conexión a la base de datos
            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaLibros>();
            db.CreateTable<TablaEspacios>();
            db.CreateTable<TablaEquipos>();

            var tipoRecursoSeleccionado = tipo.SelectedItem.ToString();
            bool recursoValido = false;

            // Validación según el tipo de recurso
            if (tipoRecursoSeleccionado == "Libro")
            {
                var existeLibro = db.Table<TablaLibros>().FirstOrDefault(l => l.Isbn == idRecursoValor);
                if (existeLibro != null)
                    recursoValido = true;
            }
            else if (tipoRecursoSeleccionado == "Espacio")
            {
                var existeEspacio = db.Table<TablaEspacios>().FirstOrDefault(e => e.Id_espacio == idRecursoValor);
                if (existeEspacio != null)
                    recursoValido = true;
            }
            else if (tipoRecursoSeleccionado == "Equipo")
            {
                var existeEquipo = db.Table<TablaEquipos>().FirstOrDefault(eq => eq.id_equipo == idRecursoValor);
                if (existeEquipo != null)
                    recursoValido = true;
            }

            if (!recursoValido)
            {
                await DisplayAlert("Error", $"El ID de recurso no existe para el tipo {tipoRecursoSeleccionado}.", "Aceptar");
                return;
            }

            try
            {
                db.Execute("UPDATE TablaPrestamos SET id_persona = ?, Fecha_prestamo = ?, Fecha_maxima_regreso = ?, Estado_prestamo = ?, Tipo_recurso = ?, id_recurso = ? WHERE id_prestamo = ?",
                    idPersona, fechaprest.Date, fechamaxregreso.Date, estado.SelectedItem.ToString(), tipo.SelectedItem.ToString(), idrecurso.Text, idS);

                await DisplayAlert("Completado", "El préstamo se ha actualizado con éxito.", "Aceptar");
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error al actualizar el préstamo: {ex.Message}", "Aceptar");
            }
        }

        private void LimpiarTPre()
        {
            idPerson.Text = "";
            fechaprest.Date = DateTime.Now;
            fechamaxregreso.Date = DateTime.Now;
            estado.SelectedItem = null;
            tipo.SelectedItem = null;
            idrecurso.Text = "";
        }
    }
}
