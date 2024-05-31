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
                             SELECT * FROM "Produkt"
                             ORDER BY id_produktu
                             """;

        using var connection = _context.CreateRootConnection();
        return await connection.QueryAsync<Product>(query);
    }
    
    
    public async Task<IEnumerable<WarehouseProductStatus>> GetWarehouseProductStatusAsync()
    {
        const string query = """
                             SELECT * FROM "Stan_magazynu_z_oczekującymi_zamowieniami"
                             """;

        using var connection = _context.CreateRootConnection();
        return await connection.QueryAsync<WarehouseProductStatus>(query);
    }

    public async Task<IEnumerable<Product>> GetProductsByNameAsync(string name)
    {
        const string query = """
                             SELECT *
                             FROM "Produkt" 
                             WHERE LOWER(nazwa) LIKE '%' || LOWER(@Name) || '%'
                             """;
        using var connection = _context.CreateRootConnection();
        return await connection.QueryAsync<Product>(query, new { name });
    }
    
    public async Task ModifyProductAsync(Product product)
    {
        const string query = """
                                UPDATE "Produkt"
                                SET
                                    cena = @Price,
                                    popularnosc = @Popularity,
                                    dostepna_ilosc = @AvailableQuantity,
                                    nazwa = @Name,
                                    jednostka = @Unit,
                                    kategoria = @Category
                                WHERE
                                    id_produktu = @Id
                             """;

        using var connection = _context.CreateRootConnection();
        await connection.ExecuteAsync(query, product);
    }
    
    public async Task<int> CreateProductAsync(Product product)
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
                            RETURNING "id_produktu"
                            """;

        using var connection = _context.CreateRootConnection();
        var productId = await connection.ExecuteScalarAsync<int>(query, product);

        return productId;
    }
    
    public async Task DeleteProductAsync(int productId)
    {
        const string query = """
                                DELETE FROM "Produkt"
                                WHERE id_produktu = @Id
                             """;

        using var connection = _context.CreateRootConnection();
        await connection.ExecuteAsync(query, new { Id = productId });
    }
}