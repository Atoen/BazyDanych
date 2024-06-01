using System.ComponentModel.DataAnnotations.Schema;
using System.Data;
using BazyDanych.Data.Entities;
using BazyDanych.Data.Models;
using Dapper;
using Npgsql;

namespace BazyDanych.Data;

public class DapperContext
{
    private const string RootConnectionStringName = "Postgres";
    private const string ManagerConnectionStringName = "Manager";
    private const string WarehouseConnectionStringName = "Warehouse";
    private const string SalesConnectionStringName = "Sales";

    private readonly string _rootConnectionString;
    private readonly string _managerConnectionString;
    private readonly string _warehouseConnectionString;
    private readonly string _salesConnectionString;
    
    public DapperContext(IConfiguration configuration)
    {
        string GetConnectionStringOrThrow(string connectionStringName)
        {
            return configuration.GetConnectionString(connectionStringName)
                   ?? throw new ArgumentNullException(nameof(configuration),
                       $"Connection string '{connectionStringName}' is missing in configuration file");
        }

        _rootConnectionString = GetConnectionStringOrThrow(RootConnectionStringName);
        _managerConnectionString = GetConnectionStringOrThrow(ManagerConnectionStringName);
        _warehouseConnectionString = GetConnectionStringOrThrow(WarehouseConnectionStringName);
        _salesConnectionString = GetConnectionStringOrThrow(SalesConnectionStringName);
        
        ConfigureDapperMappings();
    }

    public IDbConnection CreateRootConnection() => new NpgsqlConnection(_rootConnectionString);

    public IDbConnection CreateUserConnection(PermissionsModel permissionsModel)
    {
        var connectionString = permissionsModel.Permissions switch
        {
            PermissionsModel.ManagerPermission => _managerConnectionString,
            PermissionsModel.WarehousemanPermission => _warehouseConnectionString,
            PermissionsModel.SalesmanPermission => _salesConnectionString,
            _ => throw new InvalidOperationException()
        };

        return new NpgsqlConnection(connectionString);
    }

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
        MapEntityType(typeof(WarehouseProductStatus));
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