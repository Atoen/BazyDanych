using BazyDanych.Data;
using BazyDanych.Data.Entities;
using Dapper;

namespace BazyDanych.Repositories;

public class ProductRepository
{
    private readonly DapperContext _context;

    public ProductRepository(DapperContext context)
    {
        _context = context;
    }

    public async Task<IEnumerable<Product>> GetProductsAsync()
    {
        var query = """
                    SELECT * FROM "Produkt"
                    """;

        using var connection = _context.CreateConnection();
        var products = await connection.QueryAsync<Product>(query);

        return products;
    }
}