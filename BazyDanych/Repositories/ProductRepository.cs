using BazyDanych.Data;
using BazyDanych.Data.Entities;
using BazyDanych.Data.Models;
using Dapper;

namespace BazyDanych.Repositories;

public class ProductRepository
{
    private readonly DapperContext _context;

    public ProductRepository(DapperContext context)
    {
        _context = context;
    }
    
    public async Task<IEnumerable<Product>> GetProductsAsync(PermissionsModel? permissionsModel)
    {
        const string query = """
                             SELECT * FROM "Produkt"
                             ORDER BY id_produktu
                             """;

        if (permissionsModel is null) return [];
        
        using var connection = _context.CreateUserConnection(permissionsModel);
        
        return await connection.QueryAsync<Product>(query);
    }
    
    
    public async Task<IEnumerable<WarehouseProductStatus>> GetWarehouseProductStatusAsync(PermissionsModel? permissionsModel)
    {
        const string query = """
                             SELECT * FROM "Stan_magazynu_z_oczekującymi_zamowieniami"
                             """;

        if (permissionsModel is null) return [];

        using var connection = _context.CreateUserConnection(permissionsModel);
        
        return await connection.QueryAsync<WarehouseProductStatus>(query);
    }
    
    public async Task ModifyProductAsync(Product product, PermissionsModel? permissionsModel)
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

        if (permissionsModel is null) return;

        using var connection = _context.CreateUserConnection(permissionsModel);
        
        await connection.ExecuteAsync(query, product);
    }
    
    public async Task<int> CreateProductAsync(Product product, PermissionsModel? permissionsModel)
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

        if (permissionsModel is null) return 0;
        
        using var connection = _context.CreateUserConnection(permissionsModel);
        
        var productId = await connection.ExecuteScalarAsync<int>(query, product);
        return productId;
    }
    
    public async Task DeleteProductAsync(int productId, PermissionsModel? permissionsModel)
    {
        const string query = """
                                DELETE FROM "Produkt"
                                WHERE id_produktu = @Id
                             """;

        if (permissionsModel is null) return;
        
        using var connection = _context.CreateUserConnection(permissionsModel);
        
        await connection.ExecuteAsync(query, new { Id = productId });
    }
}