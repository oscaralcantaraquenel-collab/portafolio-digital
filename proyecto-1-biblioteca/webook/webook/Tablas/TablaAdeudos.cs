using System;
using System.Collections.Generic;
using System.Text;
using SQLite;

namespace webook.Tablas
{
    public class TablaAdeudos
    {
        [PrimaryKey]
        public int id_prestamo { get; set; }

        [MaxLength(30)]
        public string Tipo_adeudo { get; set; }

        [MaxLength(60)]
        public string Sancion { get; set; }

        [MaxLength(120)]
        public string Descripcion_adeudo { get; set; }

        public DateTime Fecha_adeudo { get; set; }

        public double Valor { get; set; }
    }
}
