using System;
using System.Collections.Generic;
using System.Text;
using SQLite;

namespace webook.Datos
{
    public interface BaseDatos
    {
        SQLiteAsyncConnection ObtenerConexion();
    }
}
