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
        const string query = """
                             SELECT cena, popularnosc, dostepna_ilosc, nazwa, jednostka, kategoria FROM "Produkt"
                             """;

        using var connection = _context.CreateRootConnection();
        return await connection.QueryAsync<Product>(query);
    }

    public async Task<IEnumerable<Product>> GetProductsByNameAsync(string name)
    {
        const string query = """
                             SELECT cena, popularnosc, dostepna_ilosc, nazwa, jednostka, kategoria
                             FROM "Produkt" 
                             WHERE LOWER(nazwa) LIKE '%' || LOWER(@Name) || '%'
                             """;
        using var connection = _context.CreateRootConnection();
        return await connection.QueryAsync<Product>(query, new { name });
    }

    public async Task CreateProduct(Product product)
    {
        const string query = """
                                INSERT INTO "Produkt"(
                                     cena,
                                     popularnosc,
                                     dostepna_ilosc,
                                     nazwa,
                                     jednostka,
                                     kategoria
                                 )
                                 VALUES
                                 (
                                     @Price,
                                     @Popularity,
                                     @AvailableQuantity,
                                     @Name,
                                     @Unit,
                                     @Category
                                 )
                             """;

        using var connection = _context.CreateRootConnection();
        await connection.ExecuteAsync(query, product);
    }
}