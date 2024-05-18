using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Detail ID = {Id}, Order ID = {OrderId}, Product ID = {ProductId}, Quantity = {Quantity}, Price = {Price}")]
public class WarehouseOrderDetail
{
    [Column("id_szczegolow_zamowienia")] public int Id { get; set; }

    [Column("id_zamowienia_do_magazynu")] public int OrderId { get; set; }

    [Column("id_produktu")] public int ProductId { get; set; }

    [Column("ilosc_w_zamowienia")] public int Quantity { get; set; }

    [Column("cena")] public decimal Price { get; set; }
}