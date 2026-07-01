using System;
using System.Collections.Generic;
using System.Text;
using SQLite;

namespace webook.Tablas
{
    public class TablaPrestamos
    {
        [PrimaryKey, AutoIncrement]
        public int id_prestamo { get; set; }

        public int id_persona { get; set; } 

        public DateTime Fecha_prestamo { get; set; }
        public DateTime Fecha_maxima_regreso { get; set; }

        [MaxLength(15)]
        public string Estado_prestamo { get; set; }

        [MaxLength(20)]
        public string Tipo_recurso { get; set; }

        public string id_recurso { get; set; }
    }
}


