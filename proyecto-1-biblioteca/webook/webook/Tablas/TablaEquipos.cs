using System;
using System.Collections.Generic;
using System.Text;
using SQLite;

namespace webook.Tablas
{
    public class TablaEquipos
    {
        [PrimaryKey, AutoIncrement]
        public int id_equipo { get; set; }
        [MaxLength(40)]
        public string Marca { get; set; }
        [MaxLength(40)]
        public string Modelo { get; set; }
        public int Numero_equipo { get; set; }

        [MaxLength(15)]
        public string Estado_equipo { get; set; }

        [MaxLength(100)]
        public string Descripcion_equipo { get; set; }

        public int Existencia { get; set; }
    }
}
