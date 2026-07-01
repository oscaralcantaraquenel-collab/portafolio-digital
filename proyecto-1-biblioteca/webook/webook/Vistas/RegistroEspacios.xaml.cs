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
    public partial class RegistroEspacios : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;

        public RegistroEspacios()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            Boton_Guardar.Clicked += Boton_Guardar_Clicked;
            Boton_Limpiar.Clicked += LimpiarFormulario_Boton;
            Boton_Registros.Clicked += Boton_Registros_Clicked;
        }

        private async void Boton_Guardar_Clicked(object sender, EventArgs e)
        {
            try
            {
                // Validación de campos vacíos
                if (string.IsNullOrWhiteSpace(nombre.Text) ||
                    string.IsNullOrWhiteSpace(estado.Text) ||
                    string.IsNullOrWhiteSpace(descripcion.Text) ||
                    string.IsNullOrWhiteSpace(ubicacion.Text) ||
                    string.IsNullOrWhiteSpace(tipo.Text))
                {
                    await DisplayAlert("Error", "Todos los campos deben estar llenos.", "Aceptar");
                    return;
                }

                // Crear y guardar el objeto en la base de datos
                var espacio = new TablaEspacios
                {
                    Nombre_Espacio = nombre.Text.Trim(),
                    Estado_Espacio = estado.Text.Trim(),
                    Descripcion_Espacio = descripcion.Text.Trim(),
                    Ubicacion = ubicacion.Text.Trim(),
                    Tipo = tipo.Text.Trim(),
                };
                await conexiondb.InsertAsync(espacio);

                limpiarTE();
                await DisplayAlert("Registro exitoso", "El Espacio se ha registrado correctamente", "Aceptar");
            }
            catch (Exception ex)
            {
                await DisplayAlert("Error", $"Ocurrió un error: {ex.Message}", "Aceptar");
            }
        }

        private void LimpiarFormulario_Boton(object sender, EventArgs e) => limpiarTE();

        private void limpiarTE()
        {
            nombre.Text = string.Empty;
            estado.Text = string.Empty;
            descripcion.Text = string.Empty;
            ubicacion.Text = string.Empty;
            tipo.Text = string.Empty;
        }

        private async void Boton_Registros_Clicked(object sender, EventArgs e)
        {
            await Navigation.PushAsync(new Vista_Consulta_Espacios());
        }
    }
}
