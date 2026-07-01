using System;
using System.Collections.Generic;
using System.IO;
using SQLite;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using webook.Tablas;
using webook.Datos;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class VistaEditarEquipos : ContentPage
    {
        public int idS, numS, exisS;
        public string marcaS, modeloS, estadoS, descripcionS;
        private SQLiteAsyncConnection conexiondb;

        public VistaEditarEquipos(int id, string marc, string model, int nume, string estad, string desc, int exis)
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();

            // Asignar valores a variables locales
            idS = id;
            marcaS = marc;
            modeloS = model;
            numS = nume;
            estadoS = estad;
            descripcionS = desc;
            exisS = exis;

            // Asociar eventos
            btnActualizarE.Clicked += BtnActualizarE_Clicked;
            btnEliminarE.Clicked += BtnEliminarE_Clicked;
        }

        protected override void OnAppearing()
        {
            base.OnAppearing();

            // Mostrar los valores en los controles correspondientes
            Mid.Text = $"ID: {idS}";
            marca.Text = marcaS;
            modelo.Text = modeloS;
            numEquipo.Text = numS.ToString();
            estado.Text = estadoS;
            descripcion.Text = descripcionS;
            existencia.Text = exisS.ToString();
        }

        private async void BtnEliminarE_Clicked(object sender, EventArgs e)
        {
            try
            {
                var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var db = new SQLiteConnection(BD);

                // Eliminar registro
                db.Execute("DELETE FROM TablaEquipos WHERE id_equipo = ?", idS);

                await DisplayAlert("Completado", "El equipo se ha eliminado con éxito.", "Aceptar");
                limpiarT();
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error al eliminar el equipo: {ex.Message}", "Aceptar");
            }
        }

        private async void BtnActualizarE_Clicked(object sender, EventArgs e)
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

                // Validar datos numéricos
                if (!int.TryParse(numEquipo.Text, out int numeroEquipo) ||
                    !int.TryParse(existencia.Text, out int existenciaEquipo))
                {
                    await DisplayAlert("Error", "Los campos 'Número del equipo' y 'Existencias' deben contener valores numéricos válidos.", "Aceptar");
                    return;
                }

                // Actualizar registro
                var BD = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "webookBD.db3");
                var db = new SQLiteConnection(BD);
                db.Execute("UPDATE TablaEquipos SET Marca = ?, Modelo = ?, Numero_equipo = ?, Estado_equipo = ?, Descripcion_equipo = ?, Existencia = ? WHERE id_equipo = ?",
                    marca.Text.Trim(), modelo.Text.Trim(), numeroEquipo, estado.Text.Trim(), descripcion.Text.Trim(), existenciaEquipo, idS);

                await DisplayAlert("Completado", "El equipo se ha actualizado con éxito.", "Aceptar");
                await Navigation.PopAsync();
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error al actualizar el equipo: {ex.Message}", "Aceptar");
            }
        }

        private void limpiarT()
        {
            // Limpiar los controles
            marca.Text = string.Empty;
            modelo.Text = string.Empty;
            numEquipo.Text = string.Empty;
            estado.Text = string.Empty;
            descripcion.Text = string.Empty;
            existencia.Text = string.Empty;
        }
    }
}
