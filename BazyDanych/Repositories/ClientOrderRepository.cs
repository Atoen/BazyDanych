using System.Collections.Immutable;
using BazyDanych.Data;
using BazyDanych.Data.Entities;
using BazyDanych.Data.Models;
using Dapper;

namespace BazyDanych.Repositories;

public class ClientOrderRepository
{
    private readonly DapperContext _context;

    public ClientOrderRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<ClientOrderModel>> GetAllClientOrdersAsync(PermissionsModel? permissionsModel)
    {
        const string ordersQuery = """
                                   SELECT
                                       id_zamowienia_klienta AS Id,
                                       data_zlozenia AS TakenAt,
                                       cena_sumaryczna AS TotalPrice
                                   FROM zamowienie_klienta
                                   ORDER BY id_zamowienia_klienta
                                   """;

        const string detailsQuery = """
                                    SELECT
                                          zks.id_zamowienia_klient as OrderId,
                                          zks.cena as Price,
                                          zks.ilosc_zamowiona as Amount,
                                          p.nazwa as ProductName
                                    FROM "Zamowienie_klienta_szczegoly" zks
                                    JOIN "Produkt" p on p.id_produktu = zks.id_produktu
                                    """;

        if (permissionsModel is null) return [];

        using var connection = _context.CreateUserConnection(permissionsModel);

        var ordersResult = await connection.QueryAsync(ordersQuery);
        var detailsResults = await connection.QueryAsync(detailsQuery);

        var orderDetailsMap = detailsResults
            .GroupBy(d => (int) d.orderid)
            .ToDictionary(
                g => g.Key,
                g => g.Select(d =>
                    new ClientOrderPart(new Product { Name = d.productname }, d.amount, d.price))
            );

        var orders = ordersResult
            .Select(order => new ClientOrderModel(
                order.id,
                order.takenat,
                order.totalprice,
                orderDetailsMap.TryGetValue((int) order.id, out var details)
                    ? details.ToImmutableList()
                    : ImmutableList<ClientOrderPart>.Empty
            ));

        return orders;
    }

    public async Task AddClientOrderAsync(ClientOrderModel order, PermissionsModel? permissionsModel)
    {
        const string insertOrderQuery = """
                                        INSERT INTO "zamowienie_klienta" (data_zlozenia, cena_sumaryczna)
                                        VALUES (@TakenAt, @TotalPrice)
                                        RETURNING id_zamowienia_klienta;
                                        """;

        const string insertOrderPartQuery = """
                                            INSERT INTO "Zamowienie_klienta_szczegoly" (id_zamowienia_klient, id_produktu, ilosc_zamowiona, cena)
                                            VALUES (@OrderId, @ProductId, @Amount, @Price);
                                            """;

        const string reduceProductCountQuery = """
                                               UPDATE "Produkt"
                                               SET
                                                   dostepna_ilosc = dostepna_ilosc - @Amount
                                               WHERE
                                                   id_produktu = @ProductId;
                                               """;

        if (permissionsModel is null) return;
        
        using var connection = _context.CreateUserConnection(permissionsModel);
        connection.Open();

        using var transaction = connection.BeginTransaction();

        try
        {
            var orderId = await connection.ExecuteScalarAsync<int>(insertOrderQuery,
                new { order.TakenAt, order.TotalPrice }, transaction);
            
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

                await connection.ExecuteAsync(
                    reduceProductCountQuery,
                    new
                    {
                        ProductId = part.Product.Id,
                        part.Amount
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