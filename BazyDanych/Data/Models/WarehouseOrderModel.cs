using System.Collections.Immutable;
using BazyDanych.Data.Entities;

namespace BazyDanych.Data.Models;

public record WarehouseOrderModel(
    int Id,
    DateTime PlacedAt,
    int OrderingEmployeeId,
    decimal TotalPrice,
    ImmutableList<WarehouseOrderPart> Parts,
    int? AcceptingEmployeeId = null,
    DateTime? DeliveredAt = null)
{
    public bool InProgress => AcceptingEmployeeId is null;
}

public record WarehouseOrderPart(Product Product, int Amount, decimal Price);