using System;
using System.Collections.Generic;
using System.Text;
using SQLite;

namespace webook.Tablas
{
    public class TablaPersonas
    {
        [PrimaryKey, AutoIncrement]
        public int id_persona { get; set; }
        [MaxLength(50)]
        public string Nombre_persona { get; set; }
        [MaxLength(50)]
        public string Apellido_paterno { get; set; }
        [MaxLength(50)]
        public string Apellido_materno { get; set; }
        public int Edad { get; set; }

        [MaxLength(10)]
        public string Genero { get; set; }

    }
}
