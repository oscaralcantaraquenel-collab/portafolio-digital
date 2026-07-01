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
	public partial class VistaMostrarAdeudos : ContentPage
	{
        private SQLiteAsyncConnection conexiondb;
        private ObservableCollection<TablaAdeudos> TablaAdeudos;
        public VistaMostrarAdeudos()
        {
            InitializeComponent();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ListaAdeudos.ItemSelected += ListaAdeudos_ItemSelected;
        }

        private void ListaAdeudos_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var elementos = (TablaAdeudos)e.SelectedItem;
            var tid = elementos.id_prestamo.ToString();
            var tipo = elementos.Tipo_adeudo;
            var san = elementos.Sancion;
            var desc = elementos.Descripcion_adeudo;
            var fech = elementos.Fecha_adeudo;
            var val = elementos.Valor;
            int id = Convert.ToInt32(tid);

            try
            {
                Navigation.PushAsync(new VistaActualizarAdeudos(id, tipo, san, desc, fech, val));
            }
            catch (Exception)
            {
                throw;
            }
        }

        protected async override void OnAppearing()
        {
            var Registros = await conexiondb.Table<TablaAdeudos>().ToListAsync();
            TablaAdeudos = new ObservableCollection<TablaAdeudos>(Registros);
            ListaAdeudos.ItemsSource = TablaAdeudos;
            base.OnAppearing();

        }
    }
}