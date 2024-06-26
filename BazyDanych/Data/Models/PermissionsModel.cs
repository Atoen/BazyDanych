namespace BazyDanych.Data.Models;

public record PermissionsModel(string Permissions)
{
    public override string ToString() => Permissions;

    public static PermissionsModel Manager { get; } = new(ManagerPermission);
    public static PermissionsModel Warehouseman { get; } = new(WarehousemanPermission);
    public static PermissionsModel Salesman { get; } = new(SalesmanPermission);

    public const string ManagerPermission = "kierownik";
    public const string WarehousemanPermission = "magazynier";
    public const string SalesmanPermission = "sprzedawca";

    public int DatabaseId => Permissions switch
    {
        ManagerPermission => 1,
        WarehousemanPermission => 2,
        SalesmanPermission => 3,
        _ => throw new ArgumentOutOfRangeException()
    };

    public static IReadOnlyList<PermissionsModel> AllPermissions { get; } = [Manager, Warehouseman, Salesman];
}