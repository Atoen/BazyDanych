using System.ComponentModel.DataAnnotations.Schema;
using System.Data;
using BazyDanych.Data.Entities;
using Dapper;
using Npgsql;

namespace BazyDanych.Data;

public class DapperContext
{
    private const string ConnectionStringName = "Postgres";

    private readonly string _connectionString;

    public DapperContext(IConfiguration configuration)
    {
        _connectionString = configuration.GetConnectionString(ConnectionStringName)
                            ?? throw new ArgumentNullException(nameof(configuration),
                                $"Connection string '{ConnectionStringName}' is missing in configuration file");
        
        ConfigureDapperMappings();
    }

    public IDbConnection CreateConnection() => new NpgsqlConnection(_connectionString);

    private void ConfigureDapperMappings()
    {
        MapEntityType(typeof(Product));
        MapEntityType(typeof(Decision));
        MapEntityType(typeof(Schedule));
        MapEntityType(typeof(Employee));
        MapEntityType(typeof(Movie));
        MapEntityType(typeof(Position));
        MapEntityType(typeof(Permissions));
        MapEntityType(typeof(WarehouseOrder));
        MapEntityType(typeof(WarehouseOrderDetail));
        MapEntityType(typeof(ClientOrder));
        MapEntityType(typeof(ClientOrderDetail));
    }

    private static void MapEntityType(Type type)
    {
        SqlMapper.SetTypeMap(
            type,
            new CustomPropertyTypeMap(
                type,
                (t, columnName) => 
                    t.GetProperties().FirstOrDefault(prop => 
                        prop.GetCustomAttributes(false)
                            .OfType<ColumnAttribute>()
                            .Any(attr => attr.Name == columnName))!
            )
        );
    }
}