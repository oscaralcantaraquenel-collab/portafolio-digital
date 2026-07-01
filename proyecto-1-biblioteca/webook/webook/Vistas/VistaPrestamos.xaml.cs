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
    public partial class VistaPrestamos : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;

        public VistaPrestamos()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            btnRegistrarPre.Clicked += BtnRegistrarPre_Clicked;
            btnRestablecerPre.Clicked += BtnRestablecerPre_Clicked;
            btnMostrarPre.Clicked += BtnMostrarPre_Clicked;
        }

        private void BtnMostrarPre_Clicked(object sender, EventArgs args)
        {
            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaPrestamos>();
            Navigation.PushAsync(new VistaMostrarPrestamos());
        }

        private void BtnRestablecerPre_Clicked(object sender, EventArgs args)
        {
            LimpiarTPre();
        }

        private async void BtnRegistrarPre_Clicked(object sender, EventArgs args)
        {
            // Validar ID de persona
            if (string.IsNullOrWhiteSpace(idPerson.Text))
            {
                await DisplayAlert("Error", "El ID de persona es obligatorio.", "Aceptar");
                return;
            }

            if (!int.TryParse(idPerson.Text, out int idPersona))
            {
                await DisplayAlert("Error", "El ID de la persona debe ser un número válido.", "Aceptar");
                return;
            }

            var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
            var db = new SQLiteConnection(BD);
            db.CreateTable<TablaPersonas>();

            var existePersona = db.Table<TablaPersonas>().FirstOrDefault(p => p.id_persona == idPersona);
            if (existePersona == null)
            {
                await DisplayAlert("Error", "El ID de persona no existe.", "Aceptar");
                return;
            }

            // Validar ID de recurso y tipo de recurso
            if (string.IsNullOrWhiteSpace(idrecurso.Text) || string.IsNullOrWhiteSpace(tipo.SelectedItem?.ToString()))
            {
                await DisplayAlert("Error", "El ID de recurso y el tipo de recurso son obligatorios.", "Aceptar");
                return;
            }

            if (!int.TryParse(idrecurso.Text, out int idRecursoValor))
            {
                await DisplayAlert("Error", "El ID de recurso debe ser un número válido.", "Aceptar");
                return;
            }

            // Validar que el recurso exista dependiendo del tipo de recurso
            var tipoRecursoSeleccionado = tipo.SelectedItem.ToString();

            bool recursoValido = false;
            if (tipoRecursoSeleccionado == "Libro")
            {
                var existeLibro = db.Table<TablaLibros>().FirstOrDefault(l => l.Isbn == idRecursoValor);
                recursoValido = existeLibro != null;
            }
            else if (tipoRecursoSeleccionado == "Espacio")
            {
                var existeEspacio = db.Table<TablaEspacios>().FirstOrDefault(e => e.Id_espacio == idRecursoValor);
                recursoValido = existeEspacio != null;
            }
            else if (tipoRecursoSeleccionado == "Equipo")
            {
                var existeEquipo = db.Table<TablaEquipos>().FirstOrDefault(eq => eq.id_equipo == idRecursoValor);
                recursoValido = existeEquipo != null;
            }

            if (!recursoValido)
            {
                await DisplayAlert("Error", $"El ID de recurso no existe para el tipo {tipoRecursoSeleccionado}.", "Aceptar");
                return;
            }

            // Validar que la fecha de préstamo no sea mayor que la fecha máxima de regreso
            if (fechaprest.Date > fechamaxregreso.Date)
            {
                await DisplayAlert("Error", "La fecha de préstamo no puede ser mayor a la fecha máxima de regreso.", "Aceptar");
                return;
            }

            // Validar estado
            if (estado.SelectedItem == null)
            {
                await DisplayAlert("Error", "El estado del préstamo es obligatorio.", "Aceptar");
                return;
            }

            try
            {
                // Registrar préstamo con fecha máxima de regreso y estado
                var nuevoPrestamo = new TablaPrestamos
                {
                    id_persona = idPersona,
                    Fecha_prestamo = fechaprest.Date,
                    Fecha_maxima_regreso = fechamaxregreso.Date,  // Aseguramos que la fecha máxima de regreso se guarde correctamente
                    Estado_prestamo = estado.SelectedItem.ToString(),  // Guardamos el estado seleccionado
                    Tipo_recurso = tipoRecursoSeleccionado,
                    id_recurso = idRecursoValor.ToString()
                };

                await conexiondb.InsertAsync(nuevoPrestamo);
                LimpiarTPre();
                await DisplayAlert("Completado", "Préstamo registrado con éxito.", "Aceptar");
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Error al registrar préstamo: {ex.Message}", "Aceptar");
            }
        }

        private void LimpiarTPre()
        {
            idPerson.Text = "";
            fechaprest.Date = DateTime.Now;
            fechamaxregreso.Date = DateTime.Now;
            estado.SelectedItem = null;
            idrecurso.Text = "";
            tipo.SelectedItem = null;
        }
    }
}
