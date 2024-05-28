using System.Collections.Immutable;
using BazyDanych.Data.Entities;

namespace BazyDanych.Data.Models;

public record ClientOrderModel(int Id, DateTime TakenAt, decimal TotalPrice, ImmutableList<ClientOrderPart> Parts);

public record ClientOrderPart(Product Product, int Amount, decimal Price);