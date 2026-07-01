using SQLite;
using System.Collections.ObjectModel;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;
using webook.Tablas;
using webook.Datos;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class Vista_Consulta_Espacios : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;
        private ObservableCollection<TablaEspacios> tablaEspacios;

        public Vista_Consulta_Espacios()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ListaEspacios.ItemSelected += ListaEspacios_ItemSelected;
        }

        protected async override void OnAppearing()
        {
            base.OnAppearing();
            var resultadoEspacios = await conexiondb.Table<TablaEspacios>().ToListAsync();
            tablaEspacios = new ObservableCollection<TablaEspacios>(resultadoEspacios);
            ListaEspacios.ItemsSource = tablaEspacios;
        }

        private async void ListaEspacios_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            if (e.SelectedItem is TablaEspacios espacio)
            {
                await Navigation.PushAsync(new Vista_Detalles_Espacios(
                    espacio.Id_espacio,
                    espacio.Nombre_Espacio,
                    espacio.Estado_Espacio,
                    espacio.Descripcion_Espacio,
                    espacio.Ubicacion,
                    espacio.Tipo));
            }
        }
    }
}
