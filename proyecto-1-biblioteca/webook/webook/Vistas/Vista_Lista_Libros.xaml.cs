using SQLite;
using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using webook.Datos;
using webook.Tablas;
using Xamarin.Forms;
using Xamarin.Forms.Xaml;

namespace webook.Vistas
{
    [XamlCompilation(XamlCompilationOptions.Compile)]
    public partial class Vista_Lista_Libros : ContentPage
    {
        private SQLiteAsyncConnection enlace;
        private ObservableCollection<TablaLibros> TablaLibros;
        public Vista_Lista_Libros()
        {
            InitializeComponent();
            enlace = DependencyService.Get<BaseDatos>().ObtenerConexion();
            ListaLibros.ItemSelected += ListaLibros_ItemSelected;
        }
        private void ListaLibros_ItemSelected(object sender, SelectedItemChangedEventArgs e)
        {
            var Obj = (TablaLibros)e.SelectedItem;
            var item = Obj.Isbn.ToString();
            var item2 = Obj.cantidad.ToString();
            var titulo = Obj.Titulo;
            var autores = Obj.Autores;
            var editorial = Obj.Editorial;
            var publicacion = Obj.Año_publicacion;
            var clasificacion = Obj.Clasificacion;
            var cantidad = Obj.cantidad;
            var seccion = Obj.Seccion_ubicacion;
            var estado = Obj.Estado_libro;
            int ID = Convert.ToInt32(item);
            int cant = Convert.ToInt32(item2);
            try
            {
                Navigation.PushAsync(new Vista_Detalles_Libros(ID, titulo, autores,
                    editorial, publicacion, clasificacion, cant, seccion, estado));
            }
            catch (Exception)
            {
                throw;
            }
        }
        protected async override void OnAppearing()
        {
            var RegistrosEncontrados = await enlace.Table<TablaLibros>().ToListAsync();
            TablaLibros = new ObservableCollection<TablaLibros>(RegistrosEncontrados);
            ListaLibros.ItemsSource = TablaLibros;
            base.OnAppearing();
        }
    }
}