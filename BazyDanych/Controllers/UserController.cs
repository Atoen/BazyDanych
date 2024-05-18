using BazyDanych.Repositories;
using Microsoft.AspNetCore.Mvc;

namespace BazyDanych.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UserController : ControllerBase
{
    private readonly ProductRepository _productRepository;

    public UserController(ProductRepository productRepository)
    {
        _productRepository = productRepository;
    }

    [HttpGet("products")]
    public async Task<IActionResult> GetProducts()
    {
        var products = await _productRepository.GetProductsAsync();
        return Ok(products);
    }
}