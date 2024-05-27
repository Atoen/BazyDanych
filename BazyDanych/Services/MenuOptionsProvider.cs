using BazyDanych.Data.Models;

namespace BazyDanych.Services;

public class MenuOptionsProvider
{
    private readonly UserService _userService;

    public MenuOptionsProvider(UserService userService)
    {
        _userService = userService;
    }

    public IEnumerable<MenuOption> GetOptions()
    {
        return _userService.EmployeePermissions switch
        {
            { Permissions: PermissionsModel.ManagerPermission } => GetManagerOptions(),
            { Permissions: PermissionsModel.WarehousemanPermission } => GetWarehousemanOptions(),
            { Permissions: PermissionsModel.SalesmanPermission } => GetSalesmanOptions(),
            null => [],
            _ => throw new ArgumentOutOfRangeException()
        };
    }

    private IEnumerable<MenuOption> GetManagerOptions()
    {
        return
        [
            new MenuOption("Edytuj menu", "/EditMenu"),
            new MenuOption("Zamówienia i stan magazynu", "/Warehouse"),
            new MenuOption("Zarządzaj pracownikami", "/Employees"),
            new MenuOption("Raporty", "/Reports")
        ];
    }
    
    private IEnumerable<MenuOption> GetWarehousemanOptions()
    {
        return
        [
            new MenuOption("Złóż zamówienie", "/Warehouse/PlaceOrder?FromMenu=true"),
            new MenuOption("Stan magazynu", "/Warehouse"),
            new MenuOption("Potwierdź dostarczenie", "/Warehouse/ConfirmDelivery")
        ];
    }
    
    private IEnumerable<MenuOption> GetSalesmanOptions()
    {
        return
        [
            new MenuOption("Przyjmij zamówienie", "/TakeOrder"),
            new MenuOption("Potwierdź dostarczenie zamówienia", "/Warehouse/ConfirmDelivery"),
        ];
    }
}