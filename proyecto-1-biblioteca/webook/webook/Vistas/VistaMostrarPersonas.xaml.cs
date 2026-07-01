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
using System.Collections.ObjectModel;
using System.IO;

namespace webook.Vistas
{
	[XamlCompilation(XamlCompilationOptions.Compile)]
	public partial class VistaMostrarPersonas : ContentPage
	{
        private SQLiteAsyncConnection conexiondb;
        private ObservableCollection<TablaPersonas> TablaPersonas;
        public VistaMostrarPersonas ()
		{
			InitializeComponent ();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ListaPersonas.ItemSelected += ListaPersonas_ItemSelected;
        }

        private void ListaPersonas_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var elementos = (TablaPersonas)e.SelectedItem;
            var tid = elementos.id_persona.ToString();
            var nom = elementos.Nombre_persona;
            var apP = elementos.Apellido_paterno;
            var apM = elementos.Apellido_materno;
            var edad = elementos.Edad;
            var genero = elementos.Genero;
            int id = Convert.ToInt32(tid);

            try
            {
                Navigation.PushAsync(new VistaEditarPersonas(id,nom,apP,apM,edad,genero));
            }
            catch (Exception)
            {
                throw;
            }
        }

        protected async override void OnAppearing()
        {
            var Registros = await conexiondb.Table<TablaPersonas>().ToListAsync();
            TablaPersonas = new ObservableCollection<TablaPersonas>(Registros);
            ListaPersonas.ItemsSource = TablaPersonas;
            base.OnAppearing();

        }
    }
}