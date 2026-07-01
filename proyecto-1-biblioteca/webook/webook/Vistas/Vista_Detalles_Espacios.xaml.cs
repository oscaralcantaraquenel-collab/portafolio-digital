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
    public partial class Vista_Detalles_Espacios : ContentPage
    {
        private readonly SQLiteAsyncConnection conexiondb;
        private readonly int idSeleccionado;

        public Vista_Detalles_Espacios(int id, string nom, string es, string des, string ubi, string tipo)
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            idSeleccionado = id;
            txtNombre.Text = nom;
            txtEstado.Text = es;
            txtDescripcion.Text = des;
            txtUbicacion.Text = ubi;
            txtTipo.Text = tipo;

            btn_actualizar.Clicked += Btn_actualizar_Clicked;
            btn_eliminar.Clicked += Btn_eliminar_Clicked;
        }

        private async void Btn_actualizar_Clicked(object sender, EventArgs e)
        {
            try
            {
                var espacio = new TablaEspacios
                {
                    Id_espacio = idSeleccionado,
                    Nombre_Espacio = txtNombre.Text.Trim(),
                    Estado_Espacio = txtEstado.Text.Trim(),
                    Descripcion_Espacio = txtDescripcion.Text.Trim(),
                    Ubicacion = txtUbicacion.Text.Trim(),
                    Tipo = txtTipo.Text.Trim(),
                };

                await conexiondb.UpdateAsync(espacio);
                await DisplayAlert("Éxito", "El espacio fue actualizado correctamente.", "Aceptar");
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error: {ex.Message}", "Aceptar");
            }
        }

        private async void Btn_eliminar_Clicked(object sender, EventArgs e)
        {
            try
            {
                var espacio = await conexiondb.FindAsync<TablaEspacios>(idSeleccionado);
                if (espacio != null)
                {
                    await conexiondb.DeleteAsync(espacio);
                    await DisplayAlert("Éxito", "El espacio fue eliminado correctamente.", "Aceptar");
                    await Navigation.PopAsync();
                }
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error: {ex.Message}", "Aceptar");
            }
        }
    }
}
