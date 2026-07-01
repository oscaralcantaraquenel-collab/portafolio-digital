using SQLite;
using System;
using System.Collections.Generic;
using System.Text;

namespace webook.Tablas
{
    public class TablaEspacios
    {
        [PrimaryKey, AutoIncrement]
        public int Id_espacio { get; set; }
        [MaxLength(255)]
        public string Nombre_Espacio { get; set; }
        [MaxLength(255)]
        public string Estado_Espacio { get; set; }
        [MaxLength(255)]
        public string Descripcion_Espacio { get; set; }
        [MaxLength(255)]
        public string Ubicacion { get; set; }
        [MaxLength(255)]
        public string Tipo { get; set; }
    }
}
