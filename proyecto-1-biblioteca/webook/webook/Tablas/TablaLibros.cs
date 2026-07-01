using SQLite;
using System;
using System.Collections.Generic;
using System.Text;

namespace webook.Tablas
{
    public class TablaLibros
    {
        [PrimaryKey]
        public int Isbn { get; set; }
        [MaxLength(255)]
        public string Titulo { get; set; }
        [MaxLength(255)]
        public string Autores { get; set; }
        [MaxLength(255)]
        public string Editorial { get; set; }
        [MaxLength(255)]
        public string Año_publicacion { get; set; }
        [MaxLength(255)]
        public string Clasificacion { get; set; }
        [MaxLength(255)]
        public int cantidad { get; set; }
        [MaxLength(255)]
        public string Seccion_ubicacion { get; set; }
        [MaxLength(255)]
        public string Estado_libro { get; set; }

    }
}
