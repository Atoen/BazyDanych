using System.ComponentModel.DataAnnotations.Schema;

namespace BazyDanych.Data.Entities;

public class WarehouseProductStatus
{
    [Column("nazwa_produktu")] public string ProductName { get; init; } = default!;
    
    [Column("obecnie_dostepna_ilosc")] public long AvailableQuantity { get; init; }
    
    [Column("ilosc_dostepna_po_zamowieniach")] public long AvailableAfterOrders { get; init; }
}