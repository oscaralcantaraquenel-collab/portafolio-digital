using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using webook.Vistas;
using Xamarin.Forms;

namespace webook
{
    public partial class MainPage : ContentPage
    {
        public MainPage()
        {
            InitializeComponent();
            btnRegistrarA.Clicked += BtnRegistrarA_Clicked;
            btnRegistrarEquip.Clicked += btnRegistrarEquip_Clicked;
            btnRegistrarP.Clicked += BtnRegistrarP_Clicked;
            btnRegistrarEsp.Clicked += BtnRegistrarEsp_Clicked;
            btnRegistrarL.Clicked += BtnRegistrarL_Clicked;
            btnRegistrarPr.Clicked += BtnRegistrarPr_Clicked;
        }

        private void BtnRegistrarPr_Clicked(object sender, EventArgs e)
        {
            //Prestamos
            Navigation.PushAsync(new VistaPrestamos());
        }

        private void BtnRegistrarL_Clicked(object sender, EventArgs e)
        {
            //Libros
            Navigation.PushAsync(new Vista_Registro_Libro());
        }

        private void BtnRegistrarEsp_Clicked(object sender, EventArgs e)
        {
            //Espacios
            Navigation.PushAsync(new RegistroEspacios());
        }

        private void BtnRegistrarP_Clicked(object sender, EventArgs e)
        {
            //Personas
            Navigation.PushAsync(new VistaPersonas());
        }

        private void btnRegistrarEquip_Clicked(object sender, EventArgs e)
        {
            //Equipos
            Navigation.PushAsync(new VistaEquipos());
        }

        private void BtnRegistrarA_Clicked(object sender, EventArgs e)
        {
            //Adeudos
            Navigation.PushAsync(new VistaAdeudos());
        }
    }
}
