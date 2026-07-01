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
    public partial class VistaMostrarEquipos : ContentPage
    {
        private SQLiteAsyncConnection conexiondb;
        private ObservableCollection<TablaEquipos> TablaEquipos;
        public VistaMostrarEquipos()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ListaEquipos.ItemSelected += ListaEquipos_ItemSelected;
        }

        private void ListaEquipos_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var elementos = (TablaEquipos)e.SelectedItem;
            var tid = elementos.id_equipo.ToString();
            var marc = elementos.Marca;
            var model = elementos.Modelo;
            var nume = elementos.Numero_equipo;
            var estad = elementos.Estado_equipo;
            var desc = elementos.Descripcion_equipo;
            var exis = elementos.Existencia;
            int id = Convert.ToInt32(tid);

            try
            {
                Navigation.PushAsync(new VistaEditarEquipos(id,marc,model,nume,estad,desc,exis));
            }
            catch(Exception)
            {
                throw;
            }
        }

        protected async override void OnAppearing()
        {
            var Registros = await conexiondb.Table<TablaEquipos>().ToListAsync();
            TablaEquipos = new ObservableCollection<TablaEquipos>(Registros);
            ListaEquipos.ItemsSource = TablaEquipos;
            base.OnAppearing();
           
        }

    }
}