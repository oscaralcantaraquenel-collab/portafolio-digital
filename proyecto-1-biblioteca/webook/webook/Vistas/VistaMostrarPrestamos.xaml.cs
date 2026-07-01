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
	public partial class VistaMostrarPrestamos : ContentPage
	{
        private SQLiteAsyncConnection conexiondb;
        private ObservableCollection<TablaPrestamos> TablaPrestamos;
        public VistaMostrarPrestamos ()
		{
			InitializeComponent ();
            conexiondb = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ListaPrestamos.ItemSelected += ListaPrestamos_ItemSelected;
        }

        private void ListaPrestamos_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var elementos = (TablaPrestamos)e.SelectedItem;
            var tid = elementos.id_prestamo.ToString();
            var idP = elementos.id_persona;
            var fecP = elementos.Fecha_prestamo;
            var fechMR = elementos.Fecha_maxima_regreso;
            var estado = elementos.Estado_prestamo;
            var tipo = elementos.Tipo_recurso;
            var idR = elementos.id_recurso;
            int id = Convert.ToInt32(tid);

            try
            {
                Navigation.PushAsync(new VistaEditarPrestamos(id, idP, fecP, fechMR, estado, tipo,idR));
            }
            catch (Exception)
            {
                throw;
            }
        }

        protected async override void OnAppearing()
        {
            var Registros = await conexiondb.Table<TablaPrestamos>().ToListAsync();
            TablaPrestamos = new ObservableCollection<TablaPrestamos>(Registros);
            ListaPrestamos.ItemsSource = TablaPrestamos;
            base.OnAppearing();

        }
    }
}