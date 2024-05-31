using System.Collections.Immutable;
using System.Data;
using BazyDanych.Data;
using BazyDanych.Data.Entities;
using BazyDanych.Data.Models;
using Dapper;

namespace BazyDanych.Repositories;

public class WarehouseOrderRepository
{
    private readonly DapperContext _context;

    public WarehouseOrderRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task MarkAsDeliveredAsync(WarehouseOrderModel warehouseOrderModel)
    {
        const string query = """
                             UPDATE "Zamowienie_do_magazynu"
                             SET
                                 data_zrealizowania = current_timestamp
                             WHERE 
                                 id_zamowienia = @Id
                             """;

        using var connection = _context.CreateRootConnection();
        await connection.ExecuteAsync(query, new { warehouseOrderModel.Id });
    }
    
    public async Task ConfirmDeliveryAsync(WarehouseOrderModel warehouseOrderModel, EmployeeModel confirmingEmployee)
    {
        const string procedure = "przyjecie_zamowienia";
        using var connection = _context.CreateRootConnection();
        var parameters = new
        {
            p_id_zamowienia = warehouseOrderModel.Id,
            p_id_pracownika_przyjmujacego = confirmingEmployee.Id
        };

        await connection.ExecuteAsync(procedure, parameters, commandType: CommandType.StoredProcedure);
    }

    public async Task<List<WarehouseOrderModel>> GetPendingWarehouseOrdersAsync()
    {
        const string ordersQuery = """
                                   SELECT
                                       id_zamowienia AS Id,
                                       data_zlozenia AS PlacedAt,
                                       data_zrealizowania AS DeliveredAt,
                                       id_pracownika_zamawiajacego AS OrderingEmployeeId,
                                       id_pracownika_przyjmujacego AS AcceptingEmployeeId,
                                       cena_sumaryczna AS TotalPrice
                                   FROM "Zamowienie_do_magazynu"
                                   WHERE id_pracownika_przyjmujacego IS NULL
                                   ORDER BY id_zamowienia
                                   """;

        const string detailsQuery = """
                                    SELECT
                                          zdm.id_zamowienia_do_magazynu AS OrderId,
                                          zdm.cena AS Price,
                                          zdm.ilosc_w_zamowienia AS Amount,
                                          p.nazwa AS ProductName
                                    FROM "Zamowienie_do_magazynu_szczegoly" zdm
                                    JOIN "Produkt" p ON p.id_produktu = zdm.id_produktu
                                    JOIN public."Zamowienie_do_magazynu" Z on Z.id_zamowienia = zdm.id_zamowienia_do_magazynu
                                    WHERE Z.id_pracownika_przyjmujacego IS NULL 
                                    """;
        
        using var connection = _context.CreateRootConnection();

        var ordersResult = await connection.QueryAsync(ordersQuery);
        var detailsResults = await connection.QueryAsync(detailsQuery);

        var orderDetailsMap = detailsResults
            .GroupBy(d => (int) d.orderid)
            .ToDictionary(
                g => g.Key,
                g => g.Select(d =>
                    new WarehouseOrderPart(new Product { Name = d.productname }, d.amount, d.price))
            );

        var orders = ordersResult
            .Select(order => new WarehouseOrderModel(
                order.id,
                order.placedat,
                order.orderingemployeeid,
                order.totalprice,
                orderDetailsMap.TryGetValue((int) order.id, out var details)
                    ? details.ToImmutableList()
                    : ImmutableList<WarehouseOrderPart>.Empty,
                order.acceptingemployeeid,
                order.deliveredat))
            .ToList();

        return orders;
    }

    public async Task<List<WarehouseOrderModel>> GetAllWarehouseOrdersAsync()
    {
        const string ordersQuery = """
                                   SELECT
                                       id_zamowienia AS Id,
                                       data_zlozenia AS PlacedAt,
                                       data_zrealizowania AS DeliveredAt,
                                       id_pracownika_zamawiajacego AS OrderingEmployeeId,
                                       id_pracownika_przyjmujacego AS AcceptingEmployeeId,
                                       cena_sumaryczna AS TotalPrice
                                   FROM "Zamowienie_do_magazynu"
                                   ORDER BY id_zamowienia
                                   """;

        const string detailsQuery = """
                                    SELECT
                                          zdm.id_zamowienia_do_magazynu AS OrderId,
                                          zdm.cena AS Price,
                                          zdm.ilosc_w_zamowienia AS Amount,
                                          p.nazwa AS ProductName
                                    FROM "Zamowienie_do_magazynu_szczegoly" zdm
                                    JOIN "Produkt" p ON p.id_produktu = zdm.id_produktu
                                    """;

        using var connection = _context.CreateRootConnection();

        var ordersResult = await connection.QueryAsync(ordersQuery);
        var detailsResults = await connection.QueryAsync(detailsQuery);

        var orderDetailsMap = detailsResults
            .GroupBy(d => (int) d.orderid)
            .ToDictionary(
                g => g.Key,
                g => g.Select(d =>
                    new WarehouseOrderPart(new Product { Name = d.productname }, d.amount, d.price))
            );

        var orders = ordersResult
            .Select(order => new WarehouseOrderModel(
                order.id,
                order.placedat,
                order.orderingemployeeid,
                order.totalprice,
                orderDetailsMap.TryGetValue((int) order.id, out var details)
                    ? details.ToImmutableList()
                    : ImmutableList<WarehouseOrderPart>.Empty,
                order.acceptingemployeeid,
                order.deliveredat))
            .ToList();

        return orders;
    }

    public async Task AddWarehouseOrderAsync(WarehouseOrderModel order)
    {
        const string insertOrderQuery = """
                                        INSERT INTO "Zamowienie_do_magazynu"(
                                             data_zlozenia,
                                             data_zrealizowania,
                                             id_pracownika_zamawiajacego, 
                                             id_pracownika_przyjmujacego,
                                             cena_sumaryczna
                                        )
                                        VALUES (
                                             @PlacedAt,
                                             @DeliveredAt,
                                             @OrderingEmployeeId,
                                             @AcceptingEmployeeId, 
                                             @TotalPrice
                                        )
                                        RETURNING id_zamowienia;
                                        """;

        const string insertOrderPartQuery = """
                                            INSERT INTO "Zamowienie_do_magazynu_szczegoly" (id_zamowienia_do_magazynu, id_produktu, ilosc_w_zamowienia, cena)
                                            VALUES (@OrderId, @ProductId, @Amount, @Price);
                                            """;

        using var connection = _context.CreateRootConnection();
        connection.Open();

        using var transaction = connection.BeginTransaction();

        try
        {
            var orderId = await connection.ExecuteScalarAsync<int>(insertOrderQuery,
                new
                {
                    order.PlacedAt, order.DeliveredAt, order.OrderingEmployeeId, order.AcceptingEmployeeId,
                    order.TotalPrice
                }, transaction);

            foreach (var part in order.Parts)
            {
                await connection.ExecuteAsync(
                    insertOrderPartQuery,
                    new
                    {
                        OrderId = orderId,
                        ProductId = part.Product.Id,
                        part.Amount,
                        part.Price
                    },
                    transaction);
            }

            transaction.Commit();
        }
        catch (Exception e)
        {
            transaction.Rollback();
            Console.WriteLine(e);
            throw;
        }
    }
}