using System.ComponentModel.DataAnnotations.Schema;

namespace BazyDanych.Data.Entities;

public class WarehouseProductStatus
{
    [Column("nazwa_produktu")] public string ProductName { get; set; } = default!;
    
    [Column("obecnie_dostepna_ilosc")] public long AvailableQuantity { get; set; }
    
    [Column("ilosc_dostepna_po_zamowieniach")] public long AvailableAfterOrders { get; set; }
}