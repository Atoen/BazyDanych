using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics;

namespace BazyDanych.Data.Entities;

[DebuggerDisplay("Detail ID = {Id}, Client Order ID = {ClientOrderId}, Product ID = {ProductId}, Quantity = {Quantity}, Price = {Price}")]
public class ClientOrderDetail
{
    [Column("id_szczegolow")] public int Id { get; set; }

    [Column("id_zamowienia_klient")] public int ClientOrderId { get; set; }

    [Column("id_produktu")] public int ProductId { get; set; }

    [Column("ilosc_zamowiona")] public int Quantity { get; set; }

    [Column("cena")] public decimal Price { get; set; }
}